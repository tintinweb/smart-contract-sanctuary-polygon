/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Consumer {
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    // Deposit to this contract to check if gas payload works
    function deposit() public payable {}
}

contract SmartWallet {
    // Wallet has 1 owner
    address payable public owner;
    address payable public newOwner;
    bool public voting;
    uint public newOwnerVotes;
    // Sets 3-out-of-5 guardians(admins)
    uint public numAdmins;
    mapping(address => bool) public admins;
    mapping(address => bool) public adminsVotes;
    mapping(address => uint) public amounts;

    constructor() {
        // The first owner is the address that deploys the contract
        owner = payable(msg.sender);
    }

    // Spends money on EOA and Contracts
    function transfer(uint amount, address payable to, bytes memory payload) public returns(bytes memory){
        // Payload in a contract is the input value from the receiving function (Example: 0xd0e30db0)  
        require(hasRights(msg.sender), "Not allowed to transfer");
        if (msg.sender != owner) {
            require(amounts[msg.sender] >= amount, "You can't send that amount of money");
            amounts[msg.sender] -= amount;
        }
        (bool success, bytes memory returnData) = to.call{value: amount}(payload);
        require(success, "Not enough $ETH to complete the transaction");
        return returnData;
    }

    // New owner proposal
    function allowNewOwnerElection(address payable proposedOwner) public {
        require(hasRights(msg.sender), "Not allowed to start an election");
        newOwner = proposedOwner;
        voting = true;
    }

    // Sets a new owner
    function setNewOwner() public {
        require(voting, "No elections are active");
        require(admins[msg.sender], "Just the admins can change the owner");
        require(!adminsVotes[msg.sender], "You've already voted");
        // If the new owner is admin, remove it from the mapping
        adminsVotes[msg.sender] = true;
        newOwnerVotes++;
        if (newOwnerVotes >= 3) {
            owner = newOwner;
            voting = false;
            newOwnerVotes = 0;
            if (admins[newOwner]) {
                admins[newOwner] = false;
                numAdmins--;
            }
        }
    }

    // Gives allowance to other people
    function setAdmin(address person) public {
        require(msg.sender == owner, "You're not the owner");
        require(owner != person, "Owner is already an admin");
        require(!admins[person], "Already an admin");
        require(numAdmins < 5, "No more admin spots left");
        admins[person] = true;
        numAdmins++;
    }

    // Remove admin
    function removeAdmin(address person) public {
        require(msg.sender == owner, "You're not the owner");
        require(admins[person], "Not an admin");
        admins[person] = false;
        numAdmins--;
    }

    // Check if is admin by address
    function hasRights(address person) public view returns(bool) {
        if (person == owner) {
            return true;
        }
        return admins[person];
    }

    // Receives funds with a fallback function
    receive() external payable {
        amounts[msg.sender] += msg.value;
    }
}