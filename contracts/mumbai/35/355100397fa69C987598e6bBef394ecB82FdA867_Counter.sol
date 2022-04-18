/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

pragma solidity ^0.8.7;

contract Counter {
    uint public count;
    uint public changeAmount;

    function get() public view returns (uint) {
        return count;
    }
    
    function inc() public {
        count += 1;
        changeAmount += 1;
    }

    function dec() public {
        count -= 1;
        changeAmount += 1;
    }
}