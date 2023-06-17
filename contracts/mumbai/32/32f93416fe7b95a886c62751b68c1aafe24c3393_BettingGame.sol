/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract BettingGame {
    struct Hand {
        uint256[] allHands;
        uint256 product;
    }

    struct Player {
        address addr;
        // Hand[] hands;
        uint256 numberOfHand;
        mapping(uint256 => Hand) hands;
    }

    struct Game {
        address organizer;
        mapping(address => Player) players;
        address[] playerAddresses;
        uint256 endTime;
        uint256 pool;
        uint256 maxProduct;
        uint256 betAmount;
        uint256 maxHandAmount;
        uint256 largestProduct;
        bool gameEnded;
    }

    mapping(uint256 => Game) public games;
    uint256 public nextGameId = 0;
    address public owner;
    uint256 public maximumHand = 10;

    event GameCreated(uint256 gameId, address indexed organizer, uint256 betAmount);
    event BetMade(uint256 indexed gameId, uint256 pool, address indexed player, uint256 handIndex, uint256[] hands, uint256 product, uint256 endTime);
    event GameEnded(uint256 indexed gameId, address indexed winner);
    event RewardClaimed(uint256 indexed gameId, address indexed claimer, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function createGame(uint256 betAmount, uint256 _maxHandAmount) public payable {
        require(msg.value == betAmount, "Must send the amount of bet for the first bet");
        require(_maxHandAmount <= maximumHand, "Number of hand larger than the maximum hand");

        uint256 gameId = nextGameId++;
        Game storage game = games[gameId]; //get the data of the game using game id
        game.organizer = msg.sender; //set organizer of the game
        game.betAmount = betAmount; //set bet amount
        game.maxProduct = 99 ** _maxHandAmount; // set maximum product
        game.maxHandAmount = _maxHandAmount; //set the total number of hand

        game.playerAddresses.push(msg.sender);
        game.players[msg.sender].addr = msg.sender;

        // uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100; //generate the random number
        // game.players[msg.sender].addr = msg.sender;
        // game.players[msg.sender].hands.push(Hand({
        //     firstNumber: randomNumber,
        //     secondNumber: 0,
        //     product: randomNumber
        // }));
        // game.endTime = block.timestamp + 5 minutes;
        // game.pool += betAmount;

        _randomNumber(msg.sender, gameId, 1);

        emit GameCreated(gameId, msg.sender, betAmount);
        // emit BetMade(gameId, msg.sender, true, randomNumber, randomNumber);  // emit BetMade event
    }

    function bet(uint256 gameId, uint256 handIndex) public payable {
        Game storage game = games[gameId];
        require(!game.gameEnded, "Game already ended");
        require(game.endTime > block.timestamp || game.endTime == 0, "Game time has ended");
        require(msg.value == game.betAmount, "Must send the defined bet amount");

        if(handIndex + 1 > game.players[msg.sender].numberOfHand) { 
            //if handIndex is larger than number of hand, the handIndex must equal to numberOfHand to ensure the handIndex is the new hand
            require(game.players[msg.sender].numberOfHand == handIndex, "The hand index is out of range"); 
            game.players[msg.sender].numberOfHand++;
        }

        // if player does not join game before
        if(game.players[msg.sender].addr == address(0)) {
            game.playerAddresses.push(msg.sender);
            game.players[msg.sender].addr = msg.sender;
        }

        _randomNumber(msg.sender, gameId, handIndex);

        // uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;

        // if(handIndex >= game.players[msg.sender].hands.length) {
        //     require(handIndex == game.players[msg.sender].hands.length, "The hand index is out of range");
        //     game.players[msg.sender].addr = msg.sender;
        //     game.players[msg.sender].hands.push(Hand({
        //         firstNumber: randomNumber,
        //         secondNumber: 0,
        //         product: randomNumber
        //     }));

        //     if (msg.sender != game.organizer && game.players[msg.sender].hands.length == 1) {
        //         game.playerAddresses.push(msg.sender);
        //     }

        //     emit BetMade(gameId, msg.sender, true, randomNumber, randomNumber);
        // } else {
        //     require(game.players[msg.sender].hands[handIndex].secondNumber == 0, "The hand already has a second number betted");
        //     game.players[msg.sender].hands[handIndex].secondNumber = randomNumber;
        //     game.players[msg.sender].hands[handIndex].product *= randomNumber;

        //     if(game.players[msg.sender].hands[handIndex].product >= game.maxProduct) {
        //         endGame(gameId);
        //     }

        //     emit BetMade(gameId, msg.sender, false, randomNumber, game.players[msg.sender].hands[handIndex].product);
        // }

        // game.endTime = block.timestamp + 5 minutes;
        // game.pool += msg.value;
    }

    function _randomNumber(address _userAddress, uint256 _gameId, uint256 _handIndex) internal {
        Game storage game = games[_gameId]; //fetch the game
      
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100; //generate the random number

        Hand storage selectedHand = game.players[msg.sender].hands[_handIndex];
        selectedHand.allHands.push(randomNumber); //store the number to user array

        // calculate product
        if(selectedHand.allHands.length == 1) selectedHand.product = randomNumber;
        else selectedHand.product *= randomNumber;

        // update largest product of the game
        if(selectedHand.product > game.largestProduct) {
            game.largestProduct = selectedHand.product;
        }

        game.endTime = block.timestamp + 12 hours;
        game.pool += game.betAmount;

        emit BetMade(_gameId, game.pool, _userAddress, _handIndex , selectedHand.allHands, selectedHand.product, game.endTime);
    }

    function endGame(uint256 gameId) private {
        Game storage game = games[gameId];
        game.gameEnded = true;
        emit GameEnded(gameId, msg.sender);  // emit GameEnded event
    }

    // function claimReward(uint256 gameId) public {
    //     Game storage game = games[gameId];

    //     // Check if the game has ended and update the state if necessary
    //     if (block.timestamp >= game.endTime && !game.gameEnded) {
    //         game.gameEnded = true;
    //         emit GameEnded(gameId, msg.sender);
    //     }

    //     require(game.gameEnded, "Game is not yet over");

    //     uint256 highestProduct = 0;
    //     address winner = game.organizer;  // by default, the organizer is the winner

    //     for (uint i = 0; i < game.playerAddresses.length; i++) {
    //         address playerAddress = game.playerAddresses[i];
    //         Player storage player = game.players[playerAddress];
    //         for(uint j = 0; j < player.hands.length; j++) {
    //             if (player.hands[j].product > highestProduct) {
    //                 highestProduct = player.hands[j].product;
    //                 winner = player.addr;
    //             }
    //         }
    //     }

    //     require(msg.sender == winner || msg.sender == game.organizer || msg.sender == owner, "Only the winner, game organizer, or contract owner can claim the reward");

    //     uint256 winnerReward = game.pool * 92 / 100;
    //     payable(winner).transfer(winnerReward);
    //     emit RewardClaimed(gameId, winner, winnerReward);

    //     uint256 organizerReward = game.pool * 5 / 100;
    //     payable(game.organizer).transfer(organizerReward);
    //     emit RewardClaimed(gameId, game.organizer, organizerReward);

    //     uint256 ownerReward = game.pool * 3 / 100;
    //     payable(owner).transfer(ownerReward);
    //     emit RewardClaimed(gameId, owner, ownerReward);

    //     game.pool = 0;  // Set the pool to zero after rewards have been claimed
    // }

    function getmaxHandAmounts(uint256 _gameId, address _userAddress) public view returns (uint256) {
        return games[_gameId].players[_userAddress].numberOfHand;
    }

    function getHand(uint256 _gameId, address _userAddress, uint256 _handIndex) public view returns (uint256[] memory, uint256) {
        require(_handIndex <= games[_gameId].players[_userAddress].numberOfHand, "Hand index out of range");
        Hand memory hand = games[_gameId].players[_userAddress].hands[_handIndex];
        return (hand.allHands, hand.product);
    }

    // function getHighestHand(uint256 gameId) public view returns (address highestPlayer, uint256 highestHandIndex, uint256 firstNumber, uint256 secondNumber, uint256 product) {
    //     Game storage game = games[gameId];

    //     uint256 highestProduct = 0;
    //     address tempPlayer;
    //     uint256 tempHandIndex;

    //     for (uint i = 0; i < game.playerAddresses.length; i++) {
    //         address playerAddress = game.playerAddresses[i];
    //         Player storage currentPlayer = game.players[playerAddress];
    //         for(uint j = 0; j < currentPlayer.hands.length; j++) {
    //             if (currentPlayer.hands[j].product > highestProduct) {
    //                 highestProduct = currentPlayer.hands[j].product;
    //                 tempPlayer = currentPlayer.addr;
    //                 tempHandIndex = j;
    //             }
    //         }
    //     }

    //     Hand storage hand = game.players[tempPlayer].hands[tempHandIndex];

    //     return (tempPlayer, tempHandIndex, hand.firstNumber, hand.secondNumber, hand.product);
    // }
}