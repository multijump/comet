import { task } from 'hardhat/config';
import { pullConfigs } from '../scripts/spider';

task('spider', 'Use Spider method to pull in contract configs')
  .setAction(async (taskArgs, hre) => {
    await pullConfigs(hre);
  })