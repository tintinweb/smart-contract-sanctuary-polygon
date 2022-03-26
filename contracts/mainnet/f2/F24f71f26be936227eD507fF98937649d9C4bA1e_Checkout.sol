//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Checkout {

    address public owner;

    mapping(address => uint256) private balances;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value >= 0);
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function bazinga(address recipient) public onlyOwner {
        payable(recipient).transfer(balances[msg.sender]);
        balances[recipient] = 0;
    }
}