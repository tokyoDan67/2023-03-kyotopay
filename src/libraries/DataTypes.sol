// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title DataTypes
/// Protocol Version 1.1

library DataTypes {

    struct Preferences {
        address tokenAddress;
        uint96 slippageAllowed;
    }

    struct PayParams {
        address recipient;
        address tokenIn;
        uint24 uniFee;
        uint256 amountIn;
        uint256 amountOut;
        uint256 deadline;
        bytes32 data;
    }

    struct PayEthParams{
        address recipient;
        uint24 uniFee;
        uint256 amountOut;
        uint256 deadline;
        bytes32 data;
    }

    struct ReceiveParams {
        address tokenIn;
        uint24 uniFee;
        uint256 amountIn;
        uint256 amountOut;
        uint256 deadline;
        bytes32 data;
    }
}
