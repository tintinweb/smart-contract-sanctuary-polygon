/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

pragma solidity ^0.8.13;

contract Counter {
    uint public count;

    function get() public view returns (uint) {
        return count;
    }

    function inc() public {
        count += 1;
    }

    function dec() public {
        count -= 1;
    }
}