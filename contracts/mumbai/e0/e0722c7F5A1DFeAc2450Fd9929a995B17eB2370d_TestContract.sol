/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

pragma solidity ^0.8.13;

contract TestContract {

    uint public myNumber;

    uint private privateNumber;

    uint public constant constNumber = 5;

    function set(uint _num) public {
        myNumber = _num;
    }

      function get() public view returns (uint) {
        return myNumber;
    }

}