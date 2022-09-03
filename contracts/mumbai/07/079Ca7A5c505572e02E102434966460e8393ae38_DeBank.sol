/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract DeBank
{
    //struct for costumers' information
    struct costumer
    {
        string Name;
        uint Age;
        address wallet;
        uint weight;  // It makes users to register their information before locking their money
    }

    address public owner;
    uint8 public Gas;
    mapping (address => costumer) register;
    event ENTER (address indexed costumer,string name);

    constructor (uint8 gas)
    {
        owner=msg.sender;
        Gas=gas;
    }

    // Users should enter their info at first
    function Register (string memory name, uint age) public 
    {
        register[msg.sender]=costumer(name,age,msg.sender,1);
        emit ENTER (msg.sender,name);
    }

    // struct for locktime and amount of value 
    struct locked
    {
        uint end;
        uint amount;
    }

    mapping(address => locked) users;
    event LOCK (address indexed costumer,uint indexed locktime,uint indexed value);
    event WITHDRAW (address indexed costumer, address indexed to,uint value);
 
    //Users should specify how much money they want to lock for a specific time
    function lock(uint lockTime) public payable 
    {
        require(msg.value>0, "The value should be more than this");
        require(register[msg.sender].weight==1, "Please register your information");
        users[msg.sender]=locked(block.timestamp + lockTime,msg.value);
        emit LOCK (msg.sender,block.timestamp+lockTime,msg.value);
    }

    // At certain time users can withdraw their money and pay some ether as gas.
    function withdraw(address payable user) public 
    {
        require(block.timestamp>=users[msg.sender].end, "Please wait till the lock time passes");
        uint value = users[msg.sender].amount - (Gas * 0.01 ether);
        emit WITHDRAW (msg.sender,user,users[msg.sender].amount- (Gas * 0.01 ether));
        users[msg.sender].end=0;
        users[msg.sender].amount=0;
        user.transfer(value);
    }

    modifier OnlyOwner ()
    {
        require (msg.sender == owner);
        _;
    }
    
    //A function that tranfers the remaining value from contract account to the owner's 
    function WithdrawOwner () public OnlyOwner
    {
        uint balanceContractt = address(this).balance;
        withdraw_owner (owner, balanceContractt);
    }
    
    //An overloading function that tranfers the money from contract account to the owner's 
    function withdraw_owner(address _address, uint256 _amount) private
    {
        (bool success,) = _address.call {value: _amount} ("");
        require(success, "Transfer failed.");
    }
}