import { ethers } from 'hardhat';

async function main() {
  const LENSHUB_PROXY = '0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5'; //sandbox mumbai testnet
  const MODULE_GLOBALS = '0xcbCC5b9611d22d11403373432642Df9Ef7Dd81AD'; //sandbox mumbai testnet
  const TOUCAN_OFFSET_HELPER = '0x30dC279166DCFB69F52C91d6A3380dCa75D0fCa7';
  const NATURE_CARBON_TONNE = '0x7beCBA11618Ca63Ead5605DE235f6dD3b25c530E';
  const NCTRetireCollectModule = await ethers.getContractFactory('NCTRetireCollectModule');
  const NCTModule = await NCTRetireCollectModule.deploy(
    LENSHUB_PROXY,
    MODULE_GLOBALS,
    NATURE_CARBON_TONNE,
    TOUCAN_OFFSET_HELPER
  );

  await NCTModule.deployed();

  console.log(`Deployed Contract to ${NCTModule.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
