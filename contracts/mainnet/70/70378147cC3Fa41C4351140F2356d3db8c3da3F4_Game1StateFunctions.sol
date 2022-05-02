// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../core/CozyRegistry.sol";

// TuningSet contains information about game tuning parameters
// The values used by the game are denoted in getTuningSet
struct TuningSet {
  int minPlayers;
  uint16[5] baseLaunchPercents;
  int backfireBaseCoefficient;
  int backfireMax;
  int backfireStepCoefficient;
  int backfireStreakCoefficient;
  int multiplierBaseCoefficient;
  int multiplierStepCoefficient;
  int multiplierStreakCoefficient;
  int16 backfireDistanceFactor;
  int64 playerWinStreakBonus;
  int64 playerWinStreakCap;
  int64 playerWinStreakStart;
  int64 playerLossStreakBonus;
  int64 playerLossStreakCap;
  int64 playerLossStreakStart;
}

// GameStartArgs are per-game parameters specified on game start
struct GameStartArgs {
  uint16 periods;
  uint16 sweepsPerPeriod;
  uint16 distanceCoefficient;
  uint48 movePhaseSeconds;
  uint48 startInSeconds;
}

// PlayerState contains the outward facing view of a player
// PlayerStates are not materialized in contract storage, but
// rather computed when requested
struct PlayerState {
  uint tokenId;
  uint moveIndex;
  uint8 lane;
  bool inLane;
  int64 distance;
  int64 bonus;
  int64 streak;
  int64 lastDistance;
  uint64 culledOnSweep;
  uint64 wonAtSweep;
  int64 wonAtDistance;
}

struct PlayerStatBatch {
  bool done;
  PlayerState[] states;
}

struct Move {
  uint32 sweep;
  uint8 lane;
}

struct LaunchView {
  int distance;
  int players;
  int percentFire;
  int percentBackfire;
  bool fired;
}

// LaunchBatch represents the launch results for all 5 slings
// bit packed into 1 struct. Each field is packed together
// TODO more here
struct LaunchBatch {
  bytes10 distance;
  bytes10 players;
  bytes5 percentFire;
  bytes5 percentBackfire;
  uint8 launchedLanes;
}

struct Lane {
  int16 players;
  int16 streak;
}

struct LaneView {
  int players;
  int streak;
  int tgPt;
  int bfPt;
  int mult;
  LaunchView[] launches;
}

// Syncronize with Phase in @cozy/game1-gameserver/src/types.ts
enum Phase {
  NONE,
  STARTING,
  MOVEMENT,
  VRF_REQUESTED,
  END
}

struct GameState {
  uint gameID;
  uint random;
  uint lastRandom;
  uint48 movePhaseSeconds;
  uint48 phaseStart;
  uint48 phaseScheduledEnd;
  uint16 totalSweeps;
  uint24 totalPlayers;
  uint16 sweep;
  uint16 sweepsPerPeriod;
  uint16 distanceCoefficient;
  Phase phase;
  int24 movesThisSweep;
}

struct State {
  mapping(uint => Move[]) playerMoves;
  uint[] players;
  GameState game;
  Lane[5] lanes;
  LaunchBatch[] launches;
}

library Game1StateFunctions {
  using LaunchFunctions for LaunchBatch;

  error InvalidPeriods(uint16 period);
  error InvalidSweepsPerPeriod(uint16 sweepsPerPeriod);
  error CannotMove();
  error InvalidLane(uint8 lane);
  error InvalidPhase(Phase current, Phase desired);

  function initialize(State storage state) public {
    state.game.movePhaseSeconds = 1;
    state.game.sweepsPerPeriod = 1;
    state.game.distanceCoefficient = 1;
  }

  function start(
    State storage state,
    GameStartArgs memory args,
    uint gameID
  ) public inPhase(state, Phase.NONE) {
    if (args.periods <= 0) {
      revert InvalidPeriods(args.periods);
    }
    if (args.sweepsPerPeriod <= 0) {
      revert InvalidSweepsPerPeriod(args.sweepsPerPeriod);
    }

    state.game.gameID = gameID;
    state.game.totalSweeps = args.periods * args.sweepsPerPeriod;
    state.game.phase = Phase.STARTING;
    state.game.phaseStart = uint48(block.timestamp);
    state.game.phaseScheduledEnd = uint48(block.timestamp) + args.startInSeconds;
    state.game.sweepsPerPeriod = args.sweepsPerPeriod;
    state.game.distanceCoefficient = args.distanceCoefficient;
    state.game.movePhaseSeconds = args.movePhaseSeconds;
    state.game.movesThisSweep = int24(0);
  }

  function reset(State storage state) public {
    // clear lanes
    for (uint i = 0; i < 5; i++) {
      state.lanes[i].players = 0;
      state.lanes[i].streak = 0;
    }

    // clear launches
    delete state.launches;

    // clear game state
    state.game.phase = Phase.NONE;
    state.game.totalPlayers = 0;
    state.game.sweep = 0;

    // clear player moves
    for (uint i = 0; i < state.players.length; i++) {
      delete state.playerMoves[state.players[i]];
    }
    delete state.players;
  }

  function gotoNextState(State storage state) public {
    if (state.game.phase == Phase.STARTING) {
      state.game.phase = Phase.MOVEMENT;
      state.game.phaseScheduledEnd = uint48(block.timestamp + state.game.movePhaseSeconds);
    } else if (state.game.phase == Phase.MOVEMENT) {
      state.game.phase = Phase.VRF_REQUESTED;
      state.game.phaseScheduledEnd = 0xffffffffffff;
    } else if (
      state.game.phase == Phase.VRF_REQUESTED && state.game.sweep == state.game.totalSweeps - 1
    ) {
      state.game.phase = Phase.END;
      state.game.phaseScheduledEnd = 0xffffffffffff;
    } else if (state.game.phase == Phase.VRF_REQUESTED) {
      state.game.phase = Phase.MOVEMENT;
      state.game.phaseScheduledEnd = uint48(block.timestamp + state.game.movePhaseSeconds);
    } else if (state.game.phase == Phase.END) {
      return;
    } else if (state.game.phase == Phase.NONE) {
      return;
    } else {
      assert(false);
    }
    state.game.phaseStart = uint48(block.timestamp);
  }

  function getTuningSet() public pure returns (TuningSet memory ret) {
    ret.minPlayers = 10;
    ret.baseLaunchPercents = [750, 800, 850, 900, 950];
    ret.backfireBaseCoefficient = 15;
    ret.backfireStepCoefficient = 30;
    ret.backfireStreakCoefficient = 5;
    ret.backfireMax = 950;
    ret.multiplierBaseCoefficient = 1000;
    ret.multiplierStepCoefficient = 2000;
    ret.multiplierStreakCoefficient = 250;

    ret.backfireDistanceFactor = 3;

    ret.playerWinStreakBonus = 5;
    ret.playerWinStreakCap = 5;
    ret.playerWinStreakStart = 3;

    ret.playerLossStreakBonus = 10;
    ret.playerLossStreakCap = 3;
    ret.playerLossStreakStart = 3;
  }

  function clampAndAdjust(
    int value,
    int min,
    int max
  ) internal pure returns (int) {
    // clamp
    int clamped = value < min ? min : value > max ? max : value;

    // adjust
    return clamped / 10;
  }

  function normalizePlayers(
    int players,
    int total,
    int streak,
    int minPlayers
  ) internal pure returns (int) {
    // return a value between 0 and 2000
    // 2000 indicates all moves are to the same sling
    // 1000 indicates sling is neutral
    //    0 indicates all moves are from the same sling
    if (total == 0) return int(1000);
    int t = total < minPlayers ? minPlayers : total;
    int x = players < 0 ? players / 2 : players;
    int y = (1000 * (x + t)) / t;
    int overflow = y < 1000 ? int(0) : y - int(1000);

    return y + (overflow / (streak + 1)) / 1000;
  }

  function absPercentPlayers(
    int players,
    int total,
    int minPlayers
  ) internal pure returns (int) {
    // return a value between 0 and 1000
    // 1000 indicates all players either moved from or to the same sling
    //    0 indicates the sling is neutral
    if (total == 0) return int(0);
    int t = total < minPlayers ? minPlayers : total;
    int x = players < 0 ? -1 * players : players;
    return (1000 * x) / t;
  }

  function getPeriod(State storage state) public view returns (int) {
    return int(int16(state.game.sweep / state.game.sweepsPerPeriod));
  }

  function getLastLaunch(State storage state, uint8 lane) public view returns (LaunchView memory) {
    // return the previous launch (or default if there was no previous launch)
    // values are converted to 1000-based precision to simplify computations
    LaunchView memory ret;
    if (state.launches.length > 0) {
      ret = state.launches[state.launches.length - 1].getLaunch(lane);
    } else {
      ret.distance = 100;
    }
    // convert 100 based precision to 1000 based for calculations
    ret.distance *= 10;
    ret.percentBackfire *= 10;
    ret.percentFire *= 10;
    return ret;
  }

  function lanePercentTrigger(State storage state, uint8 lane) public view returns (int) {
    TuningSet memory ts = getTuningSet();
    int percent = int(uint(ts.baseLaunchPercents[(state.game.lastRandom + lane) % 5]));
    int players = absPercentPlayers(
      state.lanes[lane].players,
      state.game.movesThisSweep,
      ts.minPlayers
    );
    return clampAndAdjust(percent + players, 0, 1000);
  }

  function lanePercentBackfire(State storage state, uint8 lane) public view returns (int) {
    TuningSet memory ts = getTuningSet();
    LaunchView memory last = getLastLaunch(state, lane);
    bool lastBackfired = last.fired && last.distance < 0;
    if (lastBackfired) {
      return clampAndAdjust(ts.backfireBaseCoefficient * getPeriod(state), 0, ts.backfireMax);
    }

    int streak = state.lanes[lane].streak;
    int percent = last.percentBackfire;
    if (last.fired) {
      percent += ts.backfireStepCoefficient + ts.backfireStreakCoefficient * streak;
    }

    int players = normalizePlayers(
      state.lanes[lane].players,
      state.game.movesThisSweep,
      streak,
      ts.minPlayers
    );
    percent = (percent * players) / 1000;
    return clampAndAdjust(percent, 0, ts.backfireMax);
  }

  function laneDistanceMultiplier(State storage state, uint8 lane) public view returns (int) {
    TuningSet memory ts = getTuningSet();
    LaunchView memory last = getLastLaunch(state, lane);
    bool lastBackfired = last.fired && last.distance < 0;
    if (lastBackfired) {
      return
        clampAndAdjust(ts.multiplierBaseCoefficient * (getPeriod(state) + 1), 1000, 0xffffffff);
    }

    int streak = state.lanes[lane].streak;
    int mult = last.distance;
    if (last.fired) {
      mult += ts.multiplierStepCoefficient + ts.multiplierStreakCoefficient * streak;
    }
    int players = normalizePlayers(
      state.lanes[lane].players,
      state.game.movesThisSweep,
      streak,
      ts.minPlayers
    );
    mult = (mult * players) / 1000;
    return clampAndAdjust(mult, 1000, 0xffffffff);
  }

  function checkpointDistanceForPeriod(State storage state, uint period) public view returns (int) {
    return int(2 * period * period * state.game.distanceCoefficient);
  }

  function sweepLane(
    State storage state,
    uint24 randomness,
    uint8 laneIndex,
    LaunchBatch memory launchBatch
  ) public {
    Lane storage lane = state.lanes[laneIndex];

    LaunchView memory lv;
    lv.players = lane.players;
    lv.distance = int16(laneDistanceMultiplier(state, laneIndex));
    lv.percentFire = int8(lanePercentTrigger(state, laneIndex));
    lv.percentBackfire = int8(lanePercentBackfire(state, laneIndex));

    uint8 triggerThreshold = uint8(0xff - uint8(uint16((int16(lv.percentFire) * 0xff) / 100)));
    uint8 backfireThreshold = uint8(0xff - uint8(uint16((int16(lv.percentBackfire) * 0xff) / 100)));

    if (uint8(randomness) >= triggerThreshold) {
      // trigger
      if (uint8(randomness >> 8) > backfireThreshold) {
        // backfire
        lv.distance = -1 * lv.distance;
        lane.streak = 0;
      } else {
        // no backfire
        lane.streak++;
      }
      lv.fired = true;
    }
    launchBatch.setLaunch(laneIndex, lv);

    lane.players = 0;
  }

  function sweepLanes(State storage state, uint randomness) public {
    // Check each lane for trigger
    // use 3 bytes of our random as a seed for each check
    uint rand = randomness;
    LaunchBatch memory launchBatch;
    for (uint8 i = 0; i < 5; i++) {
      uint24 r = uint24(rand);
      sweepLane(state, r, i, launchBatch);
      rand = rand >> 24;
    }
    state.launches.push(launchBatch);
    state.game.movesThisSweep = int24(0);
  }

  function switchPlayerLane(
    State storage state,
    uint tokenID,
    uint8 newLane
  ) public returns (uint8 oldLane) {
    if (!canMove(state)) {
      revert CannotMove();
    }

    if (newLane >= 5) {
      revert InvalidLane(newLane);
    }

    Move[] storage moves = state.playerMoves[tokenID];

    bool canReplace = false;
    // move player
    oldLane = 0xff;

    if (moves.length > 0) {
      // I have moves, checking if replacement required
      Move storage lastMove = moves[moves.length - 1];
      oldLane = lastMove.lane;
      state.lanes[lastMove.lane].players -= 1;
      canReplace = lastMove.sweep == state.game.sweep;
    } else {
      // making our first move, add to active player count
      state.game.totalPlayers += 1;
      state.players.push(tokenID);
    }
    state.lanes[newLane].players += 1;

    if (canReplace) {
      moves[moves.length - 1].lane = newLane;
    } else {
      moves.push(Move(state.game.sweep, newLane));
      state.game.movesThisSweep += 1;
    }
  }

  function canMove(State storage state) public view returns (bool) {
    return state.game.phase == Phase.MOVEMENT || state.game.phase == Phase.STARTING;
  }

  function getLanes(State storage state) public view returns (LaneView[] memory) {
    LaneView[] memory ret = new LaneView[](5);
    for (uint8 i = 0; i < 5; i++) {
      ret[i] = getLane(state, i);
    }
    return ret;
  }

  function getLane(State storage state, uint8 index) public view returns (LaneView memory) {
    return
      LaneView(
        state.lanes[index].players,
        state.lanes[index].streak,
        lanePercentTrigger(state, index),
        lanePercentBackfire(state, index),
        laneDistanceMultiplier(state, index),
        getLaunches(state, index)
      );
  }

  function getLaunches(State storage state, uint8 index) public view returns (LaunchView[] memory) {
    LaunchView[] memory launches = new LaunchView[](state.game.sweep);
    for (uint i = 0; i < state.game.sweep; i++) {
      launches[i] = state.launches[i].getLaunch(index);
    }
    return launches;
  }

  function getPlayerBonus(int64 playerStreak) public pure returns (int64) {
    TuningSet memory ts = getTuningSet();
    // Win Streak Bonus
    if (playerStreak >= ts.playerWinStreakStart) {
      int64 streak = playerStreak > ts.playerWinStreakCap ? ts.playerWinStreakCap : playerStreak;
      return streak * ts.playerWinStreakBonus;
      // Loss Streak Bonus
    } else if (-playerStreak >= ts.playerLossStreakStart) {
      int64 streak = -playerStreak > ts.playerLossStreakCap
        ? ts.playerLossStreakCap
        : -playerStreak;
      return streak * ts.playerLossStreakBonus;
      // No Bonus
    } else {
      return 0;
    }
  }

  function getNextPlayerStat(
    State storage state,
    PlayerState memory prevStat,
    uint sweep
  ) public view returns (PlayerState memory) {
    TuningSet memory ts = getTuningSet();
    PlayerState memory playerState = PlayerState(
      prevStat.tokenId,
      prevStat.moveIndex,
      prevStat.lane,
      prevStat.inLane,
      prevStat.distance,
      prevStat.bonus,
      prevStat.streak,
      prevStat.lastDistance,
      prevStat.culledOnSweep,
      prevStat.wonAtSweep,
      prevStat.wonAtDistance
    );

    Move[] storage moves = state.playerMoves[playerState.tokenId];

    if (
      moves.length > playerState.moveIndex + 1 && moves[playerState.moveIndex + 1].sweep == sweep
    ) {
      // Player moved this sweep, advance move index
      playerState.moveIndex++;
    }

    // Compute which lane (if any) you are in this sweep
    uint period = sweep / state.game.sweepsPerPeriod;
    playerState.inLane = moves.length > 0 && moves[playerState.moveIndex].sweep <= sweep;

    if (playerState.inLane) {
      playerState.lane = moves[playerState.moveIndex].lane;
    }

    // Compute the distance gained for this sweep
    int64 distance = 0;
    if (playerState.inLane) {
      LaunchView memory lv = state.launches[sweep].getLaunch(playerState.lane);

      if (!lv.fired) {
        // Didn't fire, reset streak
        playerState.bonus = 0;
        playerState.streak = playerState.streak <= 0 ? playerState.streak - 1 : int64(-1);
      } else if (lv.distance < 0) {
        // Backfired, removing distance
        distance = int64(lv.distance / ts.backfireDistanceFactor);
        playerState.bonus = 0;
        playerState.streak = playerState.streak <= 0 ? playerState.streak - 1 : int64(-1);
      } else {
        // Fired, adding distance
        int64 bonus = getPlayerBonus(playerState.streak);
        distance = int64(lv.distance + (lv.distance * bonus) / 100);
        playerState.bonus = bonus;
        playerState.streak = playerState.streak >= 0 ? playerState.streak + 1 : int64(1);
      }
    } else {
      // Not in a lane
      playerState.bonus = 0;
      playerState.streak = playerState.streak <= 0 ? playerState.streak - 1 : int64(-1);
    }

    // Update distance
    int64 minDist = int64(checkpointDistanceForPeriod(state, period));
    int64 winDist = int64(
      checkpointDistanceForPeriod(state, state.game.totalSweeps / state.game.sweepsPerPeriod)
    );
    int64 nextDistance = playerState.distance + distance;
    if (playerState.distance >= minDist && nextDistance < minDist) {
      playerState.lastDistance = minDist - playerState.distance;
    } else if (playerState.distance >= winDist && nextDistance < winDist) {
      playerState.lastDistance = winDist - playerState.distance;
    } else if (nextDistance < 0) {
      playerState.lastDistance = -1 * playerState.distance;
    } else {
      playerState.lastDistance = distance;
    }
    playerState.distance += playerState.lastDistance;

    // Check for win condition
    if (playerState.wonAtSweep == 0 && playerState.distance >= winDist) {
      playerState.wonAtSweep = uint64(sweep);
      playerState.wonAtDistance = playerState.distance;
      return playerState;
    }

    // Check for death condition
    if (
      playerState.culledOnSweep == 0 &&
      sweep % state.game.sweepsPerPeriod == state.game.sweepsPerPeriod - 1
    ) {
      // period boundary, check if player was culled
      if (playerState.distance < int64(checkpointDistanceForPeriod(state, period + 1))) {
        // player was culled
        playerState.culledOnSweep = uint64(sweep);
        return playerState;
      }
    }

    return playerState;
  }

  function getPlayerStat(
    State storage state,
    uint tokenID,
    uint upToSweep
  ) public view returns (PlayerState memory) {
    PlayerState memory playerState;
    playerState.tokenId = tokenID;
    uint limit = upToSweep > state.game.sweep ? state.game.sweep : upToSweep;
    for (uint i = 0; i < limit; i++) {
      playerState = getNextPlayerStat(state, playerState, i);

      if (playerState.culledOnSweep > 0) {
        break;
      }
    }
    return playerState;
  }

  function getPlayerStatBatch(
    State storage state,
    uint cursor,
    uint batchSize
  ) public view returns (PlayerStatBatch memory) {
    PlayerStatBatch memory batch;
    batch.done = cursor + batchSize >= state.players.length;

    if (cursor >= state.players.length) {
      return batch;
    }

    uint size = Math.min(state.players.length - cursor, batchSize);
    batch.states = new PlayerState[](size);

    for (uint i = 0; i < size; i++) {
      batch.states[i] = getPlayerStat(state, state.players[cursor + i], 0xFFFFFFFF);
    }

    return batch;
  }

  modifier inPhase(State storage state, Phase p) {
    if (state.game.phase != p) {
      revert InvalidPhase(state.game.phase, p);
    }
    _;
  }
}

library LaunchFunctions {
  function getLaunch(LaunchBatch storage launchBatch, uint8 lane)
    internal
    view
    returns (LaunchView memory lv)
  {
    lv.fired = (launchBatch.launchedLanes & (2**lane)) > 0;
    lv.distance = int16(uint16(uint80(launchBatch.distance >> (16 * lane))));
    lv.players = int16(uint16(uint80(launchBatch.players >> (16 * lane))));
    lv.percentFire = int8(uint8(uint40(launchBatch.percentFire >> (8 * lane))));
    lv.percentBackfire = int8(uint8(uint40(launchBatch.percentBackfire >> (8 * lane))));
    return lv;
  }

  function setLaunch(
    LaunchBatch memory launchBatch,
    uint8 lane,
    LaunchView memory lv
  ) internal pure {
    if (lv.fired) {
      launchBatch.launchedLanes |= uint8(2**lane);
    }
    launchBatch.distance |= bytes10(uint80(uint16(int16(lv.distance)) * 2**(16 * lane)));
    launchBatch.players |= bytes10(uint80(uint16(int16(lv.players)) * 2**(16 * lane)));
    launchBatch.percentFire |= bytes5(uint40(uint(lv.percentFire) * 2**(8 * lane)));
    launchBatch.percentBackfire |= bytes5(uint40(uint(lv.percentBackfire) * 2**(8 * lane)));
  }
}

contract Game1 is KeeperCompatibleInterface, VRFConsumerBaseV2, AccessControl {
  using Game1StateFunctions for State;
  using LaunchFunctions for LaunchBatch;

  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  error GameAlreadyRunning();
  error InvalidToken();
  error InvalidGameId(uint current, uint desired);
  error CheatsDisabled();

  // CONSTANTS

  event StateUpdated(uint gameID, Phase previous, Phase current, uint48 phaseScheduledEnd);
  event PlayerMoved(
    uint tokenID,
    uint oldLane,
    int oldLaneMultiplier,
    int oldLanePercentTrigger,
    int oldLanePercentBackfire,
    int oldLanePlayers,
    uint newLane,
    int newLaneMultiplier,
    int newLanePercentTrigger,
    int newLanePercentBackfire,
    int newLanePlayers,
    uint totalPlayers
  );
  mapping(uint => State) states;
  uint currentStateID;

  struct VRFState {
    bytes32 keyHash;
    uint64 subId;
    uint16 minimumRequestConfirmations;
    uint32 callbackGasLimit;
  }

  CozyRegistry private registry;
  VRFState private vrfState;
  VRFCoordinatorV2Interface private vrfCoordinator;
  bool public allowCheats;

  constructor(
    address _registry,
    address _coordinator,
    bytes32 _keyHash,
    uint64 _subId,
    uint16 _minimumRequestConfirmations,
    uint32 _callbackGasLimit,
    bool _allowCheats
  ) VRFConsumerBaseV2(_coordinator) {
    vrfCoordinator = VRFCoordinatorV2Interface(_coordinator);
    registry = CozyRegistry(_registry);
    states[0].initialize();

    vrfState.keyHash = _keyHash;
    vrfState.subId = _subId;
    vrfState.minimumRequestConfirmations = _minimumRequestConfirmations;
    vrfState.callbackGasLimit = _callbackGasLimit;

    allowCheats = _allowCheats;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(OPERATOR_ROLE, msg.sender);
  }

  function getPlayer(uint index) external view returns (uint) {
    State storage state = states[currentStateID];
    return state.players[index];
  }

  // -----------   Admin Cheats (for dev)   -----------
  function resetGame() public onlyRole(OPERATOR_ROLE) withCheats {
    State storage state = states[currentStateID];
    // clear lanes
    state.reset();
    emit StateUpdated(currentStateID, Phase.NONE, Phase.NONE, state.game.phaseScheduledEnd);
  }

  function tickStatus() public view returns (uint, Phase) {
    State storage state = states[currentStateID];
    return (state.game.phaseScheduledEnd, state.game.phase);
  }

  function canTick() public view returns (bool) {
    State storage state = states[currentStateID];
    return
      state.game.phase != Phase.NONE &&
      state.game.phase != Phase.END &&
      block.timestamp >= state.game.phaseScheduledEnd;
  }

  // -----------   Game Control   -----------

  function startGame(GameStartArgs memory args) public onlyRole(OPERATOR_ROLE) {
    if (
      states[currentStateID].game.phase != Phase.END &&
      states[currentStateID].game.phase != Phase.NONE
    ) {
      revert GameAlreadyRunning();
    }
    currentStateID++;
    states[currentStateID].start(args, currentStateID);
    emit StateUpdated(
      currentStateID,
      Phase.NONE,
      Phase.STARTING,
      states[currentStateID].game.phaseScheduledEnd
    );
  }

  function tickState(bool force) public {
    if (!(force || canTick())) {
      return;
    }

    _tickState();
  }

  function _tickState() internal {
    State storage state = states[currentStateID];

    Phase previousPhase = state.game.phase;
    state.gotoNextState();

    emit StateUpdated(
      currentStateID,
      previousPhase,
      state.game.phase,
      state.game.phaseScheduledEnd
    );

    if (previousPhase == Phase.MOVEMENT) {
      vrfCoordinator.requestRandomWords(
        vrfState.keyHash,
        vrfState.subId,
        vrfState.minimumRequestConfirmations,
        vrfState.callbackGasLimit,
        1
      );
    }

    if (previousPhase == Phase.VRF_REQUESTED) {
      state.sweepLanes(state.game.random);
      state.game.sweep++;
      state.game.lastRandom = state.game.random;
    }

    return;
  }

  // -----------   Game State View   -----------

  function getGameState() public view returns (GameState memory) {
    State storage state = states[currentStateID];
    return state.game;
  }

  function getLane(uint8 index) public view returns (LaneView memory) {
    State storage state = states[currentStateID];
    return state.getLane(index);
  }

  function getLanes() public view returns (LaneView[] memory) {
    State storage state = states[currentStateID];
    return state.getLanes();
  }

  function getLaunches(uint8 index) public view returns (LaunchView[] memory) {
    State storage state = states[currentStateID];
    return state.getLaunches(index);
  }

  function getTuningSet() public pure returns (TuningSet memory) {
    return Game1StateFunctions.getTuningSet();
  }

  // -----------   Player Control   -----------

  function switchLanes(uint tokenID, uint8 newLane) public {
    State storage state = states[currentStateID];
    if (msg.sender != registry.ownerOf(tokenID)) {
      revert InvalidToken();
    }
    uint8 oldLane = state.switchPlayerLane(tokenID, newLane);

    emit PlayerMoved(
      tokenID,
      oldLane,
      oldLane == 0xff ? int(0) : state.laneDistanceMultiplier(oldLane),
      oldLane == 0xff ? int(0) : state.lanePercentTrigger(oldLane),
      oldLane == 0xff ? int(0) : state.lanePercentBackfire(oldLane),
      oldLane == 0xff ? int(0) : state.lanes[oldLane].players,
      newLane,
      state.laneDistanceMultiplier(newLane),
      state.lanePercentTrigger(newLane),
      state.lanePercentBackfire(newLane),
      state.lanes[newLane].players,
      state.players.length
    );
  }

  // -----------   Player View   -----------

  function getPlayerBonus(int64 playerStreak) public pure returns (int64) {
    return Game1StateFunctions.getPlayerBonus(playerStreak);
  }

  function canMove() public view returns (bool) {
    State storage state = states[currentStateID];
    return state.canMove();
  }

  function getPlayerMoves(uint tokenID) public view returns (Move[] memory) {
    State storage state = states[currentStateID];
    return state.playerMoves[tokenID];
  }

  function minDistForPeriod(uint period) public view returns (int) {
    State storage state = states[currentStateID];
    return int(2 * period * period * state.game.distanceCoefficient);
  }

  function getNextPlayerStat(PlayerState memory prevStat, uint sweep)
    public
    view
    returns (PlayerState memory)
  {
    State storage state = states[currentStateID];
    return state.getNextPlayerStat(prevStat, sweep);
  }

  function getPlayerStatsForAllSweeps(uint tokenID, uint upToSweep)
    public
    view
    returns (PlayerState[] memory)
  {
    State storage state = states[currentStateID];

    uint limit = upToSweep > state.game.sweep ? state.game.sweep : upToSweep;
    PlayerState[] memory result = new PlayerState[](limit);
    PlayerState memory lastStat;
    lastStat.tokenId = tokenID;
    for (uint i = 0; i < limit; i++) {
      lastStat = state.getNextPlayerStat(lastStat, i);
      result[i] = lastStat;

      if (lastStat.culledOnSweep > 0) {
        break;
      }
    }
    return result;
  }

  function getPlayerStat(uint tokenID, uint upToSweep) public view returns (PlayerState memory) {
    State storage state = states[currentStateID];
    return state.getPlayerStat(tokenID, upToSweep);
  }

  function getPlayerStatBatch(uint cursor, uint batchSize)
    public
    view
    returns (PlayerStatBatch memory)
  {
    State storage state = states[currentStateID];
    return state.getPlayerStatBatch(cursor, batchSize);
  }

  // ----------- Game History -----------

  function getPlayerStatForGame(uint tokenID, uint gameID)
    public
    view
    returns (PlayerState memory)
  {
    if (gameID > currentStateID) {
      revert InvalidGameId(currentStateID, gameID);
    }
    State storage state = states[gameID];
    return state.getPlayerStat(tokenID, 0xffffffff);
  }

  function getCurrentGameID() public view returns (uint) {
    return currentStateID;
  }

  function getGameStateForGame(uint gameID) public view returns (GameState memory) {
    if (gameID > currentStateID) {
      revert InvalidGameId(currentStateID, gameID);
    }
    State storage state = states[gameID];
    return state.game;
  }

  // ----------- Keeper Interface -----------

  function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
    bytes memory empty;
    return (canTick(), empty);
  }

  function performUpkeep(bytes calldata) external override {
    tickState(false);
  }

  function fulfillRandomWords(uint, uint[] memory randomWords) internal override {
    uint randomness = randomWords[0];
    State storage state = states[currentStateID];
    state.game.random = randomness;

    _tickState();
  }

  // ----------- Utilties -----------

  modifier withCheats() {
    if (!allowCheats) {
      revert CheatsDisabled();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CozyRegistry is AccessControl {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");

  error InvalidPartnerAddress(address partnerAddress);

  uint public totalSupply;

  struct PartnerToken {
    address partnerAddress;
    uint partnerTokenId;
  }

  // Mapping from registry ID to owner addresses
  mapping(uint => address) private _owners;

  // Mapping from registry ID to partner token
  mapping(uint => PartnerToken) private _partnerTokens;

  // Mapping from partner token contents to registry ID
  mapping(address => mapping(uint => uint)) private _fromPartnerToken;

  // The allowlist for partner tokens
  mapping(address => bool) private _partnerAddressAllowlist;

  event RegistryEntryCreated(uint registryId, address indexed partnerAddress, uint partnerTokenId);
  event RegistryEntryTransferred(uint registryId, address indexed from, address indexed to);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(WRITER_ROLE, msg.sender);
  }

  // ----------- Getters -----------

  /**
   * Returns the owner of the given registry ID.
   *
   * Will return a zero address if there is no owner or if the registry entry
   * is invalidated by the allow list.
   */
  function ownerOf(uint registryId) external view returns (address) {
    PartnerToken storage token = _partnerTokens[registryId];
    if (_partnerAddressAllowlist[token.partnerAddress]) {
      return _owners[registryId];
    } else {
      return address(0);
    }
  }

  /**
   * Returns the registry ID given partner token information.
   *
   * Will return zero if registry entry does not exist.
   */
  function getRegistryId(address partnerAddress, uint partnerTokenId) external view returns (uint) {
    return _fromPartnerToken[partnerAddress][partnerTokenId];
  }

  /**
   * Returns the partner token associated with the given registry ID.
   *
   * Will return an empty partner token with a zero address if there is none.
   */
  function getPartnerToken(uint registryId) external view returns (PartnerToken memory) {
    return _partnerTokens[registryId];
  }

  /**
   * Returns whether the partner address is allowed in the registry.
   */
  function isPartnerAddressAllowed(address partnerAddress) external view returns (bool) {
    return _partnerAddressAllowlist[partnerAddress];
  }

  // ----------- Registration -----------

  /**
   * Registers a new owner to partner token information.
   *
   * Will create a new registry ID for the partner token information if the
   * partner token information has not been registered before.
   */
  function register(
    address owner,
    address partnerAddress,
    uint partnerTokenId
  ) public onlyRole(WRITER_ROLE) {
    if (!_partnerAddressAllowlist[partnerAddress]) {
      revert InvalidPartnerAddress(partnerAddress);
    }

    uint id = _getOrCreateRegistryId(partnerAddress, partnerTokenId);

    if (_owners[id] != owner) {
      address prevOwner = _owners[id];
      _owners[id] = owner;
      emit RegistryEntryTransferred(id, prevOwner, owner);
    }
  }

  /**
   * Internally get or create a registry ID associated with partner token
   * information.
   */
  function _getOrCreateRegistryId(address partnerAddress, uint partnerTokenId)
    internal
    returns (uint)
  {
    uint id = _fromPartnerToken[partnerAddress][partnerTokenId];

    if (id == 0) {
      totalSupply += 1;
      id = totalSupply;

      _fromPartnerToken[partnerAddress][partnerTokenId] = id;
      _partnerTokens[id] = PartnerToken(partnerAddress, partnerTokenId);

      emit RegistryEntryCreated(id, partnerAddress, partnerTokenId);
    }

    return id;
  }

  // -------- Administration -------

  function revokeOwner(uint registryId) external onlyRole(ADMIN_ROLE) {
    delete _owners[registryId];
  }

  function addPartnerAddress(address partnerAddress) external onlyRole(ADMIN_ROLE) {
    _partnerAddressAllowlist[partnerAddress] = true;
  }

  function removePartnerAddress(address partnerAddress) external onlyRole(ADMIN_ROLE) {
    delete _partnerAddressAllowlist[partnerAddress];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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
interface IERC165 {
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

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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