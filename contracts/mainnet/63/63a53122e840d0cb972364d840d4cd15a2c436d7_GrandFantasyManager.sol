pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./nftpickem.sol";

// Status 1 is loss, 2 is win, 0 is refund
struct ContestPerformance {
  bytes32 contestName;
  uint256 entryFee;
  uint256 payout;
  uint8 status;
  uint8 picksCorrect;
  uint8 totalPicks;
  address player;
}

contract GrandFantasyManager is ChainlinkClient {
  using Counters for Counters.Counter;
  using Chainlink for Chainlink.Request;

  // Variables to hold contest history for participants
  mapping (uint => ContestPerformance) public performances;
  mapping (address => uint[]) public playerPerformances;
  Counters.Counter private currentPerformanceId;

  // Gets current oracle address for The Rundown
  function getOracleAddress() external view returns (address) {
    return chainlinkOracleAddress();
  }

  // Sets oracle address for The Rundown
  function setOracle(address _oracle) external {
    require(msg.sender == administrator);
    setChainlinkOracle(_oracle);
  }

  // Sends all link in contract back to administrator
  function withdrawLink() public {
    require(msg.sender == administrator);
    LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
    require(linkToken.transfer(administrator, linkToken.balanceOf(address(this))), "Unable to transfer");
  }

  // Sets the JobId for The Rundown get resolved games job
  function setSpecId(bytes32 jobId) public {
    require(msg.sender == administrator);
    specId = jobId;
  }

  // Resolved game response that will be received from The Rundown oracle
  struct GameResolve {
    bytes32 gameId;
    uint8 homeScore;
    uint8 awayScore;
    uint8 statusId;
  }
  // Game data received from fulfill
  bytes[] public gamesFromOracle;

  function bytes32ToStr(bytes32 _bytes32) public pure returns (string memory) {
    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
        bytesArray[i] = _bytes32[i];
        }
    return string(bytesArray);
  }


  // Calls the rundown api to receive game results for the contest group with the
  // highest priority
  function requestGameResults(uint32 date, uint256 payment, uint contractGroup, uint gamesLength) private {
    Chainlink.Request memory request = buildChainlinkRequest(specId, address(this), this.fulfill.selector);
    uint i;
    string[] memory gameIds = new string[](gamesLength);
    if(contractGroup == 1) {
      for(i = 0; i<ncaabGames1.length; i++) {
        gameIds[i] = string(bytes32ToStr(ncaabGames1[i].rundownId));
      }
    } else if(contractGroup == 2) {
      for(i = 0; i<ncaabGames2.length; i++) {
        gameIds[i] = string(bytes32ToStr(ncaabGames2[i].rundownId));
      }
    } else if(contractGroup == 3) {
      for(i = 0; i<ncaabGames3.length; i++) {
        gameIds[i] = string(bytes32ToStr(ncaabGames3[i].rundownId));
      }
    }

    request.addUint("sportId", 5);
    request.add("market", "resolve");
    request.addUint("date", uint256(date));
    request.addStringArray("gameIds", gameIds);

    sendChainlinkRequest(request, payment);
  }

  // Callback function from request game results
  function fulfill(bytes32 _requestId, bytes[] memory _games) public recordChainlinkFulfillment(_requestId) {
    //Games come back here
    uint i;
    for(i=0; i<_games.length; i++) {
      gamesFromOracle.push(_games[i]);
    }
  }

  // Receives a group of contest performancs from a child contract
  // these contest performances are used to hold contest history
  function receivePerformance(ContestPerformance[] memory newPerformances) public {
    address sender = msg.sender;
    bool senderValid = false;

    uint i;
    for(i = 0; i<activeContracts1.current() + 1; i++) {
      if(ncaabContracts1[i] == sender) {
        senderValid = true;
      }
    }
    for(i = 0; i<activeContracts2.current(); i++) {
      if(ncaabContracts2[i] == sender) {
        senderValid = true;
      }
    }
    for(i = 0; i<activeContracts3.current(); i++) {
      if(ncaabContracts3[i] == sender) {
        senderValid = true;
      }
    }

    require(senderValid);

    for(i = 0; i<newPerformances.length; i++) {
      performances[uint(currentPerformanceId.current())] = newPerformances[i];
      playerPerformances[newPerformances[i].player].push(uint(currentPerformanceId.current()));
      currentPerformanceId.increment();
    }
  }

  function getPerformanceForPlayer(address playerWallet) public view returns(ContestPerformance[] memory) {
    uint[] memory performanceIds = playerPerformances[playerWallet];
    ContestPerformance[] memory returnPerformances = new ContestPerformance[](performanceIds.length);
    uint i;
    for(i = 0; i<performanceIds.length; i++) {
      returnPerformances[i] = performances[performanceIds[i]];
    }
    return returnPerformances;
  }


  // Queue for contest resolution
  mapping(uint256 => uint) queue;
  uint256 first = 1;
  uint256 last = 0;
  function enqueue(uint data) private {
      last += 1;
      queue[last] = data;
  }
  function dequeue() private returns (uint data) {
      require(last >= first);  // non-empty queue

      data = queue[first];

      delete queue[first];
      first += 1;
  }
  function peek() private view returns (uint data) {
    require(last >= first);
    data = queue[first];
  }

  // Holds all reusable ncaab contest smart contracts
  // and the games areas that will be populated for ongoing contest group
  address[] public ncaabContracts1;
  Game[] public ncaabGames1;
  bytes32[] public ncaabGameIds1;
  Counters.Counter private activeContracts1;
  address[] public ncaabContracts2;
  Game[] public ncaabGames2;
  bytes32[] public ncaabGameIds2;
  Counters.Counter private activeContracts2;
  address[] public ncaabContracts3;
  Game[] public ncaabGames3;
  bytes32[] public ncaabGameIds3;
  Counters.Counter private activeContracts3;
  bool ongoingContracts1;
  bool ongoingContracts2;
  bool ongoingContracts3;
  uint public maxChildContracts;
  // Address of the Grand Fantasy managed wallet that will perform administrative actions for the manager
  address public administrator;

  bytes32 specId;

  constructor(address _link, address _oracle, bytes32 jobId) {
    // Set chainlink token address and The Rundown oracle address
    setChainlinkToken(_link);
    setChainlinkOracle(_oracle);
    specId = jobId;


    // Set the administrator to be the contract owner initially
    administrator = msg.sender;

    ongoingContracts1 = false;
    ongoingContracts2 = false;
    ongoingContracts3 = false;

    // multiple of 4 since 4 contracts are deployed at a time for each group
    maxChildContracts = 32;

    currentPerformanceId.increment();
  }

  function setMaxChildContracts(uint max) public {
    require(msg.sender == administrator);
    maxChildContracts = max;
  }

  // Returns a list of contracts that the player is entered in
  // All remaining spaces in array filled with 0x0
  function getOngoingContractsForPlayer(address player) public view returns(address[] memory) {
    // Nearly all of these slots are not going to be filled, but this is technically the max
    address[] memory ongoingContracts = new address[](maxChildContracts * 3);
    uint numberOfOngoing = 0;

    uint i;
    for(i = 0; i<ncaabContracts1.length; i++) {
      GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts1[i]);
      if(pickEm.getEnteredToday(player)) {
        ongoingContracts[numberOfOngoing] = ncaabContracts1[i];
        numberOfOngoing++;
      }
    }
    for(i = 0; i<ncaabContracts2.length; i++) {
      GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts2[i]);
      if(pickEm.getEnteredToday(player)) {
        ongoingContracts[numberOfOngoing] = ncaabContracts2[i];
        numberOfOngoing++;
      }
    }
    for(i = 0; i<ncaabContracts3.length; i++) {
      GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts3[i]);
      if(pickEm.getEnteredToday(player)) {
        ongoingContracts[numberOfOngoing] = ncaabContracts3[i];
        numberOfOngoing++;
      }
    }

    return ongoingContracts;
  }

  // Returns a list of contracts that owe a player wei
  // all remaining spaces in array filled with 0x0
  function getContractsThatOwePlayer(address player) public view returns(address[] memory) {
    // Nearly all of these slots are not going to be filled, but this is technically the max
    address[] memory contractsThatOwe = new address[](maxChildContracts * 3);
    uint numberThatOwe = 0;

    uint i;
    for(i = 0; i<ncaabContracts1.length; i++) {
      GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts1[i]);
      if(pickEm.getWinningsOwed(player) > 0) {
        contractsThatOwe[numberThatOwe] = ncaabContracts1[i];
        numberThatOwe++;
      }
    }
    for(i = 0; i<ncaabContracts2.length; i++) {
      GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts2[i]);
      if(pickEm.getWinningsOwed(player) > 0) {
        contractsThatOwe[numberThatOwe] = ncaabContracts2[i];
        numberThatOwe++;
      }
    }
    for(i = 0; i<ncaabContracts3.length; i++) {
      GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts3[i]);
      if(pickEm.getWinningsOwed(player) > 0) {
        contractsThatOwe[numberThatOwe] = ncaabContracts3[i];
        numberThatOwe++;
      }
    }

    return contractsThatOwe;
  }

  // Checks whether or not new contest contracts are needed
  function needsDeployment() public view returns(bool[] memory) {
    bool[] memory needsDeploy = new bool[](3);

    // Cap the number of child contracts at 32 until we know exactly how this scales
    if(ncaabContracts1.length < maxChildContracts) {
      GrandFantasyNFTPickEm group1 = GrandFantasyNFTPickEm(ncaabContracts1[activeContracts1.current()]);
      if(group1.getContestOpen() && (group1.getCurrentEntrants() >= group1.getMaxEntrants()) && (ncaabContracts1.length < activeContracts1.current() + 2)) {
        needsDeploy[0] = true;
      }
    }

    if(ncaabContracts2.length <maxChildContracts) {
      GrandFantasyNFTPickEm group2 = GrandFantasyNFTPickEm(ncaabContracts2[activeContracts2.current()]);
      if(group2.getContestOpen() && (group2.getCurrentEntrants() >= group2.getMaxEntrants()) && (ncaabContracts2.length < activeContracts2.current() + 2)) {
        needsDeploy[1] = true;
      }
    }

    if(ncaabContracts3.length < maxChildContracts) {
      GrandFantasyNFTPickEm group3 = GrandFantasyNFTPickEm(ncaabContracts3[activeContracts3.current()]);
      if(group3.getContestOpen() && (group3.getCurrentEntrants() >= group3.getMaxEntrants()) && (ncaabContracts3.length < activeContracts3.current() + 2)) {
        needsDeploy[2] = true;
      }
    }

    return needsDeploy;
  }

  function needsScaling() public view returns(bool[] memory) {
    bool[] memory shouldScale = new bool[](3);
    GrandFantasyNFTPickEm group1 = GrandFantasyNFTPickEm(ncaabContracts1[activeContracts1.current()]);
    if(group1.getContestOpen() && (group1.getCurrentEntrants() >= group1.getMaxEntrants()) && (ncaabContracts1.length >= activeContracts1.current() + 2)) {
      shouldScale[0] = true;
    }

    GrandFantasyNFTPickEm group2 = GrandFantasyNFTPickEm(ncaabContracts2[activeContracts2.current()]);
    if(group2.getContestOpen() && (group2.getCurrentEntrants() >= group2.getMaxEntrants()) && (ncaabContracts2.length >= activeContracts2.current() + 2)) {
      shouldScale[1] = true;
    }

    GrandFantasyNFTPickEm group3 = GrandFantasyNFTPickEm(ncaabContracts3[activeContracts3.current()]);
    if(group3.getContestOpen() && (group3.getCurrentEntrants() >= group3.getMaxEntrants()) && (ncaabContracts3.length >= activeContracts3.current() + 2)) {
      shouldScale[2] = true;
    }

    return shouldScale;
  }

  function scaleGroup(uint8 group) public {
    require(msg.sender == administrator);

    uint i;
    if(group == 1) {
      for(i = 0; i<4; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts1[i]);
        pickEm.addGames(ncaabGames1);
        pickEm.performUpkeep();
      }
    } else if(group == 2) {
      for(i = 0; i<4; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts2[i]);
        pickEm.addGames(ncaabGames2);
        pickEm.performUpkeep();
      }
    } else if(group == 3) {
      for(i = 0; i<4; i++) {
        activeContracts3.increment();
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts3[i]);
        pickEm.addGames(ncaabGames3);
        pickEm.performUpkeep();
      }
    }
  }


  function deployToGroup(address[] memory contractsToAdd, uint8 group) public {
    require(msg.sender == administrator);
    require(contractsToAdd.length == 4);

    if(group == 1) {
      uint i;
      for(i = 0; i<4; i++) {
        ncaabContracts1.push(contractsToAdd[i]);
        if(ncaabGames1.length > 0) {
          GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(contractsToAdd[i]);
          pickEm.addGames(ncaabGames1);
          pickEm.performUpkeep();
        }
      }
    } else if(group == 2) {
      uint i;
      for(i = 0; i<4; i++) {
        ncaabContracts2.push(contractsToAdd[i]);
        if(ncaabGames2.length > 0) {
          GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(contractsToAdd[i]);
          pickEm.addGames(ncaabGames2);
          pickEm.performUpkeep();
        }
      }
    } else if(group == 3) {
      uint i;
      for(i = 0; i<4; i++) {
        ncaabContracts3.push(contractsToAdd[i]);
        if(ncaabGames3.length > 0) {
          GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(contractsToAdd[i]);
          pickEm.addGames(ncaabGames3);
          pickEm.performUpkeep();
        }
      }
    }
  }

  function pullContractsForContests() public view returns(address[] memory) {
    uint totalContractAddresses = activeContracts1.current() + 1;
    totalContractAddresses = totalContractAddresses + activeContracts2.current() + 1;
    totalContractAddresses = totalContractAddresses + activeContracts3.current() + 1;

    address[] memory contracts = new address[](totalContractAddresses);
    uint i;
    for(i = 0; i<activeContracts1.current() + 1; i++) {
      contracts[i] = ncaabContracts1[i];
    }
    for(i = 0; i<activeContracts2.current() + 1; i++) {
      contracts[i + activeContracts1.current() + 1] = ncaabContracts2[i];
    }
    for(i = 0; i<activeContracts3.current() + 1; i++) {
      contracts[i + activeContracts1.current() + 1 + activeContracts2.current() + 1] = ncaabContracts3[i];
    }

    return contracts;
  }

  function addGames(Game[] memory newGames) public {
    require(msg.sender == administrator);
    require(newGames.length <= 16);
    // There must be contracts available to run the contests on
    require(ongoingContracts1 == false || ongoingContracts2 == false || ongoingContracts3 == false);
    uint i;

    // There are not currently contests running on the contracts group 1
    if(ongoingContracts1 == false) {
      activeContracts1.reset();

      // Add games to first four contracts
      uint lengthToAdd = ncaabContracts1.length >= 4 ? 4 : 0;
      for(i = 0; i<lengthToAdd; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts1[i]);
        pickEm.addGames(newGames);

        if(i != lengthToAdd - 1) {
          activeContracts1.increment();
        }
      }
      for(i = 0; i<newGames.length; i++) {
        ncaabGameIds1.push(newGames[i].rundownId);
        ncaabGames1.push(newGames[i]);
      }

      // There are now contests ongoing on the contracts group 1
      ongoingContracts1 = true;
      enqueue(1);
    } else if(ongoingContracts2 == false) {
      activeContracts2.reset();

      // Add games to first four contracts
      uint lengthToAdd = ncaabContracts2.length >= 4 ? 3 : 0;
      for(i = 0; i<lengthToAdd; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts2[i]);
        pickEm.addGames(newGames);

        if(i != lengthToAdd - 1) {
          activeContracts2.increment();
        }
      }
      for(i = 0; i<newGames.length; i++) {
        ncaabGameIds2.push(newGames[i].rundownId);
        ncaabGames2.push(newGames[i]);
      }

      ongoingContracts2 = true;
      enqueue(2);
    } else if(ongoingContracts3 == false) {
        activeContracts3.reset();

        // Add game to first four contracts
        uint lengthToAdd = ncaabContracts3.length >= 4 ? 3 : 0;
        for(i = 0; i<lengthToAdd; i++) {
          GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts3[i]);
          pickEm.addGames(newGames);

          if(i != lengthToAdd - 1) {
            activeContracts3.increment();
          }
        }
        for(i = 0; i<newGames.length; i++) {
          ncaabGameIds3.push(newGames[i].rundownId);
          ncaabGames3.push(newGames[i]);
        }

        // There are now contests ongoing on the contracts group 3
        ongoingContracts3 = true;
        enqueue(3);
    }
  }

  // Makes request to oracle to get results for the highest priority games
  // that have ended.
  // Param apiKey is a valid key for the Rundown API
  function getWinners() public {
    require(msg.sender == administrator);

    // Peek which contest group is up next for resolution
    uint contractsToResolve = peek();
    uint gamesLength = 0;

    // Grab the start time of the last game to check alongside the current timestamp
    // Also populate a list of game ids to resolve
    uint i;
    uint32 lastGameStartTime = 0;
    uint256 firstStartTime = 2**256 - 1;
    if(contractsToResolve == 1) {
      gamesLength = ncaabGameIds1.length;
      for(i = 0; i<ncaabGames1.length; i++) {
        if(ncaabGames1[i].startTime > lastGameStartTime) {
          lastGameStartTime = ncaabGames1[i].startTime;
        }
        if(uint256(ncaabGames1[i].startTime) < firstStartTime) {
          firstStartTime = uint256(ncaabGames1[i].startTime);
        }
      }
    } else if(contractsToResolve == 2) {
      gamesLength = ncaabGameIds2.length;
      for(i = 0; i<ncaabGames2.length; i++) {
        if(ncaabGames2[i].startTime > lastGameStartTime) {
          lastGameStartTime = ncaabGames2[i].startTime;
        }
        if(uint256(ncaabGames2[i].startTime) < firstStartTime) {
          firstStartTime = uint256(ncaabGames2[i].startTime);
        }
      }
    } else if (contractsToResolve == 3) {
      gamesLength = ncaabGameIds3.length;
      for(i = 0; i<ncaabGames3.length; i++) {
        if(ncaabGames3[i].startTime > lastGameStartTime) {
          lastGameStartTime = ncaabGames3[i].startTime;
        }
        if(uint256(ncaabGames3[i].startTime) < firstStartTime) {
          firstStartTime = uint256(ncaabGames3[i].startTime);
        }
      }
    }


    // Only make the oracle request for the winners when the games are  over
    // Making the request before the games end will not be useful
    uint256 comparisonTimestamp = lastGameStartTime + 28800;
    if(block.timestamp > comparisonTimestamp) {
      uint256 payment = 0.1 * 10 ** 18;
      requestGameResults(lastGameStartTime, payment, contractsToResolve, gamesLength);
    }

    // For the case where games are on two different UTC days, we want to make sure we are pulling all games
    if(lastGameStartTime > uint32(firstStartTime)) {
      if(lastGameStartTime - uint32(firstStartTime) > 18000) {
        uint256 payment = 0.1 * 10 ** 18;
        requestGameResults(uint32(firstStartTime), payment, contractsToResolve, gamesLength);
      }
    }
  }

  // When called, takes scores received through oracle and distributes
  // to the correct child contract
  function distributeWinnersToContests() public {
    uint i;
    uint x;
    uint contractsToResolve = peek();

    // First, grab the games that have been received from the oracle
    // Assign winners to the existing games
    require(gamesFromOracle.length > 0);
    if(contractsToResolve == 1) {
      for(i = 0; i<gamesFromOracle.length; i++) {
        GameResolve memory game = abi.decode(gamesFromOracle[i], (GameResolve));
        for(x = 0; x<ncaabGames1.length; x++) {
          if(ncaabGames1[x].rundownId == game.gameId) {
            ncaabGames1[x].winner = game.homeScore > game.awayScore ? 1 : 2;
            break;
          }
        }
      }
    } else if(contractsToResolve == 2) {
      for(i = 0; i<gamesFromOracle.length; i++) {
        GameResolve memory game = abi.decode(gamesFromOracle[i], (GameResolve));
        for(x = 0; x<ncaabGames2.length; x++) {
          if(ncaabGames2[x].rundownId == game.gameId) {
            ncaabGames2[x].winner = game.homeScore > game.awayScore ? 1 : 2;
            break;
          }
        }
      }
    } else if(contractsToResolve == 3) {
      for(i = 0; i<gamesFromOracle.length; i++) {
        GameResolve memory game = abi.decode(gamesFromOracle[i], (GameResolve));
        for(x = 0; x<ncaabGames3.length; x++) {
          if(ncaabGames3[x].rundownId == game.gameId) {
            ncaabGames3[x].winner = game.homeScore > game.awayScore ? 1 : 2;
            break;
          }
        }
      }
    }

    // Next, make sure that we have the winner for every single
    // game
    if(contractsToResolve == 1) {
      for(i = 0; i<ncaabGames1.length; i++) {
        require(ncaabGames1[i].winner > 0);
      }
    } else if(contractsToResolve == 2) {
      for(i = 0; i<ncaabGames2.length; i++) {
        require(ncaabGames2[i].winner > 0);
      }
    } else {
      for(i = 0; i<ncaabGames3.length; i++) {
        require(ncaabGames3[i].winner > 0);
      }
    }

    // If we've made it here, we have all necessary winners to proceed
    // we can dequeue and resolve the contests
    contractsToResolve = dequeue();
    if(contractsToResolve == 1) {
      uint8[] memory finalGameWinners = new uint8[](ncaabGameIds1.length);
      for(x = 0; x<ncaabGames1.length; x++) {
        finalGameWinners[x] = ncaabGames1[x].winner;
      }

      for(i = 0; i<activeContracts1.current() + 1; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts1[i]);
        pickEm.receiveWinners(finalGameWinners);
      }

      ongoingContracts1 = false;
      delete ncaabGameIds1;
      delete ncaabGames1;
      delete gamesFromOracle;
    } else if(contractsToResolve == 2) {
      uint8[] memory finalGameWinners = new uint8[](ncaabGameIds2.length);
      for(x = 0; x<ncaabGames2.length; x++) {
        finalGameWinners[x] = ncaabGames2[x].winner;
      }

      for(i = 0; i<activeContracts2.current() + 1; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts2[i]);
        pickEm.receiveWinners(finalGameWinners);
      }

      ongoingContracts2 = false;
      delete ncaabGameIds2;
      delete ncaabGames2;
      delete gamesFromOracle;
    } else if(contractsToResolve == 3) {
      uint8[] memory finalGameWinners = new uint8[](ncaabGameIds3.length);
      for(x = 0; x<ncaabGames3.length; x++) {
        finalGameWinners[x] = ncaabGames3[x].winner;
      }

      for(i = 0; i<activeContracts3.current() + 1; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts3[i]);
        pickEm.receiveWinners(finalGameWinners);
      }

      ongoingContracts3 = false;
      delete ncaabGameIds3;
      delete ncaabGames3;
      delete gamesFromOracle;
    }
  }

  // This function is an emergency alternative to resolving contests
  // with chainlink oracles
  // If the oracle service is down or data is problematic, any contest can be
  // refunded
  function refundContest() public {
    require(msg.sender == administrator);

    uint contractsToRefund = dequeue();
    uint i;
    if(contractsToRefund == 1) {
      for(i = 0; i<activeContracts1.current() + 1; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts1[i]);
        pickEm.refundContest();
      }

      delete ncaabGameIds1;
      delete ncaabGames1;
      delete gamesFromOracle;
    } else if(contractsToRefund == 2) {
      for(i = 0; i<activeContracts2.current() + 1; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts2[i]);
        pickEm.refundContest();
      }

      delete ncaabGameIds2;
      delete ncaabGames2;
      delete gamesFromOracle;
    } else if(contractsToRefund == 3) {
      for(i = 0; i<activeContracts3.current() + 1; i++) {
        GrandFantasyNFTPickEm pickEm = GrandFantasyNFTPickEm(ncaabContracts3[i]);
        pickEm.refundContest();
      }

      delete ncaabGameIds3;
      delete ncaabGames3;
      delete gamesFromOracle;
    }
  }
}

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./grandfantasymanager.sol";

// Struct that represents a game for the PickEm
// Team1Name and Team2Name up to 32 characters
// startTime is unix timestamp
// winner will be set to 1 or 2 after the game concludes, depending on which team won
struct Game {
  bytes32 team1Name;
  bytes32 team2Name;
  uint32 startTime;
  uint16 id;
  uint8 winner;
  bytes32 rundownId;
}

contract GrandFantasyNFTPickEm {
  using Counters for Counters.Counter;

  // Whether or not players can place picks, this will be set to false before game begin
  bool public contestOpen;

  // Address of the Grand Fantasy managed wallet that will perform administrative actions for the contest
  address public administrator;

  // Address of Grand Fantasy contest manager smart contract that handles deployment of contests
  address public managerAddress;

  // UNIX timestamp of what time the next PickEm competition will open for entries...0 for not scheduled
  uint32 public nextContestStartTime;

  // UNIX timestamp of the start time of the earliest game added to the contest
  uint32 public firstGameStartTime;

  // UNIX timestamp of the start time of the latest game added to the contest
  uint32 public lastGameStartTime;

  // Boolean indicating whether or not the winners for the games have been sent in
  bool public gameWinnersReceived;

  // Boolean indicating whether or not all past contests on this contract have been resolved
  bool public contestResolved;

  // The number of correct picks a user needs to be deemed a winner of the current contest
  uint8 public requirementToWin;

  // The number of total picks a user needs to submit to be entered in to a contest
  // This is calculated when adding games to the contest
  uint8 public totalPicksRequired;

  // In wei, the prize pool of the current contest
  // Prize pool goes up with each entry
  uint256 public prizePool;

  // Name of the contest for display in the client side UI
  bytes32 public contestName;

  // Entry fee, in wei, for the contest
  uint256 public weiEntryFee;

  // Counter to keep track of how many entrants there are in the current contest
  Counters.Counter private currentEntrants;

  // Maximum number of entrants for the contest
  uint32 public maxEntrants;

  // Counter to apply an id to user pick selections
  Counters.Counter private currentPickId;

  // Array of addresses that will hold the winners of the current contest
  // Array will be populated from the end of one contest until the next is set up
  address[] public winners;

  // Chainlink upkeep variables used in order to update contests automatically
  // and without direct administrator intervention
  uint public immutable interval;
  uint public lastTimeStamp;

  // Maps GameIds to game struct
  mapping (uint16 => Game) public games;

  constructor(uint updateInterval, bytes32 name, uint256 entryFee, address manager) {
    // Set the administrator to be the contract owner initially
    administrator = msg.sender;

    // Set metadata for the contest contract
    contestName = name;
    weiEntryFee = entryFee;

    // Set the contest manager contract
    managerAddress = manager;

    // Increment the currentPickId so it starts at 1
    currentPickId.increment();

    // Make is so the admin is able to create a new contest by default
    contestResolved = true;

    // Set chainlink upkeep variables
    interval = updateInterval;
    lastTimeStamp = 0;
  }

  // Determines whether or not upkeep is needed on the contract
  function checkUpkeep() external view returns (bool upkeepNeeded) {
    if((block.timestamp - lastTimeStamp) > interval) {
      // If there have been no games added or contest details have not been added, there is no upkeep to perform
      if(totalPicksRequired > 0 && requirementToWin > 0) {
        upkeepNeeded = true;
      } else {
        upkeepNeeded = false;
      }
    } else {
      upkeepNeeded = false;
    }
  }

  function performUpkeep() external {
    require(msg.sender == administrator || msg.sender == managerAddress);
    lastTimeStamp = block.timestamp;

    // If the contest is closed for entries, but the next contest has been scheduled
    if(!contestOpen && nextContestStartTime > 0) {
      // Open the contest for entries if the current date is an hour or less before
      // the scheduled time to open entries
      if(block.timestamp > nextContestStartTime) {
        contestOpen = true;
        nextContestStartTime = 0;
        contestResolved = false;
      } else if(nextContestStartTime - block.timestamp <= 3600) {
        contestOpen = true;
        nextContestStartTime = 0;
        contestResolved = false;
      }
    }
    // If the contest is closed for entries and a contest is ongoing
    else if(!contestOpen && nextContestStartTime == 0 && gameWinnersReceived) {
      // Resolve contest and pay out winners if it has been at least 8 hours since the start
      // time of the lastest game
      // This also requires knowing the outcome of the games
      if(block.timestamp > lastGameStartTime && block.timestamp - lastGameStartTime >= 28800) {
        markForPayout();
      }
    }
    // If entries for the contest are currently open
    else if(contestOpen) {
      // Close contest entries if upkeep is happening within an hour and a half of the
      // earliest game
      if(block.timestamp > firstGameStartTime) {
        contestOpen = false;
        if(currentEntrants.current() < 3) {
          refundContest();
        }
      } else if(firstGameStartTime - block.timestamp <= 5400) {
        contestOpen = false;
        if(currentEntrants.current() < 3) {
          refundContest();
        }
      }
    }
}


  // Returns the number of current entrants into the contest
  function getCurrentEntrants() public view returns (uint) {
    return currentEntrants.current();
  }

  // Returns the number of maximum entrants into the contest
  function getMaxEntrants() public view returns (uint) {
    return maxEntrants;
  }

  function getContestOpen() public view returns (bool) {
    return contestOpen;
  }

  // Passes administration privleges to a new address
  // ADMINISTRATOR ONLY
  function passAdministrationPrivleges(address newAdministrator) public {
    require(msg.sender == administrator);
    administrator = newAdministrator;
  }

  // Function that sets the start time, number of picks required to win, and
  // maximum entrants of a new contest
  // ADMINISTRATOR ONLY
  // Param startTime - unix timestamp for start time
  // Param requirement - # of correct picks required to win the PickEm contest
  // Param max - maximum entrants into this contest
  function setContestDetails(uint32 startTime) private {
    require(contestResolved);

    // Winners could still be populated from a previous contest, clear the array
    delete winners;

    nextContestStartTime = startTime;

    uint8 requirement = totalPicksRequired - (totalPicksRequired / 3);
    requirementToWin = requirement;
    maxEntrants = 20;
  }

  // Returns an array of all games that have been added to the contest
  function getGames() public view returns(Game[] memory) {
    Game[] memory allGames = new Game[](totalPicksRequired);
    uint i;
    for(i = 0; i < totalPicksRequired; i++) {
      allGames[i] = games[uint16(i)];
    }
    return allGames;
  }

  // Struct that represents a single user pick for the PickEm
  // Pick is a value 1 to pick team1 or 2 to pick team2
  struct Pick {
    uint16 gameId;
    uint8 pick;
    uint24 pickId;
  }
  mapping (uint24 => Pick) public picks;

  // Struct that represents a player in a PickEm contest
  // playerAddress, weiOwed will be persistent accross contests
  struct Player {
    address playerAddress;
    uint24[] pickIds;
    uint256 weiOwed;
    bool enteredToday;
  }
  mapping (address => Player) public playerStructs;

  // Holds the players that have entered into the current contest
  address[] public playersToday;

  // Adds [games] for use in the PickEm contest. Winner value of these games will be set to 0.
  // ADMINISTRATOR ONLY - this will be called each day at
  // Param newGames are the games to add to the games mapping
  function addGames(Game[] memory newGames) public {
    require(msg.sender == managerAddress);
    require(contestResolved);

    if(newGames.length > 0) {
      totalPicksRequired = uint8(newGames.length);

      // Only the administrator can send in games and
      // will not send more than how many PickEm games are in a day. Likely ~10
      uint i;

      // Use max int for comparison
      uint256 firstStartTime = 2**256 - 1;
      uint32 lastStartTime;
      for (i = 0; i < newGames.length; i++) {
        // Record the start time of the earliest game and the start time of the
        // lastest game
        if(uint256(newGames[i].startTime) < firstStartTime) {
          firstStartTime = uint256(newGames[i].startTime);
        }
        if(newGames[i].startTime > lastStartTime) {
          lastStartTime = newGames[i].startTime;
        }

        games[newGames[i].id] = newGames[i];
      }

      // Save earliest and latest start time to storage
      firstGameStartTime = uint32(firstStartTime);
      lastGameStartTime = lastStartTime;

      // Open contest for entries 24 hours before games
      uint256 contestStartTime = firstStartTime - 86400;
      setContestDetails(uint32(contestStartTime));
    }
  }

  // Function to make picks here
  function submitPicksForContest(uint8[] memory playerPicks) public payable {
    // Require contest to be open to place picks
    require(contestOpen);

    // Require the entrants to not be over the max
    require(currentEntrants.current() < maxEntrants);

    // Require the value of the transaction to be over the wei entry fee
    require(msg.value >= weiEntryFee);

    address player = msg.sender;
    // Only one entry allowed per player
    require(playerStructs[player].enteredToday == false);
    // # of picks submitted must exactly equal the number of games
    require(playerPicks.length == totalPicksRequired);

    uint i;
    for(i = 0; i<playerPicks.length; i++) {
      // Picks must either be for team 1 or team 2, no other values
      require(playerPicks[i] == 1 || playerPicks[i] == 2);

      // Create data for each pick
      Pick memory newPick;
      newPick.gameId = uint16(i);
      newPick.pick = playerPicks[i];
      uint24 newPickId = uint24(currentPickId.current());
      newPick.pickId = newPickId;

      // This is a new player, initialize them in the struct
      if(i == 0 && playerStructs[player].playerAddress == address(0x0)) {
        Player memory newPlayer;
        newPlayer.playerAddress = player;
        playerStructs[player] = newPlayer;
        playerStructs[player].pickIds.push(newPickId);
      } else {
        playerStructs[player].pickIds.push(newPickId);
      }

      // Reflect the new pick in the picks struct
      picks[newPickId] = newPick;

      // Increment the counter so each pick has a unique id
      currentPickId.increment();
    }

    // Player has been successfully entered in the current contest
    playerStructs[player].enteredToday = true;
    playersToday.push(player);
    currentEntrants.increment();
    prizePool = prizePool + weiEntryFee;
  }

  function getPicksForPlayer(address player) public view returns(Pick[] memory) {
    uint24[] memory playerPickIds = playerStructs[player].pickIds;
    Pick[] memory playerPicks = new Pick[](playerPickIds.length);
    uint i;
    for(i = 0; i<playerPickIds.length; i++) {
      playerPicks[i] = picks[playerPickIds[i]];
    }
    return playerPicks;
  }

  function receiveWinners(uint8[] memory finalGames) public {
    require(msg.sender == managerAddress);

    // If the contest has been refunded, we don't want to do any of this
    if(contestResolved == false) {
      uint i;
      // Update all game structs to contain the winners using administrator data
      for(i = 0; i < finalGames.length; i++) {
        games[uint16(i)].winner = finalGames[i];
      }

      gameWinnersReceived = true;
    }
  }

  function markForPayout() private {
    uint i;
    uint8 correctPicks;
    uint x;
    ContestPerformance[] memory contestPerformances = new ContestPerformance[](currentEntrants.current());

    // At this point, the winner portion of the games structs are set
    // Go through all players today
    for(i = 0; i < playersToday.length; i++) {
      Player memory player = playerStructs[playersToday[i]];

      correctPicks = 0;

      // For each player today, go through each of their picks
      // Number of pickIds is bounded by the number of games added for the contest, usually ~10
      for(x = 0; x < player.pickIds.length; x++) {
        Pick memory pick = picks[player.pickIds[x]];
        Game memory game = games[pick.gameId];

        // If the pick aligns with the winner, it was correct
        if(game.winner == pick.pick) {
          correctPicks++;
        }
      }

      // Clear the pick ids, they will never be needed again but we may need this field again
      delete player.pickIds;

      // Remove entered today so that players will be able to enter the next contest
      player.enteredToday = false;

      // If the player has enough correct picks, they are officially a winner
      ContestPerformance memory newPerformance;
      if(correctPicks >= requirementToWin) {
        newPerformance.contestName = contestName;
        newPerformance.entryFee = weiEntryFee;
        newPerformance.payout = 0;
        newPerformance.status = 2;
        newPerformance.picksCorrect = correctPicks;
        newPerformance.totalPicks = totalPicksRequired;
        newPerformance.player = playersToday[i];
        contestPerformances[i] = newPerformance;

        winners.push(player.playerAddress);
      } else {
        newPerformance.contestName = contestName;
        newPerformance.entryFee = weiEntryFee;
        newPerformance.payout = 0;
        newPerformance.status = 1;
        newPerformance.picksCorrect = correctPicks;
        newPerformance.totalPicks = totalPicksRequired;
        newPerformance.player = playersToday[i];
        contestPerformances[i] = newPerformance;
      }

      // Set memory variable back to storage so that changes persist
      playerStructs[playersToday[i]] = player;
    }

    // Calculate payout by dividing prize pool by # of winners
    // Take a 10% rake here
    uint256 payout;
    if(winners.length > 0) {
      payout = (prizePool / 10 * 9) / winners.length;
    } else {
      playerStructs[administrator].weiOwed = playerStructs[administrator].weiOwed + prizePool;
    }

    bool takeRake = false;

    for(i = 0; i < winners.length; i++) {
      if(payout < weiEntryFee) {
        playerStructs[winners[i]].weiOwed = playerStructs[winners[i]].weiOwed + weiEntryFee;
      } else {
        playerStructs[winners[i]].weiOwed = playerStructs[winners[i]].weiOwed + payout;
        takeRake = true;
      }
    }

    for(i = 0; i<contestPerformances.length; i++) {
      if(payout < weiEntryFee &&  (contestPerformances[i].picksCorrect >= requirementToWin)) {
        contestPerformances[i].payout = contestPerformances[i].payout + weiEntryFee;
      } else if(contestPerformances[i].picksCorrect >= requirementToWin) {
        contestPerformances[i].payout = contestPerformances[i].payout + payout;
      }
    }

    GrandFantasyManager manager = GrandFantasyManager(managerAddress);
    manager.receivePerformance(contestPerformances);

    if(takeRake) {
      // The administrator wallet is able to withdraw the rake
      uint256 rake = prizePool / 10;
      playerStructs[administrator].weiOwed = playerStructs[administrator].weiOwed + rake;
    }

    // Delete all games from the games mapping
    for(i = 0; i < totalPicksRequired; i++) {
      delete games[uint16(i)];
    }

    // Do some housekeeping to get ready for any future contests
    requirementToWin = 0;
    totalPicksRequired = 0;
    prizePool = 0;
    maxEntrants = 0;
    firstGameStartTime = 0;
    lastGameStartTime = 0;
    gameWinnersReceived = false;
    contestResolved = true;

    delete playersToday;
    currentEntrants.reset();
  }

  //Function to refund contest
  function refundContest() public {
    require(msg.sender == administrator || msg.sender == managerAddress);
    uint i;
    ContestPerformance[] memory refundPerformances = new ContestPerformance[](playersToday.length);
    for(i = 0; i < playersToday.length; i++) {
      Player memory player = playerStructs[playersToday[i]];

      // Clear the pick ids, they will never be needed again but we may need this field again
      delete player.pickIds;

      // Remove entered today so that players will be able to enter the next contest
      player.enteredToday = false;

      // Refund the entry fee to the contest
      player.weiOwed = player.weiOwed + weiEntryFee;


      // Set memory variable back to storage so that changes persist
      playerStructs[playersToday[i]] = player;

      ContestPerformance memory newPerformance;
      newPerformance.contestName = contestName;
      newPerformance.entryFee = weiEntryFee;
      newPerformance.payout = weiEntryFee;
      newPerformance.status = 0;
      newPerformance.picksCorrect = 0;
      newPerformance.totalPicks = 0;
      newPerformance.player = playersToday[i];
      refundPerformances[i] = newPerformance;
    }

    GrandFantasyManager manager = GrandFantasyManager(managerAddress);
    manager.receivePerformance(refundPerformances);

    // Delete all games from the games mapping
    for(i = 0; i < totalPicksRequired; i++) {
      delete games[uint16(i)];
    }

    // Do some housekeeping to get ready for any future contests
    requirementToWin = 0;
    totalPicksRequired = 0;
    prizePool = 0;
    maxEntrants = 0;
    firstGameStartTime = 0;
    lastGameStartTime = 0;
    gameWinnersReceived = false;
    contestResolved = true;

    delete playersToday;
    currentEntrants.reset();
  }

  // If a wallet is owed wei from contests, they can call upon this function
  // to withdraw this money
  function withdrawWinnings() public {
    if(playerStructs[msg.sender].weiOwed > 0) {
      uint maticToSend = playerStructs[msg.sender].weiOwed;
      playerStructs[msg.sender].weiOwed = 0;
      payable(msg.sender).transfer(maticToSend);
    }
  }

  function getWinningsOwed(address player) public view returns(uint) {
    return playerStructs[player].weiOwed;
  }

  function getEnteredToday(address player) public view returns(bool) {
    return playerStructs[player].enteredToday;
  }
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
library Counters {
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
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

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

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}