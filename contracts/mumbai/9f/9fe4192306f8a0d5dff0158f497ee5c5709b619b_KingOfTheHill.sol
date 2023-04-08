/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract KingOfTheHill {
    address public _creator;
    address public _king;
    uint public _endTime;
    uint public _prize;
    mapping(address => Winner) public _winners;

    struct Winner {
        uint prize;
        uint endTime;
    }

    event NewKing(address indexed kingAddress, uint endTime);
    event EndGame(address indexed winnerAddress, Winner winner);
    event ClaimPrize(address indexed winnerAddress, uint prize);
    event StealPrize(address indexed kingAddress, address indexed winnerAddress, uint stealPrize);

    constructor() {
        _creator = msg.sender;
    }

    function up(address stealPrizeWinnerAddress) payable public {
        require(msg.value >= 1 ether, "To become the king, you must deposit at least 1 MATIC");

        if (_endTime > 0 && _endTime <= block.timestamp) {
            Winner memory winner = _winners[_king];
            winner.prize += _prize;
            winner.endTime = block.timestamp + 1 minutes;
            _winners[_king] = winner;
            _prize = 0;

            emit EndGame(_king, winner);
        }

        uint fee = 0;
        if (_endTime > block.timestamp) {
            fee = msg.value / 100 * 5;
            payable(_creator).transfer(fee);
        }

        _king = msg.sender;
        _endTime = block.timestamp + 1 minutes;
        _prize += msg.value - fee;

        emit NewKing(_king, _endTime);
        
        if (
            _winners[stealPrizeWinnerAddress].prize > 0
            && _winners[stealPrizeWinnerAddress].endTime <= block.timestamp
        ) {
            _prize += _winners[stealPrizeWinnerAddress].prize;
            
            emit StealPrize(_king, stealPrizeWinnerAddress, _winners[stealPrizeWinnerAddress].prize);

            delete _winners[stealPrizeWinnerAddress];
        }
    }

    function claimPrize() public {
        require(_endTime <= block.timestamp, "The game is not over yet");
        require(
            (_endTime > 0 && _endTime <= block.timestamp && _king == msg.sender)
            || _winners[msg.sender].prize > 0,
            "You can't claim the prize"
        );

        Winner memory winner = _winners[msg.sender];
        if (_endTime > 0 && _endTime <= block.timestamp && _king == msg.sender) {
            winner.prize += _prize;

            delete _prize;
            delete _endTime;
            delete _king;
        }

        payable(msg.sender).transfer(winner.prize);

        emit ClaimPrize(msg.sender, winner.prize);

        delete _winners[msg.sender];
    }
}