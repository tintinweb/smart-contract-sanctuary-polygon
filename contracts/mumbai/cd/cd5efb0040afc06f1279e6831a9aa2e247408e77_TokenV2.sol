/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: Testtoken.sol


pragma solidity 0.8.9;


contract TokenV2 is Ownable {
  uint256 public totalSupply;
  string public name = "Testing Token";
  string public symbol = "FDTBT";
  uint8 public decimals = 18;

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) private allowances;

  constructor(uint256 initialSupply) {
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
  }

  
  function transfer(address recipient, uint256 amount) external {
    require(recipient != address(0), "ERC20: transfer from the zero address");
    require(balances[msg.sender] >= amount, "Not enough balance");

    balances[msg.sender] -= amount;
    balances[recipient] += amount;
  }

  function approve(address spender, uint256 amount) external {
    require(spender != address(0), "ERC20: approve to the zero address");

    allowances[msg.sender][spender] = amount;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool) {
    require(allowances[sender][msg.sender] >= amount, "ERC20: amount exceeds allowance");
    require(balances[sender] >= amount, "Not enough balance");

    allowances[sender][msg.sender] -= amount;

    balances[sender] -= amount;
    balances[recipient] += amount;

    return true;
  }

  function mint(uint256 amount) external onlyOwner {
    totalSupply += amount;
    balances[owner()] += amount;
  }

  function burn(address account, uint256 amount) external onlyOwner {
    totalSupply -= amount;
    balances[account] -= amount;
  }

  /* --- Getters --- */

  function balanceOf(address account) public view returns (uint256) {
    return balances[account];
  }

  function allowanceOf(address balanceOwner, address spender) public view virtual returns (uint256) {
    return allowances[balanceOwner][spender];
  }
}