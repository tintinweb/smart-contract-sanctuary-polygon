// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MinerioToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Minerio Token", "RIO") {
        _mint(msg.sender, 300000000 * 10 ** decimals());
    }
}