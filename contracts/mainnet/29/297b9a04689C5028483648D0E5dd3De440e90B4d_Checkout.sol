//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Checkout {

    mapping(address => uint256) private _balances;

    constructor() {

    }

    function deposit() public {

    }

    function withdraw() public {

    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }
}