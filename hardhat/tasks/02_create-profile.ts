import { task } from 'hardhat/config';
import { LensHub__factory, MockProfileCreationProxy__factory } from '../typechain-types';
import { CreateProfileDataStruct } from '../typechain-types/LensHub';
import { waitForTx, ZERO_ADDRESS } from '../tasks/helpers/utils';

task('create-profile', 'creates a profile').setAction(async ({}, hre) => {
  //const provider = new hre.ethers.providers.JsonRpcProvider(String(process.env.MUMBAI_RPC_URL));
  //const user = new hre.ethers.Wallet(String(process.env.USER_PRIVATE_KEY), provider);

  const accounts = await hre.ethers.getSigners();
  const user = accounts[0];

  console.log(`User address: ${user.address}`);

  const lensHub_proxy = '0x60Ae865ee4C725cd04353b5AAb364553f56ceF82';
  const mock_profile_creation_proxy = '0x420f0257D43145bb002E69B14FF2Eb9630Fc4736';
  const lensHub = LensHub__factory.connect(lensHub_proxy, user);
  const profileCreation = MockProfileCreationProxy__factory.connect(
    mock_profile_creation_proxy,
    user
  );

  const inputStruct: CreateProfileDataStruct = {
    to: user.address,
    handle: 'lenscarbon',
    imageURI: 'https://ipfs.io/ipfs/QmY9dUwYu67puaWBMxRKW98LPbXCznPwHUbhX5NeWnCJbX',
    followModule: ZERO_ADDRESS,
    followModuleInitData: [],
    followNFTURI: 'https://ipfs.io/ipfs/QmTFLSXdEQ6qsSzaXaCSNtiv6wA56qq87ytXJ182dXDQJS',
  };

//   await waitForTx(profileCreation.proxyCreateProfile(inputStruct, { gasLimit: 20000000, gasPrice: 2000000000 }));

  const profileID = await lensHub.getProfileIdByHandle('lenscarbon.test');
  console.log(`Total supply: ${await lensHub.totalSupply()}`);
  console.log(`ProfileID by handle: ${profileID}`);

  console.log(
    `Profile owner: ${await lensHub.ownerOf(profileID)}, user address (should be the same): ${
      user.address
    }`
  );
});