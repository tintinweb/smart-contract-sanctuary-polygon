// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { PageLibrary } from "./libraries/PageLibrary.sol";
import { IRealmBeacon } from "./interfaces/IRealmBeacon.sol";

/// @title RealmBeacon
/// @notice A Beacon with all the references registered.
/// @dev Implementation of IRealmBeacon.
contract RealmBeacon is IRealmBeacon, Ownable {
    /// @notice Main storage of implementations
    mapping(string => address) internal implementations;

    // additional functionality
    /// @notice Array to store all names of non-zero implementations
    string[] internal registeredNames;
    /// @notice Mapping for managing add/remove to the array of registered names
    mapping(string => uint256) internal nameToIndex; // 1-based

    // Region IRealmBeacon

    /// @dev See {IRealmBeacon-getImplementation}
    function getImplementation(string memory _name) public view override returns (address _implementation) {
        return implementations[_name];
    }

    /// @dev See {IRealmBeacon-getNonZeroImplementation}
    function getNonZeroImplementation(string memory _name) public view override returns (address _implementation) {
        address addressToReturn = getImplementation(_name);
        require(addressToReturn != address(0), "Reference was not found.");
        return addressToReturn;
    }

    /// @dev See {IRealmBeacon-getAllReferences}
    /// @dev this might cause gas issues, if array is too big
    function getAllReferences() public view override returns (string[] memory _names, address[] memory _implementations) {
        uint256 size = registeredNames.length;
        uint256 lastIndex = size;
        if (lastIndex > 0) {
            lastIndex--;
        }
        return _readArraysFromStorage(0, lastIndex, size);
    }

    /// @dev See {IRealmBeacon-getPagedReferences}
    function getPagedReferences(uint256 _pageNumber, uint256 _pageSize) external view returns (string[] memory _names, address[] memory _implementations, uint256 _totalCount) {
        _totalCount = registeredNames.length;
        (uint256 startIndex, uint256 lastIndex, uint256 count) = PageLibrary.getPageParameters(_pageNumber, _pageSize, _totalCount);
        (_names, _implementations) = _readArraysFromStorage(startIndex, lastIndex, count);
        return (_names, _implementations, _totalCount);
    }

    /// @dev See {IRealmBeacon-registerImplementation}
    function registerImplementation(string memory _name, address _address) public override onlyOwner {
        address current = implementations[_name];
        address zeroAddress = address(0);

        if (current == zeroAddress && _address != zeroAddress) {
            _addNameToArray(_name);
        } else if (current != zeroAddress && _address == zeroAddress) {
            _removeNameFromArray(_name);
        }
        
        implementations[_name] = _address;

        emit ImplementationRegistered(_name, current, _address);
    }

    // endregion

    // Region private funcs

    function _addNameToArray(string memory _name) private {
        registeredNames.push(_name);
        nameToIndex[_name] = registeredNames.length;
    }

    function _removeNameFromArray(string memory _name) private {
        uint256 _1BasedIndex = nameToIndex[_name];
        uint256 registeredNamesLength = registeredNames.length;

        if (_1BasedIndex != registeredNamesLength) {
            uint256 lastRealIndex = registeredNamesLength - 1;
            string memory lastName = registeredNames[lastRealIndex];

            // switch
            // move the last item to the mid
            registeredNames[_1BasedIndex - 1] = lastName;
            // set new index for the last item
            nameToIndex[lastName] = _1BasedIndex;
        }

        registeredNames.pop();
        delete nameToIndex[_name];
    }

    function _readArraysFromStorage(uint256 _startIndex, uint256 _lastIndex, uint256 _count) private view returns (string[] memory _names, address[] memory _implementations) {
        _names = new string[](_count);
        _implementations = new address[](_count);
        
        if (_count == 0) {
            return (_names, _implementations);
        }

        for (uint256 i = _startIndex; i <= _lastIndex; i++) {
            string memory name = registeredNames[i];
            _names[i - _startIndex] = name;
            _implementations[i - _startIndex] = implementations[name];
        }
        return (_names, _implementations);
    }

    // endregion
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/// @title PageLibrary
/// @notice Library to calculate startIndex, lastIndex, count of items to be returned as a page.
library PageLibrary {
    /// @notice Calculates startIndex, lastIndex, count of items to be returned as a page
    /// @param _pageNumber Number of a page to be queried. 0-based
    /// @param _pageSize Number of items per page. If 0 items are requested, then all items will be returned
    /// @param _itemsCount Number of items in an array of data
    function getPageParameters(uint256 _pageNumber, uint256 _pageSize, uint256 _itemsCount)
    internal
    pure
    returns (uint256 _startIndex, uint256 _lastIndex, uint256 _count) {
        // if 0 items are requested, then all items should be returned
        if (_pageSize == 0) {
            _pageNumber = 0;
            _pageSize = _itemsCount;
        }

        uint256 startIndex = _pageNumber * _pageSize;
        // start index is greater than total amount of tokens, or no tokens exist in array
        if (startIndex >= _itemsCount || _itemsCount == 0) {
            return (0, 0, 0);
        }

        uint256 lastIndex = (_pageNumber + 1) * _pageSize - 1;
        if (lastIndex >= _itemsCount) {
            lastIndex = _itemsCount - 1;
        }

        return(startIndex, lastIndex, lastIndex - startIndex + 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/// @title IRealmBeacon
/// @notice A Beacon interface to register references to smart contracts and then read them.
interface IRealmBeacon {
    /// @notice Event emitted when a reference was added, altered, or removed.
    event ImplementationRegistered(string name, address previous, address current);

    /// @notice Returns an address of an implementation, registered under _name. If no reference is found, returns address(0).
    /// @param _name Unique name of the referenced contract
    function getImplementation(string memory _name) external view returns (address _implementation);
    
    /// @notice Returns an address of an implementation, registered under _name. Reverts with an error message if no reference is found.
    /// @param _name Unique name of the referenced contract
    function getNonZeroImplementation(string memory _name) external view returns (address _implementation);

    /// @notice Returns all existing names and addresses of implementations
    function getAllReferences() external view returns (string[] memory _names, address[] memory _implementations);

    /// @notice Returns a page of existing names and addresses of implementations
    /// @param _pageNumber The number of a page to query, zero-based
    /// @param _pageSize The number of items per page
    function getPagedReferences(uint256 _pageNumber, uint256 _pageSize) external view returns (string[] memory _names, address[] memory _implementations, uint256 _totalCount);
    
    /// @notice Registers implementation _address under given _name.
    /// @param _name Unique name of the referenced contract
    /// @param _address Address of implementation
    function registerImplementation(string memory _name, address _address) external;
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