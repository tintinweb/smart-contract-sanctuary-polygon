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

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20.sol";

contract Authorized is Ownable {
  uint internal constant decimals = 1e18; // ? PROD
  uint internal constant timeRate = 1; // ? PROD

  // uint internal constant decimals = 1e12;  // ? TESTNET
  // uint internal constant timeRate = 720;  // ? TESTNET
  
  mapping(uint8 => mapping(address => bool)) internal permissions;

  constructor() {
    permissions[0][_msgSender()] = true; // admin
    permissions[1][_msgSender()] = true; // controller
  }

  modifier isAuthorized(uint8 index) {
    require(permissions[index][_msgSender()] == true, "Account does not have permission");
    _;
  }

  function grantPermission(address operator, uint8 typed) external isAuthorized(0) {
    permissions[typed][operator] = true;
  }

  function revokePermission(address operator, uint8 typed) external isAuthorized(0) {
    permissions[typed][operator] = false;
  }

  /**
   * Method to able remove accidental Token deposits
   * ! THIS METHOD DOES NOT WITHDRAW MATIC FROM CONTRACT ONLY ERC20 TOKENS
   */
  function safeTransfer(
    address desiredToken,
    address receiver,
    uint amount
  ) external isAuthorized(0) {
    if (receiver == address(0)) receiver = _msgSender();
    IERC20(desiredToken).transfer(receiver, amount);
  }
}

// SPDX-License-Identifier: PROPRIETARY

pragma solidity 0.8.17;

import "./Authorized.sol";

contract ContractData is Authorized {
  string public constant name = "SmartVision";
  string public constant url = "www.smartvision.cash";

  struct AccountInfo {
    address up;
    uint unlockedLevel;
    bool registered;
    uint depositTime;
    uint lastWithdraw;
    uint depositMin;
    uint depositTotal;
    uint depositCounter;
    uint lastInteraction;
    uint extraPassive;
  }
  struct AccountEarnings {
    uint receivedPassiveAmount;
    uint receivedTotalAmount;
    uint directBonusAmount;
    uint directBonusAmountTotal;
    uint levelBonusAmount;
    uint levelBonusAmountTotal;
  }

  struct MoneyFlow {
    uint passive;
    uint direct;
    uint bonus;
  }

  struct NetworkCheck {
    uint count;
    uint deposits;
    uint depositTotal;
    uint depositCounter;
  }

  mapping(address => AccountInfo) public accountsInfo;
  mapping(address => AccountEarnings) public accountsEarnings;
  mapping(address => address[]) public accountsRefs;
  mapping(address => uint[]) public accountsFlow;

  mapping(address => address[]) public accountsShared;
  mapping(address => address[]) public accountsInShare;

  uint16[] _passiveBonusLevel = new uint16[](30);

  uint public minAllowedDeposit = 30 * decimals;
  uint public maxAmount = 2000 * decimals;

  uint public constant timeFrame = 1 days / timeRate;

  uint public constant dailyRentability = 10; //1% daily
  uint public constant dailyRentabilityPlus = 15; //1.5% daily
  uint public constant taskRentability = 5; //0.5% daily
  uint public constant directBonus = 100; // 10% direct bonus

  uint public constant networkInPercent = 20;
  uint public constant networkOutPercent = 50;

  uint public constant maxPercentToWithdraw = 200;
  uint public constant maxPercentToReceive = 200;

  uint public networkSize;
  uint public networkDeposits;
  uint public networkWithdraw;

  address networkReceiverA;
  address networkReceiverB;

  uint cumulativeNetworkFee;
  uint composeDeposit;

  address constant mainNode = 0x777c8988eFa69B8465EB561D1f7Fd0a83Ed45555;
  address ownerNode;

  constructor() {
    _passiveBonusLevel[0] = 50;
    _passiveBonusLevel[1] = 40;
    _passiveBonusLevel[2] = 40;
    _passiveBonusLevel[3] = 30;
    _passiveBonusLevel[4] = 30;
    _passiveBonusLevel[5] = 30;
    _passiveBonusLevel[6] = 20;
    _passiveBonusLevel[7] = 20;
    _passiveBonusLevel[8] = 20;
    _passiveBonusLevel[9] = 20;
    _passiveBonusLevel[10] = 10;
    _passiveBonusLevel[11] = 10;
    _passiveBonusLevel[12] = 10;
    _passiveBonusLevel[13] = 10;
    _passiveBonusLevel[14] = 10;
    _passiveBonusLevel[15] = 10;
    _passiveBonusLevel[16] = 10;
    _passiveBonusLevel[17] = 10;
    _passiveBonusLevel[18] = 10;
    _passiveBonusLevel[19] = 10;
    _passiveBonusLevel[20] = 10;
    _passiveBonusLevel[21] = 10;
    _passiveBonusLevel[22] = 10;
    _passiveBonusLevel[23] = 10;
    _passiveBonusLevel[24] = 10;
    _passiveBonusLevel[25] = 10;
    _passiveBonusLevel[26] = 10;
    _passiveBonusLevel[27] = 10;
    _passiveBonusLevel[28] = 10;
    _passiveBonusLevel[29] = 10;
  }

  event WithdrawLimitReached(address indexed addr, uint amount);
  event Withdraw(address indexed addr, uint amount);
  event NewDeposit(address indexed addr, uint amount);
  event NewUpgrade(address indexed addr, uint amount);
  event DirectBonus(address indexed addr, address indexed from, uint amount);
  event LevelBonus(address indexed addr, address indexed from, uint amount);
  event ReferralRegistration(address indexed addr, address indexed referral);
  event NewDonationDeposit(address indexed addr, uint amount);

  function setMinAllowedDeposit(uint minValue) external isAuthorized(1) {
    minAllowedDeposit = minValue;
  }

  function updateMaxAmount(uint _maxAmount) external isAuthorized(1) {
    maxAmount = _maxAmount;
  }

  function setNetworkReceiverA(address receiver) external isAuthorized(0) {
    networkReceiverA = receiver;
  }

  function setNetworkReceiverB(address receiver) external isAuthorized(0) {
    networkReceiverB = receiver;
  }

  function buildOperation(uint8 opType, uint value) internal view returns (uint res) {
    assembly {
      let entry := mload(0x40)
      mstore(entry, add(shl(200, opType), add(add(shl(160, timestamp()), shl(120, number())), value)))
      res := mload(entry)
    }
  }

  function getContractData() external view returns (uint balance, uint netSize) {
    balance = address(this).balance;
    netSize = networkSize;
  }

  function getShares(address target) external view returns (address[] memory shared, address[] memory inShare) {
    shared = accountsShared[target];
    inShare = accountsInShare[target];
  }

  function getFlow(address target, uint limit, bool asc) external view returns (uint[] memory flow) {
    uint[] memory list = accountsFlow[target];
    if (limit == 0) limit = list.length;
    if (limit > list.length) limit = list.length;
    flow = new uint[](limit);
    if (asc) {
      for (uint i = 0; i < limit; i++) flow[i] = list[i];
    } else {
      for (uint i = 0; i < limit; i++) flow[i] = list[(limit - 1) - i];
    }
  }

  function calculatePassive(uint depositTime, uint depositMin, uint receivedTotalAmount, uint receivedPassiveAmount, uint extraPassive, address sender) public view returns (uint) {
    if (depositTime == 0 || depositMin == 0) return 0;
    uint passive = extraPassive + ((((depositMin * getDailyRentability(sender)) / 1000) * (block.timestamp - depositTime)) / timeFrame) - receivedPassiveAmount;
    uint remainingAllowed = ((depositMin * maxPercentToReceive) / 100) - receivedTotalAmount; // MAX TO RECEIVE
    return passive >= remainingAllowed ? remainingAllowed : passive;
  }


  function getDailyRentability(address target) public view returns (uint) {
    return accountsInfo[target].unlockedLevel == 30 ? dailyRentabilityPlus : dailyRentability;
  }


  function getAccountNetwork(address sender, uint minLevel, uint maxLevel) public view returns (NetworkCheck[] memory) {
    maxLevel = maxLevel > _passiveBonusLevel.length || maxLevel == 0 ? _passiveBonusLevel.length : maxLevel;
    NetworkCheck[] memory network = new NetworkCheck[](maxLevel);
    for (uint i = 0; i < accountsRefs[sender].length; i++) {
      _getAccountNetworkInner(accountsRefs[sender][i], 0, minLevel, maxLevel, network);
    }
    return network;
  }

  function _getAccountNetworkInner(address sender, uint level, uint minLevel, uint maxLevel, NetworkCheck[] memory network) internal view {
    if (level >= minLevel) {
      network[level].count += 1;
      network[level].deposits += accountsInfo[sender].depositMin;
      network[level].depositCounter += accountsInfo[sender].depositCounter;
      network[level].depositTotal += accountsInfo[sender].depositTotal;
    }
    if (level + 1 >= maxLevel) return;
    for (uint i = 0; i < accountsRefs[sender].length; i++) {
      _getAccountNetworkInner(accountsRefs[sender][i], level + 1, minLevel, maxLevel, network);
    }
  }

  function getMultiAccountNetwork(address[] memory senders, uint minLevel, uint maxLevel) external view returns (NetworkCheck[] memory network) {
    for (uint x = 0; x < senders.length; x++) {
      NetworkCheck[] memory partialNetwork = getAccountNetwork(senders[x], minLevel, maxLevel);
      for (uint i = 0; i < maxLevel; i++) {
        network[i].count += partialNetwork[i].count;
        network[i].deposits += partialNetwork[i].deposits;
        network[i].depositTotal += partialNetwork[i].depositTotal;
        network[i].depositCounter += partialNetwork[i].depositCounter;
      }
    }
  }

  function getMultiLevelAccount(address[] memory senders, uint currentLevel, uint maxLevel) public view returns (bytes memory results) {
    for (uint x = 0; x < senders.length; x++) {
      if (currentLevel == maxLevel) {
        for (uint i = 0; i < accountsRefs[senders[x]].length; i++) {
          results = abi.encodePacked(results, accountsRefs[senders[x]][i]);
        }
      } else {
        results = abi.encodePacked(results, getMultiLevelAccount(accountsRefs[senders[x]], currentLevel + 1, maxLevel));
      }
    }
  }

  function getAccountEarnings(
    address sender
  )
    external
    view
    returns (
      AccountInfo memory accountI,
      AccountEarnings memory accountE,
      MoneyFlow memory total,
      MoneyFlow memory toWithdraw,
      MoneyFlow memory toMaxEarning,
      MoneyFlow memory toReceiveOverMax,
      uint directs,
      uint time
    )
  {
    accountI = accountsInfo[sender];
    accountE = accountsEarnings[sender];

    address localSender = sender;
    uint depositMin = accountsInfo[localSender].depositMin;
    uint directBonusAmount = accountsEarnings[localSender].directBonusAmount;
    uint levelBonusAmount = accountsEarnings[localSender].levelBonusAmount;
    uint receivedTotalAmount = accountsEarnings[localSender].receivedTotalAmount;
    uint passive = calculatePassive(accountsInfo[localSender].depositTime, depositMin, receivedTotalAmount, accountsEarnings[localSender].receivedPassiveAmount, accountsInfo[localSender].extraPassive, localSender);
    total = MoneyFlow(passive, directBonusAmount, levelBonusAmount);

    if (localSender == mainNode || localSender == ownerNode) depositMin = type(uint).max / 1e5;

    uint remainingWithdraw = ((depositMin * maxPercentToWithdraw) / 100) - receivedTotalAmount; // MAX WITHDRAW
    uint toRegisterPassive = passive >= remainingWithdraw ? remainingWithdraw : passive;
    remainingWithdraw = remainingWithdraw - toRegisterPassive;
    uint toRegisterDirect = directBonusAmount >= remainingWithdraw ? remainingWithdraw : directBonusAmount;
    remainingWithdraw = remainingWithdraw - toRegisterDirect;
    uint toRegisterBonus = levelBonusAmount >= remainingWithdraw ? remainingWithdraw : levelBonusAmount;

    passive -= toRegisterPassive;
    directBonusAmount -= toRegisterDirect;
    levelBonusAmount -= toRegisterBonus;

    toWithdraw = MoneyFlow(toRegisterPassive, toRegisterDirect, toRegisterBonus);

    remainingWithdraw = ((depositMin * maxPercentToReceive) / 100) - (receivedTotalAmount + toRegisterPassive + toRegisterDirect + toRegisterBonus); // MAX TO RECEIVE
    toRegisterPassive = passive >= remainingWithdraw ? remainingWithdraw : passive;
    remainingWithdraw = remainingWithdraw - toRegisterPassive;
    toRegisterDirect = directBonusAmount >= remainingWithdraw ? remainingWithdraw : directBonusAmount;
    remainingWithdraw = remainingWithdraw - toRegisterDirect;
    toRegisterBonus = levelBonusAmount >= remainingWithdraw ? remainingWithdraw : levelBonusAmount;

    passive -= toRegisterPassive;
    directBonusAmount -= toRegisterDirect;
    levelBonusAmount -= toRegisterBonus;
    toMaxEarning = MoneyFlow(toRegisterPassive, toRegisterDirect, toRegisterBonus);
    toReceiveOverMax = MoneyFlow(passive, directBonusAmount, levelBonusAmount);
    directs = accountsRefs[localSender].length;
    time = block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
  function balanceOf(address account) external view returns (uint);

  function transfer(address to, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function transferFrom(
    address from,
    address to,
    uint amount
  ) external returns (bool);
}

// SPDX-License-Identifier: PROPRIETARY
// https://www.smart-vision.com/

pragma solidity 0.8.17;

import "./ContractData.sol";

contract SmartVision is ContractData {
  constructor() {
    ownerNode = owner();
    accountsInfo[ownerNode].unlockedLevel = 30;
    accountsInfo[ownerNode].registered = true;
    accountsInfo[mainNode].up = ownerNode;
    accountsInfo[mainNode].unlockedLevel = 30;
    accountsInfo[mainNode].registered = true;
    accountsRefs[ownerNode].push(mainNode);
    emit ReferralRegistration(mainNode, ownerNode);

    networkSize += 2;
  }

  // ! --------------------- PUBLIC METHODS ---------------------------
  receive() external payable {
    makeDeposit();
  }

  function marketingPumpUp() external {}

  function registerAccount(address ref) external payable {
    address sender = msg.sender;
    require(sender != ref && accountsInfo[sender].up == address(0) && accountsInfo[ref].registered == true, "Invalid Referral");
    require(msg.value > 0, "Invalid amount");

    accountsInfo[sender].up = ref;
    accountsInfo[sender].registered = true;
    accountsRefs[ref].push(sender);
    emit ReferralRegistration(sender, ref);
    accountsFlow[ref].push(buildOperation(1, accountsRefs[ref].length));

    networkSize += 1;
    _registerDeposit(sender, msg.value);
    _payCumulativeFee();
  }

  function addShareWallet(address toBeShared) external {
    address target = msg.sender;
    require(accountsInfo[target].registered == true, "Account not registered on platform");
    require(toBeShared != address(0) && toBeShared != target, "Invalid account to be shared");

    address[] memory shared = accountsShared[target];
    require(shared.length < 9, "Max shared accounts reached");
    for (uint i = 0; i < shared.length; i++) {
      if (shared[i] == toBeShared) revert("Already been shared with this wallet");
    }

    accountsShared[target].push(toBeShared);
    accountsInShare[toBeShared].push(target);
  }

  function makeDeposit() public payable {
    _registerDeposit(msg.sender, msg.value);
    _payCumulativeFee();
  }

  function withdrawAndDeposit(uint amount) public payable {
    require(amount >= 0, "Invalid amount");
    composeDeposit = amount;
    _withdraw(0);
    _registerDeposit(msg.sender, msg.value + composeDeposit);
    _payCumulativeFee();
    composeDeposit = 0;
  }

  function directBonusDeposit(address receiver) public payable isAuthorized(1) {
    uint amount = msg.value;
    require(amount > 0, "Invalid amount");
    require(accountsInfo[receiver].registered == true, "Invalid receiver");

    address directBonusReceiver = receiver;
    accountsEarnings[directBonusReceiver].directBonusAmount += amount; // DIRECT EXTERNAL BONUS
    accountsEarnings[directBonusReceiver].directBonusAmountTotal += amount;

    emit DirectBonus(directBonusReceiver, msg.sender, amount);

    networkDeposits += amount;

    _payNetworkFee(amount, true, 0);
    _payCumulativeFee();
  }

  function makeDonation() public payable {
    uint amount = msg.value;
    address sender = msg.sender;
    require(amount > 0, "Invalid amount");

    emit NewDonationDeposit(sender, amount);
    accountsFlow[sender].push(buildOperation(2, amount));

    networkDeposits += amount;

    _payNetworkFee(amount, true, 0);
    _payCumulativeFee();
  }

  function withdraw() external {
    _withdraw(0);
    _payCumulativeFee();
  }

  function withdrawPartial(uint amount) external {
    require(amount > 0, "Invalid amount");
    _withdraw(amount);
    _payCumulativeFee();
  }

  function executeTask() public {
    uint depositMin = accountsInfo[msg.sender].depositMin;
    require(depositMin > 0, "invalid account operation");

    uint lastInteraction = accountsInfo[msg.sender].lastInteraction;
    if (lastInteraction == 0) lastInteraction = block.timestamp;

    uint timeToCount = block.timestamp - lastInteraction;
    if (timeToCount > timeFrame) timeToCount = timeFrame;

    if (depositMin > 0) {
      accountsInfo[msg.sender].extraPassive += (((depositMin * taskRentability) / 1000) * (timeToCount)) / timeFrame;
    }

    accountsInfo[msg.sender].lastInteraction = block.timestamp;
  }

  // ! --------------------- PRIVATE METHODS ---------------------------

  function _withdraw(uint amount) private {
    address sender = msg.sender;

    uint depositMin = accountsInfo[sender].depositMin;
    uint receivedTotalAmount = accountsEarnings[sender].receivedTotalAmount;

    uint depositTime = accountsInfo[sender].depositTime;
    uint extraPassive = accountsInfo[sender].extraPassive;
    uint receivedPassiveAmount = accountsEarnings[sender].receivedPassiveAmount;
    uint directBonusAmount = accountsEarnings[sender].directBonusAmount;
    uint levelBonusAmount = accountsEarnings[sender].levelBonusAmount;

    uint passive = calculatePassive(depositTime, depositMin, receivedTotalAmount, receivedPassiveAmount, extraPassive, sender);

    uint remainingWithdraw = ((depositMin * maxPercentToWithdraw) / 100) - receivedTotalAmount; // MAX WITHDRAW
    uint withdrawAmount = remainingWithdraw;

    require(withdrawAmount > 0, "No remaining withdraws");

    if (amount > 0) {
      require(amount <= remainingWithdraw, "Amount exceed remaining amount to be withdrawn");
      withdrawAmount = amount;
    } else if (directBonusAmount + levelBonusAmount + passive < remainingWithdraw) {
      if (composeDeposit > 0) {
        withdrawAmount = composeDeposit;
      }
    }
    _withdrawCalculations(sender, withdrawAmount, passive, directBonusAmount, levelBonusAmount, receivedTotalAmount, remainingWithdraw);
  }

  function _withdrawCalculations(
    address sender,
    uint withdrawAmount,
    uint passive,
    uint directBonusAmount,
    uint levelBonusAmount,
    uint receivedTotalAmount,
    uint remainingWithdraw
  ) private {
    uint toWithdrawPassive = passive >= withdrawAmount ? withdrawAmount : passive;

    if (directBonusAmount > withdrawAmount - toWithdrawPassive) directBonusAmount = withdrawAmount - toWithdrawPassive;
    if (levelBonusAmount > withdrawAmount - (toWithdrawPassive + directBonusAmount)) levelBonusAmount = withdrawAmount - (toWithdrawPassive + directBonusAmount);

    uint totalToWithdraw = toWithdrawPassive + directBonusAmount + levelBonusAmount;

    if (directBonusAmount > 0) accountsEarnings[sender].directBonusAmount -= directBonusAmount;
    if (levelBonusAmount > 0) accountsEarnings[sender].levelBonusAmount -= levelBonusAmount;

    accountsEarnings[sender].receivedPassiveAmount += toWithdrawPassive;
    accountsEarnings[sender].receivedTotalAmount += totalToWithdraw;

    uint withdrawFeeMultiplier = 3;
    {
      uint lastWithdraw = accountsInfo[sender].lastWithdraw;

      uint lastWithdraw2 = lastWithdraw / 1e15;
      lastWithdraw = lastWithdraw % 1e15;

      if (timeFrame > block.timestamp - lastWithdraw && timeFrame > block.timestamp - lastWithdraw2) {
        withdrawFeeMultiplier = 3;
      } else if (timeFrame > block.timestamp - lastWithdraw || timeFrame > block.timestamp - lastWithdraw2) {
        withdrawFeeMultiplier = 2;
      } else {
        withdrawFeeMultiplier = 1;
      }

      uint maxWithdraw = passive + directBonusAmount + levelBonusAmount;
      if (maxWithdraw >= remainingWithdraw || composeDeposit >= totalToWithdraw) {
        withdrawFeeMultiplier = 1;
      } else {
        if (timeFrame <= block.timestamp - lastWithdraw) {
          accountsInfo[sender].lastWithdraw = lastWithdraw2 * 1e15 + block.timestamp;
        } else {
          accountsInfo[sender].lastWithdraw = block.timestamp * 1e15 + lastWithdraw;
        }
      }
      require(withdrawFeeMultiplier <= 2, "Only 2 withdraws each 24h are possible");
    }

    if (totalToWithdraw >= remainingWithdraw) {
      emit WithdrawLimitReached(sender, receivedTotalAmount + totalToWithdraw);
    }

    uint feeAmount = _payNetworkFee(totalToWithdraw, false, withdrawFeeMultiplier);
    networkWithdraw += totalToWithdraw;

    _distributeLevelBonus(sender, toWithdrawPassive);

    emit Withdraw(sender, totalToWithdraw);
    accountsFlow[sender].push(buildOperation(3, totalToWithdraw));

    uint totalToPay = totalToWithdraw - feeAmount;
    if (composeDeposit > 0) {
      if (totalToPay >= composeDeposit) {
        totalToPay -= composeDeposit;
      } else {
        composeDeposit = totalToPay;
        totalToPay = 0;
      }
    }
    if (totalToPay > 0) _payWithdrawAmount(totalToPay);
  }

  function _payWithdrawAmount(uint totalToWithdraw) private {
    address sender = msg.sender;
    uint shareCount = accountsShared[sender].length;
    if (shareCount == 0) {
      payable(sender).transfer(totalToWithdraw);
      return;
    }
    uint partialPayment = totalToWithdraw / (shareCount + 1);
    payable(sender).transfer(partialPayment);

    for (uint i = 0; i < shareCount; i++) {
      payable(accountsShared[sender][i]).transfer(partialPayment);
    }
  }

  function _distributeLevelBonus(address sender, uint amount) private {
    address up = accountsInfo[sender].up;
    address contractOwner = ownerNode;
    address contractMainNome = mainNode;
    for (uint8 i = 0; i < _passiveBonusLevel.length; i++) {
      if (up == address(0)) break;

      uint currentUnlockedLevel = accountsInfo[up].unlockedLevel;

      if (currentUnlockedLevel > i || up == contractMainNome || up == contractOwner) {
        uint bonus = (amount * _passiveBonusLevel[i]) / 1000;
        accountsEarnings[up].levelBonusAmount += bonus;
        accountsEarnings[up].levelBonusAmountTotal += bonus;
        emit LevelBonus(up, sender, bonus);
      }
      up = accountsInfo[up].up;
    }
  }

  function _registerDailyEarnUpgrade(address referral) private {
    accountsInfo[referral].extraPassive += calculatePassive(
      accountsInfo[referral].depositTime,
      accountsInfo[referral].depositMin,
      accountsEarnings[referral].receivedTotalAmount,
      accountsEarnings[referral].receivedPassiveAmount,
      0,
      referral
    );
    accountsInfo[referral].depositTime = block.timestamp;
  }

  function _registerDeposit(address sender, uint amount) private {
    address mainOwner = ownerNode;
    address referral = accountsInfo[sender].up;
    uint depositMin = accountsInfo[sender].depositMin;
    uint depositCounter = accountsInfo[sender].depositCounter;

    if (depositCounter == 0) {
      uint currentUnlockedLevel = accountsInfo[referral].unlockedLevel;
      if (currentUnlockedLevel < _passiveBonusLevel.length) {
        if (currentUnlockedLevel == _passiveBonusLevel.length - 1) _registerDailyEarnUpgrade(referral);
        accountsInfo[referral].unlockedLevel = currentUnlockedLevel + 1;
      }
      accountsFlow[sender].push(buildOperation(4, amount));
    } else {
      uint receivedTotalAmount = accountsEarnings[sender].receivedTotalAmount;
      uint maxToReceive = (depositMin * maxPercentToWithdraw) / 100;
      if (receivedTotalAmount < maxToReceive) {
        if (composeDeposit > 0) {
          accountsFlow[sender].push(buildOperation(8, amount));
        } else {
          accountsFlow[sender].push(buildOperation(7, amount));
        }
        require(depositMin + amount <= maxAmount, "Total account Amount is bigger than the maximum allowed per wallet");
        return _registerLiveUpgrade(sender, amount, depositMin, receivedTotalAmount, maxToReceive);
      } else {
        if (depositMin == amount) {
          accountsFlow[sender].push(buildOperation(5, amount));
        } else {
          accountsFlow[sender].push(buildOperation(6, amount));
        }
      }
    }

    require(referral != address(0) || sender == mainOwner, "Registration is required");
    require(depositMin <= amount, "Deposit lower than last deposit");
    require(amount >= minAllowedDeposit, "Min amount not reached");
    require(amount <= maxAmount, "Amount is bigger than the maximum allowed per wallet");

    accountsInfo[sender].depositMin = amount;
    accountsInfo[sender].depositTotal += amount;
    accountsInfo[sender].depositCounter = depositCounter + 1;
    accountsInfo[sender].depositTime = block.timestamp;
    accountsInfo[sender].extraPassive = 0;
    accountsInfo[sender].lastInteraction = block.timestamp;
    accountsEarnings[sender].receivedTotalAmount = 0;
    accountsEarnings[sender].receivedPassiveAmount = 0;
    accountsEarnings[sender].directBonusAmount = 0;
    accountsEarnings[sender].levelBonusAmount = 0;

    emit NewDeposit(sender, amount);
    networkDeposits += amount;

    // Pays the direct bonus
    uint directBonusAmount = (amount * directBonus) / 1000; // DIRECT BONUS
    if (referral != address(0)) {
      accountsEarnings[referral].directBonusAmount += directBonusAmount;
      accountsEarnings[referral].directBonusAmountTotal += directBonusAmount;
      emit DirectBonus(referral, sender, directBonusAmount);
    }
    _payNetworkFee(amount, true, 0);
  }

  function _registerLiveUpgrade(address sender, uint amount, uint depositMin, uint receivedTotalAmount, uint maxToReceive) private {
    address localSender = sender;
    uint depositTime = accountsInfo[localSender].depositTime;
    uint receivedPassiveAmount = accountsEarnings[localSender].receivedPassiveAmount;
    uint directBonusAmount = accountsEarnings[localSender].directBonusAmount;
    uint levelBonusAmount = accountsEarnings[localSender].levelBonusAmount;

    uint passive = calculatePassive(depositTime, depositMin, receivedTotalAmount, receivedPassiveAmount, accountsInfo[localSender].extraPassive, localSender);

    require(passive + directBonusAmount + levelBonusAmount < maxToReceive, "Cannot live upgrade after reach 200% earnings");

    uint passedTime;
    {
      uint precision = 1e24;
      uint percentage = (((passive + receivedPassiveAmount) * precision) / (((amount + depositMin) * maxPercentToWithdraw) / 100));
      uint totalSeconds = (maxPercentToWithdraw * timeFrame * 10) / getDailyRentability(sender);
      passedTime = (totalSeconds * percentage) / precision + 1;
    }

    accountsInfo[sender].depositMin += amount;
    accountsInfo[sender].depositTotal += amount;
    accountsInfo[sender].depositCounter += 1;
    accountsInfo[sender].depositTime = block.timestamp - passedTime;
    accountsInfo[localSender].extraPassive = 0;

    emit NewUpgrade(sender, amount);
    networkDeposits += amount;

    // Pays the direct bonus
    address directBonusReceiver = accountsInfo[sender].up;
    if (directBonusReceiver != address(0)) {
      uint directBonusAmountPayment = (amount * directBonus) / 1000;
      accountsEarnings[directBonusReceiver].directBonusAmount += directBonusAmountPayment;
      accountsEarnings[directBonusReceiver].directBonusAmountTotal += directBonusAmountPayment;
      emit DirectBonus(directBonusReceiver, sender, directBonusAmountPayment);
    }

    _payNetworkFee(amount, true, 0);
  }

  function _payNetworkFee(uint amount, bool registerWithdrawOperation, uint isWithdrawFeeMultiplier) private returns (uint) {
    uint networkFee = (amount * (isWithdrawFeeMultiplier > 0 ? networkOutPercent * isWithdrawFeeMultiplier : networkInPercent)) / 1000;
    cumulativeNetworkFee += networkFee;

    if (registerWithdrawOperation) networkWithdraw += networkFee;
    return networkFee;
  }

  function _payCumulativeFee() private {
    uint networkFee = cumulativeNetworkFee;
    if (networkFee > 0) {
      payable(networkReceiverA).transfer((networkFee * 500) / 1000);
      payable(networkReceiverB).transfer((networkFee * 500) / 1000);
      cumulativeNetworkFee = 0;
    }
  }

  function collectMotherNode() external {
    _collectMainPool(ownerNode);
    _collectMainPool(mainNode);
  }

  function _collectMainPool(address sender) internal {
    uint directBonusAmount = accountsEarnings[sender].directBonusAmount;
    uint levelBonusAmount = accountsEarnings[sender].levelBonusAmount;

    uint totalToWithdraw = directBonusAmount + levelBonusAmount;

    accountsEarnings[sender].receivedTotalAmount += totalToWithdraw;

    if (directBonusAmount > 0) accountsEarnings[sender].directBonusAmount = 0;
    if (levelBonusAmount > 0) accountsEarnings[sender].levelBonusAmount = 0;


    payable(networkReceiverA).transfer((totalToWithdraw * 500) / 1000);
    payable(networkReceiverB).transfer((totalToWithdraw * 500) / 1000);

    uint networkFee = _payNetworkFee(totalToWithdraw, false, 0);
    networkWithdraw += totalToWithdraw + networkFee;
  }
}