// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import {StepwiseCollectModule} from 'contracts/collect/StepwiseCollectModule.sol';
import {MultirecipientFeeCollectModule} from 'contracts/collect/MultirecipientFeeCollectModule.sol';
import {AaveFeeCollectModule} from 'contracts/collect/AaveFeeCollectModule.sol';
import {ERC4626FeeCollectModule} from 'contracts/collect/ERC4626FeeCollectModule.sol';
import {PartialCarbonRetirementCollectModule} from 'contracts/collect/PartialCarbonRetirementCollectModule.sol';
import {V3PartialCarbonRetirementCollectModule} from 'contracts/collect/V3PartialCarbonRetirementCollectModule.sol';
import {TokenGatedReferenceModule} from 'contracts/reference/TokenGatedReferenceModule.sol';
import {ForkManagement} from 'script/helpers/ForkManagement.sol';

contract DeployBase is Script, ForkManagement {
    using stdJson for string;

    uint256 deployerPrivateKey;
    address deployer;
    address lensHubProxy;
    address moduleGlobals;

    function loadBaseAddresses(string memory json, string memory targetEnv) internal virtual {
        lensHubProxy = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        moduleGlobals = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.ModuleGlobals'))
        );
    }

    function loadPrivateKeys() internal {
        string memory mnemonic = vm.envString('MNEMONIC');

        if (bytes(mnemonic).length > 0) {
            (deployer, deployerPrivateKey) = deriveRememberKey(mnemonic, 0);
        } else {
            deployerPrivateKey = vm.envUint('PRIVATE_KEY');
            deployer = vm.addr(deployerPrivateKey);
        }

        console.log('\nDeployer address:', deployer);
        console.log('Deployer balance:', deployer.balance);
    }

    function run(string calldata targetEnv) external {
        string memory json = loadJson();
        checkNetworkParams(json, targetEnv);
        loadBaseAddresses(json, targetEnv);
        loadPrivateKeys();

        address module = deploy();
        console.log('New Deployment Address:', address(module));
    }

    function deploy() internal virtual returns (address) {}
}

contract DeployStepwiseCollectModule is DeployBase {
    function deploy() internal override returns (address) {
        console.log('\nContract: StepwiseCollectModule');
        console.log('Init params:');
        console.log('\tLensHubProxy:', lensHubProxy);
        console.log('\tModuleGlobals:', moduleGlobals);

        vm.startBroadcast(deployerPrivateKey);
        StepwiseCollectModule stepwiseCollectModule = new StepwiseCollectModule(
            lensHubProxy,
            moduleGlobals
        );
        vm.stopBroadcast();

        console.log('Constructor arguments:');
        console.logBytes(abi.encode(lensHubProxy, moduleGlobals));

        return address(stepwiseCollectModule);
    }
}

contract DeployMultirecipientFeeCollectModule is DeployBase {
    function deploy() internal override returns (address) {
        console.log('\nContract: MultirecipientFeeCollectModule');
        console.log('Init params:');
        console.log('\tLensHubProxy:', lensHubProxy);
        console.log('\tModuleGlobals:', moduleGlobals);

        vm.startBroadcast(deployerPrivateKey);
        MultirecipientFeeCollectModule module = new MultirecipientFeeCollectModule(
            lensHubProxy,
            moduleGlobals
        );
        vm.stopBroadcast();

        console.log('Constructor arguments:');
        console.logBytes(abi.encode(lensHubProxy, moduleGlobals));

        return address(module);
    }
}

import {IPoolAddressesProvider} from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';

contract DeployAaveFeeCollectModule is DeployBase {
    using stdJson for string;
    address poolAddressesProvider;

    function loadBaseAddresses(string memory json, string memory targetEnv) internal override {
        super.loadBaseAddresses(json, targetEnv);
        poolAddressesProvider = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.PoolAddressesProvider'))
        );
    }

    function deploy() internal override returns (address) {
        console.log('\nContract: AaveFeeCollectModule');
        console.log('Init params:');
        console.log('\tLensHubProxy:', lensHubProxy);
        console.log('\tModuleGlobals:', moduleGlobals);
        console.log('\tPoolAddressesProvider:', poolAddressesProvider);

        vm.startBroadcast(deployerPrivateKey);
        AaveFeeCollectModule module = new AaveFeeCollectModule(
            lensHubProxy,
            moduleGlobals,
            IPoolAddressesProvider(poolAddressesProvider)
        );
        vm.stopBroadcast();

        console.log('Constructor arguments:');
        console.logBytes(
            abi.encode(lensHubProxy, moduleGlobals, IPoolAddressesProvider(poolAddressesProvider))
        );

        return address(module);
    }
}

contract DeployPartialCarbonRetirementCollectModule is DeployBase {
    using stdJson for string;

    address retirementHelper = 0x802fd78B14bF8d0cc0Ba0325351887a323432B70; // Klima RetirementAggregatorV1 mainnet

    function deploy() internal override returns (address) {
        console.log('\nContract: PartialCarbonRetirementCollectModule');
        console.log('Init params:');
        console.log('\tLensHubProxy:', lensHubProxy);
        console.log('\tModuleGlobals:', moduleGlobals);
        console.log('\tRetirementHelper:', retirementHelper);

        vm.startBroadcast(deployerPrivateKey);
        PartialCarbonRetirementCollectModule module = new PartialCarbonRetirementCollectModule(
            lensHubProxy,
            moduleGlobals,
            retirementHelper
        );
        vm.stopBroadcast();

        console.log('Constructor arguments:');
        console.logBytes(
            abi.encode(lensHubProxy, moduleGlobals, retirementHelper)
        );

        return address(module);
    }
}

contract DeployV3PartialCarbonRetirementCollectModule is DeployBase {
    using stdJson for string;

    address retirementHelper = 0x8cE54d9625371fb2a068986d32C85De8E6e995f8; // Klima KlimaInfinity/RetirementAggregatorV2 mainnet
    function deploy() internal override returns (address) {
        console.log('\nContract: V3PartialCarbonRetirementCollectModule');
        console.log('Init params:');
        console.log('\tLensHubProxy:', lensHubProxy);
        console.log('\tModuleGlobals:', moduleGlobals);
        console.log('\tRetirementHelper:', retirementHelper);

        vm.startBroadcast(deployerPrivateKey);
        V3PartialCarbonRetirementCollectModule module = new V3PartialCarbonRetirementCollectModule(
            lensHubProxy,
            moduleGlobals,
            retirementHelper
        );
        vm.stopBroadcast();

        console.log('Constructor arguments:');
        console.logBytes(
            abi.encode(lensHubProxy, moduleGlobals, retirementHelper)
        );

        return address(module);
    }
}

contract DeployERC4626FeeCollectModule is DeployBase {
    function deploy() internal override returns (address) {
        console.log('\nContract: ERC4626FeeCollectModule');
        console.log('Init params:');
        console.log('\tLensHubProxy:', lensHubProxy);
        console.log('\tModuleGlobals:', moduleGlobals);

        vm.startBroadcast(deployerPrivateKey);
        ERC4626FeeCollectModule module = new ERC4626FeeCollectModule(lensHubProxy, moduleGlobals);
        vm.stopBroadcast();

        console.log('Constructor arguments:');
        console.logBytes(abi.encode(lensHubProxy, moduleGlobals));

        return address(module);
    }
}

contract DeployTokenGatedReferenceModule is DeployBase {
    function deploy() internal override returns (address) {
        console.log('\nContract: TokenGatedReferenceModule');
        console.log('Init params:');
        console.log('\tLensHubProxy:', lensHubProxy);

        vm.startBroadcast(deployerPrivateKey);
        TokenGatedReferenceModule module = new TokenGatedReferenceModule(lensHubProxy);
        vm.stopBroadcast();

        console.log('Constructor arguments:');
        console.logBytes(abi.encode(lensHubProxy));

        return address(module);
    }
}
