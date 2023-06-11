import { ethers } from 'hardhat';
import { LensHub__factory } from '../typechain-types';
import { waitForTx } from '../tasks/helpers/utils';

async function main() {
  //Variables
  const accounts = await ethers.getSigners();
  const governance = accounts[0];

  const MOCKSANDBOX_GOVERNANCE = "0x1677d9cc4861f1c85ac7009d5f06f49c928ca2ad"; //sandbox mumbai testnet
  const NCTRetireCollectModuleAddr = '0xc7Fc79a25597bae5CEE7BFca359398375a7Ab1ab'; //deployed on sandbox mumbai testnet

  //Lens core
  const lensHub = LensHub__factory.connect(MOCKSANDBOX_GOVERNANCE, governance);

  //Execution
  await waitForTx(lensHub.whitelistCollectModule(NCTRetireCollectModuleAddr, true));

  console.log(`Module whitelisted.`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
