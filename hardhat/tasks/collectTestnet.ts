import { ethers } from 'ethers';
import { task } from 'hardhat/config';
import { LensHub__factory, CollectNFT__factory } from '../typechain-types';
import { getAddrs, initEnv, waitForTx } from './helpers/utils';

task('collectTestnet', 'collects a post').setAction(async ({}, hre) => {
  const provider = new hre.ethers.providers.JsonRpcProvider(String(process.env.MUMBAI_RPC_URL));
  const user = new hre.ethers.Wallet(String(process.env.USER_PRIVATE_KEY), provider);
  const collector = new hre.ethers.Wallet(String(process.env.COLLECTOR_PRIVATE_KEY), provider);

  const lensHub_proxy = '0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5';
  const lensHub = LensHub__factory.connect(lensHub_proxy, collector);

  const profileId = await lensHub.getProfileIdByHandle('annitho.test');
  const numPost = 1;
  console.log(`ProfileId by handle: ${profileId}`);
  const tx = await lensHub.collect(profileId, ethers.BigNumber.from(numPost), [], {
    gasLimit: 1000 * 10000,
  });

  console.log(`Collected post: ${tx}`);
  const collectNFTAddr = await lensHub
    .connect(collector)
    .getCollectNFT(profileId, ethers.BigNumber.from(numPost));
  console.log(`Collected NFT address: ${collectNFTAddr}`);
  const collectNFT = CollectNFT__factory.connect(collectNFTAddr, user);

  const publicationContentURI = await lensHub.getContentURI(profileId, numPost);
  const totalSupply = await collectNFT.totalSupply();
  const ownerOf = await collectNFT.ownerOf(numPost);
  const collectNFTURI = await collectNFT.tokenURI(numPost);

  console.log(`Collect NFT total supply (should be 1): ${totalSupply}`);
  console.log(
    `Collect NFT owner of ID 1: ${ownerOf}, user address (should be the same): ${user.address}`
  );
  console.log(
    `Collect NFT URI: ${collectNFTURI}, publication content URI (should be the same): ${publicationContentURI}`
  );
});
