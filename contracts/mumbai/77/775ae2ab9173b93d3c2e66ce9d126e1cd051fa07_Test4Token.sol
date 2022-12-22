/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Test4Token {

    uint public price = 1300000000000000000;
    address public owner;
    mapping (address => uint) public tokenBalances;
    string public name;
    string public symbol;

    constructor () {
        owner = msg.sender;
        tokenBalances[address(this)] = 10000;
        name = "Test4";
        symbol = "TEST4";
    }

    function refill(uint amount) public {
        require(msg.sender == owner, "only the owner can refill.");
        tokenBalances[address(this)] += amount;
    }

    function buy(uint amount) public payable {
        require(msg.value >= amount * 1300000000000000000, "you must pay at least 1.3 MATIC per token.");
        require(tokenBalances[address(this)] >= amount, "not enough token in stock to complete.");
        tokenBalances[address(this)] -= amount;
        tokenBalances[msg.sender] += amount;
    }

    function withdrawAll() public {
        require(msg.sender == owner, "you not owner.");
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}