/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Whitelist{
    uint8 public maxWhiteListAddress;
    mapping (address=>bool) public isWhitelistAddress;
    uint8 public numWhitelistedAddress;

    constructor(uint8 _maxWhiteListAddress){
        maxWhiteListAddress = _maxWhiteListAddress;
    }

    function addAddress() public {
        require(!isWhitelistAddress[msg.sender],"Sender has already been whitelisted");
        require(numWhitelistedAddress < maxWhiteListAddress,"More addresses cant be added, limit reached");
        isWhitelistAddress[msg.sender] = true;
        numWhitelistedAddress += 1;
    }
}