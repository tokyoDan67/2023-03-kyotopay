// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title IPreferences

import {DataTypes} from "../libraries/DataTypes.sol";

interface IKyotoHub {
    //////////////////////////
    ///   User Functions   ///
    //////////////////////////
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
    function isWhitelistedInputToken(address) external view returns (bool);
    function isWhitelistedOutputToken(address) external view returns (bool);
    function getPartnerDiscount(address) external view returns (uint256);
    function getRecipientPreferences(address _recipient) external view returns (DataTypes.Preferences memory);

    //////////////////////////
    ///   Admin Functions   ///
    ///////////////////////////
    function addToInputWhitelist(address) external;
    function addToOutputWhitelist(address) external;
    function revokeFromInputWhitelist(address) external;
    function revokeFromOutputWhitelist(address) external;
    function setPartnerDiscount(address, uint256) external;
    function pause() external;
    function unpause() external;
}
