/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract BettingGame {
    struct Hand {
        uint256[] allHands;
        uint256 numberAmount;
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
        address winner;
        mapping(address => Player) players;
        address[] playerAddresses;
        uint256 endTime;
        uint256 pool;
        uint256 maxProduct;
        uint256 betAmount;
        uint256 maxHandAmount;
        uint256 largestProduct;
        Stages stage;
    }

    enum Stages {
        Waiting,
        Gaming,
        Ended,
        Claimed
    }

    mapping(uint256 => Game) public games;
    uint256 public nextGameId = 0;
    address public owner;
    uint256 public maximumHand = 10;

    uint256 public gamingDuration = 12 hours;
    uint8 public ownerCommission = 3;
    uint8 public organizerCommission = 5;
    bool pause = false;

    event GameCreated(uint256 gameId, address indexed organizer, uint256 betAmount);
    event BetMade(uint256 indexed gameId, uint256 pool, address indexed player, uint256 handIndex, uint256[] hands, uint256 product, uint256 endTime);
    event GameEnded(uint256 indexed gameId);
    event RewardClaimed(uint256 indexed gameId, address indexed claimer, uint256 amount);

    modifier onlyOwner(){
        require(msg.sender == owner, "Require owner to call the function");
        _;
    }

    modifier isPause(){
        require(pause == false, "Game is paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createGame(uint256 betAmount, uint256 _maxHandAmount) public payable isPause {
        require(msg.value == betAmount, "Must send the amount of bet for the first bet");
        require(_maxHandAmount > 0, "Maximum hand amount equal to zero");
        require(_maxHandAmount <= maximumHand, "Number of hand larger than the maximum hand");

        uint256 gameId = nextGameId++;
        Game storage game = games[gameId]; //get the data of the game using game id
        game.organizer = msg.sender; //set organizer of the game
        game.betAmount = betAmount; //set bet amount
        game.maxProduct = 99 ** _maxHandAmount; // set maximum product
        game.maxHandAmount = _maxHandAmount; //set the total number of hand

        game.playerAddresses.push(msg.sender);
        game.players[msg.sender].addr = msg.sender;

        _randomNumber(gameId, msg.sender, 0);

        game.stage = Stages.Gaming;
        emit GameCreated(gameId, msg.sender, betAmount);
    }

    function bet(uint256 _gameId, uint256 _handIndex) public payable {
        Game storage game = games[_gameId];

        require(game.stage != Stages.Ended, "Game already ended");
        require(game.endTime > block.timestamp || game.endTime == 0, "Game time has ended");
        require(msg.value == game.betAmount, "Must send the defined bet amount");

        // if player does not join game before
        if(game.players[msg.sender].addr == address(0)) {
            game.playerAddresses.push(msg.sender);
            game.players[msg.sender].addr = msg.sender;
        }

        _randomNumber(_gameId, msg.sender, _handIndex);
    }

    function _randomNumber(uint256 _gameId, address _userAddress, uint256 _handIndex) internal {
        Game storage game = games[_gameId]; //fetch the game
        Hand storage selectedHand = _handSelected(_gameId, _userAddress, _handIndex);

        // check user hand index bet time
        if(_handIndex > game.players[msg.sender].numberOfHand) { 
            //if handIndex is larger than number of hand, the handIndex must equal to numberOfHand to ensure the handIndex is the new hand
            require(_handSelected(_gameId, _userAddress, _handIndex-1).allHands.length > 0, "Previous hand index not yet bet"); 
            require(game.players[msg.sender].numberOfHand == _handIndex - 1, "The hand index is out of range"); 
            game.players[msg.sender].numberOfHand++;
        }
        uint256[] memory allHands = getHand(_gameId, _userAddress, _handIndex);
        require(allHands.length < game.maxHandAmount, "Hand index reached max bet times");
      
        // start generate random number after checking
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100; //generate the random number

        // selectedHand.allHands[selectedHand.numberAmount] = randomNumber; //store the number to user array
        selectedHand.allHands.push(randomNumber); //store the number to user array
        selectedHand.numberAmount++;

        // calculate product
        if(selectedHand.numberAmount == 1) selectedHand.product = randomNumber;
        else selectedHand.product *= randomNumber;

        // update largest product of the game
        if(selectedHand.product > game.largestProduct) {
            game.largestProduct = selectedHand.product;
        }

        // if user get the max product
        if(selectedHand.product >= game.maxProduct) {
            _endGame(_gameId);
        }

        game.endTime = block.timestamp + gamingDuration;
        game.pool += game.betAmount;

        uint256[] memory upDatedAllHands = getHand(_gameId, _userAddress, _handIndex);

        emit BetMade(_gameId, game.pool, _userAddress, _handIndex , upDatedAllHands, selectedHand.product, game.endTime);
    }

    function _endGame(uint256 _gameId) private {
        Game storage game = games[_gameId];
        game.stage = Stages.Ended;
        emit GameEnded(_gameId);  // emit GameEnded event
    }

    function claimReward(uint256 _gameId) public {
        Game storage game = games[_gameId];
        require(game.stage != Stages.Claimed, "Game ID is already claimed");

        // Check if the game has ended and update the state if necessary
        if (block.timestamp >= game.endTime && game.stage != Stages.Ended) {
            _endGame(_gameId);
        }

        require(game.stage == Stages.Ended, "Game is not yet over");

        address winner = game.organizer;  // by default, the organizer is the winner
        uint256 winnerHandsIndex;
        uint256[] memory winnerHands = new uint256[](5);
        uint256 highestProduct = 0;

        (winner, winnerHandsIndex, winnerHands, highestProduct) = getHighestHand(_gameId);
        game.winner = winner;

        require(msg.sender == winner || msg.sender == game.organizer || msg.sender == owner, "Only the winner, game organizer, or contract owner can claim the reward");

        uint256 winnerReward = game.pool * (100 - ownerCommission - organizerCommission) / 100;
        payable(winner).transfer(winnerReward);
        emit RewardClaimed(_gameId, winner, winnerReward);

        uint256 organizerReward = game.pool * organizerCommission / 100;
        payable(game.organizer).transfer(organizerReward);
        emit RewardClaimed(_gameId, game.organizer, organizerReward);

        uint256 ownerReward = game.pool * ownerCommission / 100;
        payable(owner).transfer(ownerReward);
        emit RewardClaimed(_gameId, owner, ownerReward);

        game.stage = Stages.Claimed;
    }

    function getmaxHandAmounts(uint256 _gameId, address _userAddress) public view returns (uint256) {
        return games[_gameId].players[_userAddress].numberOfHand;
    }

    function getHand(uint256 _gameId, address _userAddress, uint256 _handIndex) internal view returns (uint256[] memory) {
        require(_handIndex <= games[_gameId].players[_userAddress].numberOfHand, "Hand index out of range");

        Hand storage selectedHand = _handSelected(_gameId, _userAddress, _handIndex);
        return selectedHand.allHands;
    }

    function getNumberOfHand(uint256 _gameId, address _userAddress) public view returns (uint256) {
        return games[_gameId].players[_userAddress].numberOfHand;
    }

    function getUserList(uint256 _gameId) public view returns (address[] memory) {
        return games[_gameId].playerAddresses;
    }

    function getHighestHand(uint256 _gameId) public view returns (address highestPlayer, uint256 highestHandIndex, uint256[] memory hands , uint256 product) {
        Game storage game = games[_gameId];

        uint256 _highestProduct = 0;
        address _tempPlayer;
        uint256 _tempHandIndex;

        for (uint i = 0; i < game.playerAddresses.length; i++) {
            address playerAddress = game.playerAddresses[i];
            Player storage currentPlayer = game.players[playerAddress];
            
            for(uint j = 0; j < getmaxHandAmounts(_gameId, playerAddress); j++) {
                if (currentPlayer.hands[j].product > _highestProduct) {
                    _highestProduct = currentPlayer.hands[j].product;
                    _tempPlayer = currentPlayer.addr;
                    _tempHandIndex = j;
                }
            }
        }

        Hand storage selectedHand = _handSelected(_gameId, _tempPlayer, _tempHandIndex);
        hands = getHand(_gameId, _tempPlayer, _tempHandIndex);

        return (_tempPlayer, _tempHandIndex, hands, selectedHand.product);
    }

    function _handSelected(uint256 _gameId, address _userAddress, uint256 _handIndex) internal view returns (Hand storage) {
        Hand storage selectedHand = games[_gameId].players[_userAddress].hands[_handIndex];
        return selectedHand;
    }

    function togglePause() external onlyOwner {
        pause = !pause;
    }

    function setGamingDuration(uint256 _newTime) external onlyOwner {
        gamingDuration = _newTime;
    }

    function setOwnerCommission(uint8 _newCommission) external onlyOwner {
        ownerCommission = _newCommission;
    }

    function setOrganizerCommission(uint8 _newCommission) external onlyOwner {
        organizerCommission = _newCommission;
    }

    function setNextGameId(uint256 _gameId) external onlyOwner {
        require(games[_gameId].stage == Stages.Waiting, "Game is started");
        nextGameId = _gameId;
    }
}