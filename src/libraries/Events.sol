// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title Errors
/// Protocol Version 1.1

library Events {
    ////////////////////
    ///   KyotoHub   ///
    ////////////////////

    /**
     * Emitted when an input token is whitelisted
     */
    event AddedWhitelistedInputToken(address token);

    /**
     * Emitted when an output token is whitelisted
     */
    event AddedWhitelistedOutputToken(address token);

    /**
     * Emitted when an input token is removed from the whitelist
     */
    event RevokedWhitelistedInputToken(address token);

    /**
     * Emitted when an output token is removed from the whitelist
     */ 
    event RevokedWhitelistedOutputToken(address token);

    event PreferencesSet(address indexed msgSender, address token, uint96 slippageAllowed);

    /////////////////
    ///   Payer   ///
    /////////////////

    /**
     * Emitted to pass data from payment function
     */
    event Payment(address indexed recipient, address indexed tokenAddress, uint256 amountIn, bytes32 indexed data);
}