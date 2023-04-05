/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// File: contracts\whitelistedTokens.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract whitelistedTokens {
    mapping(address => bool) public isWhitelisted;
     address immutable public adminAddress;
     constructor() {
         adminAddress = msg.sender;
    }
    modifier onlyAdmin() {
    require(msg.sender == adminAddress, "Only the contract owner can perform this action.");
    _;
    }   
    function whitelistAddress(address adr) external onlyAdmin{
        isWhitelisted[adr] =true;
    }
    function iswhitelist(address adr) public view returns(bool){
        return isWhitelisted[adr];
    }
}