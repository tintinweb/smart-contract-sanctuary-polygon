/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract gamingArcade {

 /////////////////// constructor ///////////////////
 
    constructor (address _multisigDevWallet, uint8 _feePercent) {
        owner = msg.sender;
        treasuryWallet = _multisigDevWallet;
        gameFee = _feePercent;
    }


 /////////////////// variables ///////////////////
   
    enum GAME_STATE {
        started,
        inProgress,
        gameEnded,
        setteled
    }

    // deployer of this contract
    address private owner; 

    // wallet address of multi-sig treasury wallet
    address public treasuryWallet; 

    // game types , only owner can add game types
    string[] public types;

    // game fee percentage 
    uint256 public gameFee;

    // gameplay time in seconds
    // uint256 public gameplayTime = 150;

    // number of registered players
    uint256 public playerCount;

    // number of total games played
    uint256 public gameCount;

    // Player info by address, address => player
    mapping(address => Player) public players;

    // player info by id
    mapping(uint256 => Player) public playerById;

    // whether player is registered or not 
    mapping(address => bool) public isPlayer;

    // player Id to address  
    mapping(uint256 => address) idToAddress;

    // game id to game info 
    mapping(uint256 => Game) public games;

    // game Id to total pot amount of the game 
    mapping(uint256 => uint256) public gamePot;

    // gameId => player => score
    mapping(uint256 => mapping(address => uint256)) public gameScore;


    struct Player {
        address player; // address of player's wallet
        uint256 id; // Unique of the player
        uint256 signupTime; // Regestration timestamp
        uint256 gamesPlayed; // number of games played by player
        bool isBanned; // player's status (active/banned) ==> Every player is active by default
        uint256[] gameIds; // game id's all the games player participated
    }

    struct Game {
        uint256 gameId; // a unique Id for every game
        address gameOwner; // player's address who initiated/started the game
        uint256 betAmount; // betAmount for this particular game 
        string gameType; // which game ?? Tetris / Pacrush / block Jumper etc..
        address[] participants; // playerIds of all the participants 
        address winner; // address of the winner
        uint256 prize;  // amount won by winner 
        GAME_STATE state; // game state 
    }

 /////////////////// events ///////////////////

    // player registers
    event signedUp(address indexed player, uint256 playerId, uint256 regTimestamp);

    // game created
    event gameCreated(address indexed gameOwner, uint256 gameId, 
                      uint256 betAmount, string gameType
                      );
    // player joined a game 
    event playerJoined(uint256 gameId, address player, uint256 timestamp);

    // game state changed 
    event stateChanged(uint256 gameId, GAME_STATE );

    // scores submmitted 
    event scoreSubmitted(uint256 gameId, address player, 
                         uint256 score, uint256 timestamp
                         );

    // payments
    event Payments(uint256 gameId,
                   uint256 totalPotAmont,
                   uint256 prize,
                   uint256 fee,
                   address winner,
                   address treasury,
                   uint256 timestamp  
                   );


 /////////////////// modifiers ///////////////////

    // only owner
    modifier onlyOwner() {
        require(msg.sender == owner, "owner only");
        _;
    }

    // only registered players
    modifier registeredPlayerOnly() {
        require(isPlayer[msg.sender] == true, "please signup");
        _;
    }

    // bet amount modifier
    modifier onlyBetAmount(uint256 _gameId) { 
        Game storage _game = games[_gameId];
        uint betAmount = _game.betAmount;
        require(msg.value == betAmount, "bet amount is not valid");
        _;
    }

    ////// need to work Fill Me in...... ////////////
    modifier gameBetAmount() {
        require(msg.value == 50000000000000000 // 0.05 BNB/ETH
        || msg.value == 100000000000000000 // 0.1 BNB/ETH
        || msg.value == 500000000000000000 // 0.5 BNB/ETH
        || msg.value == 1000000000000000000 // 1 BNB/ETH
        );
        _;
    }


 /////////////////// functions ///////////////////

    // the deployer can ban a player with player's unique Id
    function banPlayer(uint _playerId) public onlyOwner {
        Player storage _player = playerById[_playerId];
        _player.isBanned = true;
    }

    // only owner adds the game types 
    function addGameType(string memory _gameType) public onlyOwner {
        types.push(_gameType);
    }


    // Player registers with the SC
    function signUp() public {
        require(!isPlayer[msg.sender], "already registered"); // should not be an already reg. player
        uint _id = playerCount + 1;
        // player info gets updated to player struct
        Player storage _player = players[msg.sender];
        _player.player = msg.sender;
        _player.id = _id;
        _player.signupTime = block.timestamp;
        playerCount ++ ; // player count increments
        // emits a sign up event
        emit signedUp(msg.sender, _player.id, _player.signupTime);
    }


    // player initiates/starts the game 
    function createGame(uint i) public payable registeredPlayerOnly gameBetAmount {
        require(i <= types.length, "please select valid type");
        uint _gameId = gameCount + 1;
        // game info gets updated to game struct
        Game storage _game = games[_gameId];
        _game.gameId = _gameId;
        _game.gameOwner = msg.sender;
        _game.betAmount = msg.value;
        _game.gameType = types[i];
        _game.state = GAME_STATE(0);
        gameCount++ ; // game count increments
        // game owner's profile gets updated
        players[msg.sender].gamesPlayed ++ ;
        players[msg.sender].gameIds.push(_gameId);
        // money sent by player goes to game pot
        gamePot[_gameId] += msg.value;
        // emits a game created event
        emit gameCreated(msg.sender, _game.gameId, msg.value, _game.gameType);
        // emits a state change event
        emit stateChanged(_game.gameId, GAME_STATE(0));        
    }

    // any registered player can join the game
    function joinGame(uint256 _gameId) public payable registeredPlayerOnly onlyBetAmount(_gameId){
        //game info & player profile gets updated
        Game storage _game = games[_gameId];
        _game.participants.push(msg.sender);
        players[msg.sender].gamesPlayed ++ ;
        players[msg.sender].gameIds.push(_gameId);
        _game.state = GAME_STATE(1);
        // money sent by player goes to game pot
        gamePot[_gameId] += msg.value;
        // new player joined in the game event
        emit playerJoined(_gameId, msg.sender, block.timestamp);
        // emits a state changed event
        emit stateChanged(_gameId, GAME_STATE(1));           
    }


    // Player submits the score after completing his turn 
    function submitScore(uint256 _gameId, uint256 _score) public {
        gameScore[_gameId][msg.sender] = _score;
        emit scoreSubmitted (_gameId, msg.sender, _score, block.timestamp);
    }

    // game ends and emits a state change event
    function endGame(uint256 _gameId) public {
        Game storage _game = games[_gameId];
        _game.state = GAME_STATE(2);
        emit stateChanged(_gameId, GAME_STATE(2));
    }

    // settle 90% of the game pot to winner and rest to the treasury
    function settleGame(uint256 _gameId, address[] memory _winners, uint32[] memory _shares) public {
        // update game statistics to game struct
        Game storage _game = games[_gameId];
        _game.winner = _winners[0];
        uint totalPot = gamePot[_gameId];
        // settle the bet - winner gets 90% of the pot & the rest to treasury
        uint _prize = totalPot - ((totalPot * gameFee) / 100);
        totalPot -= _prize;
        // update game data with prize amount
        _game.prize = _prize;
        // pay out to multiple winners
        for (uint i = 0; i < _winners.length; i++) {
            _pay(_winners[i], _shares[i], _prize);
        }
        // pay the rest of the totalpot to treasury wallet
        bool success;
        (success, ) = payable(treasuryWallet).call{value: totalPot}("");
        
        
        // // updates game state to setteled // //
        _game.state = GAME_STATE(3);
        emit Payments(_gameId, totalPot, _prize, (totalPot - _prize), _winners[0], treasuryWallet, block.timestamp);
        emit stateChanged(_gameId, GAME_STATE(3));

    }

 /////////////////// internal functions /////////////////// 
    
    // get player address by playerId
    function playerAddress(uint256 _id) internal view returns(address) {
        Player storage _player = playerById[_id];
        return _player.player;
    }

    // internal function for payouts
    function _pay(address winner, uint32 share, uint _amount) internal {
        uint amtToPay = (_amount * share ) / 10000;
        bool success;
        (success, ) = payable(winner).call{value: amtToPay} ("");
    }


}