import { ethers, expect, makeProtocol } from './helpers';

describe('getNow', function () {
  it('reverts if timestamp overflows', async () => {
    const { comet } = await makeProtocol();
    await ethers.provider.send('evm_mine', [2**40]);
<<<<<<< HEAD
    await expect(comet.getNow()).to.be.revertedWith("custom error 'TimestampTooLarge()'");
=======
    await expect(comet.getNow()).to.be.revertedWith('timestamp too big');
>>>>>>> 4db1033 (Trim revert strings)
    await ethers.provider.send('hardhat_reset', []); // dont break downstream tests...
  });
});

describe('updateBaseBalance', function () {
  // XXX
  it.skip('accrues the right amount of rewards', async () => {
    // XXX
  });
});

