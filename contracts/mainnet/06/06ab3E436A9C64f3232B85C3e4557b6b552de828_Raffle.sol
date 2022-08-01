// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

contract Raffle {
    address public contractAddress; //reference only
    uint256 public roundNumber; //the raffle round identifier
    uint256 public entryCost; //cost to enter the raffle in wei (have a setter for the admin)

    /*
     * Winners Record to keep all winners
     */
    struct Winner {
        address winnerAddress;
        uint256 winnerAmount;
        uint256 round;
    }
    Winner[] public winnerRegistry; //keep all winners of this lottery

    /*
     * Variables for each round
     */
    address payable public manager;
    address payable[] public players;
    uint256 public prizePool;
    uint256 public randomWinnerNumber;

    constructor() public {
        manager = msg.sender;
        roundNumber = 1;
        contractAddress = address(this);
        entryCost = 1000000000000000000;
        prizePool = 0;
    }

    /**
     * Restricted to owner only modifier to add to functions
     */
    modifier ownerOnly() {
        require(msg.sender == manager);
        _;
    }

    /**
     * @notice Enter the raffle
     */
    function enter() public payable {
        //ensure the user is sending enough to enter
        require(msg.value == entryCost);
        //user can enter raffle as many times as they like for more chances
        players.push(msg.sender);
        //increment the value of the prizepool
        prizePool = prizePool + (msg.value);
    }

    /**
     * @notice Pick a raffle winner
     */
    function pickWinner() public ownerOnly {
        //first get a random Number
        randomWinnerNumber = getRandomNumber() % players.length;
        //create a Winner and add to our winners registry array
        Winner memory newWinner = Winner({
            winnerAddress: players[randomWinnerNumber],
            winnerAmount: (address(this).balance * 4) / 5,
            round: roundNumber
        });
        winnerRegistry.push(newWinner);
        //pay the winner
        players[randomWinnerNumber].transfer((address(this).balance * 4) / 5);
        //clear the players array & prizePool
        players = new address payable[](0);
        manager.transfer((address(this).balance * 20) / 100);
        prizePool = 0;
        //increment the round number
        incrementRoundNumber();
    }

    /**
     * @notice pick a random number uses keccak
     */
    function getRandomNumber() private view returns (uint256) {
        //randomWinnerNumber = uint(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
        return
            uint256(
                keccak256(abi.encodePacked(now, block.difficulty, msg.sender))
            );
    }

    /**
     * @notice increments the raffle round number
     */
    function incrementRoundNumber() private {
        roundNumber = roundNumber + 1;
    }

    /**
     * @notice helper function to display players for frontends
     */
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    /**
     * @notice helper function to display winners for frontends
     */
    function getWinners() public view returns (Winner[] memory) {
        return winnerRegistry;
    }

    /**
     * @notice manager only functions
     */
    function setEntryCost(uint256 value) public ownerOnly {
        entryCost = value;
    }

    //fallback function
    function manualPickWinner() public ownerOnly {
        pickWinner();
    }

    //testing only function that obviously should never go in the deployed contract (rugpull anyone!?)
    function rugpullWithdrawEth() public ownerOnly {
        manager.transfer(address(this).balance);
    }
}