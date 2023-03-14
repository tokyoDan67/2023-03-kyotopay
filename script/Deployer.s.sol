// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "forge-std/Script.sol";
import {Payer} from "../src/Payer.sol";
import {Constants} from "./reference/Constants.s.sol";

// contract Deployer is Script, Constants {

//     uint256 constant ETH_CHAIN_ID = 1;
//     uint256 constant GOERLI_CHAIN_ID = 5;

//     address uniswapRouterAddress;
//     address wethAddress;
//     address usdcAddress;
//     address usdtAddress;
//     address multisigAddress; 
//     KyotoPay public kyotoPay;


//     function _setUp() internal {
//         if (block.chainid == ETH_CHAIN_ID) { 
//             uniswapRouterAddress = UNISWAP_ROUTER_ADDRESS_MAINNET;
//             wethAddress = WETH_ADDRESS_MAINNET;
//             usdcAddress = USDC_ADDRESS_MAINNET;
//             usdtAddress = USDT_ADDRESS_MAINNET;
//             multisigAddress = MAINNET_MULTISIG;
//         }
//         else if (block.chainid == GOERLI_CHAIN_ID) { 
//             uniswapRouterAddress = UNISWAP_ROUTER_ADDRESS_GOERLI;
//             wethAddress = WETH_ADDRESS_GOERLI; 
//             usdcAddress = USDC_ADDRESS_GOERLI;
//             usdtAddress = USDT_ADDRESS_GOERLI;
//             // No multisig on Goerli...
//             multisigAddress = GOERLI_EOA;
//         }
//         else {
//             revert("Unsupported chain");
//         }
//     }

//     function run() external {
//         _setUp();
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);
    
//         kyotoPay = new KyotoPay(100, uniswapRouterAddress, wethAddress);

//         /**
//          * Adding inputs...
//          */
//         kyotoPay.addToInputWhitelist(usdcAddress);
//         kyotoPay.addToInputWhitelist(usdtAddress);
//         kyotoPay.addToInputWhitelist(wethAddress);

//         /**
//          * Adding outputs
//          */
//         kyotoPay.addToOutputWhitelist(usdcAddress);
//         kyotoPay.addToOutputWhitelist(usdtAddress);
//         kyotoPay.addToOutputWhitelist(wethAddress);
        
//         kyotoPay.transferOwnership(multisigAddress);

//         vm.stopBroadcast();
//     }
// }
