/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

pragma solidity ^0.8.4;

contract polite{
    uint256 private num;
    address public owner;
    constructor(uint256 _num) {
        num = _num;
        owner = msg.sender;
    }

    function getNum() public view returns(uint256){
        require(msg.sender == owner);
        return num;
    }

    function setNum(uint256 _num) public{
        require(msg.sender == owner);
        num = _num;
    }
    
}