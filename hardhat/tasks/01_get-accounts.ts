import { task } from 'hardhat/config';

task('get-accounts', 'get accounts').setAction(async ({}, hre) => {

    const accounts = await hre.ethers.getSigners();

    for (let i = 0; i < accounts.length; i++) {
        console.log(`Account ${i}: ${accounts[i].address}`);
    }

});