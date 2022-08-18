// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract KhizaToken is ERC20 {
    constructor() ERC20("KhizaToken", "KZT") {
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}