// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./War.sol";

contract WarDeployer {
  event WarDeployed(address indexed war, uint256 start, uint256 duration, uint256 rounds);

  function deployWar(uint256 _start, uint256 _duration, uint256 _rounds, address _token) public returns (address) {
    War war = new War(_start, _duration, _rounds, _token);

    emit WarDeployed(address(war), _start, _duration, _rounds);
    return address(war);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// ⠀⢠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡄⠀
// ⠀⠀⠹⣷⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⠏⠀⠀
// ⠀⠀⠀⠙⣿⣿⣿⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣿⣿⣿⠋⠀⠀⠀
// ⠀⠀⠀⠀⠈⢿⣿⣿⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀⢀⣤⣾⣿⣿⣿⡿⠁⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠹⣿⣿⡉⠻⣷⣤⡀⠀⠀⢀⣴⣾⠟⢉⣿⣿⠏⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣦⡈⠻⣿⣦⣀⠻⠟⢁⣴⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣦⡈⠻⣿⣷⣄⠙⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⣠⡀⠀⠀⠀⠀⣀⠙⢿⣿⣦⡈⠻⣿⣷⣄⠀⠀⠀⠀⢀⣄⠀⠀⠀⠀
// ⠀⠀⠀⠘⢿⣷⡄⠀⣠⣾⣿⠗⠀⠙⢿⣿⣦⡈⠻⣿⣷⣄⠀⢠⣾⡿⠃⠀⠀⠀
// ⠀⠀⠀⠀⠀⠙⢿⣾⣿⠟⢁⣴⣿⡷⠀⠙⢿⣿⣦⡈⠻⣿⣷⡿⠋⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⢀⣿⣿⣶⣿⡿⠋⠀⠀⠀⠀⠙⢿⣿⣶⣿⣿⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⣰⣿⠟⠉⠙⢿⣷⣄⡀⠀⠀⢀⣠⣾⡿⠋⠉⠻⣿⣆⠀⠀⠀⠀⠀
// ⠀⠀⢀⣴⣾⠋⠀⠀⠀⠀⠀⠙⢿⡿⠂⠐⢿⡿⠋⠀⠀⠀⠀⠀⠙⣷⣦⡀⠀⠀
// ⠀⠸⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⠇⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// War contracts are a self referential prediction market. Users engage in PVP economic warfare in hopes to win the pot.
contract War {
  // War parameters
  uint256 public startDate;
  uint256 public duration;
  uint256 public strikeCooldown;
  address public token;

  // War state
  uint256 public noAmount;
  uint256 public yesAmount;
  mapping(address => mapping(bool => uint)) public strikes;
  mapping(address => uint256) public lastBet;

  event Strike(address indexed user, bool indexed isYes, uint256 amount);
  event Claim(address indexed user, uint256 amount);

  modifier isOver() {
    require(block.timestamp > startDate + duration, "War: not over yet");
    _;
  }

  modifier inProgress() {
    require(block.timestamp >= startDate && block.timestamp < startDate + duration, "War: not in progress");
    _;
  }

  constructor(uint256 _start, uint256 _duration, uint256 _rounds, address _token) {
    startDate = _start;
    duration = _duration;
    strikeCooldown = _duration / _rounds;
    token = _token;
  }
  
  /// @notice A user can bet if they haven't in first round or if they have waited the cooldown
  function canBet(address _user) public view returns (bool) {
    if (lastBet[_user] == 0 && block.timestamp < startDate + strikeCooldown) {
      return true;
    }

    return block.timestamp > lastBet[_user] + strikeCooldown && block.timestamp < lastBet[_user] + strikeCooldown * 2;
  }

  /// @notice allow users to strike in the war
  function strike(bool _isYes, uint256 amount) inProgress external payable {
    require(canBet(msg.sender), "War: can't bet");
    require(amount > 0, "War: must send some amount");

    bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
    require(success, "War: transferFrom failed");

    lastBet[msg.sender] = block.timestamp;
    strikes[msg.sender][_isYes] += amount;

    if (_isYes) {
      yesAmount += amount;
    } else {
      noAmount += amount;
    }

    emit Strike(msg.sender, _isYes, amount);
  }

  /// @notice get the current winnings of a user
  function winnings(address _user) external view returns (uint256) { 
    bool yesWon = yesAmount > noAmount;
    uint256 shares = strikes[_user][yesWon];
    uint256 total = yesAmount + noAmount;
    uint256 totalWinnerShares = yesWon ? yesAmount : noAmount;

    return total / totalWinnerShares * shares;
  }

  /// @notice allow users to claim their winnings at the end of the war
  function claim() isOver external {
    uint256 amount = this.winnings(msg.sender);
    delete strikes[msg.sender][true];
    delete strikes[msg.sender][false];

    // use call to send the user their funds
    bool success = IERC20(token).transfer(msg.sender, amount);
    require(success, "War: transfer failed");

    emit Claim(msg.sender, amount);
  }  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}