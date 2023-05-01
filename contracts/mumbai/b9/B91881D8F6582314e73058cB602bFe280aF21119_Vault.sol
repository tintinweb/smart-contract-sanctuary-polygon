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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    address private _owner;
    IERC20 private _token;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _isSynced;
    uint256 private _withdrawTax;
    address private _taxAddress;

    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);

    constructor(address tokenAddress) {
        _owner = msg.sender;
        _token = IERC20(tokenAddress);
        _withdrawTax = 0;
        _taxAddress = 0x10059c6E3B5129324BDEfe8a0fA47303Cd4EA266;
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero.");
        require(_token.allowance(msg.sender, address(this)) >= amount, "You must first approve the transfer of tokens to this contract.");
        require(_token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        _balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
        _isSynced[msg.sender] = false;
    }

    function sync(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero.");
        require(_balances[msg.sender] >= amount, "Insufficient balance.");
        _balances[msg.sender] -= amount;
        _isSynced[msg.sender] = true;
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero.");
        require(_isSynced[msg.sender], "You must sync your balance first.");
        require(_balances[msg.sender] >= amount, "Insufficient balance.");
        uint256 taxAmount = amount * _withdrawTax / 100;
        require(_token.transfer(_taxAddress, taxAmount), "Tax transfer failed.");
        require(_token.transfer(msg.sender, amount - taxAmount), "Token transfer failed.");
        _balances[msg.sender] -= amount;
        emit Withdrawal(msg.sender, amount);
    }

    function getBalance() public view returns (uint256) {
        return _balances[msg.sender];
    }

    function getBalanceOf(address wallet) public view returns (uint256) {
    return _balances[wallet];
    }

    function setWithdrawTax(uint256 taxAmount, address taxAddress) public {
        require(msg.sender == _owner, "Only the owner can set the withdrawal tax.");
        _withdrawTax = taxAmount;
        _taxAddress = taxAddress;
    }
}