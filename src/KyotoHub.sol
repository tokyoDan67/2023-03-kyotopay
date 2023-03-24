// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title Kyoto Hub
/// Protocol Version 1.1 

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {IKyotoHub} from "./interfaces/IKyotoHub.sol";

contract KyotoHub is IKyotoHub, Pausable, Ownable2Step {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant PRECISION_FACTOR = 10_000;

    // mapping for prferences
    mapping(address => DataTypes.Preferences) private recipientPreferences;
    EnumerableSet.AddressSet private whitelistedInputTokens;
    EnumerableSet.AddressSet private whitelistedOutputTokens;

    constructor() Ownable2Step() {}

    /**
     * @notice sets the sender's receiving preferences. 
     * @param _preferences the sender's given preferences
     * Note: slippageAllowed is inversed. For example, 9_900 is 1% slippage
     * Requirements:
     *  - '_preferences.slippageAllowed' is not 0% (i.e. >= 10,000) or 100% (i.e. 0)
     *  - '_preferences.tokenAddress' is a valid output token found in whitelistedOutputTokens
     */
    function setPreferences(DataTypes.Preferences calldata _preferences) external whenNotPaused {
        if ((_preferences.slippageAllowed == 0) || (_preferences.slippageAllowed >= PRECISION_FACTOR)) {
            revert Errors.InvalidRecipientSlippage();
        }
        if (!(whitelistedOutputTokens.contains(_preferences.tokenAddress))) revert Errors.InvalidRecipientToken();

        recipientPreferences[msg.sender] = _preferences;

        emit Events.PreferencesSet(msg.sender, _preferences.tokenAddress, _preferences.slippageAllowed);
    }

    //////////////////////////////
    ///     Admin Functions    ///
    //////////////////////////////

    /**
     * @dev Admin function to add a token to the input whitelist
     * @param _token the address of the token
     * Requirements:
     *  - '_token" != address(0)
     *  - msg.sender is the owner
     */
    function addToInputWhitelist(address _token) external onlyOwner {
        if (_token == address(0)) revert Errors.ZeroAddress();
        
        whitelistedInputTokens.add(_token);
        emit Events.AddedWhitelistedInputToken(_token);
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
        whitelistedOutputTokens.add(_token);
        emit Events.AddedWhitelistedOutputToken(_token);
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
        whitelistedInputTokens.remove(_token);
        emit Events.RevokedWhitelistedInputToken(_token);
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
        whitelistedOutputTokens.remove(_token);
        emit Events.RevokedWhitelistedOutputToken(_token);
    }

    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice returns whether or not a token is a whitelisted input token
     * @param _token the token's address
     * @return true if '_token' is a whitelisted input token, false otherwise
     */
    function isWhitelistedInputToken(address _token) external view returns(bool){
        return whitelistedInputTokens.contains(_token);
    }

    /**
     * @notice returns whether or not a token is a whitelisted output token
     * @param _token the token's address
     * @return true if '_token' is a whitelisted output token, false otherwise
     */
    function isWhitelistedOutputToken(address _token) external view returns(bool) {
        return whitelistedOutputTokens.contains(_token);
    }

    /**
     * @notice returns all whitelisted input tokens
     * @return an address array containing all whitelisted input tokens
     */
    function getWhitelistedInputTokens() external view returns (address[] memory) {
        return whitelistedInputTokens.values();
    }

    /**
     * @notice returns all whitelisted output tokens
     * @return an address array containing all whitelisted output tokens
     */
    function getWhitelistedOutputTokens() external view returns (address[] memory) {
        return whitelistedOutputTokens.values();
    }

    /**
     * @notice returns a recipient's preferences
     * @param _recipient the recipient
     * @return A struct containing the _recipient's preferred token and allowed slippage
     */
    function getRecipientPreferences(address _recipient) external view returns (DataTypes.Preferences memory) {
        return recipientPreferences[_recipient];
    }

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