// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {

constructor()public{

}

uint public number;
function setData(uint _Data) public {
    number = _Data;
}

function getData() view public returns(uint){
    return number;
}

    
}