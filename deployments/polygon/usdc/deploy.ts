import { Deployed, DeploymentManager } from '../../../plugins/deployment_manager';
import { DeploySpec, deployComet } from '../../../src/deploy';

export default async function deploy(deploymentManager: DeploymentManager, deploySpec: DeploySpec): Promise<Deployed> {
  // pull in existing assets
  //   WETH
  //   WBTC
  //   MATIC
  //   USDC
  //   DAI
  //   USDT

  // Deploy PolygonBridgeReceiver

  // Deploy Local Timelock

  // Initialize bridge receiver

  // Deploy Comet

  // Deploy Bulker

  return {
    /*
    deployed
    bulker
    bridgeReceiver
    */
  };
}