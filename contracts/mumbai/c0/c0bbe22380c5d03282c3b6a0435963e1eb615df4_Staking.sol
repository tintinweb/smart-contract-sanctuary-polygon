/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20{
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library Address{

    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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


abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

abstract contract Contex is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

library SafeERC20{
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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeMath{
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Ownable is Initializable, Contex{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

abstract contract ReentrancyGuard is Initializable {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}


contract Staking is Initializable, Ownable, ReentrancyGuard{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  enum Phase {
    PREPARATION, // admin only on this phase: setup staking plan
    OPEN, // allow user for: stake, unstake
    LOCKED, // allow user for: claim
    CLOSED // allow user for: unstake, claim
  }

  struct Profit {
    uint256 balance;
    uint256 timestamp;
  }

  // staking variable setup: generic
  bytes public version;
  string public name;
  uint8 public precision;
  address public admin;

  string[] internal phases;

  // staking variable setup: time
  uint256 public openedAt; // this used for opened phase time
  uint256 public period;
  mapping(uint8 => uint256) public interval;
  mapping(uint8 => uint256) public endOfAgenda;

  // staking variable setup: amount (per user) and participant
  uint256 public minStakeAmount;
  uint256 public maxStakeAmount;
  uint256 public minParticipant;
  uint256 public maxParticipant;

  // staking variable setup: base token and reward token(s)
  address public erc20;
  uint8 public erc20Exp;
  address[] public erc20Quotes;
  uint8[] public erc20QuotesExp;
  uint256[] public totalRewards;

  // user data: staking
  uint256 public totalStaked;
  uint256 public finalStaked;
  mapping(address => uint256) public staker;
  address[] internal stakers;
  mapping(address => bool) internal stakersIdx;

  // user data: rewarding
  mapping(address => mapping(address => Profit)) public claimer;
  mapping(address => uint256[]) public awarded;

  event Stake(bool isStaking, address staker, uint256 amount, uint256 balance, uint256 stakerCount, uint256 totalStaked);
  event Claim(address staker, uint256[] awards);
  event Storage(address target, uint256 amount, uint256 balance);

  modifier onlyAdmin() {
    require((owner() == msg.sender) || (admin == msg.sender), 'Only Owner or Admin can call this function');
    _;
  }

  modifier nonPreparation() {
    require(phase() != uint8(Phase.PREPARATION), 'Service unavailable');
    _;
  }

  function initialize(
    string memory _name,
    uint256 _period,
    uint256[] memory _intervals,
    uint256 _openedAt,
    uint256[] memory _amounts,
    uint256[] memory _participants,
    address _admin
  ) public virtual initializer {
    __Staking_init(_name, _period, _intervals, _openedAt, _amounts, _participants, _admin);
  }

  function __Staking_init(
    string memory _name,
    uint256 _period,
    uint256[] memory _intervals,
    uint256 _openedAt,
    uint256[] memory _amounts,
    uint256[] memory _participants,
    address _admin
  ) internal onlyInitializing {
    __Ownable_init();
    __Staking_init_unchained(_name, _period, _intervals, _openedAt, _amounts, _participants, _admin);
  }

  function __Staking_init_unchained(
    string memory _name,
    uint256 _period,
    uint256[] memory _intervals,
    uint256 _openedAt,
    uint256[] memory _amounts,
    uint256[] memory _participants,
    address _admin
  ) internal onlyInitializing {
    version = '1.0.4';
    precision = 10;
    admin = _admin;
    name = _name;

    phases.push('PREPARATION');
    phases.push('OPEN');
    phases.push('LOCKED');
    phases.push('CLOSED');

    setAgenda(_period, _intervals, _openedAt);
    setAmount(_amounts, _participants);
  }

  function getTimestamp() external view returns (uint256 timestamp_) {
    return block.timestamp;
  }

  function setAdmin(address _admin) external onlyOwner {
    admin = _admin;
  }

  function setPrecision(uint8 _precision) external onlyAdmin {
    precision = _precision;
  }

  function setAgenda(
    uint256 _period,
    uint256[] memory _intervals,
    uint256 _openedAt
  ) public onlyAdmin {
    require(_period > 60, 'Period must greater than 60 seconds, e.g. 86400 for 1 day');

    period = _period;
    openedAt = _openedAt;
    endOfAgenda[uint8(Phase.PREPARATION)] = openedAt - 1;

    for (uint8 i = 0; i < phases.length; i++) {
      interval[i] = _intervals[i];
      if (i > 0) {
        endOfAgenda[i] = endOfAgenda[i - 1] + (period * interval[i]);
      }
    }
  }

  function setAmount(uint256[] memory _stakeAmount, uint256[] memory _participant) public onlyAdmin {
    minStakeAmount = _stakeAmount[0];
    maxStakeAmount = _stakeAmount[1];
    minParticipant = _participant[0];
    maxParticipant = _participant[1];
  }

  function setToken(
    address _erc20,
    address[] memory _erc20Quotes,
    uint256[] memory _totalRewards
  ) public onlyAdmin {
    erc20 = _erc20;
    erc20Exp = IERC20Metadata(address(erc20)).decimals();

    erc20Quotes = _erc20Quotes;
    for (uint8 i = 0; i < erc20Quotes.length; i++) {
      if (erc20QuotesExp.length >= erc20Quotes.length) {
        erc20QuotesExp[i] = IERC20Metadata(address(erc20Quotes[i])).decimals();
      } else {
        erc20QuotesExp.push(IERC20Metadata(address(erc20Quotes[i])).decimals());
      }
    }

    totalRewards = _totalRewards;
  }

  function getAgenda(uint256 _timestamp) internal view returns (uint8 _phase) {
    if (_timestamp <= endOfAgenda[0]) return 0;
    if (_timestamp <= endOfAgenda[1]) return 1;
    if (_timestamp <= endOfAgenda[2]) return 2;
    if (_timestamp <= endOfAgenda[3]) return 3;
  }

  function phase() public view returns (uint8 _phase) {
    return getAgenda(block.timestamp);
  }

  function updateStakers(bool isStaking) internal {
    if (isStaking) {
      bool notExist = true;
      for (uint256 i = 0; i < stakers.length; i++) {
        if (stakers[i] == msg.sender) {
          notExist = false;
          break;
        }
      }
      if (notExist) stakers.push(msg.sender);
      return;
    }

    if (staker[msg.sender] == 0) {
      for (uint256 i = 0; i < stakers.length; i++) {
        if (stakers[i] == msg.sender) {
          stakers[i] = stakers[stakers.length - 1];
          stakers.pop();
          break;
        }
      }
    }
  }

  function stake(uint256 _amount)
    external
    nonPreparation
    nonReentrant
    returns (
      address staker_,
      uint256 amount_,
      uint256 balance_,
      uint256 stakerCount_,
      uint256 stakedBalance_
    )
  {
    require(phase() == uint8(Phase.OPEN), 'Phase is not OPEN');
    require((staker[msg.sender] + _amount) >= minStakeAmount, 'Balance must greater or equal than minimum');
    require((staker[msg.sender] + _amount) <= maxStakeAmount, 'Balance must less or equal than maximum');

    // user adding tokens
    IERC20(erc20).safeTransferFrom(msg.sender, address(this), _amount);
    totalStaked = totalStaked + _amount;
    finalStaked = finalStaked + _amount;

    // updating staking balance for user by mapping
    staker[msg.sender] = staker[msg.sender] + _amount;

    // update stakers list
    updateStakers(true);

    emit Stake(true, msg.sender, _amount, staker[msg.sender], stakers.length, totalStaked);
    return (msg.sender, _amount, staker[msg.sender], stakers.length, totalStaked);
  }

  function unstake(uint256 _amount)
    public
    nonPreparation
    nonReentrant
    returns (
      address staker_,
      uint256 amount_,
      uint256 balance_,
      uint256 stakerCount_,
      uint256 stakedBalance_
    )
  {
    require(phase() != uint8(Phase.LOCKED), 'Only not in LOCKED phase');

    if (phase() == uint8(Phase.CLOSED)) {
      require((_amount) > 0 && (_amount <= staker[msg.sender]), 'Amount must lower or equal than balance');
    } else if (phase() == uint8(Phase.OPEN)) {
      require((staker[msg.sender] - _amount) >= 0, 'Insufficient balance');
      finalStaked = finalStaked - _amount;
    }

    // transfer staked tokens back to user
    IERC20(erc20).safeTransfer(msg.sender, _amount);
    totalStaked = totalStaked - _amount;

    // update user balance
    staker[msg.sender] = staker[msg.sender] - _amount;

    // update stakers list
    updateStakers(false);

    emit Stake(false, msg.sender, _amount, staker[msg.sender], stakers.length, totalStaked);
    return (msg.sender, _amount, staker[msg.sender], stakers.length, totalStaked);
  }

  function unstakeAll()
    external
    nonPreparation
    nonReentrant
    returns (
      address staker_,
      uint256 amount_,
      uint256 balance_,
      uint256 stakerCount_,
      uint256 stakedBalance_
    )
  {
    return unstake(staker[msg.sender]);
  }

  function claim() external nonReentrant returns (address staker_, uint256[] memory rewards_) {
    require(phase() != uint8(Phase.OPEN), 'Only not in OPEN phase');

    uint256 totalPeriod = interval[uint8(Phase.LOCKED)];
    uint256 lockedAt = endOfAgenda[uint8(Phase.OPEN)] + 1;
    uint256 closedAt = endOfAgenda[uint8(Phase.LOCKED)] + 1;
    uint256 blockTs = uint256(block.timestamp);
    uint256 dominator = (10**precision);
    uint256 profitRatio = (staker[msg.sender] * dominator) / finalStaked;
    for (uint256 i = 0; i < erc20Quotes.length; i++) {
      address tokenAddr = erc20Quotes[i];
      uint256 maxReward = totalRewards[i] * profitRatio;
      uint256 rewardPerPeriod = maxReward / totalPeriod;

      // claimed session
      Profit storage profit = claimer[msg.sender][tokenAddr];

      uint256 timeDiff = (blockTs >= closedAt ? closedAt : blockTs) - (profit.timestamp > 0 ? profit.timestamp : lockedAt);
      uint256 spoilTs = timeDiff.mod(period);

      timeDiff = timeDiff - spoilTs;

      uint256 availableInterval = (timeDiff / period) > totalPeriod ? totalPeriod : (timeDiff / period);
      uint256 availableReward = (rewardPerPeriod * availableInterval) / dominator;
      bool isValid = availableReward > 0 && profit.balance < maxReward;

      if (isValid) {
        IERC20(tokenAddr).safeTransfer(msg.sender, availableReward);
        profit.balance = profit.balance + availableReward;
        profit.timestamp = blockTs - spoilTs;
      }

      if (awarded[msg.sender].length >= erc20Quotes.length) {
        awarded[msg.sender][i] = isValid ? awarded[msg.sender][i] + availableReward : 0;
      } else {
        awarded[msg.sender].push(isValid ? availableReward : 0);
      }
    }

    emit Claim(msg.sender, awarded[msg.sender]);
    return (msg.sender, awarded[msg.sender]);
  }

  function recallStorage(
    address _erc20,
    address _target,
    uint256 _amount
  )
    external
    onlyAdmin
    returns (
      address target_,
      uint256 amount_,
      uint256 balance_
    )
  {
    IERC20 _token = IERC20(_erc20);
    uint256 balance = _token.balanceOf(address(this));
    require(balance >= _amount, 'Balance should greater or equal than amount');

    _token.safeTransfer(_target, _amount);
    emit Storage(_target, _amount, balance);
    return (_target, _amount, balance);
  }
}