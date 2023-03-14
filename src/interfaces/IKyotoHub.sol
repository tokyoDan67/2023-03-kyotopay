// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IPreferences

import {DataTypes} from "../libraries/DataTypes.sol";
interface IKyotoHub {
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
    function setPreferences(DataTypes.Preferences calldata) external;

    //////////////////////////
    ///   View Functions   ///
    //////////////////////////
    function isWhitelistedInputToken(address) external view returns(bool);
    function isWhitelistedOutputToken(address) external view returns(bool);
    function getRecipientPreferences(address _recipient) external view returns (DataTypes.Preferences memory);
    function validateRecipientPreferences(address) external view returns (bool);
}

