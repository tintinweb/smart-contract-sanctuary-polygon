// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        Modules modules;
        BadgePair delegateBadge;
        BadgePair maintainerBadge;
        BadgePair reputationBadge;
        ReputationParams reputationParams;
    }

    struct ReputationParams {
        uint256 rewardPool;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }

    struct Modules {
        address network;
        address enforcement;
        address payment;
        address reputation;
    }

    struct BadgePair {
        address token;
        uint256 tokenId;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "./LaborMarketConfigurationInterface.sol";

interface LaborMarketInterface is LaborMarketConfigurationInterface {
    struct ServiceRequest {
        address serviceRequester;
        address pToken;
        uint256 pTokenQ;
        uint256 signalExp;
        uint256 submissionExp;
        uint256 enforcementExp;
        uint256 submissionCount;
        string uri;
    }

    struct ServiceSubmission {
        address serviceProvider;
        uint256 requestId;
        uint256 timestamp;
        string uri;
        uint256[] scores;
        bool reviewed;
    }

    struct ReviewPromise {
        uint256 total;
        uint256 remainder;
    }

    function initialize(LaborMarketConfiguration calldata _configuration)
        external;

    function setConfiguration(LaborMarketConfiguration calldata _configuration)
        external;

    function getSubmission(uint256 submissionId)
        external
        view
        returns (ServiceSubmission memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory);

    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";

contract ConstantLikertEnforcement {
    /// @dev Tracks the scores given to service submissions.
    /// @dev Labor Market -> Submission Id -> Scores
    mapping(address => mapping(uint256 => Scores)) private submissionToScores;

    /// @dev Tracks the cumulative sum of average grades.
    /// @dev Labor Market -> Request Id -> Total Grade
    mapping(address => mapping(uint256 => uint256)) private requestTotalGrade;

    /// @dev The Likert grading scale.
    enum Likert {
        SPAM,
        BAD,
        OK,
        GOOD,
        GREAT
    }

    /// @dev The scores given to a service submission.
    struct Scores {
        uint256[] scores;
        uint256 avg;
    }

    constructor() {}

    /*////////////////////////////////////////////////// 
                        SETTERS
    //////////////////////////////////////////////////*/

    /// @notice Allows a maintainer to review a submission.
    /// @param _submissionId The submission to review.
    /// @param _score The score to give the submission.
    /// @return The average score of the submission.
    function review(
          uint256 _submissionId
        , uint256 _score
    )
        external
        returns (
            uint256
        )
    {
        require(
            _score <= uint256(Likert.GREAT),
            "ConstantLikertEnforcementCriteria::review: Invalid score"
        );

        Scores storage score = submissionToScores[msg.sender][_submissionId];

        uint256 requestId = getRequestId(_submissionId);

        // Update the cumulative total earned grade.
        unchecked {
            requestTotalGrade[msg.sender][requestId] -= score.avg;
        }

        // Update the submission's scores
        score.scores.push(_score);
        score.avg = _getAvg(
            score.scores
        );

        // Update the cumulative total earned grade with the submission's new average.
        unchecked {
            requestTotalGrade[msg.sender][requestId] += score.avg;
        }

        return score.avg;
    }

    /*////////////////////////////////////////////////// 
                        GETTERS
    //////////////////////////////////////////////////*/

    /// @notice Returns the point on the payment curve for a submission.
    function verify(
          uint256 _submissionId
        , uint256 _total
    )
        external
        view
        returns (
            uint256 x
        )
    {
        uint256 score = submissionToScores[msg.sender][_submissionId].avg;

        uint256 requestId = getRequestId(_submissionId);

        /// @dev The ratio of the submission's average grade to the total grade times the total pool.
        /// @dev Multiplication first to manage precision.
        x = (score * _total) / requestTotalGrade[msg.sender][requestId];

        return sqrt(x);
    }

    /// @notice Get the request id of a submission.
    /// @param _submissionId The submission id.
    /// @return The request id.
    function getRequestId(
        uint256 _submissionId
    )
        internal
        view
        returns (
            uint256
        )
    {
        return 
            LaborMarketInterface(msg.sender)
                .getSubmission(_submissionId)
                .requestId;
    }

    /// @notice Returns the sqrt of a number.
    /// @param x The number to take the sqrt of.
    /// @return result The sqrt of x.
    function sqrt(
        uint256 x
    ) 
        internal 
        pure 
        returns (
            uint256 result
        ) 
    {
        // Stolen from prbmath
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x4) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

    /// @notice Gets the average of the scores given to a submission.
    /// @param _scores The scores given to a submission.
    /// @return The average of the scores.
    function _getAvg(
        uint256[] memory _scores
    )
        internal 
        pure 
        returns (
            uint256
        ) 
    {
        uint256 cumulativeScore;
        uint256 qScores = _scores.length;

        for (uint256 i; i < qScores; ++i) {
            cumulativeScore += _scores[i];
        }

        return cumulativeScore / qScores;
    }
}