/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

pragma solidity ^0.4.24;

contract LuckyNumber {
    mapping (address => uint) numbers;

    function setNum(uint _num) public {
        numbers[msg.sender] = _num;
    }

    function getNum(address _myAddress) public view returns (uint) {
        return numbers[_myAddress];
    }
}