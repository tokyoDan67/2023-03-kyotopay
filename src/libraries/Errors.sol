// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title Errors
/// Protocol Version 1.1

library Errors {
    //////////////////
    ///   Global   ///
    //////////////////
    /**
     * Passed in address is address(0)
     */
    error ZeroAddress();

    ////////////////
    ///   Base   ///
    ////////////////
    error NotHubOwner();

    ////////////////////
    ///   KyotoHub   ///
    ////////////////////

    /**
     *  Argument '_preferences.slippageAllowed' is invalid: it is zero or greater than the decimal values
     */
    error InvalidRecipientSlippage();

    /**
     * Argument '_preferences.tokenAddress' is not a valid whitelisted output token found in 'whitelistedOutputTokens'
     */
    error InvalidRecipientToken();

    //////////////////////
    ///   Disburser   ///
    /////////////////////

    /**
     *  Invalid value(s) for arguments 'amountIn' or '_amountOut'.  '_amountIn' is zero or '_amountOut' is zero
     */
    error InvalidAmount();

    /**
     *  Argument '_fee' in setFee cannot be greater than MAX_FEE
     */
    error InvalidAdminFee();

    /**
     * Argument '_deadline' is set before block.timestamp
     */
    error InvalidDeadline();

    /**
     *  Argument '_tokenIn' is not a valid input token
     */
    error InvalidToken();

    /**
     * Argument '_uniFee' is not a valid Uniswap fee (i.e. not equal to 0.01%, 0.05%, 0.3%, or 1%)
     */
    error InvalidUniFee();

    /**
     * address(this) has a token balance of 0 for the passed in '_tokenAddress"
     */
    error ZeroBalance();
}
