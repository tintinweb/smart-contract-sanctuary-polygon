/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// File: contracts/libraries/MapLib.sol


pragma solidity ^0.8.13;

// @author: twitter.com/kilexey

/** 
 * @dev Library for managing map types.
 * Properties:
 * - Set a key-value pair. O(1)
 * - Look up a value. O(1)
 */
library MapLib {

    /**
     * @dev Add a key-value pair to a map.
     * Time complexity: O(1)
     *
     * Returns a boolean value.
     */
    function _set(mapping(string => bytes32) storage map, string memory key, bytes32 value) internal returns (bool) {
        if (!_contains(map, key)) {
            map[key] = value;
            return true;
        } else {
            revert("MapLib: key is already mapped");
        }
    }

    /**
     * @dev Returns true if the key is mapped.
     * Time complexity: O(1)
     */
    function _contains(mapping(string => bytes32) storage map, string memory key) private view returns (bool) {
        return map[key] != 0;
    }

    /**
     * @dev Returns the value of a given key.
     * Time complexity: O(1)
     */
    function _tryGet(mapping(string => bytes32) storage map, string memory key) internal view returns (string memory) {
        return string(abi.encodePacked(map[key]));
    }
}

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

// File: contracts/Storage.sol


pragma solidity ^0.8.13;

// @author: twitter.com/kilexey



contract Storage is Ownable {

    mapping(string => bytes32) private getCID;

    /**
     * @dev Set a mapping of ID to a CID.
     */
    function set(string memory ID, bytes32 CID) public onlyOwner returns (bool) {
        return MapLib._set(getCID, ID, CID);
    }

    /**
     * @dev Returns the CID of a given ID.
     */
    function tryGet(string memory ID) public view returns (string memory) {
        return MapLib._tryGet(getCID, ID);
    }
}