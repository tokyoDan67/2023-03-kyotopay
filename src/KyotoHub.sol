// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title Kyoto Hub
/// Protocol Version 1.1 

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Errors} from "./libraries/Errors.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {IKyotoHub} from "./interfaces/IKyotoHub.sol";

// To Do: 
// - Need to make 2 step ownable...
// - Need to make a constants library
// - Add events
// - Convert whitelisted tokens to enumerable set
// - Change mappings to private...
contract KyotoHub is IKyotoHub, Pausable, Ownable {
    // Change to private
    uint256 public constant DECIMALS = 10_000;

    // mapping for prferences
    // Change to private and create custom getters...
    mapping(address => DataTypes.Preferences) public recipientPreferences;
    mapping(address => bool) public whitelistedInputTokens;
    mapping(address => bool) public whitelistedOutputTokens;

    constructor() Ownable() {}

    /**
     * @notice sets the sender's receiving preferences. 
     * @param _preferences the sender's given preferences
     * Note: slippageAllowed is inversed. For example, 9_900 is 1% slippage
     * Requirements:
     *  - '_preferences.slippageAllowed' is not 0% (i.e. >= 10,000) or 100% (i.e. 0)
     *  - '_preferences.tokenAddress' is a valid output token found in whitelistedOutputTokens
     */
    function setPreferences(DataTypes.Preferences calldata _preferences) external whenNotPaused {
        if ((_preferences.slippageAllowed == 0) || (_preferences.slippageAllowed >= DECIMALS)) {
            revert Errors.InvalidRecipientSlippage();
        }
        if (!(whitelistedOutputTokens[_preferences.tokenAddress])) revert Errors.InvalidRecipientToken();

        recipientPreferences[msg.sender] = _preferences;
    }

    /**
     * @dev Admin function to add a token to the input whitelist
     * @param _token the address of the token
     * Requirements:
     *  - '_token" != address(0)
     *  - msg.sender is the owner
     */
    function addToInputWhitelist(address _token) external onlyOwner {
        if (_token == address(0)) revert Errors.ZeroAddress();
        whitelistedInputTokens[_token] = true;
    }

    /**
     * @dev Admin function to revoke a token from the input whitelist
     * @param _token the address of the token
     * Requirements:
     *  - '_token" != address(0)
     *  - msg.sender is the owner
     */
    function revokeFromInputWhitelist(address _token) external onlyOwner {
        if (_token == address(0)) revert Errors.ZeroAddress();
        delete whitelistedInputTokens[_token];
    }

    /**
     * @dev Admin function to add a token to the output whitelist
     * @param _token the address of the token
     * Requirements:
     *  - '_token" != address(0)
     *  - msg.sender is the owner
     */
    function addToOutputWhitelist(address _token) external onlyOwner {
        if (_token == address(0)) revert Errors.ZeroAddress();
        whitelistedOutputTokens[_token] = true;
    }

    /**
     * @dev Admin function to revoke a token from the output whitelist
     * @param _token the address of the token
     * Requirements:
     *  - '_token" != address(0)
     *  - msg.sender is the owner
     */
    function revokeFromOutputWhitelist(address _token) external onlyOwner {
        if (_token == address(0)) revert Errors.ZeroAddress();
        delete whitelistedOutputTokens[_token];
    }

    function isWhitelistedInputToken(address _token) external view returns(bool){
        return whitelistedInputTokens[_token];
    }

    function isWhitelistedOutputToken(address _token) external view returns(bool) {
        return whitelistedOutputTokens[_token];
    }

    // function validateRecipientPreferences(address _recipient) external view returns (bool) {
    //     return _validatePreferences(recipientPreferences[_recipient]);
    // }

    function getRecipientPreferences(address _recipient) external view returns (DataTypes.Preferences memory) {}

    /**
     * @dev Admin function to pause payments
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Admin function to unpause payments
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}