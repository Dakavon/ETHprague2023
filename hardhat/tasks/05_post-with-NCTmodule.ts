import { task } from "hardhat/config";
import { defaultAbiCoder } from 'ethers/lib/utils';
import { PostDataStruct } from '../typechain-types/LensHub';
import { waitForTx, ZERO_ADDRESS } from '../tasks/helpers/utils';

task("postWithNCTmodule", "Publishes a post with the NCT collect module").setAction(async (taskArgs, hre) => {

    //Variables
    const accounts = await hre.ethers.getSigners();
    const user = accounts[0];

    const LENSHUB_PROXY = '0x1677d9cc4861f1c85ac7009d5f06f49c928ca2ad';
    const NCTRetireCollectModuleAddr = '0xc7Fc79a25597bae5CEE7BFca359398375a7Ab1ab';

    //Lens core
    const lensHub = await hre.ethers.getContractAt('LensHub', LENSHUB_PROXY, user);

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
});