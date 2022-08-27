/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISwaap {

    function getCoverageParameters() external view returns (
        uint8   priceStatisticsLBInRound,
        uint8   priceStatisticsLBStepInRound,
        uint64  dynamicCoverageFeesZ,
        uint256 dynamicCoverageFeesHorizon,
        uint256 priceStatisticsLBInSec,
        uint256 maxPriceUnpegRatio
    );

}

interface IChainlink {

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

contract SwaapHelper {

    struct RoundData {
        uint80 roundId;
		int256 latestPrice;
		uint256 latestTimestamp;
    }

    function fetchRoundData(ISwaap swaap, IChainlink chainlink) external view returns (RoundData[] memory) {
        (
            uint8 priceStatisticsLBInRound,
            uint8 priceStatisticsLBStepInRound,
            ,
            ,
            ,
        ) = swaap.getCoverageParameters();

        RoundData[] memory tmpRoundData = new RoundData[](priceStatisticsLBInRound - 1);

        if (priceStatisticsLBInRound == 0) {
            return tmpRoundData;
        }

        (uint80 roundId,,,,) = chainlink.latestRoundData();

        uint256 lastElement = priceStatisticsLBInRound - 2;
        for (uint i = 0; i < priceStatisticsLBInRound - 1; i++) {
            if (roundId < priceStatisticsLBStepInRound) {
                lastElement = i;
                break;
            }
            
            uint80 currentRound = roundId - priceStatisticsLBStepInRound;

            if (currentRound < priceStatisticsLBStepInRound) {
                lastElement = i;
                break;
            }

            (
                uint80 rID,
                int256 answer,
                ,
                uint256 updatedAt,
            ) = chainlink.getRoundData(currentRound);

			tmpRoundData[i] = RoundData({
                roundId: rID,
		        latestPrice: answer,
		        latestTimestamp: updatedAt
            });
		}

        if (lastElement == priceStatisticsLBInRound - 2) {
            return tmpRoundData;
        }

        RoundData[] memory roundData = new RoundData[](lastElement + 1);
        for (uint256 i = 0; i < lastElement; i++) {
            roundData[i] = tmpRoundData[i];
        }
        return roundData;
    }

}