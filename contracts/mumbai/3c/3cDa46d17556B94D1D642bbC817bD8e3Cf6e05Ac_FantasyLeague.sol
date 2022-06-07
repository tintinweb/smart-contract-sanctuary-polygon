// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./fantasy-league-parts/H2HCompetition.sol";

/**
 * @title LeagueDAO Fantasy League
 */
contract FantasyLeague is H2HCompetition {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Initializer _______________

    /**
     * @notice Acts like constructor for upgradeable contracts
     *
     * @param _admin Address for LEAGUE_PASS_ROLE
     * @param _erc721 Address of the cards with players
     * @param _calculator Scores calculator contract
     */
    function initialize(
        address _admin,
        address _generator,
        address _erc721,
        address _calculator,
        IERC20Upgradeable[] calldata _rewardTokens
    ) external initializer {
        init_GameProgress_unchained();
        init_UsersNDivisions_unchained(_admin, _generator);
        init_StakeValidator_unchained(_erc721);
        init_Staker_unchained();
        init_H2HCompetition_unchained(_calculator, _rewardTokens);
    }

    // _______________ External functions _______________

    function nextGame(uint256[] calldata _totalWeekRewards)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyGameStage(GameStage.WaitingNextGame)
    {
        // TODO Pay rewards
        // TODO Go to the playoff and the final (Mega League)
        if (areH2HCompetitionsStage) {
            startNextCompetitionWeek();
            setWeekRewards(_totalWeekRewards);
        } else {
            weekTracker.reset();
            areH2HCompetitionsStage = true;
            // TODO Everything to close season :D
            closeSeason();
        }
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./Staker.sol";
import "../../gen1/interfaces/INomoCalculator.sol";

/**
 * @notice This contract is responsible for weekly competitions and rewards.
 *
 * It includes the following functionality:
 * - Determining the schedule.
 * - Calculation of team score points and determination of winners.
 * - Counting and withdrawal of rewards.
 */
abstract contract H2HCompetition is Staker {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Enums _______________

    enum CompetitionResult {
        FirstUserWon,
        SecondUserWon,
        Tie
    }

    // _______________ Structs _______________

    // ____ Structs for storing of H2H results and user rewards ____

    struct WeekData {
        uint256 totalPoints;
        // reward token => reward value
        mapping(IERC20Upgradeable => uint256) totalRewards;
        mapping(IERC20Upgradeable => uint256) rewardPerPoint;
    }

    struct UserSeasonStats {
        uint32 wins;
        uint32 losses;
        uint32 ties;
    }

    struct UserWeekStats {
        uint256 points;
        // reward token => reward value
        mapping(IERC20Upgradeable => uint256) rewards;
        bool isWinner;
    }

    // _______________ Storage _______________

    // ____ To verify that weekly competitions is over ____

    bool public areH2HCompetitionsStage;

    // How many weeks of H2H competitions
    uint8 private competitionWeekNumber;

    // ____ External score calculator interface ____

    /// @notice Score calculator
    INomoCalculator public calculator;

    // ____ Variables for calculation of H2H competition ____

    /// @notice Used for points update and H2H winners evaluation. Last division ID that will be calculated
    uint256 public nextCompetedDivision;

    /// @notice Next user ID for whom rewards will be updated
    uint256 public nextUserWithUpdRews;

    /// @notice Last game ID
    CountersUpgradeable.Counter internal weekTracker;

    /// @notice Timestamp when last game has started
    uint256 public currentGameStartTime;

    // ____ Variables for writing history results of H2H competition ____

    /// @notice game season id => current week in season => WeekData struct
    mapping(uint256 => mapping(uint256 => WeekData)) public gamesStats;

    /// @notice user => season id => UserSeasonStats
    mapping(address => mapping(uint256 => UserSeasonStats)) public userSeasonStats;

    /// @notice user => season id => game id => UserWeekStats
    mapping(address => mapping(uint256 => mapping(uint256 => UserWeekStats))) public userWeeklyStats;

    // ____ Interfaces of external reward token contracts ____

    IERC20Upgradeable[] public rewardTokens;
    //// To compele
    // // ERC20 => id in the rewardTokens array
    // mapping(IERC20Upgradeable => uint256) public rewardTokenToId;

    // ____ For withdrawal of rewards by a user ____

    // user => reward token => reward value
    mapping(address => mapping(IERC20Upgradeable => uint256)) public accumulatedRewards;

    // _______________ Events _______________

    event CompetitionWeekNumberSet(uint8 _number);

    event H2HCompetitionWeekStarted(uint256 _week);

    /// @notice When calculator updated
    event CalculatorSet(address _calculator);

    /// @notice On head to head competition result
    event H2HCompetitionResult(
        address indexed _user1,
        address indexed _user2,
        CompetitionResult indexed _competitionResult,
        uint256 _week
    );

    event RewardPerPointCalcutated(address _rewardERC20, uint256 _rewardPerPoint);

    event UserRewardsUpdated(
        address indexed _user,
        address indexed _token,
        uint256 _weekRewards,
        uint256 _accumulatedRewards
    );

    event RewardWithdrawn(address indexed _user, IERC20Upgradeable indexed _token, uint256 _amount);

    // _______________ Initializer _______________

    function init_H2HCompetition_unchained(address _calculator, IERC20Upgradeable[] calldata _rewardTokens)
        internal
        onlyInitializing
    {
        calculator = INomoCalculator(_calculator);
        emit CalculatorSet(_calculator);

        areH2HCompetitionsStage = true;
        competitionWeekNumber = 15;
        emit CompetitionWeekNumberSet(15);

        rewardTokens = _rewardTokens;
    }

    // _______________ External functions _______________

    // ____ To verify that weekly competitions is over ____

    function setCompetitionWeekNumber(uint8 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Temporary requirement, since in the current form the algorithms do not assume another number
        require(_number == 15, "Number of weeks should be equal to 15");

        competitionWeekNumber = _number;
        emit CompetitionWeekNumberSet(_number);
    }

    // ____ For H2H competitions ____

    /**
     * @notice Change calculator contract address
     *
     * @param _calculator New calculator address
     */
    function setCalculator(address _calculator) external onlyRole(DEFAULT_ADMIN_ROLE) nonzeroAddress(_calculator) {
        calculator = INomoCalculator(_calculator);
        emit CalculatorSet(_calculator);
    }

    /**
     * @notice Calculate and store users points
     *
     * @param _numberOfDivisions Amount of divisions to process
     */
    function competeH2Hs(uint256 _numberOfDivisions)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyGameStage(GameStage.H2HCompetitions)
    {
        uint256 fromDivision = nextCompetedDivision;
        // The last division that will be calculated in this batch
        uint256 toDivision = nextCompetedDivision + _numberOfDivisions - 1;
        // Check of overflow
        uint256 lastDivision = getNumberOfDivisions() - 1;
        if (toDivision < lastDivision) {
            nextCompetedDivision = toDivision + 1;
        } else {
            if (toDivision != lastDivision) {
                toDivision = lastDivision;
            }
            nextCompetedDivision = 0;
            moveGameStageTo(GameStage.RewardPerPointCalculation);
        }

        // Below are variables for a loop
        uint256 week = weekTracker.current();
        // The elements of this array are read in pairs (indexes zero and one correspond to the first pair, and so on)
        uint8[12] memory wSchedule = weekSchedule(week);

        uint256 season = seasonId.current();
        // Number by which the offset occurs to determine a user index in the array of all users
        uint256 offsetInArray;
        // Index of the first user (competitor) in a pair in the current division
        uint256 competitor;
        // A pair of users (competitors)
        address user1;
        address user2;
        // Total score of users (competitors)
        uint256 user1Score;
        uint256 user2Score;

        // Total score of competitors in calculated divisions
        uint256 totalPoints;

        // Start from the first division that will be calculated in this batch
        // prettier-ignore
        for (uint256 division = fromDivision; division <= toDivision; ++division) {

            offsetInArray = division * getDivisionSize();
            for (competitor = 0; competitor < 12; competitor += 2) {
                // Get addresses of the first and second users (competitors)
                user1 = users[season][wSchedule[competitor] + offsetInArray];
                user2 = users[season][wSchedule[competitor + 1] + offsetInArray];

                user1Score = calculateUserScore(user1);
                user2Score = calculateUserScore(user2);
                CompetitionResult result = getCompetitionResult(user1Score, user2Score);
                updateUserStats(user1, user2, result);
                emit H2HCompetitionResult(user1, user2, result, weekTracker.current());

                // Increasing of winner's score to increase his rewards. Tie means both are winners
                if (result == CompetitionResult.FirstUserWon) {
                    user1Score *= 2;
                } else if (result == CompetitionResult.SecondUserWon) {
                    user2Score *= 2;
                } else {
                    // Tie
                    user1Score *= 2;
                    user2Score *= 2;
                }
                saveUserWeekScore(user1, user1Score);
                saveUserWeekScore(user2, user2Score);

                totalPoints += user1Score + user2Score;
            }
        }
        gamesStats[season][week].totalPoints += totalPoints;
    }

    // ____ For weekly calculation of rewards ____

    function calculateRewardPerPoint() external onlyGameStage(GameStage.RewardPerPointCalculation) {
        IERC20Upgradeable token;
        uint256 rewardPerPoint;
        WeekData storage weekData = gamesStats[seasonId.current()][weekTracker.current()];
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            token = rewardTokens[i];
            rewardPerPoint = weekData.totalRewards[token] / weekData.totalPoints;
            weekData.rewardPerPoint[token] = rewardPerPoint;
            emit RewardPerPointCalcutated(address(token), rewardPerPoint);
        }

        moveGameStageTo(GameStage.RewardsUpdate);
    }

    function updateRewardsForUsers(uint256 _numberOfUsers) external onlyGameStage(GameStage.RewardsUpdate) {
        require(_numberOfUsers != 0, "The number of users to update should not be equal to zero");

        // Index of the first user that will be updated in this batch
        uint256 fromUser = nextUserWithUpdRews;
        // Index of the last user that will be updated in this batch
        uint256 toUser = nextUserWithUpdRews + _numberOfUsers - 1;
        // Check of overflow
        uint256 lastUser = getNumberOfUsers() - 1;
        if (toUser < lastUser) {
            nextUserWithUpdRews = toUser + 1;
        } else {
            if (toUser != lastUser) {
                toUser = lastUser;
            }
            nextUserWithUpdRews = 0;
            moveGameStageTo(GameStage.WaitingNextGame);
        }

        address[] storage refUsers = users[seasonId.current()];
        for (uint256 i = fromUser; i <= toUser; ++i) {
            updateRewardsForUser(refUsers[i]);
        }
    }

    // ____ For withdrawal of rewards ____

    function withdrawRewards() external addedUser(_msgSender()) {
        IERC20Upgradeable token;
        uint256 amount;
        mapping(IERC20Upgradeable => uint256) storage refSenderAccumulatedRewards = accumulatedRewards[_msgSender()];
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            token = rewardTokens[i];

            amount = refSenderAccumulatedRewards[token];
            delete refSenderAccumulatedRewards[token];
            token.transfer(_msgSender(), amount);
            emit RewardWithdrawn(_msgSender(), token, amount);
        }
    }

    //  ____ Extra view functionality for back end ____

    function getCurrentWeek() external view returns (uint256) {
        return weekTracker.current();
    }

    function getCompetitionWeekNumber() external view returns (uint8) {
        return competitionWeekNumber;
    }

    function getTotalWeekRewards(
        uint256 _season,
        uint256 _week,
        IERC20Upgradeable _token
    ) external view returns (uint256) {
        return gamesStats[_season][_week].totalRewards[_token];
    }

    function getRewardPerPoint(
        uint256 _season,
        uint256 _week,
        IERC20Upgradeable _token
    ) external view returns (uint256) {
        return gamesStats[_season][_week].rewardPerPoint[_token];
    }

    function getUserWeekReward(
        address _user,
        uint256 _season,
        uint256 _week,
        IERC20Upgradeable _token
    ) external view returns (uint256) {
        return userWeeklyStats[_user][_season][_week].rewards[_token];
    }

    function getRewardTokens() external view returns (IERC20Upgradeable[] memory) {
        return rewardTokens;
    }

    // _______________ Public functions _______________

    // ____ For H2H competitions ____

    /**
     * @notice Count user score for the week
     *
     * @param _user Team players Ids
     * @return teamScore Weekly score of the user's team
     */
    function calculateUserScore(address _user) public view returns (uint256 teamScore) {
        uint256[] storage team = stakedPlayers[seasonId.current()][_user];

        // Calculation of total user's score taking into account the points of each player in a team
        teamScore = 0;
        for (uint256 i = 0; i < team.length; ++i) {
            teamScore += calculator.calculatePoints(team[i], currentGameStartTime);
        }
    }

    /**
     * @notice Getting of week schedule for the head to head competitions.
     *
     * @param _week Competition week number.
     * @return Teams order.
     *
     * @dev The elements of this array are read in pairs, that is, elements with indexes zero and one correspond to the
     * first pair, and so on. Each value is the index of the user (is equals to team) in the division.
     */
    // prettier-ignore
    function weekSchedule(uint256 _week) public pure returns (uint8[12] memory) {
        /*
         * Schedule for H2H competitions. For the first week it is
         * the first team vs the twelfth team (0 vs 11), the second vs the eleventh, etc.
         */
        if (_week == 1)  return [ 0, 11,   1,  10,   2,  9,    3,  8,    4,  7,    5,  6  ];

        if (_week == 2)  return [ 0, 10,   11, 9,    1,  8,    2,  7,    3,  6,    4,  5  ];

        if (_week == 3)  return [ 0, 9,    10, 8,    11, 7,    1,  6,    2,  5,    3,  4  ];

        if (_week == 4)  return [ 0, 8,    9,  7,    10, 6,    11, 5,    1,  4,    2,  3  ];

        if (_week == 5)  return [ 0, 7,    8,  6,    9,  5,    10, 4,    11, 3,    1,  2  ];

        if (_week == 6)  return [ 0, 6,    7,  5,    8,  4,    9,  3,    10, 2,    11, 1  ];

        if (_week == 7)  return [ 0, 5,    6,  4,    7,  3,    8,  2,    9,  1,    10, 11 ];

        if (_week == 8)  return [ 0, 4,    5,  3,    6,  2,    7,  1,    8,  11,   9,  10 ];

        if (_week == 9)  return [ 0, 3,    4,  2,    5,  1,    6,  11,   7,  10,   8,  9  ];

        if (_week == 10) return [ 0, 2,    3,  1,    4,  11,   5,  10,   6,  9,    7,  8  ];

        if (_week == 11) return [ 0, 1,    2,  11,   3,  10,   4,  9,    5,  8,    6,  7  ];

        if (_week == 12) return [ 0, 11,   1,  10,   2,  9,    3,  8,    4,  7,    5,  6  ];

        if (_week == 13) return [ 0, 10,   11, 9,    1,  8,    2,  7,    3,  6,    4,  5  ];

        if (_week == 14) return [ 0, 9,    10, 8,    11, 7,    1,  6,    2,  5,    3,  4  ];
        
        if (_week == 15) return [ 0, 8,    9,  7,    10, 6,    11, 5,    1,  4,    2,  3  ];

        revert("Schedule does not contain a week with the specified number");
    }

    // _______________ Internal functions _______________

    // ____ For going to next H2H competition week ____

    function startNextCompetitionWeek() internal {
        if (weekTracker.current() < competitionWeekNumber) {
            moveGameStageTo(GameStage.H2HCompetitions);
            weekTracker.increment();
            currentGameStartTime = block.timestamp;
            emit H2HCompetitionWeekStarted(weekTracker.current());
        } else {
            areH2HCompetitionsStage = false;
            // moveGameStageTo(GameStage.Playoff);
        }
    }

    // Adding of rewards for the current week
    function setWeekRewards(uint256[] memory _totalWeekRewards) internal onlyGameStage(GameStage.H2HCompetitions) {
        WeekData storage weekData = gamesStats[seasonId.current()][weekTracker.current()];
        IERC20Upgradeable token;
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            token = rewardTokens[i];
            weekData.totalRewards[token] = _totalWeekRewards[i];
        }
    }

    // ____ For H2H competitions ____

    // prettier-ignore
    function getCompetitionResult(uint256 _user1Score, uint256 _user2Score)
        internal
        pure
        returns (CompetitionResult)
    {
        if (_user1Score > _user2Score)
            return CompetitionResult.FirstUserWon;
        if (_user1Score < _user2Score)
            return CompetitionResult.SecondUserWon;
        // A tie means both are winners
        return CompetitionResult.Tie;
    }

    function updateUserStats(
        address _user1,
        address _user2,
        CompetitionResult _result
    ) internal {
        uint256 season = seasonId.current();
        uint256 week = weekTracker.current();
        if (_result == CompetitionResult.FirstUserWon) {
            userSeasonStats[_user1][season].wins += 1;
            userWeeklyStats[_user1][season][week].isWinner = true;

            userSeasonStats[_user2][season].losses += 1;
            userWeeklyStats[_user2][season][week].isWinner = false;
        } else if (_result == CompetitionResult.SecondUserWon) {
            userSeasonStats[_user1][season].losses += 1;
            userWeeklyStats[_user1][season][week].isWinner = false;

            userSeasonStats[_user2][season].wins += 1;
            userWeeklyStats[_user2][season][week].isWinner = true;
        } else {
            // Tie
            userSeasonStats[_user1][season].ties += 1;
            userWeeklyStats[_user1][season][week].isWinner = true;

            userSeasonStats[_user2][season].ties += 1;
            userWeeklyStats[_user2][season][week].isWinner = true;
        }
    }

    function saveUserWeekScore(address _user, uint256 _points) internal {
        userWeeklyStats[_user][seasonId.current()][weekTracker.current()].points = _points;
    }

    // ____ For weekly calculation of rewards ____

    function updateRewardsForUser(address _user) internal {
        IERC20Upgradeable token;

        uint256 season = seasonId.current();
        uint256 week = weekTracker.current();
        UserWeekStats storage userWeekStats = userWeeklyStats[_user][season][week];

        uint256 rewardPerPoint;
        WeekData storage weekData = gamesStats[season][week];
        uint256 userPoints;
        uint256 weekRewards;

        mapping(IERC20Upgradeable => uint256) storage refUserAccumulatedRewards = accumulatedRewards[_user];
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            token = rewardTokens[i];

            rewardPerPoint = weekData.rewardPerPoint[token];
            userPoints = userWeekStats.points;
            weekRewards = rewardPerPoint * userPoints;
            userWeekStats.rewards[token] = weekRewards;

            refUserAccumulatedRewards[token] += weekRewards;
            emit UserRewardsUpdated(_user, address(token), weekRewards, refUserAccumulatedRewards[token]);
        }
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[38] private gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./StakeValidator.sol";

/**
 * @dev
 */
abstract contract Staker is StakeValidator {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Storage _______________

    // ____ For competing team squad ____

    /// @notice Players staked by the user. Staked players are active team of the user
    // Season ID => (user => staked players)
    mapping(uint256 => mapping(address => uint256[])) public stakedPlayers;

    /// @notice Staked token index in the staked players array by user
    // Season ID => (user => (token ID => token index in the stakedPlayers[user]))
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private stakedPlayerIncreasedIndex;

    // ____ For bench ____

    // Season ID => (user => staked bench players)
    mapping(uint256 => mapping(address => uint256[])) public stakedBenchPlayers;

    // Season ID => (user => (token ID => is bench palyer))
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public isBenchPlayerStaked;

    // _______________ Events _______________

    /// @notice When user stakes new token to the team
    event PlayerStaked(uint256 _season, address _user, uint256 _tokenId);

    /// @notice When user unstakes token from the team
    event PlayerUnstaked(uint256 _season, address _user, uint256 _tokenId);

    event BenchPlayerStaked(uint256 _season, address _user, uint256 _tokenId);

    event BenchPlayerUnstaked(uint256 _season, address _user, uint256 _tokenId);

    event ReplacedFromBench(uint256 _season, address _user, uint256 _teamTokenId, uint256 _benchTokenId);

    // _______________ Initializer _______________

    function init_Staker_unchained() internal onlyInitializing {}

    // _______________ External functions _______________

    /**
     * @notice Adds player to caller's team
     * @dev Caller must be registered user and there must be free places to stake (unused limits).
     * @param _tokenId Player NFT tokenId
     */
    function stakePlayer(uint256 _tokenId) external addedUser(_msgSender()) {
        // TODO Add check that `_tokenId` is in a right division

        // Adding of a player to caller's team
        addToTeam(_tokenId);
        // Taking of a player token
        erc721.transferFrom(_msgSender(), address(this), _tokenId);
        emit PlayerStaked(seasonId.current(), _msgSender(), _tokenId);
    }

    /**
     * @notice Remove player from caller's team
     * @dev Caller must be registered user and there must be free places to stake (unused limits).
     * @param _tokenId Player NFT tokenId
     */
    function unstakePlayer(uint256 _tokenId) external addedUser(_msgSender()) {
        deleteFromTeam(_tokenId);
        erc721.transferFrom(address(this), _msgSender(), _tokenId);
        emit PlayerUnstaked(seasonId.current(), _msgSender(), _tokenId);
    }

    function stakeBenchPlayer(uint256 _tokenId) external addedUser(_msgSender()) {
        // TODO Add check that `_tokenId` is in a right division

        // Adding of a player to caller's bench
        addToBench(_tokenId);
        // Taking of a player token
        erc721.transferFrom(_msgSender(), address(this), _tokenId);
        emit BenchPlayerStaked(seasonId.current(), _msgSender(), _tokenId);
    }

    function unstakeBenchPlayer(uint256 _tokenId) external addedUser(_msgSender()) {
        deleteFromBench(_tokenId);
        erc721.transferFrom(address(this), _msgSender(), _tokenId);
        emit BenchPlayerUnstaked(seasonId.current(), _msgSender(), _tokenId);
    }

    /// @notice Swaps a player in a team with a player on a bench
    function replaceFromBench(uint256 _teamTokenId, uint256 _benchTokenId) external addedUser(_msgSender()) {
        deleteFromBench(_benchTokenId);
        addToBench(_teamTokenId);

        deleteFromTeam(_teamTokenId);
        addToTeam(_benchTokenId);

        emit ReplacedFromBench(seasonId.current(), _msgSender(), _teamTokenId, _benchTokenId);
    }

    // ____ Extra view functionality for back end ____

    function getStakedPlayerIndex(
        uint256 _season,
        address _user,
        uint256 _tokenId
    ) external view returns (uint256) {
        require(isPlayerStaked(_season, _user, _tokenId), "Such a player is not staked");
        return getIndex(stakedPlayerIncreasedIndex[_season][_user][_tokenId]);
    }

    /**
     * @notice Returns an array of token ids staked by the specified user
     * @return Array of Gen2Player NFTs ids
     */
    function getStakedPlayersOfUser(uint256 _season, address _user)
        external
        view
        addedUser(_user)
        returns (uint256[] memory)
    {
        return stakedPlayers[_season][_user];
    }

    function getStakedBenchPlayersOfUser(uint256 _season, address _user)
        external
        view
        addedUser(_user)
        returns (uint256[] memory)
    {
        return stakedBenchPlayers[_season][_user];
    }

    // _______________ Public functions _______________

    function isPlayerStaked(
        uint256 _season,
        address _user,
        uint256 _tokenId
    ) public view returns (bool) {
        return stakedPlayerIncreasedIndex[_season][_user][_tokenId] != 0;
    }

    // _______________ Private functions _______________

    function getIndex(uint256 _increasedIndex) private pure returns (uint256) {
        return _increasedIndex - 1;
    }

    function addToTeam(uint256 _tokenId) private {
        uint256 season = seasonId.current();
        require(!isPlayerStaked(season, _msgSender(), _tokenId), "This player has already been staked");

        // Reverse if there is no free space left for a token with such a position
        validatePosition(_tokenId, _msgSender());

        uint256[] storage players = stakedPlayers[season][_msgSender()];
        players.push(_tokenId);
        stakedPlayerIncreasedIndex[season][_msgSender()][_tokenId] = players.length;
    }

    function deleteFromTeam(uint256 _tokenId) private {
        uint256 season = seasonId.current();
        require(isPlayerStaked(season, _msgSender(), _tokenId), "This player is not staked");

        unstakePosition(_tokenId, _msgSender());

        uint256[] storage players = stakedPlayers[season][_msgSender()];
        mapping(uint256 => uint256) storage increasedIndex = stakedPlayerIncreasedIndex[season][_msgSender()];

        // Deletion of the player from the array of staked players and writing down of its index in the mapping
        // Index of the player in the array of staked players
        uint256 playerIndex = getIndex(increasedIndex[_tokenId]);
        uint256 lastPlayerTokenId = players[players.length - 1];
        // Replacing of the deleted player with the last one in the array
        players[playerIndex] = lastPlayerTokenId;
        // Cutting off the last player
        players.pop();

        // Replacing of an index of the last player with the deleted one
        increasedIndex[lastPlayerTokenId] = playerIndex + 1;
        // Reset of the deleted player index
        delete increasedIndex[_tokenId];
    }

    function addToBench(uint256 _tokenId) private {
        uint256 season = seasonId.current();
        require(!isBenchPlayerStaked[season][_msgSender()][_tokenId], "This player has already been benched");

        // Check that there are empty seats on a bench
        uint256[] storage bench = stakedBenchPlayers[season][_msgSender()];
        require(bench.length <= benchSize[season], "Bench is already full");

        // Adding a player to a bench
        bench.push(_tokenId);
        isBenchPlayerStaked[season][_msgSender()][_tokenId] = true;
    }

    function deleteFromBench(uint256 _tokenId) private {
        uint256 season = seasonId.current();
        require(isBenchPlayerStaked[season][_msgSender()][_tokenId], "This player is not benched");
        isBenchPlayerStaked[season][_msgSender()][_tokenId] = false;

        uint256 benchSz = benchSize[season];
        uint256[] storage bench = stakedBenchPlayers[season][_msgSender()];
        for (uint256 i = 0; i < benchSz; ++i)
            if (bench[i] == _tokenId) {
                if (i == benchSz - 1) {
                    bench.pop();
                } else {
                    uint256 lastPlayer = bench[benchSz - 1];
                    bench.pop();
                    bench[i] = lastPlayer;
                }
                break;
            }
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface INomoCalculator {
    function calculatePoints(uint256 _tokenId, uint256 _gameStartTime) external view returns (uint256 points);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./UsersNDivisions.sol";
import "../interfaces/IGen2PlayerToken.sol";

/**
 * @dev
 */
abstract contract StakeValidator is UsersNDivisions {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // TODO Add staking timer contract for verifications

    // _______________ Storage _______________

    // ____ External Gen2 NF Player Token interface ____

    /// @notice External Genesis Gen2 NF Player Token contract interface. This tokens is staked by users
    IGen2PlayerToken public erc721;

    // ____  To check the filling of competing team positions (roles) during staking ____

    /// @notice Staking limitations setting, e.g. user can stake 1 QB, 2 RB, 2 WR, 1 TE, 3 DEF Line, 1 LB, 1 DEF Back + flex staking (see above)
    // Season ID => position code => staking amount
    mapping(uint256 => mapping(uint256 => uint256)) public positionNumber;

    /**
     * @notice Flex position code (see flex position staking limitation description below)
     * @dev Other position codes will be taken from admin and compared to position codes specified in the Genesis NomoNFT (see NomoNFT contract to find position codes and CardImages functionality)
     */
    uint256 public constant FLEX_POSITION = uint256(keccak256(abi.encode("FLEX_POSITION")));

    /// @notice Custom positions flex limitation, that's a places for staking where several positions code can stand/be, e.g. 3 staking places for QB, RB, WR or TE, so, for example, user can use them as 2 QB + 1 TE or 1 WR + 1 RB + 1 TE or in other way when in total there will 3 NFTs (additionally to usual limitations) with specified positions
    // Season ID => position code => is included in flex limitation
    mapping(uint256 => mapping(uint256 => bool)) public isFlexPosition;

    /// @notice  amount of staking places for flex limitation
    // Season ID => flex position number
    mapping(uint256 => uint256) public flexPositionNumber;

    // Season ID => token id => is token staked in the flex position
    mapping(uint256 => mapping(uint256 => bool)) public isPlayerInFlexPosition;

    /// @notice Staked tokens by position to control staking limitations
    // Season ID => user => position code => amount
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public userPositionNumber;

    // ____ For bench ____

    // Season ID => bench size
    mapping(uint256 => uint256) public benchSize;

    // _______________ Events _______________

    /// @notice When staked NFT contract changed
    event ERC721Set(address _erc721);

    /// @notice When staking limitation updated
    event PositionNumberSet(uint256 _season, uint256 indexed _position, uint256 _newStakingLimit);

    /// @notice When positions are added or deleted from flex limitation
    event FlexPositionSet(uint256 _season, uint256 indexed _position, bool _isFlexPosition);

    /// @notice When flex limit amount is changed
    event FlexPositionNumberSet(uint256 _season, uint256 indexed _newNumber);

    event BenchSizeSet(uint256 _season, uint256 _number);

    // _______________ Modifiers _______________

    /**
     * @notice Safety check that owner didn't forget to pass valid position code
     * @dev Position code with value = 0 is potentially unsafe, so it's better to block them at all
     * @param _position integer number code that represents specific position; ths value must exist in the Genesis NomoNFT (see NomoNFT contract to find position codes and CardImages functionality)
     */
    modifier nonzeroPosition(uint256 _position) {
        require(_position != 0, "position code is 0, check position code");
        _;
    }

    // _______________ Initializer _______________

    function init_StakeValidator_unchained(address _erc721) internal onlyInitializing {
        erc721 = IGen2PlayerToken(_erc721);
        emit ERC721Set(_erc721);

        uint256 season = seasonId.current();
        benchSize[season] = 6;
        emit BenchSizeSet(season, 6);
    }

    // _______________ External functions _______________

    /**
     * @notice Change NFT address
     *
     * @param _erc721 New NFT address
     */
    function setERC721(address _erc721) external onlyRole(DEFAULT_ADMIN_ROLE) nonzeroAddress(_erc721) {
        erc721 = IGen2PlayerToken(_erc721);
        emit ERC721Set(_erc721);
    }

    /**
     * @notice Allows contract owner to set limitations for staking ( see flex limitations setter below)
     * @dev This is only usual limitation, in addition there are positions flex limitation
     * @param _position integer number code that represents specific position; ths value must exist in the Genesis NomoNFT (see NomoNFT contract to find position codes and CardImages functionality). Notice - this function reverts if _position is 0
     * @param _howMany amount of players with specified position that user can stake. Notice - user can stake some positions over this limit if these positions are included in the flex limitation
     */
    function setPositionNumber(uint256 _position, uint256 _howMany)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroPosition(_position)
    {
        uint256 season = seasonId.current();
        positionNumber[season][_position] = _howMany;
        emit PositionNumberSet(season, _position, _howMany);
    }

    /**
     * @notice Allows contract owner to change positions in flex limitation
     * @dev This is addition to usual limitation
     * @param _position integer number code that represents specific position; ths value must exist in the Genesis NomoNFT (see NomoNFT contract to find position codes and CardImages functionality). Notice - this function reverts if _position is 0
     * @param _isFlexPosition if true, then position is in the flex, if false, then tokens with this positions can't be staked in flex limitation places
     */
    function setFlexPosition(uint256 _position, bool _isFlexPosition)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroPosition(_position)
    {
        uint256 season = seasonId.current();
        require(
            isFlexPosition[season][_position] != _isFlexPosition,
            "passed _position is already with passed bool value"
        );
        isFlexPosition[season][_position] = _isFlexPosition;
        emit FlexPositionSet(season, _position, _isFlexPosition);
    }

    /**
     * @notice Allows contract owner to set number of tokens which can be staked as a part of the flex limitation
     * @dev If new limit is 0, then it means that flex limitation disabled. Note: you can calculate total number of tokens that can be staked by user if you will sum flex limitation amount and all limits for all positions.
     * @param _newFlexPositionNumber number of tokens that can be staked as a part of the positions flex limit
     */
    function setFlexPositionNumber(uint256 _newFlexPositionNumber) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 season = seasonId.current();
        flexPositionNumber[season] = _newFlexPositionNumber;
        emit FlexPositionNumberSet(season, _newFlexPositionNumber);
    }

    function setBenchSize(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Temporary requirement, since in the current form the algorithms do not assume another number
        require(_number == 6, "Number of bench players should be equal to 6");

        uint256 season = seasonId.current();
        benchSize[season] = _number;
        emit BenchSizeSet(season, _number);
    }

    // _______________ Internal functions _______________

    /**
     * @notice Check limitations and fill the position limit with token if there is a free place.
     * @dev Reverts if user reached all limits for token's position
     * @param _tokenId Gen2PlayerToken id user wants to stake
     * @param _user User's address
     */
    function validatePosition(uint256 _tokenId, address _user) internal addedUser(_user) {
        // get token's position
        uint256 position = erc721.getTokenPosition(_tokenId);
        require(position != 0, "Position code can't be zero");
        // check limits
        // 1. check simple limitations
        uint256 season = seasonId.current();
        mapping(uint256 => uint256) storage userPositionNum = userPositionNumber[season][_user];
        if (userPositionNum[position] < positionNumber[season][position]) {
            // stake using simple limit
            userPositionNum[position] += 1;
        } else {
            // check if this position can be staked in flex limit
            require(isFlexPosition[season][position], "Simple limit is reached and can't stake in flex");
            // check that flex limit isn't reached
            uint256 userFlexPosNumber = userPositionNum[FLEX_POSITION];
            require(userFlexPosNumber < flexPositionNumber[season], "Simple and flex limits reached");
            // if requirements passed, then we can stake this token in flex limit
            userPositionNum[FLEX_POSITION] += 1;
            isPlayerInFlexPosition[season][_tokenId] = true;
        }
    }

    function unstakePosition(uint256 _tokenId, address _user) internal addedUser(_user) {
        // get token's position
        uint256 position = erc721.getTokenPosition(_tokenId);
        require(position != 0, "Position code can't be zero");

        uint256 season = seasonId.current();
        if (isPlayerInFlexPosition[season][_tokenId]) {
            userPositionNumber[season][_user][FLEX_POSITION] -= 1;
        } else {
            userPositionNumber[season][_user][position] -= 1;
        }
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./GameProgress.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/INomoRNG.sol";

/**
 * @dev
 */
abstract contract UsersNDivisions is GameProgress, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Storage _______________

    // ____ For access ____

    /// @notice Name of the admin role
    bytes32 public constant LEAGUE_PASS_ROLE = keccak256("LEAGUE_PASS_ROLE");

    // ____ Management of users ____

    /// @notice Array of registered users
    // Season ID => users
    mapping(uint256 => address[]) public users;

    /// @notice Is user added to the game
    // Season ID => (user => is user)
    mapping(uint256 => mapping(address => bool)) public isUser;

    // ____ Generation of random numbers ____

    /// @notice Random number generator
    INomoRNG public generator;

    /// @notice Random number used for users' shuffling
    uint256 public randNumber;

    // ____ Shuffle ____

    /// @notice Last shuffled user ID. It's basically an array pointer to continue shuffling where we ended in last transaction
    uint256 public shuffledUserNum;

    // ____ User dividing (Divisions) ____

    /// @notice Defines amount of teams in division
    // Teams in Division. 1 user per 1 team
    uint256 private divisionSize;

    // _______________ Events _______________

    /// @notice When new user added to the game
    event UserAdded(uint256 indexed _seasonId, address _user);

    event RandGeneratorSet(address _generator);

    /// @notice Random generated
    event RandNumUpdated(uint256 _randNumber);

    event ShuffleEnd();

    event DivisionSizeSet(uint256 _number);

    // _______________ Modifiers _______________

    /**
     * @dev Check if address is not zero
     *
     * @param _address Address to check
     */
    modifier nonzeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    /**
     * @dev Check if user added
     *
     * @param _user Team address
     */
    modifier addedUser(address _user) {
        require(isUser[seasonId.current()][_user], "User not found");
        _;
    }

    // _______________ Initializer _______________

    function init_UsersNDivisions_unchained(address _admin, address _generator) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(LEAGUE_PASS_ROLE, _admin);

        generator = INomoRNG(_generator);
        emit RandGeneratorSet(_generator);

        divisionSize = 12;
        emit DivisionSizeSet(12);
    }

    // _______________ External functions _______________

    /**
     * @notice Add new user to the game
     * @dev This function must call other contract (look LeaguePass)
     * @param _user Address of user
     */
    function addUser(address _user)
        external
        onlyRole(LEAGUE_PASS_ROLE)
        nonzeroAddress(_user)
        onlyGameStage(GameStage.UserAdding)
    {
        // Check if user is already added
        uint256 season = seasonId.current();
        require(!isUser[season][_user], "user already added");

        // Add team to the game
        users[season].push(_user);
        isUser[season][_user] = true;

        emit UserAdded(season, _user);
    }

    /**
     * @notice Define random number generator contract
     *
     * @param _generator RNG contract address
     */
    function setRandGenerator(address _generator) external onlyRole(DEFAULT_ADMIN_ROLE) nonzeroAddress(_generator) {
        generator = INomoRNG(_generator);
        emit RandGeneratorSet(_generator);
    }

    /**
     * @notice Get random number (Chainlink VRFv2)
     *
     * @dev You need generate random on RNG contract first
     */
    function updateRandNum() external onlyRole(DEFAULT_ADMIN_ROLE) nonzeroAddress(address(generator)) {
        // get random number from generator (after that generator forget this number)
        uint256 randNum = generator.requestRandomNumber();
        randNumber = randNum;

        emit RandNumUpdated(randNum);
    }

    /**
     * @notice Shuffle users array to get random distribution across divisions
     * @dev Using Chainlink VRF for random
     * @param _numberToShuffle Amount of users to shuffle since last shuffled
     */
    function shuffleUsers(uint256 _numberToShuffle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(randNumber != 0, "Need to update random number with generator");
        require(_numberToShuffle != 0, "Number of users to shuffle should not be zero");

        if (shuffledUserNum == 0) {
            moveGameStageTo(GameStage.UserShuffle);
        }
        require(getGameStage() == GameStage.UserShuffle, "Shuffle is possible only after the adding of users");

        // Check that all users was shuffled
        address[] storage refUsers = users[seasonId.current()];
        uint256 usersLen = refUsers.length;
        require(shuffledUserNum < usersLen, "Shuffle has already been completed");

        // Check that the shuffle will be completed after this transaction
        if (usersLen <= shuffledUserNum + _numberToShuffle) {
            _numberToShuffle = usersLen - shuffledUserNum;
            emit ShuffleEnd();
            moveGameStageTo(GameStage.WaitingNextGame);
        }

        // Shuffle the array of users
        uint256 newShuffledUserNum = shuffledUserNum + _numberToShuffle;
        uint256 index;
        address user;
        for (uint256 i = shuffledUserNum; i < newShuffledUserNum; ++i) {
            index = i + (uint256(keccak256(abi.encodePacked(randNumber))) % (usersLen - i));
            // Swap
            user = refUsers[index];
            refUsers[index] = refUsers[i];
            refUsers[i] = user;
        }
        // Saving of the number of users that were shuffled
        shuffledUserNum += _numberToShuffle;
    }

    function setDivisionSize(uint256 _newSize) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newSize > 1 && _newSize % 2 == 0, "Number of teams should be even and greater than one");
        // Temporary requirement, since in the current form the algorithms do not assume another number
        require(_newSize == 12, "Number of teams should be equal to 12");

        divisionSize = _newSize;
        emit DivisionSizeSet(_newSize);
    }

    // ____ Extra view functionality for back end ____

    function getDivisionUsers(uint256 _season, uint256 _division) external view returns (address[] memory division) {
        division = new address[](divisionSize);
        // Array of users of the specified season
        address[] storage refUsers = users[_season];
        uint256 offsetInArray = _division * division.length;
        for (uint256 i = 0; i < division.length; ++i) {
            division[i] = refUsers[i + offsetInArray];
        }
        return division;
    }

    // _______________ Public functions _______________

    /**
     * @notice How many users in the game registered
     *
     * @return Amount of the users
     */
    function getNumberOfUsers() public view returns (uint256) {
        return users[seasonId.current()].length;
    }

    function getDivisionSize() public view returns (uint256) {
        return divisionSize;
    }

    /**
     * @notice Total amount of divisions
     */
    function getNumberOfDivisions() public view returns (uint256) {
        return getNumberOfUsers() / divisionSize;
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IGen2PlayerToken is IERC721Upgradeable {
    function getTokenPosition(uint256 _tokenId) external view returns (uint256 position);

    function nftToImageId(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/**
 * @dev
 */
abstract contract GameProgress is Initializable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Enums _______________

    // After WaitingNextGame during H2HCompetitions you can staking with your deadlines
    enum GameStage {
        UserAdding,
        UserShuffle,
        WaitingNextGame,
        H2HCompetitions,
        RewardPerPointCalculation,
        RewardsUpdate
    }

    // _______________ Storage _______________

    GameStage private gameStage;

    CountersUpgradeable.Counter public seasonId;

    // _______________ Events _______________

    event GameStageMovedTo(GameStage indexed _gs);

    event SeasonFinished(uint256 indexed _seasonId);

    // _______________ Modifiers _______________

    modifier onlyGameStage(GameStage _gs) {
        require(gameStage == _gs, "This is not available at the current stage of the game");
        _;
    }

    // _______________ Initializer _______________

    function init_GameProgress_unchained() internal onlyInitializing {
        gameStage = GameStage.UserAdding;
        emit GameStageMovedTo(GameStage.UserAdding);
    }

    // _______________ Public functions _______________

    function getGameStage() public view returns (GameStage) {
        return gameStage;
    }

    // _______________ External functions _______________

    //  ____ Extra view functionality for back end ____

    function getSeasonID() external view returns (uint256) {
        return seasonId.current();
    }

    // _______________ Internal functions _______________

    function moveGameStageTo(GameStage _gs) internal {
        GameStage gs = gameStage;
        if (gs != GameStage.RewardsUpdate) {
            require(gs < _gs, "The game stage should only be moved forward");
        } else {
            require(_gs == GameStage.WaitingNextGame, "The game stage should only be moved to next game waiting stage");
        }

        gameStage = _gs;
        emit GameStageMovedTo(_gs);
    }

    function closeSeason() internal {
        emit SeasonFinished(seasonId.current());
        seasonId.increment();
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface INomoRNG {
    function requestRandomNumber() external returns (uint256 _random);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}