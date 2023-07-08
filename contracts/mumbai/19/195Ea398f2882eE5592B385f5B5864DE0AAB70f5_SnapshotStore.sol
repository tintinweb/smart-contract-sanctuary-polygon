pragma solidity ^0.8.6;

import '../interfaces/ISnapshotStore.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract SnapshotStore is ISnapshotStore, Ownable {
  uint256 private nextPartIndex = 1;
  uint256 private latestBlockNumber = 0;
  mapping(uint256 => Snapshot) private partsList;
  mapping(uint256 => uint256) private tokenIdToSnapshot;
  mapping(uint256 => uint256) private tokenIdToVp;

  address public minter ;

  ////////// modifiers //////////
  modifier onlyMinterOrOwner() {
    require(owner() == _msgSender() || minter == _msgSender(), "Not owner or minter");
    _;
  }

  function register(Snapshot memory _snapshot) external onlyMinterOrOwner returns (uint256) {
    if (latestBlockNumber < _snapshot.end) {
      latestBlockNumber = _snapshot.end;
    }
    partsList[nextPartIndex] = _snapshot;
    nextPartIndex++;
    return nextPartIndex - 1;
  }

  function currentBlockNumber() external view returns (uint256) {
    return latestBlockNumber;
  }

  function setCurrentBlockNumber(uint256 _blockNumber) external onlyOwner {
    latestBlockNumber = _blockNumber;
  }

  function setMinter(address _minter) external onlyOwner {
    minter = _minter;
  }
  function setSnapshot(uint256 tokenId, uint256 snapshotId, uint256 vp) external onlyMinterOrOwner {
    tokenIdToSnapshot[tokenId] = snapshotId;
    tokenIdToVp[tokenId] = vp;
  }

  function getSnapshot(uint256 index) external view returns (Snapshot memory output) {
    output = partsList[tokenIdToSnapshot[index]];
  }

  function getTitle(uint256 index) external view returns (string memory output) {
    output = partsList[tokenIdToSnapshot[index]].title;
  }

  function getVp(uint256 index) external view returns (uint256 vp) {
    vp = tokenIdToVp[index];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ISnapshotStore {
  struct Snapshot {
    string id;
    string title;
    string choices;
    string scores;
    uint256 start;
    uint256 end;
  }

  function register(Snapshot memory snapshot) external returns (uint256);

  function currentBlockNumber() external returns (uint256);

  function setSnapshot(uint256 tokenId, uint256 snapshotId, uint256 vp) external;

  function getSnapshot(uint256 index) external view returns (Snapshot memory output);

  function getTitle(uint256 index) external view returns (string memory output);

  function getVp(uint256 index) external view returns (uint256 vp);
}

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