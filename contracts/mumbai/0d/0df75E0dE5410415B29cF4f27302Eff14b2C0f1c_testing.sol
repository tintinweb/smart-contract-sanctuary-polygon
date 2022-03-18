/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

pragma solidity ^0.7.2;     

contract testing
{
    string private Hello = "helloo world";

    function hello () public view returns(string memory)
    {
        return Hello;
    }
}