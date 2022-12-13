// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

uint constant GAME_PRICE = 0.001 ether;
uint constant ROUND_DURATION = 5 minutes;

struct Stats {
    uint totalClaimed;
    uint totalWinners;
    uint totalRolls;
}

struct PlayerState {
    uint lastClaimedRound;
    uint totalClaimed;
    uint nbShares;
    uint currentRoundShares;
    uint lastWinRound;
}

struct CurrentRound {
    uint id;
    uint benefits;
}

struct LastRound {
    uint winners;
    uint benefits;
    uint timestamp;
    uint totalClaimed;
}

contract Game {
    event GameEnded(address bidder, bool win, uint bet, uint result);

    uint randNonce = 0;
    
    mapping (address => PlayerState) public players;
    CurrentRound public currentRound;
    LastRound public lastRound;
    Stats public stats;

    constructor() {
        currentRound.id = 1;
        lastRound.timestamp = block.timestamp;
    }

    function play(uint bet) public payable {
        require(msg.value == GAME_PRICE, "Game price is not negociable");
        if (getClaimableAmount(msg.sender) > 0)
            claim();
        increaseRoundIfNeeded();
        if (currentRound.id > players[msg.sender].lastWinRound)
            players[msg.sender].currentRoundShares = 0;
        uint result = rollDice();
        bool isWin = bet == 2;
        if (isWin) {
            // WIN
            ++players[msg.sender].nbShares;
            ++players[msg.sender].currentRoundShares;
            players[msg.sender].lastWinRound = currentRound.id;
            ++stats.totalWinners;
            transfer(payable(msg.sender), msg.value);
        } else {
            // LOSS
            currentRound.benefits += msg.value;
        }
        ++stats.totalRolls;
        emit GameEnded(msg.sender, isWin, bet, result);
    }

    function claim() public {
        PlayerState storage state = players[msg.sender];
        require(state.nbShares > 0, "You have no share");
        require(state.lastClaimedRound < currentRound.id, "You already claimed for this round");

        uint claimable = getClaimableAmount(msg.sender);
        require(claimable > 0, "Nothing to claim");
        transfer(payable(msg.sender), claimable);

        stats.totalClaimed += claimable;
        lastRound.totalClaimed += claimable;
        state.totalClaimed += claimable;
        state.lastClaimedRound = currentRound.id;
    }

    function increaseRoundIfNeeded() private {
        if (block.timestamp - lastRound.timestamp < ROUND_DURATION)
            return;
        if (stats.totalWinners > 0) {
            uint lastRoundUnclaimed = lastRound.benefits - lastRound.totalClaimed;
            lastRound.benefits = currentRound.benefits + lastRoundUnclaimed;
            lastRound.winners = stats.totalWinners;
            lastRound.totalClaimed = 0;
            currentRound.benefits = 0;
        }
        lastRound.timestamp = block.timestamp;
        ++currentRound.id;
    }

    function getClaimableAmount(address player) public view returns (uint) {
        if (lastRound.winners == 0)
            return 0;
        PlayerState storage state = players[player];
        if (state.lastClaimedRound == currentRound.id)
            return 0;
        uint nbShares = state.nbShares;
        if (state.currentRoundShares > 0 && state.lastWinRound == currentRound.id)
            nbShares -= state.currentRoundShares;
        return (lastRound.benefits / lastRound.winners) * nbShares;
    }

    function random(uint min, uint max) private returns (uint) {
        randNonce++;
        uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce)));
        return (randomHash % max) + min;
    } 

    function rollDice() private returns (uint) {
        return (random(1, 6));
    }
    
    function transfer(address payable _to, uint _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

}