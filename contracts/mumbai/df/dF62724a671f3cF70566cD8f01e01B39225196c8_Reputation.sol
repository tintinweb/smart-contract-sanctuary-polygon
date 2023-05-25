// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Reputation is Ownable {

    uint256 public constant MIN_SCORE = 1 ether;
    uint256 public constant MAX_SCORE = 10 ether;

    struct User {
        uint256 score;
        uint256 cnt;
    }

    /**
     * @dev Array of addresses that are authorized to write transactions.
     */
    mapping(address => bool) public whitelist;

    /**
     * @dev Mapping of address reputation.
     */
    mapping(address => User) public reputation;

    /**
     * @dev Only authorized addresses can call a function with this modifier.
     */
    modifier onlyAuthorized() {
        require(
            whitelist[msg.sender] || owner() == msg.sender,
            "Not authorized"
        );
        _;
    }

    function addScore(
        address _user,
        uint256 _score
    ) external onlyAuthorized {
        _score = _score / MIN_SCORE * MIN_SCORE; // allow only whole numbers 1 ether, 2 ether, ...., 10 ether
        require(
            _score >= MIN_SCORE && _score <= MAX_SCORE, 
            "Invalid score"
        );

        User memory userRep = reputation[_user];
        if (userRep.cnt == 0) {
            reputation[_user].score = _score;
        } else {
            reputation[_user].score = (userRep.score * userRep.cnt + _score) / (userRep.cnt + 1);
        }
        reputation[_user].cnt += 1;
    }

    function whitelistAddresses(address[] calldata _list, bool _whitelist) external onlyOwner {
        for (uint256 i = 0; i < _list.length; i++) {
            whitelist[_list[i]] = _whitelist;
        }
    }
}