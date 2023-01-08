// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ArraysUint32, ArraysBytes32} from "./lib/ArrayUtils.sol";
import "./access/Ownable2Step.sol";

contract Transfer is Ownable2Step {

    using ArraysUint32 for uint32[];
    using ArraysBytes32 for bytes32[];


    error Transfer_Zero();
    error Transfer_DateInFuture(uint256 timestamp);

    event DataTransferred(uint256 id, bytes32 entityFromHash, bytes32 entityToHash, uint256 timestamp, string dataPublicKey);

    struct DataTransfer {
        uint32 id;
        bytes32 entityFromHash;
        bytes32 entityToHash;
        uint256 timestamp;
        string dataPublicKey;
    }

    mapping(uint32 => DataTransfer) internal _dataTransfers;
    uint32 internal _dataTransferCount = 0;

     function addTransfer(bytes32 _entityFromHash, bytes32 _entityToHash, uint256 _timestamp, string memory _dataPublicKey) external onlyOwner {
        if (_entityFromHash == 0 || _entityToHash == 0) {
            revert Transfer_Zero();
        }

        if (bytes(_dataPublicKey).length == 0) {
            revert Transfer_Zero();
        }

        if (_timestamp > block.timestamp) {
            revert Transfer_DateInFuture(_timestamp);
        }

        _dataTransferCount += 1;

        _dataTransfers[_dataTransferCount] = DataTransfer(_dataTransferCount, _entityFromHash, _entityToHash, _timestamp, _dataPublicKey);

        emit DataTransferred(_dataTransferCount, _entityFromHash, _entityToHash, _timestamp, _dataPublicKey);

     }

     function seeTransfer(uint32 _id) external view returns (DataTransfer memory) {
        return _dataTransfers[_id];
     }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.7.3 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

error Ownable_CallerNotOwner(address caller);
error Ownable_AddressIsZero();

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
        if (owner() != _msgSender()) {
            revert Ownable_CallerNotOwner(_msgSender());
        }
    }

    /**
    *   @dev Returins if the sender is ther owner
    */
    function _isOwner() internal view returns (bool) {
        return owner() == _msgSender();
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * "public -> external" diff from OpenZeppelin version
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable_AddressIsZero();
        } else {
         _transferOwnership(newOwner);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ConsentStruct as c} from "./ConsentStruct.sol";

library ArraysUint32 {

    function filterNotContained(uint32[] memory a, uint32[] memory b) internal pure returns (uint32[] memory) {
        uint32[] memory filtered = new uint32[](a.length);
        uint32 count = 0;

        for (uint32 i = 0; i < a.length; i++) {
            bool isContained = false;

            for (uint32 j = 0; j < b.length; j++) {
                if (a[i] == b[j]) {
                    isContained = true;
                    break;
                }
            }

            if (!isContained) {
                filtered[count] = a[i];
                count++;
            }
        }

        return take(filtered, count);
    }

    function take(uint32[] memory arr, uint32 amount) internal pure returns (uint32[] memory) {
        uint32[] memory tmp = new uint32[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

library ArraysConsent {

    function take(c.Consent[] memory arr, uint32 amount) internal pure returns (c.Consent[] memory) {
        c.Consent[] memory tmp = new c.Consent[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

library ArraysBytes32 {

    function take(bytes32[] memory arr, uint32 amount) internal pure returns (bytes32[] memory) {
        bytes32[] memory tmp = new bytes32[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library ConsentStruct {

    struct Consent {
        uint32 id;
        string name;
        string label;
        bool active;
        bytes32 consentHash;
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