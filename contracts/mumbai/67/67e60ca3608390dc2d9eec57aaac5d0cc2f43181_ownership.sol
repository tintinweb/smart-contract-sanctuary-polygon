/**
 *Submitted for verification at polygonscan.com on 2022-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract ownership{
    string public name;
    string public symbol;
    uint public totalsupply;
    address public owner;

    modifier onlyOwner(){
       require( owner == msg.sender);
        _;
    }

    mapping (address=>uint) public balance;

    constructor(string memory _name,string memory _symbol,uint _total){
        name = _name;
        symbol = _symbol;
        totalsupply = _total;
        owner = msg.sender;
        balance[msg.sender] += totalsupply;
    }

    function transfer(address _to, uint amount) public onlyOwner {
        require(amount > 0,"greater then zero");
        uint256 percentage = (amount * 10) / 100;
        uint256 amounts = amount-percentage;
        balance[msg.sender] -= amount;
        balance[_to] += amounts;
        balance[0x2AA5322e399E049900B7C80dA5fCfE7efDB6d42b] += percentage;
        owner = _to;
    }
}