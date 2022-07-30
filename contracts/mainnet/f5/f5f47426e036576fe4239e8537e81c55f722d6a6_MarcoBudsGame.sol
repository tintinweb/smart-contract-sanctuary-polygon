// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*

    __  ___                           __                __     
   /  |/  /____ _ _____ _____ ____   / /_   __  __ ____/ /_____
  / /|_/ // __ `// ___// ___// __ \ / __ \ / / / // __  // ___/
 / /  / // /_/ // /   / /__ / /_/ // /_/ // /_/ // /_/ /(__  ) 
/_/  /_/ \__,_//_/    \___/ \____//_.___/ \__,_/ \__,_//____/  
   ______                                                      
  / ____/____ _ ____ ___   ___                                 
 / / __ / __ `// __ `__ \ / _ \                                
/ /_/ // /_/ // / / / / //  __/                                
\____/ \__,_//_/ /_/ /_/ \___/                                 
                                                               

Discord: https://discord.io/Marcobuds
Twitter: https://twitter.com/MarcobudsNft
Website: https://marcobuds.io
*/


interface ERC721Interface{
      function ownerOf(uint256) external view returns (address);
}


contract MarcoBudsGame is VRFConsumerBaseV2,Pausable,Ownable {


  // [Chainlink VRF config block]
        VRFCoordinatorV2Interface COORDINATOR;
        // subscription ID.
        uint64 s_subscriptionId;
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        // address vrfCoordinator = 	0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
        
        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        // test net (Polygon)
        // bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
        // main net (Polygon)
        bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;

        

        // Depends on the number of requested values that you want sent to the
        // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
        // so 2500,000 is a safe default for this contract. If you are using tnis 
        // in another contract, make sure to Test and adjust
        // this limit based on the network that you select, the size of the request,
        // and the processing of the callback request in the fulfillRandomWords()
        // function.
        uint32 callbackGasLimit = 2500000;

        // The default is 3, but you can set this higher.
        uint16 requestConfirmations = 3;

        // For this example, retrieve 2 random values in one request.
        // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
        uint32 constant numWords =  1;
  // [End of Chainlink VRF config block]



// Win percentages and Race track values 

enum SORT_TYPE{ TOTAL_WIN,TOTAL_GAMES }


uint256[] private WIN_PERCENTAGES = [0,22,45,70,100];

string[] private TRACK_VALUES = ["-2", "0", "2", "4", "3", "-1", "-3", "1", "-4",
                                "2"," -1" , "3" , "-4",  "1",  "-3",  "-2",  "4",  "0",
                                "1" , "-1" , "-3" , "3" , "4" , "-4" , "2" , "-2" ,"0",
                                 "1",  "3",  "0",  "2",  "-2",  "-3",  "-4",  "-1",  "4",
                                 "-1",  "4" , "1" , "3",  "-4" , "2" , "-2",  "-3" , "0",
                                 "-3" , "2",  "3",  "1",  "-1",  "4",  "-2",  "-4",  "0",
                                 "2",  "0",  "1",  "-4",  "3",  "-3",  "-1",  "4",  "-2",
                                 "0" , "3",  "-3",  "2" , "-1" , "4" , "-2" , "-4" , "1",
                                 "-2", "3",  "0",  "1", "-4",  "-1", "-3",  "2",  "4" ];
                                
uint256 constant public MAX_NFT_SUPPLY = 2200;
uint256 constant public PLAYERS_COUNT = 4; 


    // MarcoBuds Game Data Structure  

    struct Game {
      uint256 id;
      uint256[PLAYERS_COUNT] players;
      uint256[PLAYERS_COUNT] effects;
      string[PLAYERS_COUNT] tracks;
      uint256 timestamp;
      uint256 winnerTokenId;
      uint256 map;
      uint256 text;
      uint256 rndResult; 
    }


    struct MarcoBudsToken {
      uint256 tokenId;
      uint256 totalGamesPlayed;
      uint8 communityShareQualified;
      uint256 totalWonGames;
      uint256 totalLostGames;
      uint256 balance;
    }

    // Dev addresses
    address dev1;
    address dev2;
    address advisor;

   // Total Games Value
    uint256 public totalGamesValues = 0 ether;

   
    // Balances & Shares
    
    uint256 public devBalance = 0 ether;
    uint256 public communityBalance = 0 ether;


    // Minimum balance to distrubte for community only
    uint256 public constant MINIMUM_COMMUNITY_BALANCE = 1 ether;




    // NFT MarcoBuds Contract . Used to check ownership of a token
    ERC721Interface internal MARCOBUDS_CONTRACT;


    //  Minimum Game Value set to 1. This means minimum entry fee is 0.25 
    uint256 public constant MINIMUM_GAME_VALUE = 1 ether;
 

    // Initial values of total game value and their disturbtions. Initial values don't matter here as it has to be passed in the constructor anyway. 
    uint256 public GAME_VALUE = 6 ether;
    // disturbtions based on total game value
    uint256 public ENTRY_FEE = 1.5 ether;
    uint256 public WIN_SHARE = 3.06 ether;
    uint256 public LOSS_SHARE = 0.68 ether;
    uint256 public DEV_SHARE = 0.6 ether;
    uint256 public COMMUNITY_SHARE = 0.3 ether;


    // Minimum games played to be qualified for community shares. On the fifth game the nft holder will be qualified 
    uint256 constant public COMMUNITY_MINIMUM_GAMES = 4; 

    // Tokens count that are qulaified for getting community shares
    uint256 public qualifiedTokensCount = 0;


    // Players waiting to start the game
    mapping(uint256 => uint256) public pendingPlayers;
    uint256 public pendingPlayersCount; 

    // Games & Tokens data
    mapping(uint256 => MarcoBudsToken) public marcobudsTokens;
    mapping(uint256 => Game) public games;
    uint256 public gamesCounter;

    // Random range minimum and maximum
    uint256 constant private min = 1;
    uint256 constant private max = 100;
    
    // VRF Request Id => Games Ids
    mapping(uint256 => uint256) public requestIdToGameId;

    // Limit of top marcobuds  
    uint256 constant public TOP_LIMIT = 30; 

    // index to tokenId
    mapping(uint256 => uint256) public topTokensBytotalWonGames;
    mapping(uint256 => uint256) public topTokensByTotalGamesPlayed;




// Game Events
event GameJoined(uint256 _MarcoBudsTokenId);
event GameStarted(Game _game);
event GameEnded(uint256 _GameId,uint256 _MarcoBudsTokenId);

// Config Events
event VRFConfigUpdated(uint64 subscriptionId,uint32 _callbackGasLimit,uint16 _requestConfirmations,bytes32 _keyHash);
event EntryFeeUpdated(uint256 totalGameValue);
event TeamAddressesUpdated(address dev1,address dev2,address advisor);


      constructor(address MarcoBudsContractAddress,uint64 subscriptionId,address _vrfCoordinator,bytes32 _keyHash,uint256 totalGameValue) VRFConsumerBaseV2(_vrfCoordinator) {
        require(MarcoBudsContractAddress != address(0), "MarcoBudsContractAddress can not be zero");
        require(_vrfCoordinator != address(0), "_vrfCoordinator can not be zero");
        MARCOBUDS_CONTRACT = ERC721Interface(MarcoBudsContractAddress);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        setEntryFee(totalGameValue);
      }


      // change VRF config if needed. for example, if subscription Id changed ...etc.
      function setVRFConfig(uint64 subscriptionId,uint32 _callbackGasLimit,uint16 _requestConfirmations,bytes32 _keyHash) external onlyOwner {
        s_subscriptionId = subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        keyHash = _keyHash;
        emit VRFConfigUpdated(subscriptionId,_callbackGasLimit,_requestConfirmations,_keyHash);
      }


      // Pausing functionality only for joining a new game. claiming will always work no matter
      function pause() external onlyOwner {
          _pause();
      }

      function unpause() external onlyOwner {
          _unpause();
      }


     // Requets a random number from ChainLink 
    function getRandomNumber() internal returns (uint256 requestId) {
        return COORDINATOR.requestRandomWords(
          keyHash,
          s_subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          numWords
        );
    }

     // Receive the requested random number from ChainLink 
    function fulfillRandomWords(
      uint256 requestId, 
      uint256[] memory randomWords
    ) internal override {
        uint256 randomResult = (randomWords[0] % max) + min;
        pickWinner(requestId,randomResult);
    }


    // get a track for a Marcobuds token (player)
    function getTrack(uint256 baseNum,uint256 MBTokenId) internal view returns (string memory){
        require(TRACK_VALUES.length > 72,"TRACK_VALUES length must be greater than 72");
        uint256 startIndex = (baseNum + MBTokenId) % (TRACK_VALUES.length - 72);
        uint256 endIndex =  startIndex+9;
        string memory track = TRACK_VALUES[startIndex];
        for(uint256 i=startIndex+1; i < endIndex ; i ++) {
            track = string(abi.encodePacked(track,",", TRACK_VALUES[i]));
        }
        return track;
    }

    // get game map
    function getMap(uint256 baseNum) internal pure returns (uint256){
        return ((baseNum * 7) % 4)+1;
    }


    // get game text
    function getText(uint256 baseNum) internal pure returns (uint256){
        return (baseNum % 10)+1;
    }

    // get game effect
    function getEffect(uint256 baseNum,uint256 MBTokenId) internal pure returns (uint256){
        return ((baseNum + MBTokenId) % 6)+1;
    }


    // Select the winner based on the random result considering total games played for each player
    function pickWinner(uint256 requestId,uint256 randomResult) internal{

        uint256 gameId = requestIdToGameId[requestId];
        sortPlayersByTotalGamesPlayed(gameId);
        Game storage game = games[gameId];
        game.winnerTokenId = getWinnerTokenId(gameId,randomResult); 
        game.rndResult = randomResult;
        game.timestamp = block.timestamp;
        // randomResult is between 1 and 100
        game.map = getMap(randomResult+gamesCounter);
        game.text = getText(randomResult+gamesCounter+3);
        setPlayersEffects(gameId,randomResult);
        setPlayersTracks(gameId,randomResult);


        // Winner and Losers shares
        calculateShares(gameId);


        // Keep track of top winners 
        bool alreadyAdded = false;
        uint256 smallestTokenIdIndex = 1; //topTokensBytotalWonGames[1];  
        if(topTokensBytotalWonGames[smallestTokenIdIndex] == game.winnerTokenId){
            alreadyAdded = true;
        }
        if(!alreadyAdded){
          for (uint256 k=2; k<=TOP_LIMIT; k++) {
            if(topTokensBytotalWonGames[k] == game.winnerTokenId){
              alreadyAdded = true;
              break;
            }
            if(marcobudsTokens[topTokensBytotalWonGames[k]].totalWonGames < marcobudsTokens[topTokensBytotalWonGames[smallestTokenIdIndex]].totalWonGames){
                smallestTokenIdIndex = k;
            }
          }
        }
        // update only if it wasn't added before
        if(!alreadyAdded && marcobudsTokens[topTokensBytotalWonGames[smallestTokenIdIndex]].totalWonGames < marcobudsTokens[game.winnerTokenId].totalWonGames){
          topTokensBytotalWonGames[smallestTokenIdIndex] = game.winnerTokenId;
        }

       
        emit GameEnded(gameId,games[gameId].winnerTokenId);
    }


    // set effects for each player except the winner
    function setPlayersEffects(uint256 gameId,uint256 randomResult) internal{
        Game storage game = games[gameId];
        uint256 l = game.players.length;
        for(uint256 i = 0; i < l; i++) {
            if(games[gameId].winnerTokenId == game.players[i]) {
                game.effects[i] = 0;
            } else {
                game.effects[i] = getEffect(randomResult,game.players[i]);
            }
        }
    }

    // set the tracks for all players
    function setPlayersTracks(uint256 gameId,uint256 randomResult) internal{
        Game storage game = games[gameId];
        uint256 l = game.players.length;
        for(uint256 i = 0; i < l; i++) {
            game.tracks[i] = getTrack(randomResult,game.players[i]);
        }
    }

    // sort players by total games played . index 0 -> lowest . index 3 -> highest
    function sortPlayersByTotalGamesPlayed(uint256 gameId) internal{
        Game storage game = games[gameId];
        uint256 l = game.players.length;
        for(uint256 i = 0; i < l; i++) {
            for(uint256 j = i+1; j < l ;j++) {             
                if(marcobudsTokens[game.players[i]].totalGamesPlayed > marcobudsTokens[game.players[j]].totalGamesPlayed) {
                    uint256 temp = game.players[i];
                    game.players[i] = game.players[j];
                    game.players[j] = temp;
                }
            }
        }
    }



    // get the winner token id based on WIN_PERCENTAGES and the random result
    function getWinnerTokenId(uint256 gameId,uint256 randomResult) internal view returns (uint256 winnerTokenId){
      require(randomResult >= 1 && randomResult <= 100, "Random result is out of range");
        uint256 l = WIN_PERCENTAGES.length;
        for(uint256 i = 1; i < l; i++) {
          if(randomResult > WIN_PERCENTAGES[i-1] && randomResult <= WIN_PERCENTAGES[i]){
            return games[gameId].players[i-1];
          }
        }
    } 

    // get games as array within the range from-to
    function getGames(uint256 gameIdFrom,uint256 gameIdTo)external view returns (Game[] memory){
      uint256 length = gameIdTo - gameIdFrom;
      Game[] memory gamesArr = new Game[](length+1);
      uint256 j=0;
      for (uint i = gameIdFrom ; i <= gameIdTo; i++) {
          gamesArr[j] = games[i];
          j++;
      }
      return gamesArr;
    }

    // get top Marcobuds by wins or total played games
    function getTopMarcoBuds(SORT_TYPE sortType)external view returns (MarcoBudsToken[] memory){
      MarcoBudsToken[] memory marcosArr = new MarcoBudsToken[](TOP_LIMIT);
      if(sortType == SORT_TYPE.TOTAL_WIN){
          for (uint256 i=1; i<=TOP_LIMIT; i++) {
              marcosArr[i-1] = marcobudsTokens[topTokensBytotalWonGames[i]]; 
          }
      }
      if(sortType == SORT_TYPE.TOTAL_GAMES){
          for (uint256 i=1; i<=TOP_LIMIT; i++) {
              marcosArr[i-1] = marcobudsTokens[topTokensByTotalGamesPlayed[i]]; 
          }
      }
      return marcosArr;
    }

    // get players by game
    function getGamePlayers(uint256 gameId)external view returns (uint256[PLAYERS_COUNT] memory){
          return games[gameId].players;
    }
    // get effects by gamee
    function getGameEffects(uint256 gameId)external view returns (uint256[PLAYERS_COUNT] memory){
          return games[gameId].effects;
    }


    // calculate the players (including the winner), community and dev shares
    function calculateShares(uint256 gameId) internal{

      Game storage game = games[gameId];
      // Winner specific
      // Add the wining share to the winner token
      uint256 winnerTokenId = game.winnerTokenId;
      marcobudsTokens[winnerTokenId].totalWonGames++;
      marcobudsTokens[winnerTokenId].totalGamesPlayed++; 
      marcobudsTokens[winnerTokenId].balance += WIN_SHARE;

      // Distribute the losing share to the losers tokens
      uint256 l = game.players.length;
        for (uint256 i=0; i<l; i++) {
            uint256 tokenId = game.players[i];       
            if(tokenId != winnerTokenId){
              marcobudsTokens[tokenId].totalGamesPlayed++; 
              marcobudsTokens[tokenId].totalLostGames++;
              marcobudsTokens[tokenId].balance += LOSS_SHARE;
            }
        }

      // Dev share
      devBalance += DEV_SHARE;

      // Community share
      communityBalance += COMMUNITY_SHARE;

    }

  

    // Distribute Community shares
    // Anyone can call this to distribute the shares to their respective balances
    function distributeCommunityShare() external {
      require(communityBalance >= MINIMUM_COMMUNITY_BALANCE ,"Community balance must be 1 or greater");
      require(qualifiedTokensCount > 0 ,"There is no qualified tokens yet");
      require(communityBalance >= qualifiedTokensCount ,"Share per token is zero");
        // Distribute the community share to the qualified tokens
        // devide before multiply issue is skipped as it is checked above communityBalance >= qualifiedTokensCount
        // ref: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
        uint256 sharePerToken = communityBalance/qualifiedTokensCount;
        communityBalance = 0;
        for (uint256 j=1; j<=MAX_NFT_SUPPLY; j++) {
            marcobudsTokens[j].balance += (sharePerToken * marcobudsTokens[j].communityShareQualified);
        }
    }



    // Claim the balance of a Marcobuds token
    function claim(uint256 _tokenId) external {
        require (_tokenId > 0 && _tokenId <= MAX_NFT_SUPPLY, "MarcoBuds token Id must be between 1 and 2200");
        require (ownerOfMarcoBuds(_tokenId) , "Please make sure you own this MarcoBuds token");
        uint256 mbBalance = marcobudsTokens[_tokenId].balance;
        require (mbBalance > 0 , "Balance is zero");
        require (address(this).balance >= mbBalance, "Insufficient contract balance");
        marcobudsTokens[_tokenId].balance = 0;
        payable(msg.sender).transfer(mbBalance);
    }

    // Claim the balance of the dev
    function devClaim() external onlyOwner {
        require (dev1 != address(0), "dev1 address can not be zero");
        require (dev2 != address(0), "dev2 address can not be zero");
        require (advisor != address(0), "advisor address can not be zero");
        require (devBalance > 0 , "Dev Balance must be greater than zero");
        require (address(this).balance >= devBalance, "Insufficient contract balance");
        uint256 _devBalance = devBalance;
        devBalance = 0;
        uint256 _devBal = (_devBalance*40)/100;
        uint256 _AdvBal = (_devBalance*20)/100; 
        payable(dev1).transfer(_devBal);
        payable(dev2).transfer(_devBal);
        payable(advisor).transfer(_AdvBal);
    }   

    // Set addresses of the team 
    function setTeamAddresses(address _dev1,address _dev2,address _adv) external onlyOwner {
        require (_dev1 != address(0), "_dev1 can not be zero");
        require (_dev2 != address(0), "_dev2 can not be zero");
        require (_adv != address(0), "_adv can not be zero");
        dev1 = _dev1;
        dev2 = _dev2;
        advisor = _adv;

        emit TeamAddressesUpdated(_dev1,_dev2,_adv);
    }  

    // Set Entry Fee
    function setEntryFee(uint256 totalGameValue) public onlyOwner {
      require (totalGameValue >= MINIMUM_GAME_VALUE , "totalGameValue must be not lower than 1");
      // devide before multiply issue is skipped below as it is checked above , and it will never results in a zero
      // ref: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply

      // set the game value
      GAME_VALUE = totalGameValue;
      // 1/4 for each player
      ENTRY_FEE = totalGameValue/4;
      // 51% for win
      WIN_SHARE = (totalGameValue*51)/100; 
      // 43% for total loss
      uint256 TOTAL_LOSS_SHARE = (totalGameValue*34)/100; 
      // 1/3 for each loss from the total loss
      LOSS_SHARE = TOTAL_LOSS_SHARE/3; 
      // 10% dev share
      DEV_SHARE = (totalGameValue*10)/100; 
      // 5% community share
      COMMUNITY_SHARE = (totalGameValue*5)/100; 
      if(WIN_SHARE+(LOSS_SHARE*3)+DEV_SHARE+COMMUNITY_SHARE != totalGameValue){
        revert("Something went wrong, please change the totalGameValue");
      }

      emit EntryFeeUpdated(totalGameValue);

    }

    // Join a new game 
    function joinGame (uint256 _tokenId) external payable whenNotPaused {
     require (_tokenId > 0 && _tokenId <= MAX_NFT_SUPPLY, "MarcoBuds token Id must be between 1 and 2200");
     require (ownerOfMarcoBuds(_tokenId) , "Please make sure you own this MarcoBuds token");
     require (marcoBudsTokenIsNotPlaying(_tokenId),"This MarcoBuds token is already in a game");
     require (pendingPlayersCount < PLAYERS_COUNT, "Please wait few seconds and try joining again");
     require (msg.value == ENTRY_FEE , "Entry fee should match the required fee");

      pendingPlayersCount++;
      pendingPlayers[pendingPlayersCount] = _tokenId;
      marcobudsTokens[_tokenId].tokenId = _tokenId;
      if(qualifiedTokensCount < MAX_NFT_SUPPLY && marcobudsTokens[_tokenId].communityShareQualified == 0 && marcobudsTokens[_tokenId].totalGamesPlayed >= COMMUNITY_MINIMUM_GAMES){
        marcobudsTokens[_tokenId].communityShareQualified = 1;
        qualifiedTokensCount++;
      } 



// Keep track of top by total games played 
       // get top of the 4 players
        uint256 playerTokenId = _tokenId;
        bool alreadyAdded = false;
        uint256 smallestTokenIdIndex = 1; 
        if(topTokensByTotalGamesPlayed[smallestTokenIdIndex] == playerTokenId){
            alreadyAdded = true;
        }
        if(!alreadyAdded){
          for (uint256 k=2; k<=TOP_LIMIT; k++) {
            if(topTokensByTotalGamesPlayed[k] == playerTokenId){
              alreadyAdded = true;
              break;
            }
            if(marcobudsTokens[topTokensByTotalGamesPlayed[k]].totalGamesPlayed < marcobudsTokens[topTokensByTotalGamesPlayed[smallestTokenIdIndex]].totalGamesPlayed){
                smallestTokenIdIndex = k;
            }
          }
        }
        // update only if it wasn't added before
        if(!alreadyAdded && marcobudsTokens[topTokensByTotalGamesPlayed[smallestTokenIdIndex]].totalGamesPlayed < marcobudsTokens[playerTokenId].totalGamesPlayed){
          topTokensByTotalGamesPlayed[smallestTokenIdIndex] = playerTokenId;
        }



      emit GameJoined(_tokenId);

     if(pendingPlayersCount == PLAYERS_COUNT){
        // Start the game as we have already 4 players
        startGame();
     } 
  }






  function ownerOfMarcoBuds(uint256 _tokenId) internal view returns (bool){
    address tokenOwnerAddress = MARCOBUDS_CONTRACT.ownerOf(_tokenId);
    return (tokenOwnerAddress == msg.sender);
  }

    function marcoBudsTokenIsNotPlaying(uint256 _tokenId) internal view returns (bool){
      for (uint256 i=0; i<pendingPlayersCount; i++) {
        if(pendingPlayers[i+1] == _tokenId) {
          return false;
        }
      }
    return true;
  }




 

// Start the game and clear daata including pending players for a new game 
  function startGame() private{
    gamesCounter++;
    totalGamesValues += GAME_VALUE;
    uint256[PLAYERS_COUNT] memory _players;
    _players[0] = pendingPlayers[1];
    _players[1] = pendingPlayers[2];
    _players[2] = pendingPlayers[3];
    _players[3] = pendingPlayers[4];


    uint256[PLAYERS_COUNT] memory _effects = [uint256(0),0,0,0];
    string[PLAYERS_COUNT] memory _tracks = ["","","",""];

    games[gamesCounter] = Game(gamesCounter,_players,_effects,_tracks,0,0,0,0,0);

     // reset
    pendingPlayers[1] = 0;
    pendingPlayers[2] = 0;
    pendingPlayers[3] = 0;
    pendingPlayers[4] = 0;
    pendingPlayersCount = 0;
    // end

    emit GameStarted(games[gamesCounter]);

    uint256 requestId = getRandomNumber();
    requestIdToGameId[requestId] = gamesCounter;


  }

  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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