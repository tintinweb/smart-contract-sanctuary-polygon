// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract MockAggrigatorV3Interface {
    uint256 public updatedAt;
    int256 public price;
    uint8 public decimalsIn;

    ///@dev a mock to get chainlink price
    function setPriceUpdate(int256 _price) external {
        price = _price;
        updatedAt = block.timestamp;
    }

    function decimals() external view returns (uint8) {
        return decimalsIn;
    }

    function setDecimals(uint8 _newDecimals) external {
        decimalsIn = _newDecimals;
    }

    ///@dev a mock to get chainlink price
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        uint80 roundId = 1;
        uint80 answerInRound = 1;
        return (roundId, price, updatedAt, updatedAt, answerInRound);
    }
}