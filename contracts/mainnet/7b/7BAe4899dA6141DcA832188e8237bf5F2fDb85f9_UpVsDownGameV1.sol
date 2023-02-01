/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/UpVsDownGameV1.sol

pragma solidity >=0.4.22 <0.9.0;

contract UpVsDownGameV1 is Ownable {

  struct BetGroup {
    uint256[] bets;
    address[] addresses;
    string[] avatars;
    string[] countries;
    uint256 total;
    uint256 distributedCount;
    uint256 totalDistributed;
  }

  struct Round {
    bool created;
    int32 startPrice;
    int32 endPrice;
    uint256 minBetAmount;
    uint256 maxBetAmount;
    uint256 poolBetsLimit;
    BetGroup upBetGroup;
    BetGroup downBetGroup;
    int64 roundStartTime;
  }

  struct Distribution {
    uint256 fee;
    uint256 totalMinusFee;
    uint256 pending;
  }

  address public gameController;
  mapping(bytes => Round) public pools;
  uint8 public feePercentage = 5;
  address public feeAddress = msg.sender;
  bool public isRunning;
  bytes public notRunningReason;

  // Errors

  error PendingDistributions();

  // Events

  event RoundStarted(bytes poolId, int64 timestamp, int32 price, uint256 minTradeAmount, uint256 maxTradeAmount, uint256 poolTradesLimit, bytes indexed indexedPoolId);
  event RoundEnded(bytes poolId, int64 timestamp, int32 startPrice, int32 endPrice, bytes indexed indexedPoolId);
  event TradePlaced(bytes poolId, address sender, uint256 amount, string prediction, uint256 newTotal, bytes indexed indexedPoolId, address indexed indexedSender, string avatarUrl, string countryCode, int64 roundStartTime);
  event TradeReturned(bytes poolId, address sender, uint256 amount);
  event GameStopped(bytes reason);
  event GameStarted();
  event RoundDistributed(bytes poolId, uint totalWinners, uint from, uint to, int64 timestamp);
  event TradeWinningsSent(bytes poolId, address sender, uint256 tradeAmount, uint256 winningsAmount, address indexed indexedSender);

  // Modifiers

  modifier onlyGameController () {
    require(msg.sender == gameController, 'Only game controller can do this');
    _;
  }

  modifier onlyOpenPool (bytes calldata poolId) {
    require(isPoolOpen(poolId), 'This pool has a round in progress');
    _;
  }

  modifier onlyGameRunning () {
    require(isRunning, 'The game is not running');
    _;
  }

  modifier onlyPoolExists (bytes calldata poolId) {
    require(pools[poolId].created == true, 'Pool does not exist');
    _;
  }

  constructor(address newGameController) {
    gameController = newGameController;
  }

  // Methods

  function changeGameControllerAddress(address newGameController) public onlyOwner {
    gameController = newGameController;
  }

  function changeGameFeePercentage(uint8 newFeePercentage) public onlyOwner {
    feePercentage = newFeePercentage;
  }

  function changeGameFeeAddress(address newFeeAddress) public onlyOwner {
    feeAddress = newFeeAddress;
  }

  function stopGame(bytes calldata reason) public onlyOwner {
    isRunning = false;
    notRunningReason = reason;
    emit GameStopped(reason);
  }

  function startGame() public onlyOwner {
    isRunning = true;
    notRunningReason = '';
    emit GameStarted();
  }

  function createPool(bytes calldata poolId, uint256 minBetAmount , uint256 maxBetAmount, uint256 poolBetsLimit) public onlyGameController {
    pools[poolId].created = true;
    pools[poolId].minBetAmount = minBetAmount;
    pools[poolId].maxBetAmount = maxBetAmount;
    pools[poolId].poolBetsLimit = poolBetsLimit;
  }

  function trigger(
    bytes calldata poolId,
    int64 timeMS,
    int32 price,
    uint32 batchSize
  ) public onlyGameController onlyPoolExists(poolId) {
    Round storage currentRound = pools[poolId];

    if(isPoolOpen(poolId)) {
      require(isRunning, 'The game is not running, rounds can only be ended at this point');
      currentRound.startPrice = price;
      currentRound.roundStartTime = timeMS;
    
      emit RoundStarted(poolId, timeMS, currentRound.startPrice, currentRound.minBetAmount, currentRound.maxBetAmount, currentRound.poolBetsLimit, poolId);
    } else if (currentRound.endPrice == 0) {
      currentRound.endPrice = price;

      emit RoundEnded(poolId, timeMS, currentRound.startPrice, currentRound.endPrice, poolId);

      distribute(poolId, batchSize, timeMS);
    } else {
      revert PendingDistributions();
    }
  }

  function returnBets (
    bytes calldata poolId,
    BetGroup storage group,
    uint32 batchSize
  ) private {
    uint256 pending = group.bets.length - group.distributedCount;
    uint256 limit = pending > batchSize ? batchSize : pending;
    uint256 to = group.distributedCount + limit;

    for (uint i = group.distributedCount; i < to; i ++) {
      sendEther(group.addresses[i], group.bets[i]);
      emit TradeReturned(poolId, group.addresses[i], group.bets[i]);
    }

    group.distributedCount = to;
  }

  function distribute (
    bytes calldata poolId,
    uint32 batchSize,
    int64 timeMS
  ) public onlyGameController onlyPoolExists(poolId) {
    Round storage round = pools[poolId];

    if (round.upBetGroup.bets.length == 0 || round.downBetGroup.bets.length == 0) {
      BetGroup storage returnGroup = round.downBetGroup.bets.length == 0 ? round.upBetGroup : round.downBetGroup;

      uint fromReturn = returnGroup.distributedCount;
      returnBets(poolId, returnGroup, batchSize);
      emit RoundDistributed(poolId, returnGroup.bets.length, fromReturn, returnGroup.distributedCount,timeMS);

      if (returnGroup.distributedCount == returnGroup.bets.length) {
        clearPool(poolId);
      }
      return;
    }


    BetGroup storage winners = round.downBetGroup;
    BetGroup storage losers = round.upBetGroup;

    if (round.startPrice < round.endPrice) {
      winners = round.upBetGroup;
      losers = round.downBetGroup;
    }

    Distribution memory dist = calculateDistribution(winners, losers);
    uint256 limit = dist.pending > batchSize ? batchSize : dist.pending;
    uint256 to = winners.distributedCount + limit;

    for (uint i = winners.distributedCount; i < to; i++) {
      uint256 winnings = ((winners.bets[i] * 100 / winners.total) * dist.totalMinusFee / 100);
      sendEther(winners.addresses[i], winnings + winners.bets[i]);
      emit TradeWinningsSent(poolId, winners.addresses[i], winners.bets[i], winnings, winners.addresses[i]);
      winners.totalDistributed = winners.totalDistributed + winnings;
    }

    emit RoundDistributed(poolId, winners.bets.length, winners.distributedCount, to, timeMS);

    winners.distributedCount = to;
    if (winners.distributedCount == winners.bets.length) {
      sendEther(feeAddress, dist.fee + dist.totalMinusFee - winners.totalDistributed);
      clearPool(poolId);
    }
  }

  function calculateDistribution (
    BetGroup storage winners,
    BetGroup storage losers
  ) private view returns (Distribution memory) {
    uint256 fee = feePercentage * losers.total / 100;
    uint256 pending = winners.bets.length - winners.distributedCount;
    return Distribution({
      fee: fee,
      totalMinusFee: losers.total - fee,
      pending: pending
    });
  }

  function clearPool (
    bytes calldata poolId
  ) private {
    delete pools[poolId].upBetGroup;
    delete pools[poolId].downBetGroup;
    delete pools[poolId].startPrice;
    delete pools[poolId].endPrice;
  }

  function hasPendingDistributions(
    bytes calldata poolId
  ) public view returns (bool) {
    return (pools[poolId].upBetGroup.bets.length + pools[poolId].downBetGroup.bets.length) > 0;
  }

  function isPoolOpen(
    bytes calldata poolId
  ) public view returns (bool) {
    return pools[poolId].startPrice == 0;
  }

  function addBet (
    BetGroup storage betGroup,
    uint256 amount,
    string calldata avatar,
    string calldata countryCode
  ) private returns (uint256) {
    betGroup.bets.push(amount);
    betGroup.addresses.push(msg.sender);
    betGroup.avatars.push(avatar);
    betGroup.countries.push(countryCode);
    betGroup.total += amount;
    return betGroup.total;
  }

  struct makeTradeStruct{
    bytes poolId;
    string avatarUrl;
    string countryCode;
    bool upOrDown;
  }

  function makeTrade(
    makeTradeStruct calldata userTrade
  ) public payable onlyOpenPool(userTrade.poolId) onlyGameRunning onlyPoolExists(userTrade.poolId) {
    require(msg.value > 0, "Needs to send Matic to trade");
    require(msg.value >= pools[userTrade.poolId].minBetAmount, "Trade amount should be higher than the minimum");
    require(msg.value <= pools[userTrade.poolId].maxBetAmount, "Trade amount should be lower than the maximum");
    uint256 newTotal;

    if (userTrade.upOrDown) {
      require(pools[userTrade.poolId].upBetGroup.bets.length <= pools[userTrade.poolId].poolBetsLimit-1,"Pool is full, wait for next round");
      newTotal = addBet(pools[userTrade.poolId].upBetGroup, msg.value, userTrade.avatarUrl, userTrade.countryCode);
    } else {
      require(pools[userTrade.poolId].downBetGroup.bets.length <= pools[userTrade.poolId].poolBetsLimit-1,"Pool is full, wait for next round");
      newTotal = addBet(pools[userTrade.poolId].downBetGroup, msg.value, userTrade.avatarUrl, userTrade.countryCode);
    }

    string memory avatar;
    {
      avatar = userTrade.avatarUrl;
    }

    string memory countryCode;
    {
      countryCode = userTrade.countryCode;
    }

    int64 roundStartTime;
    {
      roundStartTime = pools[userTrade.poolId].roundStartTime;
    }

    emit TradePlaced(userTrade.poolId, msg.sender, msg.value, (userTrade.upOrDown) ? "UP":"DOWN", newTotal, userTrade.poolId, msg.sender, avatar, countryCode, roundStartTime);
  }

  function sendEther (
    address to, 
    uint256 amount
  ) private {
    (bool sent, bytes memory data) = payable(to).call{gas: 0, value: amount}("");
    require(sent, "Couldn't send ether");
  } 
}