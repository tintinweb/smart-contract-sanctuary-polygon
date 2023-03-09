/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// File: contracts/voting.sol


pragma solidity ^0.6.6;

contract Voting{
    
    struct Aspirant{
        uint id;
        string name;
        uint voteCount;
    }
    
    mapping (uint => Aspirant) public aspirants;
    uint public aspirantcount;
    mapping (address => bool) public voter;
    
    constructor() public{
        addAspirant("Dave");
        addAspirant("Lucy");
    }
    
    function addAspirant(string memory _name) private{
        aspirantcount++;
        aspirants[aspirantcount] = Aspirant(aspirantcount, _name, 0);
    }
    
    function vote(uint _aspirantid) public{
        require(!voter[msg.sender]);
        
        voter[msg.sender] = true;
        aspirants[_aspirantid].voteCount ++;
        
    }
}