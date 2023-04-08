// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CronQuiz {

    struct QuizPlayer {
        
        address owner;
        uint256 totalPoint;
        string[] category;
        uint256[] point;

    }

    mapping( uint256 => QuizPlayer ) public players;

    uint256 public numberOfPlayers = 0;

    function addPlayer( 
        address _owner
    ) public returns (uint256) {

        QuizPlayer storage player = players[numberOfPlayers];

        player.owner = _owner;
        player.totalPoint = 0;

        numberOfPlayers++;

        return numberOfPlayers-1;

    }

    function addPoint(uint256 _id, string memory _category, uint256 _point ) public {

        QuizPlayer storage player = players[_id];

        player.category.push(_category);
        player.point.push(_point);
        player.totalPoint = player.totalPoint + _point;

    }

    function getPoint( uint256 _id ) view public returns( string[] memory, uint256[] memory ) {

        return (players[_id].category, players[_id].point);

    }

}