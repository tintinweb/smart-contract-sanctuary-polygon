/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Kyc {
    address owner;
    mapping(address => bool) internal verifications;

    constructor() {
        owner = msg.sender;
    }

    function verify(address _address) public {
        require(msg.sender == owner);
        verifications[_address] = true;
    }

    function unverify(address _address) public {
        require(msg.sender == owner);
        verifications[_address] = false;
    }

    function verified(address _address) public view returns(bool) {
        return verifications[_address] == true;
    }
}