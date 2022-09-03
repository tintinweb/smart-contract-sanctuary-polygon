// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Token {
    address public owner;
    uint256 public up;
    uint256 public down;

    mapping(address=>bool) voters;

    constructor(){
        owner = msg.sender;
    }


    event updown(
        string indexed updown,
        address indexed voter
    );


    function vote(string memory _vote) public{
        require(!voters[msg.sender], "you have already voted");
        if(keccak256(bytes(_vote)) == keccak256(bytes("up"))){
            up++;
        }else{
            down++;
        }

        voters[msg.sender] = true; 

        emit updown(_vote, msg.sender);
    }



}