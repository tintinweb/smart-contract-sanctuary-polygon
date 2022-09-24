/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;


contract NymphTest {

    address private owner;
    mapping (address => uint) private balance;
    mapping (address => mapping(address => uint)) private deposites;
    mapping (address => address) private referer;


   // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
   // Log the event about a deposit being made by an address and its amount
    event LogDepositMade(address indexed accountAddress, uint amount);
   // Log the event about a deposit being withdraw by an address and its amount
    event LogDepositWithdraw(address indexed accountAddress, uint amount);

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
     //   console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

     /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
       
    }
 
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /*
    The receive function is executed on a call to the contract with empty calldata.
    */
    receive() external payable {
        balance[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value);
    }

    // notice Deposit ether into contract, requires method is "payable"
    // return The balance of the user after the deposit is made
    function deposit() public payable returns (uint) {
        balance[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value);
        return balance[msg.sender];
    }

    // notice Withdraw ether from contract
    // return The balance remaining for the user
    function withdraw(uint withdrawAmount) public returns (uint remainingBal) {
        // Check enough balance available, otherwise just return balance
        if (withdrawAmount <= balance[msg.sender]) {
            balance[msg.sender] -= withdrawAmount;
            payable(msg.sender).transfer(withdrawAmount);
            emit LogDepositWithdraw(msg.sender, withdrawAmount);
        }
        return balance[msg.sender];
    }

    // notice Just reads balance of the account requesting, so "constant"
    // return The balance of the user
    function getBalance() public view returns (uint remainingBal) {
        return balance[msg.sender];
    }

 /// @return The balance of the contract (косяк)
    function userBalance(address addr) public isOwner view returns (uint) {
        return addr.balance;
    }

    /// @return The balance of the contract
    function totalBalance() public isOwner view returns (uint) {
        return address(this).balance;
    }

    function pay(address from_addr, address to_addr, uint amount) public isOwner returns (uint remainingBal) {
        require(amount <= balance[from_addr] , "not enough funds");
        balance[from_addr] -= amount;
        uint percent = amount * 100 / 20;
        balance[owner] += percent;
        balance[to_addr] += amount - percent;
        return balance[from_addr]; 

    }

    function transfer(address from_addr, address to_addr, uint amount) public isOwner returns (uint remainingBal) {
        require(amount <= balance[from_addr] , "not enough funds");
        balance[from_addr] -= amount;
        balance[to_addr] += amount;
        return balance[from_addr]; 
    }
  
    function allocate(address from_addr, address to_addr, uint amount) public isOwner returns (uint remainingBal) {
        require(amount <= balance[from_addr] , "not enough funds");
        balance[from_addr] -= amount;
        deposites[from_addr][to_addr] += amount;
        return balance[from_addr]; 
    }

    function release(address from_addr, address to_addr, uint amount) public isOwner returns (uint remainingBal) {
       require(amount <= deposites[from_addr][to_addr] , "not enough funds");
       deposites[from_addr][to_addr] -= amount;
       uint percent = amount * 100 / 20;
       balance[owner] += percent;
       balance[to_addr] += amount - percent;
       balance[from_addr] += deposites[from_addr][to_addr];
       deposites[from_addr][to_addr] = 0;
       return balance[from_addr];  
    }    

    function setReferer(address addr, address ref) public isOwner returns (address) {
        referer[addr] = ref;
        return referer[addr];
    }

    function getReferer(address addr) public isOwner view returns (address ref) {
        return referer[addr];
    }

}