// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
  event Deposit(address indexed account, uint256 amount, uint256 week);
  event Withdraw(address indexed account, uint256 amount, uint256 week);

  function DepositAmount(uint8 level, uint256 amount) external returns (bool);

  function AddUser(uint8 level, address userAddr) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./IPool.sol";

contract Pool is IPool {
  struct WeekData {
    uint256 TUsers;
    uint256 TAmount;
  }
  struct UserData {
    uint256 LastWithdrawWeek;
    uint256 LastWithdrawAmount;
    uint256 TotalWithdrawAmount;
  }

  uint256 public CurrentWeek; // Current week counter
  uint256 public LastWeekStart; // Timestamp of the start of the last week
  uint256 public NextWeekStart; // Timestamp of the start of the next week
  uint256 public LastDepositWeek; // Week number of the last deposit

  uint256 public TotalAmount; // Total amount deposited
  uint256 public TotalDepositWeek; // Week number of the total deposit when amount was deposited

  mapping(uint256 => mapping(uint8 => WeekData)) public Deposits;
  mapping(address => mapping(uint8 => UserData)) public User;
  mapping(address => mapping(uint8 => bool)) public IsUserExists;

  address public TOKEN;

  constructor(address token) {
    TOKEN = token;

    CurrentWeek = 1; // Initialize current week counter to 1
    LastWeekStart = block.timestamp; // Initialize the timestamp of the start of the last week to the contract deployment time
    NextWeekStart = block.timestamp + 1 weeks; // Calculate the timestamp for the start of the next week
    LastDepositWeek = 0; // Initialize last deposit week to 0

    TotalAmount = 0; // Initialize total amount deposited to 0
    TotalDepositWeek = 0; // Initialize total amount deposited to 0
  }

  function DepositAmount(uint8 level, uint256 amount) external returns (bool) {
    require(amount > 0, "Amount must be greater than zero"); // Check that the deposited amount is greater than 0

    uint256 currentTimestamp = block.timestamp;

    // Check if a new week has started
    if (currentTimestamp >= NextWeekStart) {
      uint256 weeksPassed = (currentTimestamp - LastWeekStart) / 1 weeks; // Calculate the number of weeks passed since the last week start
      CurrentWeek += weeksPassed; // Increment the current week counter by the number of weeks passed
      LastWeekStart += weeksPassed * 1 weeks; // Update the timestamp of the start of the last week
      NextWeekStart += weeksPassed * 1 weeks; // Update the timestamp of the start of the next week
    }

    // Save the amount and update week if necessary
    if (LastDepositWeek != CurrentWeek) {
      LastDepositWeek = CurrentWeek; // Update the last deposit week to the current week
      TotalAmount += amount; // Set the total amount deposited to the new deposit amount

      Deposits[TotalDepositWeek][level] = WeekData({
        TUsers: Deposits[TotalDepositWeek][level].TUsers,
        TAmount: amount
      });

      TotalDepositWeek++;
    } else {
      TotalAmount += amount; // Add the deposit amount to the total amount deposited
      Deposits[TotalDepositWeek][level].TAmount += amount;
    }

    emit Deposit(msg.sender, amount, CurrentWeek); // Emit the deposit event
    return true;
  }

  function AddUser(uint8 level, address userAddr) external returns (bool) {
    if (IsUserExists[userAddr][level]) return false;

    User[userAddr][level] = UserData({
      LastWithdrawWeek: 0,
      LastWithdrawAmount: 0,
      TotalWithdrawAmount: 0
    });
    IsUserExists[userAddr][level] = true;
    Deposits[TotalDepositWeek][level].TUsers++;

    return true;
  }

  function WithdrawAmount(uint8 level, address userAddr) public returns (bool) {
    require(IsUserExists[userAddr][level], "User not exists");
    require(
      User[userAddr][level].LastWithdrawWeek < TotalDepositWeek + 1 &&
        User[userAddr][level].LastWithdrawWeek < 0,
      "It's not time to Withdraw"
    );

    uint256 amount;

    for (
      uint i = User[userAddr][level].LastWithdrawWeek;
      i < TotalDepositWeek;
      i++
    ) {
      amount += calPerc(Deposits[i][level].TAmount, Deposits[i][level].TUsers);
    }

    TotalAmount -= amount;
    User[userAddr][level].LastWithdrawAmount = amount;
    User[userAddr][level].TotalWithdrawAmount += amount;
    User[userAddr][level].LastWithdrawWeek = TotalDepositWeek;

    TransferHelper.safeTransfer(TOKEN, userAddr, amount);

    emit Withdraw(msg.sender, amount, CurrentWeek);
    return true;
  }

  function CheckWithdrawAmount(
    uint8 level,
    address userAddr
  ) public view returns (uint256) {
    uint256 amount;

    for (
      uint i = User[userAddr][level].LastWithdrawWeek;
      i < TotalDepositWeek;
      i++
    ) {
      amount += calPerc(Deposits[i][level].TAmount, Deposits[i][level].TUsers);
    }

    return amount;
  }

  function calPerc(
    uint256 tAmount,
    uint256 tPerc
  ) public pure returns (uint256) {
    uint256 perc = (tAmount * tPerc) / 100;
    return perc;
  }
}