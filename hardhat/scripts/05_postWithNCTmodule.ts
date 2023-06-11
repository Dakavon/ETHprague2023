import { ethers } from 'hardhat';
import { defaultAbiCoder } from 'ethers/lib/utils';
import { task } from 'hardhat/config';
import { LensHub__factory } from '../typechain-types';
import { PostDataStruct } from '../typechain-types/LensHub';
import { getAddrs, initEnv, waitForTx, ZERO_ADDRESS } from '../tasks/helpers/utils';

import { ContentFocus, CollectPolicyType, ProfileOwnedByMeFragment, ReferencePolicy, useCreatePost } from '@lens-protocol/react';
import { upload } from './upload'

async function main() {
  //Variables
  const accounts = await ethers.getSigners();
  const user = accounts[0];

  const LENSHUB_PROXY = '0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5';
  const NCTRetireCollectModuleAddr = '0xc7Fc79a25597bae5CEE7BFca359398375a7Ab1ab';

  //Lens core
  const lensHub = LensHub__factory.connect(LENSHUB_PROXY, user);

  //Execution
  const inputStruct: PostDataStruct = {
    profileId: 34204,
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