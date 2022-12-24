pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/chainlink/IAggregatorV3Interface.sol)

interface IAggregatorV3Interface {
    function latestRoundData() external view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "../../interfaces/external/chainlink/IAggregatorV3Interface.sol";

contract DummyOracle is IAggregatorV3Interface {
    int256 public _answer;
    uint8 public _decimals;

    event AnswerSet(int256 answer);

    constructor(int256 __answer, uint8 __decimals) {
        _answer = __answer;
        _decimals = __decimals;
    }

    function setAnswer(int256 __answer) external {
        _answer = __answer;
        emit AnswerSet(__answer);
    }

    function latestRoundData() external override view returns (
        uint80 /*roundId*/,
        int256 /*answer*/,
        uint256 /*startedAt*/,
        uint256 /*updatedAt*/,
        uint80 /*answeredInRound*/
    ) {
        return (0, _answer, 0, 0, 0);
    }

    function decimals() external override view returns (uint8) {
        return _decimals;
    }
}