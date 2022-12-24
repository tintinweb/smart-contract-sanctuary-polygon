/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

pragma solidity 0.8.0;

contract GenerateNum{
    function RandomNum() public view returns(uint){
        return (uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % 99) + 1 ;
    }
}