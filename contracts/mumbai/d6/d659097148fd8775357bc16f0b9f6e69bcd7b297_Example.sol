/**
 *Submitted for verification at polygonscan.com on 2022-12-11
*/

pragma solidity ^0.8.0;

contract Example {
  
    event Event1(string message);
    event Event2(string message);

    string public owner = "Lore da pawa, akhtar lawa";

    function function1() public {
        emit Event1("This is the first event");
    }

    function function2() public {
        emit Event2("This is the second event");
    }
}