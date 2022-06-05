// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "AggregatorV3Interface.sol";
import "Ownable.sol";

contract CryptoBetsV2 is Ownable{
  // Address of the owner
  address payable ownerAddress;
  // Version of contract, used to properly display all parameters on the website.
  uint256 public version = 1;
  // Start taking bets time.
  uint256 public startTime;
  // A period of time after which the bet is concluded in minutes(taken a correction for the method execution time).
  uint256 public durationMinutes;
  // Conclude bet time.
  uint256 public endTime;
  // Bet name.
  string public name;
  // Bet description.
  string public description;
  // Price of eth/usd at the time of starting taking bets.
  int256 public startingPrice;
  // Array of all players betting for.
  address payable[] public playersFor;
  // Amounts payed by each player.
  uint256[] public playersForPayedAmount;
  // Total amount bet for.
  uint256 public amountBetFor;
  // Array of all players betting against.
  address payable[] public playersAgainst;
  // Amounts payed by each player.
  uint256[] public playersAgainstPayedAmount;
  // Total amount bet against.
  uint256 public amountBetAgainst;
  // Array of all players who won previous bet.
  address payable[] public recentWinners;
  // Array of money payed to players who won previous bet.
  uint256[] public recentWinnersWonAmount;
  // Minimum bet amount.
  uint256 public minimumBet = 1e18;//1 MATIC
  // Chainlink exchange rate providers.
  AggregatorV3Interface internal maticUsdPriceFeed;
  AggregatorV3Interface internal ethUsdPriceFeed;
  // Possible bet states.
  enum BETTING_STATE {TAKING_BETS,CLOSED,WAITING_FOR_RESULTS}// respectively 0,1,2
  // Contract state (0/1/2)
  BETTING_STATE public bettingState;

  constructor(
    string memory _name,
    string memory _description,
    address _ethPriceFeedAddress,// Chainlink ethereum price feed address on current blockchain.
    address _maticPriceFeedAddress,// Chainlink matic price feed address on current blockchain.
    uint256 _durationMinutes// A period of time after which the bet is concluded in minutes.
    ){
    require(_durationMinutes>=2,"Betting must last at least 2 minutes!");
    ownerAddress = payable(msg.sender);
    durationMinutes = _durationMinutes;// A period of time after which the bet is concluded in minutes.
    maticUsdPriceFeed = AggregatorV3Interface(_maticPriceFeedAddress);
    ethUsdPriceFeed = AggregatorV3Interface(_ethPriceFeedAddress);
    bettingState = BETTING_STATE.CLOSED;
    name = _name;
    description = _description;
  }

  // Function automatically called after previous round has ended( can only be called by the owner).
  function startTakingBets() public onlyOwner {
    require(bettingState == BETTING_STATE.CLOSED, "Cant start a new betting yet!");// Check if previous round has finished.
    bettingState = BETTING_STATE.TAKING_BETS;
    (,int256 price,,,)= ethUsdPriceFeed.latestRoundData();
    startingPrice = price;
    startTime = block.timestamp;
    endTime = startTime + durationMinutes * 1 minutes;
  }

  // Returns minimum met in USD according to chainlink price feed.
  function getMinBetUsd() external view returns (uint256){
    (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
    uint256 adjustedPrice = uint256(price)*1e10; //8+10 decimals
    return (minimumBet * adjustedPrice)/1e18;//Minimum bet amount in USD per current exchange rate.
  }

  // Returns minimum bet in MATIC.
  function getMinBet() public view returns (uint256){
    return minimumBet;//Minimum bet in MATIC.
  }

  // Functions for users to enter the betting.
  // Transaction must a set minimum amount of token to place a bet.
  function betFor() external payable{
    require(bettingState == BETTING_STATE.TAKING_BETS,"Not taking bets rn!");// Only allow to enter if the betting has begun.
    require(block.timestamp < endTime-(durationMinutes/2),"Not taking bets anymore! You must wait for another round.");//Stop taking bets half way through.
    require(msg.value >= minimumBet, "Not enough MATIC! Run getMinBet() to get a minimum bet amount.");
    playersFor.push(payable(msg.sender));// Add player to the array for.
    playersForPayedAmount.push(msg.value);// Remember how much they bet.
    amountBetFor += msg.value;// Add amount to total(makes payout easier).
  }

  function betAgainst() external payable{
    require(bettingState == BETTING_STATE.TAKING_BETS,"Not taking bets rn!");// Only allow to enter if the betting has begun.
    require(block.timestamp < endTime-(durationMinutes/2),"Not taking bets anymore! You must wait for another round.");//Stop taking bets half way through.
    require(msg.value >= getMinBet(), "Not enough MATIC! Run getMinBet() to get a minimum bet amount.");
    playersAgainst.push(payable(msg.sender));// Add player to the array against.
    playersAgainstPayedAmount.push(msg.value);// Remember how much they bet.
    amountBetAgainst += msg.value;// Add amount to total(makes payout easier).
  }

  // Function executed by the server automatically after
  // a set amount of time has passed.
  // Reads out latest eth price and compares to amount from before.
  // Sets startTime and endTime to 0 and resets arrays and variables.
  function concludeBetting(bool startNew) external onlyOwner {
    require(block.timestamp >= endTime,"Betting can not conclude until a set amount of time has passed, run .endTime() to check when it can be ended.");// Make sure it is supposed to end now.
    bettingState = BETTING_STATE.CLOSED;
    (,int256 price,,,)= ethUsdPriceFeed.latestRoundData();
    uint256 pool = amountBetFor+amountBetAgainst;
    recentWinnersWonAmount = new uint256[](0);
    if(startingPrice>price){
      if(playersFor.length!=0 && amountBetFor>0){
        recentWinners = playersFor;
        for(uint256 i=0;i<playersFor.length;i++){
          recentWinnersWonAmount.push(((pool*((playersForPayedAmount[i]*1e18)/amountBetFor))/1e20)*95);// minus 5% commision(used mainly for paying gas for transfering rewards to winners).
          playersFor[i].transfer(recentWinnersWonAmount[i]);
        }
      }
    }else{
      if(playersAgainst.length!=0 && amountBetAgainst>0){
        recentWinners = playersAgainst;
        for(uint256 i=0;i<playersAgainst.length;i++){
          recentWinnersWonAmount.push(((pool*((playersAgainstPayedAmount[i]*1e18)/amountBetAgainst))/1e20)*95);// minus 5% commision(used mainly for paying gas for transfering rewards to winners).
          playersAgainst[i].transfer(recentWinnersWonAmount[i]);
        }
      }
    }
    ownerAddress.transfer(address(this).balance);
    startTime = 0;
    endTime = 0;
    playersFor = new address payable[](0);
    playersAgainst = new address payable[](0);
    playersForPayedAmount = new uint256[](0);
    playersAgainstPayedAmount = new uint256[](0);
    amountBetFor = 0;
    amountBetAgainst = 0;
    if(startNew)startTakingBets();
  }

 // Returns the amount of players that bet for.
 function getAmountOfPlayersFor() public view returns(uint256){
   return playersFor.length;
 }
 // Returns the amount of players that bet against.
 function getAmountOfPlayersAgainst() public view returns(uint256){
   return playersAgainst.length;
 }

 // Returns the array of all players for.
 function getPlayersFor() public view returns(address payable[] memory){
   return playersFor;
 }

 // Returns the array of all amounts players bet for.
 function getPlayersForPayedAmount() public view returns(uint256[] memory){
   return playersForPayedAmount;
 }

 // Returns the array of all players against.
 function getPlayersAgainst() public view returns(address payable[] memory){
   return playersAgainst;
 }

 // Returns the array of all amounts players bet against.
 function getPlayersAgainstPayedAmount() public view returns(uint256[] memory){
   return playersAgainstPayedAmount;
 }

 // Returns the array of all players that won last bet.
 function getRecentWinners() public view returns(address payable[] memory){
   return recentWinners;
 }

 // Returns the array of money payed out to players that won last bet.
 function getRecentWinnersWonAmount() public view returns(uint256[] memory){
   return recentWinnersWonAmount;
 }

// Returns the bet pool in MATIC.
 function getPoolMatic() public view returns(uint256){
   return amountBetFor+amountBetAgainst;//amount in wei
 }

// Returns the bet pool in USD.
 function getPoolUsd() public view returns(uint256){
   uint256 pool = amountBetFor+amountBetAgainst;
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (pool*adjustedPrice)/1e18;
 }

// Returns amount of money bet for in USD.
 function getAmountBetForUsd() public view returns(uint256){
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (amountBetFor*adjustedPrice)/1e18;
 }

// Returns amount of money bet against in USD.
 function getAmountBetAgainstUsd() public view returns(uint256){
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (amountBetAgainst*adjustedPrice)/1e18;
 }

// Emerengency function for the owner to refund all players in case of a malfunction.
 function refundAllPlayers() public onlyOwner{
   for(uint256 i=0;i<playersFor.length;i++){
     playersFor[i].transfer(playersForPayedAmount[i]);
   }
   for(uint256 i=0;i<playersAgainst.length;i++){
     playersAgainst[i].transfer(playersAgainstPayedAmount[i]);
   }
 }

 function getAllData() external view returns(uint256,BETTING_STATE,string memory,string memory,uint256,uint256,uint256,uint256,address payable[] memory,address payable[] memory,address payable[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
   return(durationMinutes,bettingState,name,description,endTime,getMinBet(),getPoolMatic(),getPoolUsd(),getPlayersFor(),getPlayersAgainst(),getRecentWinners(),getRecentWinnersWonAmount(),getPlayersForPayedAmount(),getPlayersAgainstPayedAmount());
 }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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