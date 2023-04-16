/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 <0.9.0;


contract contractINFO {

address  public contractAddres = address(this);
address  public ownerAddress;


constructor() {
    ownerAddress=msg.sender;
}

receive() external payable{}
fallback() external payable{}

modifier ownerOnly() {
    require(msg.sender==ownerAddress, "Only Owner Can Call");
    _;
}


function sendETHcontract() public payable {
}


function sendETHAddress(address payable userAddress, uint _amount) public ownerOnly{
    bool sent = userAddress.send(_amount);
    require(sent==true, "Not Sent");
    
}

function viewOwnerETHBal() public view returns(uint){
    return ownerAddress.balance;
}


function viewETHBal() public view returns(uint){
    address msgSender=msg.sender;
    return msgSender.balance;
}

function viewETHBalContract() public view returns(uint){
    return address(this).balance;
}



}