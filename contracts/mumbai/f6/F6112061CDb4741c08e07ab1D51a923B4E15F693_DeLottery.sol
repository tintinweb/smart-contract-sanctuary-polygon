/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract DeLottery
{
    struct User
    {
        string Name;
        uint Age;
        address wallet;
        bool ticket; // a boolean to make users enter the lottery for once
    }

    struct Times
    {
        uint Ticket_Time; // buying tickets should've specific duration
    }

    mapping (address => User) public users; // users can get access to their information by public key
    event ENTER (address indexed user,string name);
    address public owner;
    address payable [] players;
    uint starttime;
    User USERS;
    Times TIMES;

    constructor (uint minute)
    {
        owner=msg.sender; // who deploys the contract is the owner
        starttime=block.timestamp; 
        TIMES.Ticket_Time=minute; // owner should set the time in minute for starting and finishing the lottery 
    }

    // each user should enter his/her name and age with paying 2 ether.
    function enter (string memory name, uint age) public payable
    {
        require (msg.sender != owner,"the owner can't enter the lottery");
        require (starttime+(TIMES.Ticket_Time*60)>block.timestamp,"time's up");
        require (msg.value == 0.1 ether, "It costs 0.1 ether to enter the lottery");
        require(!users[msg.sender].ticket,"the user has already bought the ticket.");
        users[msg.sender]=User(name,age,msg.sender,true);
        emit ENTER (msg.sender,name);
        players.push(payable(msg.sender));
    }
    
    // It shows the remaining time
    function showtime () public view returns (uint)
    {
        return (((starttime+(TIMES.Ticket_Time*60))-block.timestamp)/60);
    }
    event WINNER (address indexed winner,uint prize);
    function winner () public
    {
        require (msg.sender==owner, "only owner can call this function");
        require (starttime+(TIMES.Ticket_Time*60)<block.timestamp,"Not yet");
        uint random=uint(sha256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,owner, msg.data, players.length))); //It finds the winner randomly
        uint index = random % players.length;
        emit WINNER (players[index],(address(this).balance - 0.01 ether));
        players[index].transfer(address(this).balance - 0.01 ether); // The owner get 0.01 ether as a gas 
        uint balanceContractt = address(this).balance;
        withdraw_owner (owner, balanceContractt);
        USERS.Name=users[players[index]].Name;
        players = new address payable [] (0); // It resets the players' addresses
    }

    // an overloading function for getting gas
    function withdraw_owner(address _address, uint256 _amount) private
    {
        (bool success,) = _address.call {value: _amount} ("");
        require(success, "Transfer failed.");
    }

    // also owner can reveal the winner's name
    function winner_name () public view returns (string memory)
    {
        require (msg.sender==owner, "only owner can show the winner's name");
        return USERS.Name;
    }

    // showing the balance of contract
    function balance () public view returns (uint)
    {
        require (msg.sender==owner, "only owner can call this function");
        return address(this).balance;
    }
}