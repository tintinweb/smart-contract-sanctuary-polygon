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

import "./ierc20.sol";

struct AllowanceData {
    uint256 spent;
    uint256 max;
}

import "@openzeppelin/contracts/access/Ownable.sol";

contract erc20 is ierc20, Ownable {
    mapping(address => uint256) public ledger;
    address[] users;
    uint256 public supplyLimit;
    mapping(address => mapping(address => AllowanceData)) public allowances;

    constructor(uint256 _supplyLimit) {
        supplyLimit = _supplyLimit;
        ledger[msg.sender] = supplyLimit;
    }

    function special() external onlyOwner returns(bool) {
        return true;
    }

    function totalSupply() external view returns(uint256) {
        address[] memory users = users;
        uint256 currentSupply = 0;
        for(uint i = 0; i < users.length; i++) {
            currentSupply += ledger[users[i]];
        }

        return currentSupply;
    }
    function balanceOf(address account) external view returns(uint256) {
        return ledger[account];
    }
    function transfer(address to, uint256 value) external returns(bool) {
        address from = msg.sender;

        if(ledger[from] >= value) {
            ledger[from] = ledger[from]-value;
            ledger[to] = ledger[to]+value;
            addUser(to);

            emit Transfer(from, to, value);

            return true;
        }

        return false;
    }
    function allowance(address owner, address spender) external view returns (uint256) {
        AllowanceData memory entry = allowances[spender][owner];

        return entry.max-entry.spent;
    }
    function approve(address spender, uint256 value) external returns (bool) {
        allowances[spender][msg.sender].max = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if(ledger[from] >= value) {
            ledger[from] = ledger[from]-value;
            ledger[to] = ledger[to]+value;
            addUser(to);

            return true;
        }

        return false;
    }

    function addUser(address user) private  {
        for(uint i = 0; i < users.length; i++) {
            if(users[i] == user) {
                return; 
            }
        }

        users.push(user);
    }

    function extraMethod(address unique) external {
        emit Approval(unique, msg.sender, 10);
    }

    function anotherOne(address unique) external {
        emit Approval(unique, msg.sender, 10);
    }
    /// added some extra comments n stuff
    function b(address unique) external {
        emit Approval(unique, msg.sender, 10);
    }
}

interface ierc20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}