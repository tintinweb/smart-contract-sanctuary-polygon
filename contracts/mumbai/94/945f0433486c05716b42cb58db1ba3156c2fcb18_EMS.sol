/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract EMS{
    //variables

    struct mail{                   
        string data;
        address from;
    }

    mapping (address => mapping(uint256 => mail)) public mails; 
    mapping (address => uint256) private incoming; 

    

    //constructor
    constructor(){}

    //functions
    function clearIncomings() public{
        incoming[msg.sender] = 0;
    }

    function sendMessage(address to, string memory data) public{
        mails[to][incoming[to]] = mail(data, msg.sender);
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