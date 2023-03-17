// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title HubOwnable
/// Protocol Version 1.1

import {Errors} from "../libraries/Errors.sol";
import {KyotoHub} from "../KyotoHub.sol";

abstract contract HubAware {
    KyotoHub immutable public KYOTO_HUB;
    constructor(address _hub) {
        if (_hub == address(0)) revert Errors.ZeroAddress();
        KYOTO_HUB = KyotoHub(_hub);
    }
}
