/**
 *Submitted for verification at polygonscan.com on 2022-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Test2Token {

    uint public price = 0.000007 ether;
    address public owner;
    mapping (address => uint) public tokenBalances;
    string public name;
    string public symbol;

    constructor () {
        owner = msg.sender;
        tokenBalances[address(this)] = 10000;
        name = "Test2";
        symbol = "TEST2";
    }

    function refill(uint amount) public {
        require(msg.sender == owner, "only the owner can refill.");
        tokenBalances[address(this)] += amount;
    }

    function buy(uint amount) public payable {
        require(msg.value >= amount * 0.000007 ether, "you must pay at least 0.000007 ETH per token.");
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