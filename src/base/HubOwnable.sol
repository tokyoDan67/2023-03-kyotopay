// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title HubOwnable
/// Protocol Version 1.1

import {Errors} from "../libraries/Errors.sol";
import {HubAware} from "./HubAware.sol";

abstract contract HubOwnable is HubAware {
    constructor(address _kyotoHub) HubAware(_kyotoHub) {}

    modifier onlyHubOwner() {
        _validateMsgSenderHubOwner();
        _;
    }

    function _validateMsgSenderHubOwner() internal view {
        if (msg.sender != KYOTO_HUB.owner()) revert Errors.NotHubOwner();
    }
}
