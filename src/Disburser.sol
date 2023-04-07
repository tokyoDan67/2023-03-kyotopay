// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title KyotoPay
/// Version 1.1

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {HubOwnable} from "./base/HubOwnable.sol";
import {IDisburser} from "./interfaces/IDisburser.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";

// To Do:
//   - Add a receive function
//   - Add EIP712 signatures
//   - Update the deadline to be passed in by the frontend
//   - Add vendor payments

contract Disburser is HubOwnable, Pausable, IDisburser {
    using SafeERC20 for IERC20;

    // MAX_ADMIN_FEE is denominated in PRECISION_FACTOR.  I.e. 500 = 5%
    uint256 public immutable MAX_ADMIN_FEE;

    // Decimals is the same as KyotoHubs, 10_000
    uint256 public immutable PRECISION_FACTOR;
    address public immutable UNISWAP_SWAP_ROUTER_ADDRESS;
    address public immutable WETH_ADDRESS;

    // adminFee is denominated in PRECISION_FACTOR.  For example, a value for fee of 200 = 2%
    uint256 public adminFee;

    constructor(uint256 _adminFee, address _kyotoHub, address _uniswapSwapRouterAddress, address _wethAddress)
        HubOwnable(_kyotoHub)
    {
        PRECISION_FACTOR = KYOTO_HUB.PRECISION_FACTOR();
        MAX_ADMIN_FEE = KYOTO_HUB.MAX_FEE();

        if (_adminFee > MAX_ADMIN_FEE) revert Errors.InvalidAdminFee();
        if (_uniswapSwapRouterAddress == address(0)) revert Errors.ZeroAddress();
        if (_wethAddress == address(0)) revert Errors.ZeroAddress();

        UNISWAP_SWAP_ROUTER_ADDRESS = _uniswapSwapRouterAddress;
        WETH_ADDRESS = _wethAddress;

        adminFee = _adminFee;
    }

    /**
     * @notice Function to receive a payment in the msg.sender's preferred output token
     * The msg.sender should receive the input token from the payer before calling this function
     * @param _params the parameters
     */
    function receivePayment(DataTypes.ReceiveParams memory _params)
        external
        whenNotPaused
    {
        // Reconstruct params
        DataTypes.PayParams memory paymentParams = DataTypes.PayParams({
            recipient: msg.sender,
            tokenIn: _params.tokenIn,
            uniFee: _params.uniFee,
            amountIn: _params.amountIn,
            amountOut: _params.amountOut,
            deadline: _params.deadline, 
            data: _params.data
        });

        // validate input params
        _validateInputParams(paymentParams);

        // get payer funds from msg.sender
        _getSenderFunds(_params.tokenIn, _params.amountIn);

        _pay(paymentParams);
    }

    // Note: if the user has not set their preferences, they will receive WETH and not ETH
    function receiveEthPayment(DataTypes.ReceiveEthParams memory _params) external payable whenNotPaused {
        // Cache vars
        uint256 msgValue = msg.value;
        address wethAddress = WETH_ADDRESS;

        // Reconstruct params
        DataTypes.PayParams memory paymentParams = DataTypes.PayParams({
            recipient: msg.sender,
            tokenIn: wethAddress, 
            uniFee: _params.uniFee,
            amountIn: msgValue,
            amountOut: _params.amountOut,
            deadline: _params.deadline,
            data: _params.data 
        });

        // Get payer funds from msg.sender
        _validateInputParams(paymentParams);

        // Get WETH from ETH
        IWETH9(wethAddress).deposit{value: msgValue}();

        _pay(paymentParams);
    }

    /**
     * @notice pays a recipient in their preferred token from a given input token
     * @param _params the parameters 
     * Requirements:
     *  - '_params.recipient' != address(0)
     *  - '_params.tokenIn' is a valid input token
     *  - '_params.amountIn' != 0
     *  - '_params.amountOut' != 0
     *  - '_params.uniFee' is a valid Uniswap pool fee
     *  - The executed swap will send the recipient more tokens than their slippageAllowed * '_amountOut'
     */
    function pay(DataTypes.PayParams memory _params) external whenNotPaused {
        _validateInputParams(_params);

        // transfer the amount to this contract (should fail if the contract will not allow it)
        _getSenderFunds(_params.tokenIn, _params.amountIn);

        _pay(_params);
    }

    /**
     * @notice pays a recipient in their preferred token from the given ether
     * Note: if the user has not set their preferences, they will receive WETH and not ETH
     * Requirements:
     *  - '_recipient' != address(0)
     *  -  WETH is a whitelisted input
     *  -  msg.value > 0
     *  - 'amountOut' != 0
     *  - '_uniFee' is a valid Uniswap pool fee
     *  - The executed swap will send the recipient more tokens than their slippageAllowed * '_amountOut'
     */

    function payEth(DataTypes.PayEthParams memory _params)
        external
        payable
        whenNotPaused
    {
        // Cache vars
        uint256 msgValue = msg.value;
        address wethAddress = WETH_ADDRESS;

        // Reconstruct params
        DataTypes.PayParams memory paymentParams = DataTypes.PayParams({
            recipient: _params.recipient,
            tokenIn: wethAddress, 
            uniFee: _params.uniFee,
            amountIn: msgValue,
            amountOut: _params.amountOut,
            deadline: _params.deadline,
            data: _params.data 
        });

        // Validate
        _validateInputParams(paymentParams);

        // Get WETH from ETH
        IWETH9(wethAddress).deposit{value: msgValue}();

        _pay(paymentParams);
    }

    //////////////////////////////////
    //      Internal Functions      //
    //////////////////////////////////

    /**
     * @dev validates preferences, gets recipient funds, executes the UNI swap, sends funds to recipient
     * Does not execute a UNI swap if the input token is the same as the output token or if the recipient has not set preferences
     * Instead, _pay will send the user funds directly to the recipient after a fee
     */
    function _pay(DataTypes.PayParams memory _params) internal {
        // Cache the recipient's preferences
        DataTypes.Preferences memory preferences = KYOTO_HUB.getRecipientPreferences(_params.recipient);
        bool areValidPreferences = _validatePreferences(preferences);

        // If the sender's token is the recipient's preferred token or recipient's preferences haven't been set, transfer directly and stop execution
        if ((_params.tokenIn == preferences.tokenAddress) || !(areValidPreferences)) {
            // transfer funds to recipient, pays fee, emits event
            _sendRecipientFunds(_params.recipient, _params.tokenIn, _params.amountIn, _params.data);
            return;
        }

        uint256 swapOutput = _executeSwap(
            _params.tokenIn, preferences.tokenAddress, _params.amountIn, _params.amountOut, _params.deadline, _params.uniFee, preferences.slippageAllowed
        );

        // transfer funds to recipient, pays fee, emits event
        _sendRecipientFunds(_params.recipient, preferences.tokenAddress, swapOutput, _params.data);
    }

    /**
     * @dev internal function to execute a swap using the Uniswap Swap Router
     * Uses the recipient's set slippage for amountOut
     */
    function _executeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _deadline,
        uint24 _uniFee,
        uint96 _slippageAllowed
    ) internal returns (uint256) {
        // Cache
        address _uniswapSwapRouterAddress = UNISWAP_SWAP_ROUTER_ADDRESS;

        IERC20(_tokenIn).safeApprove(_uniswapSwapRouterAddress, _amountIn);

        // create the input params
        ISwapRouter.ExactInputSingleParams memory uniParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _uniFee, // e.g. fee for a pool at 0.3% tier is 3000
            recipient: address(this), // this contract will be doing the distribution of funds
            deadline: _deadline,
            amountIn: _amountIn,
            amountOutMinimum: ((_amountOut * uint256(_slippageAllowed)) / PRECISION_FACTOR),
            sqrtPriceLimitX96: 0 // sets a limit for the price that the swap will push to the pool (setting to 0 makes it inactive) --> will require more research
        });

        // swap currency on uniswap
        return ISwapRouter(_uniswapSwapRouterAddress).exactInputSingle(uniParams);
    }

    /**
     * @dev safe transfers funds from the user to address(this)
     */
    function _getSenderFunds(address _tokenAddress, uint256 _amountIn) internal {
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amountIn);
    }

    /**
     * @dev safeTransfer tokens to a given recipient given a ERC20 token address and amount to send
     */
    function _sendRecipientFunds(address _recipient, address _tokenAddress, uint256 _amount, bytes32 _data) internal {
        uint256 partnerDiscount = KYOTO_HUB.getPartnerDiscount(_recipient);
        
        uint256 fee = partnerDiscount == 0 ? adminFee : adminFee - partnerDiscount;

        uint256 ownerPayment = (_amount * fee) / PRECISION_FACTOR;

        uint256 amountToTransfer = _amount - ownerPayment; 

        // pay the recipient the excess
        IERC20(_tokenAddress).safeTransfer(_recipient, amountToTransfer);

        emit Events.Payment(_recipient, _tokenAddress, amountToTransfer, _data);
    }

    /**
     * @dev Internal function to validate input parameters. Reverts if given invalid input params.
     * Note: Uniswap fees for pools are 0.01%, 0.05%, 0.30%, and 1.00%
     * They are represented in hundredths of basis points.  I.e. 100 = 0.01%, 500 = 0.05%, etc.
     */
    function _validateInputParams(DataTypes.PayParams memory _params) internal view {
        if ((_params.uniFee != 100) && (_params.uniFee != 500) && (_params.uniFee != 3_000) && (_params.uniFee != 10_000)) {
            revert Errors.InvalidUniFee();
        }
        if (!(KYOTO_HUB.isWhitelistedInputToken(_params.tokenIn))) revert Errors.InvalidToken();
        if (_params.recipient == address(0)) revert Errors.ZeroAddress();
        if (_params.amountIn == 0 || _params.amountOut == 0) revert Errors.InvalidAmount();
        if (_params.deadline < block.timestamp) revert Errors.InvalidDeadline();
    }

    /**
     * @dev validates recipient's preferences.  Does not revert.
     * @return true when valid preferences, false when invalid
     */
    function _validatePreferences(DataTypes.Preferences memory _preferences) internal view returns (bool) {
        return ((_preferences.slippageAllowed != 0) && (KYOTO_HUB.isWhitelistedOutputToken(_preferences.tokenAddress)));
    }

    //////////////////////////////
    //      View Functions      //
    //////////////////////////////

    function getAdminFee() external view returns (uint256) {
        return adminFee;
    }

    ///////////////////////////////
    //      Admin Functions      //
    ///////////////////////////////

    /**
     * @dev Admin function to set the fee
     * @param _adminFee the new fee amount
     * Requirements:
     *  - 'adminFee" <= 'MAX_ADMIN_FEE'
     *  - msg.sender is the owner
     */
    function setAdminFee(uint256 _adminFee) external onlyHubOwner {
        if (_adminFee > MAX_ADMIN_FEE) revert Errors.InvalidAdminFee();
        adminFee = _adminFee;
    }

    /**
     * @dev Admin function to withdraw tokens from a given token address
     * Note: '_token' is not validated before passing it in as an argument
     * '_token' must always be verified manually before being called by the admin
     * @param _token the address of the token to withdraw
     * @param _amount the amount of token to withdraw
     * Requirements:
     *  - '_token' != address(0)
     *  - msg.sender is the owner
     *  - Token balance of address(this) > 0
     */
    function withdraw(address _token, uint256 _amount) external onlyHubOwner {
        if (IERC20(_token).balanceOf(address(this)) == 0) revert Errors.ZeroBalance();
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Admin function to pause payments
     */
    function pause() external onlyHubOwner {
        _pause();
    }

    /**
     * @dev Admin function to unpause payments
     */
    function unpause() external onlyHubOwner {
        _unpause();
    }
}
