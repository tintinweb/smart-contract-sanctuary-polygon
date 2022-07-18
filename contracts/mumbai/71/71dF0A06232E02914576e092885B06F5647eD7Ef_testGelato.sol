pragma solidity ^0.8.0;

contract testGelato {

    address public origin;
    address public sender;


    function test() public {

        origin = tx.origin;
        sender = msg.sender;
       
    }

}