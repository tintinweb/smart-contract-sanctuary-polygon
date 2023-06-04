/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract BlogChallenge {
  // 挑战的数据结构
  struct Challenge {
    uint256 startTime; // 挑战开始时间（s）
    uint256 cycle; // 挑战周期长度
    uint256 numberOfCycles; // 周期数

    address challenger; // 挑战者地址
    address[] participants; // 参与者地址
    uint256 maxParticipants; // 最大参与者数量

    IERC20 penaltyToken; // 惩罚币种
    uint256 penaltyAmount; // 惩罚金额

    uint256 deposit; // 押金（已存入的押金）
    string[][] blogSubmissions; // 博客提交情况
    uint8 noBalanceCount; // 余额不足次数

    uint256 lastUpdatedCycle; // 最后更新的Cycle
    bool started; // 挑战是否开始
  }

  // 当前挑战
  Challenge public currentChallenge;

  uint256 public constant DEPOSIT_MULTIPLIER = 3; // 押金倍数
  uint256 public constant SUCCEED_RATE = 60; // 挑战成功所需的比率

  // region events

  event ChallengeStart(address indexed challenger);
  event ChallengeEnd(address indexed challenger, bool indexed passed);

  event SubmitBlog(address indexed challenger, uint256 indexed cycle, string blogUrl);
  event CycleEnd(address indexed challenger, uint256 indexed cycle, bool indexed passed);

  event Participate(address indexed challenger, address indexed participant);
  event Exit(address indexed challenger, address indexed participant);

  event Release(address indexed challenger, uint256 indexed cycle, uint256 amount);

  // endregion

  // region modifier

  modifier onlyChallenger() {
    require(msg.sender == currentChallenge.challenger, "Not challenger!");
    _;
  }
  modifier onlyParticipant() {
    bool isParticipant = false;
    for (uint256 i = 0; i < currentChallenge.participants.length; i++) {
      if (msg.sender == currentChallenge.participants[i]) {
        isParticipant = true;
        break;
      }
    }
    require(isParticipant, "Not participant!");
    _;
  }
  modifier onlyNotParticipant() {
    bool isParticipant = false;
    for (uint256 i = 0; i < currentChallenge.participants.length; i++) {
      if (msg.sender == currentChallenge.participants[i]) {
        isParticipant = true;
        break;
      }
    }
    require(msg.sender != currentChallenge.challenger && !isParticipant, "Already participant!");
    _;
  }
  modifier onlyStarted() {
    require(currentChallenge.started, "Not started");
    _;
  }
  modifier onlyEnded() {
    require(!currentChallenge.started, "Not ended");
    _;
  }
  modifier onlyAfter(uint256 time) {
    require(block.timestamp >= time, "Function called too early");
    _;
  }
  modifier onlyBefore(uint256 time) {
    if (time > 0)
      require(block.timestamp < time, "Function called too late");
    _;
  }

  // endregion

  // region View calls

  function challenger() public view returns (address) {
    return currentChallenge.challenger;
  }
  function participants() public view returns (address[] memory) {
    return currentChallenge.participants;
  }
  function currentDeposit() public view returns (uint256) {
    return currentChallenge.deposit;
  }

  // 当前周期数（0表示没有开始，从1开始，最大值为currentChallenge.numberOfCycles + 1）
  function currentCycle() public onlyStarted view returns (uint256) {
    if (block.timestamp < currentChallenge.startTime) return 0;

    uint256 res = (block.timestamp - currentChallenge.startTime) / currentChallenge.cycle + 1;
    if (res > currentChallenge.numberOfCycles) return currentChallenge.numberOfCycles + 1;

    return res;
  }
  function currentCycleIdx() public view returns (uint256) {
    uint256 cycle = currentCycle();
    return cycle <= 0 ? 0 : cycle - 1;
  }

  // 是否最后一个周期
  function isLastCycle(uint256 cycle) public onlyStarted view returns (bool) {
    return cycle >= currentChallenge.numberOfCycles;
  }
  // 是否最后一个周期也已经完成
  function isFinishedCycle(uint256 cycle) public onlyStarted view returns (bool) {
    return cycle >= currentChallenge.numberOfCycles + 1;
  }

  // 是否将要被更新的周期
  function isToBeUpdatedCycle(uint256 cycle) public view returns (bool) {
    // 周期必须在当前周期之前，上一个已经更新过的周期之后
    return cycle < currentCycle() && cycle > currentChallenge.lastUpdatedCycle;
  }

  // 周期是否成功（周期都是从1开始的）
  function isCycleSucceed(uint256 cycle) public onlyStarted view returns (bool) {
    return currentChallenge.blogSubmissions[cycle - 1].length > 0;
  }

  // 检查挑战是否成功
  function checkSuccess() public onlyStarted view returns (bool) {
    // 成功提交的次数
    uint256 successfulSubmissions = 0;
    // 遍历所有周期
    for (uint256 i = 1; i <= currentChallenge.numberOfCycles; i++)
    // 如果该周期提交了博客，成功次数加一
      if (isCycleSucceed(i)) successfulSubmissions++;

    // 如果成功次数达到总周期数的60%，则挑战成功
    return successfulSubmissions >= currentChallenge.numberOfCycles * SUCCEED_RATE / 100;
  }

  // 获取要授权的代币数量
  function approveAmount() public onlyStarted view returns (uint256) {
    return currentChallenge.penaltyAmount * (DEPOSIT_MULTIPLIER + currentChallenge.numberOfCycles);
  }
  // 获取押金的代币数量
  function depositAmount() public onlyStarted view returns (uint256) {
    return currentChallenge.penaltyAmount * DEPOSIT_MULTIPLIER;
  }

  // 挑战者是否授权
  function isChallengerApproved() public onlyStarted view returns (bool) {
    IERC20 token = currentChallenge.penaltyToken;
    uint256 approve = token.allowance(currentChallenge.challenger, address(this));

    if (currentChallenge.deposit <= 0) // 未交押金
      return approve >= approveAmount();

    uint256 restCycle = currentChallenge.numberOfCycles - currentCycleIdx();
    return approve >= currentChallenge.penaltyAmount * restCycle;
  }

  // endregion

  // region Public calls

  // 设置挑战
  function setChallenge(
    uint256 _startTime,
    uint256 _cycle,
    uint256 _numberOfCycles,
    address _challenger,
    address[] memory _participants,
    uint256 _maxParticipants,
    IERC20 _penaltyToken,
    uint256 _penaltyAmount
  ) public onlyEnded {

    string[][] memory blogSubmissions = new string[][](_numberOfCycles);
    for (uint256 i = 0; i < _numberOfCycles; i++)
      blogSubmissions[i] = new string[](0);

    // 初始化当前挑战
    currentChallenge = Challenge({
    // 时间设置
    startTime: _startTime,
    cycle: _cycle,
    numberOfCycles: _numberOfCycles,

    // 人员设置
    challenger: _challenger,
    participants: _participants,
    maxParticipants: _maxParticipants,

    // 惩罚设置
    penaltyToken: _penaltyToken,
    penaltyAmount: _penaltyAmount,

    // 挑战者状态
    deposit: 0,
    blogSubmissions: blogSubmissions,
    noBalanceCount: 0,

    // 挑战状态
    lastUpdatedCycle: 0,
    started: true
    });

    for (uint256 i = 0; i < _participants.length; i++)
      emit Participate(_challenger, _participants[i]);

    emit ChallengeStart(_challenger);
  }

  // 中途加入
  function participate() public onlyNotParticipant onlyStarted {
    require(currentChallenge.participants.length <
      currentChallenge.maxParticipants, "Participants over limit!");

    currentChallenge.participants.push(msg.sender);
    emit Participate(currentChallenge.challenger, msg.sender);
  }

  // 更新周期（任何人都能调用）
  function updateCycle() public onlyStarted {
    uint256 cycle = currentChallenge.lastUpdatedCycle + 1;
    require(isToBeUpdatedCycle(cycle), "All cycles are updated!");

    do {
      string[] memory blogs = currentChallenge.blogSubmissions[cycle - 1];

      // 如果挑战者没有提交博客，则发放惩罚金
      if (blogs.length <= 0) onCycleFailed();
      // 否则视为通过
      else onCyclePass();

      emit CycleEnd(currentChallenge.challenger, cycle, blogs.length > 0);

      cycle++;
    } while (currentChallenge.started && isToBeUpdatedCycle(cycle));

    // 更新lastUpdatedCycle
    currentChallenge.lastUpdatedCycle = cycle - 1;

    if (currentChallenge.started && isFinishedCycle(cycle))
      endChallenge(checkSuccess());
  }

  // endregion

  // region Challenger calls

  // 存入押金
  function depositPenalty() public onlyChallenger onlyStarted {
    uint256 deposit = depositAmount();

    require(currentChallenge.deposit < deposit, "Have been deposited!");

    currentChallenge.penaltyToken.transferFrom(msg.sender, address(this), deposit);
    currentChallenge.deposit = deposit;
  }

  // 提交博客
  function submitBlog(string memory blogUrl) public onlyChallenger onlyStarted {
    // 记录博客提交情况
    currentChallenge.blogSubmissions[currentCycleIdx()].push(blogUrl);
    emit SubmitBlog(currentChallenge.challenger, currentCycle(), blogUrl);
  }

  // endregion

  // region Participant calls

  // 中途退出
  function exit() public onlyStarted {
    uint256 len = currentChallenge.participants.length;
    for (uint256 i = 0; i < len; i++) {
      if (msg.sender == currentChallenge.participants[i]) {
        currentChallenge.participants[i] = currentChallenge.participants[len - 1];
        currentChallenge.participants.pop();
        emit Exit(currentChallenge.challenger, msg.sender);

        break;
      }
    }
  }

  // endregion

  // region Private calls

  // 给参与者发放奖励
  function releaseToParticipants(address payer, uint256 totalAmount) private {
    IERC20 token = currentChallenge.penaltyToken;
    uint256 length = currentChallenge.participants.length;
    uint256 amount = totalAmount / length;

    for (uint256 i; i < length; i++) {
      address participant = currentChallenge.participants[i];
      if (payer == address(this)) // 如果payer是合约，直接发起转账
        token.transfer(participant, amount);
      else // 否则通过授权转账
        token.transferFrom(payer, participant, amount);
    }

    emit Release(currentChallenge.challenger, currentCycle(), amount);
  }

  // 周期成功回调
  function onCyclePass() private {
  }
  // 周期失败回调
  function onCycleFailed() private {
    IERC20 token = currentChallenge.penaltyToken;
    uint256 balance = token.balanceOf(currentChallenge.challenger);
    uint256 amount = currentChallenge.penaltyAmount;

    if (balance < amount || !isChallengerApproved()) { // 如果余额或授权数量不足
      currentChallenge.noBalanceCount++;

      // 如果两次余额不足
      if (currentChallenge.noBalanceCount >= 2) {
        // 将剩余押金平均分给参与者
        releaseToParticipants(address(this), currentChallenge.deposit);
        currentChallenge.deposit = 0;
        endChallenge(false);
      }

      // 如果有足够的押金
      else if (currentChallenge.deposit >= amount) {
        // 扣除并释放惩罚金（通过押金的方式）
        releaseToParticipants(address(this), amount);
        currentChallenge.deposit -= amount;
      }

      // 否则结束挑战
      else endChallenge(false);
    }
    // 如果余额和授权充足，扣除并释放惩罚金
    else releaseToParticipants(currentChallenge.challenger, amount);
  }

  // 结束挑战
  function endChallenge(bool success) private {
    // 挑战成功
    if (success) onChallengePass();
    // 挑战失败
    else onChallengeFailed();

    emit ChallengeEnd(currentChallenge.challenger, success);

    withdrawDeposit();
    // 标记挑战为已结束
    currentChallenge.started = false;
  }
  // 提取押金
  function withdrawDeposit() private {
    if (currentChallenge.deposit <= 0) return;
    // 将剩余押金转给挑战者
    currentChallenge.penaltyToken.transfer(
      currentChallenge.challenger, currentChallenge.deposit);
    currentChallenge.deposit = 0;
  }
  // 挑战成功回调
  function onChallengePass() private {
    // TODO: 发放NFT
  }
  // 挑战失败回调
  function onChallengeFailed() private {
  }

  // endregion
}