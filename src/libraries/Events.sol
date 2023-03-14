// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title Errors
/// Protocol Version 1.1

library Events {
    ////////////////////
    ///   KyotoHub   ///
    ////////////////////
    event AddedWhitelistedInputToken(address indexed token);
    event AddedWhitelistedOutputToken(address indexed token);
    event RevokedWhitelistedInputToken(address indexed token);
    event RevokedWhitelistedOutputToken(address indexed token);

    /////////////////
    ///   Payer   ///
    /////////////////

    /**
     * Emitted to pass data from payment function
     */
    event Payment(address recipient, address indexed tokenAddress, uint256 indexed amountIn, bytes32 indexed data);

}