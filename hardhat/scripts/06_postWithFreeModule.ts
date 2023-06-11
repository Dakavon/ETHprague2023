import { ethers } from 'hardhat';
import { defaultAbiCoder } from 'ethers/lib/utils';
import { LensHub__factory } from '../typechain-types';
import { PostDataStruct } from '../typechain-types/LensHub';
import { waitForTx, ZERO_ADDRESS } from '../tasks/helpers/utils';

async function main() {
  //Variables
  const accounts = await ethers.getSigners();
  const user = accounts[0];

  const LENSHUB_PROXY = '0x60Ae865ee4C725cd04353b5AAb364553f56ceF82';
  const freeCollectModuleAddr = '0x0BE6bD7092ee83D44a6eC1D949626FeE48caB30c';

  //Lens core
  const lensHub = LensHub__factory.connect(LENSHUB_PROXY, user);

  //Execution
  const inputStruct: PostDataStruct = {
    profileId: 34204,
    contentURI: 'https://ipfs.io/ipfs/Qmby8QocUU2sPZL46rZeMctAuF5nrCc7eR1PPkooCztWPz',
    collectModule: freeCollectModuleAddr,
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