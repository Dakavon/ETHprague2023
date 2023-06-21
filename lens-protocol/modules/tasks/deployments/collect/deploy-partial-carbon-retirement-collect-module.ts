import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployWithVerify } from '../../helpers/utils';
import { PartialCarbonRetirementCollectModule__factory, LensHub__factory } from '../../../typechain';

// External contract addresses
// Hard-coded for testnet, NOT SUITABLE FOR PRODUCTION!
// Alternative: inject values from an environment variable// Hard-coded for testnet, not suitable for production
const RETIREMENT_HELPER_ADDRESS = '0x802fd78B14bF8d0cc0Ba0325351887a323432B70';

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
    const partialCarbonRetirementCollectModule = await deployWithVerify(
      new PartialCarbonRetirementCollectModule__factory(deployer).deploy(hub, globals, RETIREMENT_HELPER_ADDRESS),
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
