// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC20.sol";

contract KouanasToken is ERC20 {
    constructor() ERC20("Otaru Token", "OT") {
        _mint(address(0xdb64c1d2a5D416E9cD4c19481b595dFEa0fc2407), 1000000 * 10**18);
    }
}