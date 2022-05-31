/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

pragma solidity ^0.4.21;

contract DepositWithdrawal {
    
    mapping (address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        msg.sender.transfer(_amount);
    }
}