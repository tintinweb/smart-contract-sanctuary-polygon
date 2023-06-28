/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SYNC 3.14 Token
 * @dev This contract implements the SYNC314 token, which is an investment confirmation token.
 *      Each token represents an investment confirmation and has a value of $0.1.
 *      sync314.com
 */
contract SYNC314 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * (10 ** 18);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "SYNC 3.14";
        symbol = "SYNC314";
        decimals = 18;
        totalSupply = MAX_SUPPLY;
        balanceOf[msg.sender] = MAX_SUPPLY;
    }

    /**
     * @dev Transfers tokens from the sender's account to the specified address.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful or not.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    /**
     * @dev Sets the allowance for the spender to transfer tokens from the sender's account.
     * @param spender The address allowed to spend the sender's tokens.
     * @param value The amount of tokens to allow.
     * @return A boolean value indicating whether the approval was successful or not.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev Transfers tokens from one address to another.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful or not.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Transfers tokens to multiple addresses.
     * @param recipients The addresses to transfer tokens to.
     * @param amounts The amounts of tokens to transfer to each address.
     * @return A boolean value indicating whether the batch transfer was successful or not.
     */
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external returns (bool) {
        require(recipients.length == amounts.length, "Invalid input");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            totalAmount += amounts[i];
        }

        require(balanceOf[msg.sender] >= totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            balanceOf[msg.sender] -= amounts[i];
            balanceOf[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }

        return true;
    }

    /**
     * @dev Returns the token information.
     * @return The token's name, symbol, decimals, and total supply.
     */
    function getTokenInformation() external view returns (string memory, string memory, uint8, uint256) {
        return (name, symbol, decimals, totalSupply);
    }
}