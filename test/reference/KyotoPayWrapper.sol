// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {KyotoPay} from "../../src/KyotoPay.sol";

contract KyotoPayWrapper is KyotoPay {
    constructor(uint256 _fee, address _uniswapSwapRouterAddress, address _wethAddress)
        KyotoPay(_fee, _uniswapSwapRouterAddress, _wethAddress)
    {}

    function validatePreferences(Preferences memory _preferences) external view returns (bool) {
        return _validatePreferences(_preferences);
    }

    function getSenderFunds(address _tokenAddress, uint256 _amountIn) external {
        _getSenderFunds(_tokenAddress, _amountIn);
    }

    function sendRecipientFunds(address _tokenAddress, address _recipient, uint256 _amount) external {
        _sendRecipientFunds(_tokenAddress, _recipient, _amount);
    }
}
