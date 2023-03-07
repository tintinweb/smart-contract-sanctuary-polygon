// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TEST") {}

    function mint() public {
        _mint(msg.sender, 10000000000000000000000000000000000000000000);
    }

}