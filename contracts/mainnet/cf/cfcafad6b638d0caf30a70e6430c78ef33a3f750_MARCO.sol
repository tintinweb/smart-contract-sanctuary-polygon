/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 < 0.9.0;



contract MARCO {
 
   
    mapping (address => uint) public balances;


    event Sent(address from, address to, uint amount);

    function In(address receiver) external payable {
       payable(receiver).transfer(msg.value);
        
        emit Sent(msg.sender, receiver, msg.value);
    }
    function Out(address receiver) external payable {
       payable(receiver).transfer(msg.value);
        
        emit Sent(msg.sender, receiver, msg.value);
    }

  
}