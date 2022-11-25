/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-18
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
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

interface AggregatorV3InterfaceS {
    struct LatestRoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    function latestRoundData() external view returns (LatestRoundData memory);

    function getRoundData(uint80 data)
        external
        view
        returns (LatestRoundData memory);

    function phaseAggregators(uint16 phaseID) external view returns (address);

    function latestRound() external view returns (uint256);
}

contract MultiPriceGetter {
    function SearchForEarliestIndex(
        uint256 maxNumberOracleUpdatesToScan,
        AggregatorV3InterfaceS oracle,
        uint80 earliestKnownOracleIndex
    )
        public
        view
        returns (
            uint80 earliestOracleIndex,
            uint256 numberOfOracleUpdatesScanned
        )
    {
        AggregatorV3InterfaceS.LatestRoundData memory correctResult = oracle
            .getRoundData(earliestKnownOracleIndex);
        AggregatorV3InterfaceS.LatestRoundData memory currentResult;

        for (
            ;
            numberOfOracleUpdatesScanned < maxNumberOracleUpdatesToScan;
            ++numberOfOracleUpdatesScanned
        ) {
            try oracle.getRoundData(--earliestKnownOracleIndex) returns (
                AggregatorV3InterfaceS.LatestRoundData memory result
            ) {
                currentResult = result;
                if (correctResult.answer == 0) {
                    break;
                }

                correctResult = currentResult;
            } catch {
                uint16 prevPhaseId = uint16(earliestKnownOracleIndex >> 64);
                //address prevAggregator = oracle.phaseAggregators(prevPhaseId);
                uint256 prevAggregatorLastRoundId = 108472;
                /*AggregatorV3InterfaceS(
                    prevAggregator
                ).latestRound();*/
                earliestKnownOracleIndex = uint80(
                    (uint256(prevPhaseId) << 64) | prevAggregatorLastRoundId
                );
                currentResult = oracle.getRoundData(earliestKnownOracleIndex);
            }
        }

        earliestOracleIndex = correctResult.roundId;
    }

    function getRoundDataMulti(
        AggregatorV3InterfaceS oracle,
        uint80 startId,
        uint256 numberToFetch
    )
        public
        view
        returns (AggregatorV3InterfaceS.LatestRoundData[] memory result)
    {
        result = new AggregatorV3InterfaceS.LatestRoundData[](numberToFetch);
        AggregatorV3InterfaceS.LatestRoundData memory latestRoundData = oracle
            .latestRoundData();

        for (
            uint256 i = 0;
            i < numberToFetch && startId <= latestRoundData.roundId;
            ++i
        ) {
            result[i] = oracle.getRoundData(startId);

            // Check if there was a 'phase change' AND the `_currentOracleUpdateTimestamp` is zero.
            if (
                (latestRoundData.roundId >> 64) != (startId >> 64) &&
                result[i].answer == 0
            ) {
                // NOTE: if the phase changes, then we want to correct the phase of the update.
                //       There is no guarantee that the phaseID won't increase multiple times in a short period of time (hence the while loop).
                //       But chainlink does promise that it will be sequential.
                while (result[i].answer == 0) {
                    // startId = (((startId >> 64) + 1) << 64) | uint80(uint64(startId));
                    startId += (1 << 64); // ie add 2^64

                    result[i] = oracle.getRoundData(startId);
                }
            }
            ++startId;
        }
    }
}