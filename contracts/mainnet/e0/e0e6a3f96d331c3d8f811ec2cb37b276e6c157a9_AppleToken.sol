/**
 *Submitted for verification at polygonscan.com on 2022-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract AppleToken {

    uint public price = 8000000000000000000;
    address public owner;
    mapping (address => uint) public tokenBalances;
    string public name;
    string public symbol;
    event Bought(address indexed buyer, uint amount);

    constructor () {
        owner = msg.sender;
        tokenBalances[address(this)] = 440000;
        name = "Apple FS";
        symbol = "AAPL.FS";
    }

    function refill(uint amount) public {
        require(msg.sender == owner);
        tokenBalances[address(this)] += amount;
    }

    function buy(uint amount) public payable {
        require(msg.value >= amount * 8000000000000000000);
        require(tokenBalances[address(this)] >= amount);
        tokenBalances[address(this)] -= amount;
        tokenBalances[msg.sender] += amount;

        emit Bought(msg.sender, msg.value);
    }

    function withdrawAll() public {
        require(msg.sender == owner);
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}