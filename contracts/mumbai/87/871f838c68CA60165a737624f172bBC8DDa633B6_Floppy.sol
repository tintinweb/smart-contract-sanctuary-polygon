/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

// import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
// import "openzeppelin-solidity/contracts/access/Ownable.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
// import "openzeppelin-solidity/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

// This is the main building block for smart contracts.
contract Floppy {
    // Some string type variables to identify the token.
    uint256 private _maxSupply = 1000000000 * 10**18;

    string public name = "Floppy";
    string public symbol = "FLP";

    // The fixed amount of tokens, stored in an unsigned integer type variable.
    uint256 public _totalSupply = 1000000 * 10**18;

    // An address type variable is used to store ethereum accounts.
    address public owner;

    // A mapping is a key/value map. Here we store each account's balance.
    mapping(address => uint256) balances;

    // The Transfer event helps off-chain applications understand
    // what happens within your contract.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * Contract initialization.
     */
    constructor() {
        // constructor(uint256 _maxSupply_, uint256 _totalSupply_) {
        // The totalSupply is assigned to the transaction sender, which is the
        // account that is deploying the contract.
        // _maxSupply = _maxSupply_;
        // _totalSupply = _totalSupply_;
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from *outside*
     * the contract.
     */
    function transfer(address to, uint256 amount) external {
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;

        // Notify off-chain applications of the transfer.
        emit Transfer(msg.sender, to, amount);
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function cap() public view virtual returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
}