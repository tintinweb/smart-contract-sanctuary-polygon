/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
contract etherLock{

   event Deposit (address indexed sender, uint amount);
   event Withdraw( address indexed caller, uint amount);

    struct UserStatus {
        uint amountLocked;
        address user;
        uint dueTime;
        uint presentTime;
    }
    mapping(address => UserStatus) public userStaus;
    mapping(address=> uint) public balanceOf;

    bool public paused;
    address public owner= msg.sender;
    uint public lockTime;
    uint public amount;


     function deposit (uint _amount) external payable{
         require( paused == false);
         if(_amount <3 ether) {
             revert("LESS THAN AMOUNT REQUIRED"); //amount must be more than 3 ether
         }
         if(_amount > 10 ether){
                 revert("MORE THAN AMOUNT REQUIRED");} //amount must be less than 10 ether
         emit Deposit(msg.sender, amount);
         balanceOf[msg.sender] += _amount;
         lockTime = block.timestamp + 1 minutes;
         

         UserStatus storage status = userStaus[msg.sender];
         uint amountLocked =_amount;
         address user= msg.sender;
         uint dueTime = lockTime;
         uint presentTime = block.timestamp;
         
     }
// To stop users from depositing
    function setPaused( bool _paused) public {
        require( msg.sender == owner, " NOT OWNER");
        paused =_paused;
    }


    function withdraw(uint _amount) public {
        require( lockTime < block.timestamp," LESS THAN DUE TIME"); 
             emit Withdraw(msg.sender,amount);
        require ( balanceOf[msg.sender] >= _amount, " INSUFFICIENT FUNDS");
        balanceOf[msg.sender] -= _amount;
       
    }
}