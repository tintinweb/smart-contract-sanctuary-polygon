/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract Lottery {

    address payable[] public players;
    address payable public recentWinner;
    uint256 public maticEntranceFee;
    address payable public owner;
    uint256 public nonce;
    
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;

    event LotteryEnded(address winner, uint256 nonce);

    modifier onlyOwner(address sender) {
        require(sender == owner, "You are not the owner of the contract");
        _;
    }

    constructor (
        address payable beneficiaryAddress
    ) public {
        lottery_state = LOTTERY_STATE.CLOSED;
        owner = beneficiaryAddress;
        nonce = 0;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery not yet open");
        require(msg.value >= getEntranceFee(), "Not enough MATIC");

        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        return maticEntranceFee;
    }

    function startLottery(uint256 entranceFee) public onlyOwner(msg.sender) {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start a new lottery yet !");
        require(entranceFee >= 0, "Can't have negative entrance fees");

        maticEntranceFee = entranceFee;
        nonce += 1;

        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner(msg.sender) {

        if (players.length > 0) {
            lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

            address winner = selectWinner();
            emit LotteryEnded(winner, nonce);

            lottery_state = LOTTERY_STATE.CLOSED;
        }
        else {
            lottery_state = LOTTERY_STATE.CLOSED;
        }

    }
    
    function selectWinner() internal returns (address winner) {
        
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    nonce, 
                    msg.sender, 
                    block.difficulty, 
                    block.timestamp
                )
            )
        );

        uint256 winnerIndex = randomNumber % players.length;
        

        recentWinner = players[winnerIndex];
        bool send = recentWinner.send(address(this).balance);
        require(send, "Matic not send");

        players = new address payable[](0);

        return recentWinner;
    }
}