import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployWithVerify } from '../../helpers/utils';
import { PartialCarbonRetirementCollectModule__factory, LensHub__factory } from '../../../typechain';

export let runtimeHRE: HardhatRuntimeEnvironment;

task(
  'deploy-partial-carbon-retirement-collect-module',
  'Deploys, verifies and whitelists the partial carbon retirement collect module'
)
  .addParam('hub')
  .addParam('globals')
  .setAction(async ({ hub, globals }, hre) => {
    runtimeHRE = hre;
    const ethers = hre.ethers;
    const accounts = await ethers.getSigners();
    const deployer = accounts[0];
    const governance = accounts[1];

    console.log('\n\n- - - - - - - - Deploying partial carbon retirement fee collect module\n\n');
    const PartialCarbonRetirementCollectModule = await deployWithVerify(
      new PartialCarbonRetirementCollectModule__factory(deployer).deploy(hub, globals),
      [hub, globals],
      'contracts/collect/PartialCarbonRetirementCollectModule.sol:PartialCarbonRetirementCollectModule'
    );

    if (process.env.HARDHAT_NETWORK !== 'matic') {
      console.log('\n\n- - - - - - - - Whitelisting partial carbon retirement fee collect module\n\n');
      await LensHub__factory.connect(hub, governance).whitelistCollectModule(
        partialCarbonRetirementCollectModule.address,
        true
      );
    }
  });
