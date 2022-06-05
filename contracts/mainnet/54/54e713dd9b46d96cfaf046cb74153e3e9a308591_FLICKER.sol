/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// File: contracts/FLICKER.sol



pragma solidity >=0.7.0 <0.9.0;


contract FLICKER {
 
   
    mapping (address => uint) public balances;


    event Sent(address from, address to, uint amount);

    function send(address receiver) external payable {
       payable(receiver).transfer(msg.value);
        
        emit Sent(msg.sender, receiver, msg.value);
    }
}