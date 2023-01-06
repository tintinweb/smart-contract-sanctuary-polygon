/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;

contract Game {
    address player_1;
    address player_2;

    uint8 current_move = 0;

    address private owner;
    mapping (address => uint) private payments;

    uint pay = 1/uint256(2);
    enum SquareState {Empty, X, O}
    SquareState[3][3] board;

    constructor (address _player_2) public {
        require (_player_2 != 0x0);
        player_1=msg.sender;
        player_2=_player_2;
    }

    function paytoStart() public payable{
        payments[msg.sender] = msg.value;
    }

    function positionIsInBounds(uint8 xpos, uint8 ypos) private pure returns(bool) {
        return (xpos >= 0 && xpos < 3 && ypos >= 0 && ypos < 3);
    }

    function squareToString(uint8 xpos, uint8 ypos) private view returns (string) {
        require (positionIsInBounds(xpos, ypos));
        if(board[xpos][ypos] == SquareState.Empty){
        return " ";
        }
        if(board[xpos][ypos] == SquareState.X) {
        return "X";
        }
        if(board[xpos][ypos] == SquareState.O) {
        return "O";
        }
    }

    function rowToString(uint8 ypos) private view returns (string) {
        return string (abi.encodePacked(squareToString(0, ypos), "|", squareToString(1, ypos), "|", squareToString(2, ypos), "|"));
    }
    function Board() public view returns (string) {
        return string(abi.encodePacked("\n",
            rowToString(0), "\n",
            rowToString(1), "\n",
            rowToString(2), "\n"));
    }
    function isGameOver() private view returns (bool) {
        return (winningPlayerShape() != SquareState.Empty || current_move > 8);
    }
    function Move(uint8 xpos, uint8 ypos) public {
        require (msg.sender == player_1 || msg.sender == player_2);
        require (!isGameOver(), "Game is over");
        require (msg.sender == currentPlayerAddress(), "It is not your turn");
        require (positionIsInBounds(xpos, ypos), "Wrong position numbers");
        require (board[xpos][ypos] == SquareState.Empty, "There is already a digit on this position");
        require (payments[msg.sender] > pay, "Pay 0.5 ETH to start (500 Finney)");

        board[xpos][ypos] = currentPlayerShape();
        current_move+=1;
    }

    function take_money() public { 
        owner=winner(); 
        require (isGameOver(), "Game is not over");
        require (msg.sender == owner, "You did not win");
        
        owner.transfer(address(this).balance);   
        //address payable _to = payable(owner);
        //address _thisContract=address(this);
        //_to.transfer(_thisContract.balance);
    }

    function winningPlayerShape() private view returns (SquareState) {
        //Columns
        if (board[0][0] != SquareState.Empty && board[0][0] == board[0][1] && board[0][0] == board[0][2]){
            return board[0][0];
        }
        if (board[1][0] != SquareState.Empty && board[1][0] == board[1][1] && board[1][0] ==board[1][2]){
            return board[1][0];
        }
        
        if (board[2][0] != SquareState.Empty && board[2][0] == board[2][1] && board[2][0] == board[2][2]){
            return board[2][0];
        }

        //Rows

        if (board[0][0] != SquareState.Empty && board[0][0] == board[1][0] && board[0][0] == board[2][0]){
            return board[0][0];
        }
        if (board[0][1] != SquareState.Empty && board[0][1] == board[1][1] && board[0][1] ==board[2][1]){
            return board[0][1];
        }
        
        if (board[0][2] != SquareState.Empty && board[0][2] == board[1][2] && board[0][2] == board[2][2]){
            return board[0][2];
        }


        //Diagonal
        if (board[0][0] != SquareState.Empty && board[0][0] == board[1][1] && board[0][0] == board[2][2]){
            return board[0][0];
        }
        if (board[0][2] != SquareState.Empty && board[0][2] == board[1][1] && board[0][2] ==board[2][0]){
            return board[0][2];
        }

    }

    function currentPlayerAddress() public view returns (address) {
        require (!isGameOver(), "Game is over");
        if (current_move % 2 == 0) {
            return player_2;
        }
        else {
            return player_1;
        }
    }

    function currentPlayerShape() private view returns (SquareState) {
        if (current_move % 2 == 0) {
            return SquareState.X;
        }
        else {
            return SquareState.O;
        }
    }

    function winner() public view returns (address) {
        require (isGameOver(), "Game is not over");
        SquareState winning_shape = winningPlayerShape();
        if(winning_shape == SquareState.X) {
            return player_2;
        } 
        else {
            if (winning_shape == SquareState.O) {
                return player_1;
            }
        }
        return 0x0;
    }
}