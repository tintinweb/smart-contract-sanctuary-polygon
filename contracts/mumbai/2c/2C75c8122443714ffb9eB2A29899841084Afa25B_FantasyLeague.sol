// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./abstracts/fantasy-league-parts/Playoff.sol";

import "./interfaces/IMegaLeague.sol";
import "./interfaces/IGen2PlayerToken.sol";

/**
 * @title LeagueDAO Fantasy League -- the main contract on the protocol, which is responsible for the main games
 * process.
 *
 * @notice Game process. There are three stages of competitions for users in the Fantasy League game:
 *  1. Weekly competitions lasting 15 weeks. All users take part in them. Each week the user only competes against one
 *     other within their division with the help of their team of staked `Gen2PlayerToken` players. That is, users from
 *     different divisions do not interact.
 *     Users receive special tokens for each week. Winners get more, losers get less. With these tokens, users can buy
 *     new `Gen2PlayerToken` players from the marketplace for replacements in their team. The marketplace is developed
 *     by a different team in a different repository.
 *  2. Then there are the playoff competitions. In 16th week the top 4 users in each division are determined by sorting
 *     them according to their stats for the weekly competitions. In the same week these 4 users compete, each against
 *     one other. In the end there are 2 users left who win. In the 17th week the 2 remaining users in each division
 *     compete and the division winner is determined. Each division winner will receive an equal reward worth several
 *     entry passes (`LeaguePassNFT`) from the reward pool.
 *  3. All division winners participate in the final stage, the Mega League. The number of division winners is equal to
 *     the number of divisions, i.e. one for each division. Immediately after the playoff in the same 17th week, they
 *     will be sorted according to their season stats. The first 10 of them will become the winners of the Mega League.
 *     The reward pool (what is left after the division winners have been rewarded) is distributed between them
 *     according to a set rule.
 *
 * For details and the rest of the functionality, read the abstract contracts comments.
 *
 * Most functions in abstract contracts are placed according to the order in which they are called.
 *
 * The `FantasyLeague` is best read from the bottom, i.e. in the following order: `GameProgress`, `UsersNDivisions`,
 * `RandomGenerator`, `H2HCompetition`, `Scheduler`, `Playoff`, `FantasyLeague`. After reading these contracts or while
 *  reading `H2HCompetition` it is worth getting to know `TeamManager`.
 *
 * @dev The following functionality is implemented directly in this part of the file:
 *  - Initialization of the `FantasyLeague` contract.
 *  - Setting of the `MegaLeague` contract to go to the final stage, the Mega League, at the end of season, as well as
 *    to update its season ID at the setting of it and closing of a season.
 *  - Setting of the `Gen2PlayerToken` contract to update its season ID at the setting of it and closing of a season.
 *  - The function that unifies the game continuation functionality. Calling it back end performs the going to the next
 *    week of the weekly competitions, the going to the playoff and to the Mega League, as well as the closing of the
 *    season and the going to the next one.
 */
contract FantasyLeague is Playoff {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Storage _______________

    /*
     * The contract that is responsible for the final game stage, the Mega League.
     * NOTE. It is stored here only to update its season ID and move on to the final stage.
     */
    IMegaLeague public megaLeague;

    /*
     * The contract that is responsible for players which users use to form a team.
     * NOTE. It is stored here only to update its season ID.
     */
    IGen2PlayerToken public gen2PlayerToken;

    // _______________ Events _______________

    /**
     * @dev Emitted when the interface address of the Mega League contract (`megaLeague`) is changed to an address
     * `_megaLeague`.
     *
     * @param _megaLeague The address which is set by the current interface address of the Mega League contract.
     */
    event MegaLeagueSet(address _megaLeague);

    /**
     * @dev Emitted when the interface address of the Gen 2 Player Token contract (`gen2PlayerToken`) is changed to an
     * address `_gen2PlayerToken`.
     *
     * @param _gen2PlayerToken The address which is set by the current interface address of the Gen 2 Player Token
     * contract.
     */
    event Gen2PlayerTokenSet(address _gen2PlayerToken);

    /**
     * @dev Emitted when a new week (`_week`) of the weekly H2H competitions is started.
     *
     * @param _week A new week of the weekly H2H competitions.
     */
    event H2HCompetitionWeekStarted(uint256 _week);

    /**
     * @dev Emitted when a new week (`_week`) of the playoff competitions is started.
     *
     * @param _week A new week of the playoff competitions.
     */
    event PlayoffCompetitionWeekStarted(uint256 _week);

    // _______________ Initializer _______________

    /**
     * @dev Initializes this contract by setting the following:
     * - the game stage as `GameStage.UserAdding`;
     * - the deployer as the initial administrator that has the `DEFAULT_ADMIN_ROLE` role.
     * As well as the following parameters:
     * @param _generator An address of the random number generator contract (`NomoRNG`).
     * @param _scheduler An address of the scheduler contract (`Scheduler`).
     * @param _multisig An address that is granted the multisig role (`MILTISIG_ROLE`).
     * @param _rewardTokens An addresses of the reward tokens.
     *
     * @notice It is used as the constructor for upgradeable contracts.
     */
    function initialize(
        address _generator,
        address _scheduler,
        address _multisig,
        IERC20Upgradeable[] calldata _rewardTokens
    ) external initializer {
        init_GameProgress_unchained();
        init_UsersNDivisions_unchained(_generator);
        init_H2HCompetition_unchained(_scheduler, _multisig, _rewardTokens);
        init_Playoff_unchained();
    }

    // _______________ External functions _______________

    /**
     * @dev Sets the Mega League contract (`megaLeague`) as `_megaLeague`, syncs the current season ID of the passed
     * Mega League with that in this contract.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - The Mega League address (`_megaLeague`) should not equal to the zero address.
     *
     * @param _megaLeague An address of the Mega League contract that is responsible for the final game stage.
     */
    function setMegaLeague(address _megaLeague) external onlyRole(DEFAULT_ADMIN_ROLE) nonzeroAddress(_megaLeague) {
        megaLeague = IMegaLeague(_megaLeague);
        emit MegaLeagueSet(_megaLeague);

        megaLeague.updateSeasonId();
    }

    /**
     * @dev Sets the Gen 2 Player Token contract (`gen2PlayerToken`) as `_gen2PlayerToken`, syncs the current season ID
     * of the Gen 2 Player Token with that in this contract.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - An Gen 2 Player Token address (`_gen2PlayerToken`) should not equal to the zero address.
     *
     * @param _gen2PlayerToken An address of the Gen 2 Player Token contract is responsible for players which users use
     * to form a team.
     */
    function setGen2PlayerToken(address _gen2PlayerToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroAddress(_gen2PlayerToken)
    {
        gen2PlayerToken = IGen2PlayerToken(_gen2PlayerToken);
        emit Gen2PlayerTokenSet(_gen2PlayerToken);

        gen2PlayerToken.updateSeasonId();
    }

    /**
     * @dev Opens each week of weekly games for the first 15 weeks inclusive. Opens the first week of the playoff
     * competitions in the 16th week and the second (last) week of the playoff competitions in the 17th week. At the
     * end of the 17th week after the playoff, move the Fantasy League to the final stage, the Mega League. After
     * that, closes the current season and moves on to the next ones.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - The game stage should be the stage of waiting a next game (`GameStage.WaitingNextGame`).
     *
     * @notice This function unifies the game continuation functionality. Calling it back end performs the going to the
     * next week of the weekly competitions, the going to the playoff and to the Mega League, as well as the closing of
     * the season and the going to the next one.
     */
    function nextGame() external onlyRole(DEFAULT_ADMIN_ROLE) onlyGameStage(GameStage.WaitingNextGame) {
        if (weekTracker.current() < H2H_COMPETITION_WEEK_NUM) {
            moveGameStageTo(GameStage.H2HCompetitions);
            weekTracker.increment();
            emit H2HCompetitionWeekStarted(weekTracker.current());

            // Send of the current timestamp for team score calculation
            teamManager.setCurrentGameStartTime(block.timestamp);
        } else if (weekTracker.current() < H2H_COMPETITION_WEEK_NUM + PLAYOFF_COMPETITION_WEEK_NUM) {
            moveGameStageTo(GameStage.PlayoffCompetitorsSelection);
            weekTracker.increment();
            emit PlayoffCompetitionWeekStarted(weekTracker.current());

            // Send of the current timestamp for team score calculation
            teamManager.setCurrentGameStartTime(block.timestamp);
        } else if (weekTracker.current() == H2H_COMPETITION_WEEK_NUM + PLAYOFF_COMPETITION_WEEK_NUM) {
            megaLeague.startMegaLeague();
        } else {
            weekTracker.reset();
            delete shuffledUserNum;
            moveGameStageTo(GameStage.UserAdding);
            closeSeason();

            megaLeague.finishMegaLeague();

            leaguePassNFT.updateSeasonId();
            teamManager.updateSeasonId();
            megaLeague.updateSeasonId();
            gen2PlayerToken.updateSeasonId();
        }
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

pragma solidity 0.8.6;

// Here these contracts is connected to the Fantasy League contract (`FantasyLeague.sol`)
import "./H2HCompetition.sol";
import "../../interfaces/INomoRNG.sol";
import "../../interfaces/IFinancialManager.sol";
import "../mega-league-parts/DivisionWinnerStatsStruct.sol";

// List of errors for this contract
// Reverts when adding of sorted divisions with an incorrect total length to the array for the playoff
error InputLengthMismatch();
// Reverts when the financial manager has the zero address
error IncorrectFinancialManager();
// Reverts when calculation of the playoff rewards for zero division winners
error DivisionWinnersNumberIsZero();
/*
 * Reverts when getting a slice of division winners' addresses or stats with the "from" index that is greater than the
 * "to" index.
 */
error StartIndexIsGreaterThanEndIndex();
/*
 * Reverts when getting a slice of division winners' addresses or stats with the "to" index that is greater than the
 * number of division winners.
 */
error EndIndexIsOutOfDivisionWinnersNumber();
// Reverts when adding of a sorted division with an incorrect length to the array for the playoff
error ArraysLengthMismatch();
// Reverts when adding of a sorted division with other addresses to the array for the playoff
error IncorrectAddressDivisionId();
// Reverts when adding of a sorted division with incorrect sort to the array for the playoff
error IncorrectSorting();
// Reverts when comparing of the user to himself
error UserSelfcomparing();
// Reverts when check of a sort of a division with an incorrect length
error ArrayLengthIsNotDivisionSize();

/**
 * @title Playoff -- the contract that responsible for playoff competitions and rewards for it (see the description of
 * the `FantasyLeague` contract for details).
 *
 * @dev This contract includes the following functionality:
 *  - Has the back end functions for adding sorted divisions to save top 4 users in each division for playoff
 *    competitions.
 *  - Processes playoff competitions to determine division winners, as well as stores the season and weekly user
 *    statistics (team points and number of wins and losses).
 *  - Sets the financial manager contract (`financialManager`) that transfers rewards for the division winners to the
 *    `FantasyLeague` contract and returns the reward token and value for an update of rewards.
 *  - Updates the rewards for division winners, as well as stores these rewards and accumulates them.
 *  - Returns division winners and their stats (it is used for the Mega League).
 *  - Compares users by seasonal statistics (firstly, it is used for playoff competitions).
 */
abstract contract Playoff is H2HCompetition {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Constants _______________

    // Number of competitors from one division who compete in the playoffs
    uint8 public constant PLAYOFF_COMPETITOR_NUM = 4;

    // How many weeks of playoff competitions
    uint8 public constant PLAYOFF_COMPETITION_WEEK_NUM = 2;

    // _______________ Storage _______________

    IFinancialManager public financialManager;

    /*
     * The array of users participating in the playoff competitions.
     *
     * NOTE. The principle of filling in:
     *  1. The top 4 users from each division will be saved here using the function of adding of sorted playoff
     *     divisions (`addSortedPlayoffDivisions()`). The divisions are written in order (same as in the `users` array).
     *  2. During the playoff competitions (`competePlayoffs()`) in the 16th week the first and third places in the
     *     array will be the winners of the first playoff division, the fifth and seventh -- the winners of the second
     *     playoff division and so on.
     *
     * Season ID => playoff competitors array.
     */
    mapping(uint256 => address[]) public playoffCompetitors;

    /*
     * Stores the playoff division winners (after the playoff competitions (`competePlayoffs()`) in the 17th week).
     *
     * NOTE. `divisionsWinners`.length == `getNumberOfDivisions()`.
     *
     * Season ID => array of division winners.
     */
    mapping(uint256 => address[]) public divisionsWinners;

    // _______________ Events _______________

    /**
     * @dev Emitted when the interface address of the financial manager contract (`financialManager`) is changed to an
     * address `_financialManager`.
     *
     * @param _financialManager The address which is set by the current interface address of the financial manager
     * contract.
     */
    event FinancialManagerSet(address _financialManager);

    /**
     * @dev Emitted when top 4 users is selected from a division (`_divisionId`) and added to the playoff competitors
     * array (`playoffCompetitors`) in a season (`_seasonId`).
     *
     * @param _seasonId The season in which the users from the division is selected.
     * @param _divisionId ID of the division from which the users are selected..
     */
    event CompetitorsSelectedFromDivision(uint256 indexed _seasonId, uint256 indexed _divisionId);

    /**
     * @dev Emitted when rewards is calculated for a division winner (`_winner`). `_accumulatedRewards` is his total
     * reward amount in the playoff reward token (stored in the `financialManager` contract).
     *
     * @param _winner The division winner for whom reward amount is calculated.
     * @param _accumulatedRewards The total reward amount that the user (`_winner`) can withdraw at the moment.
     */
    event DivisionWinnerRewardsCalculated(address indexed _winner, uint256 _accumulatedRewards);

    // _______________ Initializer _______________

    /*
     * NOTE. The function init_{ContractName}_unchained found in every upgradeble contract is the initializer function
     * without the calls to parent initializers, and can be used to avoid the double initialization problem.
     */
    function init_Playoff_unchained() internal onlyInitializing {}

    // _______________ Extrenal functions  _______________

    /**
     * @dev Checks that the divisions is correctly sorted and saves the top `PLAYOFF_COMPETITOR_NUM` users for playoff
     * competitions.
     *
     * @param _sortedDivisions An array of divisions, each sorted in descending order. Sorting is done based on user's
     * seasonal statistics (`UserSeasonStats` struct). The length of this array should be a multiple of the division
     * size.
     *
     * @notice This function is made to avoid sorting arrays in the blockchain. The back end sorts them independently
     * and sends them sorted, while the blockchain only performs a sorting check and selects the top 4 users from the
     * division.
     */
    // prettier-ignore
    function addSortedPlayoffDivisions(address[] calldata _sortedDivisions) external {
        if (!(_sortedDivisions.length >= DIVISION_SIZE && _sortedDivisions.length % DIVISION_SIZE == 0))
            revert InputLengthMismatch();

        for (uint256 i = 0; i <= _sortedDivisions.length; i += DIVISION_SIZE)
            addSortedPlayoffDivision(_sortedDivisions[i : i + DIVISION_SIZE]);
    }

    /**
     * @notice It is for playoff competitions (see the description of the `FantasyLeague` contract for details).
     *
     * @dev Processes competitions of the 16th and 17th weeks between users for some divisions (`_numberOfDivisions`).
     *
     * This process includes the following:
     *  - Check that the process is over, i.e. all divisions have been processed this week (see the description of the
     *    `_numberOfDivisions` parameter for details).
     *  - Calculation of the user's points (of his team of `Gen2PlayerToken` players) via the team manager contract
     *    (`teamManager`).
     *  - Competitions between users within divisions, where the winners are determined by the user's points and season
     *    stats. The competitions are on a schedule, obtained vie the scheduler contract (`Scheduler`).
     *  - Writing of user's statistics in the storage.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - The game stage should be the playoff competitions' stage (`GameStage.PlayoffCompetitions`).
     *  - The number of divisions should not be equal to zero.
     *  - The scheduler and team manager contracts (`scheduler`, `teamManager`) should be set.
     *
     * @notice There are determined the 2 playoff candidates for each division in the 16th week and the division winner
     * in the 17th week.
     *
     * @param _numberOfDivisions A number of divisions to process. It allows you to split the function call into
     * multiple transactions to avoid reaching the gas cost limit. Each time the function is called, this number can be
     * anything greater than zero. When the process of playoff competing is completed, the `FantasyLeague` moves on to
     * the next stage -- `GameStage.PlayoffRewards`.
     *
     * @notice Warning. This algorithm assumes that the playoffs take place in weeks 16 and 17, with 4 users competing
     * in week 16 and 2 winners in week 17. The algorithm is not designed for other values.
     */
    function competePlayoffs(uint256 _numberOfDivisions)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyGameStage(GameStage.PlayoffCompetitions)
    {
        if (_numberOfDivisions == 0) revert DivisionNumberIsZero();

        // The first division that will be calculated in this batch
        uint256 fromDivision = nextProcessedDivisionId;
        // The last division that will be calculated in this batch
        uint256 toDivision = nextProcessedDivisionId + _numberOfDivisions - 1;
        /*
         * Check that the process is over, i.e. all divisions have been processed this week. And corrected a number of
         * divisions to process if an overflow.
         */
        uint256 lastDivision = getNumberOfDivisions() - 1;
        if (toDivision < lastDivision) {
            nextProcessedDivisionId = toDivision + 1;
        } else {
            if (toDivision != lastDivision) {
                toDivision = lastDivision;
            }
            nextProcessedDivisionId = 0;

            // Movement to the next stage when this week's playoff competitions are over
            if (weekTracker.current() == 16) {
                moveGameStageTo(GameStage.WaitingNextGame);
            } else {
                // week == 17
                moveGameStageTo(GameStage.PlayoffRewards);
            }
        }

        // Below are variables for a loop of playoff competitions
        // Array of playoff competitors of the specified season
        address[] storage refPlayoffCompetitors = playoffCompetitors[seasonId.current()];

        // Number of competitors this week
        uint256 competitorNumber;
        /*
         * Schedule for playoff competitions for the sixteenth week of the Fantasy League.
         * The elements of this array are read in pairs (indexes zero and one correspond to the first pair, and so on).
         */
        uint8[PLAYOFF_COMPETITOR_NUM] memory playoffSchedule;

        // Warning. The algorithm is not designed for other values.
        if (weekTracker.current() == 16) {
            competitorNumber = PLAYOFF_COMPETITOR_NUM;
        } else {
            // week == 17
            competitorNumber = PLAYOFF_COMPETITOR_NUM / 2;
        }
        playoffSchedule = scheduler.getPlayoffWeekSchedule(weekTracker.current());

        // Number by which the offset occurs to determine a user index in the array of all playodd competitors
        uint256 offsetInArray;
        // Index of the first user (competitor) in a pair in the current division
        uint256 competitor;

        // A pair of users (competitors)
        address firstUser;
        address secondUser;
        // Total score of users (competitors)
        uint256 firstUserScore;
        uint256 secondUserScore;

        // Total score (points) of competitors in all divisions that is calculated in this batch
        uint256 totalPoints;

        // Start from the first division that will be calculated in this batch
        // prettier-ignore
        for (uint256 division = fromDivision; division <= toDivision; ++division) {
            /*
             * In 16th week, there are 4 users in each division, each competing against one other. In 17th week there
             * are 2 users remaining in each division, who compete. This determines the winner of the division.
             */
            offsetInArray = division * PLAYOFF_COMPETITOR_NUM;
            for (competitor = 0; competitor < competitorNumber; competitor += 2) {
                // Get addresses of the first and second users (competitors)
                firstUser = refPlayoffCompetitors[playoffSchedule[competitor] + offsetInArray];
                secondUser = refPlayoffCompetitors[playoffSchedule[competitor + 1] + offsetInArray];

                // Competing
                (firstUserScore, secondUserScore) = teamManager.calcTeamScoreForTwoUsers(firstUser, secondUser);
                CompetitionResult result = getH2HCompetitionResult(firstUserScore, secondUserScore);
                updateUserStats(firstUser, secondUser, result);
                emit H2HCompetitionResult(firstUser, secondUser, result, weekTracker.current());

                /*
                 * For the playoff. Determines winners if there is a tie. And rewrites the winner before the loser in
                 * a division in the `refPlayoffCompetitors` array.
                 */
                if (weekTracker.current() == 16)
                {
                    /*
                     * ! Hardcoded for playoffSchedule == [0, 3,  1, 2].
                     * NOTE. If the second won or played a tie, but randomly won, then swap the first with the second
                     * so that the winner is on top (hardcoded for playoffSchedule == [0, 2,  0, 0] in week 17).
                     */
                    if (result == CompetitionResult.SecondUserWon) {
                        refPlayoffCompetitors[playoffSchedule[competitor] + offsetInArray] = secondUser;
                        refPlayoffCompetitors[playoffSchedule[competitor + 1] + offsetInArray] = firstUser;
                    }

                    if (result == CompetitionResult.Tie) {
                        // Searching for a winner on previous merits
                        result = compareUsers(seasonId.current(), firstUser, secondUser);
                        if (
                            result == CompetitionResult.SecondUserWon ||
                                (
                                    result == CompetitionResult.Tie &&
                                    (randNumber / 2 + uint256(blockhash(block.number)) / 2) % 2 == 1
                                )
                        ) {
                            refPlayoffCompetitors[playoffSchedule[competitor] + offsetInArray] = secondUser;
                            refPlayoffCompetitors[playoffSchedule[competitor + 1] + offsetInArray] = firstUser;
                        }
                    }
                } else {
                    // week == 17
                    if (result == CompetitionResult.FirstUserWon)
                        divisionsWinners[seasonId.current()].push(firstUser);
                    else if (result == CompetitionResult.SecondUserWon)
                        divisionsWinners[seasonId.current()].push(secondUser);
                    else {
                        // result == CompetitionResult.Tie
                        // Searching for a winner on previous merits
                        result = compareUsers(seasonId.current(), firstUser, secondUser);
                        if (
                            result == CompetitionResult.FirstUserWon ||
                                (
                                    result == CompetitionResult.Tie &&
                                    (randNumber / 2 + uint256(blockhash(block.number)) / 2) % 2 == 0
                                )
                        ) {
                            divisionsWinners[seasonId.current()].push(firstUser);
                        } else {
                            divisionsWinners[seasonId.current()].push(secondUser);
                        }
                    }
                }

                // Saving of user week score
                userWeeklyStats[firstUser][seasonId.current()][weekTracker.current()].points = firstUserScore;
                userWeeklyStats[secondUser][seasonId.current()][weekTracker.current()].points = secondUserScore;

                // Saving of user total points (for the Mega League stage in the future)
                userSeasonStats[firstUser][seasonId.current()].totalPoints += firstUserScore;
                userSeasonStats[secondUser][seasonId.current()].totalPoints += secondUserScore;

                totalPoints += firstUserScore + secondUserScore;
            }
        }
        gamesStats[seasonId.current()][weekTracker.current()].totalPoints += totalPoints;
    }

    /**
     * @dev Sets an address of the financial manager contract.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - A financial manager address (`financialManager`) should not equal to the zero address.
     *
     * @param _financialManager An address of the financial manager contract (`financialManager`).
     */
    function setFinancialManager(address _financialManager)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroAddress(_financialManager)
    {
        financialManager = IFinancialManager(_financialManager);
        emit FinancialManagerSet(_financialManager);
    }

    /**
     * @dev Calculates rewards for division winners in the reward token for the playoff which is stored in the
     * `financialManager` contract.
     *
     * Requirements:
     *  - The game stage should be equal to the stage of playoff rewards (`GameStage.PlayoffRewards`).
     *  - The number of division winner (`_numberOfDivisionWinners`) should not be equal to zero.
     *  - An address of the financial manager contract (`financialManager`) should not be equal to the zero address.
     *
     * @param _numberOfDivisionWinners A number of division winner to process. It allows you to split the function call
     * into multiple transactions to avoid reaching the gas cost limit. Each time the function is called, this number
     * can be anything greater than zero. When the process of calculating is completed, the `FantasyLeague` moves on to
     * the next stage --`GameStage.WaitingNextGame`.
     *
     * @notice The `financialManager` contract should transfer rewards for the division winners to the `FantasyLeague`
     * contract.
     */
    function calculatePlayoffRewards(uint256 _numberOfDivisionWinners)
        external
        onlyGameStage(GameStage.PlayoffRewards)
    {
        if (address(financialManager) == address(0)) revert IncorrectFinancialManager();
        if (_numberOfDivisionWinners == 0) revert DivisionWinnersNumberIsZero();

        uint256 season = seasonId.current();
        address[] storage refDivisionsWinners = divisionsWinners[season];

        // Index of the first division winner for whom the rewards will be calculated in this batch
        uint256 fromWinner = nextUserWithUpdRews;
        // Index of the last division winner for whom the rewards will be calculated in this batch
        uint256 toWinner = nextUserWithUpdRews + _numberOfDivisionWinners - 1;
        /*
         * Check that the process is over, i.e. all division winners have been processed this week. And corrected a
         * number of division winners to process if an overflow.
         */
        uint256 lastWinner = refDivisionsWinners.length - 1;
        if (toWinner < lastWinner) {
            nextUserWithUpdRews = toWinner + 1;
        } else {
            if (toWinner != lastWinner) {
                toWinner = lastWinner;
            }
            nextUserWithUpdRews = 0;
            moveGameStageTo(GameStage.WaitingNextGame);
        }

        // Calculation
        // Variables for loop
        (address tokenAddr, uint256 rewardValue) = financialManager.getPlayoffRewardTokenNValue();
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddr);
        address winner;
        uint256 week = weekTracker.current();
        for (uint256 i = fromWinner; i <= toWinner; ++i) {
            winner = refDivisionsWinners[i];

            // Saving of the reward value to winner statistics
            userWeeklyStats[winner][season][week].rewards[token] = rewardValue;

            mapping(IERC20Upgradeable => uint256) storage refWinnerAccumulatedRewards = accumulatedRewards[winner];
            refWinnerAccumulatedRewards[token] += rewardValue;
            emit DivisionWinnerRewardsCalculated(winner, refWinnerAccumulatedRewards[token]);
        }
    }

    // ____ Getters for the `MegaLeague` contract ____

    /**
     * @dev Returns the slice of the division winners' array (`divisionsWinners`) from the index `_from` to the index
     * `_to` in a season (`season`).
     *
     * @param _season The season ID.
     * @param _from The first index of the slice.
     * @param _to The second index of the slice.
     * @return divisionWinners   A slice of the array of division winners' array (`divisionsWinners`).
     *
     * @notice Up to and including the `_to` index.
     */
    function getSomeDivisionWinners(
        uint256 _season,
        uint256 _from,
        uint256 _to
    ) external view returns (address[] memory divisionWinners) {
        if (_from > _to) revert StartIndexIsGreaterThanEndIndex();
        address[] storage refDivisionsWinners = divisionsWinners[_season];

        if (_to >= refDivisionsWinners.length) revert EndIndexIsOutOfDivisionWinnersNumber();

        divisionWinners = new address[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; ++i) {
            divisionWinners[i] = refDivisionsWinners[i];
        }
        return divisionWinners;
    }

    /**
     * @dev Returns stats of the division winners from the index `_from` to the index `_to` in a season (`season`).
     *
     * @param _season The season ID.
     * @param _from The first index of the slice.
     * @param _to The second index of the slice.
     * @return divisionWinnersStats   Stats of the division winners from the `divisionsWinners` array.
     *
     * @notice Up to and including the `_to` index.
     */
    function getSomeDivisionWinnersStats(
        uint256 _season,
        uint256 _from,
        uint256 _to
    ) external view returns (DivisionWinnerStats[] memory divisionWinnersStats) {
        if (_from > _to) revert StartIndexIsGreaterThanEndIndex();
        address[] storage refDivisionsWinners = divisionsWinners[_season];
        if (_to >= refDivisionsWinners.length) revert EndIndexIsOutOfDivisionWinnersNumber();

        UserSeasonStats memory memUserSeasonStats;
        divisionWinnersStats = new DivisionWinnerStats[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; ++i) {
            memUserSeasonStats = userSeasonStats[refDivisionsWinners[i]][_season];
            divisionWinnersStats[i] = DivisionWinnerStats(
                memUserSeasonStats.totalPoints,
                memUserSeasonStats.wins,
                memUserSeasonStats.ties
            );
        }
        return divisionWinnersStats;
    }

    // _______________ Public functions _______________

    /**
     * @dev Checks that the division is correctly sorted and saves the top `PLAYOFF_COMPETITOR_NUM` users for playoff
     * competitions.
     *
     * @param _sortedDivision An array of users, which is a division sorted in descending order. Sorting is done based
     * on the user's seasonal statistics (`UserSeasonStats` structs).
     */
    // prettier-ignore
    function addSortedPlayoffDivision(address[] memory _sortedDivision)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyGameStage(GameStage.PlayoffCompetitorsSelection)
    {
        if (_sortedDivision.length != DIVISION_SIZE) revert ArraysLengthMismatch();
        /*
         * ID of the division from which the top `PLAYOFF_COMPETITOR_NUM` users will be saved (added to
         * `playoffCompetitors`) during the current transaction, if the `_sortedDivision` array is correctly sorted.
         */
        uint256 currentSortedDivisionId = nextProcessedDivisionId;

        if (nextProcessedDivisionId < getNumberOfDivisions() - 1) {
            nextProcessedDivisionId = currentSortedDivisionId + 1;
        } else {
            nextProcessedDivisionId = 0;
            moveGameStageTo(GameStage.PlayoffCompetitions);
        }

        // Check that the provided `_sortedUsers` array contains the same addresses as the division
        uint256 season = seasonId.current();
        if (!isSameDivisionAddresses(season, currentSortedDivisionId, _sortedDivision))
            revert IncorrectAddressDivisionId();

        // Check that the array is correctly sorted and randomly shuffle users who have a tie
        uint256 i;
        CompetitionResult result;
        address temp;
        for (i = 0; i < DIVISION_SIZE - 1; ++i) {
            result = compareUsers(season, _sortedDivision[i], _sortedDivision[i + 1]);
            
            if (result == CompetitionResult.SecondUserWon) revert IncorrectSorting();

            // Randomly determine whether to swap users, in case of a tie
            if (
                result == CompetitionResult.Tie &&
                (randNumber / 2 + uint256(blockhash(block.number)) / 2) % 2 == 1
            ) {
                temp = _sortedDivision[i];
                _sortedDivision[i] = _sortedDivision[i + 1];
                _sortedDivision[i + 1] = temp;
            }
        }

        // Writing of playoff competitors to the storage
        address[] storage refPlayoffCompetitors = playoffCompetitors[season];
        for (i = 0; i < PLAYOFF_COMPETITOR_NUM; ++i)
            refPlayoffCompetitors.push(_sortedDivision[0]);

        emit CompetitorsSelectedFromDivision(season, currentSortedDivisionId);
    }

    /**
     * @dev Returns the result of a comparison of users: a win for the first, a win for the second, a tie.
     *
     * @param _season Season ID.
     * @param _firstUser The first user in the comparison.
     * @param _secondUser The second user in the comparison.
     * @return   The result of the comparison of users.
     */
    // prettier-ignore
    function compareUsers(
        uint256 _season,
        address _firstUser,
        address _secondUser
    ) public view returns (CompetitionResult) {
        if (_firstUser == _secondUser) revert UserSelfcomparing();
        if (!(isUser[_season][_firstUser] && isUser[_season][_secondUser])) revert UnknownUser();

        UserSeasonStats storage firstUserSeasonStats = userSeasonStats[_firstUser][_season];
        UserSeasonStats storage secondUserSeasonStats = userSeasonStats[_secondUser][_season];

        if (firstUserSeasonStats.totalPoints > secondUserSeasonStats.totalPoints)
            return CompetitionResult.FirstUserWon;
        if (firstUserSeasonStats.totalPoints < secondUserSeasonStats.totalPoints)
            return CompetitionResult.SecondUserWon;

        if (firstUserSeasonStats.wins > secondUserSeasonStats.wins)
            return CompetitionResult.FirstUserWon;
        if (firstUserSeasonStats.wins < secondUserSeasonStats.wins)
            return CompetitionResult.SecondUserWon;

        if (firstUserSeasonStats.ties > secondUserSeasonStats.ties)
            return CompetitionResult.FirstUserWon;
        if (firstUserSeasonStats.ties < secondUserSeasonStats.ties)
            return CompetitionResult.SecondUserWon;

        return CompetitionResult.Tie;
    }

    // _______________ Internal functions _______________

    /**
     * @dev Check that the array contains the same addresses as the division.
     *
     * @param _season Season ID.
     * @param _divisionId Division number.
     * @param _arr Array with which the division is compared.
     * @return   True, if the array contains the same addresses as the division, false otherwise.
     */
    function isSameDivisionAddresses(
        uint256 _season,
        uint256 _divisionId,
        address[] memory _arr
    ) internal view returns (bool) {
        if (_arr.length != DIVISION_SIZE) revert ArrayLengthIsNotDivisionSize();

        // Array of users of the specified season
        address[] storage refUsers = users[_season];
        uint256 offsetInArray = _divisionId * DIVISION_SIZE;

        uint256 i;
        address current;
        bool isFound;
        uint256 j;
        for (i = 0; i < DIVISION_SIZE; ++i) {
            current = refUsers[i + offsetInArray];
            isFound = false;
            for (j = 0; j < _arr.length; ++j) {
                if (current == _arr[j]) {
                    isFound = true;
                    break;
                }
            }
            if (!isFound) return false;
        }
        return true;
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

pragma solidity 0.8.6;

import "../abstracts/mega-league-parts/DivisionWinnerStatsStruct.sol";

interface IMegaLeague {
    function startMegaLeague() external;

    function finishMegaLeague() external;

    function updateSeasonId() external;

    function addMegaLeagueRewards(address _token, uint256 _rewardAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IGen2PlayerToken is IERC721Upgradeable {
    function nftIdToDivisionId(uint256) external view returns (uint256);

    function nftIdToImageId(uint256) external view returns (uint256);

    function nftIdToSeasonId(uint256) external view returns (uint256);

    function getTokenPosition(uint256 _tokenId) external view returns (uint256 position);

    function updateSeasonId() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

// Here these contracts is connected to the Fantasy League contract (`FantasyLeague.sol`)
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./UsersNDivisions.sol";
import "../../interfaces/IScheduler.sol";
import "./CompetitionResultEnum.sol";

// List of errors for this contract
// Reverts when adding of a reward token that has already been added
error TokenAlreadyInTheList();
error NotARewardToken();
// Reverts when head to head competing of zero divisions
error DivisionNumberIsZero();
// Reverts when setting of a total week reward by the Multisig in the incorrect game stage
error OnlyH2HStage();
// Reverts when setting of a total week reward by the Multisig for a token that has not been added
error UnknownRewardToken();
// Reverts when update of rewards for zero users
error NumberOfUsersIsZero();

/**
 * @title Head to head competition -- the contract that responsible for weekly competitions and rewards for it (see the
 * description of the `FantasyLeague` contract for details).
 *
 * @dev This contract includes the following functionality:
 *  - Has the `MULTISIG_ROLE` role for the Multisig that sets total week rewards for head to head competitions.
 *  - Adds reward tokens for head to head and playoff competitions.
 *  - Sets the scheduler contract (`Scheduler`) that determines the schedule for head to head and playoff competitions.
 *  - Processes head to head competitions, as well as stores the season and weekly user statistics (team points and
 *    number of wins, losses, ties).
 *  - Stores total week rewards that is set by the Multisig.
 *  - Caclulates the rate of reward per point. (Points are calculated when head to head competing).
 *  - Updates the rewards for users in all the reward tokens according to the calculated rate, as well as stores these
 *    rewards and accumulates them for each user.
 *  - Allows accumulated rewards to be withdrawn by users at any time.
 *  - Gives:
 *   - the number of the current competition week;
 *   - the list of reward tokens;
 *   - a rate of reward per point;
 *   - total week rewards;
 *   - users' week rewards.
 */
abstract contract H2HCompetition is UsersNDivisions {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Constants _______________

    // ____ For access ____

    // The role for the Multisig that sets total week rewards for head to head competitions
    bytes32 public constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");

    // ____ For competitions ____

    // Number of weeks of H2H competitions
    uint8 public constant H2H_COMPETITION_WEEK_NUM = 15;

    // _______________ Structs _______________

    // ____ Structs for storing of H2H results, user stats and rewards ____

    // These structures are primarily used for historical data. Such data is used by several contracts and the back end

    // For the aggregation of competition week data
    struct WeekData {
        /*
         * The total points of all users' teams for the week used to calculate the rewards. The winners' points are
         * doubled to increase the rewards compared to the losers, in case of a tie the points are doubled for both.
         */
        uint256 totalPoints;
        /*
         * Number of rewards' tokens that transferred to the `FantasyLeague` contract for this week by Multisig via the
         * `FinancialManager` contract.
         * Reward token => reward value.
         */
        mapping(IERC20Upgradeable => uint256) totalRewards;
        /*
         * The reward rate -- this week's rewards-to-points ratio for each reward token. This is used to calculate user
         * rewards (distributing total rewards to users according to team points).
         * Reward token => rewards-to-points ratio.
         */
        mapping(IERC20Upgradeable => uint256) rewardPerPoint;
    }

    // For the aggregation of the user season statistics for all competitions
    struct UserSeasonStats {
        uint32 wins;
        uint32 losses;
        uint32 ties;
        /*
         * The total team points of a user for all competitions.
         * NOTE. This is used to determine the top 4 users in the division for the playoff competitions and the top 10
         * players in the final stage, the Mega League.
         */
        uint256 totalPoints;
    }

    // For the aggregation of the user weekly statistics for all competitions
    struct UserWeekStats {
        /*
         * Team points ot a user for a week.
         * NOTE. If the user wins or draws, the points are doubled to increase the number of rewards.
         */
        uint256 points;
        /*
         * Number of user rewards in each reward token. Calculated every week after the competition.
         * Reward token => reward value.
         */
        mapping(IERC20Upgradeable => uint256) rewards;
        /*
         * A flag is true if a user wins or draws.
         * NOTE. It is used to determine user's true points for the week, as they are doubled to increase rewards if
         * a user wins or draws.
         */
        bool isWinner;
    }

    // _______________ Storage _______________

    // ____ Variables for calculation of H2H competition ____

    // The contract that returns competition week schedule for the H2H and playoff competitions
    IScheduler public scheduler;

    /*
     * Next division ID to process. It is basically an division pointer to continue the different processes from where
     * it stopped in the last transaction.
     */
    uint256 public nextProcessedDivisionId;

    // Next user ID for whom rewards will be updated
    uint256 public nextUserWithUpdRews;

    /*
     * The current week of competitions.
     * NOTE. It is also used to store data on a weekly basis in mappings.
     */
    CountersUpgradeable.Counter internal weekTracker;

    // ____ Variables for writing history results of H2H competition ____

    /*
     * Stores competition data for weeks.
     * Week => season ID => competition week data.
     */
    mapping(uint256 => mapping(uint256 => WeekData)) public gamesStats;

    /*
     * Stores users' season statistics.
     * User => season ID => user season stats.
     */
    mapping(address => mapping(uint256 => UserSeasonStats)) public userSeasonStats;

    /*
     * Stores users' week statistics.
     * User => season ID => user week stats.
     */
    mapping(address => mapping(uint256 => mapping(uint256 => UserWeekStats))) public userWeeklyStats;

    // ____ Interfaces of external reward token contracts ____

    // The list of reward tokens that is used to reward users for weekly and playoff competitions
    IERC20Upgradeable[] public rewardTokens;

    // Token => is reward token
    mapping(IERC20Upgradeable => bool) public isRewardToken;

    // ____ For withdrawal of rewards by a user ____

    /*
     * Stores total rewards for each user in each reward token in all the time.
     * User => reward token => reward value.
     */
    mapping(address => mapping(IERC20Upgradeable => uint256)) public accumulatedRewards;

    // _______________ Events _______________

    /**
     * @dev Emitted when the interface address of the scheduler contract (`scheduler`) is changed to an address
     * `_scheduler`.
     *
     * @param _scheduler The address which is set by the current interface address of the scheduler contract.
     */
    event SchedulerSet(address _scheduler);

    /**
     * @dev Emitted when a reward token address (`_token`) is added to the array of reward tokens (`rewardTokens`).
     *
     * @param _token The address which is added to the array of reward tokens.
     */
    event RewardTokenAdded(IERC20Upgradeable _token);
    event RewardTokenRemoved(IERC20Upgradeable _token);

    /**
     * @dev Emitted when a `_firstUser` user competed against the `_secondUser` user in weekly or playoff competitions
     * in week `_week` with the `_competitionResult` result.
     *
     * @param _firstUser The address of the first user who competed.
     * @param _secondUser The address of the second user who competed.
     * @param _competitionResult The result of the competition: win, lose or tie.
     * @param _week The week number when competing.
     */
    event H2HCompetitionResult(
        address indexed _firstUser,
        address indexed _secondUser,
        CompetitionResult indexed _competitionResult,
        uint256 _week
    );

    /**
     * @dev Emitted when a total week reward in the amount of `_amount` is set by the Multisig (`MULTISIG_ROLE`) for
     * a reward token with an address `_token` in week `_week` in season `_season`.
     *
     * @param _season The season number.
     * @param _week The week number.
     * @param _token The address for which is added a total week reward amount.
     * @param _amount A total week reward amount that is set by the Multisig.
     */
    event TotalWeekRewardSet(uint256 _season, uint256 _week, address _token, uint256 _amount);

    /**
     * @dev Emitted when this week's rewards-to-points ratio (`_rewardPerPoint`) is calculated for a reward token
     * (`_rewardERC20`).
     *
     * @param _rewardERC20 A reward token from the `rewardTokens` array.
     * @param _rewardPerPoint A ratio of total rewards to total users' points for this week.
     */
    event RewardPerPointCalcutated(address _rewardERC20, uint256 _rewardPerPoint);

    /**
     * @dev Emitted when rewards (`_weekRewards`) for a user (`_user`) is updated with the rewards-to-points ratio in
     * the mapping of user week stats (`userWeeklyStats`) for a reward token (`_token`), and the rewards are added to
     * the user's accumulated rewards in the mapping (`accumulatedRewards`).
     *
     * @param _user A user for whom the rewards are calculated.
     * @param _token A reward token from the `rewardTokens` array.
     * @param _weekRewards A value of rewards that is added to user's accumulated rewards.
     * @param _accumulatedRewards A current value of user's accumulated rewards in the mapping (`accumulatedRewards`).
     */
    event UserRewardsUpdated(
        address indexed _user,
        address indexed _token,
        uint256 _weekRewards,
        uint256 _accumulatedRewards
    );

    /**
     * @dev Emitted when a user (`_user`) withdraws rewards in the amount of `_amount` for a reward token (`_token`).
     * @notice Rewards can be withdrawn at any time.
     *
     * @param _user A user who withdraws.
     * @param _token A reward token from the `rewardTokens` array.
     * @param _amount Amount of a reward token (`_token`).
     */
    event RewardWithdrawn(address indexed _user, IERC20Upgradeable indexed _token, uint256 _amount);

    // _______________ Initializer _______________

    /*
     * Sets the scheduler interface (`scheduler`) to a `_scheduler` address, grants the multisig role (`MULTISIG_ROLE`)
     * to a `_multisig` address, adds an array of reward tokens (`_rewardTokens`) to the `rewardTokens` array.
     *
     * NOTE. The function init_{ContractName}_unchained found in every upgradeble contract is the initializer function
     * without the calls to parent initializers, and can be used to avoid the double initialization problem.
     */
    function init_H2HCompetition_unchained(
        address _scheduler,
        address _multisig,
        IERC20Upgradeable[] calldata _rewardTokens
    ) internal onlyInitializing {
        scheduler = IScheduler(_scheduler);
        emit SchedulerSet(_scheduler);

        _grantRole(MULTISIG_ROLE, _multisig);

        rewardTokens = _rewardTokens;
        for (uint256 i = 0; i < _rewardTokens.length; ++i) {
            isRewardToken[_rewardTokens[i]] = true;
            emit RewardTokenAdded(_rewardTokens[i]);
        }
    }

    // _______________ External functions _______________

    // ____ Management of reward tokens ____

    /**
     * @dev Adds a reward token (`_token`) to the `rewardTokens` array.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - A reward token (`_token`) already have been added.
     *
     * @param _token A token which is added.
     */
    function addRewardToken(IERC20Upgradeable _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (isRewardToken[_token]) revert TokenAlreadyInTheList();
        rewardTokens.push(_token);
        isRewardToken[_token] = true;
        emit RewardTokenAdded(_token);
    }

    function removeRewardToken(IERC20Upgradeable _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!isRewardToken[_token]) revert NotARewardToken();
        uint256 length = rewardTokens.length;
        uint256 removeIndex = 0;
        for(uint256 i=0; i < length; i++){
            if(rewardTokens[i] == _token){
                removeIndex = i;
            }
        }
        rewardTokens[removeIndex] = rewardTokens[length - 1];
        rewardTokens.pop();
        isRewardToken[_token] = false;
        emit RewardTokenRemoved(_token);
    }

    // ____ For H2H competitions ____

    /**
     * @dev Sets an address of the scheduler contract.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - A scheduler address (`_scheduler`) should not equal to the zero address.
     *
     * @param _scheduler A new address of the scheduler contract (`scheduler`).
     */
    function setScheduler(address _scheduler) external onlyRole(DEFAULT_ADMIN_ROLE) nonzeroAddress(_scheduler) {
        scheduler = IScheduler(_scheduler);
        emit SchedulerSet(_scheduler);
    }

    /**
     * @notice It is for weekly competitions (see the description of the `FantasyLeague` contract for details).
     *
     * @dev Processes this week's competitions between users for some divisions (`_numberOfDivisions`).
     *
     * This process includes the following:
     *  - Check that the process is over, i.e. all divisions have been processed this week (see the description of the
     *    `_numberOfDivisions` parameter for details).
     *  - Calculation of the user's points (of his team of `Gen2PlayerToken` players) via the team manager contract
     *    (`teamManager`).
     *  - Competitions between users within divisions, where the winners are determined by the user's points. The
     *    competitions are on a schedule, obtained vie the scheduler contract (`Scheduler`).
     *  - Writing of user's statistics in the storage. Including points to calculate user's share of the reward pool.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - The game stage should be the H2H competitions' stage (`GameStage.H2HCompetitions`).
     *  - The number of divisions should not be equal to zero.
     *  - The scheduler and team manager contracts (`scheduler`, `teamManager`) should be set.
     *
     * @param _numberOfDivisions A number of divisions to process. It allows you to split the function call into
     * multiple transactions to avoid reaching the gas cost limit. Each time the function is called, this number can be
     * anything greater than zero. When the process of playoff competing is completed, the `FantasyLeague` moves on to
     * the next stage -- `GameStage.H2HRewardPerPointCalculation`.
     */
    function competeH2Hs(uint256 _numberOfDivisions)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyGameStage(GameStage.H2HCompetitions)
    {
        if (_numberOfDivisions == 0) revert DivisionNumberIsZero();

        // The first division that will be calculated in this batch
        uint256 fromDivision = nextProcessedDivisionId;
        // The last division that will be calculated in this batch
        uint256 toDivision = nextProcessedDivisionId + _numberOfDivisions - 1;
        /*
         * Check that the process is over, i.e. all divisions have been processed this week. And corrected a number of
         * divisions to process if an overflow.
         */
        uint256 lastDivision = getNumberOfDivisions() - 1;
        if (toDivision < lastDivision) {
            nextProcessedDivisionId = toDivision + 1;
        } else {
            if (toDivision != lastDivision) {
                toDivision = lastDivision;
            }
            nextProcessedDivisionId = 0;
            // Movement to the next stage when this week's competitions are over
            moveGameStageTo(GameStage.H2HRewardPerPointCalculation);
        }

        // Below are variables for a loop of competitions
        // Array of users of the specified season
        uint256 season = seasonId.current();
        address[] storage refUsers = users[season];

        uint256 week = weekTracker.current();
        // The elements of this array are read in pairs (indexes zero and one correspond to the first pair, and so on)
        uint8[DIVISION_SIZE] memory wSchedule = scheduler.getH2HWeekSchedule(week);

        // Number by which the offset occurs to determine a user index in the array of all users (`refUsers`)
        uint256 offsetInArray;
        // Index of the first user (competitor) in a pair in the current division
        uint256 competitor;
        // A pair of users (competitors)
        address firstUser;
        address secondUser;
        // Total score (points) of users (competitors)
        uint256 firstUserScore;
        uint256 secondUserScore;

        // Total score (points) of competitors in all divisions that is calculated in this batch
        uint256 totalPoints;

        // Start from the first division that will be calculated in this batch
        // prettier-ignore
        for (uint256 division = fromDivision; division <= toDivision; ++division) {
            /*
             * In each division, each user competes against one another. That is, one division has 6 competitions,
             * because it consists of 12 users. 
             */
            offsetInArray = division * DIVISION_SIZE;
            for (competitor = 0; competitor < DIVISION_SIZE; competitor += 2) {
                // Get addresses of the first and second users (competitors)
                firstUser = refUsers[wSchedule[competitor] + offsetInArray];
                secondUser = refUsers[wSchedule[competitor + 1] + offsetInArray];

                // Competing
                (firstUserScore, secondUserScore) = teamManager.calcTeamScoreForTwoUsers(firstUser, secondUser);
                CompetitionResult result = getH2HCompetitionResult(firstUserScore, secondUserScore);
                updateUserStats(firstUser, secondUser, result);
                emit H2HCompetitionResult(firstUser, secondUser, result, weekTracker.current());

                // Saving of user total points (for the Playoff and Mega League stages in the future)
                userSeasonStats[firstUser][season].totalPoints += firstUserScore;
                userSeasonStats[secondUser][season].totalPoints += secondUserScore;

                // Increasing of winner's score to increase his rewards. Tie means both are winners
                if (result == CompetitionResult.FirstUserWon) {
                    firstUserScore *= 2;
                } else if (result == CompetitionResult.SecondUserWon) {
                    secondUserScore *= 2;
                } else {
                    // Tie
                    firstUserScore *= 2;
                    secondUserScore *= 2;
                }
                // Saving of user week score for reward calculation
                userWeeklyStats[firstUser][season][week].points = firstUserScore;
                userWeeklyStats[secondUser][season][week].points = secondUserScore;

                totalPoints += firstUserScore + secondUserScore;
            }
        }
        // Need to calculate the rewards-to-points ratio
        gamesStats[season][week].totalPoints += totalPoints;
    }

    // ____ For receiving of rewards ____

    /**
     * @dev Adds total rewards for the current week by the Miltisig. These rewards will be distributed between all
     * users according to the rewards-to-points ratio that is calculated in the `calculateRewardPerPoint()` function.
     *
     * Requirements:
     *  - The caller should have the multisig role (`MULTISIG_ROLE`).
     *  - The game stage should be equal to the H2H competitions' stage (`GameStage.H2HCompetitions`) or the stage of
     *    the calculation of the rewards-to-points ratio (`GameStage.H2HRewardPerPointCalculation`).
     *  - The reward token (`_token`) should have been added.
     *
     * @param _token A token for which rewards are added.
     * @param _amount Reward amount.
     */
    function setTotalWeekReward(IERC20Upgradeable _token, uint256 _amount) external onlyRole(MULTISIG_ROLE) {
        GameStage gs = getGameStage();

        if (!(gs == GameStage.H2HCompetitions || gs == GameStage.H2HRewardPerPointCalculation)) revert OnlyH2HStage();
        if (!isRewardToken[_token]) revert UnknownRewardToken();

        // Setting
        uint256 season = seasonId.current();
        uint256 week = weekTracker.current();
        gamesStats[season][week].totalRewards[_token] = _amount;
        emit TotalWeekRewardSet(season, week, address(_token), _amount);

        _token.transferFrom(_msgSender(), address(this), _amount);
    }

    // ____ For weekly calculation of rewards ____

    /**
     * @dev Calculates the rewards-to-points ratio which is used to calculate shares of user rewards in the reward
     * update function (`updateRewardsForUsers()`).
     *
     * Requirements:
     *  - The game stage should be equal to the stage of the calculation of the rewards-to-points ratio
     *    (`GameStage.H2HRewardPerPointCalculation`).
     *
     * @notice When the process of calculating is completed, the `FantasyLeague` moves on to the next stage --
     * `GameStage.H2HRewardsUpdate`.
     */
    function calculateRewardPerPoint() external onlyGameStage(GameStage.H2HRewardPerPointCalculation) {
        IERC20Upgradeable token;
        uint256 rewardPerPoint;
        WeekData storage weekData = gamesStats[seasonId.current()][weekTracker.current()];
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            token = rewardTokens[i];
            rewardPerPoint = weekData.totalRewards[token] / weekData.totalPoints;
            weekData.rewardPerPoint[token] = rewardPerPoint;
            emit RewardPerPointCalcutated(address(token), rewardPerPoint);
        }

        moveGameStageTo(GameStage.H2HRewardsUpdate);
    }

    /**
     * @dev Updates rewards for users in each reward token from the `rewardTokens` array.
     *
     * Requirements:
     *  - The game stage should be equal to the stage of reward update (`GameStage.H2HRewardsUpdate`).
     *  - The number of users (`_numberOfUsers`) should not be equal to zero.
     *
     * @param _numberOfUsers A number of users to process. It allows you to split the function call into multiple
     * transactions to avoid reaching the gas cost limit. Each time the function is called, this number can be anything
     * greater than zero. When the process of updating is completed, the `FantasyLeague` moves on to the next stage --
     * `GameStage.WaitingNextGame`.
     */
    function updateRewardsForUsers(uint256 _numberOfUsers) external onlyGameStage(GameStage.H2HRewardsUpdate) {
        if (_numberOfUsers == 0) revert NumberOfUsersIsZero();

        // Index of the first user that will be updated in this batch
        uint256 fromUser = nextUserWithUpdRews;
        // Index of the last user that will be updated in this batch
        uint256 toUser = nextUserWithUpdRews + _numberOfUsers - 1;
        /*
         * Check that the process is over, i.e. all users have been processed this week. And corrected a number of
         * users to process if an overflow.
         */
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

    /**
     * @dev Transfers all caller's rewards to the caller in each reward token from the `rewardTokens` array.
     *
     * Requirements:
     *  - The game stage should be equal to the stage of reward update (`GameStage.H2HRewardsUpdate`).
     *  - The number of users (`_numberOfUsers`) should not be equal to zero.
     *
     * @notice This function can be called by a user at any time.
     */
    function withdrawRewards() external {
        // Check that the caller is an added user
        uint256 season = seasonId.current();
        uint256 i;
        bool isAddedUser = false;
        for (i = 0; i <= season; ++i) {
            if (isUser[i][_msgSender()]) {
                isAddedUser = true;
            }
        }
        if (!isAddedUser) revert UnknownUser();

        // Transfers
        IERC20Upgradeable token;
        uint256 amount;
        mapping(IERC20Upgradeable => uint256) storage refSenderAccumulatedRewards = accumulatedRewards[_msgSender()];
        for (i = 0; i < rewardTokens.length; ++i) {
            token = rewardTokens[i];

            amount = refSenderAccumulatedRewards[token];
            delete refSenderAccumulatedRewards[token];
            token.transfer(_msgSender(), amount);

            emit RewardWithdrawn(_msgSender(), token, amount);
        }
    }

    //  ____ Extra view functionality for back end ____

    /**
     * @dev Returns the current week of a season (`seasonId.current()`).
     *
     * @return   The current week.
     */
    function getCurrentWeek() external view returns (uint256) {
        return weekTracker.current();
    }

    /**
     * @dev Returns total rewards of a token (`_token`) of a week (`_week`) in a season (`_season`).
     *
     * @param _season ID of the season in which a week is required.
     * @param _week The week in which rewards were set by the Multisig (`MULTISIG_ROLE`).
     * @param _token A token for which a value is returned.
     * @return   The total week rewards of the token.
     */
    function getTotalWeekRewards(
        uint256 _season,
        uint256 _week,
        IERC20Upgradeable _token
    ) external view returns (uint256) {
        return gamesStats[_season][_week].totalRewards[_token];
    }

    /**
     * @dev Returns the rewards-to-points ratio for a token (`_token`) of a week (`_week`) in a season (`_season`).
     *
     * @param _season ID of the season in which a week is required.
     * @param _week The week in which the ration were calculated.
     * @param _token A token for which a value is returned.
     * @return   The rewards-to-points ratio of the token.
     */
    function getRewardPerPoint(
        uint256 _season,
        uint256 _week,
        IERC20Upgradeable _token
    ) external view returns (uint256) {
        return gamesStats[_season][_week].rewardPerPoint[_token];
    }

    /**
     * @dev Returns rewards of a user (`_user`) for a week (`_week`) in a season (`_season`).
     *
     * @param _user A user whose rewards are to be read.
     * @param _season ID of the season in which a week is required.
     * @param _week The week in which rewards were updated for the user.
     * @param _token A token for which a value is returned.
     * @return   The user's week rewards of the token.
     */
    function getUserWeekReward(
        address _user,
        uint256 _season,
        uint256 _week,
        IERC20Upgradeable _token
    ) external view returns (uint256) {
        return userWeeklyStats[_user][_season][_week].rewards[_token];
    }

    /**
     * @dev Returns the current array of reward tokens (`rewardTokens`).
     *
     * @return   The array of reward tokens.
     */
    function getRewardTokens() external view returns (IERC20Upgradeable[] memory) {
        return rewardTokens;
    }

    // _______________ Internal functions _______________

    // ____ For H2H competitions ____

    /*
     * Returns the result of a competition between 2 users based on their points (`_firstUserScore`,
     * `_secondUserScore`).
     */
    // prettier-ignore
    function getH2HCompetitionResult(uint256 _firstUserScore, uint256 _secondUserScore)
        internal
        pure
        returns (CompetitionResult)
    {
        if (_firstUserScore > _secondUserScore)
            return CompetitionResult.FirstUserWon;
        if (_firstUserScore < _secondUserScore)
            return CompetitionResult.SecondUserWon;
        // A tie means both are winners
        return CompetitionResult.Tie;
    }

    /*
     * Writes season and week stats (wins, losses, ties) of 2 users (`_firstUser`, `_secondUser`) based on their
     * competition result (`_result`) to the storage.
     */
    function updateUserStats(
        address _firstUser,
        address _secondUser,
        CompetitionResult _result
    ) internal {
        uint256 season = seasonId.current();
        uint256 week = weekTracker.current();
        if (_result == CompetitionResult.FirstUserWon) {
            userSeasonStats[_firstUser][season].wins += 1;
            userWeeklyStats[_firstUser][season][week].isWinner = true;

            userSeasonStats[_secondUser][season].losses += 1;
            userWeeklyStats[_secondUser][season][week].isWinner = false;
        } else if (_result == CompetitionResult.SecondUserWon) {
            userSeasonStats[_firstUser][season].losses += 1;
            userWeeklyStats[_firstUser][season][week].isWinner = false;

            userSeasonStats[_secondUser][season].wins += 1;
            userWeeklyStats[_secondUser][season][week].isWinner = true;
        } else {
            // Tie
            userSeasonStats[_firstUser][season].ties += 1;
            userWeeklyStats[_firstUser][season][week].isWinner = true;

            userSeasonStats[_secondUser][season].ties += 1;
            userWeeklyStats[_secondUser][season][week].isWinner = true;
        }
    }

    // ____ For weekly calculation of rewards ____

    // Updates rewards for a specified user (`_user`) in each reward token from the `rewardTokens` array
    function updateRewardsForUser(address _user) internal {
        IERC20Upgradeable token;

        uint256 season = seasonId.current();
        uint256 week = weekTracker.current();
        UserWeekStats storage refUserWeekStats = userWeeklyStats[_user][season][week];

        uint256 rewardPerPoint;
        WeekData storage weekData = gamesStats[season][week];
        uint256 userPoints;
        uint256 weekRewards;

        mapping(IERC20Upgradeable => uint256) storage refUserAccumulatedRewards = accumulatedRewards[_user];
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            token = rewardTokens[i];

            rewardPerPoint = weekData.rewardPerPoint[token];
            userPoints = refUserWeekStats.points;
            weekRewards = rewardPerPoint * userPoints;
            refUserWeekStats.rewards[token] = weekRewards;

            refUserAccumulatedRewards[token] += weekRewards;
            emit UserRewardsUpdated(_user, address(token), weekRewards, refUserAccumulatedRewards[token]);
        }
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new variables without shifting
     * down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps.
     */
    uint256[41] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface INomoRNG {
    function requestRandomNumber() external returns (uint256 _random);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IFinancialManager {
    function getPlayoffRewardTokenNValue() external view returns (address token, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

struct DivisionWinnerStats {
    uint256 totalPoints;
    uint32 wins;
    uint32 ties;
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

// Here these contracts is connected to the Fantasy League contract (`FantasyLeague.sol`)
import "./GameProgress.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../interfaces/ILeaguePassNFT.sol";
import "../../interfaces/ITeamManager.sol";
import "../common-parts/RandomGenerator.sol";

// List of errors for this contract
// Reverts when try to pass the zero address as a parameter value
error ZeroAddress();
// Reverts when try to call by someone else a function that is intended only for the `LeaguePassNFT` contract
error NotALeaguePassNFTContract();
// Reverts when try to use an address that did not join to the Fantasy League
error UnknownUser();
// Reverts when try to join a user who has already been added
error UserIsAlreadyAdded();
// Reverts when shuffle of users with a zero random number
error RandNumberIsNotUpdated();
// Reverts when shuffle of zero users
error NumberOfUsersToShuffleIsZero();
// Reverts when shuffle not during the shuffling stage
error NotAUserShuffleGameStage();
// Reverts when shuffle after the end of the shuffle
error ShuffleIsCompleted();

/**
 * @title Users and divisions -- contract, which is part of the Fantasy League contract (`FantasyLeague.sol`), provides
 * storing of all users and assigment of them to divisions.
 *
 * @notice This contract connects `GameProgress.sol`, `ILeaguePassNFT.sol`, `ITeamManager.sol`, `RandomGenerator.sol`
 * and OpenZeppelin `AccessControlUpgradeable.sol` to the Fantasy League contract.
 *
 * Assigment of users to divisions is implemented by shuffling the user array randomly using `RandomGenerator.sol`
 * which is linked to `NomoRNG.sol`. Storing of divisions is implemented by offset in the user array.
 *
 * @dev This contract includes the following functionality:
 *  - Sets the entry pass and team manager contracts (`LeaguePassNFT.sol` and `TeamManager.sol`).
 *  - Adds and stores all users.
 *  - Sets the `RandonGenerator` contract and updates the random number.
 *  - Shuffles users to assign them to divisions.
 *  - Gives divisions, user division IDs and the number of users and divisions.
 */
abstract contract UsersNDivisions is RandomGenerator, GameProgress, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Constants _______________

    // (For user dividing into divisions). Number of teams in one division. 1 user per 1 team
    uint256 public constant DIVISION_SIZE = 12;

    // _______________ Storage _______________

    // ____ User adding access ____

    // The League Entry Pass contract that adds users
    ILeaguePassNFT public leaguePassNFT;

    // ____ Management of users ____

    /*
     * The array of added (joined) users.
     * Season ID => users.
     */
    mapping(uint256 => address[]) public users;

    // Season ID => (user => is user)
    mapping(uint256 => mapping(address => bool)) public isUser;

    // The contract stores the user's team of players and calculates the score of that team
    ITeamManager public teamManager;

    // ____ Mapping for the auction contract ____

    /*
     * Stores a division ID of a user (after the shuffle process).
     * Season ID => (user => [division ID + 1]).
     * NOTE. Plus 1, because the zero value means that the user is not assigned a division.
     */
    mapping(uint256 => mapping(address => uint256)) private userDivisionIncreasedId;

    // ____ Shuffle ____

    /*
     * Number of users who have already been shuffled (assigned to a division).
     *
     * NOTE. It's basically an array pointer to split a transaction into several and continue shuffling from the point
     * at which it was stopped.
     */
    uint256 public shuffledUserNum;

    // _______________ Events _______________

    /**
     * @dev Emitted when the interface address of the entry pass contract (`leaguePassNFT`) is changed to an address
     * `_leaguePassNFT`.
     *
     * @param _leaguePassNFT The address which is set by the current interface address of the entry pass contract.
     */
    event LeaguePassNFTSet(address _leaguePassNFT);

    /**
     * @dev Emitted when the interface address of the team manager contract (`teamManager`) is changed to an address
     * `_teamManager`.
     *
     * @param _teamManager The address which is set by the current interface address of the team manager contract.
     */
    event TeamManagerSet(address _teamManager);

    /**
     * @dev Emitted when a new user (`_user`) is added (joined) to the game (the Fantasy League) in the specified season
     * (`_seasonId`).
     *
     * @param _seasonId The season in which the user was added.
     * @param _user An added user.
     */
    event UserAdded(uint256 indexed _seasonId, address _user);

    // _______________ Modifiers _______________

    /**
     * @dev Check that an address (`_address`) is not zero. Reverts in the opposite case.
     *
     * @param _address Address check for zero.
     */
    modifier nonzeroAddress(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    /// @dev Check that the call is from the entry pass contract (`leaguePassNFT`). Reverts in the opposite case
    modifier onlyLeaguePassNFT() {
        if (_msgSender() != address(leaguePassNFT)) revert NotALeaguePassNFTContract();
        _;
    }

    /**
     * @dev Check that a user (`_user`) is added in the season (`_season`). Reverts in the opposite case.
     *
     * @param _season A season ID.
     * @param _user A user address to check.
     */
    modifier addedUser(uint256 _season, address _user) {
        if (!isUser[_season][_user]) revert UnknownUser();
        _;
    }

    // _______________ Initializer _______________

    /*
     * Grants the default administrator role (`DEFAULT_ADMIN_ROLE`) to the deployer, sets the random generator interface
     * as `_generator`.
     *
     * NOTE. The function init_{ContractName}_unchained found in every upgradeble contract is the initializer function
     * without the calls to parent initializers, and can be used to avoid the double initialization problem.
     */
    function init_UsersNDivisions_unchained(address _generator) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        setRandomGenerator(_generator);
    }

    // _______________ External functions _______________

    /**
     * @dev Sets the entry pass contract (`leaguePassNFT`) as `_leaguePassNFT`, syncs the current season ID of
     * the passed entry pass with that in this contract.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - An entry pass address (`_leaguePassNFT`) should not equal to the zero address.
     *
     * @param _leaguePassNFT An address of the LeagueDAO entry pass contract -- `LeaguePassNFT` that adds users to this
     * contract.
     */
    function setLeaguePassNFT(address _leaguePassNFT)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroAddress(_leaguePassNFT)
    {
        leaguePassNFT = ILeaguePassNFT(_leaguePassNFT);
        emit LeaguePassNFTSet(_leaguePassNFT);

        leaguePassNFT.updateSeasonId();
    }

    /**
     * @dev Adds a new user to the game (to this contract) in the current season `seasonId`.
     *
     * Requirements:
     *  - The caller should be the entry pass contract (`leaguePassNFT`).
     *  - A user address (`_user`) should not equal to the zero address.
     *  - This function should only be called in the game stage of user adding (`GameStage.UserAdding`). (This is the
     *    first stage in which the Fantasy League (`FantasyLeague`) stays at the start of the season).
     *  - A user address (`_user`) should not already have been added.
     *
     * @param _user An address of a user.
     */
    function addUser(address _user)
        external
        onlyLeaguePassNFT
        nonzeroAddress(_user)
        onlyGameStage(GameStage.UserAdding)
    {
        // Check if user is already added
        uint256 season = seasonId.current();
        if (isUser[season][_user]) revert UserIsAlreadyAdded();

        // Add team to the game
        users[season].push(_user);
        isUser[season][_user] = true;

        emit UserAdded(season, _user);
    }

    /**
     * @dev Sets the random number generator contract (`generator`) as `_generator`. (`NomoRNG` is the random generator
     * contract).
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - A random generator address (`_generator`) should not equal to the zero address.
     *
     * @param _generator An address of the random generator that updates the random number (`randNumber`).
     */
    function setRandGenerator(address _generator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setRandomGenerator(_generator);
    }

    /**
     * @dev Updates the random number (`randNumber`) via Chainlink VRFv2.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - The random generator address (`generator`) should not equal to the zero address.
     *
     * @notice Firstly, need to generate the random number on the `NomoRNG` contract.
     */
    function updateRandNum() external onlyRole(DEFAULT_ADMIN_ROLE) {
        updateRandomNumber();
    }

    /**
     * @dev Sets the team manager contract (`teamManager`) as `_teamManager`, syncs the current season ID of the passed
     * team manager with that in this contract.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - A team manager address (`_teamManager`) should not equal to the zero address.
     *
     * @param _teamManager   An address of the Team Manager contract (`TeamManager`) that calculates scores and stakes
     * user players.
     */
    function setTeamManager(address _teamManager) external onlyRole(DEFAULT_ADMIN_ROLE) nonzeroAddress(_teamManager) {
        teamManager = ITeamManager(_teamManager);
        emit TeamManagerSet(_teamManager);

        teamManager.updateSeasonId();
    }

    /**
     * @dev This function does the following:
     *  - Shuffles the array of all users to randomly divides users into divisions of 12 users.
     *  - Sets a user division ID in this and `TeamManager` contracts (`teamManager`).
     *  - Moves the game stage to the stage of waiting of the next game function (`GameStage.WaitingNextGame`) when the
     *    shuffling is completed.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - The random number (`randNumber`) should not equal to the zero.
     *  - The number of users to shuffle (`_numberToShuffle`) should not equal to the zero.
     *  - After the first call of this function (see below the `_numberToShuffle` param description), it should only be
     *    called in the game stage of user shuffle (`GameStage.UserShuffle`).
     *  - The team manager contract (`teamManager`) should be set.
     *
     * @param _numberToShuffle A number of users to shuffle. It allows you to split the function call into multiple
     * transactions to avoid reaching the gas cost limit. Each time the function is called, this number can be anything
     * greater than zero. When the process of shuffle is completed, the `FantasyLeague` moves on to the next stage
     * (`GameStage.WaitingNextGame`).
     */
    function shuffleUsers(uint256 _numberToShuffle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (randNumber == 0) revert RandNumberIsNotUpdated();
        if (_numberToShuffle == 0) revert NumberOfUsersToShuffleIsZero();

        if (shuffledUserNum == 0) {
            moveGameStageTo(GameStage.UserShuffle);
        }
        if (getGameStage() != GameStage.UserShuffle) revert NotAUserShuffleGameStage();

        // Check that all users was shuffled
        address[] storage refUsers = users[seasonId.current()];
        uint256 usersLen = refUsers.length;
        if (shuffledUserNum >= usersLen) revert ShuffleIsCompleted();

        // Check that the shuffle will be completed after this transaction
        if (usersLen <= shuffledUserNum + _numberToShuffle) {
            _numberToShuffle = usersLen - shuffledUserNum;
            moveGameStageTo(GameStage.WaitingNextGame);
        }

        // Shuffle the array of users
        uint256 newShuffledUserNum = shuffledUserNum + _numberToShuffle;
        uint256 index;
        address user;
        mapping(address => uint256) storage refUserDivisionIncreasedId = userDivisionIncreasedId[seasonId.current()];
        for (uint256 i = shuffledUserNum; i < newShuffledUserNum; ++i) {
            index = i + (uint256(keccak256(abi.encodePacked(randNumber))) % (usersLen - i));
            // Swap
            user = refUsers[index];
            refUsers[index] = refUsers[i];
            refUsers[i] = user;

            // Saving of a user division ID
            uint256 divisionId = i / DIVISION_SIZE;
            refUserDivisionIncreasedId[user] = divisionId + 1;
            // Send of a user division ID to the TeamManager contract
            teamManager.setUserDivisionId(user, divisionId);
        }
        // Saving of the number of users that were shuffled
        shuffledUserNum += _numberToShuffle;
    }

    // ____ Extra view functionality for back end ____

    /**
     * @dev Returns a division ID of a user (`_user`) in a season (`_season`).
     *
     * Requirements:
     *  - A user (`_user`) should be added in a season (`_season`).
     *
     * @return   A user division ID.
     */
    function getUserDivisionId(uint256 _season, address _user)
        external
        view
        addedUser(_season, _user)
        returns (uint256)
    {
        return getCorrectedId(userDivisionIncreasedId[_season][_user]);
    }

    /**
     * @dev Returns a division of 12 users by the specified division ID (`_divisionId`) and season (`_season`).
     *
     * @return division   A division -- an array of 12 users.
     */
    function getDivisionUsers(uint256 _season, uint256 _divisionId) external view returns (address[] memory division) {
        division = new address[](DIVISION_SIZE);
        // Array of users of the specified season
        address[] storage refUsers = users[_season];
        uint256 offsetInArray = _divisionId * division.length;
        for (uint256 i = 0; i < division.length; ++i) {
            division[i] = refUsers[i + offsetInArray];
        }
        return division;
    }

    // _______________ Public functions _______________

    /**
     * @dev Returns the number of users who is added (joined) to the Fantasy League.
     *
     * @return   The number of users who is added (joined) to the Fantasy League.
     */
    function getNumberOfUsers() public view returns (uint256) {
        return users[seasonId.current()].length;
    }

    /**
     * @dev Returns the total number of divisions in the Fantasy League.
     *
     * @return   The total number of divisions.
     */
    function getNumberOfDivisions() public view returns (uint256) {
        return getNumberOfUsers() / DIVISION_SIZE;
    }

    // _______________ Private functions _______________

    // Returns the number decreased by one. Made for convenience when working with IDs in a mapping
    function getCorrectedId(uint256 _increasedId) private pure returns (uint256) {
        return _increasedId - 1;
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new variables without shifting
     * down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps.
     */
    uint256[44] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IScheduler {
    function getH2HWeekSchedule(uint256 _week) external pure returns (uint8[12] memory);

    function getPlayoffWeekSchedule(uint256 _week) external pure returns (uint8[4] memory);
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

// Here these contracts is connected to the Fantasy League contract (`FantasyLeague.sol`)
// This is developed with OpenZeppelin upgradeable contracts v4.5.2
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

// List of errors for this contract
// Reverts when movement to the stage which is not further in the enum or exception
error IncorrectGameStageDirectionChange();
/*
 * Reverts when movement from the exception stage to the stage which is not `GameStage.WaitingNextGame`,
 * `GameStage.UserAdding`.
 */
error IncorrectGameStageChange();
// Reverts when try to untimely call a function
error IncorrectGameStage();

/**
 * @title Game Progress -- contract, which is part of the Fantasy League contract (`FantasyLeague.sol`), provides
 * season and game process advancement functionality for the Fantasy League contract.
 *
 * @notice All contracts that require a current season ID are oriented to the season ID in this contract
 * using the season sync contract (`SeasonSync.sol` or `SeasonSyncNonupgradeable.sol`).
 *
 * It is through this contract that the sequence of function calls is regulated.
 *
 * This contract connects OpenZeppelin `Initializable.sol` and `CountersUpgradeable.sol` to the Fantasy League contract.
 *
 * @dev This contract includes the following functionality:
 *  - Stores the list of game stages for the Fantasy League contract and the current game stage, as well as advances it
 *    to the next.
 *  - Stores the current season ID and advances it to the next.
 */
abstract contract GameProgress is Initializable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // _______________ Enums _______________

    /*
     * A list of states of the game stage variable (`gameStage`), that is, the game stages of the Fantasy League
     * contract during one season.
     *
     * This list is used to ensure that the Fantasy League contract functions are called in the required sequence. That
     * is, this list tells you what now needs to be called in the Fantasy League contract.
     *
     * NOTE. Adding and shuffle of users (`UserAdding` and `UserShuffle`) occurs once a season. Then the Fantasy League
     * game process can be represented by three main stages: weekly head to head competitions (15 weeks),
     * playoffs (16th and 17th week), and the Mega League [final] (17th week). The state of waiting for the next game
     * (`WaitingNextGame`) is associated with a special function (`nextGame()`, FantasyLeague.sol) that is repeatedly
     * called by the back end to continue the game process. We get into this state every week before the competitions
     * start. States with the prefix "H2H" are used for the weekly H2H competition stage. That is, every week we get to
     * `H2HCompetitions`, `H2HRewardPerPointCalculation` and `H2HRewardsUpdate`. On 16th week, we move on to
     * the playoff stage, where first the competitors are selected from all users (`PlayoffCompetitorsSelection`), then
     * the competitions are held (`PlayoffCompetitions`), and then the rewards are calculated (`PlayoffRewards`). Then,
     * using the next game function (`nextGame()`, FantasyLeague.sol), we move on to the Mega League,
     * which is implemented in an external contract (`MegaLeague.sol`).
     *
     * In addition, users have a player staking period (forming their game team) with individual deadlines. The staking
     * takes place between state `WaitingNextGame` and `H2HCompetitions`. External contract `TeamManager.sol` is
     * responsible for the functionality of the stake, and external contract `TeamsStakingDeadlines.sol` is responsible
     * for the deadlines.
     */
    enum GameStage {
        UserAdding,
        UserShuffle,
        WaitingNextGame,
        H2HCompetitions,
        H2HRewardPerPointCalculation,
        H2HRewardsUpdate,
        PlayoffCompetitorsSelection,
        PlayoffCompetitions,
        PlayoffRewards
    }

    // _______________ Storage _______________

    // The current stage of the Fantasy League game process. See the `GameStage` enum comment for details
    GameStage internal gameStage;

    /*
     * The the current season ID, during which the entire process of the Fantasy League game takes place. (The season
     * is about 17 weeks long).
     */
    CountersUpgradeable.Counter public seasonId;

    // _______________ Events _______________

    /**
     * @dev Emitted when the game stage (`gameStage`) is moved to the next stage (`_gs`). That is, the `gameStage`
     * variable is assigned value `_gs`.
     *
     * @param _gs A new game stage value.
     */
    event GameStageMovedTo(GameStage indexed _gs);

    /**
     * @dev Emitted when the Fantasy League moves on to the next season (`_seasonId`). That is, the `seasonId` variable
     * is assigned value `_seasonId`.
     *
     * @param _seasonId A next season ID.
     */
    event SeasonFinished(uint256 indexed _seasonId);

    // _______________ Modifiers _______________

    /**
     * @dev Checks that the current game stage is the `_gs` stage. Reverts in the opposite case.
     *
     * @param _gs The value of the game stage to compare with the current one.
     */
    modifier onlyGameStage(GameStage _gs) {
        if (gameStage != _gs) revert IncorrectGameStage();
        _;
    }

    // _______________ Initializer _______________

    /*
     * Sets the game stage (`gameStage`) to the user adding stage (`GameStage.UserAdding`).
     *
     * NOTE. The function init_{ContractName}_unchained found in every upgradeble contract is the initializer function
     * without the calls to parent initializers, and can be used to avoid the double initialization problem.
     */
    function init_GameProgress_unchained() internal onlyInitializing {
        gameStage = GameStage.UserAdding;
        emit GameStageMovedTo(GameStage.UserAdding);
    }

    // _______________ External functions _______________

    //  ____ Extra view functionality for back end ____

    /**
     * @dev Returns the current value of the season ID (`seasonId`).
     *
     * @return   The current season ID.
     */
    function getSeasonId() external view returns (uint256) {
        return seasonId.current();
    }

    // _______________ Public functions _______________

    /**
     * @dev Returns the current value of the game stage (`gameStage`).
     *
     * @return   The current game stage.
     */
    function getGameStage() public view returns (GameStage) {
        return gameStage;
    }

    // _______________ Internal functions _______________

    /*
     * Moves the game state (`gameStage`) to the specified one.
     *
     * Requirements:
     *  - The stage to which moves should be further in the enum, except for: `GameStage.H2HRewardsUpdate`,
     *    `GameStage.PlayoffCompetitions`, `GameStage.PlayoffRewards`.
     */
    function moveGameStageTo(GameStage _gs) internal {
        GameStage gs = gameStage;
        if (gs != GameStage.H2HRewardsUpdate && gs != GameStage.PlayoffCompetitions && gs != GameStage.PlayoffRewards) {
            if (gs > _gs) revert IncorrectGameStageDirectionChange();
        } else {
            if (!(_gs == GameStage.WaitingNextGame || _gs == GameStage.UserAdding)) revert IncorrectGameStageChange();
        }

        gameStage = _gs;
        emit GameStageMovedTo(_gs);
    }

    // Moves this contract to next season
    function closeSeason() internal {
        emit SeasonFinished(seasonId.current());
        seasonId.increment();
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

interface ILeaguePassNFT {
    function updateSeasonId() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITeamManager {
    function setCurrentGameStartTime(uint256 _timestamp) external;

    function setUserDivisionId(address _user, uint256 _divisionId) external;

    function calcTeamScoreForTwoUsers(address _firstUser, address _secondUser) external view returns (uint256, uint256);

    function updateSeasonId() external;
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