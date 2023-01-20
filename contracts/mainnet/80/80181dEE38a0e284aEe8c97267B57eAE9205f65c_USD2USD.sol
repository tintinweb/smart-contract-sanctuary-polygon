/**
 *Submitted for verification at polygonscan.com on 2023-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/*
    Simple ChainLink Oracle that always returns 1e18
*/
contract USD2USD {
    function decimals() external pure returns (uint8){
        return 18;
    }

    function description() external pure returns (string memory){
        return "USD/USD";
    }

    function version() external pure returns (uint){
        return 1;
    }

    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    ){
        return (_roundId, 1e18, block.timestamp, block.timestamp, _roundId);
    }

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    ){
        return (1, 1e18, block.timestamp, block.timestamp, 1);
    }
}