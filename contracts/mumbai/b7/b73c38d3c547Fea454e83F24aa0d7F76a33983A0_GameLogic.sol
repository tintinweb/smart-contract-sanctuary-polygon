// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

import "./Types.sol";
import "./GameManager.sol";
import "./interfaces/IGameLogic.sol";
import "./interfaces/IChainlinkFunctionConsumer.sol";


// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract GameLogic is IGameLogic, VRFV2WrapperConsumerBase {

    uint constant public NUMBER_OF_TEAMS = 2;
    uint constant public NUMBER_OF_PLAYERS_PER_TEAM = 10;

    uint constant public STAMINA_REQUIREMENT_FOR_ADVANCEMENT = 10;

    uint constant public PLAYER_STEPS_PER_MOVE = 5;
    uint constant public BALL_STEPS_PER_MOVE = 7;
    uint constant public SHOOT_STEPS = 2;

    uint constant public TOTAL_PROGRESSION_STEPS = PLAYER_STEPS_PER_MOVE + BALL_STEPS_PER_MOVE + SHOOT_STEPS;

    uint constant public BITS_PER_PLAYER_X_POS = 10;
    uint constant public BITS_PER_PLAYER_Y_POS = 9;

    uint constant public MAX_BALL_DISTANCE_REQUIRED = 25;

    uint constant public FIELD_W = 2 ** BITS_PER_PLAYER_X_POS;
    uint constant public FIELD_H = 2 ** BITS_PER_PLAYER_Y_POS;

    uint constant public STAMINA_LOSS_PER_STEP = 2;

    bool public gameIsHalted = false;

    address public logic;
    address public ticker;
    address public _sxt;

    uint public matchCounter;

    mapping(uint => Types.MatchInfo) public matchInfo;
    mapping(uint => uint) public seedRequestIdMatchId;
    mapping(uint => uint) public matchIdToMatchStateId;
    mapping(uint => mapping(uint => Types.MatchState)) matchState;
    mapping(uint => mapping(uint => Types.TeamState[])) teamState;
    mapping(uint => mapping(uint => Types.TeamMove[])) public teamMove;
    mapping(uint => mapping(uint => bool)) public stateShouldBeSkipped;

    address public manager;

    event MatchEnteredStage(uint matchId, Types.MATCH_STAGE stage);

    constructor()        
        VRFV2WrapperConsumerBase(
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693
        )  {
        manager = address(new GameManager(address(this)));
        logic = address(this);
    }

    /// @notice Sets the address of the Space and Time (SxT) Function Consumer
    /// @dev This Function consumer should implement IChainlinkFunctionConsumer interface
    /// @param sxt Address of the deployed SxT Function Consumer
    function setSxT(
        address sxt
    ) public {
        _sxt = sxt;
    }

    /// @notice Creates a new match and registers the corresponding Function Consumers
    /// @dev Both Function consumers should implement IChainlinkFunctionConsumer interface
    /// @param team1_commitmentChainlinkFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Commitment Stage
    /// @param team1_revealChainlinkFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Reveal Stage
    function createMatch(
        address team1_commitmentChainlinkFunctionConsumer, 
        address team1_revealChainlinkFunctionConsumer
    ) public {

        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("createMatch(address,address)", team1_commitmentChainlinkFunctionConsumer, team1_revealChainlinkFunctionConsumer));

        require(success, "ERR: createMatch Delegate call failed!");
    }

    /// @notice Joins an already existing Match
    /// @dev Both Function consumers should implement IChainlinkFunctionConsumer interface
    /// @param matchId ID of the Match the User wants to join
    /// @param team2_commitmentChainlinkFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Commitment Stage
    /// @param team2_revealChainlinkFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Reveal Stage
    function joinMatch(
        uint matchId,
        address team2_commitmentChainlinkFunctionConsumer, 
        address team2_revealChainlinkFunctionConsumer
    ) public {

        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("joinMatch(uint256,address,address)", matchId, team2_commitmentChainlinkFunctionConsumer, team2_revealChainlinkFunctionConsumer));

        require(success, "ERR: joinMatch Delegate call failed!");
    }


    function testRequestRandom () public {
        requestRandomness(100000, 3, 1);
    }
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint matchId = seedRequestIdMatchId[_requestId];

        Types.MatchInfo storage currMatch = matchInfo[matchId];

        currMatch.seed = _randomWords[0];

        currMatch.stage = Types.MATCH_STAGE.RANDOM_SEED_RECEIVED;

        emit MatchEnteredStage(seedRequestIdMatchId[_requestId], currMatch.stage);
    }

    /// @notice Initiates the start of Commitment Stage
    /// @dev Calls Commitment Function Consumers for both teams
    /// @param matchId ID of the Match    function commitmentTick(uint matchId) public {
    function commitmentTick(uint matchId) public {
        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("commitmentTick(uint256)", matchId));

        require(success, "ERR: commitmentTick Delegate call failed!");
    }

    /// @notice Ends the Commitment Stage and copies the underlying data
    /// @dev Request for both Commitments has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateCommitmentInfo(uint matchId) public {

        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("updateCommitmentInfo(uint256)", matchId));

        require(success, "ERR: updateCommitmentInfo Delegate call failed!");
    }

    /// @notice Initiates the start of Reveal Stage
    /// @dev Calls Reveal Function Consumers for both teams
    /// @param matchId ID of the Match
    function revealTick(uint matchId) public {

        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("revealTick(uint256)", matchId));

        require(success, "ERR: revealTick Delegate call failed!");
    }

    /// @notice Ends the Reveal Stage and copies the underlying data
    /// @dev Request for both Reveal has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateRevealInfo(uint matchId) public {
       
        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("updateRevealInfo(uint256)", matchId));

        require(success, "ERR: updateRevealInfo Delegate call failed!");
    }

    /// @notice Initiates the start of State Update Stage
    /// @dev Calls SxT Function Consumer
    /// @param matchId ID of the Match
    function stateUpdateTick(uint matchId) public {

        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("stateUpdateTick(uint256)", matchId));

        require(success, "ERR: stateUpdateTick Delegate call failed!");
    }

    /// @notice Ends the State Update Stage and unpacks the received data
    /// @dev Request for State Update has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateStateUpdateInfo(uint matchId) public {
       
        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("updateStateUpdateInfo(uint256)", matchId));

        require(success, "ERR: updateStateUpdateInfo Delegate call failed!");
    }

    /// @notice On-chain execution of the State transition
    /// @dev Used when there's no reporting by SxT because costs a hell of gas :)
    /// @param matchId ID of the Match
    function stateUpdate(uint matchId) public {
       
        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("stateUpdate(uint256)", matchId));

        require(success, "ERR: stateUpdate Delegate call failed!");
    }

    /// @notice Checks whether the reported State is correct
    /// @dev If the dispute is justified and there's a discrepancy the game is completly halted
    /// @param matchId ID of the Match
    /// @param stateId ID of the State after which there's a discrepancy
    function dispute(uint matchId, uint stateId) public {
       
        (bool success, bytes memory data) = manager.delegatecall(
            abi.encodeWithSignature("dispute(uint256,uint256)", matchId, stateId));

        require(success, "ERR: dispute Delegate call failed!");
    }

    /// @notice Generates the next Match State and all of the States in between
    /// @dev Used by .stateUpdate and .dispute
    /// @param matchId ID of the Match
    /// @param stateId ID of the previous State
    /// @return progression A series of intermediate (and final) states
    function getProgression(
        uint matchId,
        uint stateId
    ) public view returns (
        Types.ProgressionState[] memory progression
    ){
        bool shortCircuit = false; //stateShouldBeSkipped[matchId][stateId];

        Types.TeamState[] storage s_initialTeamState = teamState[matchId][stateId];
        Types.TeamState[] memory finalTeamState = teamState[matchId][stateId+1];
        Types.TeamState[] memory initialTeamState = s_initialTeamState;
        
        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            initialTeamState[teamId].playerStats = new Types.PlayerStats[](NUMBER_OF_PLAYERS_PER_TEAM);

            for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                initialTeamState[teamId].playerStats[playerId] = s_initialTeamState[teamId].playerStats[playerId];
                initialTeamState[teamId].xPos[playerId] = s_initialTeamState[teamId].xPos[playerId];
                initialTeamState[teamId].yPos[playerId] = s_initialTeamState[teamId].yPos[playerId];
            }
        }

        Types.TeamMove[] storage s_currTeamMove = teamMove[matchId][stateId];
        Types.TeamMove[] memory currTeamMove = s_currTeamMove;
        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                currTeamMove[teamId].xPos[playerId] = s_currTeamMove[teamId].xPos[playerId];
                currTeamMove[teamId].yPos[playerId] = s_currTeamMove[teamId].yPos[playerId];
            }
        }

        progression = new Types.ProgressionState[](
            TOTAL_PROGRESSION_STEPS
        );

        uint stepId = 0;
        for(; stepId < TOTAL_PROGRESSION_STEPS; ++stepId){

            Types.ProgressionState memory currProgressionState = progression[stepId];
            
            currProgressionState.teamState = new Types.TeamState[](NUMBER_OF_TEAMS);
            for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
                Types.TeamState memory currTeamState = currProgressionState.teamState[teamId];
                currTeamState.playerStats = new Types.PlayerStats[](NUMBER_OF_PLAYERS_PER_TEAM);
                currTeamState.xPos = new uint[](NUMBER_OF_PLAYERS_PER_TEAM);
                currTeamState.yPos = new uint[](NUMBER_OF_PLAYERS_PER_TEAM);
            }

            if(stepId == 0){
                currProgressionState.teamState = initialTeamState;
                currProgressionState.teamIdWithTheBall = matchState[matchId][stateId].teamIdWithTheBall;
                currProgressionState.playerIdWithTheBall = matchState[matchId][stateId].playerIdWithTheBall;
                currProgressionState.ballXPos = matchState[matchId][stateId].ballXPos;
                currProgressionState.ballYPos = matchState[matchId][stateId].ballYPos;
                // currProgressionState.shotWasTaken = matchState[matchId][stateId].shotWasTaken;
                // currProgressionState.goalWasScored = matchState[matchId][stateId].goalWasScored;
                currProgressionState = _copyBallPositionFromBallHolder(currProgressionState);
                continue;
            }

            Types.ProgressionState memory prevProgressionState = progression[stepId-1];

            currProgressionState.startingTeamIdWithTheBall = prevProgressionState.startingTeamIdWithTheBall;
            currProgressionState.startingPlayerIdWithTheBall = prevProgressionState.startingPlayerIdWithTheBall;
            currProgressionState.teamIdWithTheBall = prevProgressionState.teamIdWithTheBall;
            currProgressionState.playerIdWithTheBall = prevProgressionState.playerIdWithTheBall;
            currProgressionState.ballWasWon = prevProgressionState.ballWasWon;
            currProgressionState.ballWasWonByTeam = prevProgressionState.ballWasWonByTeam;
            currProgressionState.interceptionOccured = prevProgressionState.interceptionOccured;
            currProgressionState.interceptionAchievedByTeam = prevProgressionState.interceptionAchievedByTeam;
            currProgressionState.ballXPos = prevProgressionState.ballXPos;
            currProgressionState.ballYPos = prevProgressionState.ballYPos;

            for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
                currProgressionState.teamState[teamId].playerStats = new Types.PlayerStats[](NUMBER_OF_PLAYERS_PER_TEAM);

                for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                    currProgressionState.teamState[teamId].playerStats[playerId] = prevProgressionState.teamState[teamId].playerStats[playerId];
                    currProgressionState.teamState[teamId].xPos[playerId] = prevProgressionState.teamState[teamId].xPos[playerId];
                    currProgressionState.teamState[teamId].yPos[playerId] = prevProgressionState.teamState[teamId].yPos[playerId];
                }
            }

            if(shortCircuit == false){
                if(stepId < PLAYER_STEPS_PER_MOVE){
                    for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
                        for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                            currProgressionState = _advancePlayerPosition(
                                initialTeamState,
                                currTeamMove, 
                                teamId, 
                                playerId,
                                prevProgressionState, 
                                currProgressionState, 
                                stepId
                            );
                        }
                    }
                    currProgressionState = _copyBallPositionFromBallHolder(currProgressionState);
                    
                    currProgressionState =_fightForBall(currProgressionState);
                } else if(stepId < PLAYER_STEPS_PER_MOVE + BALL_STEPS_PER_MOVE) {
                    if( currProgressionState.interceptionOccured == false
                        && currProgressionState.teamIdWithTheBall == progression[0].teamIdWithTheBall){
                        currProgressionState = _advanceBallPassPosition(
                            progression[PLAYER_STEPS_PER_MOVE-1],
                            progression[0].teamIdWithTheBall,
                            currTeamMove,
                            prevProgressionState,
                            currProgressionState,
                            1 + stepId - PLAYER_STEPS_PER_MOVE
                        );
                    }
                }
            }
        }

        Types.ProgressionState memory lastProgressionStateBeforeShoot = progression[progression.length-1-SHOOT_STEPS];
        Types.ProgressionState memory goalKeeperProgressionState = progression[progression.length-2];
        Types.ProgressionState memory finalProgressionState = progression[progression.length-1];

        if(currTeamMove[lastProgressionStateBeforeShoot.teamIdWithTheBall].wantToShoot){
            lastProgressionStateBeforeShoot.shotWasTaken 
                = goalKeeperProgressionState.shotWasTaken
                = finalProgressionState.shotWasTaken
                = true;
            lastProgressionStateBeforeShoot.teamIdOfTheGoalWhereTheShootWasTaken = 1 - lastProgressionStateBeforeShoot.teamIdWithTheBall;

            goalKeeperProgressionState.ballXPos = (lastProgressionStateBeforeShoot.teamIdWithTheBall == 0) ? FIELD_W : 0;
            goalKeeperProgressionState.ballYPos = FIELD_H / 2;

            finalProgressionState.goalWasScored = _shootScores(lastProgressionStateBeforeShoot);
            finalProgressionState.teamIdWithTheBall 
                // = goalKeeperProgressionState.teamIdWithTheBall 
                = 1 - lastProgressionStateBeforeShoot.teamIdWithTheBall;

            if(finalProgressionState.goalWasScored){
                finalProgressionState.ballXPos = FIELD_W / 2;
                finalProgressionState.ballYPos = FIELD_H / 2;
                finalProgressionState.playerIdWithTheBall = 2;
            } else {
                uint receivingPlayerId = 5;
                finalProgressionState.ballXPos = 
                    finalProgressionState.teamState[1 - lastProgressionStateBeforeShoot.teamIdWithTheBall]
                    .xPos[receivingPlayerId];
                finalProgressionState.ballYPos = 
                    finalProgressionState.teamState[1 - lastProgressionStateBeforeShoot.teamIdWithTheBall]
                    .yPos[receivingPlayerId];
                finalProgressionState.playerIdWithTheBall = receivingPlayerId;
            }
        }
    }

    /// @notice Internal method that Advances the Player's position for one step
    /// @param initialTeamState Inital State from which the Player will be moving
    /// @param wantedMove Where the Player 'wants' to move to
    /// @param teamId ID of the team the Player belongs to
    /// @param playerId Player's ID
    /// @param prevState From Where the Player is Moving
    /// @param nextState Where the Player  will end up
    /// @param stepId ID of the current Progression Step
    /// @return Updated State
    function _advancePlayerPosition(
        Types.TeamState[] memory initialTeamState,
        Types.TeamMove[] memory wantedMove,
        uint teamId,
        uint playerId,
        Types.ProgressionState memory prevState,
        Types.ProgressionState memory nextState,
        uint stepId
    ) internal view returns (Types.ProgressionState memory) {

        uint[2] memory wantedPos = [ 
            wantedMove[teamId].xPos[playerId], 
            wantedMove[teamId].yPos[playerId] 
        ];

        uint[2] memory initialPos = [
            initialTeamState[teamId].xPos[playerId],
            initialTeamState[teamId].yPos[playerId]
        ];

        uint[2] memory currPos = [
            prevState.teamState[teamId].xPos[playerId],
            prevState.teamState[teamId].yPos[playerId]
        ];


        if(currPos[0] == wantedPos[0] && currPos[1] == currPos[1]){
            return nextState;
        }

        int[2] memory diff = [
            int(wantedPos[0]) - int(initialPos[0]),
            int(wantedPos[1]) - int(initialPos[1])
        ];

        uint distance = uint(diff[0]*diff[0] + diff[1]*diff[1]);

        Types.PlayerStats memory currPlayerStats = 
            prevState.teamState[teamId].playerStats[playerId];

        if(true
            // currPlayerStats.stamina >= STAMINA_LOSS_PER_STEP
            //&& currPlayerStats.speed * PLAYER_STEPS_PER_MOVE >= distance
        ){
            uint[2] memory newPos = [
                diff[0] > 0 ? 
                    (currPos[0] + (wantedPos[0] - initialPos[0]) / PLAYER_STEPS_PER_MOVE)
                    :(currPos[0] - (initialPos[0] - wantedPos[0]) / PLAYER_STEPS_PER_MOVE),
                diff[1] > 0 ? 
                    (currPos[1] + (wantedPos[1] - initialPos[1]) / PLAYER_STEPS_PER_MOVE)
                    :(currPos[1] - (initialPos[1] - wantedPos[1]) / PLAYER_STEPS_PER_MOVE)
            ];

            if(stepId == PLAYER_STEPS_PER_MOVE){
                newPos[0] = wantedPos[0];
                newPos[1] = wantedPos[1];
            }

            if(newPos[0] < FIELD_W && newPos[1] < FIELD_H){
                //player can move
                nextState.teamState[teamId].xPos[playerId] = newPos[0];
                nextState.teamState[teamId].yPos[playerId] = newPos[1];
                nextState.teamState[teamId].playerStats[playerId].stamina = 
                    (nextState.teamState[teamId].playerStats[playerId].stamina > STAMINA_LOSS_PER_STEP) ?
                    nextState.teamState[teamId].playerStats[playerId].stamina - STAMINA_LOSS_PER_STEP:
                    STAMINA_LOSS_PER_STEP;
                // console.log("newPos: %s %s", newPos[0], newPos[1]);
            }
        }

        return nextState;
    }

    /// @notice Internal method that Advances the Ball's position while it's being passed
    /// @param initialState Inital State from which the Player will be moving
    /// @param wantedMove Where the Player 'wants' to move to
    /// @param teamId ID of the team the Player belongs to
    /// @param prevState From Where the Player is Moving
    /// @param nextState Where the Player  will end up
    /// @param stepId ID of the current Progression Step
    /// @return Updated State
    function _advanceBallPassPosition(
        Types.ProgressionState memory initialState,
        uint teamId,
        Types.TeamMove[] memory wantedMove,
        Types.ProgressionState memory prevState,
        Types.ProgressionState memory nextState,
        uint stepId
    ) internal view returns (
        Types.ProgressionState memory
    ) {

        uint[2] memory wantedPos = [ 
            initialState.teamState[teamId].xPos[wantedMove[teamId].receivingPlayerId], 
            initialState.teamState[teamId].yPos[wantedMove[teamId].receivingPlayerId]
        ];

        uint[2] memory initialPos = [
            initialState.ballXPos,
            initialState.ballYPos
        ];

        uint[2] memory currPos = [
            prevState.ballXPos,
            prevState.ballYPos
        ];

        if(currPos[0] == wantedPos[0] && currPos[1] == currPos[1]){
            nextState.ballXPos = wantedPos[0];
            nextState.ballYPos = wantedPos[1];
            return nextState;
        }

        int[2] memory diff = [
            int(wantedPos[0]) - int(initialPos[0]),
            int(wantedPos[1]) - int(initialPos[1])
        ];

        uint[2] memory newPos = [
            diff[0] > 0 ? 
                (currPos[0] + (wantedPos[0] - initialPos[0]) / BALL_STEPS_PER_MOVE)
                :(currPos[0] - (initialPos[0] - wantedPos[0]) / BALL_STEPS_PER_MOVE),
            diff[1] > 0 ? 
                (currPos[1] + (wantedPos[1] - initialPos[1]) / BALL_STEPS_PER_MOVE)
                :(currPos[1] - (initialPos[1] - wantedPos[1]) / BALL_STEPS_PER_MOVE)
        ];


        if(stepId == BALL_STEPS_PER_MOVE){
            newPos[0] = wantedPos[0];
            newPos[1] = wantedPos[1];
        }

        if(newPos[0] < FIELD_W && newPos[1] < FIELD_H){
            nextState.ballXPos = newPos[0];
            nextState.ballYPos = newPos[1];
        }

        return _checkForInterceptions(initialState, teamId, wantedMove, prevState, nextState, stepId);
    }

    function _checkForInterceptions (
        Types.ProgressionState memory initialState,
        uint teamId,
        Types.TeamMove[] memory wantedMove,
        Types.ProgressionState memory prevState,
        Types.ProgressionState memory nextState,
        uint stepId
    ) internal view returns (
        Types.ProgressionState memory
    ) {
        uint oposingTeamId = 1 - initialState.teamIdWithTheBall;
        for(uint oposingPlayerId = 0; oposingPlayerId < NUMBER_OF_PLAYERS_PER_TEAM; ++oposingPlayerId){
            
            if(
                _sqrDistanceBetweenBallAndPlayer(
                    nextState,
                    oposingTeamId, 
                    oposingPlayerId
                ) < MAX_BALL_DISTANCE_REQUIRED
            ) {
                (uint winningTeamId, uint winningPlayerId) =_whoWinsTheDuel(
                    initialState,
                    initialState.teamIdWithTheBall,
                    initialState.startingPlayerIdWithTheBall,
                    oposingTeamId,
                    oposingPlayerId
                );
                if(winningTeamId != initialState.teamIdWithTheBall) {
                    //ball has been intecepted
                    nextState.interceptionOccured = true;
                    nextState.interceptionAchievedByTeam = oposingTeamId;
                    nextState.teamIdWithTheBall = winningTeamId;
                    nextState.playerIdWithTheBall = winningPlayerId;
                    nextState.startingTeamIdWithTheBall = teamId;
                    nextState.startingPlayerIdWithTheBall = initialState.startingPlayerIdWithTheBall;
                    // console.log("INTERCEPTION OCCURED %s", stepId);
                    // require(false, "YEAH MOFO");
                    break;
                }
            }
        }

        if(nextState.interceptionOccured == false){
            nextState.teamIdWithTheBall = teamId;
            nextState.playerIdWithTheBall = wantedMove[teamId].receivingPlayerId;
            nextState.startingTeamIdWithTheBall = teamId;
        }

        return nextState;
    }

    /// @notice Internal method that Copies the Ball's position from the Player that has it
    /// @param currState Current State
    /// @return Updated State
    function _copyBallPositionFromBallHolder(
        Types.ProgressionState memory currState
    ) internal view returns (
        Types.ProgressionState memory
    ) {

        Types.TeamState memory tState = currState.teamState[currState.teamIdWithTheBall];

        currState.ballXPos = tState.xPos[currState.playerIdWithTheBall];
        currState.ballYPos = tState.yPos[currState.playerIdWithTheBall];

        return currState;
    }

    /// @notice Internal method that determines who wins the ball in duels
    /// @param currState Current State
    /// @return Updated State
    function _fightForBall(
        Types.ProgressionState memory currState
    ) internal view returns (
        Types.ProgressionState memory
    ) {
        uint teamId = currState.teamIdWithTheBall;
        uint startingPlayerIdWithTheBall = currState.playerIdWithTheBall;

        uint oposingTeamId = 1 - teamId;


        for(uint oposingPlayerId = 0; oposingPlayerId < NUMBER_OF_PLAYERS_PER_TEAM; ++oposingPlayerId){
            if(
                _sqrDistanceBetweenPlayers(
                    currState,
                    teamId,
                    startingPlayerIdWithTheBall, 
                    oposingTeamId, 
                    oposingPlayerId
                ) < MAX_BALL_DISTANCE_REQUIRED
            ) {
                (uint winningTeamId, uint winningPlayerId) =_whoWinsTheDuel(
                    currState,
                    currState.teamIdWithTheBall,
                    startingPlayerIdWithTheBall,
                    oposingTeamId,
                    oposingPlayerId
                );
                if(winningTeamId != currState.teamIdWithTheBall) {
                    //ball has been won
                    currState.ballWasWon = true;
                    currState.ballWasWonByTeam = oposingTeamId;
                    currState.playerIdWithTheBall = winningPlayerId;
                    currState.startingTeamIdWithTheBall = teamId;
                    currState.startingPlayerIdWithTheBall = startingPlayerIdWithTheBall;
                    break;
                }
            }
        }

        return currState;
    }
    /// @notice Internal method that determines the squared distance between a player and a ball
    /// @param currState Current State
    /// @param oposingTeamId Player's Team ID
    /// @param oposingPlayerId Player's ID
    /// @return distance (squared)
    function _sqrDistanceBetweenBallAndPlayer(
        Types.ProgressionState memory currState,
        uint oposingTeamId,
        uint oposingPlayerId
    ) internal view returns (
        uint distance
    ) {
        Types.TeamState memory tState = currState.teamState[oposingTeamId];
        
        uint xDist = 
            currState.ballXPos > tState.xPos[oposingPlayerId] ?
            currState.ballXPos - tState.xPos[oposingPlayerId] :
            tState.xPos[oposingPlayerId] - currState.ballXPos ;

        uint yDist = 
            currState.ballYPos > tState.yPos[oposingPlayerId] ?
            currState.ballYPos - tState.yPos[oposingPlayerId] :
            tState.yPos[oposingPlayerId] - currState.ballYPos ;

        distance = xDist ** 2 + yDist ** 2;
    }
    /// @notice Internal method that determines the squared distance between a player and a ball
    /// @param currState Current State
    /// @param teamId Player's Team ID
    /// @param playerId Player's ID
    /// @param oposingTeamId Opossing Player's Team ID
    /// @param oposingPlayerId Opossing Player's ID
    /// @return distance (squared)
    function _sqrDistanceBetweenPlayers(
        Types.ProgressionState memory currState,
        uint teamId,
        uint playerId,
        uint oposingTeamId,
        uint oposingPlayerId
    ) internal view returns (
        uint distance
    ) {

        Types.TeamState memory tState1 = currState.teamState[teamId];
        Types.TeamState memory tState2 = currState.teamState[oposingTeamId];
        
        uint xDist = 
            tState1.xPos[playerId] > tState2.xPos[oposingPlayerId] ?
            tState1.xPos[playerId] - tState2.xPos[oposingPlayerId] :
            tState2.xPos[oposingPlayerId] - tState1.xPos[playerId] ;

        uint yDist = 
            tState1.yPos[playerId] > tState2.yPos[oposingPlayerId] ?
            tState1.yPos[playerId] - tState2.yPos[oposingPlayerId] :
            tState2.yPos[oposingPlayerId] - tState1.yPos[playerId] ;

        distance = xDist ** 2 + yDist ** 2;
    }

    /// @notice Internal method that determines who wins a duel
    /// @param currState Current State
    /// @param teamId Player's Team ID
    /// @param playerId Player's ID
    /// @param oposingTeamId Opossing Player's Team ID
    /// @param oposingPlayerId Opossing Player's ID
    /// @return winningTeamId ID of the Winning Team 
    /// @return winningPlayerId ID of the Winning Player 
    function _whoWinsTheDuel(
        Types.ProgressionState memory currState,
        uint teamId,
        uint playerId,
        uint oposingTeamId,
        uint oposingPlayerId
    ) internal view returns (
        uint winningTeamId,
        uint winningPlayerId
    ) {
        uint totalSkill = 
            currState.teamState[teamId].playerStats[playerId].skill
            + currState.teamState[teamId].playerStats[playerId].skill + 1;

        uint rnd = _getCurrSeed();
        if(currState.teamState[teamId].playerStats[playerId].skill < (rnd % totalSkill)){
            winningTeamId = teamId;
            winningPlayerId = playerId;
        } else {
            winningTeamId = oposingTeamId;
            winningPlayerId = oposingPlayerId;
        }
    }
    /// @notice Internal method that determines if a shoot leads to a goal
    /// @param currState Current State
    /// @return scored Goal or no Goal
    function _shootScores(
        Types.ProgressionState memory currState
    ) internal view returns (
        bool scored
    ) {
        uint playerSkill = currState.teamState[currState.teamIdWithTheBall]
                                    .playerStats[currState.playerIdWithTheBall]
                                    .skill;

        uint goalKeeperSkill = currState.teamState[1-currState.teamIdWithTheBall]
                                    .goalKeeperStats
                                    .skill;

         uint totalSkill = playerSkill + goalKeeperSkill;

        uint rnd = _getCurrSeed();
        return true;
        if(playerSkill < (rnd % totalSkill)){
            return true;
        } else {
            return false;
        }
    }

    function _getCurrSeed() internal view returns (uint) {
        return 1301;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

import "./Types.sol";
import "./interfaces/IGameLogic.sol";
import "./interfaces/IChainlinkFunctionConsumer.sol";


// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract GameManager is VRFV2WrapperConsumerBase {

    uint constant public NUMBER_OF_TEAMS = 2;
    uint constant public NUMBER_OF_PLAYERS_PER_TEAM = 10;

    uint constant public STAMINA_REQUIREMENT_FOR_ADVANCEMENT = 10;
    uint constant public PLAYER_STEPS_PER_MOVE = 5;
    uint constant public BALL_STEPS_PER_MOVE = 7;
    uint constant public SHOOT_STEPS = 2;

    uint constant public TOTAL_PROGRESSION_STEPS = PLAYER_STEPS_PER_MOVE + BALL_STEPS_PER_MOVE + SHOOT_STEPS;

    uint constant public BITS_PER_PLAYER_X_POS = 10;
    uint constant public BITS_PER_PLAYER_Y_POS = 9;

    uint constant public MAX_BALL_DISTANCE_REQUIRED = 25;

    uint constant public FIELD_W = 2 ** BITS_PER_PLAYER_X_POS;
    uint constant public FIELD_H = 2 ** BITS_PER_PLAYER_Y_POS;

    uint constant public STAMINA_LOSS_PER_STEP = 2;

    bool public gameIsHalted = false;

    address public logic;
    address public ticker;
    address public sxt;

    uint public matchCounter;

    mapping(uint => Types.MatchInfo) public matchInfo;
    mapping(uint => uint) public seedRequestIdMatchId;
    mapping(uint => uint) public matchIdToMatchStateId;
    mapping(uint => mapping(uint => Types.MatchState)) matchState;
    mapping(uint => mapping(uint => Types.TeamState[])) teamState;
    mapping(uint => mapping(uint => Types.TeamMove[])) public teamMove;
    mapping(uint => mapping(uint => bool)) public stateShouldBeSkipped;

    address public manager;

    event MatchEnteredStage(uint matchId, Types.MATCH_STAGE stage);
    constructor(address _logic) 
        VRFV2WrapperConsumerBase(
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693
        ) {
        logic = _logic;
    }

    /// @notice Creates a new match and registers the corresponding Function Consumers
    /// @dev Both Function consumers should implement IChainlinkFunctionConsumer interface
    /// @param commitmentFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Commitment Stage
    /// @param revealFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Reveal Stage
    function createMatch(
        address commitmentFunctionConsumer, 
        address revealFunctionConsumer
    ) public {

        uint matchId = matchCounter;

        _initStorageForMatch(matchId, 0);
        _setPlayersToInitialPositions(matchId, 0);

        Types.MatchInfo storage currMatch = matchInfo[matchId];

        currMatch.stage = Types.MATCH_STAGE.P1_CREATED_THE_MATCH;
        currMatch.commitmentFunctionConsumer[0] = commitmentFunctionConsumer;
        currMatch.revealFunctionConsumer[0] = revealFunctionConsumer;

        matchCounter += 1;

        emit MatchEnteredStage(matchId, currMatch.stage);
    }
    /// @notice Joins an already existing Match
    /// @dev Both Function consumers should implement IChainlinkFunctionConsumer interface
    /// @param matchId ID of the Match the User wants to join
    /// @param commitmentFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Commitment Stage
    /// @param revealFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Reveal Stage
    function joinMatch(
        uint matchId,
        address commitmentFunctionConsumer, 
        address revealFunctionConsumer
    ) public {
        Types.MatchInfo storage currMatch = matchInfo[matchId];

        require(
            currMatch.stage == Types.MATCH_STAGE.P1_CREATED_THE_MATCH, 
            "ERR: You can only join a newly created match!"
        );

        currMatch.commitmentFunctionConsumer[1] = commitmentFunctionConsumer;
        currMatch.revealFunctionConsumer[1] = revealFunctionConsumer;

        currMatch.stage = Types.MATCH_STAGE.P2_JOINED_THE_MATCH;

        emit MatchEnteredStage(matchId, currMatch.stage);

        _requestSeed(matchId);
    }

    function _requestSeed(
        uint matchId
    ) internal {
        Types.MatchInfo storage currMatch = matchInfo[matchId];

        uint requestId = requestRandomness(300000, 3, 1);

        seedRequestIdMatchId[requestId] = matchId;

        currMatch.stage = Types.MATCH_STAGE.RANDOM_SEED_FETCHED;

        emit MatchEnteredStage(matchId, currMatch.stage);
    }


    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint matchId = seedRequestIdMatchId[_requestId];

        Types.MatchInfo storage currMatch = matchInfo[matchId];

        currMatch.seed = _randomWords[0];

        currMatch.stage = Types.MATCH_STAGE.RANDOM_SEED_RECEIVED;

        emit MatchEnteredStage(seedRequestIdMatchId[_requestId], currMatch.stage);
    }

    /// @notice Initiates the start of Commitment Stage
    /// @dev Calls Commitment Function Consumers for both teams
    /// @param matchId ID of the Match
    function commitmentTick(
        uint matchId
    ) public {
        Types.MatchInfo storage currMatch = matchInfo[matchId];

        require(
            currMatch.stage == Types.MATCH_STAGE.RANDOM_SEED_RECEIVED 
            || currMatch.stage == Types.MATCH_STAGE.STATE_UPDATE_PERFORMED, 
            "ERR: Match not in correct stage to fetch Commitments!"
        );

        if(currMatch.stage == Types.MATCH_STAGE.RANDOM_SEED_RECEIVED){
            _createPlayerStats(matchId);
        }

        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            IChainlinkFunctionConsumer(currMatch.commitmentFunctionConsumer[teamId]).requestData();
        }

        currMatch.stage = Types.MATCH_STAGE.COMMITMENTS_FETCHED;

        emit MatchEnteredStage(matchId, currMatch.stage);
    }

    /// @notice Ends the Commitment Stage and copies the underlying data
    /// @dev Request for both Commitments has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateCommitmentInfo(
        uint matchId
    ) public {
        Types.MatchInfo storage currMatch = matchInfo[matchId];

        require(
            currMatch.stage == Types.MATCH_STAGE.COMMITMENTS_FETCHED,
            "ERR: Match not in correct stage to receive Commitments!"
        );        
        
        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            require(
                IChainlinkFunctionConsumer(currMatch.commitmentFunctionConsumer[teamId]).dataIsReady(),
                "ERR: Not all teams have issued commitments!"
            );
        }

        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            _updateTeamMoveCommitments(
                matchId, 
                teamId,
                IChainlinkFunctionConsumer(currMatch.commitmentFunctionConsumer[teamId]).copyData()
            );      
        }

        currMatch.stage = Types.MATCH_STAGE.COMMITMENTS_RECEIVED;

        emit MatchEnteredStage(matchId, currMatch.stage);
    }

    function _updateTeamMoveCommitments(
        uint matchId,
        uint teamId,
        bytes memory payload
    ) internal {
        Types.TeamMove storage currTeamMove = teamMove[matchId][matchIdToMatchStateId[matchId]][teamId];

        currTeamMove.commitment = payload;
    }

    /// @notice Initiates the start of Reveal Stage
    /// @dev Calls Reveal Function Consumers for both teams
    /// @param matchId ID of the Match
    function revealTick(
        uint matchId
    ) public {
        Types.MatchInfo storage currMatch = matchInfo[matchId];

        require(
            currMatch.stage == Types.MATCH_STAGE.COMMITMENTS_RECEIVED,
            "ERR: Match not in correct stage to fetch Reaveals!"
        );

        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            IChainlinkFunctionConsumer(currMatch.revealFunctionConsumer[teamId]).requestData();
        }

        currMatch.stage = Types.MATCH_STAGE.REVEALS_FETCHED;

        emit MatchEnteredStage(matchId, currMatch.stage);
    }

    /// @notice Ends the Reveal Stage and copies the underlying data
    /// @dev Request for both Reveal has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateRevealInfo(
        uint matchId
    ) public {
        Types.MatchInfo storage currMatch = matchInfo[matchId];

        require(
            currMatch.stage == Types.MATCH_STAGE.REVEALS_FETCHED,
            "ERR: Match not in correct stage to receive Reveals!"
        );        
        
        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            require(
                IChainlinkFunctionConsumer(currMatch.revealFunctionConsumer[teamId]).dataIsReady(),
                "ERR: Not all teams have issued commitments!"
            );
        }

        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            _updateTeamMove(
                matchId, 
                teamId,
                IChainlinkFunctionConsumer(currMatch.revealFunctionConsumer[teamId]).copyData()
            );      
        }

        currMatch.stage = Types.MATCH_STAGE.REVEAL_RECEIVED;

        emit MatchEnteredStage(matchId, currMatch.stage);
    }

    /// @notice Initiates the start of State Update Stage
    /// @dev Calls SxT Function Consumer
    /// @param matchId ID of the Match
    function stateUpdateTick(
        uint matchId
    ) public {
        Types.MatchInfo storage currMatch = matchInfo[matchId];

        require(
            currMatch.stage == Types.MATCH_STAGE.REVEAL_RECEIVED,
            "ERR: Match not in correct stage to fetch State update!"
        );

        IChainlinkFunctionConsumer(sxt).requestData();

        currMatch.stage = Types.MATCH_STAGE.STATE_UPDATE_FETCHED;

        emit MatchEnteredStage(matchId, currMatch.stage);
    }

    /// @notice Ends the State Update Stage and unpacks the received data
    /// @dev Request for State Update has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateStateUpdateInfo(
        uint matchId
    ) public {
        Types.MatchInfo storage currMatch = matchInfo[matchId];

        uint stateId = matchIdToMatchStateId[matchId];
        _initStorageForMatch(matchId, stateId+1);

        require(
            currMatch.stage == Types.MATCH_STAGE.STATE_UPDATE_FETCHED,
            "ERR: Match not in correct stage to receive State update!"
        );        
        
        require(
            IChainlinkFunctionConsumer(sxt).dataIsReady(),
            "ERR: State update has not been resolved!"
        );

        _unpackReportedState(
            matchId,
            stateId+1,
            IChainlinkFunctionConsumer(sxt).copyData()
        );

        matchIdToMatchStateId[matchId] += 1;

        currMatch.stage = Types.MATCH_STAGE.STATE_UPDATE_PERFORMED;

        emit MatchEnteredStage(matchId, currMatch.stage);
    }

    /// @notice On-chain execution of the State transition
    /// @dev Used when there's no reporting by SxT because costs a hell of gas :)
    /// @param matchId ID of the Match
    function stateUpdate(uint matchId) public {
        Types.MatchInfo storage s_currMatch = matchInfo[matchId];
        uint stateId = matchIdToMatchStateId[matchId];
        _initStorageForMatch(matchId, stateId+1);
        Types.MatchState storage s_currMatchState = matchState[matchId][stateId+1];

        require(
            s_currMatch.stage == Types.MATCH_STAGE.REVEAL_RECEIVED,
            "ERR: Match not in correct stage to perform a State update!"
        ); 

        Types.ProgressionState[] memory progression = IGameLogic(logic).getProgression(matchId, stateId);

        Types.ProgressionState memory lastProgressionState = progression[progression.length-1];

        Types.TeamState[] memory currTeamState = lastProgressionState.teamState;
        Types.TeamState[] storage s_currTeamState = teamState[matchId][stateId+1];

        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){

            for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                s_currTeamState[teamId].playerStats[playerId] = currTeamState[teamId].playerStats[playerId];
                s_currTeamState[teamId].xPos[playerId] = currTeamState[teamId].xPos[playerId];
                s_currTeamState[teamId].yPos[playerId] = currTeamState[teamId].yPos[playerId];
            }
        }

        s_currMatchState.teamIdWithTheBall = lastProgressionState.teamIdWithTheBall;
        s_currMatchState.playerIdWithTheBall = lastProgressionState.playerIdWithTheBall;
        s_currMatchState.ballXPos = lastProgressionState.ballXPos;
        s_currMatchState.ballYPos = lastProgressionState.ballYPos;
        s_currMatchState.shotWasTaken = lastProgressionState.shotWasTaken;
        s_currMatchState.goalWasScored = lastProgressionState.goalWasScored;

        if(lastProgressionState.shotWasTaken){
            if(lastProgressionState.goalWasScored){
                 _setPlayersToInitialPositions(matchId, stateId+1);
                s_currMatchState.teamIdWithTheBall = lastProgressionState.teamIdWithTheBall;
                s_currMatchState.playerIdWithTheBall = lastProgressionState.playerIdWithTheBall;
                s_currMatchState.ballXPos = lastProgressionState.ballXPos;
                s_currMatchState.ballYPos = lastProgressionState.ballYPos;
                s_currMatchState.shotWasTaken = lastProgressionState.shotWasTaken;
                s_currMatchState.goalWasScored = lastProgressionState.goalWasScored;
            } else {

            }
        }

        matchIdToMatchStateId[matchId] += 1;

        s_currMatch.stage = Types.MATCH_STAGE.STATE_UPDATE_PERFORMED;

        emit MatchEnteredStage(matchId, s_currMatch.stage);
    }
    
    /// @notice Checks whether the reported State is correct
    /// @dev If the dispute is justified and there's a discrepancy the game is completly halted
    /// @param matchId ID of the Match
    /// @param stateId ID of the State after which there's a discrepancy
    function dispute(
        uint matchId,
        uint stateId
    ) public {

        require(
            stateId < matchIdToMatchStateId[matchId] - 2,
            "ERR: The match has not progressed that far"
        );

        Types.MatchState storage s_actualMatchState = matchState[matchId][stateId+1];

        Types.ProgressionState memory expected = 
            IGameLogic(logic).getProgression(matchId, stateId)[TOTAL_PROGRESSION_STEPS-1];

        gameIsHalted = 
            expected.teamIdWithTheBall != s_actualMatchState.teamIdWithTheBall
            || expected.playerIdWithTheBall != s_actualMatchState.playerIdWithTheBall
            || expected.ballXPos != s_actualMatchState.ballXPos
            || expected.ballYPos != s_actualMatchState.ballYPos
            || expected.shotWasTaken != s_actualMatchState.shotWasTaken
            || expected.goalWasScored != s_actualMatchState.goalWasScored;
    }

    /// @notice Unpacks the SxT reported state
    /// @param matchId ID of the Match
    /// @param stateId ID of the State that will be unpacked
    /// @param payload Received Data Payload
    function _unpackReportedState(
        uint matchId,
        uint stateId,
        bytes memory payload
    ) internal {
        Types.MatchState storage mState = matchState[matchId][stateId];
        mState.reportedState = payload;

        (uint team1Pos, uint team2Pos, uint meta) =
            abi.decode(payload, (uint, uint, uint));
        //console.log("022222");
        uint[2] memory teamPos = [team1Pos, team2Pos];

        uint SHIFT_STEP = BITS_PER_PLAYER_X_POS + BITS_PER_PLAYER_Y_POS;

        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            Types.TeamState storage tState = teamState[matchId][stateId][teamId];

            for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                uint segment = (teamPos[teamId] >> (playerId * SHIFT_STEP));
                tState.xPos[playerId] = (segment >> BITS_PER_PLAYER_Y_POS) & (2**BITS_PER_PLAYER_X_POS - 1);
                tState.yPos[playerId] = segment & (2**BITS_PER_PLAYER_Y_POS - 1);
            }
        }

        mState.teamIdWithTheBall = meta & 1;
        uint proposedPlayerId =  (meta >> 1) & 15;
        mState.playerIdWithTheBall = proposedPlayerId < NUMBER_OF_PLAYERS_PER_TEAM ? proposedPlayerId: 0;

        mState.ballXPos = (meta >> 5) & (2**BITS_PER_PLAYER_X_POS - 1);
        mState.ballYPos = (meta >> (5+BITS_PER_PLAYER_X_POS)) & (2**BITS_PER_PLAYER_Y_POS - 1);

        mState.shotWasTaken = ((meta >> (5+BITS_PER_PLAYER_X_POS+BITS_PER_PLAYER_Y_POS)) & 1) == 1;
        mState.goalWasScored = ((meta >> (5+BITS_PER_PLAYER_X_POS+BITS_PER_PLAYER_Y_POS+1)) & 1) == 1;
    }

    /// @notice Updates the Team move based on received Payload
    /// @param matchId ID of the Match
    /// @param teamId ID of the Team that will be updated
    /// @param payload Received Data Payload
    function _updateTeamMove(
        uint matchId,
        uint teamId,
        bytes memory payload
    ) internal {
        Types.TeamMove storage currTeamMove = teamMove[matchId][matchIdToMatchStateId[matchId]][teamId];

        bytes memory revealHash = abi.encode(keccak256(payload));

        // require(
        //     keccak256(revealHash) == keccak256(currTeamMove.commitment),
        //     "ERR: Reveal doesn't correspond to the Commitment"  
        // );

        currTeamMove.reveal = payload;

        uint seed = 13; uint packedData = 13;
        // (uint seed, uint packedData) = abi.decode(payload, (uint, uint));

        currTeamMove.seed = seed;

        uint SHIFT_STEP = BITS_PER_PLAYER_X_POS + BITS_PER_PLAYER_Y_POS;

        for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
            uint segment = (packedData >> (playerId * SHIFT_STEP));
            currTeamMove.xPos[playerId] = (segment >> BITS_PER_PLAYER_Y_POS) & (2**BITS_PER_PLAYER_X_POS - 1);
            currTeamMove.yPos[playerId] = segment & (2**BITS_PER_PLAYER_Y_POS - 1);
        }

        currTeamMove.wantToShoot = true; //(packedData >> (SHIFT_STEP * NUMBER_OF_PLAYERS_PER_TEAM) & 1) == 1;
        
        currTeamMove.wantToPass = (packedData >> (SHIFT_STEP * NUMBER_OF_PLAYERS_PER_TEAM + 1) & 1) == 1;

        uint potentialReceivingPlayerId = (packedData >> (SHIFT_STEP * NUMBER_OF_PLAYERS_PER_TEAM + 2) & 0xf);
        currTeamMove.receivingPlayerId = potentialReceivingPlayerId < 10 ? potentialReceivingPlayerId : 0;
    }

    /// @notice Sets the player to Start Positions (in storage)
    /// @param matchId ID of the Match
    /// @param stateId ID of the State that will be altered
    function _setPlayersToInitialPositions(
        uint matchId,
        uint stateId
    ) public {
        uint teamId = 0;

        Types.MatchState storage s_currMatchState = matchState[matchId][stateId];
        s_currMatchState.ballXPos = FIELD_W / 2;
        s_currMatchState.ballYPos = FIELD_H / 2;
        Types.TeamState storage currTeamState = teamState[matchId][stateId][teamId];

        for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
            if(playerId == 0){
                currTeamState.xPos[playerId] = FIELD_W/2;
                currTeamState.yPos[playerId] = FIELD_H/2;
            } else if (playerId > 0 && playerId < 4){
                currTeamState.xPos[playerId] = 3 * (FIELD_W/8);
                currTeamState.yPos[playerId] = playerId * (FIELD_H/4);
            }  else if (playerId > 3 && playerId < 8){
                currTeamState.xPos[playerId] = 2 * (FIELD_W/8);
                currTeamState.yPos[playerId] = (playerId-3) * (FIELD_H/5);
            } else if (playerId > 7 && playerId < 10){
                currTeamState.xPos[playerId] = 1 * (FIELD_W/8);
                currTeamState.yPos[playerId] = (playerId-7) * (FIELD_H/3);
            }
        }

        teamId = 1;
        Types.TeamState storage currTeamState2 = teamState[matchId][stateId][teamId];
        for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
            if(playerId == 0){
                currTeamState2.xPos[playerId] = FIELD_W/2;
                currTeamState2.yPos[playerId] = FIELD_H/2;
            } else if (playerId > 0 && playerId < 4){
                currTeamState2.xPos[playerId] = 5 * (FIELD_W/8);
                currTeamState2.yPos[playerId] = playerId * (FIELD_H/4);
            }  else if (playerId > 3 && playerId < 8){
                currTeamState2.xPos[playerId] = 6 * (FIELD_W/8);
                currTeamState2.yPos[playerId] = (playerId-3) * (FIELD_H/5);
            } else if (playerId > 7 && playerId < 10){
                currTeamState2.xPos[playerId] = 7 * (FIELD_W/8);
                currTeamState2.yPos[playerId] = (playerId-7) * (FIELD_H/3);
            }
        }
    }

    /// @notice Sets the initial player stats based on VRF's Seed
    /// @param matchId ID of the Match
    function _createPlayerStats(
        uint matchId
    ) internal { 
        
        uint seed = matchInfo[matchId].seed;
        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
            Types.TeamState storage tState = teamState[matchId][0][teamId];
            for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                uint segment = (seed >> ((1+teamId)*playerId*11));
                tState.playerStats[playerId].speed = segment & (2**7-1);
                tState.playerStats[playerId].skill = (segment >> 7) & (2**7-1);
                tState.playerStats[playerId].stamina = (segment >> 14) & (2**7-1);
            }
            tState.goalKeeperStats.speed = ((seed >> (teamId*21)) >> 0) & (2**7-1);
            tState.goalKeeperStats.skill = ((seed >> (teamId*21)) >> 7) & (2**7-1);
            tState.goalKeeperStats.stamina = ((seed >> (teamId*21)) >> 14) & (2**7-1);
        }
    }

    /// @notice Initializes all the arrays and field for a State
    /// @param matchId ID of the Match
    /// @param currMoveId ID of the MOve which will be instantiated
    function _initStorageForMatch(
        uint matchId, 
        uint currMoveId
    ) public {

        if(currMoveId == 0){
            for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){
                matchInfo[matchId].commitmentFunctionConsumer.push();
                matchInfo[matchId].revealFunctionConsumer.push();
            }
        }

        Types.MatchState storage currMatchState = matchState[matchId][currMoveId];
        Types.TeamState[] storage currTeamState = teamState[matchId][currMoveId];
        Types.TeamMove[] storage currTeamMove = teamMove[matchId][currMoveId];
        for(uint teamId = 0; teamId < NUMBER_OF_TEAMS; ++teamId){

            currMatchState.score.push(0);

            currTeamState.push();
            for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                currTeamState[teamId].playerStats.push();

                currTeamState[teamId].xPos.push();
                currTeamState[teamId].yPos.push();
            }

            currTeamMove.push();
            for(uint playerId = 0; playerId < NUMBER_OF_PLAYERS_PER_TEAM; ++playerId){
                currTeamMove[teamId].xPos.push();
                currTeamMove[teamId].yPos.push();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Additional interface for all Function Consumers in the AI:1301 project
/// @author Milos Bojinovic
/// @notice Experimental use
interface IChainlinkFunctionConsumer {

    /// @notice Method that makes a Request to be processed by Chainlink Decentralized Oracle Network (DON)
    function requestData () external;

    /// @notice Method extracts the Request Data and updates its status
    /// @return Received Data after the Request
    function copyData () external returns (bytes memory);

    /// @notice Method that checks whether the Request has been fulfilled
    /// @return Status of the Request fulfillment
    function dataIsReady () external view returns(bool);

    /// @notice Method that checks whether the Request Data has been used
    /// @return Status of the Request Data use
    function dataHasBeenRead () external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Interface for the Main Game contract
/// @author Milos Bojinovic
/// @notice Experimental use


import "../Types.sol";
interface IGameLogic {

    /// @notice Sets the address of the Space and Time (SxT) Function Consumer
    /// @dev This Function consumer should implement IChainlinkFunctionConsumer interface
    /// @param sxt Address of the deployed SxT Function Consumer
    function setSxT(address sxt) external;


    /// @notice Creates a new match and registers the corresponding Function Consumers
    /// @dev Both Function consumers should implement IChainlinkFunctionConsumer interface
    /// @param team1_commitmentChainlinkFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Commitment Stage
    /// @param team1_revealChainlinkFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Reveal Stage
    function createMatch(
        address team1_commitmentChainlinkFunctionConsumer, 
        address team1_revealChainlinkFunctionConsumer
    ) external;

    /// @notice Joins an already existing Match
    /// @dev Both Function consumers should implement IChainlinkFunctionConsumer interface
    /// @param matchId ID of the Match the User wants to join
    /// @param team2_commitmentChainlinkFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Commitment Stage
    /// @param team2_revealChainlinkFunctionConsumer Address of the deployed Function Consumer 
    ///     that will be used in the Reveal Stage
    function joinMatch(
        uint matchId,
        address team2_commitmentChainlinkFunctionConsumer, 
        address team2_revealChainlinkFunctionConsumer
    ) external;

    /// @notice Initiates the start of Commitment Stage
    /// @dev Calls Commitment Function Consumers for both teams
    /// @param matchId ID of the Match
    function commitmentTick(uint matchId) external;

    /// @notice Ends the Commitment Stage and copies the underlying data
    /// @dev Request for both Commitments has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateCommitmentInfo(uint matchId) external;

    /// @notice Initiates the start of Reveal Stage
    /// @dev Calls Reveal Function Consumers for both teams
    /// @param matchId ID of the Match
    function revealTick(uint matchId) external;

    /// @notice Ends the Reveal Stage and copies the underlying data
    /// @dev Request for both Reveal has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateRevealInfo(uint matchId) external;

    /// @notice Initiates the start of State Update Stage
    /// @dev Calls SxT Function Consumer
    /// @param matchId ID of the Match
    function stateUpdateTick(uint matchId) external;

    /// @notice Ends the State Update Stage and unpacks the received data
    /// @dev Request for State Update has to be resolved (fulfilled)
    /// @param matchId ID of the Match
    function updateStateUpdateInfo(uint matchId) external;

    /// @notice On-chain execution of the State transition
    /// @dev Used when there's no reporting by SxT because costs a hell of gas :)
    /// @param matchId ID of the Match
    function stateUpdate(uint matchId) external;

    /// @notice Checks whether the reported State is correct
    /// @dev If the dispute is justified and there's a discrepancy the game is completly halted
    /// @param matchId ID of the Match
    /// @param stateId ID of the State after which there's a discrepancy
    function dispute(uint matchId, uint stateId) external;

    /// @notice Generates the next Match State and all of the States in between
    /// @dev Used by .stateUpdate and .dispute
    /// @param matchId ID of the Match
    /// @param stateId ID of the previous State
    /// @return progression A series of intermediate (and final) states
    function getProgression(
        uint matchId,
        uint stateId
    ) external returns (
        Types.ProgressionState[] memory progression
    );
}

pragma solidity ^0.8.18;

contract Types {

    enum MATCH_STAGE {
        DUMMY,
        P1_CREATED_THE_MATCH,
        P2_JOINED_THE_MATCH,
        RANDOM_SEED_FETCHED,
        RANDOM_SEED_RECEIVED,
        COMMITMENTS_FETCHED,
        COMMITMENTS_RECEIVED,
        REVEALS_FETCHED,
        REVEAL_RECEIVED,
        STATE_UPDATE_FETCHED,
        STATE_UPDATE_PERFORMED,
        MATCH_ENDED
    }


    struct MatchInfo {
        uint seed;

        address[] commitmentFunctionConsumer;
        address[] revealFunctionConsumer;

        MATCH_STAGE stage;

        uint stateId;
    }


    struct MatchState {
        uint[] score;

        uint teamIdWithTheBall;
        uint playerIdWithTheBall;

        uint ballXPos;
        uint ballYPos;

        bool shotWasTaken;
        bool goalWasScored;

        bytes reportedState;
    }

    struct PlayerStats {
        uint speed;
        uint skill;
        uint stamina;
    }

    struct TeamState {
        PlayerStats[] playerStats;
        PlayerStats goalKeeperStats;
        uint[] xPos;
        uint[] yPos;
    }

    struct TeamMove {
        bytes commitment;
        bytes reveal;

        uint seed;

        uint[] xPos;
        uint[] yPos;

        bool wantToPass;
        uint receivingPlayerId;

        bool wantToShoot;
    }

    struct ProgressionState {
        uint startingTeamIdWithTheBall;
        uint startingPlayerIdWithTheBall;

        uint teamIdWithTheBall;
        uint playerIdWithTheBall;

        bool ballWasWon;
        uint ballWasWonByTeam;

        bool interceptionOccured;
        uint interceptionAchievedByTeam;
        uint ballXPos;
        uint ballYPos;

        bool shotWasTaken;
        uint teamIdOfTheGoalWhereTheShootWasTaken;
        bool goalWasScored;
        uint goalWasScoredByTeam;

        TeamState[] teamState;
    }

}