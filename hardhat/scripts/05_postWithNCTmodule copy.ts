import { ethers } from 'hardhat';
import { defaultAbiCoder } from 'ethers/lib/utils';
import { task } from 'hardhat/config';
import { LensHub__factory } from '../typechain-types';
import { PostDataStruct } from '../typechain-types/LensHub';
import { getAddrs, initEnv, waitForTx, ZERO_ADDRESS } from '../tasks/helpers/utils';

async function main() {
  //Variables
  const accounts = await ethers.getSigners();
  const user = accounts[0];

  const LENSHUB_PROXY = '0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5';
  const NCTRetireCollectModuleAddr = '0x6bDddAFa4d8C383d09B50a08F1Dd338471f928Ae';

  //Lens core
  const lensHub = LensHub__factory.connect(LENSHUB_PROXY, user);

  //Execution
  const inputStruct: PostDataStruct = {
    profileId: 1,
    contentURI: 'https://ipfs.io/ipfs/Qmby8QocUU2sPZL46rZeMctAuF5nrCc7eR1PPkooCztWPz',
    collectModule: NCTRetireCollectModuleAddr,
    collectModuleInitData: defaultAbiCoder.encode(['bool'], [true]),
    referenceModule: ZERO_ADDRESS,
    referenceModuleInitData: [],
  };

  await waitForTx(lensHub.post(inputStruct));
  console.log(await lensHub.getPub(1, 1));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// task('post', 'publishes a post').setAction(async ({}, hre) => {
//   const [governance, , user] = await initEnv(hre);
//   const addrs = getAddrs();
//   const freeCollectModuleAddr = addrs['free collect module'];
//   const lensHub = LensHub__factory.connect(addrs['lensHub proxy'], governance);

//   await waitForTx(lensHub.whitelistCollectModule(freeCollectModuleAddr, true));

//   const inputStruct: PostDataStruct = {
//     profileId: 1,
//     contentURI: 'https://ipfs.io/ipfs/Qmby8QocUU2sPZL46rZeMctAuF5nrCc7eR1PPkooCztWPz',
//     collectModule: freeCollectModuleAddr,
//     collectModuleInitData: defaultAbiCoder.encode(['bool'], [true]),
//     referenceModule: ZERO_ADDRESS,
//     referenceModuleInitData: [],
//   };

//   await waitForTx(lensHub.connect(user).post(inputStruct));
//   console.log(await lensHub.getPub(1, 1));
// });
