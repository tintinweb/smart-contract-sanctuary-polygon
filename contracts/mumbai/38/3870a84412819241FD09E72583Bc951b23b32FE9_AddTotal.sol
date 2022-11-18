pragma solidity ^0.8.0;

contract AddTotal{
    uint public myTotal = 0;

    function AddTotalValue(uint8 _myArgs) public {
        myTotal = myTotal + _myArgs;
    }
}