// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "AggregatorV3Interface.sol";
import "Ownable.sol";

contract SportsBetsV1 is Ownable{
  // Address of the owner
  address payable ownerAddress;
  // Start taking bets time.
  uint256 public startTime;
  // Start of the match time.
  uint256 public matchStart;
  // Start of the match time.
  uint256 public matchEnd;
  // Contestants:
  string public team1;
  string public team2;
  // Bet name.
  string public name;
  // Bet description.
  string public description;
  // Array of all players betting on team 1.
  address payable[] public playersBetOnTeam1;
  // Amounts payed by each player.
  uint256[] public playersBetOnTeam1PayedAmount;
  // Total amount bet on team 1.
  uint256 public amountBetOnTeam1;
  // Array of all players betting against.
  address payable[] public playersBetOnTeam2;
  // Amounts payed by each player.
  uint256[] public playersBetOnTeam2PayedAmount;
  // Total amount bet against.
  uint256 public amountBetOnTeam2;
  // Array of all players betting on draw.
  address payable[] public playersBetOnDraw;
  // Amounts payed by each player.
  uint256[] public playersBetOnDrawPayedAmount;
  // Total amount bet on draw.
  uint256 public amountBetOnDraw;
  // Array of all players who won previous bet.
  address payable[] public recentWinners;
  // Array of money payed to players who won previous bet.
  uint256[] public recentWinnersWonAmount;
  // Minimum bet amount.
  uint256 public minimumBet = 1e17;//0.1 MATIC
  // Chainlink exchange rate provider MATIC/USD.
  AggregatorV3Interface internal maticUsdPriceFeed;
  // Possible bet states.
  enum BETTING_STATE {TAKING_BETS,CLOSED,WAITING_FOR_RESULTS}// respectively 0,1,2
  // Contract state (0/1/2)
  BETTING_STATE public bettingState;

  constructor(
    address _maticPriceFeedAddress// Chainlink matic price feed address on current blockchain.
    ){
    ownerAddress = payable(msg.sender);
    maticUsdPriceFeed = AggregatorV3Interface(_maticPriceFeedAddress);
    bettingState = BETTING_STATE.CLOSED;
  }

  // Function called by the owner to start a new betting round.
  function startTakingBets(string memory _name,string memory _description,uint256 _matchStart,uint256 _matchEnd) external onlyOwner {
    require(bettingState == BETTING_STATE.CLOSED, "Cant start a new betting yet!");// Check if previous round has finished.
    bettingState = BETTING_STATE.TAKING_BETS;
    name = _name;
    description = _description;
    matchStart = _matchStart;
    matchEnd = _matchEnd;
    startTime = block.timestamp;
  }

  // Returns minimum bet amount in USD according to chainlink price feed.
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
  function betOnTeam1() external payable{
    require(bettingState == BETTING_STATE.TAKING_BETS,"Not taking bets rn!");// Only allow to enter if the betting has begun.
    require(block.timestamp < matchStart,"Not taking bets anymore! Waiting for the match to end.");//Stop taking bets when the match begins.
    require(msg.value >= minimumBet, "Not enough MATIC! Run getMinBet() to get a minimum bet amount.");
    playersBetOnTeam1.push(payable(msg.sender));// Add player to the array.
    playersBetOnTeam1PayedAmount.push(msg.value);// Remember how much they bet.
    amountBetOnTeam1 += msg.value;// Add amount to total(makes payout easier).
  }

  function betOnTeam2() external payable{
    require(bettingState == BETTING_STATE.TAKING_BETS,"Not taking bets rn!");// Only allow to enter if the betting has begun.
    require(block.timestamp < matchStart,"Not taking bets anymore! Waiting for the match to end.");//Stop taking bets when the match begins.
    require(msg.value >= minimumBet, "Not enough MATIC! Run getMinBet() to get a minimum bet amount.");
    playersBetOnTeam2.push(payable(msg.sender));// Add player to the array.
    playersBetOnTeam2PayedAmount.push(msg.value);// Remember how much they bet.
    amountBetOnTeam2 += msg.value;// Add amount to total(makes payout easier).
  }

  function betOnDraw() external payable{
    require(bettingState == BETTING_STATE.TAKING_BETS,"Not taking bets rn!");// Only allow to enter if the betting has begun.
    require(block.timestamp < matchStart,"Not taking bets anymore! Waiting for the match to end.");//Stop taking bets when the match begins.
    require(msg.value >= minimumBet, "Not enough MATIC! Run getMinBet() to get a minimum bet amount.");
    playersBetOnDraw.push(payable(msg.sender));// Add player to the array.
    playersBetOnDrawPayedAmount.push(msg.value);// Remember how much they bet.
    amountBetOnDraw += msg.value;// Add amount to total(makes payout easier).
  }

  // Function executed by the server automatically after
  // a set amount of time has passed.
  // Takes score as arguments and pays players accordingly.
  // Sets matchStart and matchEnd to 0 and resets arrays and variables.
  function concludeBetting(uint256 team1Score, uint256 team2Score) external onlyOwner {
    require(block.timestamp >= matchEnd,"Betting can not conclude until the match is over and results are known, run .matchEnd() to check when it can be ended.");// Make sure it is supposed to end now.
    bettingState = BETTING_STATE.CLOSED;
    uint256 pool = amountBetOnTeam1+amountBetOnTeam2+amountBetOnDraw;
    recentWinnersWonAmount = new uint256[](0);
    if(team1Score>team2Score){
      if(playersBetOnTeam1.length!=0 && amountBetOnTeam1>0){
        recentWinners = playersBetOnTeam1;
        for(uint256 i=0;i<playersBetOnTeam1.length;i++){
          recentWinnersWonAmount.push(((pool*((playersBetOnTeam1PayedAmount[i]*1e18)/amountBetOnTeam1))/1e20)*95);// minus 5% commision(used mainly for paying gas for transfering rewards to winners).
          playersBetOnTeam1[i].transfer(recentWinnersWonAmount[i]);
        }
      }
    }else{
      if(team1Score<team2Score){
        if(playersBetOnTeam2.length!=0 && amountBetOnTeam2>0){
          recentWinners = playersBetOnTeam2;
          for(uint256 i=0;i<playersBetOnTeam2.length;i++){
            recentWinnersWonAmount.push(((pool*((playersBetOnTeam2PayedAmount[i]*1e18)/amountBetOnTeam2))/1e20)*95);// minus 5% commision(used mainly for paying gas for transfering rewards to winners).
            playersBetOnTeam2[i].transfer(recentWinnersWonAmount[i]);
          }
        }
      }else{
        require(team1Score==team2Score, "Its not a draw! teamScore parameters invalid!");
        if(playersBetOnTeam2.length!=0 && amountBetOnTeam2>0){
          recentWinners = playersBetOnDraw;
          for(uint256 i=0;i<playersBetOnDraw.length;i++){
            recentWinnersWonAmount.push(((pool*((playersBetOnDrawPayedAmount[i]*1e18)/amountBetOnDraw))/1e20)*95);// minus 5% commision(used mainly for paying gas for transfering rewards to winners).
            playersBetOnDraw[i].transfer(recentWinnersWonAmount[i]);
          }
        }
      }
    }
    ownerAddress.transfer(address(this).balance);
    matchStart = 0;
    matchEnd = 0;
    playersBetOnTeam1 = new address payable[](0);
    playersBetOnTeam2 = new address payable[](0);
    playersBetOnDraw = new address payable[](0);
    playersBetOnTeam1PayedAmount = new uint256[](0);
    playersBetOnTeam2PayedAmount = new uint256[](0);
    playersBetOnDrawPayedAmount = new uint256[](0);
    amountBetOnTeam1 = 0;
    amountBetOnTeam2 = 0;
    amountBetOnDraw = 0;
  }

 // Returns the amount of players that bet for team1.
 function getAmountOfPlayersBetOnTeam1() public view returns(uint256){
   return playersBetOnTeam1.length;
 }

 // Returns the amount of players that bet on team2.
 function getAmountOfPlayersBetOnTeam2() public view returns(uint256){
   return playersBetOnTeam2.length;
 }

 // Returns the amount of players that bet on draw.
 function getAmountOfPlayersBetOnDraw() public view returns(uint256){
   return playersBetOnDraw.length;
 }

 // Returns the array of all players that bet for team 1.
 function getPlayersBetOnTeam1() public view returns(address payable[] memory){
   return playersBetOnTeam1;
 }

 // Returns the array of all amounts players that bet for team 1.
 function getPlayersBetOnTeam1PayedAmount() public view returns(uint256[] memory){
   return playersBetOnTeam1PayedAmount;
 }

 // Returns the array of all players that bet for team 2.
 function getPlayersBetOnTeam2() public view returns(address payable[] memory){
   return playersBetOnTeam2;
 }

 // Returns the array of all amounts players that bet for team 2.
 function getPlayersBetOnTeam2PayedAmount() public view returns(uint256[] memory){
   return playersBetOnTeam2PayedAmount;
 }

 // Returns the array of all players that bet for team 2.
 function getPlayersBetOnDraw() public view returns(address payable[] memory){
   return playersBetOnDraw;
 }

 // Returns the array of all amounts players that bet for team 2.
 function getPlayersBetOnDrawPayedAmount() public view returns(uint256[] memory){
   return playersBetOnDrawPayedAmount;
 }

 // Returns the array of all players that won the last bet.
 function getRecentWinners() public view returns(address payable[] memory){
   return recentWinners;
 }

 // Returns the array of money payed out to players that won the last bet.
 function getRecentWinnersWonAmount() public view returns(uint256[] memory){
   return recentWinnersWonAmount;
 }

// Returns the bet pool in MATIC.
 function getPoolMatic() public view returns(uint256){
   return amountBetOnTeam1+amountBetOnTeam2+amountBetOnDraw;//amount in wei
 }

// Returns the bet pool in USD.
 function getPoolUsd() public view returns(uint256){
   uint256 pool = amountBetOnTeam1+amountBetOnTeam2+amountBetOnDraw;
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (pool*adjustedPrice)/1e18;
 }

// Returns amount of money bet on team 1 in USD.
 function getAmountBetOnTeam1Usd() public view returns(uint256){
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (amountBetOnTeam1*adjustedPrice)/1e18;
 }

// Returns amount of money bet on team 2 in USD.
 function getAmountBetOnTeam2Usd() public view returns(uint256){
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (amountBetOnTeam2*adjustedPrice)/1e18;
 }

 // Returns amount of money bet on team 2 in USD.
  function getAmountBetOnDrawUsd() public view returns(uint256){
    (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
    uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
    return (amountBetOnDraw*adjustedPrice)/1e18;
  }

// Emerengency function for the owner to refund all players in case of malfunction.
 function refundAllPlayers() external onlyOwner{
   for(uint256 i=0;i<playersBetOnTeam1.length;i++){
     playersBetOnTeam1[i].transfer(playersBetOnTeam1PayedAmount[i]);
   }
   for(uint256 i=0;i<playersBetOnTeam2.length;i++){
     playersBetOnTeam2[i].transfer(playersBetOnTeam2PayedAmount[i]);
   }
   for(uint256 i=0;i<playersBetOnTeam2.length;i++){
     playersBetOnDraw[i].transfer(playersBetOnDrawPayedAmount[i]);
   }
 }

 // Data aggregators for quicker website loading.
 function getBetInfo() external view returns(BETTING_STATE,string memory,string memory,uint256,uint256,uint256,uint256,uint256){
   return(bettingState,name,description,matchStart,matchEnd,getMinBet(),getPoolMatic(),getPoolUsd());
 }
 function getPlayerInfo() external view returns(address payable[] memory,address payable[] memory,address payable[] memory,address payable[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
   return(getPlayersBetOnTeam1(),getPlayersBetOnTeam2(),getPlayersBetOnDraw(),getRecentWinners(),getRecentWinnersWonAmount(),getPlayersBetOnTeam1PayedAmount(),getPlayersBetOnTeam2PayedAmount(),getPlayersBetOnDrawPayedAmount());
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