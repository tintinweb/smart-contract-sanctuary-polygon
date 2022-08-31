// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20.sol";

contract BLOO is ERC20("BLOO", "BLC", 18) {

    uint256 public mintAmount = 480_000 ether;
    address public _owner;

    constructor (address __owner) {
        _owner = __owner;
        _mint(_owner, mintAmount);
        _transferOwnership(__owner);
    }

    function mintBloo() external onlyOwner {
        _mint(_owner, mintAmount);
    }
}