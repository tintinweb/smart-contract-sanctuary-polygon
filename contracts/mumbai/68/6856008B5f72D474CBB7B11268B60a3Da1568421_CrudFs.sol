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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './unorderedKeySetLib.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @title CrudFs Contract
/// @author Alex Miller
/// @notice This contract is a simple file system for storing files on IPFS.
/// @dev This contract is not tested or audited. Do not use for production.

// SPECULATIVE LIFTS:
// TODO: Store CIDs in a more efficient way, maybe bytes32?
// TODO: Add a requirement that checks if CIDs are valid IPFS CIDs, replace isEmpty checks
// TODO: Store a CID to a JSON file that contains the metadata for the file, to save space
// TODO: Store a CID that references a JSON file or SQL database that contains all data in the contract

contract CrudFs is Ownable {
  // Use the UnorderedKeySetLib library for managing our file objects
  using UnorderedKeySetLib for UnorderedKeySetLib.Set;
  UnorderedKeySetLib.Set fileSet;

  /// A File struct that'd designed to be indexed by the hash of the file's path
  struct FileStruct {
    // The file's path on the file system
    string path;
    // The file's CID
    string cid;
    // When last updated
    uint256 timestamp;
    // The file's metadata -- this is a JSON string. Be responsible with the size of this.
    string metadata;
  }

  // A mapping that maps a hash of a file's path to a FileStruct
  mapping(bytes32 => FileStruct) files;

  // Events (Not sure if I want to emit Metadata yet)
  event CreateFile(
    bytes32 indexed key,
    uint256 indexed timestamp,
    string cid,
    string metadata
  );
  event UpdateFile(
    bytes32 indexed key,
    uint256 indexed timestamp,
    string cid,
    string metadata
  );
  event DeleteFile(bytes32 key);

  /// Public C.R.U.D. Functions

  // C is for 'Create'

  // Create a new file
  function createFile(
    string memory path,
    string memory cid,
    string memory metadata
  ) public onlyOwner {
    // Require that the path and cid are not empty
    require(bytes(path).length > 0, 'Path cannot be empty');
    require(bytes(cid).length > 0, 'CID cannot be empty');

    // Hash the path to get the key, revert if the file already exists
    bytes32 key = keccak256(abi.encodePacked(path));
    require(!fileSet.exists(key), 'File already exists.');

    // Insert the key into the fileSet
    fileSet.insert(key);
    FileStruct storage f = files[key];
    f.path = path;
    f.cid = cid;
    f.timestamp = block.timestamp;
    f.metadata = metadata;

    // Emit an event
    emit CreateFile(key, block.timestamp, cid, metadata);
  }

  // R is for 'Read'

  // Read a file by its key
  function readFile(
    bytes32 key
  )
    public
    view
    returns (
      string memory path,
      string memory cid,
      uint256 timestamp,
      string memory metadata
    )
  {
    // Revert if the file doesn't exist
    require(fileSet.exists(key), 'File does not exist.');
    FileStruct storage f = files[key];
    return (f.path, f.cid, f.timestamp, f.metadata);
  }

  // Read Multiple Files by their keys
  function readFiles(
    bytes32[] memory keys
  )
    public
    view
    returns (
      string[] memory paths,
      string[] memory cids,
      uint256[] memory timestamps,
      string[] memory metadata
    )
  {
    uint256 count = keys.length;
    // Initialize arrays for the struct members
    paths = new string[](count);
    cids = new string[](count);
    timestamps = new uint256[](count);
    metadata = new string[](count);
    // Loop through the keys and populate the arrays
    for (uint256 i = 0; i < count; i++) {
      // Revert if the file doesn't exist
      require(fileSet.exists(keys[i]), 'File does not exist.');
      FileStruct storage f = files[keys[i]];
      paths[i] = f.path;
      cids[i] = f.cid;
      timestamps[i] = f.timestamp;
      metadata[i] = f.metadata;
    }
    return (paths, cids, timestamps, metadata);
  }

  // Read the count of files
  function readFileCount() public view returns (uint256 count) {
    return fileSet.count();
  }

  // Read a file key at an index
  function readFileKeyAtIndex(uint256 index) public view returns (bytes32 key) {
    require(index < fileSet.count(), 'Index out of bounds.');
    return fileSet.keyAtIndex(index);
  }

  // Read a file by its index
  function readFileAtIndex(
    uint256 index
  )
    public
    view
    returns (
      string memory path,
      string memory cid,
      uint256 timestamp,
      string memory metadata
    )
  {
    require(index < fileSet.count(), 'Index out of bounds.');
    bytes32 key = fileSet.keyAtIndex(index);
    FileStruct storage f = files[key];
    return (f.path, f.cid, f.timestamp, f.metadata);
  }

  // Read all file keys in an array
  function readAllFileKeys() public view returns (bytes32[] memory keys) {
    uint256 count = fileSet.count();
    keys = new bytes32[](count);
    for (uint256 i = 0; i < count; i++) {
      keys[i] = fileSet.keyAtIndex(i);
    }
    return keys;
  }

  // Read all files. Return struct members as a tuple of arrays. Optional request to include keys and metadata.
  function readAllFiles()
    public
    view
    returns (
      string[] memory paths,
      string[] memory cids,
      uint256[] memory timestamps,
      string[] memory metadata
    )
  {
    uint256 count = fileSet.count();
    // Initialize arrays for the struct members
    paths = new string[](count);
    cids = new string[](count);
    timestamps = new uint256[](count);
    metadata = new string[](count);
    // Loop through the keys and populate the arrays
    for (uint256 i = 0; i < count; i++) {
      bytes32 key = fileSet.keyAtIndex(i);
      FileStruct storage f = files[key];
      paths[i] = f.path;
      cids[i] = f.cid;
      timestamps[i] = f.timestamp;
      metadata[i] = f.metadata;
    }
    return (paths, cids, timestamps, metadata);
  }

  // U is for 'Update'

  // Update a file
  function updateFile(
    bytes32 key,
    string memory cid,
    string memory metadata
  ) public onlyOwner {
    // Revert if the file doesn't exist
    require(fileSet.exists(key), 'File does not exist.');

    FileStruct storage f = files[key];
    f.cid = cid;
    f.timestamp = block.timestamp;
    f.metadata = metadata;

    // Emit an event
    emit UpdateFile(key, block.timestamp, cid, metadata);
  }

  // D is for 'Delete'

  // Delete a file
  function deleteFile(bytes32 key) public onlyOwner {
    require(fileSet.exists(key), 'File does not exist.');
    fileSet.remove(key);
    delete files[key];
    emit DeleteFile(key);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title UnorderedKeySet Library
/// @author Rob Hitchens
/// @notice Library for managing CRUD operations in dynamic key sets.
/// @dev This library is not tested or audited. Do not use for production.
/// @dev Much thanks to Rob Hitchens for this library.

/*
    Hitchens UnorderedKeySet v0.93

    Library for managing CRUD operations in dynamic key sets.
    https://github.com/rob-Hitchens/UnorderedKeySet

    Copyright (c), 2019, Rob Hitchens, the MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

// Sorry Rob, I renamed the library to UnorderedKeySetLib
library UnorderedKeySetLib {
  // Our core Set struct
  struct Set {
    // Maps keys to their index in the keyList
    mapping(bytes32 => uint) keyPointers;
    // List of keys in the set
    bytes32[] keyList;
  }

  // Insert a key into the set
  function insert(Set storage self, bytes32 key) internal {
    require(key != 0x0, 'UnorderedKeySet(100) - Key cannot be 0x0');
    require(
      !exists(self, key),
      'UnorderedKeySet(101) - Key already exists in the set.'
    );
    self.keyList.push(key);
    self.keyPointers[key] = self.keyList.length - 1;
  }

  // Remove a key from the set
  function remove(Set storage self, bytes32 key) internal {
    require(
      exists(self, key),
      'UnorderedKeySet(102) - Key does not exist in the set.'
    );
    bytes32 keyToMove = self.keyList[count(self) - 1];
    uint rowToReplace = self.keyPointers[key];
    self.keyPointers[keyToMove] = rowToReplace;
    self.keyList[rowToReplace] = keyToMove;
    delete self.keyPointers[key];
    self.keyList.pop();
  }

  // Return the number of keys in the set
  function count(Set storage self) internal view returns (uint) {
    return (self.keyList.length);
  }

  // Check if a key exists in the set
  function exists(Set storage self, bytes32 key) internal view returns (bool) {
    if (self.keyList.length == 0) return false;
    return self.keyList[self.keyPointers[key]] == key;
  }

  // Return the key at a given index
  function keyAtIndex(
    Set storage self,
    uint index
  ) internal view returns (bytes32) {
    return self.keyList[index];
  }

  // Delete the entire set
  function nukeSet(Set storage self) public {
    delete self.keyList;
  }
}