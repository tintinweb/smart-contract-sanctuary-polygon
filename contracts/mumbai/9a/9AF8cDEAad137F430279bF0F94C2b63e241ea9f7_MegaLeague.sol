// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./abstracts/mega-league-parts/DivisionWinnerReader.sol";
import "./abstracts/fantasy-league-parts/CompetitionResultEnum.sol";
import "./abstracts/common-parts/RandomGenerator.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title Mega League -- the final game stage in the end of a season.
 *
 * @notice Rewards are awarded ....
 *
 * This contract includes the following functionality:
 *  - .
 *
 * @dev Warning. This contract is not intended for inheritance. In case of inheritance, it is recommended to change the
 * access of all storage variables from public to private in order to avoid violating the integrity of the storage. In
 * addition, you will need to add functions for them to get values.
 */
contract MegaLeague is DivisionWinnerReader, RandomGenerator {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Structs _______________

    struct MegaLeagueWinner {
        uint256 points;
        address winner;
    }

    // _______________ Constants _______________

    bytes32 public constant FINANCIAL_MANAGER_ROLE = keccak256("FINANCIAL_MANAGER_ROLE");

    // _______________ Storage _______________

    // ____ For the MegaLeague stage ____

    uint256 public megaLeagueWinnerNumber;

    // Season ID => array of Mega League winners
    mapping(uint256 => MegaLeagueWinner[]) public megaLeagueWinners;

    uint256 public megaLeagueNextPossibleWinnerIndex;

    bool public isFirstStageOfMegaLeagueFinding;

    uint256 public megaLeagueLastWinnerPoints;

    // Season ID => buffer of the last Mega League winners
    mapping(uint256 => MegaLeagueWinner[]) public megaLeagueLastWinnersBuffer;

    // ____ For the RewardsCalculation stage ____

    IERC20Upgradeable[] public rewardTokens;

    // Token => reward amount
    mapping(IERC20Upgradeable => bool) public isRewardToken;

    // Season ID => (token => reward amount)
    mapping(uint256 => mapping(IERC20Upgradeable => uint256)) public rewardTokenAmounts;

    // Season ID => (token => (user => rewards))
    mapping(uint256 => mapping(IERC20Upgradeable => mapping(address => uint256))) public megaLeagueWinnerRewards;

    // _______________ Events _______________
    event RewardTokenAdded(IERC20Upgradeable _token);

    event MegaLeagueWinnerNumberSet(uint256 _megaLeagueWinnerNumber);

    event UserMegaLeagueRewardsUpdated(
        address indexed _user,
        address indexed _token,
        uint256 _megaLeagueRewards,
        uint256 _userReward
    );

    event UserMegaLeagueRewardsWithdrawn(
        uint256 indexed _userIndex,
        address indexed _userAddress,
        address indexed _token,
        uint256 _userReward
    );

    // _______________ Modifiers _______________

    // Check that the `_address` is not zero
    modifier nonzeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    // _______________ Initializer _______________

    function initialize(
        IERC20Upgradeable[] calldata _rewardTokens,
        address _financialManager,
        address _generator
    ) external initializer {
        init_SeasonSync_unchained(_msgSender());
        init_MegaLeagueProgress_unchained();
        init_RandomGenerator_unchained(_generator);

        rewardTokens = _rewardTokens;
        for (uint256 i = 0; i < _rewardTokens.length; ++i) {
            isRewardToken[_rewardTokens[i]] = true;
            emit RewardTokenAdded(_rewardTokens[i]);
        }

        _grantRole(FINANCIAL_MANAGER_ROLE, _financialManager);

        megaLeagueWinnerNumber = 10;
        emit MegaLeagueWinnerNumberSet(10);

        isFirstStageOfMegaLeagueFinding = true;
    }

    // _______________ External functions _______________

    function setMegaLeagueWinnerNumber(uint256 _megaLeagueWinnerNumber) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Temporary requirement, since in the current form the algorithms do not assume another number
        require(_megaLeagueWinnerNumber == 10, "Number of winners should be equal to 10");

        megaLeagueWinnerNumber = _megaLeagueWinnerNumber;
        emit MegaLeagueWinnerNumberSet(_megaLeagueWinnerNumber);
    }

    /**
     * @dev Sets the random number generator contract.
     *
     * @param _generator An address of the random number generator.
     */
    function setRandGenerator(address _generator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setRandomGenerator(_generator);
    }

    /**
     * @dev Updates the random number via Chainlink VRFv2.
     *
     * @notice Firstly, need to generate the random number on NomoRNG contract.
     */
    function updateRandNum() external onlyRole(DEFAULT_ADMIN_ROLE) {
        updateRandomNumber();
    }

    /**
     * @dev Finds Mega League winners. The finding process is paced.
     *
     * Requirements:
     * - The caller should be the administrator of the MegaLeague contract.
     * - The FantasyLeague should be at stage MegaLeague (`MegaLeagueStage.MegaLeague`).
     * - A limit of iterations should be greater than zero.
     *
     * @param _iterLimit   A number that allows you to split the function call into multiple transactions to avoid
     * reaching the gas cost limit. Each time the function is called, this number can be anything greater than zero.
     * When the process of finding the Mega League winners is completed, the FantasyLeague moves on to the next stage
     * (update the Mega League rewards -- `MegaLeagueStage.RewardsCalculation`). The sum of the iteration limits will
     * be approximately equal to twice the number of division winners.
     */
    // prettier-ignore
    function stepToFindMegaLeagueWinners(uint256 _iterLimit)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyMegaLeagueStage(MegaLeagueStage.MegaLeague)
    {
        require(_iterLimit != 0, "Iteration limit number should be greater than zero");

        /*
         * Description.
         *
         * This function finds Mega League winners among division winners.
         * The number of Mega League winners is equal to `megaLeagueWinnerNumber` (10 by default). There will be fewer
         * Mega League winners if there are fewer than `megaLeagueWinnerNumber` division winners.
         *
         * Because there can be many division winners, the cost of the transaction in gas can reach a limit. Because of
         * this, this function takes a number of iterations (`_iterLimit`) as input, which means that the function will
         * need to be called over and over again until the process of finding winners is complete. Completion means
         * that the FantasyLeague moves on to the next stage -- update of the Mega League rewards
         * (`MegaLeagueStage.RewardsCalculation`).
         *
         * NOTE. The user in this function means the winner of the division.
         */

        // During the current function call, users from `fromUserIndex` to `toUserIndex` will be processed
        uint256 fromUserIndex;
        uint256 toUserIndex;

        // There are storage pointers for the process
        uint256 season = seasonId;
        address[] storage refDivisionWinners = divisionWinners[season];
        mapping(address => DivisionWinnerStats) storage refDivisionWinnerStats = divisionWinnerStats[season];
        MegaLeagueWinner[] storage refMegaLeagueWinners = megaLeagueWinners[season];

        // Index of the last user in the array of division winners
        uint256 lastUserIndex = refDivisionWinners.length - 1;

        /*
         * By the end of the current transaction, this array will contain the current Mega League winners, which will
         * be written into the storage (`megaLeagueWinners` array).
         */
        MegaLeagueWinner[] memory curWinners;
        // Number of Mega League winners to find
        uint256 winnerNumber = megaLeagueWinnerNumber;

        uint256 i;
        address curUser;
        uint256 curUserPoints;

        /*
         * The first stage. It consists of finding the `megaLeagueWinnerNumber` users with the highest number of points
         * in the array of division winners.
         */
        if (isFirstStageOfMegaLeagueFinding) {
            fromUserIndex = megaLeagueNextPossibleWinnerIndex;
            toUserIndex = fromUserIndex + _iterLimit - 1;

            // Check that the first step is over and saving of the remaining number of iterations
            if (toUserIndex < lastUserIndex) {
                megaLeagueNextPossibleWinnerIndex = toUserIndex + 1;
            } else {
                if (toUserIndex != lastUserIndex)
                    toUserIndex = lastUserIndex;

                // Saving of the rest of iterations
                _iterLimit -= toUserIndex - lastUserIndex;

                megaLeagueNextPossibleWinnerIndex = 0;
                // Going to the next finding stage
                isFirstStageOfMegaLeagueFinding = false;
            }

            // Getting of the current array of winners
            /*
             * If the storage array of Mega League winners (`megaLeagueWinners`) contains few users
             * (< `megaLeagueWinnerNumber`).
             */
            if (fromUserIndex < winnerNumber) {
                curWinners = new MegaLeagueWinner[](winnerNumber);
                // Copying of the current winners
                for (i = 0; i < fromUserIndex; ++i) {
                    curWinners[i].points = refMegaLeagueWinners[i].points;
                    curWinners[i].winner = refMegaLeagueWinners[i].winner;
                }
            } else {
                curWinners = refMegaLeagueWinners;
            }

            // Finding of the winners and descending sort of them
            uint256 k;
            for (i = fromUserIndex; i <= toUserIndex; ++i) {
                curUser = refDivisionWinners[i];
                curUserPoints = refDivisionWinnerStats[curUser].totalPoints;

                for (uint256 j = 0; j < curWinners.length; ++j) {
                    // Shift of the current winners and writing a new one
                    if (curUserPoints > curWinners[j].points) {
                        for (k = curWinners.length - 1; k > j; --k) {
                            curWinners[k].points = curWinners[k - 1].points;
                            curWinners[k].winner = curWinners[k - 1].winner;
                        }
                        curWinners[j].winner = curUser;
                        curWinners[j].points = curUserPoints;
                        break;
                    }
                }
            }

            // Writing of current winners to the storage
            // For the first time
            if (fromUserIndex == 0)
                for (i = 0; i < curWinners.length; ++i)
                    refMegaLeagueWinners.push(curWinners[i]);
            else
                for (i = 0; i < curWinners.length; ++i)
                    if (refMegaLeagueWinners[i].winner != curWinners[i].winner) {
                        refMegaLeagueWinners[i].points = curWinners[i].points;
                        refMegaLeagueWinners[i].winner = curWinners[i].winner;
                    }
        }

        /*
         * The second stage -- completing the finding of Mega League winners.
         *
         * Once `winnerNumber` Mega League winners are found, there is a need to find among all the division winners
         * those with points equal to the last one, and then decide which one of them will really be
         * the `winnerNumber`th winner.
         *
         * If there are less than `winnerNumber` Mega League winners, then there are less than `winnerNumber` division
         * winners, then going straight to the stage of update of the Mega League rewards
         * (`MegaLeagueStage.RewardsCalculation`).
         */
        if (!isFirstStageOfMegaLeagueFinding && _iterLimit != 0) {
            if (lastUserIndex >= winnerNumber) {
                // For the first time
                if (megaLeagueNextPossibleWinnerIndex == 0) {
                    uint256 size = refMegaLeagueWinners.length;
                    // Saving of the last possible winner's points
                    megaLeagueLastWinnerPoints = refMegaLeagueWinners[size - 1].points;

                    // Removal from the current winners those who have points equal to those of the last winner
                    for (i = size; i > 0; --i)
                        if (refMegaLeagueWinners[i - 1].points == megaLeagueLastWinnerPoints)
                            refMegaLeagueWinners.pop();
                        else
                            break;
                }

                fromUserIndex = megaLeagueNextPossibleWinnerIndex;
                toUserIndex = fromUserIndex + _iterLimit - 1;
                // Check that the first step is over and saving of the remaining number of iterations
                if (toUserIndex < lastUserIndex) {
                    megaLeagueNextPossibleWinnerIndex = toUserIndex + 1;
                } else {
                    if (toUserIndex != lastUserIndex)
                        toUserIndex = lastUserIndex;
                    megaLeagueNextPossibleWinnerIndex = 0;
                    // Going to the next stage
                    moveMegaLeagueStageTo(MegaLeagueStage.RewardsCalculation);
                }

                // Finding of the last winners
                MegaLeagueWinner[] storage refLastWinnersBuffer = megaLeagueLastWinnersBuffer[season];
                for (i = fromUserIndex; i <= toUserIndex; ++i) {
                    curUser = refDivisionWinners[i];
                    curUserPoints = refDivisionWinnerStats[curUser].totalPoints;

                    if (curUserPoints == megaLeagueLastWinnerPoints)
                        refLastWinnersBuffer.push(MegaLeagueWinner(curUserPoints, curUser));
                }

                // Selection sort in descending order to identify the real last winners
                if (refLastWinnersBuffer.length > 1) {
                    uint256 max;
                    MegaLeagueWinner memory temp;
                    for (i = 0; i < refLastWinnersBuffer.length - 1; ++i) {
                        max = i;
                        for (uint256 j = i + 1; j < refLastWinnersBuffer.length; ++j)
                            if (isFirstWinner(season, refLastWinnersBuffer[j].winner, refLastWinnersBuffer[max].winner))
                                max = j;

                        if (max != i) {
                            // Swap
                            temp.winner = refLastWinnersBuffer[i].winner;
                            temp.points = refLastWinnersBuffer[i].points;
                            refLastWinnersBuffer[i].winner = refLastWinnersBuffer[max].winner;
                            refLastWinnersBuffer[i].points = refLastWinnersBuffer[max].points;
                            refLastWinnersBuffer[max].winner = temp.winner;
                            refLastWinnersBuffer[max].points = temp.points;
                        }
                    }
                }

                // For the last time. Adding of the real last Mega League winners to the current Mega League winners
                if (megaLeagueNextPossibleWinnerIndex == 0) {
                    uint256 missingNumber = winnerNumber - refMegaLeagueWinners.length;
                    for (i = 0; i < missingNumber; ++i)
                        refMegaLeagueWinners.push(refLastWinnersBuffer[i]);
                }
            } else {
                // Removal of empty users
                uint256 removalNumber = winnerNumber - lastUserIndex;
                for (i = 0; i < removalNumber; ++i)
                    refMegaLeagueWinners.pop();

                // Go to the next stage
                moveMegaLeagueStageTo(MegaLeagueStage.RewardsCalculation);
            }
        }
    }

    function addMegaLeagueRewards(IERC20Upgradeable _token, uint256 _rewardAmount)
        external
        onlyRole(FINANCIAL_MANAGER_ROLE)
    {
        require(isRewardToken[_token], "Unknown token");
        require(_rewardAmount > 0, "Zero reward amount");

        rewardTokenAmounts[seasonId][_token] = _rewardAmount;
        require(_token.balanceOf(address(this)) >= _rewardAmount, "The MegaLeague did not receive rewards");
    }

    // prettier-ignore
    function calculateMegaLeagueRewards()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyMegaLeagueStage(MegaLeagueStage.RewardsCalculation)
    {
        // Calculation
        IERC20Upgradeable[] memory memRewardTokens = rewardTokens;
        uint256 season = seasonId;
        mapping(IERC20Upgradeable => mapping(address => uint256)) storage refMegaLeagueWinnerRewards =
            megaLeagueWinnerRewards[season];
        mapping(IERC20Upgradeable => uint256) storage refRewardTokenAmounts = rewardTokenAmounts[season];
        uint256 rewardAmount;

        MegaLeagueWinner[] storage refMegaLeagueWinners = megaLeagueWinners[season];
        // 35%, 20%, 10%, 5%, ..., 5%
        uint256[10] memory rewardPercentages = [uint256(35), 20, 10, 5, 5, 5, 5, 5, 5, 5];
        uint256 j;
        uint256 divider;
        uint256 userReward;
        for (uint256 i = 0; i < memRewardTokens.length; ++i) {
            mapping(address => uint256) storage refMegaLeagueWinnerTokenRewards =
                refMegaLeagueWinnerRewards[memRewardTokens[i]];
            rewardAmount = refRewardTokenAmounts[memRewardTokens[i]];

            /*
             * Here we calculate the divider. If we have all 10 Mega League winners, then the divider is 100
             * (just like 100%).
             * If we have less than 10 Mega League winners, then the divider is the sum of the first `winners.length`
             * percentages.
             */
            divider = 0;
            for (j = 0; j < refMegaLeagueWinners.length; ++j)
                divider += rewardPercentages[j];
            // Here we calculate the reward for each Mega League winner
            for (j = 0; j < refMegaLeagueWinners.length; ++j) {
                userReward = rewardAmount * rewardPercentages[j] / divider;
                refMegaLeagueWinnerTokenRewards[refMegaLeagueWinners[j].winner] += userReward;
                emit UserMegaLeagueRewardsUpdated(
                    refMegaLeagueWinners[j].winner,
                    address(memRewardTokens[i]),
                    rewardAmount,
                    userReward
                );
            }
        }

        moveMegaLeagueStageTo(MegaLeagueStage.RewardsWithdrawal);
    }

    /**
     * @notice Withdraw rewards for the MegaLeague winner.
     * @dev Msg.sender must be a winner. Where will be separate transfer for each reward token.
     * @param _userIndex Index of the winner in the MegaLeague winners array.
     */
    function withdrawRewards(uint256 _userIndex) external {
        uint256 season = seasonId;
        validateMegaLeagueWinner(season, _userIndex, _msgSender());

        IERC20Upgradeable token;
        uint256 userReward;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            token = rewardTokens[i];
            userReward = megaLeagueWinnerRewards[season][token][_msgSender()];
            require(token.balanceOf(address(this)) >= userReward, "The MegaLeague did not receive rewards");
            token.transfer(msg.sender, userReward);
            emit UserMegaLeagueRewardsWithdrawn(_userIndex, _msgSender(), address(token), userReward);
        }
    }

    /**
     * @notice Add reward token to the rewardTokens array.
     * @dev Only the default admin can add a reward token.
     * @param _token Token to add.
     */
    function addRewardToken(IERC20Upgradeable _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isRewardToken[_token], "The token is already in the list");
        rewardTokens.push(_token);
        isRewardToken[_token] = true;
        emit RewardTokenAdded(_token);
    }

    function getMegaLeagueWinners(uint256 _season) external view returns (MegaLeagueWinner[] memory) {
        return megaLeagueWinners[_season];
    }

    // _______________ Private functions _______________

    /*
     * @dev Returns the result of a comparison of users: a win for the first, a win for the second, a tie.
     *
     * @param _season Season ID.
     * @param _firstUser The first user in the comparison.
     * @param _secondUser The second user in the comparison.
     * @return   The result of the comparison of users.
     */
    // prettier-ignore
    function isFirstWinner(
        uint256 _season,
        address _firstUser,
        address _secondUser
    ) private view returns (bool) {
        require(_firstUser != _secondUser, "Comparing of the user to himself");
        require(isDivisionWinner(_season, _firstUser) && isDivisionWinner(_season, _secondUser), "Unknown user");

        mapping(address => DivisionWinnerStats) storage refDivisionWinnerStats = divisionWinnerStats[_season];
        DivisionWinnerStats storage firstDivisionWinnerStats = refDivisionWinnerStats[_firstUser];
        DivisionWinnerStats storage secondDivisionWinnerStats = refDivisionWinnerStats[_secondUser];

        if (firstDivisionWinnerStats.totalPoints > secondDivisionWinnerStats.totalPoints)
            return true;
        if (firstDivisionWinnerStats.totalPoints < secondDivisionWinnerStats.totalPoints)
            return false;

        if (firstDivisionWinnerStats.wins > secondDivisionWinnerStats.wins)
            return true;
        if (firstDivisionWinnerStats.wins < secondDivisionWinnerStats.wins)
            return false;

        if (firstDivisionWinnerStats.ties > secondDivisionWinnerStats.ties)
            return true;
        if (firstDivisionWinnerStats.ties < secondDivisionWinnerStats.ties)
            return false;

        if ((randNumber / 2 + uint256(blockhash(block.number)) / 2) % 2 == 0)
            return true;
        else
            return false;
    }

    /**
     * @dev Reverts if specified user is not a winner.
     * @param _season Season ID.
     * @param _userIndex Winner index in the megaLeagueWinners array.
     * @param _user User address to check.
     */
    function validateMegaLeagueWinner(
        uint256 _season,
        uint256 _userIndex,
        address _user
    ) public view {
        MegaLeagueWinner[] storage refMegaLeagueWinners = megaLeagueWinners[_season];
        require(refMegaLeagueWinners.length > _userIndex, "_userIndex out of range");
        require(refMegaLeagueWinners[_userIndex].winner == _user, "The user is not a winner");
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private gap;
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

pragma solidity 0.8.6;

import "../mega-league-parts/MegaLeagueProgress.sol";
import "../mega-league-parts/DivisionWinnerStatsStruct.sol";

abstract contract DivisionWinnerReader is MegaLeagueProgress {
    // _______________ Storage _______________

    /*
     * Next division winner index to process. It is basically an division winner pointer to continue the different
     * processes from where it stopped in the last transaction.
     */
    uint256 public nextProcessedDivisionWinner;

    // Season ID => array of division champions
    mapping(uint256 => address[]) public divisionWinners;

    /*
     * Stores a division winner index in the array of division winners.
     * Season ID => (division winner => [1 + index in the `divisionWinners` array]).
     * NOTE. Plus 1, because the zero value is used to check that a division winner exists.
     */
    mapping(uint256 => mapping(address => uint256)) public divisionWinnersIncreasedIndex;

    // Season ID => (division winner => DivisionWinnerStats)
    mapping(uint256 => mapping(address => DivisionWinnerStats)) public divisionWinnerStats;

    // _______________ Initializer _______________

    function init_DivisionWinnerReader_unchained() internal onlyInitializing {}

    // _______________ External functions _______________

    /**
     * @dev Reads the array of division winner and their season statistics from the FantasyLeague contract after the
     * playoff end and saves it to this contract.
     *
     * @param _numberOfDivisions A number of divisions to process. It allows you to split the function call into
     * multiple transactions to avoid reaching the gas cost limit. Each time the function is called, this number can be
     * anything greater than zero. When the process of reading is completed, the MegaLeague moves on to the next stage
     * (`MegaLeagueStage.MegaLeague`).
     */
    // prettier-ignore
    function readDivisionWinner(uint256 _numberOfDivisions)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyMegaLeagueStage(MegaLeagueStage.DivisionWinnersReading)
    {
        require(_numberOfDivisions != 0, "Number of divisions should be greater than zero");

        uint256 fromDivisionWinner = nextProcessedDivisionWinner;
        // The last division winner that will be calculated in this batch
        uint256 toDivisionWinner = nextProcessedDivisionWinner + _numberOfDivisions - 1;
        // Check of overflow
        uint256 lastDivisionWinner = fantasyLeague.getNumberOfDivisions() - 1;
        if (toDivisionWinner < lastDivisionWinner) {
            nextProcessedDivisionWinner = toDivisionWinner + 1;
        } else {
            if (toDivisionWinner != lastDivisionWinner) {
                toDivisionWinner = lastDivisionWinner;
            }
            nextProcessedDivisionWinner = 0;
            moveMegaLeagueStageTo(MegaLeagueStage.MegaLeague);
        }

        // Addresses of division winners
        // Reading of division winners
        uint256 season = seasonId;
        address[] memory dWinners = fantasyLeague.getSomeDivisionWinners(season, fromDivisionWinner, toDivisionWinner);

        // Saving of division winners to the storage
        address dWinner;
        address[] storage refDivisionWinners = divisionWinners[season];
        mapping(address => uint256) storage refDivisionWinnersIncreasedIndex = divisionWinnersIncreasedIndex[season];
        for (uint256 i = 0; i < dWinners.length; ++i) {
            dWinner = dWinners[i];
            refDivisionWinners.push(dWinner);
            refDivisionWinnersIncreasedIndex[dWinner] = fromDivisionWinner + i;
        }

        // Season statistics of division winners
        // Reading of statistics
        DivisionWinnerStats[] memory dWinnersStats =
            fantasyLeague.getSomeDivisionWinnersStats(season, fromDivisionWinner, toDivisionWinner);

        // Saving of statistics to the storage
        mapping(address => DivisionWinnerStats) storage refDivisionWinnerStats = divisionWinnerStats[season];
        for (uint256 i = 0; i < dWinnersStats.length; ++i)
            refDivisionWinnerStats[dWinners[i]] = dWinnersStats[i];
    }

    // _______________ Public functions _______________

    function isDivisionWinner(uint256 _season, address _user) public view returns (bool) {
        return divisionWinnersIncreasedIndex[_season][_user] != 0;
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

// The result of a competition between two users for the head to head competitions and playoff
enum CompetitionResult {
    FirstUserWon,
    SecondUserWon,
    Tie
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/INomoRNG.sol";

/**
 * @title Random generator -- contract, which is common part of several contracts in `contracts/gen2/*`, provides the
 * random numbers.
 *
 * @dev This contract includes the following functionality:
 *  - Sets the `NomoRNG` random generator contract which is connected with the Chainlink VRFv2.
 *  - Stores and updates the random number.
 */
abstract contract RandomGenerator is Initializable {
    // _______________ Storage _______________

    // The random number generator interface
    INomoRNG public generator;

    // The current random number
    uint256 public randNumber;

    // _______________ Events _______________

    /**
     * @dev Emitted when the interface address of the `NomoRNG` random generator contract (`generator`) is changed to an
     * address `_generator`.
     *
     * @param _generator The address which is set by the current interface address of the random generator contract.
     */
    event RandomGeneratorSet(address _generator);

    /**
     * @dev Emitted when the random number (`randNumber`) has been updated to a number (`_randomNumber`).
     *
     * @param _randomNumber The number which is set by the current random number (`randNumber`).
     */
    event RandNumberUpdated(uint256 _randomNumber);

    // _______________ Initializer _______________

    /*
     * Sets the address of the `NomoRNG` random number generator to a `_generator`.
     *
     * NOTE. The function init_{ContractName}_unchained found in every upgradeble contract is the initializer function
     * without the calls to parent initializers, and can be used to avoid the double initialization problem.
     */
    function init_RandomGenerator_unchained(address _generator) internal onlyInitializing {
        generator = INomoRNG(_generator);
        emit RandomGeneratorSet(_generator);
    }

    // _______________ Internal functions _______________

    /*
     * Sets the random number generator contract (`generator`) as `_generator`. (`NomoRNG` is the random generator
     * contract).
     *
     * Requirements:
     *  - A random generator address (`_generator`) should not equal to the zero address.
     *
     * `_generator` -- an address of the random generator that updates the random number (`randNumber`).
     */
    function setRandomGenerator(address _generator) internal {
        require(_generator != address(0), "Zero address");

        generator = INomoRNG(_generator);
        emit RandomGeneratorSet(_generator);
    }

    /*
     * Updates the random number (`randNumber`) via Chainlink VRFv2.
     *
     * Requirements:
     *  - The random generator address (`generator`) should not equal to the zero address.
     *
     * NOTE. Firstly, need to generate the random number on the `NomoRNG` contract.
     */
    function updateRandomNumber() internal {
        require(address(generator) != address(0), "Zero address");

        // Getting of the random number (after that the generator forgets this number)
        uint256 randNum = generator.requestRandomNumber();
        randNumber = randNum;

        emit RandNumberUpdated(randNum);
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new variables without shifting
     * down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps.
     */
    uint256[48] private gap;
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

import "../common-parts/SeasonSync.sol";

abstract contract MegaLeagueProgress is SeasonSync {
    // _______________ Enums _______________

    enum MegaLeagueStage {
        WaitingCompletedPlayoff,
        DivisionWinnersReading,
        MegaLeague,
        RewardsCalculation,
        RewardsWithdrawal
    }

    // _______________ Storage _______________

    MegaLeagueStage private megaLeagueStage;

    // _______________ Events _______________

    event MegaLeagueStageMovedTo(MegaLeagueStage indexed _s);

    // _______________ Modifiers _______________

    modifier onlyMegaLeagueStage(MegaLeagueStage _s) {
        require(megaLeagueStage == _s, "This is not available at the current stage of the Mega League");
        _;
    }

    // _______________ Initializer _______________

    function init_MegaLeagueProgress_unchained() internal onlyInitializing {
        megaLeagueStage = MegaLeagueStage.WaitingCompletedPlayoff;
        emit MegaLeagueStageMovedTo(MegaLeagueStage.WaitingCompletedPlayoff);
    }

    // _______________ Public functions _______________

    function getMegaLeagueStage() public view returns (MegaLeagueStage) {
        return megaLeagueStage;
    }

    // _______________ External functions _______________

    function startMegaLeague() external onlyFantasyLeague {
        moveMegaLeagueStageTo(MegaLeagueStage.DivisionWinnersReading);
    }

    function finishMegaLeague() external onlyFantasyLeague {
        moveMegaLeagueStageTo(MegaLeagueStage.WaitingCompletedPlayoff);
    }

    // _______________ Internal functions _______________

    function moveMegaLeagueStageTo(MegaLeagueStage _s) internal {
        MegaLeagueStage s = megaLeagueStage;
        if (s != MegaLeagueStage.RewardsWithdrawal) {
            require(s < _s, "The Mega League stage should only be moved forward");
        } else {
            require(
                _s == MegaLeagueStage.WaitingCompletedPlayoff,
                "Stage should only be moved to waiting completed playoff"
            );
        }

        megaLeagueStage = _s;
        emit MegaLeagueStageMovedTo(_s);
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

struct DivisionWinnerStats {
    uint256 totalPoints;
    uint32 wins;
    uint32 ties;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../interfaces/IFantasyLeague.sol";

/**
 * @title
 */
abstract contract SeasonSync is AccessControlUpgradeable {
    // _______________ Storage _______________

    IFantasyLeague public fantasyLeague;

    uint256 public seasonId;

    // _______________ Events _______________

    event FantasyLeagueSet(address _fantasyLeague);

    event SeasonIdUpdated(uint256 indexed _seasonId);

    // _______________ Modifiers _______________

    modifier onlyFantasyLeague() {
        require(_msgSender() == address(fantasyLeague), "Function should only be called by the FantasyLeague contract");
        _;
    }

    // _______________ Initializer _______________

    function init_SeasonSync_unchained(address _admin) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    // _______________ External functions _______________

    function setFantasyLeague(address _fantasyLeague) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fantasyLeague = IFantasyLeague(_fantasyLeague);
        emit FantasyLeagueSet(_fantasyLeague);
    }

    function updateSeasonId() external {
        require(
            _msgSender() == address(fantasyLeague) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Should be called by the FantasyLeague contract or administrator"
        );

        uint256 season = fantasyLeague.getSeasonId();
        seasonId = season;
        emit SeasonIdUpdated(season);
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

import "../abstracts/mega-league-parts/DivisionWinnerStatsStruct.sol";

interface IFantasyLeague {
    function getSeasonId() external view returns (uint256);

    function addUser(address _user) external;

    function getNumberOfDivisions() external view returns (uint256);

    function getCurrentWeek() external view returns (uint256);

    /**
     * @notice How many users in the game registered
     *
     * @return Amount of the users
     */
    function getNumberOfUsers() external view returns (uint256);

    /**
     * @dev How many users in one division.
     * @return   Number.
     */
    function DIVISION_SIZE() external view returns (uint256);

    function getSomeDivisionWinners(
        uint256 _season,
        uint256 _from,
        uint256 _to
    ) external view returns (address[] memory divisionWinners);

    function getSomeDivisionWinnersStats(
        uint256 _season,
        uint256 _from,
        uint256 _to
    ) external view returns (DivisionWinnerStats[] memory divisionWinnersStats);
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

pragma solidity 0.8.6;

interface INomoRNG {
    function requestRandomNumber() external returns (uint256 _random);
}