// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract CONE is ERC20, Ownable {
    constructor() ERC20("CONE", "CONE") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}