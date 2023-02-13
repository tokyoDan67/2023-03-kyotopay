// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Deployer} from "../script/Deployer.s.sol";
import {Constants} from "../script/reference/Constants.s.sol";
import {KyotoPay} from "../src/KyotoPay.sol";
import {IKyotoPay} from "../src/interfaces/IKyotoPay.sol";
import {Fork} from "./reference/Fork.sol";
contract DeployerTest is Test, Fork, Constants {

    Deployer deployer;

    function testFork_DeploymentMainnet() public {
        vm.createSelectFork(MAINNET_RPC_URL, MAINNET_FORK_BLOCK);

        deployer = new Deployer();
        deployer.run();

        KyotoPay _kyotoPay = KyotoPay(deployer.kyotoPay());

        assertEq(_kyotoPay.uniswapSwapRouterAddress(), UNISWAP_ROUTER_ADDRESS_MAINNET);
        assertEq(_kyotoPay.wethAddress(), WETH_ADDRESS_MAINNET);
        
        assertTrue(_kyotoPay.whitelistedInputTokens(USDC_ADDRESS_MAINNET));
        assertTrue(_kyotoPay.whitelistedInputTokens(USDT_ADDRESS_MAINNET));
        assertTrue(_kyotoPay.whitelistedInputTokens(WETH_ADDRESS_MAINNET));

        assertTrue(_kyotoPay.whitelistedOutputTokens(USDC_ADDRESS_MAINNET));
        assertTrue(_kyotoPay.whitelistedOutputTokens(USDT_ADDRESS_MAINNET));
        assertTrue(_kyotoPay.whitelistedOutputTokens(WETH_ADDRESS_MAINNET));

        assertEq(_kyotoPay.owner(), MAINNET_MULTISIG);
    }
    function testFork_DeploymentGoerli() public {
        vm.createSelectFork(GOERLI_RPC_URL, GOERLI_FORK_BLOCK);

        deployer = new Deployer();
        deployer.run();

        KyotoPay _kyotoPay = KyotoPay(deployer.kyotoPay());

        assertEq(_kyotoPay.uniswapSwapRouterAddress(), UNISWAP_ROUTER_ADDRESS_GOERLI);
        assertEq(_kyotoPay.wethAddress(), WETH_ADDRESS_GOERLI);
        
        assertTrue(_kyotoPay.whitelistedInputTokens(USDC_ADDRESS_GOERLI));
        assertTrue(_kyotoPay.whitelistedInputTokens(USDT_ADDRESS_GOERLI));
        assertTrue(_kyotoPay.whitelistedInputTokens(WETH_ADDRESS_GOERLI));

        assertTrue(_kyotoPay.whitelistedOutputTokens(USDC_ADDRESS_GOERLI));
        assertTrue(_kyotoPay.whitelistedOutputTokens(USDT_ADDRESS_GOERLI));
        assertTrue(_kyotoPay.whitelistedOutputTokens(WETH_ADDRESS_GOERLI));

        assertEq(_kyotoPay.owner(), GOERLI_EOA);
    }

    function testFork_Deployment_RevertIf_UnsupportedChain() public {
        vm.createSelectFork(POLYGON_RPC_URL, POLYGON_FORK_BLOCK);

        deployer = new Deployer();
        vm.expectRevert("Unsupported chain");
        deployer.run();
    }
}