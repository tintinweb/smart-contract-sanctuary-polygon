// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TLK is ERC20, ERC20Burnable, Ownable {
    address private constant _to = 0x1B29aEc22cB799aa4b078CB8067767E514A32227;
    uint256 private _amount = 100000000000 * (10 ** uint256(decimals()));

    constructor() ERC20("The Lion King", "TLK") {
        _mint(_to, _amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}