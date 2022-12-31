// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// все должно быть в wei

contract GameFactory {
    event GameCreated(uint indexed _id);

    
    struct GameStruct {
        uint gameId;
        address owner;
        uint jackpot_pct;
        uint simple_pct;
        bool closed;
        uint256 balance;
        uint256 price;
    }


    GameStruct [] public games;



    uint public gameId;
    address public gamblingFieldOwner;


    constructor(){
        gamblingFieldOwner = msg.sender;
        gameId = 0;
    }


    // contract funcs
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // general funcs
    function getGames() public view returns(GameStruct[] memory) {
        //for(uint i=0; i<games.length; i++){
        //    if(games[i].closed == false){
        //        open_games.push(games[i]);
        //    }
        //}
        return games;
    }
    function getAccountGames() public view returns(GameStruct[] memory) {
        GameStruct[] memory ownerGames = new GameStruct[](games.length);
        uint counter = 0;
        for(uint i=0; i<games.length; i++) {
            if(games[i].owner == msg.sender) {
                ownerGames[counter] = games[i];
                counter++;
            }
        }

        GameStruct[] memory result = new GameStruct[](counter);
        for(uint i=0; i<counter; i++) {
            result[i] = ownerGames[i];
        }
        return result;
    }
    function createGame(uint _jackpot_pct, uint _simple_pct) public  {
        //Game game = new Game(gameId, msg.sender, _jackpot_pct, _simple_pct, true, 0);
        //game_examples.push(game);
        games.push(GameStruct(gameId, msg.sender, _jackpot_pct, _simple_pct, true, 0, 0));


        gameId += 1;

        emit GameCreated(gameId);
    }


    // game functions
    function participate(uint _gameId) payable public {
        require(games[_gameId].closed == false, "Game is closed. Wait until you can play!");
        require(msg.sender != games[_gameId].owner, "You can't play your own game!");

        // сначала везде одинаковая будет, потом здесь будет механизм определения цены участия в игре...
        games[_gameId].price = 0.01 ether;
        uint256 plus_k_balance = 0.01 ether - 0.01 ether * 10/100 - (0.01 ether * 10/100)*10/100;
        games[_gameId].balance += plus_k_balance;
        payable(games[_gameId].owner).transfer(0.01 ether * 10/100);
        payable(gamblingFieldOwner).transfer((0.01 ether * 10/100)*10/100);
    }
    function fixJackpotWin(uint _gameId) public {
        require(games[_gameId].balance > (games[_gameId].balance * 50/100), "Not enough money to withdraw win");
        uint256 sum_to_pay_winner = ((games[_gameId].balance * 50/100) - ((games[_gameId].balance * 50/100)*10/100));
        uint256 sum_to_pay_aggr = (games[_gameId].balance * 50/100)*10/100;
        payable(msg.sender).transfer(sum_to_pay_winner);
        // comission
        payable(gamblingFieldOwner).transfer(sum_to_pay_aggr);
        uint256 balance = games[_gameId].balance;
        games[_gameId].balance = balance - sum_to_pay_winner - sum_to_pay_aggr;
    }
    function fixSimpleWin(uint _gameId) public {
        require(games[_gameId].balance > (games[_gameId].balance * 10/100), "Not enough money to withdraw win");
        uint256 sum_to_pay_winner = ((games[_gameId].balance * 10/100) - ((games[_gameId].balance * 10/100)*10/100));
        uint256 sum_to_pay_aggr = (games[_gameId].balance * 10/100)*10/100;
        //payable(games[_gameId].owner).transfer(sum_to_pay * 1e18);
        // я указываю победителя сам в ethers.js коде
        payable(msg.sender).transfer(sum_to_pay_winner);
        // comission
        //payable(games[_gameId].owner).transfer((games[_gameId].price * (_feePct/100))* 1e18);
        payable(gamblingFieldOwner).transfer(sum_to_pay_aggr);
        //games[_gameId].balance * 1e18 -= sum_to_pay * 1e18;
        uint256 balance = games[_gameId].balance;
        games[_gameId].balance = balance - sum_to_pay_winner - sum_to_pay_aggr;
    }
    function closeGame(uint _gameId) public {
        require(games[_gameId].closed == false, "Your game already closed!");
        games[_gameId].closed = true;
    }
    function openGame(uint _gameId) public {
        require(games[_gameId].closed == true, "Your game already opened!");
        games[_gameId].closed = false;
    }
    function addFunds(uint _gameId) onlyOwner(_gameId) payable public {
        require(games[_gameId].balance + msg.value > 0.2 ether, "You add not enough fund. Balance must be greater than 0.2");
        require(games[_gameId].balance + msg.value < 1.1 ether, "You add too much funds. Balance must be greater than 0.2");
        games[_gameId].balance += msg.value;
        games[_gameId].closed = false;
    }
    function getGameBalance(uint _gameId) public view returns(uint256) {
        return games[_gameId].balance;
    }
    function withdraw(uint _gameId) public {
        require(games[_gameId].owner == msg.sender, "You can't withdraw because you are not owner!");
        payable(msg.sender).transfer(games[_gameId].balance);
        games[_gameId].balance = 0;
    }




    // modifiers
    modifier onlyOwner(uint _gameId) {
        require(msg.sender == games[_gameId].owner);
        _;
    }

   
}

// 0x60c9a4cb04390A7bE4221F26aaBab300D7D79E7F
// https://mumbai.polygonscan.com/address/0x60c9a4cb04390A7bE4221F26aaBab300D7D79E7F#code