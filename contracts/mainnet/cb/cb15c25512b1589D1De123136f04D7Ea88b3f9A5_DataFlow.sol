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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./access/Managers.sol";

/**
 * @title Data Lake Data Flow Contract
 */
contract DataFlow is Managers {
    error DataFlow_PublicKeyZero();
    error DataFlow_DateInFuture(uint256 timestamp);

    enum DataFlowTypes {
        TO_FOUNDATION,
        FROM_FOUNDATION
    }

    event DataFlow_DataTransferred(uint256 id, uint256 timestamp, uint8 dataFlowType, string dataPublicKey);

    struct DataFlow {
        uint32 id;
        uint256 timestamp;
        uint8 dataFlowType;
        string dataPublicKey;
    }

    mapping(uint32 => DataFlow) internal _dataFlows;
    mapping(string => DataFlow) internal _dataFlowsByKey;

    uint32 internal _dataFlowsCount = 0;

    function addDataFlow(
        uint256 _timestamp,
        uint8 _dataFlowType,
        string memory _dataPublicKey
    ) external onlyManagerOROwner {
        if (bytes(_dataPublicKey).length == 0 && _dataFlowType == uint256(DataFlowTypes.FROM_FOUNDATION)) {
            revert DataFlow_PublicKeyZero();
        }

        if (_timestamp > block.timestamp) {
            revert DataFlow_DateInFuture(_timestamp);
        }

        _dataFlowsCount += 1;

        _dataFlows[_dataFlowsCount] = DataFlow(_dataFlowsCount, _timestamp, _dataFlowType, _dataPublicKey);
        _dataFlowsByKey[_dataPublicKey] = DataFlow(_dataFlowsCount, _timestamp, _dataFlowType, _dataPublicKey);

        emit DataFlow_DataTransferred(_dataFlowsCount, _timestamp, _dataFlowType, _dataPublicKey);
    }

    function seeDataFlowByID(uint32 _id) external view returns (DataFlow memory) {
        return _dataFlows[_id];
    }

    function seeDataFlowByKey(string calldata _key) external view returns (DataFlow memory) {
        return _dataFlowsByKey[_key];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Ownable2Step.sol";

error Managers_Error(string msg);

/**
 * @title Managers Contract
 */
abstract contract Managers is Ownable2Step {
    event ManagerChanged(address indexed previousManager, address indexed newManager);

    address private _manager;

    constructor() {
        _setManager(_msgSender());
    }

    modifier onlyManagerOROwner() {
        if (_msgSender() != manager() && _msgSender() != owner()) {
            revert Managers_Error("Caller is not the manager or owner!");
        }
        _;
    }

    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Sets manager.
     */
    function setManager(address newManager) public virtual onlyOwner {
        if (newManager == address(0)) {
            revert Managers_Error("New manager is a zero address!");
        }
        _setManager(newManager);
    }

    /**
     * @dev Sets blacklist manager.
     * Internal function without access restriction.
     */
    function _setManager(address newManager) internal virtual {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagerChanged(oldManager, newManager);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

error Ownable_Error(string msg);

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
            revert Ownable_Error("Caller is not the owner!");
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable_Error("New owner is a zero address!");
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity 0.8.9;

import "./Ownable.sol";

error Ownable2Step_Error(string msg);

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
        if (newOwner == address(0)) {
            revert Ownable2Step_Error("New owner is a zero address!");
        }
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
        if (pendingOwner() != sender) {
            revert Ownable2Step_Error("Caller is not the new owner!");
        }
        _transferOwnership(sender);
    }
}