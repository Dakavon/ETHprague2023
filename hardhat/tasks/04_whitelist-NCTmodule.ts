import { task } from "hardhat/config";

task("whitelistNCTmodule", "Whitelist NCT retire module").setAction(async (taskArgs, hre) => {
    //Variables
    const accounts = await hre.ethers.getSigners();
    const governance = accounts[0];

    const MOCKSANDBOX_GOVERNANCE = "0x1677d9cc4861f1c85ac7009d5f06f49c928ca2ad"; //sandbox mumbai testnet
    const NCTRetireCollectModuleAddr = '0xc7Fc79a25597bae5CEE7BFca359398375a7Ab1ab'; //deployed on sandbox mumbai testnet

    //Lens core
    const lensHub = await hre.ethers.getContractAt('LensHub', MOCKSANDBOX_GOVERNANCE, governance);

    //Execution
    await lensHub.whitelistCollectModule(NCTRetireCollectModuleAddr, true);

    console.log(`Module whitelisted.`);
});