/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract EMS{
    //variables

    struct mail{                   
        string data;
        address from;
        uint256 unix;
    }

    mapping (address => mapping(uint256 => mail)) public mails; 
    mapping (address => uint256) private incoming; 
    mapping (address => string) public RSApub;
    

    //constructor
    constructor(){}

    //functions
    function clearIncomings() public{
        incoming[msg.sender] = 0;
    }


    function setRSApub(string memory key) public {
        RSApub[msg.sender] = key;
    }

    function sendMessage(address to, string memory data) public{
        mails[to][incoming[to]] = mail(data, msg.sender, block.timestamp);
        incoming[to]++;
    }
    //Metamask interface

    function balanceOf(address account) public view returns (uint256) {
        return incoming[account];
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function symbol() public pure returns (string memory) {
        return "mail";
    }

}