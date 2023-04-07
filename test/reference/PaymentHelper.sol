// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "../../src/interfaces/IWETH9.sol";
import {Disburser} from "../../src/Disburser.sol";
import {KyotoHub} from "../../src/KyotoHub.sol";
import {Fork} from "./Fork.sol";

/**
 * @dev Sets up KyotoHub and Disburser for payment tests.  Deals tokens to RANDOM_USER for tests.  
 * Sets max approvals by RANDOM_USER to the Disburser and KyotoPay contract
 */

abstract contract PaymentHelper is Fork {
    using SafeERC20 for IERC20;
    
    KyotoHub kyotoHub;
    Disburser disburser;

    function setUp() public virtual override {

        // Call Fork setup
        Fork.setUp();

        // mainnetForkId is defined in reference/Fork.sol
        mainnetForkId = vm.createSelectFork(MAINNET_RPC_URL, MAINNET_FORK_BLOCK);
        kyotoHub = new KyotoHub();
        disburser = new Disburser(FEE, address(kyotoHub), UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);

        /**
         * Add inputs
         */
        kyotoHub.addToInputWhitelist(WBTC_ADDRESS);
        kyotoHub.addToInputWhitelist(WETH_ADDRESS);
        kyotoHub.addToInputWhitelist(DAI_ADDRESS);
        kyotoHub.addToInputWhitelist(USDC_ADDRESS);

        /**
         * Add outputs
         */
        kyotoHub.addToOutputWhitelist(DAI_ADDRESS);
        kyotoHub.addToOutputWhitelist(USDC_ADDRESS);
        kyotoHub.addToOutputWhitelist(WETH_ADDRESS);

        /**
         * Give RANDOM_USER DAI, USDC, ETH, WBTC, and WETH
         */

        // Give RANDOM_USER 10,000,000 DAI
        deal(DAI_ADDRESS, RANDOM_USER, (10_000_000 * (10 ** DAI_DECIMALS)));

        // Give RANDOM_USER 10,000 WBTC
        deal(WBTC_ADDRESS, RANDOM_USER, (10_000 * (10 ** WBTC_DECIMALS)));

        // Give RANDOM_USER 10,000,000 USDC
        deal(USDC_ADDRESS, RANDOM_USER, (10_000_000 * (10 ** USDC_DECIMALS)));

        // Give RANDOM_USER 20,000 WETH
        vm.deal(RANDOM_USER, 20_000 ether);
        vm.startPrank(RANDOM_USER);
        IWETH9(WETH_ADDRESS).deposit{value: 10_000 ether}();

        /**
         *  Set allowances to type(uint256).max
         *  msg.sender is RANDOM_USER from startPrank() above
         */
        DAI_CONTRACT.safeApprove(address(disburser), type(uint256).max);
        USDC_CONTRACT.safeApprove(address(disburser), type(uint256).max);
        WETH_CONTRACT.safeApprove(address(disburser), type(uint256).max);
        WBTC_CONTRACT.safeApprove(address(disburser), type(uint256).max);

        vm.stopPrank();
    }
}

contract SetUpTest is PaymentHelper {

    function setUp() public override {
        PaymentHelper.setUp();
    }

    function test_SetUp() public {
        /**
         * Verify inputs
         */
        assertTrue(kyotoHub.isWhitelistedInputToken(WBTC_ADDRESS));
        assertTrue(kyotoHub.isWhitelistedInputToken(WETH_ADDRESS));
        assertTrue(kyotoHub.isWhitelistedInputToken(DAI_ADDRESS));
        assertTrue(kyotoHub.isWhitelistedInputToken(USDC_ADDRESS));

        /**
         * Verify outputs
         */
        assertTrue(kyotoHub.isWhitelistedOutputToken(WETH_ADDRESS));
        assertTrue(kyotoHub.isWhitelistedOutputToken(DAI_ADDRESS));
        assertTrue(kyotoHub.isWhitelistedOutputToken(USDC_ADDRESS));

        /**
         * Verify balances
         */
        assertEq(DAI_CONTRACT.balanceOf(RANDOM_USER), 10_000_000 * (10 ** DAI_DECIMALS));
        assertEq(USDC_CONTRACT.balanceOf(RANDOM_USER), 10_000_000 * (10 ** USDC_DECIMALS));
        assertEq(WETH_CONTRACT.balanceOf(RANDOM_USER), 10_000 ether);
        assertEq(WBTC_CONTRACT.balanceOf(RANDOM_USER), 10_000 * (10 ** WBTC_DECIMALS));
        assertEq(RANDOM_USER.balance, 10_000 ether);

        /**
         * Verify allowances
         */
        assertEq(DAI_CONTRACT.allowance(RANDOM_USER, address(disburser)), type(uint256).max);
        assertEq(USDC_CONTRACT.allowance(RANDOM_USER, address(disburser)), type(uint256).max);
        assertEq(WBTC_CONTRACT.allowance(RANDOM_USER, address(disburser)), type(uint256).max);
        assertEq(WETH_CONTRACT.allowance(RANDOM_USER, address(disburser)), type(uint256).max);

        /**
         * Verify constants in Helper
         */
        assertEq(FEE, disburser.getAdminFee());
        assertEq(KYOTOPAY_DECIMALS, disburser.PRECISION_FACTOR());
    }
}