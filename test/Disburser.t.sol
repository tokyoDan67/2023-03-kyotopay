// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title Disburser Tests
/// Version 1.1

import "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {Events} from "../src/libraries/Events.sol";
import {Fork} from "./reference/Fork.sol";
import {Helper} from "./reference/Helper.sol";
import {IWETH9} from "../src/interfaces/IWETH9.sol";
import {KyotoHub} from "../src/KyotoHub.sol";
import {Disburser} from "../src/Disburser.sol";
import {MockERC20} from "./reference/MockERC20.sol";

//////////////////////////////////////////////////////////////////
//      If you're unfamiliar with Foundry best practices,       //
//      read the following documentation before procceeding:    //
//      https://book.getfoundry.sh/tutorials/best-practices     //
//////////////////////////////////////////////////////////////////


// Harness contract for internal functions
contract DisburserHarness is Disburser {
    constructor(uint256 _fee, address _hub, address _uniswapSwapRouterAddress, address _wethAddress)
        Disburser(_fee, _hub, _uniswapSwapRouterAddress, _wethAddress)
    {}

    function validatePreferences(DataTypes.Preferences memory _preferences) external view returns (bool) {
        return _validatePreferences(_preferences);
    }

    function getSenderFunds(address _tokenAddress, uint256 _amountIn) external {
        _getSenderFunds(_tokenAddress, _amountIn);
    }

    function sendRecipientFunds(address _tokenAddress, address _recipient, uint256 _amount) external {
        _sendRecipientFunds(_tokenAddress, _recipient, _amount);
    }
}


contract Constructor is Test, Helper {
    address kyotoHubAddress;
    Disburser disburser;

    function setUp() public {
        kyotoHubAddress = address(new KyotoHub());
    }

    function testConstructor_RevertIf_InvalidAdminFee() public {
        uint256 _invalidAdminFee = 600;
        vm.expectRevert(Errors.InvalidAdminFee.selector);
        disburser = new Disburser(_invalidAdminFee, kyotoHubAddress, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
    }

    function testConstructor_RevertIf_UniswapRouterZeroAddress() public {
        uint256 _validAdminFee = 100;
        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser = new Disburser(_validAdminFee, kyotoHubAddress, address(0), WETH_ADDRESS);
    }

    function test_RevertIf_WethZeroAddress() public {
        uint256 _validAdminFee = 100;
        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser = new Disburser(_validAdminFee, kyotoHubAddress, UNISWAP_SWAPROUTER_ADDRESS, address(0));
    }

    function testConstructor_ValidParams() public {
        disburser = new Disburser(FEE, kyotoHubAddress, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);

        assertEq(disburser.adminFee(), FEE);
        assertEq(disburser.UNISWAP_SWAP_ROUTER_ADDRESS(), UNISWAP_SWAPROUTER_ADDRESS);
        assertEq(address(disburser.KYOTO_HUB()), kyotoHubAddress);
    }
}

contract Admin is Test, Helper {
    using SafeERC20 for ERC20;

    Disburser disburser;
    KyotoHub kyotoHub;
    address mockERC20;

    function setUp() public {
        kyotoHub = new KyotoHub();
        disburser = new Disburser(FEE, address(kyotoHub), UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
        mockERC20 = address(new MockERC20());
        kyotoHub.addToInputWhitelist(mockERC20);
        kyotoHub.addToOutputWhitelist(mockERC20);
    }
    function test_SetAdminFee() public {
        uint256 _validFee = 200;

        disburser.setAdminFee(_validFee);

        assertEq(disburser.adminFee(), _validFee);
    }

    function test_SetAdminFee_RevertIf_GreaterThanMaxFee() public {
        uint256 _maxFee = disburser.MAX_ADMIN_FEE();

        vm.expectRevert(Errors.InvalidAdminFee.selector);
        disburser.setAdminFee(_maxFee + 1);
    }

    function test_SetAdminFee_RevertIf_NotHubOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.NotHubOwner.selector);
        disburser.setAdminFee(200);

        vm.stopPrank();
    }

    function test_Pause_RevertIf_NotHubOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Ownable: caller is not the owner");
        disburser.pause();

        vm.stopPrank();
    }

    function test_Unpause_RevertIf_NotHubOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Ownable: caller is not the owner");
        disburser.unpause();

        vm.stopPrank();
    }

    function test_Pause() public {
        disburser.pause();
    }

    function test_Unpause() public {
        disburser.pause();
        disburser.unpause();
    }
}

contract InternalFunctions is Test, Helper {
    using SafeERC20 for ERC20;

    KyotoHub kyotoHub;
    DisburserHarness disburserHarness;
    ERC20 mockERC20;

    function setUp() public {
        kyotoHub = new KyotoHub();
        disburserHarness = new DisburserHarness(FEE, address(kyotoHub), UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
        mockERC20 = ERC20(new MockERC20());
        kyotoHub.addToInputWhitelist(address(mockERC20));
        kyotoHub.addToOutputWhitelist(address(mockERC20));
    }

    function _transferMockERC20(address _recipient, uint256 _amount) internal {
        mockERC20.safeTransfer(_recipient, _amount);
    }

    function test_ValidatePreferences() public {
        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: address(mockERC20), slippageAllowed: 100});

        assertTrue(disburserHarness.validatePreferences(_preferences));
    }

    function test_ValidatePreferences_RevertIf_SlippageZero() public {
        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: address(mockERC20), slippageAllowed: 0});

        assertFalse(disburserHarness.validatePreferences(_preferences));
    }

    function test_ValidatePreferences_RevertIf_TokenNotWhitelisted() public {
        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 100});

        assertFalse(disburserHarness.validatePreferences(_preferences));
    }

    function test_GetSenderFunds() public {
        uint256 _toSend = 1_000 ether;

        _transferMockERC20(RANDOM_USER, _toSend);

        assertEq(mockERC20.balanceOf(RANDOM_USER), _toSend);

        vm.startPrank(RANDOM_USER);

        mockERC20.safeApprove(address(disburserHarness), _toSend);
        disburserHarness.getSenderFunds(address(mockERC20), _toSend);

        vm.stopPrank();

        assertEq(mockERC20.balanceOf(address(disburserHarness)), _toSend);
        assertEq(mockERC20.balanceOf(RANDOM_USER), 0);
        assertEq(mockERC20.allowance(RANDOM_USER, address(disburserHarness)), 0);
    }

    function test_SendRecipientFunds() public {
        uint256 _fee = disburserHarness.adminFee();
        uint256 _decimals = disburserHarness.DECIMALS();
        uint256 _toSend = 1_000 ether;

        uint256 feePayment = (_fee * _toSend) / _decimals;

        _transferMockERC20(address(disburserHarness), _toSend);

        disburserHarness.sendRecipientFunds(address(mockERC20), RANDOM_USER, _toSend);

        assertEq(mockERC20.balanceOf(address(disburserHarness)), feePayment);
        assertEq(mockERC20.balanceOf(RANDOM_USER), (_toSend - feePayment));
    }
}

contract Withdraw is Test, Helper {
    using SafeERC20 for ERC20;

    KyotoHub kyotoHub;
    Disburser disburser;
    ERC20 mockERC20;

    uint256 _toTransfer = 10 ether;

    function setUp() public {
        kyotoHub = new KyotoHub();
        disburser = new Disburser(FEE, address(kyotoHub), UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
        mockERC20 = ERC20(new MockERC20());
    }

    function _transferMockToDisburser() internal {
        mockERC20.safeTransfer(address(disburser), _toTransfer);
        assertEq(mockERC20.balanceOf(address(disburser)), _toTransfer);
    }

    function test_Withdraw() public {
        _transferMockToDisburser();

        uint256 _adminBalanceBeforeWithdraw = mockERC20.balanceOf(address(this));

        vm.prank(ADMIN);
        disburser.withdraw(address(mockERC20), _toTransfer);
    
        uint256 _adminBalanceAfterWithdraw = mockERC20.balanceOf(address(this)); 

        assertEq(mockERC20.balanceOf(address(disburser)), 0);
        assertEq((_adminBalanceAfterWithdraw - _adminBalanceBeforeWithdraw), _toTransfer);
    }

    function test_Withdraw_RevertIfZeroBalance() public {
        vm.expectRevert(Errors.ZeroBalance.selector);
        disburser.withdraw(address(mockERC20), _toTransfer);
    }

    function test_Withdraw_RevertIf_NotOwner() public {
        vm.prank(RANDOM_USER);

        vm.expectRevert(Errors.NotHubOwner.selector);
        disburser.withdraw(address(mockERC20), _toTransfer);
    }

    function test_Withdraw_RevertIf_NotEnoughBalance() public {
        _transferMockToDisburser();

        uint256 totalBalance = mockERC20.balanceOf(address(disburser));

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        disburser.withdraw(address(mockERC20), totalBalance + 1);
    }
}

/**
 * @dev The Uniswap tests fork ETH mainnet
 */
contract Pay is Fork {
    using SafeERC20 for IERC20;

    KyotoHub kyotoHub;
    Disburser disburser;

    function setUp() public override {
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
        deal(WBTC_ADDRESS, RANDOM_USER,(10_000 * (10 ** WBTC_DECIMALS)));

        // Give RANDOM_USER 10,000,000 USDC 
        deal(USDC_ADDRESS, RANDOM_USER,(10_000_000 * (10 ** USDC_DECIMALS)));

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

    function testFork_SetUp() public {
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
        assertEq(FEE, disburser.adminFee());
        assertEq(KYOTOPAY_DECIMALS, disburser.DECIMALS());
    }

    function testFork_Pay_RevertIf_RecipientAddressZero() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser.pay(address(0), USDC_ADDRESS, 100_000_000, 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_Pay_RevertIf_InvalidUniFee() public {
        vm.startPrank(RANDOM_USER);

        uint24 _invalidUniFee = 333;

        vm.expectRevert(Errors.InvalidUniFee.selector);
        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, 100_000_000, 99_000_000, _invalidUniFee, bytes32(0));

        vm.stopPrank();
    }

    function testFork_Pay_RevertIf_Paused() public {
        disburser.pause();

        vm.expectRevert("Pausable: paused");
        disburser.pay(RANDOM_RECIPIENT, LOOKS_ADDRESS, 100_000_000, 99_000_000, 100, bytes32(0));
    }

    function testFork_Pay_RevertIf_InvalidInputToken() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidToken.selector);
        disburser.pay(RANDOM_RECIPIENT, LOOKS_ADDRESS, 100_000_000, 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_Pay_RevertIf_InvalidAmountIn() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidAmount.selector);
        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, 0, 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    function tesFork_Pay_RevertIf_InvalidAmountOut() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidAmount.selector);
        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, 100_000_000, 0, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_Pay_NotEnoughToken() public {
        vm.startPrank(RANDOM_USER);

        uint256 userUSDCBalance = USDC_CONTRACT.balanceOf(RANDOM_USER);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, (userUSDCBalance + 1), 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_Pay_InsufficcientAllowance() public {
        vm.startPrank(RANDOM_USER);

        USDC_CONTRACT.safeApprove(address(disburser), 100);

        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, 100_000_000, 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    /**
     *  Input: USDC
     *  Output: WETH
     *  Note: slippage is set to %0.01%, meaning that nearly any payment should revert
     */
    function testFork_Pay_RevertIf_InsufficcientAmountOut() public {
        // Random data
        bytes32 _data = bytes32(uint256(67));

        // Amount in is $10,000 of USDC...
        uint256 _amountIn = 10_000 * (10 ** USDC_DECIMALS);

        // Set slippage to zero...
        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: WETH_ADDRESS, slippageAllowed: uint96(KYOTOPAY_DECIMALS - 1)});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        // Defined in Fork.sol...
        (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

        // USDC uses 6 decimals
        // WETH uses 18 decimals
        // Chainlink's pricefeed uses 8 decimals
        // However: We need the calculation to end up using the WETH decimals, i.e. 10^18

        // _amountIn = USDC_Amount * 10^6
        // ethUSDCPrice = ETH_Price * 10^8
        // expectedWeth = (USDC_Amount * 10^6) * (10^8) * (10^(18-6)) / (ETH_Price * 10^8)
        // Note: the 10^8s in the nominator and denominator cancel each other out, leaving 10^(18-6) * 10^6 which is just 10^18

        // Therefore: expectedWeth = (_amountIn) * (10^8) * (10^(18-6)) / ethUSDCPrice

        uint256 expectedWeth =
            (_amountIn * (10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS))) / uint256(ethUSDCPrice);

        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Too little received");
        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, expectedWeth, 100, _data);

        vm.stopPrank();
    }

    /**
     *  Input: WETH
     *  Output: USDC
     *  Note: slippage is set to 0.01%, meaning that any sufficcient payment will revert
     *  Surpisingly, slippage ends up being less than 0.01% even at $40,000 payment
     *  Needed to up the payment amount to $48,000 to have a slippage >0.01%
     */
    function testFork_PayEth_RevertIf_InsufficcientAmountOut() public {
        // Random data
        bytes32 _data = bytes32(uint256(67));

        // Amount in is ~$48,000 of ether...
        uint256 _amountIn = 30 ether;

        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: uint96(KYOTOPAY_DECIMALS - 1)});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        // Defined in Fork.sol...
        (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

        // USDC uses 6 decimals
        // WETH uses 18 decimals
        // Chainlink's pricefeed uses 8 decimals
        // However: We need the calculation to end up using the USDC decimals, i.e. 10^6

        // _amountIn = WETH_Amount * 10^18
        // ethUSDCPrice = ETH_Price * 10^8
        // expectedUSDC = (WETH_Amount * 10^18) * ((ETH_Price * 10^8) * (10**(6-18))) / (10^8)
        // Algebraically, 10**(6-18) in the numerator can be made 10**(18-6) in the denominator
        // Note: the 10^8s cancel each other out in the numberator and denominator, leaving (10^18)/(10^(18-6)), which is just 10^6

        // Therefore: expectedUSDC = (_amountIn * ethUSDCPrice) / ((10^8) * (10^(18-6)))

        uint256 expectedUSDC =
            (_amountIn * uint256(ethUSDCPrice)) / ((10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS)));

        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Too little received");
        disburser.payEth{value: _amountIn}(RANDOM_RECIPIENT, expectedUSDC, 100, _data);

        vm.stopPrank();
    }

    function testFork_PayETH_RevertIf_Paused() public {
        disburser.pause();

        vm.expectRevert("Pausable: paused");
        disburser.payEth{value: 1 ether}(RANDOM_RECIPIENT, 99_000_000, 100, bytes32(0));
    }

    function testFork_PayETH_RevertIf_RecipientAddressZero() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser.payEth{value: 1 ether}(address(0), 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_WrongUniFee() public {
        vm.startPrank(RANDOM_USER);

        uint24 _invalidUniFee = 333;

        vm.expectRevert(Errors.InvalidUniFee.selector);
        disburser.payEth{value: 1 ether}(RANDOM_RECIPIENT, 99_000_000, _invalidUniFee, bytes32(0));

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_InvalidInputToken() public {
        kyotoHub.revokeFromInputWhitelist(WETH_ADDRESS);

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidToken.selector);
        disburser.payEth{value: 1 ether}(RANDOM_RECIPIENT, 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_InvalidAmountIn() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidAmount.selector);
        disburser.payEth{value: 0}(RANDOM_RECIPIENT, 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_InvalidAmountOut() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidAmount.selector);
        disburser.payEth{value: 1 ether}(RANDOM_RECIPIENT, 0, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_NotEnoughETH() public {
        vm.startPrank(RANDOM_USER);

        uint256 userETHBalance = RANDOM_USER.balance;

        vm.expectRevert();
        disburser.payEth{value: (userETHBalance + 1)}(RANDOM_RECIPIENT, 99_000_000, 100, bytes32(0));

        vm.stopPrank();
    }

    function testFork_Pay_NoPreferenceSet() public {
        bytes32 _data = bytes32(uint256(67));
        uint256 _amountIn = 100_000_000;

        DataTypes.Preferences memory _recipientPreferences  = kyotoHub.getRecipientPreferences(RANDOM_RECIPIENT);
        assertEq(_recipientPreferences.tokenAddress, address(0));
        assertEq(_recipientPreferences.slippageAllowed, uint96(0));

        (uint256 userUSDCBalanceBefore, uint256 recipientUSDCBalanceBefore, uint256 disburserUSDCBalanceBefore) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(disburser));

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, _data);

        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, 99_000_000, 100, _data);

        vm.stopPrank();

        (uint256 userUSDCBalanceAfter, uint256 recipientUSDCBalanceAfter, uint256 disburserUSDCBalanceAfter) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(disburser));

        uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

        /**
         * Assert admin fee and recipientPayment are correct given logic...
         */
        assertEq(adminFee, 1_000_000);
        assertEq(recipientPayment, 99_000_000);

        assertEq((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment);
        assertEq((userUSDCBalanceBefore - userUSDCBalanceAfter), _amountIn);
        assertEq((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee);
    }

    function testFork_Pay_PreferenceSetSameInputAndOutput() public {
        bytes32 _data = bytes32(uint256(67));
        uint256 _amountIn = 100_000_000;

        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 9_900});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        DataTypes.Preferences memory _recipientPreferences = kyotoHub.getRecipientPreferences(RANDOM_RECIPIENT);
        assertEq(_recipientPreferences.tokenAddress, USDC_ADDRESS);
        assertEq(_recipientPreferences.slippageAllowed, 9_900);

        (uint256 userUSDCBalanceBefore, uint256 recipientUSDCBalanceBefore, uint256 disburserUSDCBalanceBefore) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(disburser));

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, _data);

        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, 99_000_000, 100, _data);

        vm.stopPrank();

        (uint256 userUSDCBalanceAfter, uint256 recipientUSDCBalanceAfter, uint256 disburserUSDCBalanceAfter) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(disburser));

        uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

        /**
         * Assert admin fee and recipientPayment are correct given logic...
         */
        assertEq(adminFee, 1_000_000);
        assertEq(recipientPayment, 99_000_000);

        assertEq((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment);
        assertEq((userUSDCBalanceBefore - userUSDCBalanceAfter), _amountIn);
        assertEq((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee);
    }

    function testFork_Pay_PreferenceInputUsdcAndOutputWeth() public {
        // Random data
        bytes32 _data = bytes32(uint256(67));

        // Amount in is $10,000 of USDC...
        uint256 _amountIn = 10_000 * (10 ** USDC_DECIMALS);

        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: WETH_ADDRESS, slippageAllowed: 9_900});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        /**
         * Store before balances...
         */
        (uint256 recipientWethBalanceBefore, uint256 disburserWethBalanceBefore,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 userUSDCBalanceBefore = USDC_CONTRACT.balanceOf(RANDOM_USER);

        // Defined in Fork.sol...
        (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

        // USDC uses 6 decimals
        // WETH uses 18 decimals
        // Chainlink's pricefeed uses 8 decimals
        // However: We need the calculation to end up using the WETH decimals, i.e. 10^18

        // _amountIn = USDC_Amount * 10^6
        // ethUSDCPrice = ETH_Price * 10^8
        // expectedWeth = (USDC_Amount * 10^6) * (10^8) * (10^(18-6)) / (ETH_Price * 10^8)
        // Note: the 10^8s in the nominator and denominator cancel each other out, leaving 10^(18-6) * 10^6 which is just 10^18

        // Therefore: expectedWeth = (_amountIn) * (10^8) * (10^(18-6)) / ethUSDCPrice

        uint256 expectedWeth =
            (_amountIn * (10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS))) / uint256(ethUSDCPrice);

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, _data);

        // Correct fee for this pool is 0.05%, which is 500...
        disburser.pay(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, expectedWeth, 500, _data);

        vm.stopPrank();

        (uint256 recipientWethBalanceAfter, uint256 disburserWethBalanceAfter,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 userUSDCBalanceAfter = USDC_CONTRACT.balanceOf(RANDOM_USER);

        uint256 adminFee = (expectedWeth * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = expectedWeth - adminFee;

        assertEq((userUSDCBalanceBefore - userUSDCBalanceAfter), _amountIn);

        // Approximately equal within 0.25%.
        assertApproxEqRel((recipientWethBalanceAfter - recipientWethBalanceBefore), recipientPayment, 0.0025e18);
        assertApproxEqRel((disburserWethBalanceAfter - disburserWethBalanceBefore), adminFee, 0.0025e18);
    }

    function testFork_Pay_PreferenceInputWbtcAndOutputUSDC() public {
        // Amount in is ~$22,000 of WBTC
        uint256 _amountIn = 1 * (10 ** WBTC_DECIMALS);

        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 9_800});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        /**
         * Store before balances...
         */
        (uint256 recipientUSDCBalanceBefore, uint256 disburserUSDCBalanceBefore,) =
            getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 userWbtcBalanceBefore = WBTC_CONTRACT.balanceOf(RANDOM_USER);

        // Defined in Fork.sol...
        (int256 btcUSDCPrice, uint8 btcUSDCDecimals) = getBtcToUSDCPriceAndDecimals();

        // Unlike WETH and ETH, WBTC and BTC don't trade in parity...
        (int256 wbtcBtcConversionRate, uint8 wbtcBtcConversionDecimals) = getWbtcToBtcConversionRateAndDecimals();

        // WBTC uses 8 decimals
        // USDC uses 6 decimals
        // Chainlink's pricefeeds uses 8 decimals
        // However: We need the calculation to end up using the USDC decimals, i.e. 10^6

        // _amountIn = WBTC_Amount * 10^8
        // btcUSDCPrice = BTC_Price * 10^8
        // wbtcBtcConversionRate = Conversion_Rate * 10^8
        // expectedUSDC = (WBTC_Amount * 10^8) * (Conversion_Rate * 10^8) * (btcUSDPrice * 10^8) * (10^(6-8)) / (10^8) * 10(^8)
        // Algebraically, 10^(6-8) in the numerator is the same as 10^(8-6) in the denominator
        // Note: the 10^8s in the nominator and denominator cancel each other out, leaving 10^(18-6) * 10^6 which is just 10^18

        // Therefore: expectedUSDC = _amountIn * wbtcBtcConversionRate * btcUSDCPrice) / (10(8-6) * (10^8) * 10(^8))

        uint256 expectedUSDC = (_amountIn * uint256(wbtcBtcConversionRate) * uint256(btcUSDCPrice))
            / ((10 ** (WBTC_DECIMALS - USDC_DECIMALS)) * (10 ** btcUSDCDecimals) * (10 ** wbtcBtcConversionDecimals));

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, WBTC_ADDRESS, _amountIn, bytes32(uint256(0)));

        // Correct fee for this pool is 0.3%, which is 3000...
        disburser.pay(RANDOM_RECIPIENT, WBTC_ADDRESS, _amountIn, expectedUSDC, 3000, bytes32(uint256(0)));

        vm.stopPrank();

        (uint256 recipientUSDCBalanceAfter, uint256 disburserUSDCBalanceAfter,) =
            getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 userWbtcBalanceAfter = WBTC_CONTRACT.balanceOf(RANDOM_USER);
        uint256 adminFee = (expectedUSDC * FEE) / KYOTOPAY_DECIMALS;

        assertEq((userWbtcBalanceBefore - userWbtcBalanceAfter), _amountIn);

        // Approximately equal within 0.50%
        // recipientPayment = expectedUSDC - adminFee
        assertApproxEqRel((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), (expectedUSDC - adminFee), 0.005e18);
        assertApproxEqRel((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee, 0.005e18);
    }

    function testFork_PayEth_NoPreferencesSet() public {
        bytes32 _data = bytes32(uint256(67));
        uint256 _amountIn = 10 ether;

        DataTypes.Preferences memory _recipientPreferences = kyotoHub.getRecipientPreferences(RANDOM_RECIPIENT);
        assertEq(_recipientPreferences.tokenAddress, address(0));
        assertEq(_recipientPreferences.slippageAllowed, uint96(0));

        uint256 userEthBalanceBefore = RANDOM_USER.balance;

        (uint256 recipientWethBalanceBefore, uint256 disburserWethBalanceBefore,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, WETH_ADDRESS, _amountIn, _data);

        // Amount out doesn't matter here...
        disburser.payEth{value: _amountIn}(RANDOM_RECIPIENT, 99_000_000, 100, _data);

        vm.stopPrank();

        (uint256 recipientWethBalanceAfter, uint256 disburserWethBalanceAfter,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

        /**
         * Assert admin fee and recipientPayment are correct given logic...
         */
        assertEq(adminFee, 0.1 ether);
        assertEq(recipientPayment, 9.9 ether);

        assertEq((recipientWethBalanceAfter - recipientWethBalanceBefore), recipientPayment);
        assertEq((userEthBalanceBefore - RANDOM_USER.balance), _amountIn);
        assertEq((disburserWethBalanceAfter - disburserWethBalanceBefore), adminFee);
    }

    function testFork_PayEth_EthInputAndWethOutput() public {
        bytes32 _data = bytes32(uint256(67));
        uint256 _amountIn = 10 ether;

        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: WETH_ADDRESS, slippageAllowed: 9_900});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        DataTypes.Preferences memory _recipientPreferences = kyotoHub.getRecipientPreferences(RANDOM_RECIPIENT);
        assertEq(_recipientPreferences.tokenAddress, WETH_ADDRESS);
        assertEq(_recipientPreferences.slippageAllowed, 9_900);

        uint256 userETHBalanceBefore = RANDOM_USER.balance;

        (uint256 recipientWethBalanceBefore, uint256 disburserWethBalanceBefore,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, WETH_ADDRESS, _amountIn, _data);

        // Amount out doesn't matter here...
        disburser.payEth{value: _amountIn}(RANDOM_RECIPIENT, 99_000_000, 100, _data);

        vm.stopPrank();

        (uint256 recipientWethBalanceAfter, uint256 disburserWethBalanceAfter,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

        /**
         * Assert admin fee and recipientPayment are correct given logic...
         */
        assertEq(adminFee, 0.1 ether);
        assertEq(recipientPayment, 9.9 ether);

        assertEq((recipientWethBalanceAfter - recipientWethBalanceBefore), recipientPayment);
        assertEq((userETHBalanceBefore - RANDOM_USER.balance), _amountIn);
        assertEq((disburserWethBalanceAfter - disburserWethBalanceBefore), adminFee);
    }

    function testFork_PayEth_UsdcOutput() public {
        // Random data
        bytes32 _data = bytes32(uint256(67));

        // Amount in is ~$16,000 of ether...
        uint256 _amountIn = 10 ether;

        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 9_900});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        /**
         * Store before balances...
         */
        (uint256 recipientUSDCBalanceBefore, uint256 disburserUSDCBalanceBefore,) =
            getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 userEthBalanceBefore = RANDOM_USER.balance;

        // Defined in Fork.sol...
        (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

        // USDC uses 6 decimals
        // WETH uses 18 decimals
        // Chainlink's pricefeed uses 8 decimals
        // However: We need the calculation to end up using the USDC decimals, i.e. 10^6

        // _amountIn = WETH_Amount * 10^18
        // ethUSDCPrice = ETH_Price * 10^8
        // expectedUSDC = (WETH_Amount * 10^18) * ((ETH_Price * 10^8) * (10**(6-18))) / (10^8)
        // Algebraically, 10**(6-18) in the numerator can be made 10**(18-6) in the denominator
        // Note: the 10^8s cancel each other out in the numberator and denominator, leaving (10^18)/(10^(18-6)), which is just 10^6

        // Therefore: expectedUSDC = (_amountIn * ethUSDCPrice) / ((10^8) * (10^(18-6)))

        uint256 expectedUSDC =
            (_amountIn * uint256(ethUSDCPrice)) / ((10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS)));

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, WETH_ADDRESS, _amountIn, _data);

        // Correct fee for this pool is 0.05%, which is 500...
        disburser.payEth{value: _amountIn}(RANDOM_RECIPIENT, expectedUSDC, 500, _data);

        vm.stopPrank();

        (uint256 recipientUSDCBalanceAfter, uint256 disburserUSDCBalanceAfter,) =
            getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 adminFee = (expectedUSDC * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = expectedUSDC - adminFee;

        assertEq((userEthBalanceBefore - RANDOM_USER.balance), _amountIn);

        // Approximately equal within 0.25%.
        assertApproxEqRel((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment, 0.0025e18);
        assertApproxEqRel((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee, 0.0025e18);
    }
}

// Will get to after demo day....
// Relatively unimportant, but good to have, especially regarding extreme values in Pay and PayEth

contract FuzzNoFork is Helper, Test {}

contract FuzzFork is Fork {
// function testForkFuzz_Pay_SameInputAndOutput() public {}

// function testForkFuzz_Pay_WbtcInputAndUsdcOutput() public {}
}
