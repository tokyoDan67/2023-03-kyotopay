// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


/// @title DataTypes
/// Version 1.1

library DataTypes {
    struct Preferences {
        address tokenAddress;
        uint96 slippageAllowed;
    }
} 