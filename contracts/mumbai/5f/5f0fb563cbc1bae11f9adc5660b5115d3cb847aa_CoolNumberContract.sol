/**
 *Submitted for verification at polygonscan.com on 2022-07-02
*/

pragma solidity ^0.6.6;

contract CoolNumberContract {

    uint public coolNumber = 10;

    function setCoolNumber (uint _coolNumber) public
    {
        coolNumber = _coolNumber;
    }
}