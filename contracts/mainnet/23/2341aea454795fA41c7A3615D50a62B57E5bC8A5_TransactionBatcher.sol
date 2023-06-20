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
pragma solidity ^0.8.0;

import "../../util/core/TieredOwnership.sol";
import "../interfaces/ITransactionBatcher.sol";

/**
 * @title Batcher
 * @author Amir Shirif, Telcoin, LLC.
 * @notice groups multiple transactions together
 */
contract TransactionBatcher is ITransactionBatcher, TieredOwnership {
    event Transaction(uint256 indexed index, address indexed wallet);

    /**
     * @notice sends a grouping of transactions
     * @param wallets an array of destinations
     * @param payloads the data to be distributed
     * @param values the values to be distributed
     */
    function batch(
        address[] memory wallets,
        bytes[] memory payloads,
        uint256[] memory values
    ) external payable override onlyOwner {
        require(
            wallets.length == payloads.length &&
                payloads.length == values.length,
            "TransactionBatcher: arrays must be of equal length"
        );

        uint256 size = wallets.length;

        for (uint256 i = 0; i < size; i++) {
            (bool success, ) = wallets[i].call{value: values[i]}(payloads[i]);
            require(success, "Transaction failed");
            emit Transaction(i, wallets[i]);
        }

        require(
            address(this).balance == 0,
            "TransactionBatcher: must have zero balance after execution"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransactionBatcher {
    /**
     * @notice sends a grouping of transactions
     * @param wallets an array of destinations
     * @param payloads the data to be distributed
     * @param values the values to be distributed
     */
    function batch(
        address[] memory wallets,
        bytes[] memory payloads,
        uint256[] memory values
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implements Openzeppelin Audited Contracts
 * @dev Contract module a sole executor responsible for adding and removing owners
 * @dev Contract module which provides a basic access control mechanism, where
 * there is a variable number of accounts (owners) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owners.
 */
abstract contract TieredOwnership is Context {
    address private _executor;
    address private _nominatedExecutor;
    mapping(address => bool) private _owners;

    event ExecutorNominated(address indexed newExecutor);
    event ExecutorChanged(
        address indexed oldExecutor,
        address indexed newExecutor
    );
    event OwnershipAdded(address indexed newOwner);
    event OwnershipRemoved(address indexed oldOwner);

    /**
     * @dev Initializes the contract setting the deployer as the executor
     *
     * Emits a {ExecutorChanged} event.
     */
    constructor() {
        _executor = _msgSender();
        emit ExecutorChanged(address(0), _executor);
    }

    /**
     * @dev Returns the address of the current executor.
     */
    function executor() public view virtual returns (address) {
        return _executor;
    }

    /**
     * @dev Throws if called by any account other than the executor.
     */
    modifier onlyExecutor() {
        require(
            executor() == _msgSender(),
            "TieredOwnership: caller is not an executor"
        );
        _;
    }

    /**
     * @dev Returns the address of the currently nominated executor.
     */
    function nominatedExecutor() public view virtual returns (address) {
        return _nominatedExecutor;
    }

    /**
     * @notice nominates address as new executor
     * @param newExecutor address is the new address being given executorship
     *
     * Emits a {ExecutorNominated} event.
     */
    function nominateExecutor(address newExecutor) external onlyExecutor {
        _nominatedExecutor = newExecutor;
        emit ExecutorNominated(_nominatedExecutor);
    }

    /**
     * @notice promotes nominated executor to executor
     *
     * Emits a {ExecutorChanged} event.
     */
    function acceptExecutorship() external {
        require(
            _msgSender() == nominatedExecutor(),
            "TieredOwnership: You must be nominated before you can accept executorship"
        );
        emit ExecutorChanged(executor(), nominatedExecutor());
        _executor = nominatedExecutor();
        _nominatedExecutor = address(0);
    }

    /**
     * @dev Returns true if address is owner
     * @param owner address of possible owner
     */
    function isOwner(address owner) public view virtual returns (bool) {
        return _owners[owner];
    }

    /**
     * @dev Throws if called by any account other than one of the owners.
     */
    modifier onlyOwner() {
        require(
            isOwner(_msgSender()) == true,
            "TieredOwnership: caller is not an owner"
        );
        _;
    }

    /**
     * @notice adds additional owner
     * @param newOwner address is the new address being given ownership
     *
     * Emits a {OwnershipAdded} event.
     */
    function addOwner(address newOwner) public virtual onlyExecutor {
        _owners[newOwner] = true;
        emit OwnershipAdded(newOwner);
    }

    /**
     * @dev removes an owner.
     * @param oldOwner address is the owner to be removed
     */
    function removeOwner(address oldOwner) public virtual onlyExecutor {
        _owners[oldOwner] = false;
        emit OwnershipRemoved(oldOwner);
    }
}