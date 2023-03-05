/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CKC {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BettingApp {
    address public ckcAddress = 0x4566b9Dd99Ed8751622A90d63C8DCaEA6F8e6871;
    address public devWallet = 0x1B79C3EDC0eC5C8B7DC56aE39DEe643684171F72;
    uint256 public minBetAmount = 100; // Minimum bet amount in CKC

    struct Bet {
        address player;
        uint256 amount;
        uint256 team;
    }

    Bet[] public bets;

    function placeBet(uint256 team) external payable {
        require(msg.value == minBetAmount, "Bet amount must be equal to the minimum bet amount");

        CKC ckcContract = CKC(ckcAddress);
        require(ckcContract.transfer(devWallet, msg.value), "Transfer of CKC failed");

        Bet memory newBet = Bet(msg.sender, msg.value, team);
        bets.push(newBet);
    }

    function getBetCount() external view returns (uint256) {
        return bets.length;
    }

    function distributePrizes(uint256 winningTeam) external {
        require(msg.sender == ckcAddress, "Only the contract owner can distribute prizes");

        uint256 totalAmount = address(this).balance;
        uint256 winnersCount = 0;
        uint256 winnersAmount = 0;

        for (uint256 i = 0; i < bets.length; i++) {
            if (bets[i].team == winningTeam) {
                winnersCount++;
                winnersAmount += bets[i].amount;
            }
        }

        for (uint256 i = 0; i < bets.length; i++) {
            if (bets[i].team == winningTeam) {
                uint256 payoutAmount = (bets[i].amount * totalAmount) / winnersAmount;
                CKC ckcContract = CKC(ckcAddress);
                require(ckcContract.transfer(bets[i].player, payoutAmount), "Transfer of CKC failed");
            }
        }
    }
}