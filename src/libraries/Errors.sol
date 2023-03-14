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

    ///////////////
    ///   Pay   ///
    ///////////////

    /**
     *  Invalid value(s) for arguments 'amountIn' or '_amountOut'.  '_amountIn' is zero or '_amountOut' is zero
     */
    error InvalidAmount();

    /**
     *  Argument '_fee' in setFee cannot be greater than MAX_FEE
     */
    error InvalidAdminFee();

    /**
     *  Argument '_tokenIn' is not a valid input token
     */
    error InvalidToken();

    /**
     * address(this) has a token balance of 0 for the passed in '_tokenAddress"
     */
    error ZeroBalance();
} 