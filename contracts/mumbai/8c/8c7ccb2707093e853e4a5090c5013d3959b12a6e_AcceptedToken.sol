// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract AcceptedToken is ERC20 {
    constructor() ERC20("AcceptedToken", "ACT") {
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}