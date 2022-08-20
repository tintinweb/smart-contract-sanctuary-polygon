// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable
{
    constructor (string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals)
    {
        mint (100000000);
    }

    function mint (uint256 amount) public onlyOwner
    {
        address owner = msg.sender;
        _mint (owner, amount);

    }
}