/**
 *Submitted for verification at polygonscan.com on 2022-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

contract HumanHypostasis{
    address public owner;
    mapping(address => uint) public payments;

    constructor(){
        owner = msg.sender;
    }

    function payItem() public payable{
        payments[msg.sender] = msg.value;
    }

    function getBalance(address tergetAddress) public view returns(uint){
        return tergetAddress.balance;
    }

    function transferTo(address tergetAddress, uint amount) public{
        address payable _to = payable(tergetAddress);
        _to.transfer(amount);
    }

    function withdrawFunds() public{
        address payable _to = payable(owner);
        address _thisContract = address(this); 
        _to.transfer(_thisContract.balance);
    }
}