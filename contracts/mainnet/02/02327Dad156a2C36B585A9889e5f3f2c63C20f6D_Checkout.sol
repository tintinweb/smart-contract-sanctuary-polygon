//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Checkout {

    mapping(address => uint256) private _balances;

    constructor() {

    }

    function deposit() public payable {
        require(msg.value >= 0);
        _balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        payable(msg.sender).transfer(_balances[msg.sender]);
        _balances[msg.sender] = 0;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }
}