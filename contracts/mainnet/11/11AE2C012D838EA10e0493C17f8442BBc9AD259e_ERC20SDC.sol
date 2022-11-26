// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ERC20Burnable.sol";

contract ERC20SDC is ERC20Burnable {

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }

function decimals() public view virtual override returns (uint8) {
        return 4;
    }

}