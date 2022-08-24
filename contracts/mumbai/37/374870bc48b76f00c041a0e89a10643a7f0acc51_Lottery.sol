/**
 *Submitted for verification at polygonscan.com on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract Lottery{
    address public manager;
    uint public noofcontributors;
    address public loterywinner;
    struct Participant{
        address wallet;
        uint256 value;
    }
    mapping(address=>Participant) public participants;
    address payable[] public  participantsWallet;
    constructor()
    {
        manager = msg.sender;
    }

    receive() external payable{
        require(msg.value > 1000 wei , "minimum 1 ether");
        Participant storage person = participants[msg.sender];
        if(person.value == 0){
            noofcontributors++;
            participantsWallet.push(payable(msg.sender));
        }
        person.value += msg.value;
        person.wallet = payable(msg.sender);
    }
    function getallParticipents() public view returns(address[] memory , uint[] memory){
        address [] memory walletarray = new address[](noofcontributors);
        uint [] memory walletvalue = new uint[](noofcontributors);
          for(uint i=0 ; i<participantsWallet.length ; i++){
            Participant storage person = participants[participantsWallet[i]];
            walletarray[i] = person.wallet;
            walletvalue[i] = person.value;
        } 
        return (walletarray,walletvalue  );
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function getUserinvestment() view  public returns(uint){
        Participant storage person = participants[msg.sender];
        return person.value;
    }
    function random(uint number) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }
    function selectwinner()  public {
        require(msg.sender == manager , "only manager can call");
        require(noofcontributors >=3 , "player ar not up to mark to select winner");
        uint r = random(noofcontributors);
        address payable  winner;
        uint index = r%participantsWallet.length;
        winner = participantsWallet[index];
        winner.transfer(address(this).balance);
        for(uint i=0 ; i<participantsWallet.length ; i++){
            Participant storage person = participants[participantsWallet[i]];
            person.wallet = 0x0000000000000000000000000000000000000000;
            person.value=0;
        } 
        participantsWallet = new address payable[](0);
       noofcontributors=0;
       loterywinner = winner;
    }
}