// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


/* Errors */

error Payments_AmntLessMin();

contract SacPayments {

    struct TipInfo {
        address user;
        uint256 amount;
    }

    mapping(address => TipInfo[]) public profiles;
    mapping(address => uint256) public totalReceived;
    mapping(address => uint256) public totalDonated;

    function tip(address payable tipAddress) public payable {

        profiles[tipAddress].push(TipInfo(msg.sender, msg.value));

        totalReceived[tipAddress] += msg.value;
        totalDonated[msg.sender] += msg.value;

        tipAddress.transfer(msg.value);

    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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