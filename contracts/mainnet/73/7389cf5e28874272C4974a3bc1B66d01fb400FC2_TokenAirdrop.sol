/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


/** @title Token Airdrop . */
contract TokenAirdrop {

    // Event for logging the successful transfer of eQuad
    event Airdropped(address recipient, uint256 weiSent);

    // The Airdrop function required the exact amount or more to be approved by the user to be spend by the contract on the same chain
    /** @dev batch send token to multiple recipients.
     *  @param _tokenAddress address of the token smart contract on the same chain as the contract.
     *  @param _recipients array of the recipients to which the tokens are to be sent.
     *  @param _amount array of the amounts to be sent in order.
     */
    function airdrop(
        address _tokenAddress,
        address[] memory _recipients,
        uint256[] memory _amount
    ) public returns (bool) {
        uint256 totalBalance;

        // Check for the mismatiching arguments
        require(
            _recipients.length == _amount.length,
            "Length for recipients and amounts does not match."
        );

        // Getting the total amount of tokens to be spent by the contract
        for (uint256 _i; _i < _amount.length; _i++)
            totalBalance = totalBalance + _amount[_i];

        // Check for the spend allowance approved by the user on the token contract
        require(
            IERC20(_tokenAddress).allowance(
            msg.sender,
            address(this)
        ) >= totalBalance,
            "the total allowed tokens are not equal to the sent token"
        );

        // checking the balance of the user
        require(
            IERC20(_tokenAddress).balanceOf(msg.sender) >= totalBalance,
            "Balance is less than allowed amount"
        );

        // spending the token and transferring it to the recipients directly from the user account
        for (uint256 _i; _i < _recipients.length; _i++) {
            IERC20(_tokenAddress).transferFrom(msg.sender, _recipients[_i], _amount[_i]);
            emit Airdropped(_recipients[_i], _amount[_i]);
        }
        return true;
    }
}