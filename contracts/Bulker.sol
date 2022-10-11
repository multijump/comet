// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometInterface.sol";
import "./ERC20.sol";
import "./IWrappedNativeAsset.sol";

interface IClaimable {
    function claim(address comet, address src, bool shouldAccrue) external;

    function claimTo(address comet, address src, address to, bool shouldAccrue) external;
}

contract Bulker {
    /** General configuration constants **/
    address public immutable admin;
    address payable public immutable wrappedNativeAsset;

    /** Actions **/
    uint public constant ACTION_SUPPLY_ASSET = 1;
    uint public constant ACTION_SUPPLY_NATIVE_ASSET = 2;
    uint public constant ACTION_TRANSFER_ASSET = 3;
    uint public constant ACTION_WITHDRAW_ASSET = 4;
    uint public constant ACTION_WITHDRAW_NATIVE_ASSET = 5;
    uint public constant ACTION_CLAIM_REWARD = 6;

    /** Custom errors **/
    error InvalidArgument();
    error FailedToSendNativeAsset();
    error Unauthorized();

    constructor(address admin_, address payable wrappedNativeAsset_) {
        admin = admin_;
        wrappedNativeAsset = wrappedNativeAsset_;
    }

    /**
     * @notice Fallback for receiving native asset. Needed for ACTION_WITHDRAW_NATIVE_ASSET.
     */
    receive() external payable {}

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (Timelock)
     * @param recipient The address that will receive the swept funds
     * @param asset The address of the ERC-20 token to sweep
     */
    function sweepToken(address recipient, ERC20 asset) external {
        if (msg.sender != admin) revert Unauthorized();

        uint256 balance = asset.balanceOf(address(this));
        asset.transfer(recipient, balance);
    }

    /**
     * @notice A public function to sweep accidental native asset transfers to this contract. Tokens are sent to admin (Timelock)
     * @param recipient The address that will receive the swept funds
     */
    function sweepNativeAsset(address recipient) external {
        if (msg.sender != admin) revert Unauthorized();

        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{ value: balance }("");
        if (!success) revert FailedToSendNativeAsset();
    }

    /**
     * @notice Executes a list of actions in order
     * @param actions The list of actions to execute in order
     * @param data The list of calldata to use for each action
     */
    function invoke(uint[] calldata actions, bytes[] calldata data) external payable {
        if (actions.length != data.length) revert InvalidArgument();

        uint unusedNativeAsset = msg.value;
        for (uint i = 0; i < actions.length; ) {
            uint action = actions[i];
            if (action == ACTION_SUPPLY_ASSET) {
                (address comet, address to, address asset, uint amount) = abi.decode(data[i], (address, address, address, uint));
                supplyTo(comet, to, asset, amount);
            } else if (action == ACTION_SUPPLY_NATIVE_ASSET) {
                (address comet, address to, uint amount) = abi.decode(data[i], (address, address, uint));
                unusedNativeAsset -= amount;
                supplyNativeAssetTo(comet, to, amount);
            } else if (action == ACTION_TRANSFER_ASSET) {
                (address comet, address to, address asset, uint amount) = abi.decode(data[i], (address, address, address, uint));
                transferTo(comet, to, asset, amount);
            } else if (action == ACTION_WITHDRAW_ASSET) {
                (address comet, address to, address asset, uint amount) = abi.decode(data[i], (address, address, address, uint));
                withdrawTo(comet, to, asset, amount);
            } else if (action == ACTION_WITHDRAW_NATIVE_ASSET) {
                (address comet, address to, uint amount) = abi.decode(data[i], (address, address, uint));
                withdrawNativeAssetTo(comet, to, amount);
            } else if (action == ACTION_CLAIM_REWARD) {
                (address comet, address rewards, address src, bool shouldAccrue) = abi.decode(data[i], (address, address, address, bool));
                claimReward(comet, rewards, src, shouldAccrue);
            }
            unchecked { i++; }
        }

        // Refund unused native asset back to msg.sender
        if (unusedNativeAsset > 0) {
            (bool success, ) = msg.sender.call{ value: unusedNativeAsset }("");
            if (!success) revert FailedToSendNativeAsset();
        }
    }

    /**
     * @notice Supplies an asset to a user in Comet
     */
    function supplyTo(address comet, address to, address asset, uint amount) internal {
        CometInterface(comet).supplyFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Wraps native asset and supplies wrapped native asset to a user in Comet
     */
    function supplyNativeAssetTo(address comet, address to, uint amount) internal {
        IWrappedNativeAsset(wrappedNativeAsset).deposit{ value: amount }();
        IWrappedNativeAsset(wrappedNativeAsset).approve(comet, amount);
        CometInterface(comet).supplyFrom(address(this), to, wrappedNativeAsset, amount);
    }

    /**
     * @notice Transfers an asset to a user in Comet
     */
    function transferTo(address comet, address to, address asset, uint amount) internal {
        CometInterface(comet).transferAssetFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Withdraws an asset to a user in Comet
     */
    function withdrawTo(address comet, address to, address asset, uint amount) internal {
        CometInterface(comet).withdrawFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Withdraws wrapped native asset from Comet to a user after unwrapping it to native asset
     */
    function withdrawNativeAssetTo(address comet, address to, uint amount) internal {
        CometInterface(comet).withdrawFrom(msg.sender, address(this), wrappedNativeAsset, amount);
        IWrappedNativeAsset(wrappedNativeAsset).withdraw(amount);
        (bool success, ) = to.call{ value: amount }("");
        if (!success) revert FailedToSendNativeAsset();
    }

    /**
     * @notice Claim reward for a user
     */
    function claimReward(address comet, address rewards, address src, bool shouldAccrue) internal {
        IClaimable(rewards).claim(comet, src, shouldAccrue);
    }
}
