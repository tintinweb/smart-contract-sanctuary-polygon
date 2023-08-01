/**
 *Submitted for verification at polygonscan.com on 2023-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address public admin; // The administrator who can transfer the admin role
    address[] public players;

    constructor() {
        manager = msg.sender;
        admin = msg.sender; // Set the contract deployer as the initial admin
    }

    // Function to allow users to deposit ETH and participate in the lottery
    function deposit() public payable {
        require(msg.value > 0, "You need to send some ETH to participate.");
        players.push(msg.sender);
    }

    // Function to choose a random winner and send all the ETH to the winner
    function drawLottery() public restricted {
        require(players.length > 0, "No participants in the lottery.");
        
        // Select a random index based on the current block number and the number of players
        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.number, block.difficulty, players))) % players.length;
        address winner = players[winnerIndex];

        // Transfer the entire contract balance to the winner
        uint256 contractBalance = address(this).balance;
        payable(winner).transfer(contractBalance);

        // Reset the lottery for the next round
        players = new address[](0);
    }

    // Modifier to restrict certain functions to be called only by the manager/admin
    modifier restricted() {
        require(msg.sender == manager || msg.sender == admin, "Only the manager/admin can call this function.");
        _;
    }

    // Function to get the current contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to get the list of players
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    // Function to transfer the admin role to a new address
    function transferAdmin(address newAdmin) public restricted {
        require(newAdmin != address(0), "Invalid address.");
        admin = newAdmin;
    }
}