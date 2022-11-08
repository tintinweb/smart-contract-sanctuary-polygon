// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/*
 * @title A consumer contract for Enetscores.
 * @author Perrin GRANDNE from Irruption Lab.
 * @notice Interact with the daily events API.
 * @dev Uses @chainlink/contracts 0.4.2.
 */
contract IpFakeEnetScore {
    // @notice structure for the creation of a game to predict
    struct GameCreate {
        uint32 gameId;
        uint40 startTime;
        string homeTeam;
        string awayTeam;
    }

    // @notice structure for the Oracle resolution of predicted game
    struct GameResolve {
        uint32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        string status;
    }

    // @notice structure for scores from a game
    struct Scores {
        uint8 homeScore;
        uint8 awayScore;
    }

    // @notice structure for data received from the front end, predictions from a player
    struct GamePredict {
        uint32 gameId;
        uint8 homeScore;
        uint8 awayScore;
    }

    // @notice structure for id league and end of contest for each contest
    struct ContestInfo {
        uint256 leagueId;
        uint256 dateEnd;
    }

    // @notice association between request id and data
    mapping(string => GameCreate[]) private requestIdGames;

    //@notice association between array of requests and contest
    mapping(uint256 => string[]) private listRequestsPerContest;

    // @notice assocation between contest info and contest
    mapping(uint256 => ContestInfo) private infoContest;

    // @notice use struct Score for a game id
    mapping(uint32 => Scores) private scoresPerGameId;

    // @notice use struct Score for all game id predicted for a contest by a player
    mapping(address => mapping(uint256 => mapping(uint32 => Scores)))
        private predictionsPerPlayerPerContest;

    // @notice list of all playesr who participate to the contest
    mapping(uint256 => address[]) private listPlayersPerContest;

    // @notice specId = jobId from https://market.link/nodes/Enetscores/integrations
    bytes32 private specId;
    // @notice amount of Link for Oracle
    uint256 private payment;
    uint256 private currentContestId;

    constructor() {
        currentContestId = 0; // initialisation of current contest id
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /*
     * @notice Requests the tournament games either to be created or to be resolved on a specific date.
     * @dev Requests the 'schedule' endpoint. Result is an array of GameCreate or GameResolve encoded (see structs).
     * specId the jobID.
     * payment the LINK amount in Juels (i.e. 10^18 aka 1 LINK).
     * @param _market the number associated with the type of market (see Data Conversions).
     * @param _leagueId the tournament ID.
     * @param _date the starting time of the event as a UNIX timestamp in seconds.
     */

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function getGameCreate(string memory _requestId, uint256 _idx)
        external
        view
        returns (GameCreate memory)
    {
        return requestIdGames[_requestId][_idx];
    }

    /* ========== INTERPOOL WRITE FUNCTIONS ========== */

    function fakeGameCreate(
        string memory _requestId,
        GameCreate[] memory _fakeGameCreate
    ) public {
        for (uint256 i = 0; i < _fakeGameCreate.length; i++) {
            requestIdGames[_requestId].push(
                GameCreate({
                    gameId: _fakeGameCreate[i].gameId,
                    startTime: _fakeGameCreate[i].startTime,
                    homeTeam: _fakeGameCreate[i].homeTeam,
                    awayTeam: _fakeGameCreate[i].awayTeam
                })
            );
        }
    }

    // function fakeGameResolve() public {

    //         struct GameResolve {
    //     uint32 gameId;
    //     uint8 homeScore;
    //     uint8 awayScore;
    //     string status;
    // }

    /*
     * @notice Creation of a Contest : 1667315919 ; 1669907919
     * @param _leagueId: 53 for Ligue 1, 42 Champion's League, 77 World Cup
     * @param _listDates: Array of dates with games for request id*
     * @param _dateEndContest: Timtestamp of the end for saving predictions
     * create a new contest => increment the current contest id
     * schedule all request associated to date and league and save it in listRequestsPerContest
     * add information about the contest in infoContest
     */
    function createContest(
        uint256 _leagueId,
        string[] memory _listRequestId,
        uint256 _dateEndContest
    ) public {
        currentContestId++;
        for (uint256 i = 0; i < _listRequestId.length; i++) {
            listRequestsPerContest[currentContestId].push(_listRequestId[i]);
        }
        infoContest[currentContestId] = ContestInfo({
            leagueId: _leagueId,
            dateEnd: _dateEndContest
        });
    }

    /*
     * @notice Get scores of games when they are finished
     * @param _leagueId: 53 for Ligue 1, 42 Champion's League, 77 World Cup
     * @param _date : date of request to resolve
     * resolve a request => get results of games for a league and a date
     * and save scores in scoresPerGameId
     */
    function saveRequestResults(GameResolve[] memory _fakeGameResolve) public {
        for (uint256 i = 0; i < _fakeGameResolve.length; i++) {
            scoresPerGameId[_fakeGameResolve[i].gameId] = Scores({
                homeScore: _fakeGameResolve[i].homeScore,
                awayScore: _fakeGameResolve[i].awayScore
            });
        }
    }

    /**
     * @notice Save predictions for a player for the current contest
     * @param _gamePredictions: table of games with predicted scores received from the front end
     * Verify the contest is still open and the number of predictions is the expected number
     * Save scores of games in predictionsPerPlayerPerContest
     */
    function savePrediction(GamePredict[] memory _gamePredictions) public {
        require(
            block.timestamp < infoContest[currentContestId].dateEnd,
            "Prediction Period is closed!"
        );
        require(
            _gamePredictions.length ==
                getNumberOfGamesPerContest(currentContestId),
            "The number of predictions doesn't match!"
        );
        uint256 nbOfGames = getNumberOfGamesPerContest(currentContestId);
        for (uint256 i = 0; i < nbOfGames; i++) {
            predictionsPerPlayerPerContest[msg.sender][currentContestId][
                _gamePredictions[i].gameId
            ] = Scores({
                homeScore: _gamePredictions[i].homeScore,
                awayScore: _gamePredictions[i].awayScore
            });
        }
        listPlayersPerContest[currentContestId].push(msg.sender);
    }

    /* ========== INTERPOOL VIEW FUNCTIONS ========== */

    /**
     * @notice Get the number of games for a request id
     * @param _requestId: the id of request to ask
     */
    function getNumberOfGamesPerRequest(string memory _requestId)
        public
        view
        returns (uint)
    {
        return requestIdGames[_requestId].length;
    }

    /**
     * @notice Get the list of requests id for a contest
     * @param _contestId: the id of contest to ask
     */
    function getRequestIdPerContest(uint256 _contestId)
        external
        view
        returns (string[] memory)
    {
        return listRequestsPerContest[_contestId];
    }

    /**
     * @notice Get the number of games for a contest
     * @param _contestId: the id of contest to ask
     */
    function getNumberOfGamesPerContest(uint256 _contestId)
        public
        view
        returns (uint256)
    {
        uint256 nbGames = 0;
        for (
            uint256 i = 0;
            i < listRequestsPerContest[_contestId].length;
            i++
        ) {
            nbGames += requestIdGames[listRequestsPerContest[_contestId][i]]
                .length;
        }
        return nbGames;
    }

    function getScorePerGameId(uint32 _gameId)
        public
        view
        returns (Scores memory)
    {
        return scoresPerGameId[_gameId];
    }

    /**
     * @notice Get the list of games for a contest
     * @param _contestId: the id of contest to ask
     * nbGames is used to agregate all games of all requests from the contest
     * GameCreate[] is used to store all games of all requests with info
     * iGames is used to increment the array GameCreate[]
     */
    function getListGamesPerContest(uint256 _contestId)
        public
        view
        returns (GameCreate[] memory)
    {
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        uint256 iGames;
        GameCreate[] memory listGamesPerContest = new GameCreate[](nbGames);
        for (
            uint256 i = 0;
            i < listRequestsPerContest[_contestId].length;
            i++
        ) {
            nbGames = requestIdGames[listRequestsPerContest[_contestId][i]]
                .length;
            for (uint256 j = 0; j < nbGames; j++) {
                listGamesPerContest[iGames] = requestIdGames[
                    listRequestsPerContest[_contestId][i]
                ][j];
                iGames++;
            }
        }
        return listGamesPerContest;
    }

    /**
     * @notice Get the previsions per Player per Contest
     * @param _contestId: the id of contest to ask
     * @param _player: address of the player
     * Get the number of expected games for the contest,
     * Get the list of all Games for the contest
     * Associate each game id with home score and array score from the player
     */
    function getPrevisionsPerPlayerPerContest(
        uint256 _contestId,
        address _player
    ) public view returns (GamePredict[] memory) {
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        uint32 gameId;
        GamePredict[] memory listPredictionsPerContest = new GamePredict[](
            nbGames
        );
        GameCreate[] memory listGamesPerContest = new GameCreate[](nbGames);
        listGamesPerContest = getListGamesPerContest(_contestId);
        for (uint256 i = 0; i < nbGames; i++) {
            gameId = listGamesPerContest[i].gameId;
            listPredictionsPerContest[i] = GamePredict({
                gameId: gameId,
                homeScore: predictionsPerPlayerPerContest[_player][_contestId][
                    gameId
                ].homeScore,
                awayScore: predictionsPerPlayerPerContest[_player][_contestId][
                    gameId
                ].awayScore
            });
        }
        return listPredictionsPerContest;
    }

    /**
     * @notice Transform scores of home and away to a result of game : 0 = home win, 1 = draw, 2 = away win
     * @param _homeScore: Score from the team A
     * @param _awayScore: Score from the team B
     */
    function calculateMatchResult(uint8 _homeScore, uint8 _awayScore)
        private
        pure
        returns (uint256)
    {
        uint256 gameResult;
        if (_homeScore > _awayScore) {
            gameResult = 0;
        } else if (_awayScore > _homeScore) {
            gameResult = 2;
        } else {
            gameResult = 1;
        }
        return gameResult;
    }

    /**
     * @notice Compare the predictions of a player with results from Oracle for a contest
     * @param _contestId: Contest id for the comparison
     * @param _player: Player which compare his predictions with Oracle results
     */
    function checkResult(uint256 _contestId, address _player)
        public
        view
        returns (uint256)
    {
        uint256 gameResultPlayer; // 0 home win, 1 draw, 2 away win
        uint256 gameResultOracle; // 0 home win, 1 draw, 2 away win
        uint256 playerScoring = 0;
        uint32 gameId;
        uint256 nbGames = getNumberOfGamesPerContest(_contestId);
        GameCreate[] memory listGamesPerContest = new GameCreate[](nbGames);
        listGamesPerContest = getListGamesPerContest(_contestId);
        for (uint256 i = 0; i < nbGames; i++) {
            gameId = listGamesPerContest[i].gameId;
            gameResultPlayer = calculateMatchResult(
                predictionsPerPlayerPerContest[_player][_contestId][gameId]
                    .homeScore,
                predictionsPerPlayerPerContest[_player][_contestId][gameId]
                    .awayScore
            );
            gameResultOracle = calculateMatchResult(
                scoresPerGameId[gameId].homeScore,
                scoresPerGameId[gameId].awayScore
            );
            if (gameResultPlayer == gameResultOracle) {
                playerScoring += 1;
                if (
                    predictionsPerPlayerPerContest[_player][_contestId][gameId]
                        .homeScore ==
                    scoresPerGameId[gameId].homeScore &&
                    predictionsPerPlayerPerContest[_player][_contestId][gameId]
                        .awayScore ==
                    scoresPerGameId[gameId].awayScore
                ) {
                    playerScoring += 2;
                }
            }
        }
        return playerScoring;
    }
}