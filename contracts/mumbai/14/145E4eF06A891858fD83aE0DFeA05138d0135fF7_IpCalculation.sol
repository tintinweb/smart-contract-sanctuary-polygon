// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IpFakeEnetScore} from "./IpFakeEnetScore.sol";

/*
 * @title A consumer contract for Enetscores.
 * @author Perrin GRANDNE from Irruption Lab.
 * @notice Interact with the daily events API.
 * @dev Uses @chainlink/contracts 0.4.2.
 */
contract IpCalculation is IpFakeEnetScore {

    struct Gain {
        address player;
        uint256 score;
        uint256 rankExAequo;
        uint256 rewardNoExAequo;
        uint256 cumulatedRewardsNoExAequo;
        uint256 cumulatedRewardsPerRank;
        uint256 rewardPerRankPerPlayer;     
    }

    struct Rank {
        address player;
        uint256 score;
        uint256 rankExAequo;
    }

    struct PlayerScoreTicket {
        address player;
        uint256 nbTickets;
        uint256 score;
    }

    struct PlayerScore {
        address player;
        uint256 score;
    }

    struct ContestResult {
        address player;
        uint256 nbTickets;
        uint256 score;
        uint256 rankExAequo;
        uint256 rewardPerRankPerPlayer;     
    }

    uint256 prizePool; 
    uint256 gainPercentage;
    mapping (uint256 => ContestResult[]) public contestTable;

    mapping (uint256 => uint256) nbTotalTicketsPerContest;
    
    constructor() {
        prizePool = 1758;
        gainPercentage = 5;
        nbTotalTicketsPerContest[1] = 25;
    }


    function getScoreTable(uint256 _contestId) public view returns(PlayerScoreTicket[] memory) {
        uint256 nbPlayers = IpFakeEnetScore.listPlayersPerContest[_contestId].length;
        address player;
        PlayerScoreTicket[] memory scoreTable = new PlayerScoreTicket[](nbPlayers);
        uint256 scorePlayer; 
        for (uint256 i=0; i < nbPlayers; i++) {
            player = listPlayersPerContest[_contestId][i];
            scorePlayer = IpFakeEnetScore.checkResult(_contestId, player);
            scoreTable[i] = PlayerScoreTicket({
            player: player,
            nbTickets: 1,
            score: scorePlayer
        });
        }
        return scoreTable;

    }

    function calculateGain(uint _contestId, PlayerScoreTicket[] memory _scoreTable) public view returns (Gain[] memory){
        uint256 ranking;
        uint256 lastRanking;
        uint256 cumulatedRewardsNoExAequo = 0;
        uint256 nbExAequo;
        uint256 rewardNoExAequo;
        uint256 indexTable = 0;
        uint256 nbTotalTickets = nbTotalTicketsPerContest[_contestId];
        PlayerScore[] memory scoreTablePerTicket = new PlayerScore[](nbTotalTickets);
        Rank[] memory rankTable = new Rank[](nbTotalTickets);
        Gain[] memory gainTable = new Gain[](nbTotalTickets);
        for (uint256 i=0; i < _scoreTable.length; i++) {
            PlayerScoreTicket memory tempPlayerScore = _scoreTable[i];
            for (uint256 j=0; j < tempPlayerScore.nbTickets; j++) {
                scoreTablePerTicket[indexTable] = PlayerScore({
                    player: tempPlayerScore.player,
                    score: tempPlayerScore.score
                });
                indexTable ++;
            }
        }
        for (uint256 i=0; i < nbTotalTickets; i++) {
            ranking = 1;
            for (uint256 j=0; j < nbTotalTickets; j++) {
                if (scoreTablePerTicket[i].score < scoreTablePerTicket[j].score) {
                ranking++;
                if (ranking > lastRanking) {
                    lastRanking = ranking;
                }
                }
            }
            rankTable[i] = Rank({
                player: scoreTablePerTicket[i].player,
                score: scoreTablePerTicket[i].score,
                rankExAequo: ranking
            });
        }
        indexTable = 0;
        for (uint256 i=1; i <= lastRanking; i++) {
            for (uint256 j=0; j < nbTotalTickets; j++) {
                if (rankTable[j].rankExAequo == i) {
                    gainTable[indexTable] = (Gain({
                        player: rankTable[j].player,
                        score: rankTable[j].score,
                        rankExAequo: rankTable[j].rankExAequo,
                        rewardNoExAequo: 0,
                        cumulatedRewardsNoExAequo: 0,
                        cumulatedRewardsPerRank: 0,
                        rewardPerRankPerPlayer: 0
                }));
                indexTable ++;
                }
            }
        }
        /// Inititate the table with the first row
        rewardNoExAequo = (prizePool - cumulatedRewardsNoExAequo) * gainPercentage / 100;
        cumulatedRewardsNoExAequo += rewardNoExAequo;
        gainTable[0].rewardNoExAequo = rewardNoExAequo;
        gainTable[0].cumulatedRewardsNoExAequo = rewardNoExAequo;
        gainTable[0].cumulatedRewardsPerRank = rewardNoExAequo;
        gainTable[0].rewardPerRankPerPlayer = rewardNoExAequo;
        for(uint256 m=1; m < nbTotalTickets; m++) {
            rewardNoExAequo = (prizePool - cumulatedRewardsNoExAequo) * gainPercentage / 100;
            gainTable[m].rewardNoExAequo = rewardNoExAequo;
            cumulatedRewardsNoExAequo += rewardNoExAequo;
            gainTable[m].cumulatedRewardsNoExAequo = cumulatedRewardsNoExAequo;
            if (m != (nbTotalTickets-1)) {
                if (gainTable[m].rankExAequo == gainTable[m-1].rankExAequo) {
                    gainTable[m].cumulatedRewardsPerRank = gainTable[m-1].cumulatedRewardsPerRank + rewardNoExAequo;
                } else {
                    gainTable[m].cumulatedRewardsPerRank = rewardNoExAequo;
                    gainTable[m].rewardPerRankPerPlayer = rewardNoExAequo;
                    nbExAequo = gainTable[m].rankExAequo - gainTable[m-1].rankExAequo;
                    for (uint n=0; n < nbExAequo; n++) {
                        gainTable[m-(n+1)].rewardPerRankPerPlayer = (gainTable[m-1].cumulatedRewardsPerRank /nbExAequo);
                    }
                }
            } else {
                if (gainTable[m].rankExAequo == gainTable[m-1].rankExAequo) {
                    gainTable[m].cumulatedRewardsPerRank = gainTable[m-1].cumulatedRewardsPerRank + rewardNoExAequo;
                    nbExAequo = nbTotalTickets + 1 - gainTable[m].rankExAequo;
                    for (uint n=0; n < nbExAequo; n++) {
                    gainTable[m-n].rewardPerRankPerPlayer = (gainTable[m].cumulatedRewardsPerRank /nbExAequo);
                    }
                } else {
                    gainTable[m].cumulatedRewardsPerRank = rewardNoExAequo;
                    gainTable[m].rewardPerRankPerPlayer = rewardNoExAequo;
                }
            }
        }
        return gainTable;
    }

    function updateContestTable(uint _contestId) public {
        PlayerScoreTicket[] memory scoreTable = getScoreTable(_contestId);
        Gain[] memory gainTable = calculateGain(_contestId, scoreTable);
        uint256 indexTable = 0;
        /// Inititate the table with the first row
        contestTable[_contestId].push(ContestResult({
                player: gainTable[0].player,
                nbTickets: 1,
                score: gainTable[0].score,
                rankExAequo: gainTable[0].rankExAequo,
                rewardPerRankPerPlayer: gainTable[0].rewardPerRankPerPlayer
        }));
        for (uint i=1; i < nbTotalTicketsPerContest[_contestId]; i++) {
            if (gainTable[i].player == gainTable[i-1].player) {
                contestTable[_contestId][indexTable].nbTickets ++;
                contestTable[_contestId][indexTable].rewardPerRankPerPlayer += gainTable[i].rewardPerRankPerPlayer;
            } else {
                contestTable[_contestId].push(ContestResult({
                    player: gainTable[i].player,
                    nbTickets: 1,
                    score: gainTable[i].score,
                    rankExAequo: gainTable[i].rankExAequo,
                    rewardPerRankPerPlayer: gainTable[i].rewardPerRankPerPlayer
                    }));
                indexTable ++;
            }
        }
    }

    function getContestTable(uint256 _contestId) public view returns (ContestResult[] memory) {
        return contestTable[_contestId];
    }
}

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
    mapping(uint256 => address[]) internal listPlayersPerContest;

    // @notice specId = jobId from https://market.link/nodes/Enetscores/integrations
    bytes32 private specId;
    // @notice amount of Link for Oracle
    uint256 private payment;
    uint256 private currentContestId;

    mapping(uint32 => bool) gamePlayed;

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
            gamePlayed[_fakeGameResolve[i].gameId] = true;
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
            if (
                gameResultPlayer == gameResultOracle &&
                gamePlayed[gameId] == true
            ) {
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