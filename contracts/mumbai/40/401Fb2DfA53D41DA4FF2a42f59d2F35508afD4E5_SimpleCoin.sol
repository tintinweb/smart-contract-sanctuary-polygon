// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20Interface {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @dev Returns a boolean value indicating whether the operation succeeded.
     * @dev Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract SimpleCoin is ERC20Interface {
    // This is just for tests, does not fully implement ERC20, only methods we need.
    mapping(address => uint256) private balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function giveBalance(address account, uint256 amount) external {
        balances[account] = amount;
    }

    // Below are the two functions we need to provide for tests
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        if (
            balances[msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient] &&
            amount != 42
        ) {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
            return true;
        } else {
            return false;
        }
    }
}