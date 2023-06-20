// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IBet.sol";
import "./Ownable.sol";

contract BetsMemory is Ownable {
    address[] public bets;
    uint public betsCount;

    event BetAdded(address indexed bet, address indexed game);

    address public aggregator; // address of Core

    modifier onlyAggregator() {
        require(msg.sender == aggregator, "Memory: Only aggregator can call this function");
        _;
    }

    function setAggregator(address aggregatorAddress) public onlyOwner {
        aggregator = aggregatorAddress;
    }

    function addBet(address bet) public onlyAggregator() {
        bets.push(bet);
        betsCount++;
        emit BetAdded(bet, IBet(bet).game());
    }
    // function returns array of bets based on limit and offset. filtered by game if not 0x0000000
    function getBets(uint limit, uint offset, address game) public view returns (address[] memory) {
        if (limit > bets.length) {
            limit = bets.length;
        }
        address[] memory result = new address[](limit);
        if (limit == 0) {
            return result;
        }
        uint resultIndex = 0;
        for (uint i = bets.length - 1 - offset; i >= 0; i--) {
            if (game == address(0) || IBet(bets[i]).game() == game) {
                result[resultIndex] = bets[i];
                resultIndex++;
                if (resultIndex == limit) {
                    break;
                }
            }
        }
        return result;
    }

    function getBetsCount() public view returns (uint) {
        return betsCount;
    }
}