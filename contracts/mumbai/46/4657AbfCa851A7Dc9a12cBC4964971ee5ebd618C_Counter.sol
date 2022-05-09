/**
 *Submitted for verification at polygonscan.com on 2022-05-09
*/

pragma solidity ^0.8.0;

contract Counter {
    uint public counter;
    event Increment(uint counter); 

    function setCounter() public {
        counter += 1;
        emit Increment(counter);
    }
}