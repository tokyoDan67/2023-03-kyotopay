// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint256 private constant TOTAL_SUPPLY = 100_000_000 ether;

    constructor() ERC20("Mock", "MOCK") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}
