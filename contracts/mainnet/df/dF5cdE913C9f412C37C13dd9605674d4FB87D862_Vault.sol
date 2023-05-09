// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./libs/app/Auth.sol";
import "./interfaces/IMENToken.sol";
import "./interfaces/ICitizen.sol";
import "./interfaces/ILPToken.sol";
import "./interfaces/ITaxManager.sol";
import "./interfaces/INFTPass.sol";
import "./abstracts/BaseContract.sol";
import "./interfaces/IShareManager.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/IVault.sol";

contract Vault is BaseContract {
  struct User {
    uint joinedAt;
    uint balance;
    uint balanceCredited;
    uint refCredited;
    uint deposited;
    uint depositedInUsd;
    uint depositedAndCompounded;
    uint depositedAndCompoundedInUsd;
    uint lastCheckin;
    uint[] claims;
    uint directQualifiedF1;
    uint qualifiedLevel;
    uint autoCompoundExpire;
    bool locked;
    uint totalClaimed;
    mapping (address => bool) levelUpFromF1;
  }
  struct Airdrop {
    uint lastAirdropped;
    uint userUpLineAirdropAmountThisWeek;
    uint userHorizontalAirdropAmountThisWeek;
  }
  struct Transfer {
    uint allowed;
    uint used;
  }
  struct Config {
    uint systemClaimHardCap;
    uint userClaimHardCap;
    uint f1QualifyCheckpoint;
    uint secondsInADay;
    uint minRateClaimCheckpoint;
    uint maxUpLineAirdropAmountPerWeek;
    uint maxHorizontalLineAirdropAmountPerWeek;
    uint maxDepositAmountInUsd;
    uint systemTodayClaimed;
    uint systemLastClaimed;
    uint vestingStartedAt;
    bool pauseAirdrop;
    uint refLevels;
  }
  struct ArrayConfig {
    uint[] refBonusPercentages;
    uint[] interestPercentages;
    uint[2] levelConditions;
  }
  IMENToken public menToken;
  ICitizen public citizen;
  ILPToken public lpToken;
  IShareManager public shareManager;
  ITaxManager public taxManager;
  INFTPass public nftPass;
  IBEP20 public stToken;
  Config public config;
  ArrayConfig private arrayConfig;
  ISwap public swap;
  uint private constant DECIMAL3 = 1000;
  bool private internalCalling;
  uint constant MAX_USER_LEVEL = 30;
  mapping (address => User) public users;
  mapping (address => Airdrop) public airdropAble;
  mapping (address => Transfer) public transferable;
  mapping (uint => uint) public autoCompoundPrices;
  mapping (address => bool) wlv;

  event Airdropped(address indexed sender, address receiver, uint amount, uint timestamp);
  event ArrayConfigUpdated(
    uint[] refBonusPercentages,
    uint[] interestPercentages,
    uint[2] levelConditions,
    uint timestamp
  );
  event AutoCompoundBought(address indexed user, uint extraDay, uint newExpireTimestamp, uint price);
  event AutoCompoundPriceSet(uint day, uint price);
  event BalanceTransferred(address indexed sender, address receiver, uint amount, uint timestamp);
  event Compounded(address indexed user, uint todayReward, uint timestamp);
  event ConfigUpdated(
    uint secondInADay,
    uint maxUpLineAirdropAmountPerWeek,
    uint maxHorizontalLineAirdropAmountPerWeek,
    uint maxDepositAmountInUsd,
    bool pauseAirdrop,
    uint systemClaimHardCap,
    uint userClaimHardCap,
    uint f1QualifyCheckpoint,
    uint refLevels,
    uint timestamp
  );
  event CompoundedFor(address[] users, uint[] todayRewards, bytes32 fingerPrint, uint timestamp);
  event Claimed(address indexed user, uint todayReward, uint timestamp);
  event Deposited(address indexed user, uint amount, uint timestamp, IVault.DepositType depositType);
  event RefBonusSent(address[31] users, uint[31] amounts, uint timestamp, address sender);

  function initialize() public initializer {
    BaseContract.init();
    arrayConfig.refBonusPercentages = [0, 300, 100, 100, 100, 50, 50, 50, 50, 50, 10, 10, 10, 10, 10, 10, 10, 10, 10, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];
    arrayConfig.interestPercentages = [8, 7, 7, 7, 7, 7, 7, 7, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 3];
    arrayConfig.levelConditions = [10, 1000];
    config.systemClaimHardCap = 100_000 ether;
    config.userClaimHardCap = 1000 ether;
    config.f1QualifyCheckpoint = 200 ether;
    config.minRateClaimCheckpoint = 22;
    config.secondsInADay = 86_400;
    config.maxDepositAmountInUsd = 5000 ether;
    config.refLevels = 30;
  }

  function deposit(uint _amount) external {
    internalCalling = true;
    _takeFundMEN(_amount);
    depositFor(msg.sender, _amount, IVault.DepositType.vaultDeposit);
    internalCalling = false;
  }

  function depositFor(address _userAddress, uint _amount, IVault.DepositType _depositType) public {
    require(internalCalling || msg.sender == address(swap), "Vault: only swap");
    require(citizen.isCitizen(_userAddress), "Vault: Please register first");
    User storage user = users[_userAddress];
    _validateUser(user);
    require(_amount > 0, "Vault: invalid amount");
    uint depositAmountInUsd = _amount * getTokenPrice() / DECIMAL3;
    require(user.depositedInUsd + depositAmountInUsd <= config.maxDepositAmountInUsd, "Vault: max deposit reached");
    _checkF1QualifyCheckpoint(user, _userAddress, depositAmountInUsd);
    _increaseDeposit(user, _amount, depositAmountInUsd);
    _increaseBalance(user, _amount * 2, false);
    if (user.joinedAt == 0) {
      user.joinedAt = block.timestamp;
    }
    _bonusReferral(_userAddress, _amount);
    emit Deposited(_userAddress, _amount * 2, block.timestamp, _depositType);
  }

  function airdrop(address _userAddress, uint _amount) public {
    require(citizen.isCitizen(msg.sender) && citizen.isCitizen(_userAddress), "Vault: Please register first");
    _resetAirdropStatisticIfNeed();
    User storage sender = users[msg.sender];
    _validateUser(sender);
    bool validSender = _validateAndUpdateAirdropStatistic(_userAddress, _amount);
    require(validSender && _amount > 0, "Vault: data invalid");
    _takeFundMEN(_amount);
    User storage user = users[_userAddress];
    uint depositAmountInUsd = _amount * getTokenPrice() / DECIMAL3;
    require(user.depositedInUsd + depositAmountInUsd <= config.maxDepositAmountInUsd, "Vault: max deposit reached");
    _checkF1QualifyCheckpoint(user, _userAddress, depositAmountInUsd);
    _increaseDeposit(user, _amount, depositAmountInUsd);
    _increaseBalance(user, _amount * 2, false);
    if (user.joinedAt == 0) {
      user.joinedAt = block.timestamp;
    }
    _bonusReferral(_userAddress, _amount);
    emit Airdropped(msg.sender, _userAddress, _amount, block.timestamp);
  }

  function transfer(address _receiver, uint _amount) external {
    require(_receiver != msg.sender, "Vault: receiver invalid");
    require(_amount > 0, "Vault: amount invalid");
    User storage sender = users[msg.sender];
    _validateSenderAndUpdateTransferStatistic(sender, _amount);
    sender.balance -= _amount;

    User storage receiver = users[_receiver];
    _increaseBalance(receiver, _amount, false);
    uint depositAmount = _amount / 2;
    uint depositAmountInUsd = _amount * getTokenPrice() / 2 / DECIMAL3;
    receiver.deposited += depositAmount;
    receiver.depositedAndCompounded += depositAmount;
    receiver.depositedInUsd += depositAmountInUsd;
    receiver.depositedAndCompoundedInUsd += depositAmountInUsd;
    emit BalanceTransferred(msg.sender, _receiver, _amount, block.timestamp);
  }

  function compound() external {
    uint todayReward = _compound(users[msg.sender], msg.sender, false);
    emit Compounded(msg.sender, todayReward, block.timestamp);
  }

  function claim() external {
    User storage user = users[msg.sender];
    require(user.autoCompoundExpire < _getNextDayTimestamp(), "Vault: your auto compound is running");
    uint todayReward = getUserTodayReward(msg.sender);
    _checkin(user);
    require(todayReward > 0, "Vault: no reward");
    _validateClaimCap(user, todayReward);
    _checkMintTokenIfNeeded(todayReward);
    user.balance -= todayReward;
    user.totalClaimed += todayReward;
    menToken.transfer(msg.sender, todayReward);
    _bonusReferral(msg.sender, todayReward);
    emit Claimed(msg.sender, todayReward, block.timestamp);
  }

  function buyAutoCompound(uint _days) external payable {
    require(autoCompoundPrices[_days] == msg.value && msg.value > 0, "Vault: data invalid");
    payable(contractCall).transfer(msg.value);
    uint extraDay = config.secondsInADay * _days;
    User storage user = users[msg.sender];
    if (user.autoCompoundExpire == 0 || user.autoCompoundExpire <= block.timestamp) {
      user.autoCompoundExpire = _getNextDayTimestamp() + extraDay;
    } else {
      user.autoCompoundExpire += extraDay;
    }
    emit AutoCompoundBought(msg.sender, extraDay, user.autoCompoundExpire, msg.value);
  }

  function getArrayConfigs() external view returns (uint[] memory, uint[] memory, uint[2] memory) {
    return (arrayConfig.refBonusPercentages, arrayConfig.interestPercentages, arrayConfig.levelConditions);
  }

  function getUserDeposited(address _user) external view returns (uint) {
    if (_user == addressBook.get("taxManager")) {
      return 999999999 ether;
    }
    return users[_user].depositedAndCompounded;
  }

  function getUserTodayReward(address _userAddress) public view returns (uint) {
    User storage user = users[_userAddress];
    if (user.lastCheckin == _getStartOfDayTimestamp()) {
      return 0;
    }
    uint startTimestampOfPrevious28Day = _getStartOfDayTimestamp() - config.secondsInADay * 28;
    uint userClaimsInPrevious28Day = _getUserClaimSince(user, startTimestampOfPrevious28Day);
    return user.balance * arrayConfig.interestPercentages[userClaimsInPrevious28Day] / DECIMAL3;
  }

  function testGetUserClaimAndBonusPercentage(address _userAddress) external view returns (uint, uint, uint, uint) {
    uint startTimestampOfPrevious28Day = _getStartOfDayTimestamp() - config.secondsInADay * 28;
    (uint a, uint b) = getUserClaimAndBonusPercentage(_userAddress);
    User storage user = users[_userAddress];
    uint totalClaims;
    for(uint i = user.claims.length - 1; i > 0; i--) {
      if(user.claims[i] > startTimestampOfPrevious28Day && totalClaims < 28) {
        totalClaims += 1;
      }
    }
    return (a, b, startTimestampOfPrevious28Day, totalClaims);
  }

  function getUserClaimAndBonusPercentage(address _userAddress) public view returns (uint, uint) {
    uint startTimestampOfPrevious28Day = _getStartOfDayTimestamp() - config.secondsInADay * 28;
    User storage user = users[_userAddress];
    // max out
    if (user.balanceCredited > 0 && user.balanceCredited >= user.depositedAndCompounded * 12) {
      return (0, arrayConfig.interestPercentages[29]);
    }
    uint totalClaims = 0;
    if (user.claims.length > 0) {
      for(uint i = user.claims.length - 1; i > 0; i--) {
        if(user.claims[i] > startTimestampOfPrevious28Day && totalClaims < 28) {
          totalClaims += 1;
        }
      }
      if (user.claims[0] > startTimestampOfPrevious28Day) {
        totalClaims += 1;
      }
    }
    if (startTimestampOfPrevious28Day < user.joinedAt || startTimestampOfPrevious28Day < config.vestingStartedAt) {
      return (totalClaims, arrayConfig.interestPercentages[15]); // default 0.5% for first 28 days
    }
    if (user.claims.length == 0) {
      return (0, arrayConfig.interestPercentages[0]);
    }
    if (user.claims.length == 1) {
      if (user.claims[0] < startTimestampOfPrevious28Day) {
        return (1, arrayConfig.interestPercentages[1]);
      } else {
        return (0, arrayConfig.interestPercentages[0]);
      }
    }
    return (totalClaims, arrayConfig.interestPercentages[totalClaims]);
  }

  function getUserClaims(address _userAddress) external view returns (uint[] memory) {
    return users[_userAddress].claims;
  }

  function getUserAirdropAmountThisWeek(address _userAddress) external view returns (uint, uint) {
    uint startOfWeek = block.timestamp - (block.timestamp - config.vestingStartedAt) % (config.secondsInADay * 7);
    if(airdropAble[_userAddress].lastAirdropped < startOfWeek) {
      return (0, 0);
    }
    return (airdropAble[_userAddress].userUpLineAirdropAmountThisWeek, airdropAble[_userAddress].userHorizontalAirdropAmountThisWeek);
  }

  // AUTH FUNCTIONS

  function setAutoCompoundPrice(uint _days, uint _price) external onlyMn {
    autoCompoundPrices[_days] = _price;
    emit AutoCompoundPriceSet(_days, _price);
  }

  function compoundFor(address[] calldata _users, bytes32 _fingerPrint) public onlyContractCall {
    uint[] memory todayRewards = new uint[](_users.length);
    User storage user;
    for(uint i = 0; i < _users.length; i++) {
      user = users[_users[i]];
      require(user.autoCompoundExpire >= _getNextDayTimestamp(), "Vault: user expire");
      todayRewards[i] = _compound(user, _users[i], true);
    }
    emit CompoundedFor(_users, todayRewards, _fingerPrint, block.timestamp);
  }

  function updateQualifiedLevel(address _user1Address, address _user2Address) external {
    address shareAddress = addressBook.get("shareManager");
    if(!(_user1Address == address(0) || _user1Address == shareAddress)) {
      _updateQualifiedLevel(_user1Address, nftPass.balanceOf(_user1Address), stToken.balanceOf(_user1Address));
    }
    if(!(_user2Address == address(0) || _user2Address == shareAddress)) {
      _updateQualifiedLevel(_user2Address, nftPass.balanceOf(_user2Address), stToken.balanceOf(_user2Address));
    }
  }

  function updateConfig(
    uint _secondsInADay,
    uint _maxUpLineAirdropAmountPerWeek,
    uint _maxHorizontalLineAirdropAmountPerWeek,
    uint _maxDepositAmountInUsd,
    bool _isPaused,
    uint _systemClaimHardCap,
    uint _userClaimHardCap,
    uint _f1QualifyCheckpoint,
    uint _refLevels
  ) external onlyMn {
    require(_refLevels > 0 && _refLevels <= 30, "Vault: _refLevels invalid");
    config.secondsInADay = _secondsInADay;
    config.maxUpLineAirdropAmountPerWeek = _maxUpLineAirdropAmountPerWeek;
    config.maxHorizontalLineAirdropAmountPerWeek = _maxHorizontalLineAirdropAmountPerWeek;
    config.maxDepositAmountInUsd = _maxDepositAmountInUsd;
    config.pauseAirdrop = _isPaused;
    config.systemClaimHardCap = _systemClaimHardCap;
    config.userClaimHardCap = _userClaimHardCap;
    config.f1QualifyCheckpoint = _f1QualifyCheckpoint;
    config.refLevels = _refLevels;
    emit ConfigUpdated(
      _secondsInADay,
      _maxUpLineAirdropAmountPerWeek,
      _maxHorizontalLineAirdropAmountPerWeek,
      _maxDepositAmountInUsd,
      _isPaused,
      _systemClaimHardCap,
      _userClaimHardCap,
      _f1QualifyCheckpoint,
      _refLevels,
      block.timestamp
    );
  }

  function updateArrayConfig(
    uint[] calldata _interestPercentages,
    uint[] calldata _refBonusPercentages,
    uint[2] calldata _levelConditions
  ) external onlyMn {
    uint refBonusPercentages;
    for (uint i = 0; i < _refBonusPercentages.length; i++) {
      refBonusPercentages += _refBonusPercentages[i];
    }
    require(refBonusPercentages == 1000, "Vault: refBonusPercentages invalid");
    arrayConfig.interestPercentages = _interestPercentages;
    arrayConfig.refBonusPercentages = _refBonusPercentages;
    arrayConfig.levelConditions = _levelConditions;
    emit ArrayConfigUpdated(_interestPercentages, _refBonusPercentages, _levelConditions, block.timestamp);
  }

  function updateTransfer(address _user, uint _allowed) external onlyMn {
    transferable[_user].allowed = _allowed;
  }

  function startVesting(uint _timestamp) external onlyMn {
    require(_timestamp > block.timestamp && config.vestingStartedAt == 0, "Vault: timestamp must be in the future or vesting had started already");
    config.vestingStartedAt = _timestamp;
  }

  function updateWaitingStatus(address _user, bool _wait) external onlyMn {
    users[_user].locked = _wait;
  }

  function swlv(address _user, bool _wlv) external onlyMn {
    wlv[_user] = _wlv;
  }

  // PRIVATE FUNCTIONS

  function _increaseBalance(User storage _user, uint _amount, bool _refBonus) private returns (uint) {
    if (_refBonus && _user.deposited == 0) {
      return 0;
    }
    uint increaseAble = _amount;
    if (_user.depositedAndCompounded > 0 && _user.balanceCredited + _amount > (_user.depositedAndCompounded * 12)) {
      increaseAble = _user.depositedAndCompounded * 12 - _user.balanceCredited;
    }
    _user.balance += increaseAble;
    _user.balanceCredited += increaseAble;
    if (_refBonus) {
      _user.refCredited += increaseAble;
    }
    return increaseAble;
  }

  function _increaseDeposit(User storage _user, uint _amount, uint _amountInUsd) private {
    _user.deposited += _amount;
    _user.depositedInUsd += _amountInUsd;
    _user.depositedAndCompounded += _amount;
    _user.depositedAndCompoundedInUsd += _amountInUsd;
  }

  function _checkF1QualifyCheckpoint(User storage _user, address _userAddress, uint _depositAmountInUsd) private {
    if (_user.depositedAndCompoundedInUsd + _depositAmountInUsd >= config.f1QualifyCheckpoint) {
      _increaseInviterDirectQualifiedF1(_userAddress);
    }
  }

  function _checkMintTokenIfNeeded(uint _targetBalance) private {
    uint contractBalance = menToken.balanceOf(address(this));
    if (contractBalance >= _targetBalance) {
      return;
    }
    menToken.releaseMintingAllocation(_targetBalance - contractBalance);
  }

  function _compound(User storage _user, address _userAddress, bool _autoCompound) private returns (uint) {
    if (!_autoCompound) {
      require(_user.autoCompoundExpire < _getNextDayTimestamp(), "Vault: your auto compound is running");
    }
    uint todayReward = getUserTodayReward(_userAddress);
    _checkin(_user);
    uint todayRewardInUsd = todayReward * getTokenPrice() / DECIMAL3;
    _checkF1QualifyCheckpoint(_user, _userAddress, todayRewardInUsd);
    _user.balance += todayReward;
    _user.balanceCredited += todayReward * 2;
    _user.depositedAndCompounded += todayReward;
    _user.depositedAndCompoundedInUsd += todayRewardInUsd;
    _bonusReferral(_userAddress, todayReward);
    return todayReward;
  }

  function _getUserClaimSince(User storage _user, uint _timestamp) private view returns (uint) {
    // max out
    if (_user.balanceCredited > 0 && _user.balanceCredited >= _user.depositedAndCompounded * 12) {
      return 29;
    }
    if (_timestamp < _user.joinedAt || _timestamp < config.vestingStartedAt) {
      return 15; // default 0.5% for first 28 days
    }
    if (_user.claims.length == 0) {
      return 0;
    }
    if (_user.claims.length == 1) {
      if (_user.claims[0] < _timestamp) {
        return 1;
      } else {
        return 0;
      }
    }
    uint totalClaims = 0;
    for(uint i = _user.claims.length - 1; i > 0; i--) {
      if(_user.claims[i] < _timestamp || totalClaims >= config.minRateClaimCheckpoint) {
        return totalClaims;
      }
      totalClaims += 1;
    }
    if (_user.claims.length < config.minRateClaimCheckpoint && _user.claims[0] < _timestamp) {
      totalClaims += 1;
    }
    return totalClaims;
  }

  function _checkin(User storage _user) private {
    require(config.vestingStartedAt > 0, "Vault: please wait for more time");
    require(_user.joinedAt > 0, "Vault: please deposit first");
    _validateUser(_user);
    require(block.timestamp - _user.lastCheckin >= config.secondsInADay, "Vault: please wait more time");
    _user.lastCheckin = _getStartOfDayTimestamp();
  }

  function _bonusReferral(address _userAddress, uint _amount) private {
    address[31] memory refAddresses;
    uint[31] memory refAmounts;
    address inviterAddress;
    address senderAddress = _userAddress;
    uint refBonusAmount;
    uint defaultRefBonusAmount = 0;
    User storage inviter;
    address defaultInviter = citizen.defaultInviter();
    for (uint i = 1; i <= config.refLevels; i++) {
      inviterAddress = citizen.getInviter(_userAddress);
      if (inviterAddress == address(0)) {
        break;
      }
      refBonusAmount = (_amount * arrayConfig.refBonusPercentages[i] / DECIMAL3);
      inviter = users[inviterAddress];
      if (
        (i == 1 || inviter.qualifiedLevel >= i || wlv[inviterAddress]) &&
        (inviterAddress != defaultInviter)
      ) {
        refBonusAmount = _increaseBalance(inviter, refBonusAmount, true);
        if (refBonusAmount > 0) {
          refAddresses[i - 1] = inviterAddress;
          refAmounts[i - 1] = refBonusAmount;
        }
      } else {
        defaultRefBonusAmount += refBonusAmount;
      }
      _userAddress = inviterAddress;
    }
    if (config.refLevels < 30) {
      uint refBonusPercentageLeft;
      for (uint i = 30; i > config.refLevels; i--) {
        refBonusPercentageLeft += arrayConfig.refBonusPercentages[i];
      }
      defaultRefBonusAmount += (_amount * refBonusPercentageLeft / DECIMAL3);
    }
    if (defaultRefBonusAmount > 0) {
      User storage defaultAcc = users[defaultInviter];
      defaultAcc.balance += defaultRefBonusAmount;
      defaultAcc.balanceCredited += defaultRefBonusAmount;
      defaultAcc.refCredited += defaultRefBonusAmount;
      refAddresses[30] = defaultInviter;
      refAmounts[30] = defaultRefBonusAmount;
    }
    emit RefBonusSent(refAddresses, refAmounts, block.timestamp, senderAddress);
  }

  function _increaseInviterDirectQualifiedF1(address _userAddress) private {
    address inviterAddress = _getInviter(_userAddress);
    User storage inviter = users[inviterAddress];
    if (inviter.levelUpFromF1[_userAddress]) {
      return;
    }
    inviter.levelUpFromF1[_userAddress] = true;
    inviter.directQualifiedF1 += 1;
    _updateQualifiedLevel(inviterAddress, nftPass.balanceOf(inviterAddress), stToken.balanceOf(inviterAddress));
  }

  function _updateQualifiedLevel(address _userAddress, uint _nftBalance, uint _stBalance) private {
    (uint nftStocked, uint stStocked) = shareManager.getUserHolding(_userAddress);
    uint nftPoint = (_nftBalance + nftStocked) / arrayConfig.levelConditions[0];
    uint stPoint = (_stBalance + stStocked) / arrayConfig.levelConditions[1] / 1 ether;
    User storage user = users[_userAddress];
    uint newLevel = user.directQualifiedF1 + nftPoint + stPoint;
    user.qualifiedLevel = newLevel > MAX_USER_LEVEL
      ? MAX_USER_LEVEL
      : newLevel;
  }

  function _getInviter(address _userAddress) private returns (address) {
    address defaultInviter = citizen.defaultInviter();
    if (_userAddress == defaultInviter) {
      return address(0);
    }
    address inviterAddress = citizen.getInviter(_userAddress);
    if (inviterAddress == address(0)) {
      inviterAddress = defaultInviter;
    }
    return inviterAddress;
  }

  function _takeFundMEN(uint _amount) private {
    require(menToken.allowance(msg.sender, address(this)) >= _amount, "Vault: please call approve function first");
    require(menToken.balanceOf(msg.sender) >= _amount, "Vault: insufficient balance");
    menToken.transferFrom(msg.sender, address(this), _amount);
  }

  function getTokenPrice() public view returns (uint) {
    (uint r0, uint r1) = lpToken.getReserves();
    return r1 * DECIMAL3 / r0;
  }

  function _getNextDayTimestamp() private view returns (uint) {
    return block.timestamp - block.timestamp % config.secondsInADay + config.secondsInADay;
  }

  function _getStartOfDayTimestamp() private view returns (uint) {
    return block.timestamp - block.timestamp % config.secondsInADay;
  }

  function _resetAirdropStatisticIfNeed() private {
    uint startOfWeek = block.timestamp - (block.timestamp - config.vestingStartedAt) % (config.secondsInADay * 7);
    if(airdropAble[msg.sender].lastAirdropped < startOfWeek) {
      delete airdropAble[msg.sender].userUpLineAirdropAmountThisWeek;
      delete airdropAble[msg.sender].userHorizontalAirdropAmountThisWeek;
    }
  }

  function _validateSenderAndUpdateTransferStatistic(User storage _sender, uint _amount) private {
    _validateUser(_sender);
    require(_sender.balance >= _amount, "Vault: insufficient vault balance");
    require(transferable[msg.sender].used + _amount <= transferable[msg.sender].allowed, "Vault: transfer amount exceeded allowance");
    transferable[msg.sender].used += _amount;
  }

  function _validateAndUpdateAirdropStatistic(address _receiverAddress, uint _amount) private returns (bool) {
    if(config.pauseAirdrop) {
      return false;
    }
    Airdrop storage airdropInfo = airdropAble[msg.sender];
    bool isInDownLine = citizen.isSameLine(_receiverAddress, msg.sender);
    if (isInDownLine) {
      airdropInfo.lastAirdropped = block.timestamp;
      return true;
    }
    bool isInUpLine = citizen.isSameLine(msg.sender, _receiverAddress);
    bool valid;
    if (isInUpLine) {
      valid = config.maxUpLineAirdropAmountPerWeek >= (airdropInfo.userUpLineAirdropAmountThisWeek + _amount);
      if(valid) {
        airdropInfo.lastAirdropped = block.timestamp;
        airdropInfo.userUpLineAirdropAmountThisWeek += _amount;
      }
    } else {
      valid = config.maxHorizontalLineAirdropAmountPerWeek >= (airdropInfo.userHorizontalAirdropAmountThisWeek + _amount);
      if (valid) {
        airdropInfo.lastAirdropped = block.timestamp;
        airdropInfo.userHorizontalAirdropAmountThisWeek += _amount;
      }
    }
    return valid;
  }

  function _validateClaimCap(User storage _user, uint _todayReward) private {
    if (config.systemLastClaimed < _getStartOfDayTimestamp()) {
      config.systemTodayClaimed = 0;
    }
    require(config.systemTodayClaimed + _todayReward <= config.systemClaimHardCap, "Vault: system hard cap reached");
    config.systemTodayClaimed += _todayReward;
    config.systemLastClaimed = block.timestamp;

    require(_todayReward <= config.userClaimHardCap, "Vault: user hard cap reached");
    _user.claims.push(block.timestamp);
  }

  function _validateUser(User storage _user) private view {
    require(!_user.locked, "Vault: user is locked");
  }

  function _initDependentContracts() override internal {
    menToken = IMENToken(addressBook.get("menToken"));
    lpToken = ILPToken(addressBook.get("lpToken"));
    shareManager = IShareManager(addressBook.get("shareManager"));
    taxManager = ITaxManager(addressBook.get("taxManager"));
    nftPass = INFTPass(addressBook.get("nftPass"));
    citizen = ICitizen(addressBook.get("citizen"));
    stToken = IBEP20(addressBook.get("stToken"));
    swap = ISwap(addressBook.get("swap"));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IAddressBook.sol";

abstract contract Auth is Initializable {

  address public bk;
  address public mn;
  address public contractCall;
  IAddressBook public addressBook;

  event ContractCallUpdated(address indexed _newOwner);

  function init(address _mn) virtual public {
    mn = _mn;
    contractCall = _mn;
  }

  modifier onlyBk() {
    require(_isBk(), "onlyBk");
    _;
  }

  modifier onlyMn() {
    require(_isMn(), "Mn");
    _;
  }

  modifier onlyContractCall() {
    require(_isContractCall() || _isMn(), "onlyContractCall");
    _;
  }

  function updateContractCall(address _newValue) external onlyMn {
    require(_newValue != address(0x0));
    contractCall = _newValue;
    emit ContractCallUpdated(_newValue);
  }

  function setAddressBook(address _addressBook) external onlyMn {
    addressBook = IAddressBook(_addressBook);
    _initDependentContracts();
  }

  function reloadAddresses() external onlyMn {
    _initDependentContracts();
  }

  function updateBk(address _newBk) external onlyBk {
    require(_newBk != address(0), "TokenAuth: invalid new bk");
    bk = _newBk;
  }

  function reload() external onlyBk {
    mn = addressBook.get("mn");
    contractCall = addressBook.get("contractCall");
  }

  function _initDependentContracts() virtual internal;

  function _isBk() internal view returns (bool) {
    return msg.sender == bk;
  }

  function _isMn() internal view returns (bool) {
    return msg.sender == mn;
  }

  function _isContractCall() internal view returns (bool) {
    return msg.sender == contractCall;
  }
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface IMENToken is IBEP20 {
  function releaseMintingAllocation(uint _amount) external returns (bool);
  function releaseLMSAllocation(uint _amount) external returns (bool);
  function burn(uint _amount) external;
  function mint(uint _amount) external returns (bool);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface ICitizen {
  function isCitizen(address _address) external view returns (bool);
  function getInviter(address _address) external returns (address);
  function defaultInviter() external returns (address);
  function isSameLine(address _from, address _to) external view returns (bool);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface ILPToken is IBEP20 {
  function getReserves() external view returns (uint, uint);
  function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface ITaxManager {
  function totalTaxPercentage() external view returns (uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface INFTPass is IERC721Upgradeable {
  function mint(address _owner, uint _quantity) external;
  function getOwnerNFTs(address _owner) external view returns(uint[] memory);
  function waitingList(address _user) external view returns (bool);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.9;

import "../libs/app/Auth.sol";
import "../interfaces/IAddressBook.sol";

abstract contract BaseContract is Auth {

  function init() virtual public {
    Auth.init(msg.sender);
  }
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IShareManager {
  function fund(uint _amount) external;
  function getUserHolding(address _userAddress) external view returns (uint, uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface ISwap {
  enum PaymentCurrency {
    usdt,
    usdc,
    dai
  }
  function swapTokenForUSDT(uint _amount, bool _lms) external;
  function swapUSDForToken(uint _amount, PaymentCurrency _paymentCurrency, bool _autoStake) external returns (uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IVault {
  enum DepositType {
    vaultDeposit,
    swapUSDForToken,
    swapBuyDNO
  }

  function updateQualifiedLevel(address _user1Address, address _user2Address) external;
  function depositFor(address _userAddress, uint _amount, DepositType _depositType) external;
  function getUserDeposited(address _user) external view returns (uint);
  function getTokenPrice() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IAddressBook {
  function get(string calldata _name) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165Upgradeable {
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