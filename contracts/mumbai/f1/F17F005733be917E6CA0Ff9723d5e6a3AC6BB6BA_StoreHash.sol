/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract StoreHash {
    struct Game{
        bytes32 gameHash;
        string gameCreatedAt;
        bool exsists;
    }


    address public owner;
    mapping (uint=>Game) private games;

    event NewGameAdded(uint indexed _gameId, bytes32 indexed _gameHash);

    modifier onlyOwner(){
         require (msg.sender==owner, "not an owner");
        _;
    }
    modifier gameNotExist(uint id){
         require (!games[id].exsists, "Allready added");
        _;
    }

    constructor(){
        owner=msg.sender;
    }

    //получить хэш игры по номеру игры
    function getGameHash(uint _gameId) external view returns(Game memory){
        return games[_gameId];  
    }

    //СПОСОБ1. сохранить хэш игры записав сам хэш под номер игры
    function storeGameHash1(uint _gameId, bytes32 _gameHash, string calldata _gameCreationDate) external onlyOwner gameNotExist(_gameId){
        games[_gameId] = Game(_gameHash, _gameCreationDate, true);
        emit NewGameAdded(_gameId,_gameHash);
    } 
    
    receive() external payable{
        revert("We are not receiving money");
    }
}