/**
 *Submitted for verification at polygonscan.com on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract Web3GamesSpace {
    struct Game {
        uint256 id;
        string cid;
        string thumbnail;
        string preview;
        string title;
        string description;
        address creator;
        uint256[] tags;
        uint256 timestamp;
    }

    event NewGameUploaded(
        uint256 id,
        string cid,
        string thumbnail,
        string preview,
        string title,
        string description,
        address creator,
        uint256[] tags,
        uint256 timestamp
    );

    uint256 public totalGames = 0;

    mapping(string => Game) games;
    mapping(uint256 => Game) idToGame;

    function getFromId(uint256 id) public view returns (Game memory) {
        return idToGame[id];
    }

    function getFromCid(string memory cid) public view returns (Game memory) {
        return games[cid];
    }

    function getAll() public view returns (Game[] memory) {
        Game[] memory _games = new Game[](totalGames);
        for (uint256 i = 0; i < totalGames; i++) {
            Game storage game = idToGame[i];
            _games[i] = game;
        }
        return _games;
    }

    function set(
        string memory cid,
        string memory thumbnail,
        string memory preview,
        string memory title,
        string memory description,
        uint256[] memory tags,
        uint256 timestamp
    ) public {
        games[cid] = Game(
            totalGames,
            cid,
            thumbnail,
            preview,
            title,
            description,
            msg.sender,
            tags,
            timestamp
        );
        idToGame[totalGames] = Game(
            totalGames,
            cid,
            thumbnail,
            preview,
            title,
            description,
            msg.sender,
            tags,
            timestamp
        );
        emit NewGameUploaded(
            totalGames,
            cid,
            thumbnail,
            preview,
            title,
            description,
            msg.sender,
            tags,
            timestamp
        );
        totalGames++;
    }
}