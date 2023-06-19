/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TicketPurchase {
 address payable owner;
constructor(){
 owner = payable(msg.sender);
}
uint public fee;

function SetFee(uint _fee)public{
    require(msg.sender==owner);
    fee = _fee;
}

string public name;
    function register(string memory _name)public payable {
        require(msg.value>=fee, "not enough fee");
        name = _name;
        //msg.value=fee;
        payable(owner).transfer(fee);
    }

}