// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title Interface for KyotoPay
/// Version 1.0

import {DataTypes} from "../libraries/DataTypes.sol";

interface IDisburser {
    /**
     * Emitted to pass data from payment function
     */
    event Payment(address recipient, address indexed tokenAddress, uint256 indexed amountIn, bytes32 indexed data);

    /**
     * Pays a recipient in their preferred token from a given input token
     * Requirements:
     *  - '_recipient' != address(0)
     *  - '_tokenIn' is a valid input token
     *  - '_amountIn' != 0
     *  - 'amountOut' != 0
     *  - '_uniFee' is a valid Uniswap pool fee
     *  - The executed swap will send the recipient more tokens than their slippageAllowed * '_amountOut'
     *  - The user's token balance > '_amountIn'
     *  - The user has approve the contract to transfer their tokens
     */
    function pay(
        address _recipient,
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _deadline,
        uint24 _uniFee,
        bytes32 _data
    ) external;

    /**
     * Pays a recipient in their preferred token from the given ether
     * Note: if the user has not set their preferences, they will receive WETH and not ETH
     * Requirements:
     *  - '_recipient' != address(0)
     *  -  WETH is a whitelisted input
     *  -  msg.value > 0
     *  - 'amountOut' != 0
     *  - '_uniFee' is a valid Uniswap pool fee
     *  - The executed swap will send the recipient more tokens than their slippageAllowed * '_amountOut'
     */

    function payEth(address _recipient, uint256 _amountOut, uint256 _deadline, uint24 _uniFee, bytes32 _data)
        external
        payable;
}
