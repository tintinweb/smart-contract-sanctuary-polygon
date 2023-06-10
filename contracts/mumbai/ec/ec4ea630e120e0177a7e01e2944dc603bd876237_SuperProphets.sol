/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED
 * VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * If you are reading data feeds on L2 networks, you must
 * check the latest answer from the L2 Sequencer Uptime
 * Feed to ensure that the data is accurate in the event
 * of an L2 sequencer outage. See the
 * https://docs.chain.link/data-feeds/l2-sequencer-feeds
 * page for details.
 */

contract SuperProphets {
    AggregatorV3Interface internal dataFeed;

    uint public timeStart;

    /**
     * Network: Sepolia
     * Aggregator: BTC/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */

    // main btc usd 
    // 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c

    // polygon main net  link usd 
    //  0xd9FFdb71EbE7496cC440152d43986Aae0AB76665

    constructor() {
        dataFeed = AggregatorV3Interface(
            0xd9FFdb71EbE7496cC440152d43986Aae0AB76665
        );

        timeStart = block.timestamp;
    }

    /**
     * Returns the latest answer.
     */
    function getLatestData() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

     function getPriceOneHourAgo() external view returns (int) {
        uint oneHourAgo = block.timestamp - 1 hours;
       uint80 timeAgo = uint80(oneHourAgo);

     //  uint80 roundId = uint80(block.timestamp / 1 hours); // Convert to uint80 explicitly
        (, int256 price, , , ) = dataFeed.getRoundData(timeAgo);
        return price;
    }


    function checkTime() public view returns(uint){
        uint diff = block.timestamp - timeStart;
        return diff;
    }
}