// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC20 Simple Token
/// @author Arthur Gonçalves Breguez
/// @notice Use this contract only to simulate porpuses

contract ERC20Token is Ownable {
   
    /// @notice Track amount of tokens of each account
    mapping (address => uint256) private balanceOf;   
    /// @notice Track the amount of tokens an address can spend on behalf the owner of the tokens
    mapping(address => mapping(address => uint256)) private allowance;

    string private name;
    string private symbol;
    uint8 private decimals = 18;
    uint256 private totalSupply = 1000000 ether;
    uint256 private currentSupply = 100 * (uint256(10) ** decimals);

    /// @notice Emit an event when a transfer is made
    event Transfer(address indexed from, address indexed to, uint256 value);
    /// @notice Emit an event when an approval for allowance is made
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier mintable(uint256 amount) {
        require(amount+currentSupply <= totalSupply);
        _;
    }

    /// @notice Transfer all inicial supply to the token creator
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        balanceOf[msg.sender] = currentSupply;
        emit Transfer(address(0), msg.sender, currentSupply);
    }

    /// @notice Show the token name
    function tokenName() public view returns(string memory) {
        return name;
    }

    /// @notice Show the token symbol
    function tokenSymbol() public view returns(string memory) {
        return symbol;
    }

    /// @notice Show the token number of decimals
    function tokenDecimals() public view returns(uint8) {
        return decimals;
    }

    /// @notice Show the token current supply
    function tokenCurrentSupply() public view returns(uint256) {
        return currentSupply;
    }

    /// @notice Show the token total supply
    function tokenTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    /// @notice Show the ammount of tokens of the account
    /// @param _address Account address
    /// @return Address token balance
    function accountBalance(address _address) external view returns(uint256) {
        return balanceOf[_address];
    }

    /// @notice Show the amount of tokens the account can spend on behalf of the owner
    /// @param _spender The spender of the tokens account
    /// @return The amount of tokens the account can spend
    function accountAllowance(address _owner ,address _spender) external view returns(uint256) {
        return allowance[_owner][_spender];
    }
    /// @notice Transfer user tokens to an address
    /// @param _to The account that tokens will be transfered
    /// @param _value The amount of tokens in (arrumar isso!!!)
    /// @return success If tokens has been transfered
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough tokens!");
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;          
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Approve an address to spend tokens on behalf of the function caller (msg.sender)
    /// @param _spender Address of the spender
    /// @param _value Amount of tokens the spender account can move
    /// @return success If an account was approved to spend tokens
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Spend tokens from the owner (of the tokens) account
    /// @param _from Account owner of the tokens
    /// @param _value Amount of tokens to be transfered
    /// @return success If tokens has been transfered on behalf of the owner
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "Not enought balance!");
        require(_value <= allowance[_from][msg.sender], "You don't have the permission to spend this amount of tokens");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Mint tokens to an account
    /// @param _to Address that tokens will be minted
    /// @param _amount Amount of tokens that will be minted
    function mint(address _to, uint256 _amount) external onlyOwner mintable(_amount) returns (bool success){
        require(_to != address(0), "Cannot mint to the zero address");
        currentSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        return true;
    }
    
    /// @notice Burn tokens from an account
    /// @param _from Address that tokens will be burned
    /// @param _amount Amount of tokens that will be burned
    function burn(address _from, uint256 _amount) external onlyOwner returns(bool success){
        require(_from != address(0), "Address cannot be zero");
        uint256 balance = balanceOf[_from];
        require(balance >= _amount, "Cannot burn more than the address has");
        balanceOf[_from] -= _amount;
        currentSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
        return true;
    }
}