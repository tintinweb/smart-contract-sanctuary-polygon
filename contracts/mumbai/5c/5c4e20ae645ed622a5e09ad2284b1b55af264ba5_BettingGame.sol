// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./String.sol";

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
    uint16 public maximumHand = 7;
    uint256 public minBet = 10 ** 10;

    uint256 public gamingDuration = 12 hours;
    uint8 public ownerCommission = 3;
    uint8 public organizerCommission = 5;
    bool pause = false;

    event GameCreated(uint256 gameId, address indexed organizer, uint256 betAmount);
    event BetMade(uint256 indexed gameId, uint256 pool, address indexed player, uint256 handIndex, uint256[] hands, uint256 product, uint256 endTime);
    event GameEnded(uint256 indexed gameId);
    event RewardClaimed(uint256 indexed gameId, address[3] indexed claimer, uint256[3] amount);

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
        require(betAmount >= minBet, "Bet Amount too low");

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
        Game storage game = games[_gameId]; //fetch game
        Hand storage selectedHand = _handSelected(_gameId, _userAddress, _handIndex);

        // check user hand index bet time
        if(_handIndex > game.players[msg.sender].numberOfHand) { 
            //if handIndex is larger than number of hand, handIndex must equal to numberOfHand to ensure handIndex is new hand
            require(_handSelected(_gameId, _userAddress, _handIndex-1).allHands.length > 0, "Previous hand index not yet bet"); 
            require(game.players[msg.sender].numberOfHand == _handIndex - 1, "The hand index is out of range"); 
            game.players[msg.sender].numberOfHand++;
        }
        uint256[] memory allHands = getHand(_gameId, _userAddress, _handIndex);
        require(allHands.length < game.maxHandAmount, "Hand index reached max bet times");
      
        // start generate random number after checking
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100; //generate random number

        selectedHand.allHands.push(randomNumber); //store number to user array
        selectedHand.numberAmount++;

        // calculate product
        if(selectedHand.numberAmount == 1) selectedHand.product = randomNumber;
        else selectedHand.product *= randomNumber;

        // if largest ppl randomed 0, update the highest product
        if(randomNumber == 0) {
            (address user, uint256 handIndex, uint256[] memory hands, uint256 highestProduct) = _getHighestHand(_gameId);
            game.largestProduct = highestProduct;
        }

        // update largest product of game
        if(selectedHand.product > game.largestProduct) {
            game.largestProduct = selectedHand.product;
        }

        // if user get max product
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

        (winner, winnerHandsIndex, winnerHands, highestProduct) = _getHighestHand(_gameId);
        game.winner = winner;

        require(msg.sender == winner || msg.sender == game.organizer || msg.sender == owner, "Only the winner, game organizer, or contract owner can claim the reward");

        uint256 winnerReward = game.pool * (100 - ownerCommission - organizerCommission) / 100;
        payable(winner).transfer(winnerReward);

        uint256 organizerReward = game.pool * organizerCommission / 100;
        payable(game.organizer).transfer(organizerReward);

        uint256 ownerReward = game.pool * ownerCommission / 100;
        payable(owner).transfer(ownerReward);

        address[3] memory claimAddress = [winner, game.organizer, owner];
        uint256[3] memory claimFee = [winnerReward, organizerReward, ownerReward];

        game.stage = Stages.Claimed;

        emit RewardClaimed(_gameId, claimAddress, claimFee);

    }

    function getmaxHandAmounts(uint256 _gameId, address _userAddress) public view returns (uint256) {
        return games[_gameId].players[_userAddress].numberOfHand;
    }

    function getHand(uint256 _gameId, address _userAddress, uint256 _handIndex) public view returns (uint256[] memory) {
        require(_handIndex <= games[_gameId].players[_userAddress].numberOfHand, "Hand index out of range");

        Hand storage selectedHand = _handSelected(_gameId, _userAddress, _handIndex);
        return selectedHand.allHands;
    }

    function getUserAllHands(uint256 _gameId, address _userAddress) public view returns(string[] memory) {
        Game storage game = games[_gameId];

        uint256 _userHands = game.players[_userAddress].numberOfHand;
        string[] memory allHands = new string[](_userHands + 1);

        for(uint256 i = 0; i <= _userHands; i++) {
            uint256[] memory _userHand = getHand(_gameId, _userAddress, i);
            string memory hand;

            for (uint256 j = 0; j < _userHand.length; j++) {
                if(j == 0) hand = string.concat(Strings.toString(_userHand[j]));
                else hand = string.concat(hand, "-", Strings.toString(_userHand[j]));
            }
            // allHands = string.concat(string(abi.encodePacked(_userAddress)), ":", "(", hand, ")");
            // allHands = string.concat(hand);
            allHands[i] = hand;
        }

        return allHands;
    }

    function getGameHands(uint256 _gameId) external view returns(string[] memory) {
        address[] memory _allPlayers = getUserList(_gameId);
        string[] memory _handsDetail = new string[](_allPlayers.length);

        // loop for all players
        for(uint i=0; i<_allPlayers.length; i++) {
            string[] memory _userHands = getUserAllHands(_gameId, _allPlayers[i]);
            string memory _stringUserHands;

            for(uint j=0; j < _userHands.length; j++) {
                if(j==0) _stringUserHands = string.concat("(", _userHands[j], ")");
                else _stringUserHands = string.concat(_stringUserHands, ",(", _userHands[j], ")");
            }
            string memory _userAddress = string.concat("0x", _toAsciiString(_allPlayers[i]));
            _handsDetail[i] = string.concat(_userAddress, ":", _stringUserHands);
        }

        return _handsDetail;
    }

    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);            
        }
        return string(s);
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function getNumberOfHand(uint256 _gameId, address _userAddress) public view returns (uint256) {
        return games[_gameId].players[_userAddress].numberOfHand;
    }

    function getUserList(uint256 _gameId) public view returns (address[] memory) {
        return games[_gameId].playerAddresses;
    }

    function _getHighestHand(uint256 _gameId) internal view returns (address highestPlayer, uint256 highestHandIndex, uint256[] memory hands , uint256 product) {
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

    function setOwnerCommission(uint8 _newOwnerCommission) external onlyOwner {
        ownerCommission = _newOwnerCommission;
    }

    function setOrganizerCommission(uint8 _newOrganizerCommission) external onlyOwner {
        organizerCommission = _newOrganizerCommission;
    }

    function setNextGameId(uint256 _gameId) external onlyOwner {
        require(games[_gameId].stage == Stages.Waiting, "Game is started");
        nextGameId = _gameId;
    }

    function setGameMaximumHand(uint16 _maxHand) external onlyOwner {
        maximumHand = _maxHand;
    }

    function setBetAmount(uint256 _minBet) external onlyOwner {
        minBet = _minBet;
    }

    function setting(uint256 _newTime, uint8 _newOwnerCommission, uint8 _newOrganizerCommission, uint256 _nextGameId, uint16 _maxHand, uint256 _minBet) external onlyOwner {
        require(games[_nextGameId].stage == Stages.Waiting, "Game is started");

        gamingDuration = _newTime;
        ownerCommission = _newOwnerCommission;
        organizerCommission = _newOrganizerCommission;
        nextGameId = _nextGameId;
        maximumHand = _maxHand;
        minBet = _minBet;
    }
}