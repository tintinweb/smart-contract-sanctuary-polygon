/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract BettingGame {
    struct Hand {
        uint256 firstNumber;
        uint256 secondNumber;
        uint256 product;
    }

    struct Player {
        address addr;
        Hand[] hands;
    }

    struct Game {
        address organizer;
        mapping(address => Player) players;
        address[] playerAddresses;
        uint256 endTime;
        uint256 pool;
        uint256 maxProduct;
        uint256 betAmount;
        bool gameEnded;
    }

    mapping(uint256 => Game) public games;
    uint256 public nextGameId = 0;
    address public owner;

    event GameCreated(uint256 gameId, address indexed organizer, uint256 betAmount);
    event BetMade(uint256 indexed gameId, address indexed player, bool isFirstNumber, uint256 number, uint256 product);
    event GameEnded(uint256 indexed gameId, address indexed winner);
    event RewardClaimed(uint256 indexed gameId, address indexed claimer, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function createGame(uint256 betAmount) public payable {
        require(msg.value == betAmount, "Must send the amount of bet for the first bet");

        uint256 gameId = nextGameId++;
        Game storage game = games[gameId];
        game.organizer = msg.sender;
        game.betAmount = betAmount;
        game.maxProduct = 9801; // 99*99

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        game.players[msg.sender].addr = msg.sender;
        game.players[msg.sender].hands.push(Hand({
            firstNumber: randomNumber,
            secondNumber: 0,
            product: randomNumber
        }));
        game.endTime = block.timestamp + 5 minutes;
        game.pool += betAmount;

        emit GameCreated(gameId, msg.sender, betAmount);
        emit BetMade(gameId, msg.sender, true, randomNumber, randomNumber);  // emit BetMade event
    }

    function bet(uint256 gameId, uint256 handIndex) public payable {
        Game storage game = games[gameId];
        require(!game.gameEnded, "Game already ended");
        require(game.endTime > block.timestamp || game.endTime == 0, "Game time has ended");
        require(msg.value == game.betAmount, "Must send the defined bet amount");

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;

        if(handIndex >= game.players[msg.sender].hands.length) {
            require(handIndex == game.players[msg.sender].hands.length, "The hand index is out of range");
            game.players[msg.sender].addr = msg.sender;
            game.players[msg.sender].hands.push(Hand({
                firstNumber: randomNumber,
                secondNumber: 0,
                product: randomNumber
            }));

            if (msg.sender != game.organizer && game.players[msg.sender].hands.length == 1) {
                game.playerAddresses.push(msg.sender);
            }

            emit BetMade(gameId, msg.sender, true, randomNumber, randomNumber);
        } else {
            require(game.players[msg.sender].hands[handIndex].secondNumber == 0, "The hand already has a second number betted");
            game.players[msg.sender].hands[handIndex].secondNumber = randomNumber;
            game.players[msg.sender].hands[handIndex].product *= randomNumber;

            if(game.players[msg.sender].hands[handIndex].product >= game.maxProduct) {
                endGame(gameId);
            }

            emit BetMade(gameId, msg.sender, false, randomNumber, game.players[msg.sender].hands[handIndex].product);
        }

        game.endTime = block.timestamp + 5 minutes;
        game.pool += msg.value;
    }

    function endGame(uint256 gameId) private {
        Game storage game = games[gameId];
        game.gameEnded = true;
        emit GameEnded(gameId, msg.sender);  // emit GameEnded event
    }

    function claimReward(uint256 gameId) public {
        Game storage game = games[gameId];

        // Check if the game has ended and update the state if necessary
        if (block.timestamp >= game.endTime && !game.gameEnded) {
            game.gameEnded = true;
            emit GameEnded(gameId, msg.sender);
        }

        require(game.gameEnded, "Game is not yet over");

        uint256 highestProduct = 0;
        address winner = game.organizer;  // by default, the organizer is the winner

        for (uint i = 0; i < game.playerAddresses.length; i++) {
            address playerAddress = game.playerAddresses[i];
            Player storage player = game.players[playerAddress];
            for(uint j = 0; j < player.hands.length; j++) {
                if (player.hands[j].product > highestProduct) {
                    highestProduct = player.hands[j].product;
                    winner = player.addr;
                }
            }
        }

        require(msg.sender == winner || msg.sender == game.organizer || msg.sender == owner, "Only the winner, game organizer, or contract owner can claim the reward");

        uint256 winnerReward = game.pool * 92 / 100;
        payable(winner).transfer(winnerReward);
        emit RewardClaimed(gameId, winner, winnerReward);

        uint256 organizerReward = game.pool * 5 / 100;
        payable(game.organizer).transfer(organizerReward);
        emit RewardClaimed(gameId, game.organizer, organizerReward);

        uint256 ownerReward = game.pool * 3 / 100;
        payable(owner).transfer(ownerReward);
        emit RewardClaimed(gameId, owner, ownerReward);

        game.pool = 0;  // Set the pool to zero after rewards have been claimed
    }

    function getNumberOfHands(uint256 gameId, address playerAddress) public view returns (uint256) {
        return games[gameId].players[playerAddress].hands.length;
    }

    function getHand(uint256 gameId, address playerAddress, uint256 handIndex) public view returns (uint256, uint256, uint256) {
        require(handIndex < games[gameId].players[playerAddress].hands.length, "Hand index out of range");
        Hand memory hand = games[gameId].players[playerAddress].hands[handIndex];
        return (hand.firstNumber, hand.secondNumber, hand.product);
    }

    function getHighestHand(uint256 gameId) public view returns (address highestPlayer, uint256 highestHandIndex, uint256 firstNumber, uint256 secondNumber, uint256 product) {
        Game storage game = games[gameId];

        uint256 highestProduct = 0;
        address tempPlayer;
        uint256 tempHandIndex;

        for (uint i = 0; i < game.playerAddresses.length; i++) {
            address playerAddress = game.playerAddresses[i];
            Player storage currentPlayer = game.players[playerAddress];
            for(uint j = 0; j < currentPlayer.hands.length; j++) {
                if (currentPlayer.hands[j].product > highestProduct) {
                    highestProduct = currentPlayer.hands[j].product;
                    tempPlayer = currentPlayer.addr;
                    tempHandIndex = j;
                }
            }
        }

        Hand storage hand = game.players[tempPlayer].hands[tempHandIndex];

        return (tempPlayer, tempHandIndex, hand.firstNumber, hand.secondNumber, hand.product);
    }
}