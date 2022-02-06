/**
 *Submitted for verification at polygonscan.com on 2022-02-05
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.5.0 < 0.8.0;

contract HotelRoom{

    mapping(uint => uint) rooms;
    event rented(uint _no, address _owner);

    address payable public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyEmpty(uint no){
        require(rooms[no] == 0, "Not EMPTY!"); _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "ONLY OWNER!"); _;
    }

    function rent(uint noRoom) public payable onlyEmpty(noRoom){
        rooms[noRoom] = 1;
        emit rented(noRoom, msg.sender);
        owner.transfer(1 ether);
    }

}