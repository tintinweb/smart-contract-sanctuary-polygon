// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./interfaces/IERC20Minter.sol";


import "./NftStaking.sol";
import "./LpStaking.sol";
import "./Vault.sol";
import "./GameCoordinator.sol";
import "./RentShares.sol";


// This is the main game contrat

contract MetaBoards is Ownable, ReentrancyGuard, VRFConsumerBaseV2  {
    using SafeMath for uint256;

    // Chainlink VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    bytes32 internal keyHash;
    address internal vrfCoordinator;
    uint32 internal callbackGasLimit = 350000;
    uint16 requestConfirmations = 3;
    
     // Dev address.
    address payable public feeAddress;

    // The burn address
    address public constant burnAddress = address(0xdead);   
    
    // percent of bnb to send to the vault on jackpot or rug
    uint256 public vaultPercent;

    //Game active
    bool public gameActive;

    bool public migrationActive = true;

    // Migration vars 
    mapping(address => bool) public hasMigrated;

     struct Contracts {
        IERC20Minter token;
        NftStaking nftStaking;
        LpStaking lpStaking;
        address migrator;
        Vault vault;
        GameCoordinator gameCoordinator;
        RentShares rentShares;
    }
     struct GameSettings {
        uint256 defaultParking; // The amount to seed the parking jackpot with
        uint256 minLevel;       // Min level required to play
        uint256 maxLevel;       // Max level a player can achive
        uint256 payDayReward;  // The amount you collect landing on go/sppt 0
        uint256 chestReward; // The amount you collect landing on chest spots
        uint256 rollTimeLimit;   // time in second between rolls
        uint256 activeTimeLimit;  // time in second before a player is no longer considered active for payout
        uint256 riskMod;  // multiply all rent, rewards and taxes by this multiplier
        uint256 rollTokenBurn;  // if we should require a token burn fee to roll
        uint256 rollBbnPayment;  // if we should require a bnb payment to roll
        
        uint256 levelLimit;  // what level you must be in order to claim instant rewards. Set to 0 for the first pass
        uint256 tierLimit;  // what Rewards Tier you have to be to roll Set to zero to skip the check
        uint256 minRollBalance;  // Min Token balance you must have in your wallet to roll, Set to 0 to skip this check
        bool shareRent;
//        uint256 minStakeToRoll;  // Min Cards staked to roll, Set to 0 to skip this check
    }

    struct GameStats {
        
        uint256 totalSpaces; // Total board spots
        uint256 parkingBalance; // current jackpot balance
        uint256 totalRentPaid; // total rent ever paid
        uint256 totalRentPaidOut; // total rewards paid out
        uint256 totalPlayers; //players that rolled at least 1 time
        uint256 totalRolls; //all time total rolls
        uint256 jackpotWins; //Total times the jackpot was won
        uint256 jailCount; //Total times someone was sent to jail
        uint256 rollBurn;
        uint256 rollBnb;
    }


    //player data structure
    struct PlayerInfo {
      uint256 spotId;   // the index of the spot they are currently on.
      uint256 rentDue;      // the current rent due for this player.
      uint256 lastRoll; // the lsast number rolled
      uint256 lastDice1; // each dice rolled
      uint256 lastDice2;
      uint256 lastRollTime; // timestamp of the last roll
      uint256 doublesCount; // how many times in a row they rolled doubles
      bool inJail; //if this player is in jail
//      uint256 jackpotWins; //Total times the jackpot was won
//      uint256 jailCount; //Total times someone was sent to jail
      bool isRolling; //if this player is in jail

    }

    
    struct BoardInfo {
        uint256 spotType; //what type of space this is
        uint256 rent;      // the rent for this space.
        uint256 balance;  // the balance currently paid to this spot
        uint256 nftId; // Nft id's that relate to this spot
        uint256 totalPaid;  // total rent paid to this spot
        uint256 totalLanded;  // total times someone landed on this spot
        uint256 currentLanded; //how many people are currently here

        IERC20Minter partnerRewardToken;
        uint256 partnerRewardAmount;
    }

    /* 

        1 - reduce roll time
        2 - prevent you from losing a level when you get rugged
        3 - bonus  to your payday 
        4 - reduce tax and utility
        5 - reduce tax only
        6 - reduce utility only 
    */
    struct PowerUpInfo {
        uint256 puType; // what type of power up this is 
        uint256 puNftId; // Nft id's that relate to this power up
        uint256 puValue;  // the value that is tied to this powerup
    }

    mapping(uint256 => address) private rollQueue;
    
    GameSettings public gameSettings;
    GameStats public gameStats;
    Contracts public contracts;

    bool public devRoll;

    uint256 public rollNowBnbFee;
    mapping(address => PlayerInfo) public playerInfo;
    mapping(uint256 => BoardInfo) public boardInfo;
    mapping(uint256 => PowerUpInfo) public powerUpInfo;
    mapping(address => uint256) private activePowerup;

    event SpotPaid(uint256 spotId, uint256 share);
    event Roll(address indexed user, uint256 rollNum, uint256 spodId);

    //-----------------------------

    constructor(
       
        address payable _feeAddress, //dev address
        uint256[] memory _boardTypes, //an array of each board piece by type
        uint256[] memory _boardRent, //a corresponding array of each board piece by rent
        uint256[] memory _nftIds, //a corresponding array of each board piece by nftId
        address _vrfCoordinator,
        bytes32 _vrfKeyHash, 
        uint64 _subscriptionId
    ) VRFConsumerBaseV2 (
        _vrfCoordinator
    )  {
    //    contracts.token = _token;
    //   contracts.nftStaking = _nftStaking;
   //     contracts.lpStaking = _lpStakingAddress;
   //     contracts.migrator = _migrator;
        // contracts.vault = _vault;
        feeAddress = _feeAddress;

        //set the default board
         gameStats.totalSpaces = _boardTypes.length;
        for (uint i=0; i<gameStats.totalSpaces; i++) {
            BoardInfo storage bSpot = boardInfo[i];
            bSpot.spotType = _boardTypes[i];
            bSpot.rent = _boardRent[i];
            bSpot.nftId = _nftIds[i];
            //bSpot.balance = 0;
        }

      
        // set up chainlink
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        vrfCoordinator = _vrfCoordinator;
        keyHash = _vrfKeyHash;
        
    }

    /** 
    * @notice Modifier to only allow updates by the VRFCoordinator contract
    */
    modifier onlyVRFCoordinator {
        require(msg.sender == vrfCoordinator, 'VRF Only');
        _;
    }
  

    /**
    * @dev Roll and take a players turn
    * - must not owe rent
    * - must have waited long enough between rolls
    * - sends request to chainlink VRF // noBlacklistAddress
    */
    function roll() public payable  nonReentrant returns (uint256)  {
        //roll and move
        // bool burnSuccess = false;
  
        PlayerInfo storage player = playerInfo[msg.sender];


        require(

            _canRoll(msg.sender) &&
            msg.value >= gameSettings.rollBbnPayment
            , "Can't Roll");

        // handle transfer and burns

        // if we are taking BNB transfer it to the contract
        if(gameSettings.rollBbnPayment > 0){
            gameStats.rollBnb = gameStats.rollBnb.add(gameSettings.rollBbnPayment);
            // feeAddress.transfer(msg.value);
           // address(this).transfer(msg.value);
        }
 
   
        // if we need to burn burn it
        if(gameSettings.rollTokenBurn > 0){
             gameStats.totalRentPaid = gameStats.totalRentPaid.add(gameSettings.rollTokenBurn);
             contracts.gameCoordinator.addTotalPaid(msg.sender,gameSettings.rollTokenBurn);
             // player.totalRentPaid = player.totalRentPaid.add(gameSettings.rollTokenBurn);
             gameStats.rollBurn = gameStats.rollBurn.add(gameSettings.rollTokenBurn);
             contracts.token.transferFrom(msg.sender, burnAddress, gameSettings.rollTokenBurn);

              // give shares
              contracts.vault.giveShares(msg.sender, gameSettings.rollTokenBurn);
              // contracts.token.transferFrom(msg.sender, burnAddress, gameSettings.rollTokenBurn);
             // require(burnSuccess, "Burn failed");
        }

        player.isRolling = true;
  
        // PowerUpInfo storage powerUp = _getPowerUp(msg.sender);
        PowerUpInfo storage powerUp = powerUpInfo[contracts.nftStaking.getPowerUp(msg.sender)];
        // contracts.nftStaking.getPowerUp(_account)
        activePowerup[msg.sender] = powerUp.puNftId;

        //Virgin player
        if( contracts.gameCoordinator.getTotalRolls(msg.sender) < 1){
            contracts.gameCoordinator.addTotalPlayers(1);
        }

        //inc some counters
        contracts.gameCoordinator.addTotalRolls(msg.sender);

//        player.totalRolls = player.totalRolls.add(1);
//        gameStats.totalRolls = gameStats.totalRolls.add(1);

        //check for players in jail
        if(player.inJail){
            //set them free
            player.inJail = false;
            //transport them to the jail spot 
            player.spotId = 10;
        }

        //check moon jackpot to make sure there is always something to pay out
        //this shouldnt need to happen besides the first roll
        if(gameStats.parkingBalance <= 0){
            seedParking();
        }
/*
        //harvest any pending game rewards
        if(player.rewards > 0){
            _claimGameRewards();
        }
*/
        //time lock the roll
        player.lastRollTime = block.timestamp;

        // udate the global last roll before we modify
        contracts.gameCoordinator.setLastRollTime(msg.sender, player.lastRollTime );
        
        // check for a roll powerup
        if(powerUp.puType == 1){
            player.lastRollTime = player.lastRollTime.sub(gameSettings.rollTimeLimit.mul(powerUp.puValue).div(1 ether));
        }

        
        uint256 _requestId = COORDINATOR.requestRandomWords(
          keyHash,
          subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          2
        );

        rollQueue[_requestId] = msg.sender;
        return _requestId;
        

    }


     /**
     * @notice Callback function used by VRF Coordinator
     * @dev Important! Add a modifier to only allow this function to be called by the VRFCoordinator
     * @dev The VRF Coordinator will only send this function verified responses.
     * @dev The VRF Coordinator will not pass randomness that could not be verified.
     * @dev Get a number between 2 and 12, and run the roll logic
     */
      function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
      ) internal override {

        // uint256[] storage dice = new uint256[](2);
        uint256 _die1 = randomWords[0].mod(5).add(1);
        uint256 _die2 = randomWords[1].mod(5).add(1);

        address _player = rollQueue[requestId];
        // dice[0] = _die1;
        // dice[1] = _die2;
        // delete playerInfo[_player].lastDice;

        

        _doRoll(_die1,_die2,payable(_player));

      }
  /*  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override onlyVRFCoordinator {

            uint256 _roll = randomness.mod(11).add(2);
            address _player = rollQueue[requestId];
            
            _doRoll(_roll,payable(_player));

    }
*/
    /*
    types: [
        0: 'start',
        1: 'prop',
        2: 'rr',
        3: 'util',
        4: 'chest',
        5: 'chance', 
        6: 'tax',
        7: 'jail',
        8: 'gojail',
        9: 'parking'
    ]
    */

    /**
     * @dev called by fulfillRandomness, process the roll and mvoe the player
     */
    function _doRoll(uint256 _die1, uint256 _die2, address payable _player) private {
        
        bool isPropOwner =  false;
        bool doSeedParking = false;
        uint256 _roll = _die1 + _die2;
        bool _isDoubles = _die1 == _die2;

        uint256 payBase = gameSettings.payDayReward.mul(gameSettings.riskMod).div(1 ether);

        
        PlayerInfo storage player = playerInfo[_player];
        uint256 playerTier = contracts.lpStaking.getUserLevel(_player);
        uint256 lvl = contracts.gameCoordinator.getLevel(_player);

        PowerUpInfo storage powerUp = powerUpInfo[activePowerup[_player]];



        // check for a payday power up
        if(powerUp.puType == 3){
            payBase = payBase.mul(powerUp.puValue).div(1 ether);
        }

        // remove the count for the curent space
        if(boardInfo[player.spotId].currentLanded > 0){
            boardInfo[player.spotId].currentLanded = boardInfo[player.spotId].currentLanded.sub(1);
        }
        

        //move the player
        player.spotId = player.spotId.add(_roll);

        // check for a third double
        if(_isDoubles){
            player.doublesCount = player.doublesCount +1; 
            if( player.doublesCount > 2){
                // send them to the rugged space/ jail
                player.spotId = 30;
                
            }
        } else {
            player.doublesCount = 0;
        }

        //log last roll
        player.lastRoll = _roll;

        player.lastDice1 = _die1;
        player.lastDice2 = _die2;

        //check if we passed go
        if(player.spotId >= gameStats.totalSpaces){

          // harvest the NFT farms
          contracts.nftStaking.gameHarvest(_player);

          if(lvl < gameSettings.maxLevel){
            lvl = lvl.add(1);
            contracts.gameCoordinator.setLevel(_player,lvl);
          }

          player.spotId = player.spotId.sub(gameStats.totalSpaces);
          
          //don't pay them twice
          if(player.spotId != 0){
            //multiply by the level or the max level for this board
            uint256 lBase = payBase.mul(lvl);

            if(lvl > gameSettings.maxLevel){
                lBase = payBase.mul(gameSettings.maxLevel);
            }
            gameStats.totalRentPaidOut = gameStats.totalRentPaidOut.add(lBase);
            // player.rewards = player.rewards.add(lBase);
            contracts.rentShares.addPendingRewards(_player, lBase);
            contracts.token.mint(address(contracts.rentShares), lBase);
          }
        }

        BoardInfo storage bSpot = boardInfo[player.spotId];

        //some stats
        bSpot.totalLanded = bSpot.totalLanded.add(1);
        bSpot.currentLanded = bSpot.currentLanded.add(1);

        //set the rent
        uint256 rent = bSpot.rent.mul(gameSettings.riskMod).div(1 ether);
        
        //check the spot type
        if(bSpot.spotType == 0){
            //landed on go mint 4x the pay day x the level up to the max level for this board
            uint256 lBase = payBase.mul(4).mul(lvl);

            if(lvl > gameSettings.maxLevel){
                lBase = payBase.mul(4).mul(gameSettings.maxLevel);
            }

            gameStats.totalRentPaidOut =  gameStats.totalRentPaidOut.add(lBase);
            // player.rewards = player.rewards.add(lBase);
            contracts.rentShares.addPendingRewards(_player, lBase);
            contracts.token.mint(address(contracts.rentShares), lBase);

            // see if we have partner rewards
            if(bSpot.partnerRewardToken != IERC20Minter(address(0x0)) && bSpot.partnerRewardAmount != 0){
                // make sure we still have a balance
                if(bSpot.partnerRewardToken.balanceOf(address(this)) > 0){
                    // send the partner rewards
                    safePartnerTransfer(bSpot.partnerRewardToken, _player, bSpot.partnerRewardAmount);
                }
            }
        }

        if(bSpot.spotType == 1 || bSpot.spotType == 2){
            //property and rocket
            //don't pay rent for our own property
            isPropOwner = _isStaked(_player, player.spotId);
            if(isPropOwner){
                rent = 0;
            }
        }


        if(bSpot.spotType == 3){
            /*
            @dev Utility
            rent is base rent X the roll so we can have varying util rents
            ie: 
            - first util spot rent is 4 so (4x the roll)
            - second util spot rent is 8 so (8x the roll)
            */
            if(lvl < gameSettings.levelLimit || playerTier < gameSettings.tierLimit){
                rent = 0;
            } else {
                rent = rent.mul(_roll);
                // check for utility power up
                if(powerUp.puType == 4 || powerUp.puType == 6){
                    rent = rent.mul(powerUp.puValue).div(1 ether);
                }
            }
        }

        // @dev make sure they players level is at the proper level to earn instant rewards
        if(bSpot.spotType == 4 && lvl >= gameSettings.levelLimit && playerTier >= gameSettings.tierLimit){
            //community chest
            uint256 modChestReward = gameSettings.chestReward.mul(gameSettings.riskMod).div(1 ether);

            gameStats.totalRentPaidOut =  gameStats.totalRentPaidOut.add(modChestReward);
            // player.rewards = player.rewards.add(modChestReward);
            contracts.rentShares.addPendingRewards(_player, modChestReward);
            contracts.token.mint(address(contracts.rentShares), modChestReward);

            // see if we have partner rewards
            if(bSpot.partnerRewardToken != IERC20Minter(address(0x0)) && bSpot.partnerRewardAmount != 0){
                // make sure we still have a balance
                if(bSpot.partnerRewardToken.balanceOf(address(this)) > 0){
                    // send the partner rewards
                    safePartnerTransfer(bSpot.partnerRewardToken, _player, bSpot.partnerRewardAmount);
                }
            }
            
        }

        if(bSpot.spotType == 5){
            //roll again
            //get a free roll, set the timesamp back 
            player.lastRollTime = block.timestamp.sub(gameSettings.rollTimeLimit);
        }

        if(bSpot.spotType == 6){
            if(lvl < gameSettings.levelLimit || playerTier < gameSettings.tierLimit){
                // since we don't give rewards we should't charge tax
                rent = 0;
            } else {
                // check for a tax power up
                if(powerUp.puType == 4 || powerUp.puType == 5){
                    rent = rent.mul(powerUp.puValue).div(1 ether);
                }
            }
        }

        if(bSpot.spotType == 8){
            //go to jail
            bool validRug;
            // see if we have a level shield powerup
            if(powerUp.puType != 2){
                //take away a level
                if(lvl > 0){
                    // harvest the NFT farms
                    contracts.nftStaking.gameHarvest(_player);
                    
                    lvl = lvl.sub(1);
                    contracts.gameCoordinator.setLevel(_player,lvl);
                    validRug = true;
                }
            }
            //flag player in jail
            player.inJail = true;
//            player.jailCount = player.jailCount.add(1);
            gameStats.jailCount = gameStats.jailCount.add(1);

            //Clear the jackpot
            uint256 _pbal = gameStats.parkingBalance;
            gameStats.parkingBalance = 0;

            //lock them for 3 rolls time
            player.lastRollTime = block.timestamp.add(gameSettings.rollTimeLimit.mul(2));

            // reset the doubles count
            player.doublesCount = 0;
            // check for a roll powerup
            if(powerUp.puType == 1){
                player.lastRollTime = player.lastRollTime.sub(gameSettings.rollTimeLimit.mul(3).mul(powerUp.puValue).div(1 ether));
                // player.lastRollTime = player.lastRollTime.mul(powerUp.puValue).div(1 ether);
            }

            // emit GotoJail(_player, _pbal);

           /*  )
              ) \  
             / ) (  
             \(_)/ */
            //Burn the jackpot!!! 
            safeTokenTransfer(address(burnAddress), _pbal);

            // give shares for the rug amount?
            // contracts.vault.giveShares(_player, _pbal);
            // transfer BNB to the dev wallet
            if(validRug && address(this).balance > 0){
               
                // send 20% to the vault
                uint256 toVault = address(this).balance.mul(vaultPercent).div(100);
                (bool sent, ) = payable(address(contracts.vault)).call{value: toVault}("");
                require(sent, "Failed to send");

                // the rest to the dev
                feeAddress.transfer(address(this).balance.sub(toVault));
            }

            //re-seed the jackpot
            doSeedParking = true;

        }

        // @dev make sure they players level is at the proper level to earn instant rewards
        if(bSpot.spotType == 9 && lvl >= gameSettings.levelLimit && playerTier >= gameSettings.tierLimit){
            //Moon Jackpot
            //WINNER WINNER CHICKEN DINNER!!!
            if(gameStats.parkingBalance > 0){
                //send the winner the prize
                uint256 _pbal = gameStats.parkingBalance;
                // emit LandedParking(_player, _pbal);
                gameStats.parkingBalance = 0;

                // transfer BNB to the winner
                if(address(this).balance > 0){
                    // send 20% to the vault
                    uint256 toVault = address(this).balance.mul(vaultPercent).div(100);
                    uint256 toWinner = address(this).balance.sub(toVault);
                    (bool sent, ) = payable(address(contracts.vault)).call{value: toVault}("");
                    require(sent, "Failed to send");

                    // the rest to the winner
                   _player.transfer(toWinner);

                }

                // player.rewards = player.rewards.add(_pbal);
                // transfer to the rent share contract
                contracts.rentShares.addPendingRewards(_player, _pbal);
                safeTokenTransfer(address(contracts.rentShares), _pbal);

                // see if we have partner rewards
                if(bSpot.partnerRewardToken != IERC20Minter(address(0x0)) && bSpot.partnerRewardAmount != 0){
                    // make sure we still have a balance
                    if(bSpot.partnerRewardToken.balanceOf(address(this)) > 0){
                        // send the partner rewards
                        safePartnerTransfer(bSpot.partnerRewardToken, _player, bSpot.partnerRewardAmount);
                    }
                }

//                player.jackpotWins = player.jackpotWins.add(1);
                gameStats.jackpotWins = gameStats.jackpotWins.add(1);
                gameStats.totalRentPaidOut =  gameStats.totalRentPaidOut.add(_pbal);
                //reset the parking balance
                doSeedParking = true;
            }
        }


        if(doSeedParking){
            seedParking();
        }

        player.isRolling = false;
        player.rentDue = rent;

         emit Roll(_player, _roll, player.spotId);
    }


     //-----------------------------

     /**
      * @dev Set all the base game settings in one function to reduce code
      */
    function setGameSettings( 
        
        uint256 _riskMod,
        uint256 _minLevel, // min level to play
        uint256 _maxLevel, //the level cap for players
        uint256 _defaultParking, //the value of a fresh parking jackpot
        uint256 _payDayReward, //the value of landing on go, (payDayReward/10) for passing it
        uint256 _chestReward, //value to mint on a chest spot
        uint256 _rollTimeLimit, //seconds between rolls
        uint256 _activeTimeLimit, //seconds since last roll before a player is ineligible for payouts
        bool _shareRent, // if we are sending rent to players or burning it
        uint256 _vaultPercent
    ) public onlyOwner {
        
        gameSettings.riskMod = _riskMod;
        gameSettings.minLevel = _minLevel;
        gameSettings.maxLevel = _maxLevel;
        gameSettings.defaultParking = _defaultParking;
        gameSettings.payDayReward = _payDayReward;
        gameSettings.chestReward = _chestReward;
        gameSettings.rollTimeLimit = _rollTimeLimit;
        gameSettings.activeTimeLimit = _activeTimeLimit;
        gameSettings.shareRent = _shareRent;
        vaultPercent = _vaultPercent;
    }

    /**
      * @dev Set roll limits in one funtion to reduce code
      */
    function setRollSettings( 
        uint256 _rollTokenBurn, // amount of tokens to burn on every roll
        uint256 _rollBbnPayment, // amount of bnb to charge for every roll
        uint256 _levelLimit, // min ingame level to get rewards or pay rent
        uint256 _tierLimit, // min LP tier to get rewards or pay rent
        uint256 _minRollBalance, // amount of Tokens you must have in your wallet to roll
        uint256 _rollNowBnbFee

//        uint256 _minStakeToRoll // min amount of cards staked to be able to roll
    ) public onlyOwner {
        gameSettings.rollTokenBurn = _rollTokenBurn;
        gameSettings.rollBbnPayment = _rollBbnPayment;
        gameSettings.levelLimit = _levelLimit;
        gameSettings.tierLimit = _tierLimit;
        gameSettings.minRollBalance = _minRollBalance;
        rollNowBnbFee = _rollNowBnbFee;
//        gameSettings.minStakeToRoll = _minStakeToRoll;
    }
    
    
    /**
    * @dev See if a player has a valid card staked and has recently rolled
    */
    function _isStaked(address _account, uint256 _spotId) private view returns(bool){

        //see if they have rolled lately 
        // do we need this since it is onlycalled on doRoll? 
        if(!_playerActive(_account)){
            return false;
        }

        if(boardInfo[_spotId].nftId == 0){
            return false;
        }

        // Change this 
        // instead of getting all the staked cards, see if they have rent shares for this NFT
        if(contracts.rentShares.getRentShares(_account, boardInfo[_spotId].nftId) > 0){
            return true;
        }
        /*
        uint256[] memory stakedCards = contracts.nftStaking.getCardsStakedOfAddress(_account);
        uint256 len = stakedCards.length;
        
        
        if(len <= 0){
            return false;
        }

        for (uint i=0; i<len; i++) {
            if(stakedCards[i] > 0 && i == bSpot.nftId){
                //check if they have rolled/active
                return true;
            } 
        }
*/
        return false;

    }

    /**
    * @dev Assign or update a specific NftId as a power up
    */
    function setPowerUp(uint256 _puNftId, uint256 _puType, uint256 _puValue) public onlyOwner {
        powerUpInfo[_puNftId].puNftId = _puNftId;
        powerUpInfo[_puNftId].puType = _puType;
        powerUpInfo[_puNftId].puValue = _puValue;
//        // emit PowerUpSet(_puNftId, _puType, _puValue);
    }

    /**
     * @dev Claim/harvest the pending rewards won while playing, not related to yield farming
    */
/*    function claimGameRewards() public nonReentrant {
           _claimGameRewards();
    }

    function _claimGameRewards() internal {

         PlayerInfo storage player = playerInfo[msg.sender];
            uint256 pending = player.rewards;
            require(pending > 0, "nothing to claim");
            if(pending > 0){

                // emit RewardsClaimed(msg.sender, pending);
                player.rewards = 0;
                player.totalClaimed = player.totalClaimed.add(pending);
                safeTokenTransfer(msg.sender, pending);

            }
    }
*/
    /**
    * @dev Handle paying a players rent/tax 
    */
    function payRent() public nonReentrant {

            
        bool transferSuccess = false;
         // BoardInfo storage bSpot = boardInfo[_spotId];
        PlayerInfo storage player = playerInfo[msg.sender];

        uint256 _rentDue = player.rentDue;
        uint256 tokenBal = contracts.token.balanceOf(msg.sender);

        require(gameActive && _rentDue > 0 && tokenBal >= _rentDue, "Can't pay");

         //if we don't have full rent take what we can get
        if(tokenBal < _rentDue){
            _rentDue = tokenBal;
        }

        //pay the rent internally 
        player.rentDue = player.rentDue.sub(_rentDue);
        transferSuccess = contracts.token.transferFrom(address(msg.sender),address(this),_rentDue);
        require(transferSuccess, "transfer failed");

        if(boardInfo[player.spotId].spotType == 3){
            //utils are community add to the moon jackpot
            gameStats.parkingBalance = gameStats.parkingBalance.add(_rentDue);
        } else if(boardInfo[player.spotId].spotType == 6){

           /*  )
              ) \  
             / ) (  
             \(_)/ */
            //Burn all taxes 
            safeTokenTransfer(address(burnAddress), _rentDue);
        } else {
            //pay the spot and run payouts for all the stakers
            boardInfo[player.spotId].balance = boardInfo[player.spotId].balance.add(_rentDue);
            _payOutSpot(player.spotId);
            
        }

        //keep track of the total paid stats
        gameStats.totalRentPaid = gameStats.totalRentPaid.add(_rentDue);
        contracts.gameCoordinator.addTotalPaid(msg.sender, _rentDue);
//        player.totalRentPaid = player.totalRentPaid.add(_rentDue);
        boardInfo[player.spotId].totalPaid = boardInfo[player.spotId].totalPaid.add(_rentDue);

    }

    function resetTimer() public payable nonReentrant {
        uint256 timerEnd = playerInfo[msg.sender].lastRollTime.add(gameSettings.rollTimeLimit);
        require(gameActive,'Game Not Active');
        require(block.timestamp < timerEnd,'Timer Expired');
        require(msg.value >= rollNowBnbFee,'Low Balance');

        gameStats.rollBnb = gameStats.rollBnb.add(rollNowBnbFee);
       //playerInfo[msg.sender].lastRollTime =  block.timestamp.sub(timerEnd.sub(block.timestamp));
       playerInfo[msg.sender].lastRollTime = block.timestamp.sub(gameSettings.rollTimeLimit);

    }

    /**
     * @dev Pays out all the stakers of this spot and resets its balance.
     *
     * // Emits a {SpotPaid} 
     *
     * Payouts are distributed like so:
     * 10% - burned forever
     * 10% - sent to the parking jackpot
     * 5% - sent to dev address
     * 75% - split evenly between all stakers (active or not)
     * - To be eligible to receive the payout the player must have the card staked and rolled in the last day
     * - Any staked share that is not eligible will be burned
     * 
     *
     * Requirements
     *
     * - `_spotId` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
    */
    function _payOutSpot(uint256 _spotId) internal {
    //get all the addresses that have this card staked
    //total up the stakers
        require(_spotId.add(1) <= gameStats.totalSpaces && boardInfo[_spotId].balance > 0, "Invalid");

        uint256 totalToDistribute = boardInfo[_spotId].balance;

        //10% to burn
        uint256 toBurn = totalToDistribute.mul(10).div(100);

        //10% to parking
        uint256 toParking = totalToDistribute.mul(10).div(100);

        //5% to dev
        uint256 toDev = totalToDistribute.mul(5).div(100);


        uint256 share = 0;
      //  uint256 amtStaking;
        //clear the spot balance
        boardInfo[_spotId].balance = 0;
        if(gameSettings.shareRent){
            uint256 toSend = totalToDistribute.sub(toBurn).sub(toParking).sub(toDev);
            if(contracts.rentShares.totalRentSharePoints(boardInfo[_spotId].nftId) > 0){
                contracts.rentShares.collectRent(boardInfo[_spotId].nftId,toSend);
            } else {
                toBurn = toBurn.add(toSend);
            }

        } else {
            // no distribution burn a lot more!
            
            //20% to parking
            toParking = totalToDistribute.mul(20).div(100);

            //5% to dev
            toDev = totalToDistribute.mul(5).div(100);

            //75% to burn
            toBurn = totalToDistribute.sub(toParking).sub(toDev);
        }


        gameStats.parkingBalance = gameStats.parkingBalance.add(toParking);
       /*  )
          ) \  
         / ) (  
         \(_)/ */
        //burn it!
        safeTokenTransfer(address(burnAddress), toBurn);
        safeTokenTransfer(feeAddress,toDev);

        //emit SpotPaid(_spotId, origBal, share, totalToDistribute, toParking, toBurn, toDev, stakers);
        emit SpotPaid(_spotId, share);
    }
     
    /**
    * @dev reset the parking jackpot
    */
    function seedParking() internal {
         //seed the parking
        gameStats.parkingBalance = gameSettings.defaultParking.mul(gameSettings.riskMod).div(1 ether);
        contracts.token.mint(address(this), gameStats.parkingBalance);
    }

    /**
    * @dev Add to the parking jackpot used for promos or for any generous soul to give back
    */
    function addParking(uint256 _amount) public nonReentrant {
             // manually add to the parking jackpot 
            require(_amount > 0 && contracts.token.balanceOf(msg.sender) >= _amount, "Nothing to add");

//            bool transferSuccess = false;

            gameStats.parkingBalance = gameStats.parkingBalance.add(_amount);

            // transferSuccess = contracts.token.transferFrom(address(msg.sender),address(this),_amount);
            contracts.token.transferFrom(address(msg.sender),address(this),_amount);
//            require(transferSuccess, "transfer failed");

    }

    /**
    * @dev Update the details on a space
    */
    function updateSpot(
        uint256 _spotId,  
        uint256 _spotType, 
        uint256 _rent,
        uint256 _nftId,
        IERC20Minter _partnerRewardToken,
        uint256 _partnerRewardAmount) public onlyOwner {

            boardInfo[_spotId].spotType = _spotType;
            boardInfo[_spotId].rent = _rent;
            boardInfo[_spotId].nftId = _nftId;
            boardInfo[_spotId].partnerRewardToken = _partnerRewardToken;
            boardInfo[_spotId].partnerRewardAmount = _partnerRewardAmount;

    }

    function canRoll(address _account) external view returns(bool){

        return _canRoll(_account);
    }

    function _canRoll(address _account) private view returns(bool) {
        uint256 tokenBal = contracts.token.balanceOf(_account);

        if(
            !gameActive || 
            contracts.gameCoordinator.getLevel(_account) < gameSettings.minLevel ||
//            !hasMigrated[msg.sender] || 
            playerInfo[_account].isRolling || 
            playerInfo[_account].rentDue > 0 || 
            block.timestamp < playerInfo[_account].lastRollTime.add(gameSettings.rollTimeLimit) ||
            tokenBal < gameSettings.rollTokenBurn  ||
            tokenBal < gameSettings.minRollBalance
        ){
            return false;
        }
        return true;
    }

    function playerActive(address _account) external view returns(bool){
        return _playerActive(_account);
    }

    function _playerActive(address _account) internal view returns(bool){
        if(block.timestamp <= playerInfo[_account].lastRollTime.add(gameSettings.activeTimeLimit)){
            return true;
        }
        return false;
    }
/*
    function getLevel(address _address) external view returns(uint256){
        return playerInfo[_address].level;
    }
*/
    // Safe token transfer function, just in case if rounding error causes pool to not have enough Tokens.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = contracts.token.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > tokenBal) {
            transferSuccess = contracts.token.transfer(_to, tokenBal);
        } else {
            transferSuccess = contracts.token.transfer(_to, _amount);
        }
        require(transferSuccess, "transfer failed");
    }

    function safePartnerTransfer(IERC20Minter _partnerRewardToken, address _to, uint256 _amount) internal {
        uint256 tokenBal = _partnerRewardToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > tokenBal) {
            transferSuccess = _partnerRewardToken.transfer(_to, tokenBal);
        } else {
            transferSuccess = _partnerRewardToken.transfer(_to, _amount);
        }
        require(transferSuccess, "transfer failed");
    }

    function endMigration() public onlyOwner{
        migrationActive = false;
    }

    function updatePlayer (
        address _address, 
        uint256 _spotId, 
        uint256 _rentDue, 
        uint256 _lastRoll,
        uint256 _lastRollTime,
//        uint256 _level,
        bool _inJail
//        uint256 _totalClaimed,
//        uint256 _totalRentPaid,
//        uint256 _totalRolls
        ) public {
        
        require(migrationActive && !hasMigrated[_address] && msg.sender == contracts.migrator, "already migrated");

        hasMigrated[_address] = true;
        playerInfo[_address].spotId = _spotId;
        playerInfo[_address].rentDue = _rentDue;
        playerInfo[_address].lastRoll = _lastRoll;
        playerInfo[_address].lastRollTime = _lastRollTime;
//        playerInfo[_address].level = _level;
        playerInfo[_address].inJail = _inJail;
//        playerInfo[_address].totalClaimed = _totalClaimed;
//        playerInfo[_address].totalRentPaid = _totalRentPaid;
//        playerInfo[_address].totalRolls = _totalRolls;
    }

    /**
    * @dev Set the game active 
    */
    function setGameActive(bool _isActive) public onlyOwner {
        gameActive = _isActive;
    }

    // Update dev address by the previous dev.
    function dev(address payable _feeAddress) public onlyOwner{
        feeAddress = _feeAddress;
    }


    function setContracts(IERC20Minter _token, NftStaking _nftStakingAddress, LpStaking _lpStaking, address _migrator, Vault _vault, GameCoordinator _gameCoordinator, RentShares _rentSharesAddress) public onlyOwner{
        contracts.token = _token;
        contracts.nftStaking = _nftStakingAddress;
        contracts.lpStaking = _lpStaking;
        contracts.migrator = _migrator;
        contracts.vault = _vault;
        contracts.gameCoordinator = _gameCoordinator;
        contracts.rentShares = _rentSharesAddress;

        contracts.token.approve(address(_rentSharesAddress), type(uint256).max);

    }

    /**
     * @dev If we need to migrate contracts we need a way to get the BNB out of it
     */ 
    function withdrawBnb() public onlyOwner{
        feeAddress.transfer(address(this).balance);
    }

    /**
     * @dev transfer LINK out of the contract
     */
/*    function withdrawLink(uint256 _amount) public onlyOwner {
        require(LINK.transfer(msg.sender, _amount), "Unable to transfer");
    }*/

    function withdrawPartnerToken(IERC20Minter _partnerRewardToken) public onlyOwner {
        safePartnerTransfer(_partnerRewardToken, address(owner()), _partnerRewardToken.balanceOf(address(this)));
    }

    /**
     * @dev Accept bnb 
     */ 
    fallback() external  payable { }
    receive() external payable { }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
pragma solidity >=0.8.11;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11; 

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import './ProxyRegistry.sol';
import './Concat.sol';

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, Ownable, AccessControl {
    using SafeMath for uint256;
    using Strings for string;

//    address proxyRegistryAddress;
    uint256 private _currentTokenID = 0;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => uint256) public tokenInitialMaxSupply;

    address public constant burnWallet = address(0xdead);
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
//        address _proxyRegistryAddress
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
//        proxyRegistryAddress = _proxyRegistryAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

    }

    function uri(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "erc721tradable#uri: NONEXISTENT_TOKEN");
        string memory _uri = super.uri(_id);
        return Concat.strConcat(_uri, Strings.toString(_id));
    }


    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
        // return tokenMaxSupply[_id];
    }

    function initialMaxSupply(uint256 _id) public view returns (uint256) {
        return tokenInitialMaxSupply[_id];
        // return tokenMaxSupply[_id];
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external returns (uint256 tokenId) {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_initialSupply <= _maxSupply, "initial supply cannot be more than max supply");
        
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

         if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
      
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        tokenInitialMaxSupply[_id] = _maxSupply;
        return _id;
    }

    function mint(
//        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        
        uint256 newSupply = tokenSupply[_id].add(_quantity);
        require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
        // _mint(_to, _id, _quantity, _data);
        _mint(msg.sender, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    /**
        * @dev Mint tokens for each id in _ids
        * @param _to          The address to mint tokens to
        * @param _ids         Array of ids to mint
        * @param _quantities  Array of amounts of tokens to mint per id
        * @param _data        Data to pass if receiver is contract
    */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");

        for (uint256 i = 0; i < _ids.length; i++) {
          uint256 _id = _ids[i];
          uint256 quantity = _quantities[i];
          uint256 newSupply = tokenSupply[_id].add(quantity);
          require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
          
          tokenSupply[_id] = tokenSupply[_id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
    }

    function burn(
        address _address, 
        uint256 _id, 
        uint256 _amount
    ) external virtual {
        require((msg.sender == _address) || isApprovedForAll(_address, msg.sender), "ERC1155#burn: INVALID_OPERATOR");
        require(balanceOf(_address,_id) >= _amount, "Trying to burn more tokens than you own");

        // _burnAndReduce(_address,_id,_amount);
        _burn(_address, _id, _amount);
    }
/*
    function _burnAndReduce(
        address _address, 
        uint256 _id, 
        uint256 _amount
    ) internal {
        // reduce the total supply
        tokenMaxSupply[_id] = tokenMaxSupply[_id].sub(_amount);
        _burn(_address, _id, _amount);
    }
*/
    /* dev Check if we are sending to the burn address and burn and reduce supply instead */ 
  /*  function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator,from,to,ids,amounts,data);

        // check if to is the burn address and burn tokens
        if(to == burnWallet){
            for(uint256 i = 0; i <= ids.length; ++i){
                require(balanceOf(from,ids[i]) >= amounts[i], "Trying to burn more tokens than you own");
                _burnAndReduce(from,ids[i],amounts[i]);
            }
        }
    }
    */
    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
/*        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
*/
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }

     /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) public view virtual override(AccessControl,ERC1155) returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
        interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Concat {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Minter is IERC20 {
  function mint(
    address recipient,
    uint256 amount
  )
    external;

  function burn(
    address account,
    uint256 amount
  )
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./libs/PancakeLibs.sol";

contract VaultMiner is Context, Ownable, IERC1155Receiver, ReentrancyGuard {

    using SafeERC20 for IERC20;
    
    IERC20 public token;
    ERC1155 public nftContract;

    // The burn address
    address public constant burnAddress = address(0xdead);

    // where the tokens get sent too after buys, default to burn
    address public tokenReceiver = address(0xdead);

    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

    uint256 internal constant COST_FOR_SHARE = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    

    bool private initialized = false;
    address payable internal treasuryWallet;
    address payable internal investWallet;

    mapping (address => uint256) internal userShares;
    mapping (address => uint256) internal claimedWorkers;
    mapping (address => uint256) internal lastClaim;
    mapping (address => address) internal referrals;
    uint256 internal marketWorkers;

    uint256 public totalShares;    

    // lifetime max an address can buy in with 
    uint256 private maxPerAddress = 10000 * 1 ether;

    // min buy amount
    uint256 private minBuy = 5 * 1 ether;

    // max buy amount 
    uint256 private maxBuy = 1000 * 1 ether;

    // min amount an address much have bought to be an active referral
    uint256 private minRefAmount = 100;

    // sell time frame to trigger noSell or penalty fees, 0 disables
    uint256 private sellDuration = 6 days;

    // forced time between compounds, 0 disables
    // uint256 compoundDuration = 12 hours;

    // enable/disable the buyFromToken feature
    bool private buyFromTokenEnabled;

    // if true you can only sell after the sell duration is up, otherwise the fees apply
    bool private noSell;

    // if true, referrals will get rewards from both compounds and buys
    bool private refCompoundEnabled;

/*    
    // fees
    // referral fee, only on buys
    uint256 private refFee = 90; // 9%   

    // buy and normal sell fees
    // divide by 1000 ie 42 =  4.20
    uint256 private buyFee = 20;
    uint256 private devFee = 20;
    uint256 private investFee = 20;

    // if noSell is false, these settings control the penalty fees
    // (50% total fees)
    uint256 buyPenalty = 200;
    uint256 devPenalty = 200;
    uint256 investPenalty = 200;*/

    // hard cap Penalty fee of 60% max
    uint256 private constant MAX_PENALTY_FEE = 600;

    // hard cap buy in fee of 20% max
    uint256 private constant MAX_BUY_FEE = 200;

    // hard cap on the max NFT multiplier 3x max
    uint256 private constant MAX_NFT_MULTIPLIER = 30;

    // hard cap of 15% on the referral fees
    uint256 private constant MAX_REF_FEE = 150;

    struct FeesInfo {
        uint256 refFee;
        uint256 buyFee;
        uint256 devFee;
        uint256 investFee;
        uint256 buyPenalty;
        uint256 devPenalty;
        uint256 investPenalty;
    }

    struct UserStats {
        uint256 purchases; // how many times they bought shares
        uint256 purchaseAmount; // total amount they have purchased
        uint256 purchaseValue; // total value they have purchased 
        uint256 compounds; // how many times they have compounded
        uint256 compoundAmount; // total amount they have compounded
        uint256 compoundValue; // total value they have compounded (at time of compound) 
        uint256 lastSell; // timestamp of last sell
        uint256 sells; // how many times they sold shares
        uint256 sellAmount; // total amount they have sold
        uint256 sellValue; // total value they have sold
        uint256 firstBuy; //when they made their first buy
        uint256 refRewards; // total value of ref rewards (at time of purchase) 
    }

    struct MinerNftInfo {
        uint256 nftType; // 1 for percent - 2 for instant shares
        uint256 amount; // how many shares this gives (only applies to type 2)
        uint256 lifetime; // time in seconds this is active (only applies to type 1)
        uint256 multiplier;  // multiply new shares by this amount (only applies to type 1)
        uint256 totalUsed; // how many nfts were used
        bool isDisabled; // so we can hide ones we don't want
    }

    struct MultiplierInfo {
        uint256 nftId; 
        uint256 lifetime; // time in seconds this is active 
        uint256 startTime; // time stamp it was staked
        uint256 endTime; // time stamp it when it ends
        uint256 multiplier;  // multiply new shares by this amount (only applies to type 1)
    }
  
    mapping(uint256 => MinerNftInfo) public minerNftInfo;
    mapping(address => MultiplierInfo) public currentMultiplier;
    mapping(address => UserStats) public userStats;
    FeesInfo public fees;

    event FeeChanged(uint256 refFee, uint256 fee, uint256 penaltyFees, uint256 timestamp);

    constructor(
        address payable _treasuryWallet, 
        address payable _investWallet, 
        IERC20 _token, 
        ERC1155 _nftContract,
        address _router) {

        treasuryWallet = payable(_treasuryWallet);
        investWallet = payable(_investWallet);

        token = _token;
        nftContract = _nftContract;

        // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            _router
        );
        // get a uniswap pair for this token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

        pancakeRouter = _pancakeRouter;

        // token.approve(address(this), type(uint256).max);
        // nftContract.setApprovalForAll(address(this),true);

        // default fees
        fees = FeesInfo({
            refFee: 90,
            buyFee: 20,
            devFee: 20,
            investFee: 20,
            buyPenalty: 200,
            devPenalty: 100,
            investPenalty: 200
        });
    }
    
    function claimWorkers(address ref) public isInitialized nonReentrant {
        _claimWorkers(msg.sender,ref, false);
    }

    event WorkersClaimed(address indexed user, address indexed ref, uint256 newShares, uint256 userWorkers, uint256 refWorkers);
    function _claimWorkers(address addr, address ref, bool isBuy) internal {
        // require(isBuy || block.timestamp > (lastClaim[addr] + compoundDuration), 'Too soon' );
        if(ref == addr) {
            ref = address(0);
        }
        
        if(referrals[addr] == address(0) && referrals[addr] != addr && referrals[referrals[addr]] != addr) {
            referrals[addr] = ref;
        }

        bool hasRef = referrals[addr] != address(0) && referrals[addr] != addr && userStats[referrals[addr]].purchaseValue >= minRefAmount;
        
        uint256 workersUsed = getMyWorkers(addr);
        uint256 userWorkers;
        uint256 refWorkers;

        if(hasRef && (isBuy || refCompoundEnabled)) {
            refWorkers = getFee(workersUsed,fees.refFee);
            userWorkers = workersUsed - refWorkers;
            //send referral workers
            claimedWorkers[referrals[addr]] = claimedWorkers[referrals[addr]] + refWorkers;
            userStats[referrals[addr]].refRewards = userStats[referrals[addr]].refRewards + calculateWorkerSell(refWorkers);
        }
       
        if(userWorkers == 0){
            userWorkers = workersUsed;
        }

        if(isBuy){
            userStats[addr].purchases = userStats[addr].purchases + 1;
            userStats[addr].purchaseAmount = userStats[addr].purchaseAmount + workersUsed; 
        } else {
            userStats[addr].compounds = userStats[addr].compounds + 1;
            userStats[addr].compoundAmount = userStats[addr].compoundAmount + workersUsed; 
            userStats[addr].compoundValue = userStats[addr].compoundValue + calculateWorkerSell(workersUsed); 
        }

        uint256 newShares = userWorkers/COST_FOR_SHARE;
        
        userShares[addr] = userShares[addr] + newShares;
        totalShares = totalShares + newShares;

        claimedWorkers[addr] = 0;
        lastClaim[addr] = block.timestamp;
         
        //boost market to nerf shares hoarding
        marketWorkers = marketWorkers + (workersUsed/5);

        emit WorkersClaimed(addr, ref, newShares, userWorkers, refWorkers);
    }


    event WorkersSold(address indexed user,  uint256 amount, uint256 workersSold );
    function sellWorkers() public isInitialized nonReentrant {
        require(!noSell || block.timestamp > (userStats[msg.sender].lastSell + sellDuration), 'too soon to sell');

        uint256 hasWorkers = getMyWorkers(msg.sender);
        uint256 workerValue = calculateWorkerSell(hasWorkers);

        uint256 fee = getFee(workerValue,(fees.buyFee + fees.devFee + fees.investFee));
        uint256 toBuy = getFee(workerValue,fees.buyFee);
        uint256 toDev = getFee(workerValue,fees.devFee);
        uint256 toInvest = getFee(workerValue,fees.investFee);

        if(!noSell && block.timestamp < (userStats[msg.sender].lastSell + sellDuration)){
            // use the penalty fees
            fee = getFee(workerValue, (fees.buyPenalty + fees.devPenalty + fees.investPenalty));
            toBuy = getFee(workerValue,fees.buyPenalty);
            toDev = getFee(workerValue,fees.devPenalty);
            toInvest = getFee(workerValue,fees.investPenalty);
        }

        claimedWorkers[msg.sender] = 0;
        lastClaim[msg.sender] = block.timestamp;
        marketWorkers = marketWorkers + hasWorkers;

        userStats[msg.sender].lastSell = block.timestamp; 
        userStats[msg.sender].sells = userStats[msg.sender].sells + 1; 
        userStats[msg.sender].sellAmount = userStats[msg.sender].sellAmount + hasWorkers;
        userStats[msg.sender].sellValue = userStats[msg.sender].sellValue + (workerValue-fee);

        bool sent;
        if(toDev > 0) {
            (sent,) = treasuryWallet.call{value: (toDev)}("");
            require(sent,"send failed");
        }

        if(toInvest > 0) {
            (sent,) = investWallet.call{value: (toInvest)}("");
            require(sent,"send failed");
        }

        if(toBuy > 0) {
            swapFromFees(toBuy);
        }
        
        (sent,) = investWallet.call{value: (toInvest)}("");
        require(sent,"send failed");


        // send to the user
        (sent,) = investWallet.call{value: (workerValue-fee)}("");
        require(sent,"send failed");

        emit WorkersSold(msg.sender, workerValue, hasWorkers );
    }
    
    function pendingRewards(address adr) public view returns(uint256) {
        uint256 hasWorkers = getMyWorkers(adr);
        if(hasWorkers == 0){
            return 0;
        }
        uint256 workerValue = calculateWorkerSell(hasWorkers);
        return workerValue;
    }
    
    function buyWorkers(address ref) public payable isInitialized nonReentrant {
        return _buyWorkers(msg.sender, msg.value, ref, false);
    }

    event WorkersBought(address indexed user, address indexed ref, uint256 amount, uint256 workersBought, bool fromSwap );
    function _buyWorkers(address user, uint256 amount, address ref,  bool fromSwap) internal {
        require(amount >= minBuy, 'Buy too small');
        require(amount <= maxBuy, 'Buy too large');
        require(maxPerAddress == 0 || (userStats[user].purchaseValue + amount) <= maxPerAddress, 'Max buy amount reached');

        uint256 fee = fees.buyFee + fees.devFee + fees.investFee;
        
        uint256 workersBought = calculateWorkerBuy(amount,(address(this).balance - amount));
        workersBought = workersBought - getFee(workersBought,fee);

        // see if we have a valid multiplier nft
        if(currentMultiplier[user].startTime > 0) {
            if(currentMultiplier[user].endTime > block.timestamp) {
                // expired, reset the current multiplier
                delete currentMultiplier[user];
            } else {
                // valid multiplier, multiply the post fee amount 
                workersBought = ((workersBought * currentMultiplier[user].multiplier)/10);
            }
        }

        uint256 toBuy = getFee(amount,fees.buyFee);
        uint256 toDev = getFee(amount,fees.devFee);
        uint256 toInvest = getFee(amount,fees.investFee);

        if(userStats[user].firstBuy == 0){
            userStats[user].firstBuy = block.timestamp;
        }

        userStats[user].purchaseValue = userStats[user].purchaseValue + amount; 
        
        bool sent;
        // send the fee to the treasuryWallet
        if(toDev > 0) {
            (sent,) = treasuryWallet.call{value: (toDev)}("");
            require(sent,"send failed");
        }

        // send to the invest wallet
        if(toInvest > 0) {
            (sent,) = investWallet.call{value: (toInvest)}("");
            require(sent,"send failed");
        }

        // do the buyback
        if(toBuy > 0) {
            swapFromFees(toBuy);
        }

        claimedWorkers[user] = claimedWorkers[user] + workersBought;

        emit WorkersBought(user, ref, amount, workersBought, fromSwap );

        _claimWorkers(msg.sender,ref,true);
    }

    event NftUsed(address indexed user, uint256 nftId, uint256 nftType);
    function useNft(uint256 _nftId) public isInitialized nonReentrant{
        require(minerNftInfo[_nftId].nftType > 0 && minerNftInfo[_nftId].nftType < 3,'Invalid Type');
        require(!minerNftInfo[_nftId].isDisabled,'NFT Disabled');
        require(nftContract.balanceOf(msg.sender,_nftId) > 0, 'No NFT Balance');

        // send the NFT
        nftContract.safeTransferFrom( msg.sender, address(this), _nftId, 1, "");
        
        // burn the NFT
        nftContract.safeTransferFrom( address(this), burnAddress, _nftId, 1, "");

        // if the type is instant, give them instant shares
        if(minerNftInfo[_nftId].nftType == 2){
            claimedWorkers[msg.sender] = minerNftInfo[_nftId].amount * COST_FOR_SHARE;
            _claimWorkers(msg.sender,msg.sender,false);
        } else {
            // otherwise set the current multiplier    
            currentMultiplier[msg.sender].nftId = _nftId;
            currentMultiplier[msg.sender].lifetime = minerNftInfo[_nftId].lifetime;
            currentMultiplier[msg.sender].startTime = block.timestamp;
            currentMultiplier[msg.sender].endTime = block.timestamp + minerNftInfo[_nftId].lifetime;
            currentMultiplier[msg.sender].multiplier = minerNftInfo[_nftId].multiplier;
        }

        emit NftUsed(msg.sender, _nftId, minerNftInfo[_nftId].nftType );

    }

    // buy 
    //(10000 * marketWorkers)/(5000 + ( ((10000 * contractBalance) + (5000 * workers))/workers) );

    // sell
    //(10000 * contractBalance)/(5000 + ( ((10000 * marketWorkers) + (5000 * rt))/rt) );


    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) internal view returns(uint256) {
        return (PSN * bs)/(PSNH + ( ((PSN * rs) + (PSNH * rt))/rt) );
    }
    
    function calculateWorkerSell(uint256 workers) public view returns(uint256) {
        return calculateTrade(workers,marketWorkers,address(this).balance);
    }
    
    function calculateWorkerBuy(uint256 amount,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(amount,contractBalance,marketWorkers);
    }
    
    function calculateWorkerBuySimple(uint256 amount) public view returns(uint256) {
        return calculateWorkerBuy(amount,address(this).balance);
    }
    
    function totalFees() internal view returns(uint256) {
        return fees.buyFee + fees.devFee + fees.investFee;
    }

    function totalPenalties() internal view returns(uint256) {
        return fees.buyPenalty + fees.devPenalty + fees.investPenalty;
    }

    function getFee(uint256 amount, uint256 fee) internal pure returns(uint256) {
        return (amount * fee)/1000;
    }
    
    event MarketInitialized(uint256 timestamp);
    function seedMarket() public payable onlyOwner {
        require(marketWorkers == 0);

        initialized = true;
        marketWorkers = 108000000000;

        emit MarketInitialized(block.timestamp);
    }

    function setTokenContract( IERC20 _token) public onlyOwner {
        token = _token;      
    }

    function setNftContract( ERC1155 _nftContract ) public onlyOwner {
        nftContract = _nftContract;      
    }

    event TreasurySet(address indexed oldWallet, address indexed newWallet, uint256 timestamp); 
    function setTreasury(address _treasuryWallet) public onlyOwner{
        address oldWallet = payable(treasuryWallet);
        treasuryWallet = payable(_treasuryWallet);
        emit TreasurySet(oldWallet, _treasuryWallet, block.timestamp);
    }   

    event InvestWalletSet(address indexed oldWallet, address indexed newWallet, uint256 timestamp); 
    function setInvestWallet(address _investWallet) public onlyOwner{
        address oldWallet = investWallet;
        investWallet = payable(_investWallet);
        emit InvestWalletSet(oldWallet, _investWallet, block.timestamp);
    }    

    event TokenReciverSet(address indexed oldWallet, address indexed newWallet, uint256 timestamp); 
    function setTokenReciver(address _tokenReceiver) public onlyOwner{
        address oldWallet = tokenReceiver;
        tokenReceiver = _tokenReceiver;
        emit TokenReciverSet(oldWallet, _tokenReceiver, block.timestamp);
    }

    function setBuySettings(uint256 _maxPerAddress, uint256 _minBuy, uint256 _maxBuy) public onlyOwner{
        maxPerAddress = _maxPerAddress;
        minBuy = _minBuy;
        maxBuy = _maxBuy;
    }

    function setMinRefAmount(uint256 _minRefAmount) public onlyOwner{
        minRefAmount = _minRefAmount;
    }

    function setDurationa(uint256 _sellDuration) public onlyOwner{
        sellDuration = _sellDuration;
    }

    function setNoSell(bool _noSell) public onlyOwner {
        noSell = _noSell;
    }

    function setRefCompoundEnabled(bool _refCompoundEnabled) public onlyOwner {
        refCompoundEnabled = _refCompoundEnabled;
    }

    function setFees(
        uint256 _refFee,
        uint256 _buyFee, 
        uint256 _devFee, 
        uint256 _investFee,
        uint256 _buyPenalty, 
        uint256 _devPenalty, 
        uint256 _investPenalty
    ) public onlyOwner {
        require(_refFee <= MAX_REF_FEE, 'ref fee too high');
        require((_buyFee + _devFee + _investFee) <= MAX_BUY_FEE, "Fee capped at 20%");
        require((_buyPenalty + _devPenalty + _investPenalty) <= MAX_PENALTY_FEE, "Penalty capped at 60%");

         fees = FeesInfo({
            refFee: _refFee,
            buyFee: _buyFee,
            devFee: _devFee,
            investFee: _investFee,
            buyPenalty: _buyPenalty,
            devPenalty: _devPenalty,
            investPenalty: _investPenalty
        });

        emit FeeChanged(_refFee, (_buyFee + _devFee + _investFee), (_buyPenalty + _devPenalty + _investPenalty), block.timestamp);
    }


    function setBuyFromTokenEnabled(bool _buyFromTokenEnabled) public onlyOwner {
        buyFromTokenEnabled = _buyFromTokenEnabled;
    }
    

    function setMinerNftInfo(
        uint256 _nftId, 
        uint256 _nftType,
        uint256 _amount,
        uint256 _lifetime,
        uint256 _multiplier) public onlyOwner {
        

        require(_multiplier <= MAX_NFT_MULTIPLIER, 'Multiplier too high');

        minerNftInfo[_nftId].nftType = _nftType;
        minerNftInfo[_nftId].amount = _amount; 
        minerNftInfo[_nftId].lifetime = _lifetime; 
        minerNftInfo[_nftId].multiplier = _multiplier; 

    }

    function setMinerNftDisabled(uint256 _nftId, bool _isDisabled) public onlyOwner {
        minerNftInfo[_nftId].isDisabled = _isDisabled;        
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyShares(address adr) public view returns(uint256) {
        return userShares[adr];
    }
    
    function getMyWorkers(address adr) public view returns(uint256) {
        return claimedWorkers[adr] + getWorkersSinceLastClaim(adr);
    }
    
    function getWorkersSinceLastClaim(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(COST_FOR_SHARE,(block.timestamp - lastClaim[adr]));
        return secondsPassed * userShares[adr];
    }

    function getReferral(address adr) public view returns(address) {
        return referrals[adr];
    }

    function getShareSettings() public view returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        bool,
        bool,
        bool
    ) {
        return (
            maxPerAddress,
            minBuy,
            maxBuy,
            minRefAmount,
            sellDuration,
            buyFromTokenEnabled,
            noSell,
            refCompoundEnabled
        );
    }
   
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function buyFromToken(uint256 tokenAmount, IERC20 tokenAddress, address ref) public isInitialized {
        require(buyFromTokenEnabled,'not enabled');

        // transfer the ERC20 token
        tokenAddress.safeTransferFrom(address(msg.sender), address(this), tokenAmount);

        // get current balance
        uint256 currentBalance = address(this).balance;

        // do the swap
        _swapTokenForNative(tokenAmount, tokenAddress);

        // get new balance and amount to buy
        uint256 toBuy = currentBalance - address(this).balance;

        // make the buy
        _buyWorkers(msg.sender,toBuy,ref,true);
    }


    function _swapTokenForNative(uint256 tokenAmount, IERC20 tokenAddress) private {
        _swapTokenForNative(tokenAmount, tokenAddress, address(this));
    }

    function swapFromFees(uint256 amount) private {
         _swapNativeForToken(amount, token, address(tokenReceiver));
    }

    //swaps tokens on the contract for Native
    function _swapTokenForNative(uint256 tokenAmount, IERC20 fromToken, address toAddress) internal {
        address[] memory path = new address[](2);
        path[0] = address(fromToken);
        path[1] = pancakeRouter.WETH();

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(toAddress),
            block.timestamp
        );
    }

    //swaps Native for a token
    function _swapNativeForToken(uint256 amount, IERC20 toToken, address toAddress) internal {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(toToken);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(toAddress),
            block.timestamp
        );
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
    }


    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    modifier isInitialized {
      require(initialized, "Vault Miner has not been initialized");
      _;
    }
}

// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VaultMiner.sol";
import "./libs/ERC1155Tradable.sol";
import "./libs/PancakeLibs.sol";

/**
 * @title BlacklistAddress
 * @dev Manage the blacklist and add a modifier to prevent blacklisted addresses from taking action
 */
contract Vault is VaultMiner {
    // using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // global flag to set staking and depositing active
    bool public isActive;

    bool lpEnabled;

    // Nft Packs Address
    address public nftPacksAddress;

    // bridge gateway
    address private gatewayAddress; 

    // total Native added to LP
    uint256 public totalLPNative;

    // total token added to LP
    uint256 public totalLPToken;

    // total tokens burned
    uint256 public totalTokensBurned;

    uint256 public tokenBurnMultiplier = 6;
    uint256 public nftGiveMultiplier = 4;
    uint256 public nftBurnMultiplier = 3;
    uint256 public packThresh = 3;

    //lpAddress is also equal to the liquidity token address
    //LP token are locked in the contract
    address private lpAddress; 
    // IPancakeRouter02 private  pancakeRouter; 
    //TODO: Change to Mainnet
    //TestNet
     // address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
   // address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

   // polygon testnet
   // address private constant PancakeRouter=0xbdd4e5660839a088573191A9889A262c0Efc0983;

   // address private constant PancakeRouter=0x8954AfA98594b838bda56FE4C12a09D7739D179b;
    // address private PancakeRouter;

    struct UserLock {
        uint256 tokenAmount; // total amount they locked
        uint256 claimedAmount; // total amount they have withdrawn
        uint256 vestShare; // how many tokens they get back each vesting period
        uint256 vestPeriod; // how many seconds each vest point is
        uint256 startTime; // start of the lock
        uint256 endTime; //when the lock ends
    }

    struct UserNftLock {
        uint256 amount; // amount they have locked
        uint256 sharePoints;  // total share points being given for this lock
        uint256 startTime; // start of the lock
        uint256 endTime; //when the lock ends
    }

    struct NftInfo {
        uint256 tokenId; // which token to lock (mPCKT or LP)
        uint256 lockDuration; // how long this nft needs you to lock
        uint256 tokenAmount; // how many tokens you must lock
        uint256 vestPoints; // lock time / vestPoints = each vesting period
        uint256 sharePoints;  // how many share points this is worth for locking (4x for giving)
        uint256 givenAmount; // how many have been deposited into the contract
        uint256 burnedAmount; // how many have been deposited into the contract
        uint256 claimedAmount; // how many have been claimed from the contract
        uint256 lockedNfts; // how many nfts are currently locked
        bool toBurn; // if this should be burned or transferred when deposited
        bool isDisabled; // so we can hide ones we don't want
        address lastGiven; // address that last gave this nft so they can't reclaim
    }

    mapping(address => mapping(uint256 => UserLock)) public userLocks;
    mapping(address => mapping(uint256 => UserNftLock)) public userNftLocks;
    mapping(uint256 => NftInfo) public nftInfo;
    mapping(uint256 => bool) public inNftPacks;
    mapping(uint256 => IERC20) public tokenIds;
    mapping(address => bool) private canGive;

    

    event Locked(address indexed account, uint256 nftId, uint256 unlock );
    event UnLocked(address indexed account, uint256 nftId);
//    event Claimed(address indexed account, uint256 nftId, uint256 amount);
    event NftGiven(address indexed account, uint256 nftId);
    event NftLocked(address indexed account, uint256 nftId, uint256 unlock);
    event TokensBurned(address indexed account, uint256 amount);

    event NftUnLocked(address indexed account, uint256 nftId);


    constructor (
        ERC1155Tradable _nftContract, 
        IERC20 _token, 
        address payable _treasuryWallet,        
        address payable _investWallet,
        address _lpAddress,
        address _router
    ) VaultMiner(_treasuryWallet, _investWallet, _token, _nftContract, _router ) {
        // nftContract = _nftContract;
        // treasuryWallet = _treasuryWallet;
        // PancakeRouter = _router;
        
        _setToken(1,_token);

        canGive[address(this)] = true;
        canGive[owner()] = true;
        lpAddress = _lpAddress;
       // pancakeRouter = IPancakeRouter02(_router);

    //    lpAddress = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());

        _token.approve(address(pancakeRouter), type(uint256).max);
     //   _token.approve(burnAddress, type(uint256).max);
    }

    function setMultipliers(uint256 _tokenBurnMultiplier, uint256 _nftGiveMultiplier, uint256 _nftBurnMultiplier ) public onlyOwner {
        tokenBurnMultiplier = _tokenBurnMultiplier;
        nftGiveMultiplier = _nftGiveMultiplier;
        nftBurnMultiplier = _nftBurnMultiplier;
    }

    function setPackThresh(uint256 _packThresh) public onlyOwner {
        packThresh = _packThresh;
    }

    function setGatewayAddress( address _gatewayAddress) public onlyOwner {
        gatewayAddress = _gatewayAddress;
    }

    function setLpAddress( address _lpAddress) public onlyOwner {
        lpAddress = _lpAddress;
    }

    function setNftPacksAddress(address _nftPacksAddress) public onlyOwner {
        nftPacksAddress = _nftPacksAddress;
    }
    function setToken(uint256 _tokenId, IERC20 _tokenAddress) public onlyOwner {
        _setToken(_tokenId, _tokenAddress);
        _tokenAddress.approve(address(pancakeRouter), type(uint256).max);
    }

    function _setToken(uint256 _tokenId, IERC20 _tokenAddress) private {
        tokenIds[_tokenId] = _tokenAddress;
    }

    function setNftInPack(uint256 _nftId, bool _inPack) public onlyOwner {
        inNftPacks[_nftId] = _inPack;
    }

    function setNftInfo(
        uint256 _nftId, 
        uint256 _tokenId, 
        uint256 _lockDuration, 
        uint256 _tokenAmount, 
        uint256 _vestPoints, 
        uint256 _sharePoints, 
        bool _toBurn) public onlyOwner {

        require(address(tokenIds[_tokenId]) != address(0), "No valid token");

        nftInfo[_nftId].tokenId = _tokenId;
        nftInfo[_nftId].lockDuration = _lockDuration;
        nftInfo[_nftId].tokenAmount = _tokenAmount;
        nftInfo[_nftId].vestPoints = _vestPoints;
        nftInfo[_nftId].sharePoints = _sharePoints;
        nftInfo[_nftId].toBurn = _toBurn;

    }

    function setNftDisabled(uint256 _nftId, bool _isDisabled) public onlyOwner {
        nftInfo[_nftId].isDisabled = _isDisabled;        
    }

    function setVaultActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function setLpEnabled(bool _lpEnabled) public onlyOwner {
        lpEnabled = _lpEnabled;
    }

    function lock(uint256 _nftId) public nonReentrant {

        require(userLocks[msg.sender][_nftId].tokenAmount == 0, 'Already Locked');
        require(isActive && tokenIds[nftInfo[_nftId].tokenId].balanceOf(msg.sender) >= nftInfo[_nftId].tokenAmount && nftInfo[_nftId].tokenId  > 0 && !nftInfo[_nftId].isDisabled && (nftContract.balanceOf(address(this), _nftId) - nftInfo[_nftId].lockedNfts) > 0, 'Not Enough');
        require(nftInfo[_nftId].lastGiven != address(msg.sender),'can not claim your own' );

        userLocks[msg.sender][_nftId].tokenAmount = nftInfo[_nftId].tokenAmount;
        userLocks[msg.sender][_nftId].startTime = block.timestamp; // block.timestamp;
        userLocks[msg.sender][_nftId].endTime = block.timestamp + nftInfo[_nftId].lockDuration; // block.timestamp.add(nftInfo[_nftId].lockDuration);
        userLocks[msg.sender][_nftId].vestShare = nftInfo[_nftId].tokenAmount / nftInfo[_nftId].vestPoints;
        userLocks[msg.sender][_nftId].vestPeriod = nftInfo[_nftId].lockDuration / nftInfo[_nftId].vestPoints;

        // give them share points 1:1 for the tokens they have staked
        // _addShares(msg.sender,userLocks[msg.sender][_nftId].tokenAmount); 

        // move the tokens
        tokenIds[nftInfo[_nftId].tokenId].safeTransferFrom(address(msg.sender), address(this), nftInfo[_nftId].tokenAmount);

        // send the NFT
        nftContract.safeTransferFrom( address(this), msg.sender, _nftId, 1, "");

        // emit Locked( msg.sender, nftInfo[_nftId].tokenId, nftInfo[_nftId].tokenAmount, userLocks[msg.sender][_nftId].endTime, _nftId);
        emit Locked( msg.sender, _nftId, userLocks[msg.sender][_nftId].endTime );

    }


    function claimLock(uint256 _nftId) public nonReentrant {
        require(isActive && userLocks[msg.sender][_nftId].tokenAmount > 0, 'Not Locked');
        require(userLocks[msg.sender][_nftId].tokenAmount > 0 && (userLocks[msg.sender][_nftId].tokenAmount - userLocks[msg.sender][_nftId].claimedAmount) > 0, 'Nothing to claim');
        // _claimLock(msg.sender, _nftId);

        // see how many vest points they have hit
        uint256 vested;
        for(uint256 i = 1; i <= nftInfo[_nftId].vestPoints; ++i){
            // if(block.timestamp >= userLocks[msg.sender][_nftId].startTime.add(userLocks[msg.sender][_nftId].vestPeriod.mul(i))){
            if(block.timestamp >= userLocks[msg.sender][_nftId].startTime + (userLocks[msg.sender][_nftId].vestPeriod * i)){    
                vested++;
            }
        }

        uint256 totalVested = userLocks[msg.sender][_nftId].vestShare * vested;

        // get the amount owed to them based on previous claims and current vesting period
        uint256 toClaim = totalVested - userLocks[msg.sender][_nftId].claimedAmount;

        require(toClaim > 0, 'Nothing to claim.');

        userLocks[msg.sender][_nftId].claimedAmount = userLocks[msg.sender][_nftId].claimedAmount + toClaim;

        // remove the shares
        _removeShares(msg.sender, toClaim);

        // move the tokens
        tokenIds[nftInfo[_nftId].tokenId].safeTransfer(address(msg.sender), toClaim);
//        Claimed(_address, _nftId, toClaim);



        if(block.timestamp >= userLocks[msg.sender][_nftId].endTime){
            delete userLocks[msg.sender][_nftId];
            emit UnLocked(msg.sender,_nftId);
        }
        
    }

    // Trade tokens directly for share points at 3:1 rate
    function tokensForShares(uint256 _amount) public nonReentrant {
        require(isActive && tokenIds[1].balanceOf(msg.sender) >= _amount, "Not enough tokens");

        _addShares(msg.sender,_amount * tokenBurnMultiplier, true );
        
        totalTokensBurned = totalTokensBurned + _amount;

        tokenIds[1].safeTransferFrom(address(msg.sender),burnAddress, _amount);
        emit TokensBurned(msg.sender, _amount);
    }

    function giveNft(uint256 _nftId, uint256 _amount) public nonReentrant {
        require(nftContract.balanceOf(address(msg.sender), _nftId) >= _amount,'Not Enough NFTs');

        require(isActive && nftInfo[_nftId].sharePoints > 0  && !nftInfo[_nftId].isDisabled, 'NFT Not Registered');

        address toSend = address(this);
        uint256 multiplier = nftGiveMultiplier;

        //see if we burn it
        if(nftInfo[_nftId].toBurn){
            toSend = burnAddress;
            multiplier =  nftBurnMultiplier;
            nftInfo[_nftId].burnedAmount = nftInfo[_nftId].burnedAmount + _amount;
        } else {
            // check if it's in packs
            if(inNftPacks[_nftId] && (nftContract.balanceOf(address(this), _nftId) - nftInfo[_nftId].lockedNfts) >= packThresh){
                toSend = address(nftPacksAddress);
            }
            nftInfo[_nftId].givenAmount = nftInfo[_nftId].givenAmount + _amount;
        }

        // give them shares for the NFTs
        _addShares(msg.sender,nftInfo[_nftId].sharePoints * _amount * multiplier, true );
        
        // send the NFT
        nftContract.safeTransferFrom( msg.sender, toSend, _nftId, _amount, "");

        emit NftGiven(msg.sender, _nftId);

    }

    // locks an NFT for the amount of time and the user share points
    // dont't allow burnable NFTS to count
    function lockNft(uint256 _nftId, uint256 _amount) public nonReentrant {
        require(
            isActive && 
            nftInfo[_nftId].sharePoints > 0  && 
            !nftInfo[_nftId].toBurn && 
            !nftInfo[_nftId].isDisabled && 
            nftContract.balanceOf(address(msg.sender), _nftId) >= _amount , "Can't Lock");
        // && userNftLocks[msg.sender][_nftId].startTime == 0
        
        // require(isActive && nftInfo[_nftId].sharePoints > 0  && !nftInfo[_nftId].toBurn && !nftInfo[_nftId].isDisabled, 'NFT Not Registered');

        userNftLocks[msg.sender][_nftId].amount = userNftLocks[msg.sender][_nftId].amount + _amount;
        userNftLocks[msg.sender][_nftId].startTime = block.timestamp; //  block.timestamp;
        userNftLocks[msg.sender][_nftId].endTime = block.timestamp + nftInfo[_nftId].lockDuration; // block.timestamp.add(nftInfo[_nftId].lockDuration);

        // update the locked count
        nftInfo[_nftId].lockedNfts = nftInfo[_nftId].lockedNfts + _amount;

        // give them shares for the NFTs (1/4 the value of giving it away)
        uint256 sp = nftInfo[_nftId].sharePoints * _amount;

        userNftLocks[msg.sender][_nftId].sharePoints = userNftLocks[msg.sender][_nftId].sharePoints + sp;
        _addShares(msg.sender, sp, true);

        // send the NFT
        nftContract.safeTransferFrom( msg.sender, address(this), _nftId, _amount, "");

        emit NftLocked( msg.sender, _nftId, userNftLocks[msg.sender][_nftId].endTime);

    }

    // unlocks and claims an NFT if allowed and removes the share points
    function unLockNft(uint256 _nftId) public nonReentrant {
        require(isActive && userNftLocks[msg.sender][_nftId].amount > 0, 'Not Locked');
        require(block.timestamp >= userNftLocks[msg.sender][_nftId].endTime, 'Still Locked');
        
        // remove the shares
        _removeShares(msg.sender, userNftLocks[msg.sender][_nftId].sharePoints);

        uint256 amount = userNftLocks[msg.sender][_nftId].amount;
        delete userNftLocks[msg.sender][_nftId];
        // update the locked count
        nftInfo[_nftId].lockedNfts = nftInfo[_nftId].lockedNfts - amount;
        
        // send the NFT
        nftContract.safeTransferFrom(  address(this), msg.sender, _nftId, amount, "");

        emit NftUnLocked( msg.sender, _nftId);
    }

    // manage which contracts/addresses can give shares to allow other contracts to interact
    function setCanGive(address _addr, bool _canGive) public onlyOwner {
        canGive[_addr] = _canGive;
    }

    //gets shares of an address
    function getShares(address _addr) public view returns(uint256){
        return getMyShares(_addr);
    }


    function giveShares(address _addr, uint256 _amount) public {
        require(canGive[msg.sender], "Can't give");
        _addShares(_addr,_amount,false);
    }

    function removeShares(address _addr, uint256 _amount) public {
        require(canGive[msg.sender], "Can't remove");
        _removeShares(_addr,_amount);
    }


    //adds shares
    function _addShares(address _addr, uint256 _amount, bool _forceClaim) private {
      
        
        claimedWorkers[_addr] = claimedWorkers[_addr] + (_amount * COST_FOR_SHARE) / 1 ether;
        if(_forceClaim){
            _claimWorkers(_addr,_addr,false);
        }
    }

    //removes shares
    function _removeShares(address _addr, uint256 _amount) private {
        // claim first
        _claimWorkers(_addr,_addr,false);

        uint256 toRemove = _amount/ 1 ether;
        userShares[_addr] = userShares[_addr] - toRemove;
        totalShares = totalShares - toRemove;
        
        // remove workers from the market
        marketWorkers = marketWorkers - ((toRemove * COST_FOR_SHARE)/ 1 ether);
    }

    // LP Functions
    //Adds Liquidity directly to the contract where LP are locked(unlike safemoon forks, that transfer it to the owner)
    function _addLiquidity(uint256 tokenamount, uint256 nativeamount) private {
        totalLPNative+=nativeamount;
        totalLPToken+=tokenamount;

        try pancakeRouter.addLiquidityETH{value: nativeamount}(
            address(tokenIds[1]),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        ){}
        catch{}
    }



    function extendLiquidityLock(uint256 secondsUntilUnlock) public onlyOwner {
        uint256 newUnlockTime = secondsUntilUnlock+block.timestamp;
        require(newUnlockTime>liquidityUnlockTime);
        liquidityUnlockTime=newUnlockTime;
    }

    // unlock time for contract LP
    uint256 public liquidityUnlockTime;

    // default for new lp added after release
    uint256 private constant DefaultLiquidityLockTime=14 days;

    //Release Liquidity Tokens once unlock time is over
    function releaseLiquidity() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= liquidityUnlockTime, "Locked");
        liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;       
        IPancakeERC20 liquidityToken = IPancakeERC20(lpAddress);
        // uint256 amount = liquidityToken.balanceOf(address(this));

        // only allow 20% 
        // amount=amount*2/10;
        liquidityToken.transfer(treasuryWallet, (liquidityToken.balanceOf(address(this)) * 2) / 10);
    }

    // burn all mPCKT in the contract, this gets built up when adding LP
    function burnLeftovers() public onlyOwner {
        tokenIds[1].transferFrom(address(this), burnAddress, tokenIds[1].balanceOf(address(this)) );
    }

    event OnVaultReceive(address indexed sender, uint256 amount, uint256 shared);
    receive() external payable {

        // @TODO
        // Check if it's coming from the gateway address
        // don't add LP (LP added to sidechains pool)

        // Send half to LP
        uint256 lpBal = msg.value / 2;
        uint256 shareBal = msg.value - lpBal;

        //if we have no shares 100% LP    
        if(totalShares <= 0){
            lpBal = msg.value;
            shareBal = 0;
        }

        // send any cross chain vault sends or returned change to all the share holders 
        if(!lpEnabled || msg.sender == address(pancakeRouter) || msg.sender == address(gatewayAddress)){
            lpBal = 0;
            shareBal = msg.value;
        } else {

            // split the LP part in half
            uint256 nativeToSpend = lpBal / 2;
            uint256 nativeToPost = lpBal - nativeToSpend;

            // get the current mPCKT balance
            uint256 contractTokenBal = tokenIds[1].balanceOf(address(this));
           
            // do the swap
            _swapNativeForToken(nativeToSpend, tokenIds[1], address(this));

            //new balance
            uint256 tokenToPost = tokenIds[1].balanceOf(address(this)) - contractTokenBal;

            // add LP
            _addLiquidity(tokenToPost, nativeToPost);
        }

        emit OnVaultReceive(msg.sender, msg.value, shareBal);
    }


}

// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract RentShares is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

	// each property has a unique total of "shares"
	// each time someone stakes an active property shares are given
	// each time someone un-stakes an active property shares are removed
	// shares should be tied to the NFT ids not the spot, so that old shares can be claimed


	// keeps a total for each user per property
	// time before they expire
	// if they haven't claimed in X it burns the excess on claim


	// game contract sends MNOP to rent shares contract instead of doing the math
	// rent shares contract only accepts from game contract 


	// The burn address
    address public constant burnAddress = address(0xdead);

    // array of all property nfts that get rent
    uint256[] public nfts;
    // a fast way to check if it's a registered nft
    mapping(uint256 => bool) public nftExists;

    IERC20 public token;
    address public gameCoordinator;

    mapping(address => bool) private canGive;

    mapping(uint256 => uint256) public totalRentSharePoints;
	//lock for the rent claim only 1 claim at a time
    bool private _isWithdrawing;
    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a decimal.
    mapping(uint256 => uint256) private profitPerShare;
    //the total reward distributed through the vault, for tracking purposes
    mapping(uint256 => uint256) public totalShareRewards;
    //the total payout through the vault, for tracking purposes
    mapping(uint256 => uint256) public totalPayouts;
    uint256 public allTotalPayouts;
    uint256 public allTotalBurns;
    uint256 public allTotalPaid;
    mapping(address => mapping(uint256 => uint256)) private rentShares;
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => mapping(uint256 => uint256)) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => mapping(uint256 => uint256)) private toBePaid;
    //Mapping of static rewards pending for an address
    mapping(address => uint256) private pendingRewards;

    constructor (
        IERC20 _tokenAddress,
        address _gameCoordinator,
        uint256[] memory _nfts
    ) {
        token = _tokenAddress;
        gameCoordinator = _gameCoordinator;

        for (uint i=0; i<_nfts.length; i++) {
            addNft(_nfts[i]);
        }
        token.approve(address(gameCoordinator), type(uint256).max);
        token.approve(address(this), type(uint256).max);
    }

    modifier onlyCanGive {
      require(canGive[msg.sender], "Can't do this");
      _;
    }


    // add NFT
    function addNft(uint256 _nftId) public onlyOwner {
        if(!_isInArray(_nftId, nfts)){
            nfts.push(_nftId);
            nftExists[_nftId] = true;
        }
    }

    // bulk add NFTS
    function addNfts(uint256[] calldata _nfts) external onlyOwner {
        for (uint i=0; i<_nfts.length; i++) {
            addNft(_nfts[i]);
        }
    }

	// manage which contracts/addresses can give shares to allow other contracts to interact
    function setCanGive(address _addr, bool _canGive) public onlyOwner {
        canGive[_addr] = _canGive;
    }

    //gets shares of an address/nft
    function getRentShares(address _addr, uint256 _nftId) public view returns(uint256){
        return (rentShares[_addr][_nftId]);
    }

    //Returns the amount a player can still claim
    function getAllRentOwed(address _addr, uint256 _mod) public view returns (uint256){

    	uint256 amount;
        for (uint i=0; i<nfts.length; i++) {
        	amount += getRentOwed(_addr, nfts[i]);
        }

        if(_mod > 0){
       		// adjust with the no claim mod
	        amount = amount.mul(_mod).div(100);
        }

        return amount;
    }

    function getRentOwed(address _addr, uint256 _nftId) public view returns (uint256){
       return  _getRentOwed(_addr, _nftId) + toBePaid[_addr][_nftId];
    }

    function canClaim(address _addr, uint256 _mod) public view returns (uint256){

        uint256 amount;
        for (uint i=0; i<nfts.length; i++) {
            amount += _getRentOwed(_addr, nfts[i]) + toBePaid[_addr][nfts[i]];
        }

        if(_mod > 0){
            // adjust with the no claim mod
            amount = amount.mul(_mod).div(100);
        }

        return getAllRentOwed(_addr, _mod).add(pendingRewards[_addr]);
    }

    function collectRent(uint256 _nftId, uint256 _amount) public onlyCanGive nonReentrant {
        allTotalPaid += _amount;
        _updatePorfitPerShare(_amount, _nftId);
        token.safeTransferFrom(address(msg.sender),address(this), _amount); 

    }
    
	// claim any pending rent, only allow 1 claim at a time
	//
	function claimRent(address _address, uint256 _mod) public nonReentrant {
		require(address(msg.sender) == address(gameCoordinator), 'Nope');
        require(!_isWithdrawing,'in progress');
        

        _isWithdrawing=true;

        // get everything to claim for this address
        uint256 amount;
        for (uint i=0; i<nfts.length; i++) {
            if(rentShares[_address][nfts[i]] > 0) {
            	uint256 amt = _getRentOwed(_address,nfts[i]);
            	if(amt > 0){
            		//Substracts the amount from the rent dividends
            		_updateClaimedRent(_address, nfts[i], amt);
            		totalPayouts[nfts[i]]+=amt;
                    amount += amt;
            	}
            }
        	
        }
        

        // adjust with the no claim mod
        uint256  claimAmount = amount.mul(_mod).div(100);
        uint256  burnAmount = amount.sub(claimAmount);

        // add any static rewards
        if(pendingRewards[_address] > 0){
            claimAmount = claimAmount.add(pendingRewards[_address]);
            pendingRewards[_address] = 0;
        }
        
        require(claimAmount!=0 || burnAmount!=0,"=0"); 

        allTotalPayouts+=claimAmount;
        allTotalBurns+=burnAmount;

        token.transferFrom(address(this),_address, claimAmount);

        if(burnAmount > 0){
			token.transferFrom(address(this),burnAddress, burnAmount);        	
        }

        _isWithdrawing=false;
//        emit OnClaimBNB(_address,amount);

    }

    function addPendingRewards(address _addr, uint256 _amount) public onlyCanGive {
      pendingRewards[_addr] = pendingRewards[_addr].add(_amount);
    }

    function giveShare(address _addr, uint256 _nftId) public onlyCanGive {
        require(nftExists[_nftId], 'Not a property');
        _addShare(_addr,_nftId);
    }

    function removeShare(address _addr, uint256 _nftId) public onlyCanGive {
        require(nftExists[_nftId], 'Not a property');
        _removeShare(_addr,_nftId);
    }

    function batchGiveShares(address _addr, uint256[] calldata _nftIds) external onlyCanGive {
      
        uint256 length = _nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            // require(nftExists[_nftId], 'Not a property');
            if(nftExists[_nftIds[i]]) {
                _addShare(_addr,_nftIds[i]);
            }
        }
    }

    function batchRemoveShares(address _addr, uint256[] calldata _nftIds) external onlyCanGive {
        
        uint256 length = _nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            // require(nftExists[_nftId], 'Not a property');
            if(nftExists[_nftIds[i]]) {
                _removeShare(_addr,_nftIds[i]);
            }
        }
    }



    //adds shares to balances, adds new Tokens to the toBePaid mapping and resets staking
    function _addShare(address _addr, uint256 _nftId) private {
        // the new amount of points
        uint256 newAmount = rentShares[_addr][_nftId].add(1);

        // update the total points
        totalRentSharePoints[_nftId]+=1;

        //gets the payout before the change
        uint256 payment = _getRentOwed(_addr, _nftId);

        //resets dividends to 0 for newAmount
        alreadyPaidShares[_addr][_nftId] = profitPerShare[_nftId].mul(newAmount);
        //adds dividends to the toBePaid mapping
        toBePaid[_addr][_nftId]+=payment; 
        //sets newBalance
        rentShares[_addr][_nftId]=newAmount;
    }

    //removes shares, adds Tokens to the toBePaid mapping and resets staking
    function _removeShare(address _addr, uint256 _nftId) private {
        //the amount of token after transfer
        uint256 newAmount=rentShares[_addr][_nftId].sub(1);
        totalRentSharePoints[_nftId] -= 1;

        //gets the payout before the change
        uint256 payment =_getRentOwed(_addr, _nftId);
        //sets newBalance
        rentShares[_addr][_nftId]=newAmount;
        //resets dividendss to 0 for newAmount
        alreadyPaidShares[_addr][_nftId] = profitPerShare[_nftId].mul(rentShares[_addr][_nftId]);
        //adds dividendss to the toBePaid mapping
        toBePaid[_addr][_nftId] += payment; 
    }



    //gets the rent owed to an address that aren't in the toBePaid mapping 
    function _getRentOwed(address _addr, uint256 _nftId) private view returns (uint256) {
        uint256 fullPayout = profitPerShare[_nftId].mul(rentShares[_addr][_nftId]);
        //if excluded from staking or some error return 0
        if(fullPayout<=alreadyPaidShares[_addr][_nftId]) return 0;
        return (fullPayout.sub(alreadyPaidShares[_addr][_nftId])).div(DistributionMultiplier);
    }


    //adjust the profit share with the new amount
    function _updatePorfitPerShare(uint256 _amount, uint256 _nftId) private {

        totalShareRewards[_nftId] += _amount;
        if (totalRentSharePoints[_nftId] > 0) {
            //Increases profit per share based on current total shares
            profitPerShare[_nftId] += ((_amount.mul(DistributionMultiplier)).div(totalRentSharePoints[_nftId]));
        }
    }

    //Substracts the amount from rent to claim, fails if amount exceeds dividends
    function _updateClaimedRent(address _addr, uint256 _nftId, uint256 _amount) private {
        if(_amount==0) return;
 
        require(_amount <= getRentOwed(_addr, _nftId),"exceeds amount");
        uint256 newAmount = _getRentOwed(_addr, _nftId);

        //sets payout mapping to current amount
        alreadyPaidShares[_addr][_nftId] = profitPerShare[_nftId].mul(rentShares[_addr][_nftId]);
        //the amount to be paid 
        toBePaid[_addr][_nftId]+=newAmount;
        toBePaid[_addr][_nftId]-=_amount;
    }

    function setContracts(IERC20 _tokenAddress, address _gameCoordinator) public onlyOwner {
        token = _tokenAddress;
        gameCoordinator = _gameCoordinator;
        token.approve(address(gameCoordinator), type(uint256).max);
    }
    /**
     * @dev Utility function to check if a value is inside an array
     */
    function _isInArray(uint256 _value, uint256[] memory _array) internal pure returns(bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }
        return false;
    }

}

// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IERC20Minter.sol";
import "./libs/ERC1155Tradable.sol";
import "./GameCoordinator.sol";
import "./RentShares.sol";

/**
 * @dev Contract for handling the NFT staking and set creation.
 */

contract NftStaking is  Ownable, IERC1155Receiver, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Minter;

    struct CardSet {
        uint256[] cardIds;
        uint256 tokensPerDayPerCard;      //reward per day per card
        uint256 bonusMultiplier;    // bonus for a full set 100% bonus = 1e5
        bool isRemoved;
    }

     struct Contracts {
        ERC1155Tradable nfts;
        IERC20Minter token;
        GameCoordinator gameCoordinator;
        RentShares rentShares;
    }

    struct Settings {
        bool stakingActive;
        uint256 maxStake;
        uint256 riskMod;
        bool checkRoll;
        uint256 levelLimit;
        uint256 maxHarvestTime;
        uint256 powerUpBurn;
        uint256 boostBurn;
        // amount of tokens to lock per slot
        uint256 tokenPerSlot;
        // amount of free slots
        uint256 freeSlots;
        uint256 endHarvestTime;
        uint256 modBase;
    }

    // types
    // 1 = percent boost
    // 2 = perday boost
    struct FarmBoostInfo {
        uint256 boostType; // what type of boost this is 
        uint256 boostNftId; // Nft id's that relate to this boost
        uint256 boostValue;  // the value that is tied to this boost
    }

    mapping(address => bool) public hasMigrated;

    // The burn address
    address public constant burnAddress = address(0xdead);  

    //dev address 
    address public operationsAddress;

    uint256[] public cardSetList;

    //Highest CardId added to the museum
    uint256 public highestCardId;

    Contracts public contracts;
    Settings public settings;

    //Addresses that can harvest on other users behalf, ie, game contracts
    mapping(address => bool) private canAdminHarvest;

    //SetId mapped to all card IDs in the set.
    mapping (uint256 => CardSet) public cardSets;

    //CardId to SetId mapping
    mapping (uint256 => uint256) private cardToSetMap;

    //toal staked for each cardId
    mapping (uint256 => uint256) public totalStaked;

    //user's cards staked mapped to the cardID with the value of the idx of stakedCards
    mapping (address => mapping(uint256 => uint256)) public userCards;

    //Status of cards staked mapped to the user addresses
    mapping (uint256 => mapping(uint256 => address)) public stakedCards;

    // amount per day saved on stake/unstake to cut loops out of harvesting
    mapping (address => uint256) public currentPerDay;

    // mapping of NFT ids that are valid power ups
    mapping (uint256 => bool) public powerUps;

    //users power up card stakes
    mapping (address => uint256) public powerUpsStaked;

    // mapping of NFT ids that are valid farm boosts
    mapping(uint256 => FarmBoostInfo) public farmBoostInfo;

    //users boost card stakes
    mapping (address => uint256) public farmBoostStaked;
    
    // mapping of custom burn amounts for power ups and boosters
    mapping (uint256 => uint256) public customBurnFees;

    //Last update time for a user's Token rewards calculation
    mapping (address => uint256) public userLastUpdate;

    // user token locks
    mapping (address => uint256) public userLocked;

     event Stake(address indexed user, uint256[] cardIds);
     event Unstake(address indexed user, uint256[] cardIds);
    event Harvest(address indexed user, uint256 amount);
    // event PowerUpStaked(address indexed user, uint256 cardId);
    // event PowerUpUnStaked(address indexed user, uint256 cardId);

    constructor(
        ERC1155Tradable _nftContractAddr, 
        IERC20Minter _tokenAddr, 
        GameCoordinator _gameCoordinator,
        RentShares _rentShares,
        address _operationsAddress

    ) { 
        contracts.nfts = _nftContractAddr;
        contracts.token = _tokenAddr;
        contracts.gameCoordinator = _gameCoordinator;
        contracts.rentShares = _rentShares;
        operationsAddress = _operationsAddress;
        canAdminHarvest[msg.sender] = true;
    }

    /**
     * @dev Utility function to check if a value is inside an array
     */
    function _isInArray(uint256 _value, uint256[] memory _array) internal pure returns(bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }
        return false;
    }

    function lockToken(uint256 _amount) external {
        require(_amount > 0 && contracts.token.balanceOf(msg.sender) >= _amount, 'not enough');

        userLocked[msg.sender] = userLocked[msg.sender].add(_amount);
        // move the tokens
        contracts.token.safeTransferFrom(address(msg.sender), address(this), _amount);
    }

    function unLockToken(uint256 _amount) external {
        // make sure they have enough locked and that once they withdraw it doesn't lead to more staked NFTs than slots
        require(userLocked[msg.sender] >= _amount && ((userLocked[msg.sender].sub(_amount)/settings.tokenPerSlot)  + settings.freeSlots >= _getNumOfNftsStakedByAddress(msg.sender)), 'unstake first');

        userLocked[msg.sender] = userLocked[msg.sender].sub(_amount);
        // move the tokens
        //contracts.token.safeTransferFrom(address(this), address(msg.sender), _amount);
        contracts.token.safeTransfer(address(msg.sender), _amount);
    }

    function getMaxSlots(address _address) external view returns(uint256){
        return _getMaxSlots(_address);
    }

    function _getMaxSlots(address _address) internal view returns(uint256){
        uint256 totalSlots = (userLocked[_address]/settings.tokenPerSlot) + settings.freeSlots;

        if(totalSlots > settings.maxStake){
            return settings.maxStake;
        }

        if(totalSlots <= settings.freeSlots){
            return settings.freeSlots;
        }
        return totalSlots;
    }

    /**
     * @dev Indexed boolean for whether a card is staked or not. Index represents the cardId.
     */
    function getCardsStakedOfAddress(address _user) public view returns(uint256[] memory) {
        uint256[] memory cardsStaked = new uint256[](highestCardId + 1);
        for (uint256 i = 0; i < highestCardId + 1; ++i) {           
            cardsStaked[i] = userCards[_user][i];
        }
        return cardsStaked;
    }
    
    /**
     * @dev Returns the list of cardIds which are part of a set
     */
    function getCardIdListOfSet(uint256 _setId) external view returns(uint256[] memory) {
        return cardSets[_setId].cardIds;
    }
    

    /**
     * @dev returns all the addresses that have a cardId staked
     */
    function getStakersOfCard(uint256 _cardId) external view returns(address[] memory) {
        address[] memory cardStakers = new address[](totalStaked[_cardId]);

        uint256 cur;
        for (uint256 i = 1; i <= totalStaked[_cardId]; ++i) {
            if(stakedCards[_cardId][i] != address(0)){
                cardStakers[cur] = stakedCards[_cardId][i];
                cur += 1;
            }
        }
        return cardStakers;
    }
 
    /**
     * @dev Indexed  boolean of each setId for which a user has a full set or not.
     */
    function getFullSetsOfAddress(address _user) public view returns(bool[] memory) {
        uint256 length = cardSetList.length;
        bool[] memory isFullSet = new bool[](length);
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = cardSetList[i];
            if (cardSets[setId].isRemoved) {
                isFullSet[i] = false;
                continue;
            }
            bool _fullSet = true;
            uint256[] memory _cardIds = cardSets[setId].cardIds;
            
            for (uint256 j = 0; j < _cardIds.length; ++j) {
                if (userCards[_user][_cardIds[j]] == 0) {
                    _fullSet = false;
                    break;
                }
            }
            isFullSet[i] = _fullSet;
        }
        return isFullSet;
    }

    /**
     * @dev Returns the amount of NFTs staked by an address for a given set
     */
    function getNumOfNftsStakedForSet(address _user, uint256 _setId) public view returns(uint256) {
        uint256 nbStaked = 0;
        if (cardSets[_setId].isRemoved) return 0;
        uint256 length = cardSets[_setId].cardIds.length;
        for (uint256 j = 0; j < length; ++j) {
            uint256 cardId = cardSets[_setId].cardIds[j];
            if (userCards[_user][cardId] > 0) {
                nbStaked = nbStaked.add(1);
            }
        }
        return nbStaked;
    }

    /**
     * @dev Returns the total amount of NFTs staked by an address across all sets
     */
    function getNumOfNftsStakedByAddress(address _user) public view returns(uint256) {
        
        return _getNumOfNftsStakedByAddress(_user);
    }

    function _getNumOfNftsStakedByAddress(address _user) internal view returns(uint256) {
        uint256 nbStaked = 0;
        for (uint256 i = 0; i < cardSetList.length; ++i) {
            nbStaked = nbStaked.add(getNumOfNftsStakedForSet(_user, cardSetList[i]));
        }
        return nbStaked;
    }
    
    /**
     * @dev Returns the total per day before any other adjustments or mods
     */ 
    function _calcPerDay(address _user) private view returns(uint256){
        uint256 totalTokensPerDay = 0;
        uint256 length = cardSetList.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = cardSetList[i];
            CardSet storage set = cardSets[setId];
            if (set.isRemoved) continue;
            uint256 cardLength = set.cardIds.length;
            bool isFullSet = true;
            uint256 setTokensPerDay = 0;
            for (uint256 j = 0; j < cardLength; ++j) {
                if (userCards[_user][set.cardIds[j]] == 0) {
                    isFullSet = false;
                    continue;
                }
                setTokensPerDay = setTokensPerDay.add(set.tokensPerDayPerCard);
            }
            if (isFullSet) {
                setTokensPerDay = setTokensPerDay.mul(set.bonusMultiplier).div(1e5);
            }
            totalTokensPerDay = totalTokensPerDay.add(setTokensPerDay);
        }
        return totalTokensPerDay;
    }

    /**
     * @dev Returns the total tokens pending for a given address. will return the totalPerDay,
     * if second param is set to true.
     */
    function totalPendingTokensOfAddress(address _user, bool _perDay) public view returns (uint256) {

        uint256 totalTokensPerDay = currentPerDay[_user];
        totalTokensPerDay = totalTokensPerDay.mul(settings.riskMod).div(1 ether);

        
        
        uint256 lastUpdate = userLastUpdate[_user];
        uint256 lastRollTime = contracts.gameCoordinator.getLastRollTime(_user);
        uint256 blockTime = block.timestamp;
        uint256 maxTime = lastUpdate.add(settings.maxHarvestTime);

        if(settings.maxHarvestTime > 0){

            // if we are checking the roll, set the max time to the last roll instead of last harvest
            if(settings.checkRoll ){
                maxTime = lastRollTime.add(settings.maxHarvestTime);
            }

            if( maxTime < blockTime){
                blockTime = maxTime;
            }            
        }

        if(settings.endHarvestTime > 0){
            if( settings.endHarvestTime  < blockTime){
                blockTime = settings.endHarvestTime;
            }
        }

        uint256 playerLevel = contracts.gameCoordinator.getLevel(_user);
        uint256 yieldMod = playerLevel.add(settings.modBase);

        totalTokensPerDay = totalTokensPerDay.mul(yieldMod).div(100);

        // check for farm boosts
        if(farmBoostStaked[_user] > 0){
            if(farmBoostInfo[farmBoostStaked[_user]].boostType == 1){
               // adjust based on a multiplier
               uint256 boostedValue = totalTokensPerDay.mul(farmBoostInfo[farmBoostStaked[_user]].boostValue);
               totalTokensPerDay = boostedValue.div(1 ether);
            }

            if(farmBoostInfo[farmBoostStaked[_user]].boostType == 2){
                // direct adjustment
                totalTokensPerDay = totalTokensPerDay.add(farmBoostInfo[farmBoostStaked[_user]].boostValue);
            }
        }

        if(_perDay || totalTokensPerDay == 0){
            return totalTokensPerDay;
        }

        return blockTime.sub(lastUpdate).mul(totalTokensPerDay.div(86400));
    }

    function getYieldMod(address _user) public view returns(uint256){
        uint256 playerLevel = contracts.gameCoordinator.getLevel(_user);
        uint256 levelMod = playerLevel.div(10).mul(1 ether);
        if(levelMod <= 0){
            levelMod = 1 ether;
        }

        return playerLevel.add(settings.modBase);
    }


    /**
     * @dev Manually sets the highestCardId, if it goes out of sync.
     * Required calculate the range for iterating the list of staked cards for an address.
     */
    function setHighestCardId(uint256 _highestId) external onlyOwner {
        // require(_highestId > 0, "Set if minimum 1 card is staked.");
        highestCardId = _highestId;
    }

    /**
     * @dev Adds a card set with the input param configs. Removes an existing set if the id exists.
     */
     // bool _isBooster,
     // uint256 _bonusFullSetBoost
     // uint256[] memory _poolBoosts, 
    function addCardSet(
        uint256 _setId, 
        uint256[] calldata _cardIds, 
        uint256 _bonusMultiplier, 
        uint256 _tokensPerDayPerCard
        
        ) external onlyOwner {
            removeCardSet(_setId);
            uint256 length = _cardIds.length;
            for (uint256 i = 0; i < length; ++i) {
                uint256 cardId = _cardIds[i];
                if (cardId > highestCardId) {
                    highestCardId = cardId;
                }
                // Check all cards to assign arent already part of another set
                require(cardToSetMap[cardId] == 0, "Card already assigned to a set");
                // Assign to set
                cardToSetMap[cardId] = _setId;
            }
            if (_isInArray(_setId, cardSetList) == false) {
                cardSetList.push(_setId);
            }
            cardSets[_setId] = CardSet({
                cardIds: _cardIds,
                bonusMultiplier: _bonusMultiplier,
                tokensPerDayPerCard: _tokensPerDayPerCard,
                isRemoved: false
            });
    }


    /**
     * @dev Remove a cardSet that has been added.
     */
    function removeCardSet(uint256 _setId) public onlyOwner {
        uint256 length = cardSets[_setId].cardIds.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 cardId = cardSets[_setId].cardIds[i];
            cardToSetMap[cardId] = 0;
        }
        delete cardSets[_setId].cardIds;
        cardSets[_setId].isRemoved = true;
    }

    /**
     * @dev Public harvest function
     */
    function harvest() public nonReentrant {
        _harvest(msg.sender);
    }

    /**
     * @dev Allow owner to call harvest for an account
     */
    function gameHarvest(address _user) public {
        require(canAdminHarvest[msg.sender],'Nope');
        _harvest(_user);
    }

    /**
     * @dev Harvests the accumulated Token in the contract, for the caller.
     */
    function _harvest(address _user) private {
        // require(!checkRoll || memenopoly.playerActive(msg.sender) ,"You must take a roll to harvest");
        require(canAdminHarvest[msg.sender] || _isActive(_user), "NftStaking: Farms locked");
        uint256 pendingTokens = totalPendingTokensOfAddress(_user,false);
        userLastUpdate[_user] = block.timestamp;
        if (pendingTokens > 0) {
            contracts.token.mint(operationsAddress, pendingTokens.div(40)); // 2.5% Token for the dev 
            contracts.token.mint(_user, pendingTokens);
        }
        emit Harvest(_user, pendingTokens);
    }

    /**
     * @dev Stakes the cards on providing the card IDs. 
     */
    function stake(uint256[] calldata _cardIds) external nonReentrant {
        /*require(_cardIds.length > 0, "you need to stake something");
        require(_isActive(msg.sender), "NftStaking: Farms locked");
        require(settings.maxStake == 0 || _getNumOfNftsStakedByAddress(msg.sender).add(_cardIds.length) <= _getMaxSlots(msg.sender), 'Max cards staked');*/
        require(_cardIds.length > 0 && isActive(msg.sender) && (settings.maxStake == 0 || _getNumOfNftsStakedByAddress(msg.sender).add(_cardIds.length) <= _getMaxSlots(msg.sender)), "Can't Stake");
        // require(!checkRoll || memenopoly.playerActive(msg.sender) ,"You must take a roll to stake");
        // Check no card will end up above max stake and if it is needed to update the user NFT pool

        _harvest(msg.sender);


        uint256 length = _cardIds.length;

        for (uint256 i = 0; i < length; ++i) {
            uint256 cardId = _cardIds[i];
            // require(userCards[msg.sender][cardId] == 0, "item already staked");
            require(cardToSetMap[cardId] != 0 && userCards[msg.sender][cardId] == 0, "you can't stake that");
        }
        
        //Stake 1 unit of each cardId
        uint256[] memory amounts = new uint256[](_cardIds.length);
        for (uint256 i = 0; i < _cardIds.length; ++i) {
            amounts[i] = 1;
        }

        contracts.rentShares.batchGiveShares(msg.sender, _cardIds);
        contracts.nfts.safeBatchTransferFrom(msg.sender, address(this), _cardIds, amounts, "");
        //Update the staked status for the card ID.
        for (uint256 i = 0; i < length; ++i) {
            uint256 cardId = _cardIds[i];
            totalStaked[cardId] = totalStaked[cardId].add(1);

            userCards[msg.sender][cardId] = totalStaked[cardId]; 
            stakedCards[cardId][totalStaked[cardId]] = msg.sender;
            
        }

        // update the currentPerDay
        currentPerDay[msg.sender] =  _calcPerDay(msg.sender);

        emit Stake(msg.sender, _cardIds);


    }
  
     /**
     * @dev Unstakes the cards on providing the card IDs. 
     */
    function unstake(uint256[] calldata _cardIds) external nonReentrant {
 
         // require(_cardIds.length > 0, "input at least 1 card id");
         require(_cardIds.length > 0 && _isActive(msg.sender), "NftStaking: Farms locked");
         // require(!checkRoll || memenopoly.playerActive(msg.sender) ,"You must take a roll to unstake");

         _harvest(msg.sender);

        // Check if all cards are staked and if it is needed to update the user NFT pool
        uint256 length = _cardIds.length;

        for (uint256 i = 0; i < length; ++i) {
            uint256 cardId = _cardIds[i];
            require(userCards[msg.sender][cardId] > 0, "Card not staked");

            // move the last item to the idx we just deleted
            if(userCards[msg.sender][cardId] != totalStaked[cardId]){
                stakedCards[cardId][userCards[msg.sender][cardId]] = stakedCards[cardId][totalStaked[cardId]];
                userCards[stakedCards[cardId][totalStaked[cardId]]][cardId] = userCards[msg.sender][cardId];
            } 
            
            delete stakedCards[cardId][totalStaked[cardId]];
            userCards[msg.sender][cardId] = 0;
            
            totalStaked[cardId] = totalStaked[cardId].sub(1);

        }
        
        contracts.rentShares.batchRemoveShares(msg.sender, _cardIds);

        //UnStake 1 unit of each cardId
        uint256[] memory amounts = new uint256[](_cardIds.length);
        for (uint256 i = 0; i < _cardIds.length; ++i) {
            amounts[i] = 1;
        }

        // update the currentPerDay
        currentPerDay[msg.sender] =  _calcPerDay(msg.sender);
        contracts.nfts.safeBatchTransferFrom(address(this), msg.sender, _cardIds, amounts, "");

        emit Unstake(msg.sender, _cardIds);
    }

    /**
     * @dev Emergency unstake the cards on providing the card IDs, forfeiting the Token rewards 
     */
    function emergencyUnstake(uint256[] calldata _cardIds) external nonReentrant {

        userLastUpdate[msg.sender] = block.timestamp;
        uint256 length = _cardIds.length;

        for (uint256 i = 0; i < length; ++i) {
            uint256 cardId = _cardIds[i];
            require(userCards[msg.sender][cardId] > 0, "Card not staked");
            // move the last item to the idx we just deleted
            if(userCards[msg.sender][cardId] != totalStaked[cardId]){
                stakedCards[cardId][userCards[msg.sender][cardId]] = stakedCards[cardId][totalStaked[cardId]];
                userCards[stakedCards[cardId][totalStaked[cardId]]][cardId] = userCards[msg.sender][cardId];
            } 


            delete stakedCards[cardId][totalStaked[cardId]];
            userCards[msg.sender][cardId] = 0;
            
            totalStaked[cardId] = totalStaked[cardId].sub(1);

        }
        
        contracts.rentShares.batchRemoveShares(msg.sender, _cardIds);

        //UnStake 1 unit of each cardId
        uint256[] memory amounts = new uint256[](_cardIds.length);
        for (uint256 i = 0; i < _cardIds.length; ++i) {
            amounts[i] = 1;
        }
        // update the currentPerDay
        currentPerDay[msg.sender] =  _calcPerDay(msg.sender);
        contracts.nfts.safeBatchTransferFrom(address(this), msg.sender, _cardIds, amounts, "");

    }
    
    function isActive(address _address) public view returns(bool){
        return _isActive(_address);
    }

    function _isActive(address _address) private view returns(bool){
        uint256 playerLevel = contracts.gameCoordinator.getLevel(_address);
//        uint256 playerTier = contracts.theBanker.getUserLevel(_address);

        if(settings.stakingActive && (!settings.checkRoll || contracts.gameCoordinator.playerActive(msg.sender)) && playerLevel >= settings.levelLimit){ // && playerTier >= tierLimit
            return true;
        }
        return false;

    }
    
    function setCustomBurnFee(uint256 _cardId, uint256 _amount) public onlyOwner {
        customBurnFees[_cardId] = _amount;
    }

    function setFarmBoost(uint256 _boostNftId, uint256 _boostType, uint256 _boostValue) public onlyOwner {
        farmBoostInfo[_boostNftId].boostNftId = _boostNftId;
        farmBoostInfo[_boostNftId].boostType = _boostType;
        farmBoostInfo[_boostNftId].boostValue = _boostValue;
    }

    /**
     * @dev Stakes the farm boost
     */
    function stakeFramBoost(uint256 _cardId) external {
        require(farmBoostInfo[_cardId].boostNftId == _cardId && farmBoostStaked[msg.sender] != _cardId, "Can't Stake Booster");
        require(_isActive(msg.sender), "Farms Locked");

        if(settings.boostBurn > 0 || customBurnFees[_cardId] > 0){
            bool burnSuccess = false;
            uint256 burnFee = settings.boostBurn;

            if(customBurnFees[_cardId] > 0){
                burnFee = customBurnFees[_cardId];
            }
            require(contracts.token.balanceOf(msg.sender) >= burnFee, 'Not enough to burn');

            burnSuccess = contracts.token.transferFrom(msg.sender, burnAddress, burnFee);
            require(burnSuccess, "Burn failed");
        }
        _harvest(msg.sender);

        // unstake a boost if it's already staked
        if(farmBoostStaked[msg.sender] > 0){
            _unStakeFarmBoost();
        }

        // transfer it to the contract
        contracts.nfts.safeTransferFrom(msg.sender, address(this), _cardId, 1, "");
        farmBoostStaked[msg.sender] = _cardId;

//        emit FarmBoostStaked(msg.sender, _cardId);
    }

    /**
     * @dev Unstake a powerup card if there is one for this addres 
     */
    function unStakeFarmBoost() public {
        _harvest(msg.sender);
        _unStakeFarmBoost();
    }

    function _unStakeFarmBoost() private {
        require(farmBoostStaked[msg.sender] > 0, "nftStaking: No Booster Staked");
        require(_isActive(msg.sender), "Farms Locked");
        
        uint256 cardId = farmBoostStaked[msg.sender];
        farmBoostStaked[msg.sender] = 0;
        // transfer from the contract back to the owner
        contracts.nfts.safeTransferFrom(address(this), msg.sender,  cardId, 1, "");
        

//        emit FarmBoostUnStaked(msg.sender, cardId);
    }

    /**
     * @dev Simple way to get the boost in other contracts
     */
    function getFarmBoost(address _address) external view returns(uint256) {
        return farmBoostStaked[_address];
    }


  function addPowerUp(uint256 _cardId) external onlyOwner {
        powerUps[_cardId] = true;
    }

    function removePowerUp(uint256 _cardId) external onlyOwner {
        powerUps[_cardId] = false;
    }

    /**
     * @dev Stakes the cards on providing the card IDs. 
     */
    function stakePowerUp(uint256 _cardId) external {
        require(powerUps[_cardId] && powerUpsStaked[msg.sender] != _cardId, "Can't Stake PowerUp");
        // require(powerUpsStaked[msg.sender] != _cardId, "NftStaking: Power up already staked");

        if(settings.powerUpBurn > 0 || customBurnFees[_cardId] > 0){
            bool burnSuccess = false;

            uint256 burnFee = settings.powerUpBurn;

            if(customBurnFees[_cardId] > 0){
                burnFee = customBurnFees[_cardId];
            }

            require(contracts.token.balanceOf(msg.sender) >= burnFee, 'Not enough to burn');

            burnSuccess = contracts.token.transferFrom(msg.sender, burnAddress, burnFee);
            require(burnSuccess, "Burn failed");
        }

        // unstake a powerup if it's already staked
        if(powerUpsStaked[msg.sender] > 0){
            unStakePowerUp();
        }

        // transfer it to the contract
        contracts.nfts.safeTransferFrom(msg.sender, address(this), _cardId, 1, "");
        powerUpsStaked[msg.sender] = _cardId;

//        emit PowerUpStaked(msg.sender, _cardId);
    }

    /**
     * @dev Unstake a powerup card if there is one for this addres 
     */
    function unStakePowerUp() public {
        require(powerUpsStaked[msg.sender] > 0, "NftStaking: No Powerup Staked");

        uint256 cardId = powerUpsStaked[msg.sender];
        powerUpsStaked[msg.sender] = 0;
        // transfer from the contract back to the owner
        contracts.nfts.safeTransferFrom(address(this), msg.sender,  cardId, 1, "");
        

//        emit PowerUpUnStaked(msg.sender, cardId);
    }

    /**
     * @dev Simple way to get the powerup from the game
     */
    function getPowerUp(address _address) external view returns(uint256) {
        return powerUpsStaked[_address];
    }





    /**
     * @dev set the contract addresses
     */
    function setContracts(
        IERC20Minter _tokenAddr, 
        ERC1155Tradable _nft, 
        GameCoordinator _gameCoordinator,
        RentShares _rentShares
        ) external onlyOwner {

              contracts.token = _tokenAddr;
              contracts.nfts = _nft;
              contracts.gameCoordinator = _gameCoordinator;
              contracts.rentShares = _rentShares;
    }  

    function addAdminHarvestAddress(address _address) public onlyOwner {
        canAdminHarvest[_address] = true;
    }

    function removeAdminHarvestAddress(address _address) public onlyOwner {
        canAdminHarvest[_address] = false;
    }

    function updateSettings(
        bool _stakingActive,
        bool _checkRoll,
        uint256 _riskMod,
        uint256 _maxHarvestTime,
        uint256 _maxStake,
        uint256 _powerUpBurn,
        uint256 _boostBurn,
        uint256 _levelLimit,
        uint256 _tokenPerSlot,
        uint256 _freeSlots,
        uint256 _endHarvestTime,
        uint256 _modBase

    ) public onlyOwner{
        settings.stakingActive = _stakingActive;
        settings.checkRoll = _checkRoll;
        settings.riskMod = _riskMod;
        settings.maxHarvestTime = _maxHarvestTime;
        settings.maxStake = _maxStake;
        settings.powerUpBurn = _powerUpBurn;
        settings.boostBurn = _boostBurn;
        settings.levelLimit = _levelLimit;
        settings.tokenPerSlot = _tokenPerSlot;
        settings.freeSlots = _freeSlots;
        settings.endHarvestTime = _endHarvestTime;
        settings.modBase = _modBase;
    }



    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
/// @title LP Staking
/// @author MrD 

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IERC20Minter.sol";
import "./libs/PancakeLibs.sol";


contract LpStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Minter;


    /* @dev struct to hold the user data */
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt.
        uint256 firstStake; // timestamp of the first time this wallet stakes
    }

    struct FeeInfo {
        uint256 feePercent;         // Percent fee that applies to this range
        uint256 timeCheck; // number of seconds from the intial stake this fee applies
    }

    /* @dev struct to hold the info for each pool */
    struct PoolInfo {
        IERC20Minter lpToken;           // Address of a token contract, LP or token.
        uint256 allocPoint;       // How many allocation points assigned to this pool. 
        uint256 lastRewardBlock;  // Last block number that distribution occurs.
        uint256 accRewardsPerShare;   // Accumulated Tokens per share, times 1e12. 
        uint directStake;      // 0 = off, 1 = buy token, 2 = pair bnb/token, 3 = pair token/token, 
        IERC20Minter tokenA; // leave emty if bnb, otherwise the token to pair with tokenB
        IERC20Minter tokenB; // the other half of the LP pair
        uint256 levelMultiplier;   // rewards * levelMultiplier is how many level points earned
    }

    // struct to hold the level info 
    struct UserLevel {
        uint256 currentLevel;   // current farm level
        uint256 levelRewards;   // the amount of farm level points earned
    }


    // Array of the level thresholds 
    uint256[] public userLevelsThresh;
    uint256 public maxLevels;
    mapping(address => UserLevel) public userLevel;

    // Migration vars 
    mapping(address => bool) public hasMigrated;

    // Global active flag
    bool isActive;

    // swap check
    bool isSwapping;

    // add liq check
    bool isAddingLp;

    // The Token
    IERC20Minter public rewardToken;

    // Base amount of rewards distributed per block
    uint256 public rewardsPerBlock;

    // Addresses 
    address public feeAddress;

    // Info of each user that stakes LP tokens 
    PoolInfo[] public poolInfo;

    // Info about the withdraw fees
    FeeInfo[] public feeInfo;
    
    // Total allocation points. Must be the sum of all allocation points in all pools 
    uint256 public totalAllocPoint = 0;

    // The block number when rewards start 
    uint256 public startBlock;

    uint256 public minPairAmount;

    uint256 public defaultFeePercent = 100;

    // PCS router
    IPancakeRouter02 private  pancakeRouter; 

    //TODO: Change to Mainnet
    //TestNet
     address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    // address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // Info of each user that stakes LP tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // @dev mapping of existing pools to avoid dupes
    mapping(IERC20Minter => bool) public pollExists;

    event SetActive( bool isActive);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event AutoAddLiquidity(address indexed user, uint256 indexed pid, uint256 amountLp, uint256 amountBnb);    
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetFeeStructure(uint256[] feePercents, uint256[] feeTimeChecks);
    event UpdateEmissionRate(address indexed user, uint256 rewardsPerBlock);

    constructor(
        IERC20Minter _rewardToken,
        address _feeAddress,
        uint256 _rewardsPerBlock,
        uint256 _startBlock,
        uint256[] memory _feePercents,
        uint256[] memory  _feeTimeChecks,
        uint256[] memory _levelThresh
    ) {
        require(_feeAddress != address(0),'Invalid Address');

        rewardToken = _rewardToken;
        feeAddress = _feeAddress;
        rewardsPerBlock = _rewardsPerBlock;
        startBlock = _startBlock;

        pancakeRouter = IPancakeRouter02(PancakeRouter);
        rewardToken.approve(address(pancakeRouter), type(uint256).max);

        // set the initial fee structure
        _setWithdrawFees(_feePercents ,_feeTimeChecks );

        // set the level thresholds
        setUserLevelThresh(_levelThresh);

        // add the SAS staking pool
        add(400, rewardToken,  true, 4000000000000000000, 1, IERC20Minter(address(0)), IERC20Minter(address(0)));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setWithdrawFees( uint256[] calldata _feePercents ,uint256[] calldata  _feeTimeChecks ) public onlyOwner {
        _setWithdrawFees( _feePercents , _feeTimeChecks );
    }

    function _setWithdrawFees( uint256[] memory _feePercents ,uint256[] memory  _feeTimeChecks ) private {
        delete feeInfo;
        for (uint256 i = 0; i < _feePercents.length; ++i) {
            require( _feePercents[i] <= 2500, "fee too high");
            feeInfo.push(FeeInfo({
                feePercent : _feePercents[i],
                timeCheck : _feeTimeChecks[i]
            }));
        }
        emit SetFeeStructure(_feePercents,_feeTimeChecks);
    }

    /* @dev Adds a new Pool. Can only be called by the owner */
    function add(
        uint256 _allocPoint, 
        IERC20Minter _lpToken, 
        bool _withUpdate,
        uint256 _levelMultiplier, 
        uint _directStake,
        IERC20Minter _tokenA,
        IERC20Minter _tokenB
    ) public onlyOwner {
        require(pollExists[_lpToken] == false, "nonDuplicated: duplicated");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        pollExists[_lpToken] = true;

        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accRewardsPerShare : 0,
            tokenA: _tokenA,
            tokenB: _tokenB,
            directStake: _directStake,
            levelMultiplier: _levelMultiplier
        }));
    }

    /* @dev Update the given pool's allocation point and deposit fee. Can only be called by the owner */
    function set(
        uint256 _pid, 
        uint256 _allocPoint, 
        bool _withUpdate, 
        uint256 _levelMultiplier,
        uint _directStake
    ) public onlyOwner {

        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].levelMultiplier = _levelMultiplier;
        poolInfo[_pid].directStake = _directStake;
    }

    /* @dev Return reward multiplier over the given _from to _to block */
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    /* @dev View function to see pending rewards on frontend.*/
    function pendingRewards(uint256 _pid, address _user)  external view returns (uint256) {
        return _pendingRewards(_pid, _user);
    }

    /* @dev calc the pending rewards */
    function _pendingRewards(uint256 _pid, address _user) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardsPerShare = accRewardsPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accRewardsPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see pending level rewards for this pool 
    function pendingLevelRewards(uint256 _pid, address _user)  external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 pending = _pendingRewards(_pid,_user);

        return pending.mul(pool.levelMultiplier.div(1 ether));
    }

     // return the current level
    function getUserLevel(address _user)  external view returns (uint256) {
        return userLevel[_user].currentLevel;
    }


    function setUserLevelThresh(uint256[] memory _levelThresh) public onlyOwner {
        userLevelsThresh = _levelThresh;
        maxLevels = userLevelsThresh.length;
    }

    function setUserLevel(address _user) internal {
        UserLevel storage uLevel = userLevel[_user];
        uint256 length = userLevelsThresh.length;
        uint256 level = 0;

        for (uint256 lvl = 0; lvl < length; ++lvl) {
            if(uLevel.levelRewards >= userLevelsThresh[lvl].mul(1 ether) ){
                level = lvl.add(1);
            }
        }

        uLevel.currentLevel = level;
    }

    /* @dev Update reward variables for all pools. Be careful of gas spending! */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /* @dev Update reward variables of the given pool to be up-to-date */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        rewardToken.mint(feeAddress, tokenReward.div(10));
        rewardToken.mint(address(this), tokenReward);

        pool.accRewardsPerShare = pool.accRewardsPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    /* @dev Harvest and deposit LP tokens into the pool */
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(isActive,'Not active');
        _deposit(_pid,_amount,msg.sender,false);
    }

    function _deposit(uint256 _pid, uint256 _amount, address _addr, bool _isDirect) private {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_addr];
        UserLevel storage level = userLevel[msg.sender];

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e12).sub(user.rewardDebt);
            
            if (pending > 0) {
                // handle updating level points
                if(pool.levelMultiplier > 0){
                    level.levelRewards = level.levelRewards.add(pending.mul(pool.levelMultiplier.div(1 ether)));
                    setUserLevel(_addr);
                }
                // send from the contract
                safeTokenTransfer(_addr, pending);
            }
        }

        if (_amount > 0) {

            if(!_isDirect){
                pool.lpToken.safeTransferFrom(address(_addr), address(this), _amount);
            }
            
            user.amount = user.amount.add(_amount);

        }

        if(user.firstStake == 0){
            // set the timestamp for the addresses first stake
            user.firstStake = block.timestamp;
        }

        user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e12);
        emit Deposit(_addr, _pid, _amount);
    }

   

    /* @dev Harvest and withdraw LP tokens from a pool*/
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        require(isActive,'Not active');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserLevel storage level = userLevel[msg.sender];

        require(user.amount >= _amount && _amount > 0, "withdraw: no tokens to withdraw");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e12).sub(user.rewardDebt);
        
        if (pending > 0) {
            // handle updating level points
            if(pool.levelMultiplier > 0){
                level.levelRewards = level.levelRewards.add(pending.mul(pool.levelMultiplier.div(1 ether)));
                setUserLevel(msg.sender);
            }
            // send from the contract
            safeTokenTransfer(msg.sender, pending);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);

            // check and charge the withdraw fee
            uint256 withdrawFeePercent = _currentFeePercent(msg.sender, _pid);

            uint256 withdrawFee = _amount.mul(withdrawFeePercent).div(10000);

            // subtract the fee from the amount we send
            uint256 toSend = _amount.sub(withdrawFee);

            // transfer the fee
            pool.lpToken.safeTransfer(feeAddress, withdrawFee);
      
            // transfer to user 
            pool.lpToken.safeTransfer(address(msg.sender), toSend);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /* @dev Withdraw entire balance without caring about rewards. EMERGENCY ONLY */
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
            
        // check and charge the withdraw fee
        uint256 withdrawFeePercent = _currentFeePercent(msg.sender, _pid);
        uint256 withdrawFee = amount.mul(withdrawFeePercent).div(10000);

        // subtract the fee from the amount we send
        uint256 toSend = amount.sub(withdrawFee);

        // transfer the fee
        pool.lpToken.safeTransfer(feeAddress, withdrawFee);
  
        // transfer to user 
        pool.lpToken.safeTransfer(address(msg.sender), toSend);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /* @dev Return the current fee */
    function currentFeePercent (address _addr, uint256 _pid) external view returns(uint256){
        return _currentFeePercent(_addr, _pid);
    }

    /* @dev calculate the current fee based on first stake and current timestamp */
    function _currentFeePercent (address _addr, uint256 _pid) internal view returns(uint256){
        // get the time they staked
        uint256 startTime = userInfo[_pid][_addr].firstStake;

        // get the current time
        uint256 currentTime = block.timestamp;

        // check the times
        for (uint256 i = 0; i < feeInfo.length; ++i) {
            uint256 t = startTime + feeInfo[i].timeCheck;
            if(currentTime < t){
                return feeInfo[i].feePercent;
            }
        }

        return defaultFeePercent;
    }

    /* @dev send in any amount of BNB to have it paired to LP and auto-staked */
    function directToLp(uint256 _pid) public payable nonReentrant {
        require(isActive,'Not active');
        require(poolInfo[_pid].directStake > 0 ,'No direct stake');
        require(!isSwapping,'Token swap in progress');
        require(!isAddingLp,'Add LP in progress');
        require(msg.value >= minPairAmount, "Not enough BNB to swap");

        uint256 liquidity;

        // directStake 1 - stake only the token (use the LPaddress)
        if(poolInfo[_pid].directStake == 1){
            // get the current token balance
            uint256 sasContractTokenBal = poolInfo[_pid].lpToken.balanceOf(address(this));
            _swapBNBForToken(msg.value, address(poolInfo[_pid].lpToken));
            liquidity = poolInfo[_pid].lpToken.balanceOf(address(this)).sub(sasContractTokenBal);
        }

        // directStake 2 - pair BNB/tokenA 
        if(poolInfo[_pid].directStake == 2){
            // use half the BNB to buy the token
            uint256 bnbToSpend = msg.value.div(2);
            uint256 bnbToPost =  msg.value.sub(bnbToSpend);

            // get the current token balance
            uint256 contractTokenBal = poolInfo[_pid].tokenA.balanceOf(address(this));
           
            // do the swap
            _swapBNBForToken(bnbToSpend, address(poolInfo[_pid].tokenA));

            //new balance
            uint256 tokenToPost = poolInfo[_pid].tokenA.balanceOf(address(this)).sub(contractTokenBal);

            // add LP
            (,, uint lp) = _addLiquidity(address(poolInfo[_pid].tokenA),tokenToPost, bnbToPost);
            liquidity = lp;
        }

        // directStake 3 - pair tokenA/tokenB
        if(poolInfo[_pid].directStake == 3){

            // split the BNB
            // use half the BNB to buy the tokens
            uint256 bnbForTokenA = msg.value.div(2);
            uint256 bnbForTokenB =  msg.value.sub(bnbForTokenA);

            // get the current token balances
            uint256 contractTokenABal = poolInfo[_pid].tokenA.balanceOf(address(this));
            uint256 contractTokenBBal = poolInfo[_pid].tokenB.balanceOf(address(this));

            // buy both tokens
            _swapBNBForToken(bnbForTokenA, address(poolInfo[_pid].tokenA));
            _swapBNBForToken(bnbForTokenB, address(poolInfo[_pid].tokenB));

            // get the balance to post
            uint256 tokenAToPost = poolInfo[_pid].tokenA.balanceOf(address(this)).sub(contractTokenABal);
            uint256 tokenBToPost = poolInfo[_pid].tokenB.balanceOf(address(this)).sub(contractTokenBBal);

            // pair it
            (,, uint lp) =  _addLiquidityTokens( 
                address(poolInfo[_pid].tokenA), 
                address(poolInfo[_pid].tokenB), 
                tokenAToPost, 
                tokenBToPost
            );
            liquidity = lp;

        }
        

        // stake it to the contract
        _deposit(_pid,liquidity,msg.sender,true);

    }


    // LP Functions
    // adds liquidity and send it to the contract
    function _addLiquidity(address token, uint256 tokenamount, uint256 bnbamount) private returns(uint, uint, uint){
        isAddingLp = true;
        uint amountToken;
        uint amountETH;
        uint liquidity;

       (amountToken, amountETH, liquidity) = pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(token),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
        isAddingLp = false;
        return (amountToken, amountETH, liquidity);

    }

    function _addLiquidityTokens(address _tokenA, address _tokenB, uint256 _tokenAmountA, uint256 _tokenAmountB) private returns(uint, uint, uint){
        isAddingLp = true;
        uint amountTokenA;
        uint amountTokenB;
        uint liquidity;

       (amountTokenA, amountTokenB, liquidity) = pancakeRouter.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _tokenAmountA,
            _tokenAmountB,
            0,
            0,
            address(this),
            block.timestamp
        );
        isAddingLp = false;

        return (amountTokenA, amountTokenB, liquidity);

    }

    function _swapBNBForToken(uint256 amount, address _token) private {
        isSwapping = true;
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(_token);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );
        isSwapping = false;
    }

    function _swapTokenForToken(address _tokenA, address _tokenB, uint256 _amount) private {
        isSwapping = true;
        address[] memory path = new address[](2);
        path[0] = address(_tokenA);
        path[1] = address(_tokenB);

        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        isSwapping = false;
    }

    /* @dev Safe token transfer function, just in case if rounding error causes pool to not have enough tokens */
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = rewardToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > bal) {
            transferSuccess = rewardToken.transfer(_to, bal);
        } else {
            transferSuccess = rewardToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
        emit SetActive(_isActive);
    }

    function setMinPairAmount(uint256 _minPairAmount) public onlyOwner {
        minPairAmount = _minPairAmount;
    }

    function setDefaultFee(uint256 _defaultFeePercent) public onlyOwner {
        require(_defaultFeePercent <= 500, "fee too high");
        defaultFeePercent = _defaultFeePercent;
    }


    function updateTokenContract(IERC20Minter _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    function setFeeAddress(address _feeAddress) public {
        require(_feeAddress != address(0),'Invalid Address');
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function updateEmissionRate(uint256 _rewardsPerBlock) public onlyOwner {
        massUpdatePools();
        rewardsPerBlock = _rewardsPerBlock;
        emit UpdateEmissionRate(msg.sender, _rewardsPerBlock);
    }

    // pull all the tokens out of the contract, needed for migrations/emergencies 
    function withdrawToken() public onlyOwner {
        safeTokenTransfer(feeAddress, rewardToken.balanceOf(address(this)));
    }

    // pull all the bnb out of the contract, needed for migrations/emergencies 
    function withdrawBNB() public onlyOwner {
         (bool sent,) =address(feeAddress).call{value: (address(this).balance)}("");
        require(sent,"withdraw failed");
    }


    receive() external payable {}
}

// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./RentShares.sol";


contract GameCoordinator is Ownable {

  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
    
    
  EnumerableSet.AddressSet private gameContracts;

	RentShares public rentShares;

  uint256 public activeTimeLimit;

	struct GameInfo {
		address contractAddress; // game contract
		uint256 minLevel; // min level for this game to be unlocked
		uint256 maxLevel; // max level this game can give
	}

	struct PlayerInfo {
      uint256 rewards; //pending rewards that are not rent shares
      uint256 level; //the current level for this player
      uint256 totalClaimed; //lifetime mnop claimed from the game
      uint256 totalPaid; //lifetime rent and taxes paid
      uint256 totalRolls; //total rolls for this player
      uint256 lastRollTime; // timestamp of the last roll on any board
    }

    mapping(uint256 => GameInfo) public gameInfo;
    mapping(address => PlayerInfo) public playerInfo;

    uint256 public totalPlayers;

    constructor(
        RentShares _rentSharesAddress, // rent share contract
        uint256 _activeTimeLimit 
    ) {

      	rentShares = _rentSharesAddress;
        activeTimeLimit = _activeTimeLimit;
      /*
      	for (uint i=0; i<_gameContracts.length; i++) {
      		setGame(i,_gameContracts[i],_minLevel[i],_maxLevel[i]);
      	} */
    }

    /** 
    * @notice Modifier to only allow updates by the VRFCoordinator contract
    */
    modifier onlyGame {
        require(gameContracts.contains(address(msg.sender)), 'Game Only');
        _;
    }

    function getRewards(address _address) external view returns(uint256) {
      return playerInfo[_address].rewards;
    }

    function getLevel(address _address) external view returns(uint256) {
    	return playerInfo[_address].level;
    }

    function getTotalRolls(address _address) external view returns(uint256) {
      return playerInfo[_address].totalRolls;
    }

    function getLastRollTime(address _address) external view returns(uint256) {
      return playerInfo[_address].lastRollTime;
    }

    function addTotalPlayers(uint256 _amount) public onlyGame {
      totalPlayers = totalPlayers.add(_amount);
    }    

    function addRewards(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].rewards = playerInfo[_address].rewards.add(_amount);
    }

    function setLevel(address _address, uint256 _level) public onlyGame {
      playerInfo[_address].level = _level;
    }

    function addTotalClaimed(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].totalClaimed = playerInfo[_address].totalClaimed.add(_amount);
    }

    function addTotalPaid(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].totalPaid = playerInfo[_address].totalPaid.add(_amount);
    }

    function addTotalRolls(address _address) public onlyGame {
      playerInfo[_address].totalRolls = playerInfo[_address].totalRolls.add(1);
    }

    function setLastRollTime(address _address, uint256 _lastRollTime) public onlyGame {
      playerInfo[_address].lastRollTime = _lastRollTime;
    }

    function setGame(uint256 _gameId, address _gameContract, uint256 _minLevel, uint256 _maxLevel) public onlyOwner {
    	
      if(!gameContracts.contains(address(_gameContract))){
        gameContracts.add(address(_gameContract));
      }
      gameInfo[_gameId].contractAddress = _gameContract;
    	gameInfo[_gameId].minLevel = _minLevel;
    	gameInfo[_gameId].maxLevel = _maxLevel;

    }

    function removeGame(uint256 _gameId) public onlyOwner {
    	require(gameInfo[_gameId].maxLevel > 0, 'Game Not Found');
      gameContracts.remove(address(gameInfo[_gameId].contractAddress));
    	delete gameInfo[_gameId];
    }

    function canPlay(address _player, uint256 _gameId)  external view returns(bool){
    	return _canPlay(_player, _gameId);
    }
    
    function _canPlay(address _player, uint256 _gameId)  internal view returns(bool){
    	if(playerInfo[_player].level >= gameInfo[_gameId].minLevel){
    		return true;
    	}

    	return false;
    }

    function playerActive(address _player) external view returns(bool){
        return _playerActive(_player);
    }

    function _playerActive(address _player) internal view returns(bool){
        if(block.timestamp <= playerInfo[_player].lastRollTime.add(activeTimeLimit)){
            return true;
        }
        return false;
    }

    // Hook rent claims into this contract
    // check for the last roll
    // after 1 day every day reduces it by 10% up until there is only 10% left

    function claimRent() public {
    	require(rentShares.canClaim(msg.sender,0) > 0, 'Nothing to Claim');

    	// claim the rent share
    	rentShares.claimRent(msg.sender,_getMod(msg.sender));
    }

    function getRentOwed(address _address) public view returns(uint256) {
    	return rentShares.canClaim(_address,_getMod(_address));
    }

    function _getMod(address _address) private view returns(uint256) {
    	uint256 mod = 100;
    	uint256 cutOff = playerInfo[_address].lastRollTime.add(activeTimeLimit);

    	if(cutOff > block.timestamp) {
    		// we need to adjust 
    		// see how many days
    		uint256 d = cutOff.sub(block.timestamp).div(activeTimeLimit);
    		//if over 10 days, force it to 10%
    		if(d > 10) {
    			mod = 10;
    		} else {
    			mod = mod.sub(d.mul(10));
    		}
    	}
    	return mod;
    }

    function setRentShares(RentShares _rentShares) public onlyOwner {
      rentShares = _rentShares;
    }

    function setActiveTimeLimi(uint256 _activeTimeLimit) public onlyOwner {
      activeTimeLimit = _activeTimeLimit;
    }
    
}