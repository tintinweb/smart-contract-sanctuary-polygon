/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract AuthContract {
    uint public NOACCESS = 0;
    uint public READER = 1;
    uint public WRITER = 2;
    uint public APPROVER = 3;
    uint public OWNER = 4;
    address  public owner;
    mapping(address=>uint) public authUsers;

    modifier atlestReader (){
        require(authUsers[msg.sender] > NOACCESS || msg.sender == owner, "The sender is not whitelisted" );
        _;
    }
    
    modifier atleastWriter(){
        require(authUsers[msg.sender] > READER || msg.sender == owner, "The sender is not whitelisted" );
        _;
    }

    modifier atleastApprover(){
        require(authUsers[msg.sender] > WRITER || msg.sender == owner, "The sender is not whitelisted" );
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner" );
        _;
    }

    constructor() {
        owner = msg.sender;
        authUsers[msg.sender] = OWNER;
    }

    function addReader(address _reader) public atleastWriter{
        require(authUsers[_reader]==0, "No permissions to alter status");
        authUsers[_reader] = READER;
    }

    function addWriter(address _writer) public atleastApprover{
        require(authUsers[_writer] < 2, "No permissions to alter status");
        authUsers[_writer] = WRITER;
    }

    function addApprover(address _approver) public onlyOwner{
        require(authUsers[_approver] < 3, "No permissions to alter status");
        authUsers[_approver] = APPROVER;
    }

    function transferOwnership(address _owner) public onlyOwner{
        owner = _owner;
        authUsers[owner] = OWNER;
    }
}