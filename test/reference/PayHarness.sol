// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {DataTypes} from "../../src/libraries/DataTypes.sol";
import {Pay} from "../../src/Pay.sol";

contract PayHarness is Pay {
    constructor(uint256 _fee, address _hub, address _uniswapSwapRouterAddress, address _wethAddress)
        Pay(_fee, _hub, _uniswapSwapRouterAddress, _wethAddress)
    {}

    function validatePreferences(DataTypes.Preferences memory _preferences) external view returns (bool) {
        return _validatePreferences(_preferences);
    }

    function getSenderFunds(address _tokenAddress, uint256 _amountIn) external {
        _getSenderFunds(_tokenAddress, _amountIn);
    }

    function sendRecipientFunds(address _tokenAddress, address _recipient, uint256 _amount) external {
        _sendRecipientFunds(_tokenAddress, _recipient, _amount);
    }
}
