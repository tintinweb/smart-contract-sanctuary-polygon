/**
 *Submitted for verification at polygonscan.com on 2022-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Whitelist {

    address owner; // variable that will contain the address of the contract deployer
    mapping(address => bool) whitelistedAddresses;
    mapping(address => bool) lawyers;

    constructor() {
        owner = msg.sender; // setting the owner the contract deployer
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyLawyer() {
        bool isLaywer = lawyers[msg.sender];
        require(isLaywer, "Lawyer: caller is not a lawyer");
        _;
    }

    function addLawyer(address _address) public onlyOwner {
        lawyers[_address] = true;
    }
    function removeLawyer(address _address) public onlyOwner {
        lawyers[_address] = true;
    }
    function verifyLawyer(address _address) public view returns(bool) {
        bool userIsLawyer = lawyers[_address];
        return userIsLawyer;
    }

    function addUser(address _address) public onlyLawyer {
        whitelistedAddresses[_address] = true;
    }
    function removeUser(address _address) public onlyLawyer {
        whitelistedAddresses[_address] = true;
    }

    function verifyUser(address _address) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_address];
        return userIsWhitelisted;
    }

}