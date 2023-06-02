/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}


// File contracts/IncrementBalance.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract IncrementBalance {
    address private owner;
    address private maticTokenAddress;

    event BalanceIncremented(uint256 newValue);
    event MaticDeposited(address indexed account, uint256 amount);
    event MaticWithdrawn(address indexed account, uint256 amount);

    constructor(address _maticTokenAddress) public{
        owner = msg.sender;
        maticTokenAddress = _maticTokenAddress;
    }

    function incrementBalance() public {
        uint256 currentBalance = IERC20(maticTokenAddress).balanceOf(msg.sender);
        require(currentBalance > 0, "Insufficient MATIC balance");

        IERC20(maticTokenAddress).transferFrom(
            msg.sender,
            address(this),
            currentBalance
        );

        emit BalanceIncremented(currentBalance);
    }

    function depositMatic(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");

        IERC20(maticTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit MaticDeposited(msg.sender, amount);
    }

    function withdrawMatic() public {
        require(msg.sender == owner, "Only the contract owner can call this function");

        uint256 balance = IERC20(maticTokenAddress).balanceOf(address(this));
        require(balance > 0, "Contract has no MATIC balance");

        IERC20(maticTokenAddress).transfer(owner, balance); 
        emit MaticWithdrawn(owner, balance);
    }
}