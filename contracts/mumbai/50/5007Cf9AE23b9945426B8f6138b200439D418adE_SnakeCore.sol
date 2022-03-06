/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// SPDX-License-Identifier: None
pragma solidity >=0.8.9;

contract SnakeCore {

    event AppleIsPlaced(uint x, uint y);
    event AppleIsEaten(uint x, uint y, Snake snake);

    struct Snake {
        address player;

        // the velocity of the snake
        uint dx;
        uint dy;

        // the position of the Snake on the grid
        uint x;
        uint y;
    }

    // the width and height of the map is 800x800px
    // the size of the snake cell is 8x8x
    // the maximum screen size is 100x100 grid
    Snake[100][100] map;
    bool[100][100] apples;

    uint latestAppleX;
    uint latestAppleY;

    uint num;

    mapping(address => Snake) playerToSnake;

    function _getSnake(address _player) private view returns (Snake memory) {
        return playerToSnake[_player];
    }

    function setNum(uint _num) public {
        num = _num;
    }

    function getNum() public view returns (uint) {
        return num;
    }

    function placeApple(uint _x, uint _y) public {
        latestAppleX = _x;
        latestAppleY = _y;

        // make sure everything is false first
        for (uint i = 0; i < apples.length; i++) {
            for (uint j = 0; j < apples[i].length; j++) {
                apples[i][j] = false;
            }
        }
        
        // mark the one with apple as true
        apples[_x][_y] = true;

        emit AppleIsPlaced(_x, _y);
    }

    function getAppleLocation() public view returns (uint, uint) {
        return (latestAppleX, latestAppleY);
    }

    function move(uint _x, uint _y, uint _dx, uint _dy, address _player) public {
        playerToSnake[_player] = Snake(_player, _dx, _dy, _x, _y);

        map[_x][_y] = playerToSnake[_player];
    }

    function eat(uint _x, uint _y, address _player) public {
        Snake memory _snake = playerToSnake[_player];

        emit AppleIsEaten(_x, _y, _snake);
    }
}