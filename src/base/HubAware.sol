// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title HubOwnable
/// Protocol Version 1.1

import {KyotoHub} from "../KyotoHub.sol";

abstract contract HubAware {
    KyotoHub immutable KYOTO_HUB;
    constructor(address _hub) {
        KYOTO_HUB = KyotoHub(_hub);
    }
}
