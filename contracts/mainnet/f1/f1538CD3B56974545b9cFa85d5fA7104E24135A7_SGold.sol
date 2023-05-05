/**
 *Submitted for verification at Polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// SGold - a crypto token that emits the price of gold. 
// SGold - this token is a typical stable representation of the real virtual gold price in US dollars.
// SGold - otherwise Smart Gold.
// SGold - designed so that everyone can have "Virtual Smart Gold" on their cryptocurrency wallet in a simple, fast and secure way.
// SGold - our project allows you to make a transaction via SGold crypto-token as the equivalent of 1:1 the price of physical gold given in the United States Dollar.

// Importing external contracts
import "./Ownable.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SGoldDraw.sol";
import "./MultiSigWallet.sol";
import "./ModificationFunction.sol";
import "./SetSGoldPrice.sol";
import "./EmergencyStopOwner.sol";

contract SGold {
    // Token metadata
    string public name = "SGold";
    string public symbol = "SGOLD";
    uint8 public decimals = 18; 
    uint256 public totalSupply = 100000000 * 10 ** decimals; // maximum number of SGold token pool

    // Token distribution
    uint256 public pool;
    uint256 public monthlySupply = 500000 * 10 ** decimals; // monthly number of tokens added to the general pool of SGold
    uint256 public lastSupplyDate;

    // Ownership and account blocking
    address public owner;
    mapping(address => bool) public ownerships;
    mapping(address => bool) public blocked;

    // Balances
    mapping(address => uint256) balances;

    constructor() {
    pool = 30000000 * 10 ** decimals; // the starting number of SGold tokens released
    owner = msg.sender;
    balances[msg.sender] = pool;
    emit Transfer(address(0), msg.sender, pool);
    }

    // Get token balance of an address
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    // Transfer tokens from sender to recipient
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(!blocked[msg.sender], "Account is blocked");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // Burn tokens by sender, reducing total supply and pool
    function burn(uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        pool -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        return true;
    }

    // Supply monthly tokens to the owner
    function supplyMonthly() public returns (bool) {
        require(ownerships[msg.sender], "Only contract owner can call this function");
        require(block.timestamp - lastSupplyDate >= 30 days, "Monthly supply not yet due");

        uint256 newSupply = monthlySupply;
        if (pool + monthlySupply > totalSupply) {
            newSupply = totalSupply - pool;
        }

        pool += newSupply;
        balances[owner] += newSupply;
        lastSupplyDate = block.timestamp;

        emit Supply(newSupply);
        return true;
    }

    /**
     * @dev Transfers ownership of the contract to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public {
        require(ownerships[msg.sender], "Only contract owner can call this function");
        require(newOwner != address(0), "Invalid new owner address");

        owner = newOwner;

        emit OwnershipTransferred(newOwner);
    }

    /**
     * @dev Adds ownership of the contract to a new owner
     * @param newOwner The address of the new owner
     */
    function addOwnership(address newOwner) public {
        require(ownerships[msg.sender], "Only contract owner can call this function");
        require(newOwner != address(0), "Invalid new owner address");

        ownerships[newOwner] = true;

        emit OwnershipAdded(newOwner);
    }

    /**
     * @dev Removes ownership of the contract from an owner
     * @param ownerToRemove The address of the owner to remove
     */
    function removeOwnership(address ownerToRemove) public {
        require(ownerToRemove != address(0), "Invalid owner address");
        require(ownerships[msg.sender], "Only contract owner can call this function");
        require(ownerToRemove != owner, "Cannot remove contract owner");

        ownerships[ownerToRemove] = false;

        emit OwnershipRemoved(ownerToRemove);
    }

    /**
      * @dev Blocks an account from making transfers
     */
    function blockAccount() public {
        require(balanceOf(msg.sender) > 0, "Account balance is zero");

        blocked[msg.sender] = true;

        emit AccountBlocked(msg.sender);
    }

    /**
     * @dev Unblocks an account from making transfers
     */
    function unblockAccount() public {
        blocked[msg.sender] = false;
    }

    // Events

    /**
     * @dev Emitted when tokens are transferred from one address to another
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param value The amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev Emitted when tokens are burned from an address
     * @param from The address tokens are burned from
     * @param value The amount of tokens burned
     */
    event Burn(address indexed from, uint256 value);
    
    /**
     * @dev Emitted when the total supply of tokens is updated
     * @param value The updated total supply of tokens
     */
    event Supply(uint256 value);
    
    /**
     * @dev Emitted when ownership of the contract is transferred to a new owner
     * @param newOwner The address of the new owner
     */
    event OwnershipTransferred(address indexed newOwner);
    
    /**
     * @dev Emitted when ownership of the contract is added to a new owner
     * @param newOwner The address of the new owner
     */
    event OwnershipAdded(address indexed newOwner);
    
    /**
     * @dev Emitted when ownership of the contract is removed from an owner
     * @param ownerToRemove The address of the owner being removed
      */
    event OwnershipRemoved(address indexed ownerToRemove);
    
    /**
     * @dev Emitted when an account is blocked from making transfers
     * @param account The address of the blocked account
     */
    event AccountBlocked(address indexed account);
}