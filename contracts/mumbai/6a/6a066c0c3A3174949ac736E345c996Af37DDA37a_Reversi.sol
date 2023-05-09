/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Reversi {

    address public player1;
    address public player2;

    address public turn;

    uint8[8][8] public board;

    uint8 public state;

    uint8 constant NUL = 0;
    uint8 constant WHITE = 1;
    uint8 constant BLACK = 2;

    uint8 constant INITIAL = 0;
    uint8 constant STARTED = 1;
    uint8 constant PLAYING = 2;

    function startGame() public payable returns (address){
        require(state == INITIAL, "Game has already started!");
        player1 = msg.sender;
        for (uint8 i = 0; i < 8; i++) {
            for (uint8 j = 0; j < 8; j++) {
                delete board[i][j];
            }
        }
        state = STARTED;
        turn = msg.sender;
        return(player1);
    }

    function joinGame() public payable returns(address){
        require(state == STARTED, "Game should be started by other player!");
        player2 = msg.sender;
        state = PLAYING;
        board[3][3] = WHITE;
        board[4][3] = BLACK;
        board[3][4] = BLACK;
        board[4][4] = WHITE;
        return(player2);
    }

    function setStone(uint8 _x, uint8 _y) public onlyOnYourTurn onlyWhilePlaying returns(uint8[8][8] memory) {
        require(_x < 8 && _y < 8, "Invalid board position");
        uint8 stone;
        if (msg.sender == player1) {
            stone = WHITE;
        } else {
            stone = BLACK;
        }
        for (uint8 i = 0; i < 3; i++){
            for (uint8 j = 0; j < 3; j++) {
                uint8 change_num = check_dir(_x, _y, i, j);
                for(uint8 k = 1; k < change_num+1; k++){
    				board[i+(i - 1)*k][j+(j - 1)*k] = stone;
    			}
            }
        }
        board[_x][_y] = stone;
        return (board);
    }

    function check_plc(uint8 _x, uint8 _y) internal returns (bool) {
        if (board[_x][_y] == NUL){
            for (uint8 i = 0; i < 3; i++){
                for (uint8 j = 0; j < 3; j++) {
                    uint8 checkX = (_x >= 1) ? (_x - 1 + i) : 0;
                    uint8 checkY = (_y >= 1) ? (_y - 1 + j) : 0;
                    if (checkX !=8 || checkY != 8) {
                        if (check_dir(checkX, checkY, i, j) > 0) {
                            return true;
                        }
                    }
                }
            }
        } 
        return false;
    }

    function check_dir(uint8 _x, uint8 _y, uint8 _xDiff, uint8 _yDiff) internal returns(uint8) {
        uint8 times = 1;
        uint8 stone;
        if (msg.sender == player1) {
            stone = WHITE;
        } else {
            stone = BLACK;
        }
        int8 nextX = int8(_x) + int8(_xDiff - 1) * int8(times);
        int8 nextY = int8(_y) + int8(_yDiff - 1) * int8(times);
        while (nextX >= 0 && nextY >= 0 && uint8(nextX) < 8 && uint8(nextY) < 8 && board[uint8(nextX)][uint8(nextY)] != stone) {
            times++;
        }
        if (nextX >= 0 && nextY >= 0 && uint8(nextX) < 8 && uint8(nextY) < 8 && board[uint8(nextX)][uint8(nextY)] == stone) {
            return times - 1;
        }
        return 0;
    }

    function pass() public onlyOnYourTurn returns(address){
        if (msg.sender == player1) {
            turn = player2;
        } else {
            turn = player1;
        }
        return turn;
    }

    function judge_board() public returns(address){
        state = INITIAL;
    	uint8 count_b = 0; //黒石の数
    	uint8 count_w = 0; //白石の数
    	for(uint8 i = 0; i < 8; i++){
    		for(uint8 j = 0; j < 8; j++){
    			if(board[i][j] == BLACK){
    				count_b++;
    			}else if(board[i][j] == WHITE){
    				count_w++;
    			}
    		}
    	}
        if (count_w > count_b) {
            return (player1);
        } else if (count_w < count_b) {
            return (player2);
        } else {
            return (address(0));
        }
    }

    // modifier
    modifier onlyWhilePlaying() {
        require(state == PLAYING, "This function is only available while you playing a game!");
        _;
    }

    modifier onlyOnYourTurn() {
        require(turn == msg.sender, "You can put stone only on your turn!");
        _;
    }
}