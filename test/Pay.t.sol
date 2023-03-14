// // SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

// import "forge-std/Test.sol";
// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {DataTypes} from "../src/libraries/DataTypes.sol";
// import {Fork} from "./reference/Fork.sol";
// import {Helper} from "./reference/Helper.sol";
// import {IKyotoPay} from "../src/interfaces/IKyotoPay.sol";
// import {IWETH9} from "../src/interfaces/IWETH9.sol";
// import {KyotoPay} from "../src/KyotoPay.sol";
// import {KyotoPayWrapper} from "./reference/KyotoPayWrapper.sol";
// import {MockERC20} from "./reference/MockERC20.sol";


// /*************************
//  *
//  * If you're unfamiliar with Foundry best practices, 
//  * read the following documentation before procceeding: https://book.getfoundry.sh/tutorials/best-practices
//  *
//  **************************/

// contract Constructor is Test, Helper {
//     KyotoPay kyotoPayContract;

//     function test_RevertIf_InvalidAdminFee() public {
//         uint256 _invalidAdminFee = 600;
//         vm.expectRevert(IKyotoPay.InvalidAdminFee.selector);
//         kyotoPayContract = new KyotoPay(_invalidAdminFee, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
//     }

//     function test_RevertIf_UniswapRouterZeroAddress() public {
//         uint256 _validAdminFee = 100;
//         vm.expectRevert(IKyotoPay.ZeroAddress.selector);
//         kyotoPayContract = new KyotoPay(_validAdminFee, address(0), WETH_ADDRESS);
//     }

//     function test_RevertIf_WethZeroAddress() public {
//         uint256 _validAdminFee = 100;
//         vm.expectRevert(IKyotoPay.ZeroAddress.selector);
//         kyotoPayContract = new KyotoPay(_validAdminFee, UNISWAP_SWAPROUTER_ADDRESS, address(0));
//     }

//     function test_ValidParams() public {
//         kyotoPayContract = new KyotoPay(FEE, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);

//         assertEq(kyotoPayContract.adminFee(), FEE);
//         assertEq(kyotoPayContract.uniswapSwapRouterAddress(), UNISWAP_SWAPROUTER_ADDRESS);
//     }
// }

// contract Setters is Test, Helper {
//     using SafeERC20 for ERC20;

//     KyotoPay kyotoPayContract;
//     address mockERC20;

//     function setUp() public {
//         kyotoPayContract = new KyotoPay(FEE, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
//         mockERC20 = address(new MockERC20());
//         kyotoPayContract.addToInputWhitelist(mockERC20);
//         kyotoPayContract.addToOutputWhitelist(mockERC20);
//     }

//     function test_SetPreferences() public {
//         uint96 _validSlippage = 100;

//         DataTypes.Preferences memory _validPreferences =
//             DataTypes.Preferences({tokenAddress: mockERC20, slippageAllowed: _validSlippage});

//         vm.prank(RANDOM_USER);
//         kyotoPayContract.setPreferences(_validPreferences);

//         (address _userTokenAddress, uint96 _userSlippageAllowed) = kyotoPayContract.recipientPreferences(RANDOM_USER);

//         assertEq(_userTokenAddress, mockERC20);
//         assertEq(_userSlippageAllowed, _validSlippage);
//     }

//     function test_SetPreferences_RevertIf_SlippagePreferenceZero() public {
//         DataTypes.Preferences memory _invalidSlippage =
//             DataTypes.Preferences({tokenAddress: mockERC20, slippageAllowed: 0});

//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidRecipientSlippage.selector);
//         kyotoPayContract.setPreferences(_invalidSlippage);

//         vm.stopPrank();
//     }

//     function test_SetPreferences_RevertIf_SlippagePreferenceEqualToDecimals() public {
//         uint256 decimals256 = kyotoPayContract.DECIMALS();
//         uint96 invalidSlippage = uint96(decimals256);

//         DataTypes.Preferences memory _invalidSlippage =
//             DataTypes.Preferences({tokenAddress: mockERC20, slippageAllowed: invalidSlippage});

//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidRecipientSlippage.selector);
//         kyotoPayContract.setPreferences(_invalidSlippage);

//         vm.stopPrank();
//     }

//     function test_SetPreferences_RevertIf_SlippagePreferenceGreaterThanDecimals() public {
//         uint256 decimals256 = kyotoPayContract.DECIMALS();
//         uint96 invalidSlippage = uint96(decimals256 + 1);

//         DataTypes.Preferences memory _invalidSlippage =
//             DataTypes.Preferences({tokenAddress: mockERC20, slippageAllowed: invalidSlippage});

//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidRecipientSlippage.selector);
//         kyotoPayContract.setPreferences(_invalidSlippage);

//         vm.stopPrank();
//     }

//     /**
//      * @dev DAI hasn't been added to whitelisted tokens yet
//      */
//     function test_SetPreference_RevertIf_InvalidTokenPreference() public {
//         assertFalse(kyotoPayContract.whitelistedOutputTokens(DAI_ADDRESS));

//         DataTypes.Preferences memory _invalidToken =
//             DataTypes.Preferences({tokenAddress: DAI_ADDRESS, slippageAllowed: 100});

//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidRecipientToken.selector);
//         kyotoPayContract.setPreferences(_invalidToken);
//     }

//     function test_Pause_RevertIf_NotOwner() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Ownable: caller is not the owner");
//         kyotoPayContract.pause();

//         vm.stopPrank();
//     }

//     function test_Unpause_RevertIf_NotOwner() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Ownable: caller is not the owner");
//         kyotoPayContract.unpause();

//         vm.stopPrank();
//     }

//     function test_Pause() public {
//         vm.prank(ADMIN);
//         kyotoPayContract.pause();
//     }

//     function test_Unpause() public {
//         vm.startPrank(ADMIN);

//         kyotoPayContract.pause();
//         kyotoPayContract.unpause();

//         vm.stopPrank();
//     }

//     function test_SetAdminFee() public {
//         uint256 _validFee = 200;

//         vm.prank(ADMIN);
//         kyotoPayContract.setAdminFee(_validFee);

//         assertEq(kyotoPayContract.adminFee(), _validFee);
//     }

//     function test_SetAdminFee_RevertIf_GreaterThanMaxFee() public {
//         uint256 _maxFee = kyotoPayContract.MAX_ADMIN_FEE();

//         vm.startPrank(ADMIN);

//         vm.expectRevert(IKyotoPay.InvalidAdminFee.selector);
//         kyotoPayContract.setAdminFee(_maxFee + 1);

//         vm.stopPrank();
//     }

//     function test_SetAdminFee_RevertIf_NotOwner() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Ownable: caller is not the owner");
//         kyotoPayContract.setAdminFee(200);

//         vm.stopPrank();
//     }
// }

// contract Whitelist is Test, Helper {
//     using SafeERC20 for ERC20;

//     KyotoPay kyotoPayContract;
//     address mockERC20;

//     function setUp() public {
//         kyotoPayContract = new KyotoPay(FEE, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
//         mockERC20 = address(new MockERC20());
//     }

//     function test_addToInputWhitelist() public {
//         vm.prank(ADMIN);
//         kyotoPayContract.addToInputWhitelist(mockERC20);
//         assertTrue(kyotoPayContract.whitelistedInputTokens(mockERC20));
//     }

//     function test_addToOutputWhitelist() public {
//         vm.prank(ADMIN);
//         kyotoPayContract.addToOutputWhitelist(mockERC20);
//         assertTrue(kyotoPayContract.whitelistedOutputTokens(mockERC20));
//     }

//     function test_addToInputWhiteList_RevertIf_NotOwner() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Ownable: caller is not the owner");
//         kyotoPayContract.addToInputWhitelist(mockERC20);

//         vm.stopPrank();
//     }

//     function test_addToOutputWhitelist_RevertIf_NotOwner() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Ownable: caller is not the owner");
//         kyotoPayContract.addToOutputWhitelist(mockERC20);

//         vm.stopPrank();
//     }

//     function test_addToInputWhiteList_RevertIf_ZeroAddress() public {
//         vm.startPrank(ADMIN);

//         vm.expectRevert(IKyotoPay.ZeroAddress.selector);
//         kyotoPayContract.addToInputWhitelist(address(0));

//         vm.stopPrank();
//     }

//     function test_addToOutputWhiteList_RevertIf_ZeroAddress() public {
//         vm.startPrank(ADMIN);

//         vm.expectRevert(IKyotoPay.ZeroAddress.selector);
//         kyotoPayContract.addToOutputWhitelist(address(0));

//         vm.stopPrank();
//     }

//     function test_revokeFromInputWhitelist() public {
//         vm.startPrank(ADMIN);

//         kyotoPayContract.addToInputWhitelist(mockERC20);
//         assertTrue(kyotoPayContract.whitelistedInputTokens(mockERC20));

//         kyotoPayContract.revokeFromInputWhitelist(mockERC20);
//         assertFalse(kyotoPayContract.whitelistedInputTokens(mockERC20));
//     }

//     function test_revokeFromOutputWhitelist() public {
//         vm.startPrank(ADMIN);

//         kyotoPayContract.addToOutputWhitelist(mockERC20);
//         assertTrue(kyotoPayContract.whitelistedOutputTokens(mockERC20));

//         kyotoPayContract.revokeFromOutputWhitelist(mockERC20);
//         assertFalse(kyotoPayContract.whitelistedOutputTokens(mockERC20));
//     }

//     function test_revokeFromInputWhiteList_RevertIf_NotOwner() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Ownable: caller is not the owner");
//         kyotoPayContract.revokeFromInputWhitelist(mockERC20);

//         vm.stopPrank();
//     }

//     function test_revokeFromOutputWhiteList_RevertIf_NotOwner() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Ownable: caller is not the owner");
//         kyotoPayContract.revokeFromOutputWhitelist(mockERC20);

//         vm.stopPrank();
//     }

//     function test_revokeFromInputWhiteListRevertIf_ZeroAddress() public {
//         vm.startPrank(ADMIN);

//         vm.expectRevert(IKyotoPay.ZeroAddress.selector);
//         kyotoPayContract.revokeFromInputWhitelist(address(0));

//         vm.stopPrank();
//     }

//     function test_revokeFromOutputWhiteListRevertIf_ZeroAddress() public {
//         vm.startPrank(ADMIN);

//         vm.expectRevert(IKyotoPay.ZeroAddress.selector);
//         kyotoPayContract.revokeFromOutputWhitelist(address(0));

//         vm.stopPrank();
//     }
// }

// contract InternalFunctions is Test, Helper {
//     using SafeERC20 for ERC20;

//     KyotoPayWrapper kyotoPayWrapper;
//     ERC20 mockERC20;

//     function setUp() public {
//         kyotoPayWrapper = new KyotoPayWrapper(FEE, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
//         mockERC20 = ERC20(new MockERC20());
//         kyotoPayWrapper.addToInputWhitelist(address(mockERC20));
//         kyotoPayWrapper.addToOutputWhitelist(address(mockERC20));
//     }

//     function _transferMockERC20(address _recipient, uint256 _amount) internal {
//         mockERC20.safeTransfer(_recipient, _amount);
//     }

//     function test_validatePreferences() public {
//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: address(mockERC20), slippageAllowed: 100});

//         assertTrue(kyotoPayWrapper.validatePreferences(_preferences));
//     }

//     function test_validatePreferences_RevertIf_SlippageZero() public {
//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: address(mockERC20), slippageAllowed: 0});

//         assertFalse(kyotoPayWrapper.validatePreferences(_preferences));
//     }

//     function test_validatePreferences_RevertIf_TokenNotWhitelisted() public {
//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 100});

//         assertFalse(kyotoPayWrapper.validatePreferences(_preferences));
//     }

//     function test_getSenderFunds() public {
//         uint256 _toSend = 1_000 ether;

//         _transferMockERC20(RANDOM_USER, _toSend);

//         assertEq(mockERC20.balanceOf(RANDOM_USER), _toSend);

//         vm.startPrank(RANDOM_USER);

//         mockERC20.safeApprove(address(kyotoPayWrapper), _toSend);
//         kyotoPayWrapper.getSenderFunds(address(mockERC20), _toSend);

//         vm.stopPrank();

//         assertEq(mockERC20.balanceOf(address(kyotoPayWrapper)), _toSend);
//         assertEq(mockERC20.balanceOf(RANDOM_USER), 0);
//         assertEq(mockERC20.allowance(RANDOM_USER, address(kyotoPayWrapper)), 0);
//     }

//     function test_sendRecipientFunds() public {
//         uint256 _fee = kyotoPayWrapper.adminFee();
//         uint256 _decimals = kyotoPayWrapper.DECIMALS();
//         uint256 _toSend = 1_000 ether;

//         uint256 feePayment = (_fee * _toSend) / _decimals;

//         _transferMockERC20(address(kyotoPayWrapper), _toSend);

//         kyotoPayWrapper.sendRecipientFunds(address(mockERC20), RANDOM_USER, _toSend);

//         assertEq(mockERC20.balanceOf(address(kyotoPayWrapper)), feePayment);
//         assertEq(mockERC20.balanceOf(RANDOM_USER), (_toSend - feePayment));
//     }
// }

// contract Withdraw is Test, Helper {
//     using SafeERC20 for ERC20;

//     KyotoPay kyotoPay;
//     ERC20 mockERC20;

//     uint256 _toTransfer = 10 ether;

//     function setUp() public {
//         kyotoPay = new KyotoPay(FEE, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);
//         mockERC20 = ERC20(new MockERC20());
//     }

//     function transferMock() internal {
//         mockERC20.safeTransfer(address(kyotoPay), _toTransfer);
//         assertEq(mockERC20.balanceOf(address(kyotoPay)), _toTransfer);
//     }

//     function test_Withdraw() public {
//         transferMock();

//         kyotoPay.withdraw(address(mockERC20), _toTransfer);
//         assertEq(mockERC20.balanceOf(address(kyotoPay)), 0);
//     }

//     function test_Withdraw_RevertIfZeroBalance() public {
//         vm.expectRevert(IKyotoPay.ZeroBalance.selector);
//         kyotoPay.withdraw(address(mockERC20), _toTransfer);
//     }

//     function test_Withdraw_RevertIf_NotOwner() public {
//         vm.prank(RANDOM_USER);

//         vm.expectRevert("Ownable: caller is not the owner");
//         kyotoPay.withdraw(address(mockERC20), _toTransfer);
//     }

//     function test_Withdraw_RevertIf_NotEnoughBalance() public {
//         transferMock();

//         uint256 totalBalance = mockERC20.balanceOf(address(kyotoPay));

//         vm.expectRevert("ERC20: transfer amount exceeds balance");
//         kyotoPay.withdraw(address(mockERC20), totalBalance + 1);
//     }
// }

// /**
//  * @dev The Uniswap tests fork mainnet. Forking is much simpler than local deployment of all the Uniswap contracts
//  */
// contract Pay is Fork {
//     using SafeERC20 for IERC20;

//     KyotoPay kyotoPay;

//     function setUp() public override {
//         // Call Fork setup
//         Fork.setUp();

//         // mainnetForkId is defined in reference/Fork.sol
//         mainnetForkId = vm.createSelectFork(MAINNET_RPC_URL, MAINNET_FORK_BLOCK);
//         kyotoPay = new KyotoPay(FEE, UNISWAP_SWAPROUTER_ADDRESS, WETH_ADDRESS);

//         /**
//          * Add inputs
//          */
//         kyotoPay.addToInputWhitelist(WBTC_ADDRESS);
//         kyotoPay.addToInputWhitelist(WETH_ADDRESS);
//         kyotoPay.addToInputWhitelist(DAI_ADDRESS);
//         kyotoPay.addToInputWhitelist(USDC_ADDRESS);

//         /**
//          * Add outputs
//          */
//         kyotoPay.addToOutputWhitelist(DAI_ADDRESS);
//         kyotoPay.addToOutputWhitelist(USDC_ADDRESS);
//         kyotoPay.addToOutputWhitelist(WETH_ADDRESS);

//         /**
//          * Give RANDOM_USER DAI, USDC, ETH, WBTC, and WETH
//          */
//         vm.prank(DAI_HOLDER);
//         DAI_CONTRACT.safeTransfer(RANDOM_USER, 10_000_000 * (10 ** DAI_DECIMALS));

//         vm.prank(WBTC_HOLDER);
//         WBTC_CONTRACT.safeTransfer(RANDOM_USER, 10_000 * (10 ** WBTC_DECIMALS));

//         issueUSDC(RANDOM_USER, 10_000_000 * (10 ** USDC_DECIMALS));

//         payable(RANDOM_USER).transfer(20_000 ether);

//         vm.startPrank(RANDOM_USER);
//         IWETH9(WETH_ADDRESS).deposit{value: 10_000 ether}();

//         /**
//          *  Set allowances to type(uint256).max
//          *  msg.sender is RANDOM_USER from startPrank() above
//          */
//         DAI_CONTRACT.safeApprove(address(kyotoPay), type(uint256).max);
//         USDC_CONTRACT.safeApprove(address(kyotoPay), type(uint256).max);
//         WETH_CONTRACT.safeApprove(address(kyotoPay), type(uint256).max);
//         WBTC_CONTRACT.safeApprove(address(kyotoPay), type(uint256).max);

//         vm.stopPrank();
//     }

//     function testFork_SetUp() public {
//         /**
//          * Verify inputs
//          */
//         assertTrue(kyotoPay.whitelistedInputTokens(WBTC_ADDRESS));
//         assertTrue(kyotoPay.whitelistedInputTokens(WETH_ADDRESS));
//         assertTrue(kyotoPay.whitelistedInputTokens(DAI_ADDRESS));
//         assertTrue(kyotoPay.whitelistedInputTokens(USDC_ADDRESS));

//         /**
//          * Verify outputs
//          */
//         assertTrue(kyotoPay.whitelistedOutputTokens(WETH_ADDRESS));
//         assertTrue(kyotoPay.whitelistedOutputTokens(DAI_ADDRESS));
//         assertTrue(kyotoPay.whitelistedOutputTokens(USDC_ADDRESS));

//         /**
//          * Verify balances
//          */
//         assertEq(DAI_CONTRACT.balanceOf(RANDOM_USER), 10_000_000 * (10 ** DAI_DECIMALS));
//         assertEq(USDC_CONTRACT.balanceOf(RANDOM_USER), 10_000_000 * (10 ** USDC_DECIMALS));
//         assertEq(WETH_CONTRACT.balanceOf(RANDOM_USER), 10_000 ether);
//         assertEq(WBTC_CONTRACT.balanceOf(RANDOM_USER), 10_000 * (10 ** WBTC_DECIMALS));
//         assertEq(RANDOM_USER.balance, 10_000 ether);

//         /**
//          * Verify allowances
//          */
//         assertEq(DAI_CONTRACT.allowance(RANDOM_USER, address(kyotoPay)), type(uint256).max);
//         assertEq(USDC_CONTRACT.allowance(RANDOM_USER, address(kyotoPay)), type(uint256).max);
//         assertEq(WBTC_CONTRACT.allowance(RANDOM_USER, address(kyotoPay)), type(uint256).max);
//         assertEq(WETH_CONTRACT.allowance(RANDOM_USER, address(kyotoPay)), type(uint256).max);

//         /**
//          * Verify constants in Helper
//          */
//         assertEq(FEE, kyotoPay.adminFee());
//         assertEq(KYOTOPAY_DECIMALS, kyotoPay.DECIMALS());
//     }

//     function testFork_Pay_RevertIf_RecipientAddressZero() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.ZeroAddress.selector);
//         kyotoPay.pay(address(0), USDC_ADDRESS, 100_000_000, 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_Pay_RevertIf_WrongUniFee() public {
//         vm.startPrank(RANDOM_USER);

//         uint24 _invalidUniFee = 333;

//         vm.expectRevert("Invalid Uni Fee");
//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, 100_000_000, 99_000_000, _invalidUniFee, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_Pay_RevertIfPaused() public {
//         kyotoPay.pause();

//         vm.expectRevert("Pausable: paused");
//         kyotoPay.pay(RANDOM_RECIPIENT, LOOKS_ADDRESS, 100_000_000, 99_000_000, 100, bytes32(0));
//     }

//     function testFork_Pay_RevertIf_InvalidInputToken() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidToken.selector);
//         kyotoPay.pay(RANDOM_RECIPIENT, LOOKS_ADDRESS, 100_000_000, 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_Pay_RevertIf_InvalidAmountIn() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidAmount.selector);
//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, 0, 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function tesFork_Pay_RevertIf_InvalidAmountOut() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidAmount.selector);
//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, 100_000_000, 0, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_Pay_NotEnoughToken() public {
//         vm.startPrank(RANDOM_USER);

//         uint256 userUSDCBalance = USDC_CONTRACT.balanceOf(RANDOM_USER);

//         vm.expectRevert("ERC20: transfer amount exceeds balance");
//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, (userUSDCBalance + 1), 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_Pay_InsufficcientAllowance() public {
//         vm.startPrank(RANDOM_USER);

//         USDC_CONTRACT.safeApprove(address(kyotoPay), 100);

//         vm.expectRevert("ERC20: transfer amount exceeds allowance");
//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, 100_000_000, 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     /**
//      *  Input: USDC
//      *  Output: WETH
//      *  Note: slippage is set to %0.01%, meaning that nearly any payment should revert
//      */
//     function testFork_Pay_RevertIf_InsufficcientAmountOut() public {
//         // Random data
//         bytes32 _data = bytes32(uint256(67));

//         // Amount in is $10,000 of USDC...
//         uint256 _amountIn = 10_000 * (10 ** USDC_DECIMALS);

//         // Set slippage to zero...
//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: WETH_ADDRESS, slippageAllowed: uint96(KYOTOPAY_DECIMALS - 1)});

//         vm.prank(RANDOM_RECIPIENT);
//         kyotoPay.setPreferences(_preferences);

//         // Defined in Fork.sol...
//         (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

//         // USDC uses 6 decimals
//         // WETH uses 18 decimals
//         // Chainlink's pricefeed uses 8 decimals
//         // However: We need the calculation to end up using the WETH decimals, i.e. 10^18

//         // _amountIn = USDC_Amount * 10^6
//         // ethUSDCPrice = ETH_Price * 10^8
//         // expectedWeth = (USDC_Amount * 10^6) * (10^8) * (10^(18-6)) / (ETH_Price * 10^8)
//         // Note: the 10^8s in the nominator and denominator cancel each other out, leaving 10^(18-6) * 10^6 which is just 10^18

//         // Therefore: expectedWeth = (_amountIn) * (10^8) * (10^(18-6)) / ethUSDCPrice

//         uint256 expectedWeth =
//             (_amountIn * (10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS))) / uint256(ethUSDCPrice);

//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Too little received");
//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, expectedWeth, 100, _data);

//         vm.stopPrank();
//     }

//     /**
//      *  Input: WETH
//      *  Output: USDC
//      *  Note: slippage is set to 0.01%, meaning that any sufficcient payment will revert
//      *  Surpisingly, slippage ends up being less than 0.01% even at $40,000 payment
//      *  Needed to up the payment amount to $48,000 to have a slippage >0.01%
//      */
//     function testFork_PayEth_RevertIf_InsufficcientAmountOut() public {
//         // Random data
//         bytes32 _data = bytes32(uint256(67));

//         // Amount in is ~$48,000 of ether...
//         uint256 _amountIn = 30 ether;

//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: uint96(KYOTOPAY_DECIMALS - 1)});

//         vm.prank(RANDOM_RECIPIENT);
//         kyotoPay.setPreferences(_preferences);

//         // Defined in Fork.sol...
//         (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

//         // USDC uses 6 decimals
//         // WETH uses 18 decimals
//         // Chainlink's pricefeed uses 8 decimals
//         // However: We need the calculation to end up using the USDC decimals, i.e. 10^6

//         // _amountIn = WETH_Amount * 10^18
//         // ethUSDCPrice = ETH_Price * 10^8
//         // expectedUSDC = (WETH_Amount * 10^18) * ((ETH_Price * 10^8) * (10**(6-18))) / (10^8)
//         // Algebraically, 10**(6-18) in the numerator can be made 10**(18-6) in the denominator
//         // Note: the 10^8s cancel each other out in the numberator and denominator, leaving (10^18)/(10^(18-6)), which is just 10^6

//         // Therefore: expectedUSDC = (_amountIn * ethUSDCPrice) / ((10^8) * (10^(18-6)))

//         uint256 expectedUSDC =
//             (_amountIn * uint256(ethUSDCPrice)) / ((10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS)));

//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert("Too little received");
//         kyotoPay.payEth{value: _amountIn}(RANDOM_RECIPIENT, expectedUSDC, 100, _data);

//         vm.stopPrank();
//     }

//     function testFork_PayETH_RevertIf_Paused() public {
//         kyotoPay.pause();

//         vm.expectRevert("Pausable: paused");
//         kyotoPay.payEth{value: 1 ether}(RANDOM_RECIPIENT, 99_000_000, 100, bytes32(0));
//     }

//     function testFork_PayETH_RevertIf_RecipientAddressZero() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.ZeroAddress.selector);
//         kyotoPay.payEth{value: 1 ether}(address(0), 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_PayEth_RevertIf_WrongUniFee() public {
//         vm.startPrank(RANDOM_USER);

//         uint24 _invalidUniFee = 333;

//         vm.expectRevert("Invalid Uni Fee");
//         kyotoPay.payEth{value: 1 ether}(RANDOM_RECIPIENT, 99_000_000, _invalidUniFee, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_PayEth_RevertIf_InvalidInputToken() public {
//         kyotoPay.revokeFromInputWhitelist(WETH_ADDRESS);

//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidToken.selector);
//         kyotoPay.payEth{value: 1 ether}(RANDOM_RECIPIENT, 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_PayEth_RevertIf_InvalidAmountIn() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidAmount.selector);
//         kyotoPay.payEth{value: 0}(RANDOM_RECIPIENT, 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_PayEth_RevertIf_InvalidAmountOut() public {
//         vm.startPrank(RANDOM_USER);

//         vm.expectRevert(IKyotoPay.InvalidAmount.selector);
//         kyotoPay.payEth{value: 1 ether}(RANDOM_RECIPIENT, 0, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_PayEth_RevertIf_NotEnoughETH() public {
//         vm.startPrank(RANDOM_USER);

//         uint256 userETHBalance = RANDOM_USER.balance;

//         vm.expectRevert();
//         kyotoPay.payEth{value: (userETHBalance + 1)}(RANDOM_RECIPIENT, 99_000_000, 100, bytes32(0));

//         vm.stopPrank();
//     }

//     function testFork_Pay_NoPreferenceSet() public {
//         bytes32 _data = bytes32(uint256(67));
//         uint256 _amountIn = 100_000_000;

//         (address _recipientToken, uint96 _recipientSlippage) = kyotoPay.recipientPreferences(RANDOM_RECIPIENT);
//         assertEq(_recipientToken, address(0));
//         assertEq(_recipientSlippage, uint96(0));

//         (uint256 userUSDCBalanceBefore, uint256 recipientUSDCBalanceBefore, uint256 kyotoUSDCBalanceBefore) =
//             getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(kyotoPay));

//         vm.startPrank(RANDOM_USER);

//         vm.expectEmit(true, true, true, true);
//         emit Payment(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, _data);

//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, 99_000_000, 100, _data);

//         vm.stopPrank();

//         (uint256 userUSDCBalanceAfter, uint256 recipientUSDCBalanceAfter, uint256 kyotoUSDCBalanceAfter) =
//             getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(kyotoPay));

//         uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
//         uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

//         /**
//          * Assert admin fee and recipientPayment are correct given logic...
//          */
//         assertEq(adminFee, 1_000_000);
//         assertEq(recipientPayment, 99_000_000);

//         assertEq((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment);
//         assertEq((userUSDCBalanceBefore - userUSDCBalanceAfter), _amountIn);
//         assertEq((kyotoUSDCBalanceAfter - kyotoUSDCBalanceBefore), adminFee);
//     }

//     function testFork_Pay_PreferenceSetSameInputAndOutput() public {
//         bytes32 _data = bytes32(uint256(67));
//         uint256 _amountIn = 100_000_000;

//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 9_900});

//         vm.prank(RANDOM_RECIPIENT);
//         kyotoPay.setPreferences(_preferences);

//         (address recipientToken, uint96 recipientSlippage) = kyotoPay.recipientPreferences(RANDOM_RECIPIENT);
//         assertEq(recipientToken, USDC_ADDRESS);
//         assertEq(recipientSlippage, 9_900);

//         (uint256 userUSDCBalanceBefore, uint256 recipientUSDCBalanceBefore, uint256 kyotoUSDCBalanceBefore) =
//             getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(kyotoPay));

//         vm.startPrank(RANDOM_USER);

//         vm.expectEmit(true, true, true, true);
//         emit Payment(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, _data);

//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, 99_000_000, 100, _data);

//         vm.stopPrank();

//         (uint256 userUSDCBalanceAfter, uint256 recipientUSDCBalanceAfter, uint256 kyotoUSDCBalanceAfter) =
//             getTokenBalances(USDC_CONTRACT, RANDOM_USER, RANDOM_RECIPIENT, address(kyotoPay));

//         uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
//         uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

//         /**
//          * Assert admin fee and recipientPayment are correct given logic...
//          */
//         assertEq(adminFee, 1_000_000);
//         assertEq(recipientPayment, 99_000_000);

//         assertEq((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment);
//         assertEq((userUSDCBalanceBefore - userUSDCBalanceAfter), _amountIn);
//         assertEq((kyotoUSDCBalanceAfter - kyotoUSDCBalanceBefore), adminFee);
//     }

//     function testFork_Pay_PreferenceInputUsdcAndOutputWeth() public {
//         // Random data
//         bytes32 _data = bytes32(uint256(67));

//         // Amount in is $10,000 of USDC...
//         uint256 _amountIn = 10_000 * (10 ** USDC_DECIMALS);

//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: WETH_ADDRESS, slippageAllowed: 9_900});

//         vm.prank(RANDOM_RECIPIENT);
//         kyotoPay.setPreferences(_preferences);

//         /**
//          * Store before balances...
//          */
//         (uint256 recipientWethBalanceBefore, uint256 kyotoWethBalanceBefore,) =
//             getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         uint256 userUSDCBalanceBefore = USDC_CONTRACT.balanceOf(RANDOM_USER);

//         // Defined in Fork.sol...
//         (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

//         // USDC uses 6 decimals
//         // WETH uses 18 decimals
//         // Chainlink's pricefeed uses 8 decimals
//         // However: We need the calculation to end up using the WETH decimals, i.e. 10^18

//         // _amountIn = USDC_Amount * 10^6
//         // ethUSDCPrice = ETH_Price * 10^8
//         // expectedWeth = (USDC_Amount * 10^6) * (10^8) * (10^(18-6)) / (ETH_Price * 10^8)
//         // Note: the 10^8s in the nominator and denominator cancel each other out, leaving 10^(18-6) * 10^6 which is just 10^18

//         // Therefore: expectedWeth = (_amountIn) * (10^8) * (10^(18-6)) / ethUSDCPrice

//         uint256 expectedWeth =
//             (_amountIn * (10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS))) / uint256(ethUSDCPrice);

//         vm.startPrank(RANDOM_USER);

//         vm.expectEmit(true, true, true, true);
//         emit Payment(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, _data);

//         // Correct fee for this pool is 0.05%, which is 500...
//         kyotoPay.pay(RANDOM_RECIPIENT, USDC_ADDRESS, _amountIn, expectedWeth, 500, _data);

//         vm.stopPrank();

//         (uint256 recipientWethBalanceAfter, uint256 kyotoWethBalanceAfter,) =
//             getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         uint256 userUSDCBalanceAfter = USDC_CONTRACT.balanceOf(RANDOM_USER);

//         uint256 adminFee = (expectedWeth * FEE) / KYOTOPAY_DECIMALS;
//         uint256 recipientPayment = expectedWeth - adminFee;

//         assertEq((userUSDCBalanceBefore - userUSDCBalanceAfter), _amountIn);

//         // Approximately equal within 0.25%.
//         assertApproxEqRel((recipientWethBalanceAfter - recipientWethBalanceBefore), recipientPayment, 0.0025e18);
//         assertApproxEqRel((kyotoWethBalanceAfter - kyotoWethBalanceBefore), adminFee, 0.0025e18);
//     }

//     function testFork_Pay_PreferenceInputWbtcAndOutputUSDC() public {
//         // Amount in is ~$22,000 of WBTC
//         uint256 _amountIn = 1 * (10 ** WBTC_DECIMALS);

//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 9_800});

//         vm.prank(RANDOM_RECIPIENT);
//         kyotoPay.setPreferences(_preferences);

//         /**
//          * Store before balances...
//          */
//         (uint256 recipientUSDCBalanceBefore, uint256 kyotoUSDCBalanceBefore,) =
//             getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         uint256 userWbtcBalanceBefore = WBTC_CONTRACT.balanceOf(RANDOM_USER);

//         // Defined in Fork.sol...
//         (int256 btcUSDCPrice, uint8 btcUSDCDecimals) = getBtcToUSDCPriceAndDecimals();

//         // Unlike WETH and ETH, WBTC and BTC don't trade in parity...
//         (int256 wbtcBtcConversionRate, uint8 wbtcBtcConversionDecimals) = getWbtcToBtcConversionRateAndDecimals();

//         // WBTC uses 8 decimals
//         // USDC uses 6 decimals
//         // Chainlink's pricefeeds uses 8 decimals
//         // However: We need the calculation to end up using the USDC decimals, i.e. 10^6

//         // _amountIn = WBTC_Amount * 10^8
//         // btcUSDCPrice = BTC_Price * 10^8
//         // wbtcBtcConversionRate = Conversion_Rate * 10^8
//         // expectedUSDC = (WBTC_Amount * 10^8) * (Conversion_Rate * 10^8) * (btcUSDPrice * 10^8) * (10^(6-8)) / (10^8) * 10(^8)
//         // Algebraically, 10^(6-8) in the numerator is the same as 10^(8-6) in the denominator
//         // Note: the 10^8s in the nominator and denominator cancel each other out, leaving 10^(18-6) * 10^6 which is just 10^18

//         // Therefore: expectedUSDC = _amountIn * wbtcBtcConversionRate * btcUSDCPrice) / (10(8-6) * (10^8) * 10(^8))

//         uint256 expectedUSDC = (_amountIn * uint256(wbtcBtcConversionRate) * uint256(btcUSDCPrice))
//             / ((10 ** (WBTC_DECIMALS - USDC_DECIMALS)) * (10 ** btcUSDCDecimals) * (10 ** wbtcBtcConversionDecimals));

//         vm.startPrank(RANDOM_USER);

//         vm.expectEmit(true, true, true, true);
//         emit Payment(RANDOM_RECIPIENT, WBTC_ADDRESS, _amountIn, bytes32(uint256(0)));

//         // Correct fee for this pool is 0.3%, which is 3000...
//         kyotoPay.pay(RANDOM_RECIPIENT, WBTC_ADDRESS, _amountIn, expectedUSDC, 3000, bytes32(uint256(0)));

//         vm.stopPrank();

//         (uint256 recipientUSDCBalanceAfter, uint256 kyotoUSDCBalanceAfter,) =
//             getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         uint256 userWbtcBalanceAfter = WBTC_CONTRACT.balanceOf(RANDOM_USER);
//         uint256 adminFee = (expectedUSDC * FEE) / KYOTOPAY_DECIMALS;

//         assertEq((userWbtcBalanceBefore - userWbtcBalanceAfter), _amountIn);

//         // Approximately equal within 0.50%
//         // recipientPayment = expectedUSDC - adminFee
//         assertApproxEqRel((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), (expectedUSDC - adminFee), 0.005e18);
//         assertApproxEqRel((kyotoUSDCBalanceAfter - kyotoUSDCBalanceBefore), adminFee, 0.005e18);
//     }

//     function testFork_PayEth_NoPreferencesSet() public {
//         bytes32 _data = bytes32(uint256(67));
//         uint256 _amountIn = 10 ether;

//         (address _recipientToken, uint96 _recipientSlippage) = kyotoPay.recipientPreferences(RANDOM_RECIPIENT);
//         assertEq(_recipientToken, address(0));
//         assertEq(_recipientSlippage, uint96(0));

//         uint256 userEthBalanceBefore = RANDOM_USER.balance;

//         (uint256 recipientWethBalanceBefore, uint256 kyotoWethBalanceBefore,) =
//             getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         vm.startPrank(RANDOM_USER);

//         vm.expectEmit(true, true, true, true);
//         emit Payment(RANDOM_RECIPIENT, WETH_ADDRESS, _amountIn, _data);

//         // Amount out doesn't matter here...
//         kyotoPay.payEth{value: _amountIn}(RANDOM_RECIPIENT, 99_000_000, 100, _data);

//         vm.stopPrank();

//         (uint256 recipientWethBalanceAfter, uint256 kyotoWethBalanceAfter,) =
//             getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
//         uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

//         /**
//          * Assert admin fee and recipientPayment are correct given logic...
//          */
//         assertEq(adminFee, 0.1 ether);
//         assertEq(recipientPayment, 9.9 ether);

//         assertEq((recipientWethBalanceAfter - recipientWethBalanceBefore), recipientPayment);
//         assertEq((userEthBalanceBefore - RANDOM_USER.balance), _amountIn);
//         assertEq((kyotoWethBalanceAfter - kyotoWethBalanceBefore), adminFee);
//     }

//     function testFork_PayEth_EthInputAndWethOutput() public {
//         bytes32 _data = bytes32(uint256(67));
//         uint256 _amountIn = 10 ether;

//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: WETH_ADDRESS, slippageAllowed: 9_900});

//         vm.prank(RANDOM_RECIPIENT);
//         kyotoPay.setPreferences(_preferences);

//         (address recipientToken, uint96 recipientSlippage) = kyotoPay.recipientPreferences(RANDOM_RECIPIENT);
//         assertEq(recipientToken, WETH_ADDRESS);
//         assertEq(recipientSlippage, 9_900);

//         uint256 userETHBalanceBefore = RANDOM_USER.balance;

//         (uint256 recipientWethBalanceBefore, uint256 kyotoWethBalanceBefore,) =
//             getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         vm.startPrank(RANDOM_USER);

//         vm.expectEmit(true, true, true, true);
//         emit Payment(RANDOM_RECIPIENT, WETH_ADDRESS, _amountIn, _data);

//         // Amount out doesn't matter here...
//         kyotoPay.payEth{value: _amountIn}(RANDOM_RECIPIENT, 99_000_000, 100, _data);

//         vm.stopPrank();

//         (uint256 recipientWethBalanceAfter, uint256 kyotoWethBalanceAfter,) =
//             getTokenBalances(WETH_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         uint256 adminFee = (_amountIn * FEE) / KYOTOPAY_DECIMALS;
//         uint256 recipientPayment = _amountIn - ((_amountIn * FEE) / KYOTOPAY_DECIMALS);

//         /**
//          * Assert admin fee and recipientPayment are correct given logic...
//          */
//         assertEq(adminFee, 0.1 ether);
//         assertEq(recipientPayment, 9.9 ether);

//         assertEq((recipientWethBalanceAfter - recipientWethBalanceBefore), recipientPayment);
//         assertEq((userETHBalanceBefore - RANDOM_USER.balance), _amountIn);
//         assertEq((kyotoWethBalanceAfter - kyotoWethBalanceBefore), adminFee);
//     }

//     function testFork_PayEth_UsdcOutput() public {
//         // Random data
//         bytes32 _data = bytes32(uint256(67));

//         // Amount in is ~$16,000 of ether...
//         uint256 _amountIn = 10 ether;

//         DataTypes.Preferences memory _preferences =
//             DataTypes.Preferences({tokenAddress: USDC_ADDRESS, slippageAllowed: 9_900});

//         vm.prank(RANDOM_RECIPIENT);
//         kyotoPay.setPreferences(_preferences);

//         /**
//          * Store before balances...
//          */
//         (uint256 recipientUSDCBalanceBefore, uint256 kyotoUSDCBalanceBefore,) =
//             getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         uint256 userEthBalanceBefore = RANDOM_USER.balance;

//         // Defined in Fork.sol...
//         (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

//         // USDC uses 6 decimals
//         // WETH uses 18 decimals
//         // Chainlink's pricefeed uses 8 decimals
//         // However: We need the calculation to end up using the USDC decimals, i.e. 10^6

//         // _amountIn = WETH_Amount * 10^18
//         // ethUSDCPrice = ETH_Price * 10^8
//         // expectedUSDC = (WETH_Amount * 10^18) * ((ETH_Price * 10^8) * (10**(6-18))) / (10^8)
//         // Algebraically, 10**(6-18) in the numerator can be made 10**(18-6) in the denominator
//         // Note: the 10^8s cancel each other out in the numberator and denominator, leaving (10^18)/(10^(18-6)), which is just 10^6

//         // Therefore: expectedUSDC = (_amountIn * ethUSDCPrice) / ((10^8) * (10^(18-6)))

//         uint256 expectedUSDC =
//             (_amountIn * uint256(ethUSDCPrice)) / ((10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS)));

//         vm.startPrank(RANDOM_USER);

//         vm.expectEmit(true, true, true, true);
//         emit Payment(RANDOM_RECIPIENT, WETH_ADDRESS, _amountIn, _data);

//         // Correct fee for this pool is 0.05%, which is 500...
//         kyotoPay.payEth{value: _amountIn}(RANDOM_RECIPIENT, expectedUSDC, 500, _data);

//         vm.stopPrank();

//         (uint256 recipientUSDCBalanceAfter, uint256 kyotoUSDCBalanceAfter,) =
//             getTokenBalances(USDC_CONTRACT, RANDOM_RECIPIENT, address(kyotoPay), address(0));

//         uint256 adminFee = (expectedUSDC * FEE) / KYOTOPAY_DECIMALS;
//         uint256 recipientPayment = expectedUSDC - adminFee;

//         assertEq((userEthBalanceBefore - RANDOM_USER.balance), _amountIn);

//         // Approximately equal within 0.25%.
//         assertApproxEqRel((recipientUSDCBalanceAfter - recipientUSDCBalanceBefore), recipientPayment, 0.0025e18);
//         assertApproxEqRel((kyotoUSDCBalanceAfter - kyotoUSDCBalanceBefore), adminFee, 0.0025e18);
//     }
// }

// // Will get to after demo day....
// // Relatively unimportant, but good to have, especially regarding extreme values in Pay and PayEth

// contract FuzzNoFork is Helper, Test {}

// contract FuzzFork is Fork {
// // function testForkFuzz_Pay_SameInputAndOutput() public {}

// // function testForkFuzz_Pay_WbtcInputAndUsdcOutput() public {}
// }
