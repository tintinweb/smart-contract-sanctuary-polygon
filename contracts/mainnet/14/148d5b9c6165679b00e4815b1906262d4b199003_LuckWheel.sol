/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File contracts/ILadder.sol

pragma solidity ^0.8.0;

uint constant PRIZE_HEAD_LENGTH = 3; 
uint constant PRIZE_TAIL_LENGTH = 5; // (=R)
uint constant PRIZE_TAIL_GROUP_SIZE = 20;
interface ILadder {
  event SeasonCreated(uint seasonNumber);
  
  struct Player {
    address account;
    uint chainId;
    uint points;
    uint gamesPlayed;
  }

  struct Winner {
    address account;
    uint chainId;
    uint place;
    uint prizeAmount;
  }

  struct Season {
    uint id;
    bool areWinnersReported;
    bool isPrizeAmountDistributedBetweenChains;
    uint prizeAmount;
    uint[PRIZE_HEAD_LENGTH] prizeHead;
    uint[PRIZE_TAIL_LENGTH] prizeTail;
    uint[2] seasonInterval;
    uint[2][4] weekendIntervals;
  }

  function reportGamePoints(
    address[] calldata accounts, 
    uint[] calldata chainIds,
    uint[] calldata points
  ) external;
  
  function getPlayerCount(
    uint seasonNumber, 
    uint chainId
  ) external view returns(uint);
  
  function getPlayers(
    uint chainId,
    uint seasonNumber, 
    uint startIdx, 
    uint endIdx
  ) external view returns(Player[] memory);
  
  function getPlayerFor(
    uint chainId,
    uint seasonNumber, 
    address account
  ) external view returns(Player memory);
  
  function reportSeasonWinners(
    address[] calldata accounts, 
    uint[] calldata chainIds,
    uint[] calldata places
  ) external;


  function reserveChainLadderBalance(uint chainId) external;

  function freeChainUnclaimableReservedLadderBalance(uint chainId) external;

  function saveChainLadderBalance(uint chainId) external;

  function distributePrizeFundBetweenChains() external;

  function createSeason(
    uint[2] calldata seasonInterval,
    uint[2][4] calldata weekendIntervals
  ) external;

  function setSeasonInterval(
    uint[2] calldata seasonInterval
  ) external;

  function setSeasonWeekendInterval(
    uint weekendNumber, // 1,2,3 or 4
    uint[2] calldata weekendInterval
  ) external;

  function getActiveSeason() external view
    returns(Season memory);
  
  function getSeasonByNumber(uint seasonNumber) external view
    returns(Season memory);

  function getSeasons(uint startIdx, uint endIdx) external view 
    returns(Season[] memory);

  function getActiveSeasonNumber() external view returns(uint);

  function getSupportedChainIds() external view returns(uint[] memory);
  
  function setSupportedChainIds(uint[] memory) external;
  
  function removeSupportedChainIds(uint[] memory) external;

  function getPauserRole() external pure returns (bytes32);
  
  function getExtractorRole() external pure returns (bytes32);

  function getChainSeasonWinnerCount(uint chainId, uint seasonNumber) 
    external view returns(uint);
  
  function getChainSeasonWinners(
    uint chainId, 
    uint seasonNumber, 
    uint startIdx, 
    uint endIdx
  ) external view returns(Winner[] memory);
  
  function shareWinnersWithChain(uint chainId, uint startIdx, uint endIdx) external;

  function getChainSeasonBalance(uint chainId, uint seasonNumber) 
    external view returns(uint);

  function getPointsPrecision() external pure returns(uint); 

  function getPrimaryChainId() external view returns(uint);

  function penalizeAccounts(
    uint[] calldata chainIds,
    address[] calldata accounts,
    uint[] calldata pointsToRemove,
    uint[] calldata gamesToRemove
  ) external; 

  function unpenalizeAccounts(
    uint[] calldata chainIds,
    address[] calldata accounts,
    uint[] calldata pointsToAdd,
    uint[] calldata gamesToAdd
  ) external;
}


// File contracts/ITreasury.sol


pragma solidity ^0.8.0;

uint constant PayeeCount = 3;

interface ITreasury {
  enum PayeeIds { FOUNDERS, STAKING, SKIN }
  
  event Transfer(address payee, uint amount);
  event MintFundsAccepted(uint amount);
  event ResurrectionFundsAccepted(uint amount);
  event AcceptedFundsDistributed(uint amountPpk, uint amountStaking, uint amountTournaments);

  function transfer() external;
  function getPayees() external view returns (address[PayeeCount] memory);
  function getSharesInCentipercents() external view returns (uint[PayeeCount] memory);
  function getCyclesInDays() external view returns (uint[PayeeCount] memory);
  function getPayTimes() external view returns (uint[PayeeCount] memory);
  function getSecondsInDay() external view returns (uint);
  function getSNKAddress() external view returns (address);

  // ev2
  function getPpkBalance() external view returns (uint);
  function getTournamentsBalance() external view returns (uint);
  function getLpStakingBalance() external view returns (uint);
  function acceptMintFunds(uint amount) external; 
  function acceptResurrectionFunds(uint amount) external;
  
  function payPpkRewards(address recipient, uint amount) external;

  // luckwheel
  function mintLuckWheelSNOOK(address to) external returns(uint);
  function awardLuckWheelSNK(address to, uint prizeAmount) external;

  // ladder
  function acceptSeasonWinners(
    uint seasonNumber, 
    ILadder.Winner[] memory winners
  ) external;
  function getWinnerFor(
    address account,
    uint seasonNumber 
  ) external view returns(ILadder.Winner memory);
  function claimPrizeFor(
    address account, 
    uint seasonNumber
  ) external;
  function purgeLadderWinner(
    address account,
    uint seasonNumber
  ) external;
  function reserveTournamentsBalance(uint amount) external;
  function getReservedTournamentsBalance() external view returns(uint);
  function freeUnclaimableReservedTournamentsBalance(uint amount) external;
}


// File contracts/IPRNG.sol


pragma solidity ^0.8.0;

interface IPRNG {
  function generate() external;
  function read(uint64 max) external returns (uint64);
}


// File contracts/ILuckWheel.sol


pragma solidity ^0.8.0;

interface ILuckWheel {
  // keccack256: 60b6c2f89a3109fa0434654121cba693ec714eb2ed068a5abebf604f9124c924
  event SNKPrizeWin(address indexed to, uint prizeAmount);
  // keccack256: 358b42ae86f1a8facae5fe253e82ceacf922b9092c24142d904f19fb5b0a35d9
  event SNOOKPrizeWin(address indexed to, uint snookId);
  // keccack256: 9b5b377fb9211713b7e47651d4bbb7481643ec2f18027198d1043532ceb0d2ef
  event NoLuck(address indexed to);

  function getRequiredCheckinsToSilverWheel() external view returns(uint);
  function getRequiredCheckinsToGoldenWheel() external view returns(uint);
  function checkin() external;
  function getStatusFor(address a) external view  
    returns (
      uint silverWheels, 
      uint goldenWheels, 
      uint checkinCount, 
      uint lastCheckinTimestamp
    );
  function spinGoldenWheel() external;
  function spinSilverWheel() external;
}


// File contracts/LuckWheel.sol


pragma solidity ^0.8.0;




contract LuckWheel is Initializable, ILuckWheel {  
  
  struct AccountCheckin {
    uint timestamp;
    uint count;
  }

  mapping (address => AccountCheckin) private _accountCheckin;
  uint private _secondsInDay;
  IPRNG private _prng;
  ITreasury private _treasury;
  uint private _chanceToWin200SNK1in;
  uint private _chanceToWin500SNK1in;
  uint private _chanceToMintSNOOK1in;
  uint private _requiredCheckinsToSilverWheel;
  uint private _requiredCheckinsToGoldenWheel;

  function initialize(
    uint secondsInDay,
    IPRNG prng,
    ITreasury treasury,
    uint chanceToWin200SNK1in,
    uint chanceToWin500SNK1in,
    uint chanceToMintSNOOK1in,
    uint requiredCheckinsToSilverWheel,
    uint requiredCheckinsToGoldenWheel
  ) initializer public {
    _secondsInDay = secondsInDay;
    _prng = IPRNG(prng);
    _treasury = ITreasury(treasury);
    _chanceToWin200SNK1in = chanceToWin200SNK1in;
    _chanceToWin500SNK1in = chanceToWin500SNK1in;
    _chanceToMintSNOOK1in = chanceToMintSNOOK1in;
    _requiredCheckinsToSilverWheel = requiredCheckinsToSilverWheel;
    _requiredCheckinsToGoldenWheel = requiredCheckinsToGoldenWheel;
  }

  function getRequiredCheckinsToSilverWheel() external override view returns(uint) {
    return _requiredCheckinsToSilverWheel;
  }

  function getRequiredCheckinsToGoldenWheel() external override view returns(uint) {
    return _requiredCheckinsToGoldenWheel;
  }


  function checkin() external override {
    require(block.timestamp - _accountCheckin[msg.sender].timestamp >= _secondsInDay, 'LuckWheel: already checked in');
    _accountCheckin[msg.sender].count += 1;
    _accountCheckin[msg.sender].timestamp = block.timestamp;
  }

  function _getStatusFor(address a) internal view 
    returns (
      uint silverWheels, 
      uint goldenWheels, 
      uint checkinCount, 
      uint lastCheckinTimestamp
    ) 
  {
    checkinCount = _accountCheckin[a].count; 
    lastCheckinTimestamp = _accountCheckin[a].timestamp;
    return (
      checkinCount / _requiredCheckinsToSilverWheel, 
      checkinCount / _requiredCheckinsToGoldenWheel, 
      checkinCount, 
      lastCheckinTimestamp
    ); 
  }

  function getStatusFor(address a) external view override 
    returns (
      uint silverWheels, 
      uint goldenWheels, 
      uint checkinCount, 
      uint lastCheckinTimestamp
    ) 
  {
    return _getStatusFor(a);
  }

  function spinGoldenWheel() external override {
    (,uint goldenWheels,,) = _getStatusFor(msg.sender);
    require(goldenWheels > 0, 'No golden wheels');
    _prng.generate();
    // give 200 SNK with chance of 1/1000 or 500 SNK with chance of 1/5000 from treasury.
    _accountCheckin[msg.sender].count -= _requiredCheckinsToGoldenWheel;
    uint choice1 = _prng.read(uint64(_chanceToWin200SNK1in));
    uint choice2 = _prng.read(uint64(_chanceToWin500SNK1in));
    uint prizeAmount = 0;
    if (choice1 == 0) { // just any number
      prizeAmount = 200 ether;
    } else if (choice2 == 0) {
      prizeAmount = 500 ether;
    }
    if (prizeAmount > 0) {
      _treasury.awardLuckWheelSNK(msg.sender, prizeAmount);
      emit SNKPrizeWin(msg.sender, prizeAmount);
    } else {
      emit NoLuck(msg.sender);
    }
  }

  function spinSilverWheel() external override {
    (uint silverWheels,,,) = _getStatusFor(msg.sender);
    require(silverWheels>0, 'No silver wheels');
    _prng.generate();
    // mint snook, 50% chance
    _accountCheckin[msg.sender].count -= _requiredCheckinsToSilverWheel;
    uint choice = _prng.read(uint64(_chanceToMintSNOOK1in)); 
    if (choice == 0) {
      uint snookId = _treasury.mintLuckWheelSNOOK(msg.sender);
      emit SNOOKPrizeWin(msg.sender, snookId);
    } else {
      emit NoLuck(msg.sender);
    }
  }  
}