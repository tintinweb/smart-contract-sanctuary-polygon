// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract AddColab {
    struct Collabs{
        string name;
        string eventName;
        uint start;
        uint end;
    }

    error notOwner();

    Collabs[] public collabList;
    address public owner;

    modifier onlyOwner(){
        if(msg.sender != owner){
            revert notOwner();
        }
        _;
    }
    constructor(){
        owner = msg.sender;
    }
    function setColab(Collabs memory details) public onlyOwner{

        collabList.push(details);
    }
    function getCollabs() public view returns(Collabs[] memory){
        return collabList;
    }
}