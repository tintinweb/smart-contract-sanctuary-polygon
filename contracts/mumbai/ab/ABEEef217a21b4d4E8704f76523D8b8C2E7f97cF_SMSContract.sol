//SPDX-License-Identifier: UNLICENSED
//Depolyed Address: 0x7A60a45F4f48F257d6302e2fb9AD38c411c0B6cA
pragma solidity ^0.8.0;

contract SMSContract{

    address payable owner;

    event Donate(
        address from,
        uint256 amount
    );

    constructor(){
       owner = payable(msg.sender);
    }

    function newDonation(uint256 _amount) public payable{
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Failed to send money");
        emit Donate(msg.sender, _amount);
    }
}