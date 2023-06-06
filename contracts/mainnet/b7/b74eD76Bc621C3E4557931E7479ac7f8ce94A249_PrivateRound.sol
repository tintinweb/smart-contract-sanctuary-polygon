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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PrivateRound {
    // Address of the ERC20 token contract
    address private _tokenAddress;

    // Recipient address
    address private _recipient;

    // Minimum amount to transfer (in 18 decimal points, 6 decimal for Tether)
    uint256 private _minAmount;

    // Mapping to store the user deposits
    mapping(address => uint256) private _userDeposits;

    constructor(address tokenAddress, address recipient, uint256 minAmount) {
        _tokenAddress = tokenAddress;
        _recipient = recipient;
        _minAmount = minAmount;
    }

    /**
     * @notice Transfer ERC20 tokens from the sender to the specified recipient address
     * @param amount The amount of tokens to transfer (in 18 decimal points)
     * @return True if the transfer is successful, false otherwise
     */
    function buySTR(uint256 amount) external returns (bool) {
        require(amount >= _minAmount, "Amount must be greater than or equal to the minimum amount");

        // Create an instance of the ERC20 token contract
        IERC20 token = IERC20(_tokenAddress);

        // Transfer tokens from the sender to the recipient
        bool success = token.transferFrom(msg.sender, _recipient, amount);

        if (success) {
            // Update the user deposit
            _userDeposits[msg.sender] += amount;
        }

        return success;
    }

    /**
     * @notice Get the total deposit amount of a user
     * @param user The address of the user
     * @return The total deposit amount of the user
     */
    function getUserDeposit(address user) external view returns (uint256) {
        return _userDeposits[user];
    }
}