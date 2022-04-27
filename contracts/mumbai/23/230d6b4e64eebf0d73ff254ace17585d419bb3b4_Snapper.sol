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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Snapper is Ownable {
    /**
     * @notice snapshot info
     * @param block the block number snapshotted for The Space.
     * @param cid IPFS CID of the snapshot file.
     */
    event Snapshot(uint256 indexed block, string cid);

    /**
     * @notice delta info
     * @param block delta end at this block number, inclusive
     * @param cid IPFS CID of the delta file.
     */
    event Delta(uint256 indexed block, string cid);

    /**
     * @dev store latest snapshot info.
     */
    uint256 private _latestSnapshotBlock;
    string private _latestSnapshotCid;

    /**
     * @notice create Snapper contract, init safeConfirmations and emit initial snapshot.
     * @dev Emits {Snapshot} event.
     * @param theSpaceCreationBlock_ the Contract Creation block number of The Space contract.
     * @param snapshotCid_ the initial pixels picture IPFS CID of The Space.
     */
    constructor(uint256 theSpaceCreationBlock_, string memory snapshotCid_) {
        _latestSnapshotBlock = theSpaceCreationBlock_;
        _latestSnapshotCid = snapshotCid_;

        emit Snapshot(_latestSnapshotBlock, snapshotCid_);
    }

    /**
     * @dev Emits {Snapshot} and {Delta} events.
     * @param lastSnapshotBlock_ last block number snapshotted for The Space. use to validate precondition.
     * @param snapshotBlock_ the block number snapshotted for The Space this time.
     */
    function takeSnapshot(
        uint256 lastSnapshotBlock_,
        uint256 snapshotBlock_,
        string calldata snapshotCid_,
        string calldata deltaCid_
    ) external onlyOwner {
        require(
            lastSnapshotBlock_ == _latestSnapshotBlock,
            "`lastSnapshotBlock_` must be equal to `latestSnapshotBlock` returned by `latestSnapshotInfo`"
        );
        require(
            snapshotBlock_ > _latestSnapshotBlock,
            "`snapshotBlock_` must be greater than `latestSnapshotBlock` returned by `latestSnapshotInfo`"
        );

        _latestSnapshotBlock = snapshotBlock_;
        _latestSnapshotCid = snapshotCid_;

        emit Snapshot(snapshotBlock_, snapshotCid_);
        emit Delta(snapshotBlock_, deltaCid_);
    }

    /**
     * @dev get the lastest snapshot info.
     */
    function latestSnapshotInfo() external view returns (uint256 latestSnapshotBlock, string memory latestSnapshotCid) {
        return (_latestSnapshotBlock, _latestSnapshotCid);
    }
}