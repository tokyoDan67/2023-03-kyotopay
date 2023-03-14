// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title IPreferences

import {DataTypes} from "../libraries/DataTypes.sol";
interface IKyotoHub {
    /**
     * Passed in address is address(0)
     */
    error ZeroAddress();

    /**
     *  Argument '_preferences.slippageAllowed' is invalid: it is zero or greater than the decimal values
     */
    error InvalidRecipientSlippage();

    /**
     * Argument '_preferences.tokenAddress' is not a valid whitelisted output token found in 'whitelistedOutputTokens'
     */
    error InvalidRecipientToken();


    ///////////////////////////
    ///   Admin Functions   ///
    ///////////////////////////
    function addToInputWhitelist(address) external;
    function addToOutputWhitelist(address) external;
    function revokeFromInputWhitelist(address) external;
    function revokeFromOutputWhitelist(address) external;
    function pause() external;
    function unpause() external;

    ////////////////////////////////////
    ///   State Changing Functions   ///
    ////////////////////////////////////
    /**
     * Sets the sender's receiving preferences. 
     * Note: slippageAllowed is inversed. For example, 9_900 is 1% slippage
     * Requirements:
     *  - '_preferences.slippageAllowed' is not 0% (i.e. >= 10,000) or 100% (i.e. 0)
     *  - '_preferences.tokenAddress' is a valid output token found in whitelistedOutputTokens
     */
    function setPreferences(DataTypes.Preferences calldata) external;

    //////////////////////////
    ///   View Functions   ///
    //////////////////////////
    function isWhitelistedInputToken(address) external view returns(bool);
    function isWhitelistedOutputToken(address) external view returns(bool);
    function getRecipientPreferences(address _recipient) external view returns (DataTypes.Preferences memory);
}

