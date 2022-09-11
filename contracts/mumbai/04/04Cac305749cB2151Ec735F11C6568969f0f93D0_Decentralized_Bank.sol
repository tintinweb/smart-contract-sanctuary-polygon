/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

//SPDX-License-Identifier: mit
pragma solidity ^0.8.0;

contract Decentralized_Bank {
    address owner;
    address payable fee;
    uint256 lockedUntil;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    //  modifier lockTime () {require (block.timestamp > lockedUntil); _;}

    struct User {
        string firstName; //Users informatin
        string lastName;
        uint256 password;
        address userAddr;
    }

    mapping(address => uint256) balance;
    mapping(address => bool) registered;
    mapping(address => User) Userinfos;

    /*Regiteration Area: (User at first place must register to be able to interact with DBank*/
    //--------------------------------------------------------------------
    function register(
        string memory FirstName,
        string memory LastName,
        uint256 Password
    ) public {
        require(msg.sender != owner, "Owner can not register");
        require(registered[msg.sender] != true, "You already have registered");
        registered[msg.sender] = true;

        Userinfos[msg.sender] = User(FirstName, LastName, Password, msg.sender);
    }

    /*In Deposit field you need to declare اow long do you want to lock the money in the contract?*/
    //--------------------------------------------------------------------
    function deposit(uint256 lockDuration) public payable {
        lockedUntil = lockDuration + block.timestamp;
        balance[msg.sender] += msg.value;
    }

    /*10 percent of withdrawl as fee goes to the owner*/
    //--------------------------------------------------------------------
    function withdraw(uint256 withdrawAmount, uint256 Passcode) public payable {
        withdrawAmount = withdrawAmount * 1e18; // shows as Ether
        require(Userinfos[msg.sender].password == Passcode, "Wrong Passcode");
        require(
            lockedUntil < block.timestamp,
            "The withdrawal time has not yet arrived"
        );
        require(withdrawAmount <= balance[msg.sender], "Insufficient Funds");

        balance[msg.sender] -= withdrawAmount;
        payable(msg.sender).transfer((withdrawAmount * 90) / 100);
        payable(fee).transfer((withdrawAmount * 10) / 100);
    }

    /*Gives you the ability to see how much you have put in the contract*/
    //--------------------------------------------------------------------
    function getBalance() public view returns (uint256) {
        return (address(this).balance / 1e18);
    }

    /*By calling this function all the fees that have save threw the transactions goes to the owner address*/
    //--------------------------------------------------------------------
    function getFee() public payable onlyOwner {
        balance[owner] += balance[fee];
    }
}