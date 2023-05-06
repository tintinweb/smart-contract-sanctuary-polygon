// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.18;

contract Lottery {
    // State Variables
    address public manager; // manager is the person who deployed the contract
    address payable[] private players; // players is the array of addresses of all the players
    address[] private winners; // winners is the array of addresses of all the winners
    uint private lotteryId; // lotteryId is the unique id of the lottery

    // Constructor - this function is called only once when the contract is deployed
    constructor() {
        manager = msg.sender; // msg.sender is the address of the person who deployed the contract
        lotteryId = 0; // lotteryId is initialized to 0
    }

    // Enter function - this function is called when a player wants to enter the lottery
    function enter() public payable {
        require(msg.value >= 1 ether, "Minimum lot entry price is 1 ETHER"); // require is used to check if the condition is true or not
        players.push(payable(msg.sender)); // the sender is added to the players array if the condition is true
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players; // this function returns the players array
    }

    // getBalance function - this function is called to get the balance of the contract in wei
    function getBalance() public view returns (uint) {
        return address(this).balance; // this keyword is used to refer to the current contract
    }

    // get Lottery Id function - this function is called to get the lottery id
    function getLotteryId() public view returns (uint) {
        return lotteryId; // lottery id is returned
    }

    // get random number function - this function is called to get a random number
    function getRandomNumber() private view returns (uint) {
        return
            uint(
                keccak256(abi.encodePacked(block.timestamp, manager, players))
            ); // keccak256 is a hashing function which returns a 256 bit hash value
    }

    // pickWinner function - this function is called to pick a winner
    function pickWinner() public {
        require(msg.sender == manager, "Only the manager can pick the winner"); // require is used to check if the condition is true or not
        uint index = getRandomNumber() % players.length; // a random number is generated and the modulo of the length of the players array is taken
        players[index].transfer(address(this).balance); // the winner is paid the balance of the contract
        winners.push(players[index]); // the winner is added to the winners array
        lotteryId++; // the lottery id is incremented

        players = new address payable[](0); // the players array is reset
    }

    // get Winners function - this function is called to get the winners array
    function getWinners() public view returns (address[] memory) {
        return winners; // the winners array is returned
    }
}