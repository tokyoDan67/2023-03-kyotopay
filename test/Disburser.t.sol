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
import {PaymentHelper} from "./reference/PaymentHelper.sol";
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

    function sendRecipientFunds(address _recipient, address _tokenAddress, uint256 _amount, bytes32 _data) external {
        _sendRecipientFunds(_recipient, _tokenAddress,  _amount, _data);
    }
}

contract Constructor is Test, Helper {
    address kyotoHubAddress;
    Disburser disburser;

    function setUp() public {
        kyotoHubAddress = address(new KyotoHub());
    }

    function test_Constructor() public {
        disburser = new Disburser(FEE, kyotoHubAddress, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);

        assertEq(disburser.getAdminFee(), FEE);
        assertEq(disburser.UNISWAP_SWAP_ROUTER_ADDRESS(), UNISWAP_SWAPROUTER_ADDRESS);
        assertEq(disburser.WETH_ADDRESS(), WETH_ADDRESS);
        assertEq(address(disburser.KYOTO_HUB()), kyotoHubAddress);
    }

    function test_Constructor_RevertIf_KyotoHubZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser = new Disburser(FEE, address(0), UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
    }

    function test_Constructor_RevertIf_InvalidAdminFee() public {
        uint256 _invalidAdminFee = 600;
        vm.expectRevert(Errors.InvalidAdminFee.selector);
        disburser = new Disburser(_invalidAdminFee, kyotoHubAddress, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
    }

    function test_Constructor_RevertIf_UniswapRouterZeroAddress() public {
        uint256 _validAdminFee = 100;
        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser = new Disburser(_validAdminFee, kyotoHubAddress, address(0), WETH_ADDRESS);
    }

    function test_Constructor_RevertIf_WethZeroAddress() public {
        uint256 _validAdminFee = 100;
        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser = new Disburser(_validAdminFee, kyotoHubAddress, UNISWAP_SWAPROUTER_ADDRESS, address(0));
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
        assertEq(disburser.getAdminFee(), _validFee);
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

        vm.expectRevert(Errors.NotHubOwner.selector);
        disburser.pause();

        vm.stopPrank();
    }

    function test_Unpause_RevertIf_NotHubOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.NotHubOwner.selector);
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
        uint256 _fee = disburserHarness.getAdminFee();
        uint256 _decimals = disburserHarness.PRECISION_FACTOR();
        uint256 _toSend = 1_000 ether;
        bytes32 _data = keccak256(abi.encode(USDC_ADDRESS));

        uint256 feePayment = (_fee * _toSend) / _decimals;
        uint256 recipientPayment = _toSend - feePayment;

        _transferMockERC20(address(disburserHarness), _toSend);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment( RANDOM_USER, address(mockERC20), recipientPayment, _data);
        disburserHarness.sendRecipientFunds(RANDOM_USER, address(mockERC20), _toSend, _data);

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

contract PayFunctions is PaymentHelper {
    using SafeERC20 for IERC20;

    function setUp() public override {
        // Call Fork setup
        PaymentHelper.setUp();
    }

    function testFork_Pay_RevertIf_RecipientAddressZero() public {
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: address(0),
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser.pay(params);

        vm.stopPrank();
    }

    function testFork_Pay_RevertIf_InvalidUniFee() public {
        uint24 _invalidUniFee = 333;

        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: _invalidUniFee,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidUniFee.selector);
        disburser.pay(params);

        vm.stopPrank();
    }

    function testFork_Pay_RevertIf_Paused() public {
        disburser.pause();

        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Pausable: paused");
        disburser.pay(params);

        vm.stopPrank();
    }

    function testFork_Pay_RevertIf_InvalidInputToken() public {
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: LOOKS_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidToken.selector);
        disburser.pay(params);

        vm.stopPrank();
    }

    function testFork_Pay_RevertIf_InvalidAmountIn() public {
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 0,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidAmount.selector);
        disburser.pay(params);

        vm.stopPrank();
    }

    function tesFork_Pay_RevertIf_InvalidAmountOut() public {
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            amountOut: 0,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 
        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidAmount.selector);
        disburser.pay(params);

        vm.stopPrank();
    }

    function testFork_Pay_NotEnoughToken() public {
        vm.startPrank(RANDOM_USER);

        uint256 userUSDCBalance = USDC_CONTRACT.balanceOf(RANDOM_USER);

        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: (userUSDCBalance + 1),
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        });  

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        disburser.pay(params);

        vm.stopPrank();
    }

    function testFork_Pay_InsufficcientAllowance() public {
        vm.startPrank(RANDOM_USER);

        USDC_CONTRACT.safeApprove(address(disburser), 100);

        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        disburser.pay(params);

        vm.stopPrank();
    }

    /**
     *  Input: USDC
     *  Output: WETH
     *  Note: slippage is set to %0.01%, meaning that nearly any payment should revert
     */
    function testFork_Pay_RevertIf_InsufficcientAmountOut() public {
        uint256 _amountIn = 10_000 * (10 ** USDC_DECIMALS);

        // Set slippage to zero...
        DataTypes.Preferences memory preferences =
            DataTypes.Preferences({tokenAddress: WETH_ADDRESS, slippageAllowed: uint96(KYOTOPAY_DECIMALS - 1)});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(preferences);

        uint256 expectedWeth = _convertUsdcToWeth(_amountIn);

        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 500,
            amountIn: _amountIn,
            amountOut: expectedWeth,
            deadline: block.timestamp,
            data: bytes32(uint256(67))
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Too little received");
        disburser.pay(params);

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
        // Amount in is ~$1,700,000 of ether...
        uint256 _amountIn = 1_000 ether;

        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: uint96(KYOTOPAY_DECIMALS - 1)});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        uint256 expectedUSDC = _convertWethToUsdc(_amountIn);

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: 500,
            amountOut: expectedUSDC,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Too little received");
        disburser.payEth{value: _amountIn}(params);

        vm.stopPrank();
    }

    function testFork_PayETH_RevertIf_Paused() public {
        disburser.pause();

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: 100,
            amountOut: 1 ether,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Pausable: paused");
        disburser.payEth{value: 1 ether}(params);

        vm.stopPrank();
    }

    function testFork_PayETH_RevertIf_RecipientAddressZero() public {
        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: address(0),
            uniFee: 100,
            amountOut: 1 ether,
            deadline: block.timestamp,
            data: bytes32(0)
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.ZeroAddress.selector);
        disburser.payEth{value: 1 ether}(params);

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_WrongUniFee() public {
        uint24 _invalidUniFee = 333;

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: _invalidUniFee,
            amountOut: 1 ether,
            deadline: block.timestamp,
            data: bytes32(0)
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidUniFee.selector);
        disburser.payEth{value: 1 ether}(params);

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_InvalidInputToken() public {
        kyotoHub.revokeFromInputWhitelist(WETH_ADDRESS);

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: 100,
            amountOut: 1 ether,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER); 

        vm.expectRevert(Errors.InvalidToken.selector);
        disburser.payEth{value: 1 ether}(params);

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_InvalidAmountIn() public {
        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: 100,
            amountOut: 1 ether,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidAmount.selector);
        disburser.payEth{value: 0}(params);

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_InvalidAmountOut() public {
        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: 100,
            amountOut: 0,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidAmount.selector);
        disburser.payEth{value: 1 ether}(params);

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_NotEnoughETH() public {
        uint256 userETHBalance = RANDOM_USER.balance;

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: 100,
            amountOut: 1 ether,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert();
        disburser.payEth{value: (userETHBalance + 1)}(params);

        vm.stopPrank();
    }

    function testFork_Pay_RevertIf_InvalidDeadline() public {
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 3_000,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp - 1,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidDeadline.selector);
        disburser.pay(params);

        vm.stopPrank();
    }

    function testFork_PayEth_RevertIf_InvalidDeadline() public {
        uint256 _amountIn = 1 ether;

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: 100,
            amountOut: 1 ether,
            deadline: block.timestamp - 1,
            data: bytes32(0) 
        }); 

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidDeadline.selector);
        disburser.payEth{value: _amountIn}(params);

        vm.stopPrank();
    }

    function testFork_Pay_NoPreferencesSet() public {
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            // amountOut doesn't matter here...
            amountOut: 100_000_000,
            deadline: block.timestamp,
            data: bytes32(uint256(67))
        }); 

        DataTypes.Preferences memory _recipientPreferences = kyotoHub.getRecipientPreferences(RANDOM_RECIPIENT);
        assertEq(_recipientPreferences.tokenAddress, address(0));
        assertEq(_recipientPreferences.slippageAllowed, uint96(0));

        (uint256 userUSDCBalanceBefore, uint256 recipientUSDCBalanceBefore, uint256 disburserUSDCBalanceBefore) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(disburser));

        uint256 adminFee = (params.amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = params.amountIn - ((params.amountIn * FEE) / KYOTOPAY_DECIMALS);

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, USDC_ADDRESS, recipientPayment, params.data);

        disburser.pay(params);

        vm.stopPrank();

        (uint256 userUSDCBalanceAfter, uint256 recipientUSDCBalanceAfter, uint256 disburserUSDCBalanceAfter) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(disburser));

        /**
         * Assert admin fee and recipientPayment are correct given logic...
         */
        assertEq(adminFee, 1_000_000);
        assertEq(recipientPayment, 99_000_000);

        assertEq((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment);
        assertEq((userUSDCBalanceBefore - userUSDCBalanceAfter), params.amountIn);
        assertEq((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee);
    }

    function testFork_Pay_PreferenceSetSameInputAndOutput() public {
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            // amountOut doesn't matter here...
            amountOut: 100_000_000,
            deadline: block.timestamp,
            data: bytes32(uint256(67))
        }); 

        DataTypes.Preferences memory _preferences =
            DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 9_900});

        vm.prank(RANDOM_RECIPIENT);
        kyotoHub.setPreferences(_preferences);

        (uint256 userUSDCBalanceBefore, uint256 recipientUSDCBalanceBefore, uint256 disburserUSDCBalanceBefore) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(disburser));

        uint256 adminFee = (params.amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = params.amountIn - ((params.amountIn * FEE) / KYOTOPAY_DECIMALS);

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, USDC_ADDRESS, recipientPayment, params.data);

        disburser.pay(params);

        vm.stopPrank();

        (uint256 userUSDCBalanceAfter, uint256 recipientUSDCBalanceAfter, uint256 disburserUSDCBalanceAfter) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(disburser));

        /**
         * Assert admin fee and recipientPayment are correct given logic...
         */
        assertEq(adminFee, 1_000_000);
        assertEq(recipientPayment, 99_000_000);

        assertEq((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment);
        assertEq((userUSDCBalanceBefore - userUSDCBalanceAfter), params.amountIn);
        assertEq((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee);
    }

    function testFork_Pay_PreferenceInputUsdcAndOutputWeth() public {
        // Amount in is $10,000 USDC
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: USDC_ADDRESS,
            uniFee: 500,
            amountIn: (10_000 * (10 ** USDC_DECIMALS)),
            amountOut: 0,
            deadline: block.timestamp,
            data: bytes32(uint256(67))
        }); 

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

        uint256 usdcToWethConversion = _convertUsdcToWeth(params.amountIn);

        // Adjust for Uniswap fee
        params.amountOut = (usdcToWethConversion * (UNISWAP_FEE_PRECISION_FACTOR - params.uniFee))/UNISWAP_FEE_PRECISION_FACTOR;

        uint256 adminFee = (params.amountOut * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = params.amountOut - adminFee;

        vm.startPrank(RANDOM_USER);

        // Unable to accurately predict the amountOut
        vm.expectEmit(true, true, true, false);
        emit Events.Payment(RANDOM_RECIPIENT, WETH_ADDRESS, params.amountOut, params.data);

        disburser.pay(params);

        vm.stopPrank();

        (uint256 recipientWethBalanceAfter, uint256 disburserWethBalanceAfter,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        assertEq((userUSDCBalanceBefore - USDC_CONTRACT.balanceOf(RANDOM_USER)), params.amountIn);

        // Approximately equal within 0.1%
        assertApproxEqRel((recipientWethBalanceAfter - recipientWethBalanceBefore), recipientPayment, 0.001e18);
        assertApproxEqRel((disburserWethBalanceAfter - disburserWethBalanceBefore), adminFee, 0.001e18);
    }

    function testFork_Pay_PreferenceInputWbtcAndOutputUSDC() public {
        // Amount in is ~$28,000 of WBTC
        DataTypes.PayParams memory params = DataTypes.PayParams({
            recipient: RANDOM_RECIPIENT,
            tokenIn: WBTC_ADDRESS,
            uniFee: 3_000,
            amountIn: (1 * (10 ** WBTC_DECIMALS)),
            amountOut: 0,
            deadline: block.timestamp,
            data: bytes32(uint256(67))
        }); 

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

        uint256 wbtcToUsdcConversion = _convertWbtcToUsdc(params.amountIn);

        // Adjust for Uniswap fee
        params.amountOut = (wbtcToUsdcConversion * (UNISWAP_FEE_PRECISION_FACTOR - params.uniFee))/UNISWAP_FEE_PRECISION_FACTOR;
 
        uint256 adminFee = (params.amountOut * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = params.amountOut - adminFee; 

        vm.startPrank(RANDOM_USER);
        
        disburser.pay(params);

        vm.stopPrank();

        (uint256 recipientUSDCBalanceAfter, uint256 disburserUSDCBalanceAfter,) =
            getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        assertEq((userWbtcBalanceBefore - WBTC_CONTRACT.balanceOf(RANDOM_USER)), params.amountIn, "Incorrect user balance");

        // Approximately equal within 0.15%
        // recipientPayment = expectedUSDC - adminFee
        assertApproxEqRel((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment, 0.0015e18, "Incorrect recipient balance");
        assertApproxEqRel((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee, 0.0015e18, "Incorrect disburser balance");
    }

    function testFork_PayEth_NoPreferencesSet() public {
        uint256 _amountIn = 10 ether; 

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            // uniFee doesn't matter here...
            uniFee: 100,
            // amountOut doesn't matter here...
            amountOut: 10 ether,
            deadline: block.timestamp,
            data: bytes32(uint256(67))
        }); 

        DataTypes.Preferences memory _recipientPreferences = kyotoHub.getRecipientPreferences(RANDOM_RECIPIENT);
        assertEq(_recipientPreferences.tokenAddress, address(0));
        assertEq(_recipientPreferences.slippageAllowed, uint96(0));

        uint256 userEthBalanceBefore = RANDOM_USER.balance;

        (uint256 recipientWethBalanceBefore, uint256 disburserWethBalanceBefore,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

        uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, WETH_ADDRESS, recipientPayment, params.data);

        // Amount out doesn't matter here...
        disburser.payEth{value: _amountIn}(params);

        vm.stopPrank();

        (uint256 recipientWethBalanceAfter, uint256 disburserWethBalanceAfter,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

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
        uint256 _amountIn = 10 ether;

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            // uniFee doesn't matter here...
            uniFee: 500,
            // amountOut doesn't matter here...
            amountOut: 10 ether,
            deadline: block.timestamp,
            data: bytes32(uint256(67))
        }); 

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

        uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);
        
        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_RECIPIENT, WETH_ADDRESS, recipientPayment, params.data);

        // Amount out doesn't matter here...
        disburser.payEth{value: _amountIn}(params);

        vm.stopPrank();

        (uint256 recipientWethBalanceAfter, uint256 disburserWethBalanceAfter,) =
            getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));

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
        // Amount in is ~$16,000 of ether...
        uint256 _amountIn = 10 ether;

        DataTypes.PayEthParams memory params = DataTypes.PayEthParams({
            recipient: RANDOM_RECIPIENT,
            uniFee: 500,
            amountOut: 0,
            deadline: block.timestamp,
            data: bytes32(uint256(67))
        }); 

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

        uint256 wethToUsdcConversion = _convertWethToUsdc(_amountIn);

        // Adjust for Uniswap fee
        params.amountOut = params.amountOut = (wethToUsdcConversion * (UNISWAP_FEE_PRECISION_FACTOR - params.uniFee))/UNISWAP_FEE_PRECISION_FACTOR;

        uint256 adminFee = (params.amountOut * FEE) / KYOTOPAY_DECIMALS;
        uint256 recipientPayment = params.amountOut - adminFee;

        vm.startPrank(RANDOM_USER);

        // Unable to accurately predict the amountOut
        vm.expectEmit(true, true, true, false);
        emit Events.Payment(RANDOM_RECIPIENT, USDC_ADDRESS, params.amountOut, params.data);

        disburser.payEth{value: _amountIn}(params);

        vm.stopPrank();

        (uint256 recipientUSDCBalanceAfter, uint256 disburserUSDCBalanceAfter,) =
            getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(disburser), address(0));


        assertEq((userEthBalanceBefore - RANDOM_USER.balance), _amountIn);

        // Approximately equal within 0.1%.
        assertApproxEqRel((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment, 0.001e18);
        assertApproxEqRel((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee, 0.001e18);
    }

    function test_ReceivePayment_NoPreferencesSet() public {
        DataTypes.ReceiveParams memory params = DataTypes.ReceiveParams({
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        (uint256 userUSDCBalanceBefore, , uint256 disburserUSDCBalanceBefore) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, address(0), address(disburser));

        uint256 adminFee = (params.amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 userPaymentReceived = params.amountIn - ((params.amountIn * FEE) / KYOTOPAY_DECIMALS);

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_USER, USDC_ADDRESS, userPaymentReceived, params.data);

        disburser.receivePayment(params);

        vm.stopPrank();

        (uint256 userUSDCBalanceAfter, , uint256 disburserUSDCBalanceAfter) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, address(0), address(disburser));

        /**
         * Assert admin fee and recipientPayment are correct given logic...
         */
        assertEq(adminFee, 1_000_000);
        assertEq(userPaymentReceived, 99_000_000);

        // User balance should be the same minus the admin fee
        assertEq((userUSDCBalanceBefore - adminFee), userUSDCBalanceAfter);
        assertEq((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee); 
    }

    function test_ReceivePayment_SameInputAndOutput() public {
        DataTypes.Preferences memory _preferences =
        DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 9_900});

        vm.prank(RANDOM_USER);
        kyotoHub.setPreferences(_preferences);

        DataTypes.ReceiveParams memory params = DataTypes.ReceiveParams({
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 

        (uint256 userUSDCBalanceBefore, , uint256 disburserUSDCBalanceBefore) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, address(0), address(disburser));

        uint256 adminFee = (params.amountIn * FEE) / KYOTOPAY_DECIMALS;
        uint256 userPaymentReceived = params.amountIn - ((params.amountIn * FEE) / KYOTOPAY_DECIMALS);

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.Payment(RANDOM_USER, USDC_ADDRESS, userPaymentReceived, params.data);

        disburser.receivePayment(params);

        vm.stopPrank();

        (uint256 userUSDCBalanceAfter, , uint256 disburserUSDCBalanceAfter) =
            getTokenBalances(USDC_CONTRACT, RANDOM_USER, address(0), address(disburser));

        /**
         * Assert admin fee and recipientPayment are correct given logic...
         */
        assertEq(adminFee, 1_000_000);
        assertEq(userPaymentReceived, 99_000_000);

        // User balance should be the same minus the admin fee
        assertEq((userUSDCBalanceBefore - adminFee), userUSDCBalanceAfter);
        assertEq((disburserUSDCBalanceAfter - disburserUSDCBalanceBefore), adminFee); 
    }

    function test_ReceivePayment_InputUSDC_OutputWETH() public {
        DataTypes.ReceiveParams memory params = DataTypes.ReceiveParams({
            tokenIn: USDC_ADDRESS,
            uniFee: 100,
            amountIn: 100_000_000,
            amountOut: 99_000_000,
            deadline: block.timestamp,
            data: bytes32(0) 
        }); 


    }

}