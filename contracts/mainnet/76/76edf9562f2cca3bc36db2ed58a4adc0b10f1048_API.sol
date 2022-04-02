/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract API {
    address public protocol;
    address public owner;

    mapping(address => string) public staticData;

    event NewListing(address indexed token, string hashString);

    constructor(address _protocol, address _owner) {
        protocol = _protocol;
        owner = _owner;
    }

    function addStaticData(address token, string memory hashString) external {
        require(
            protocol == msg.sender || owner == msg.sender,
            "Only the DAO or the Protocol can add data."
        );
        staticData[token] = hashString;
        emit NewListing(token, hashString);
    }

    function removeStaticData(address token) external {
        require(owner == msg.sender);
        delete staticData[token];
    }

    function setProtocolAddress(address _protocol) external {
        require(
            owner == msg.sender,
            "Only the DAO can modify the Protocol address."
        );
        protocol = _protocol;
    }
}