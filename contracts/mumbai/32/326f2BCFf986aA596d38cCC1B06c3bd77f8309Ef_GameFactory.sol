// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Game {
    uint gameId;
    address public owner;
    uint public jackpot_pct;
    uint public simple_pct;
    bool public closed;
    uint256 public balance;


    constructor (uint _gameId, address _owner, uint _jackpot_pct, uint _simple_pct, bool _closed, uint256 _balance){
        gameId = _gameId;
        owner = payable(_owner);
        jackpot_pct = _jackpot_pct;
        simple_pct = _simple_pct;
        closed = _closed;
        balance = _balance;
    }


    function addFunds() onlyOwner payable public {
        require(address(this).balance + msg.value > 0.2 ether, "You add not enough fund. Balance must be greater than 0.2");
        require(address(this).balance + msg.value < 1.1 ether, "You add too much funds. Balance must be greater than 0.2");

        closed = false;
    }
    function closeGame() onlyOwner public {
        closed = true;
    }
    function participate(uint _feePct) payable public {
        require(closed == false, "Game is closed. Wait until you can play!");
        require(msg.sender != owner, "You can't play your own game!");
        payable(owner).transfer(msg.value * (_feePct/100));
    }
    function fixJackpotWin(uint _feePct) public payable {
        require(balance > (balance * (jackpot_pct/100)), "Not enough money to withdraw win");
        payable(owner).transfer( (balance * (jackpot_pct/100))*_feePct/100);
    }
    function fixSimpleWin(uint _feePct) public payable {
        require(balance > (balance * (simple_pct/100)), "Not enough money to withdraw win");
        payable(owner).transfer( (balance * ((simple_pct/100)/5))*_feePct/100);
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}
// *** FOR TEST ***
// Game.sol deploy –– 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 30, 70, false, 0

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Game.sol";

contract GameFactory {
    event GameCreated(Game indexed game);

    
    struct GameStruct {
        uint _gameId;
        address owner;
        uint jackpot_pct;
        uint simple_pct;
        bool closed;
        uint balance;
    }


    GameStruct [] public games;
    GameStruct [] public openGames;



    uint public gameId;


    constructor(){
        gameId = 0;
    }


    function getGames() public view returns(GameStruct[] memory) {
        return games;
        // for(uint i=0; i<games.length; i++){
        //     if(games[i].closed == false){
        //         openGames[i] = games[i];
        //     }
        // }
        // return openGames;
    }
    function getAccountGames() public view returns(GameStruct[] memory) {
        require(games.length != 0, "Nothing to show because list is empty!");
        uint ownersGameId = 0;
        GameStruct[] memory ownersGames;
        for(uint i=0; i<games.length; i++){
            if(games[i].owner == msg.sender){
                ownersGames[ownersGameId] = games[i];
                ownersGameId += 1;
            }
        }
        return ownersGames;
    }
    function createGame(uint _jackpot_pct, uint _simple_pct) public  {
        Game game = new Game(gameId, msg.sender, _jackpot_pct, _simple_pct, true, 0);
        GameStruct memory game_struct = games.push();

        game_struct._gameId = gameId;
        game_struct.owner = msg.sender;
        game_struct.jackpot_pct = _jackpot_pct;
        game_struct.simple_pct = _simple_pct;
        game_struct.closed = true;
        game_struct.balance = 0;

        gameId += 1;

        emit GameCreated(game);
    }

    function closeGame(uint _gameId) public view {
        require(games[_gameId].closed == false, "Your game already closed!");
        games[_gameId].closed == false;
    }

   
}

// 0xaA81026b8321d1f31f5b7E3e29f7D32AD4105BD0
// https://mumbai.polygonscan.com/address/0xaA81026b8321d1f31f5b7E3e29f7D32AD4105BD0#code