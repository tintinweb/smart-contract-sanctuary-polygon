/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

contract RockPaperScissors {

    // each player only has these options to play
    enum Choice { None, Rock, Paper, Scissors }

    // address of players (I guess that using a fixed-size array would require less gas)
    address[2] private _players;

    // current player count
    uint256 private _nPlayers;

    // map from player to its choice which is hidden in a commitment (hash)
    // the reason for the commitment is that everything is public in most chains
    // we need to find a way to keep the choice of one player hidden from the other one
    // the commitment is gonna be a hash between the player's choice and some secret/keyword
    mapping(address => bytes32) private _commitments;

    // after both players have commited their choice, they will have to provide them again (publicly)
    mapping(address => Choice) private _choices;

    // the constructor just sets the number of players to zero
    constructor() {
        _nPlayers = 0;
    }

    // check that the choice lies in the correct range
    modifier validChoice(uint256 choice) {
        require(choice != 0 && choice <= uint256(Choice.Scissors), "Invalid Choice");
        _;
    }

    // since this is public pure, it can run on client side without the opponent knowing about it
    function getCommitmentHash(uint256 choice, uint256 secret) public pure validChoice(choice) returns (bytes32) {
        return keccak256(abi.encodePacked(choice, secret));
    }

    // the player "plays" by providing a commitment (use getCommitmentHash)
    function play(bytes32 commitment) public {
        require(_nPlayers < 2, "There are alrady 2 players playing. Please wait");

        _commitments[msg.sender] = commitment;
        _players[_nPlayers++] = msg.sender;
        _choices[msg.sender] = Choice.None;

    }

    // once both players have played, the can reveal their commitments
    function reveal(uint256 choice, uint256 secret) public validChoice(choice) {
        require(_nPlayers == 2, "Not all players have provided their commitment yet. Please wait.");
        require(msg.sender == _players[0] || msg.sender == _players[1], "You are not a player in the current round");
        require(getCommitmentHash(choice, secret) == _commitments[msg.sender], "That was not the choice or secret you commited");

        _choices[msg.sender] = Choice(choice);
    }

    // once both players have revealed their commitments, each player can ask if they won 
    function didIWin() public view returns(string memory) {
        require(msg.sender == _players[0] || msg.sender == _players[1], "You are not a player in the current round");
        require(_choices[_players[0]] != Choice.None && _choices[_players[1]] != Choice.None, "One of the players hasn't revealed yet their commitment");

        uint256 opponent = 0;
        if (msg.sender == _players[0]) {
            opponent = 1;
        }

        if (_choices[_players[0]] == _choices[_players[1]]) {
            return "It is a draw";
        }
        
        if (isCallerTheWinner(_choices[msg.sender], _choices[_players[opponent]])) {
            return "You win";
        }
        else {
            return "You lose";
        }
    }

    // internal logic
    function isCallerTheWinner(Choice a, Choice b) private pure returns(bool) {
        
        if (a == Choice.Rock && b == Choice.Paper) {
            return false;   
        }
        else if (a == Choice.Rock && b == Choice.Scissors) {
            return true;
        }
        else if (a == Choice.Paper && b == Choice.Scissors) {
            return false;
        }
        else if (a == Choice.Paper && b == Choice.Rock) {
            return true;
        }
        else if (a == Choice.Scissors && b == Choice.Rock) {
            return false;
        }
        else if (a == Choice.Scissors && b == Choice.Paper) {
            return true;
        }

        return false;
    }
}