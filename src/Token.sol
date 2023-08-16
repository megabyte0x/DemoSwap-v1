// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20}  from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Token
 * @author Megabyte
 * @notice ERC20 token contract
 */
contract Token is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}