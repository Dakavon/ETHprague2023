import { ethers } from 'ethers';
import { defaultAbiCoder } from 'ethers/lib/utils';
import { task } from 'hardhat/config';
import { LensHub__factory } from '../typechain-types';
import { PostDataStruct } from '../typechain-types/LensHub';
import { getAddrs, initEnv, waitForTx, ZERO_ADDRESS } from './helpers/utils';

task('postTestnet', 'publishes a post').setAction(async ({}, hre) => {
  const provider = new hre.ethers.providers.JsonRpcProvider(String(process.env.MUMBAI_RPC_URL));
  const user = new hre.ethers.Wallet(String(process.env.USER_PRIVATE_KEY), provider);

  const lensHub_proxy = '0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5';
  const NCTRetireCollectModuleAddr = '0xe8C0BF8Cc8bDD7a764E81DF7490A30fbf0FC8E89';
  const NTCAddress = '0x7beCBA11618Ca63Ead5605DE235f6dD3b25c530E';
  const lensHub = LensHub__factory.connect(lensHub_proxy, user);
  console.log('1');
  const profileId = await lensHub.getProfileIdByHandle('annitho.test');

  console.log(`2: ProfileId by handle is ${profileId}`);
  const inputStruct: PostDataStruct = {
    profileId: profileId,
    contentURI: 'newer Post',
    // collectModule: NCTRetireCollectModuleAddr,
    collectModule: NCTRetireCollectModuleAddr,
    collectModuleInitData: defaultAbiCoder.encode(
      ['uint256', 'address', 'address', 'uint16', 'bool'],
      [ethers.BigNumber.from(100000000000000), NTCAddress, user.address, 0, false]
    ),
    referenceModule: ZERO_ADDRESS,
    referenceModuleInitData: [],
  };

  console.log(`3: User address is ${user.address}`);
  //await waitForTx(lensHub.connect(user).post(inputStruct));
  const tx = await lensHub.post(inputStruct, { gasLimit: 1000 * 10000 });
  const receipt = await tx.wait();
  console.log(`4: Receipt: ${receipt}`);
  console.log(await lensHub.getPub(profileId, 14));
  console.log('5');
});
