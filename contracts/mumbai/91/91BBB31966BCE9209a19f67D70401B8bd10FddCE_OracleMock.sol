// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

import "../../interfaces/AggregatorV3Interface.sol";

// for PoC, emulate chain link oracle
// data of "1INCH / ETH" (https://etherscan.io/address/0x72afaecf99c9d9c8215ff44c77b94b99c28741e8)
// [ latestRoundData method Response ]
//   roundId   uint80 :  36893488147419105479
//   answer   int256 :  377968485108467
//   startedAt   uint256 :  1663195404
//   updatedAt   uint256 :  1663195404
//   answeredInRound   uint80 :  36893488147419105479
contract OracleMock is AggregatorV3Interface {
    address public admin;
    uint8 private _decimals = 18;
    string private _description = "1IX / MATIC";
    uint256 private _version = 4;
    uint80 private __roundId = 36893488147419105479;
    int256 private _answer = 0.377968 ether;
    uint256 private _startedAt = 1663195404;
    uint256 private _updatedAt = 1663195404;
    uint80 private _answeredInRound = 36893488147419105479;

    constructor(address _admin) {
        admin = _admin;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function description() external view returns (string memory) {
        return _description;
    }

    function version() external view returns (uint256) {
        return _version;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (_roundId);

        return _returnMock();
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return _returnMock();
    }

    function _returnMock()
        internal
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (__roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
    }

    function setAnswer(int256 newAnswer) external {
        require(msg.sender == admin, "sender is not admin");
        _answer = newAnswer;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

/**
 * https://github.com/smartcontractkit/chainlink/blob/v1.8.0/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
 */
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}