// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "MultiSigWallet.sol";

/**
 * @title Multisignature wallet with timelock
 * @notice Enforces a delay before allowing a transaction to execute.
 * @author Josh Davis - <[email protected]>
 *
 * When a transaction reached the required number of confirmations, a countdown
 * timer begins. The transaction cannot be executed until the required amount
 * of time has passed. If enough owners revoke their confirmation so that the
 * transation no longer has the required number of confirmations, the timer is
 * reset, and will start over if the required number of confirmations is
 * reached again.
 *
 * If the timelock period is 0, then transactions are executed immediately once
 * they reach the required number of confirmations. Otherwise, the transaction
 * must be executed manually by calling the `executeTransaction()` function.
 *
 * IMPORTANT: If the number of required confirmations change, and the change
 * causes pending transactions to reach or fall below the new value, the
 * countdown timers are NOT automatically set or cleared. You can manually
 * set or reset the timer for a transaction by calling `resetConfirmationTimer()`.
 */
contract MultiSigWalletWithTimelock is MultiSigWallet {
    /**
     * @notice Emitted when the timelock period is changed.
     */
    event TimelockChange(uint256 previous, uint256 timelock);

    /**
     * @notice Emitted when the countdown timer for a transaction has been set.
     */
    event ConfirmationTimeSet(uint256 transactionId, uint256 confirmationTime);

    /**
     * @notice Emitted when the countdown timer for a transaction has been cleared.
     */
    event ConfirmationTimeUnset(uint256 transactionId);

    /**
     * @dev The number of seconds to wait after confirmation before any
     *     transaction can be executed.
     */
    uint256 public lockPeriod;

    /**
     * @dev Tracks when a transaction received the required number of
     *     confirmations.
     * @dev Key is transactionId, value is block.timestamp
     */
    mapping(uint256 => uint256) public confirmationTimes;

    /**
     * @param _owners The initial list of owners.
     * @param _required The initial required number of confirmations.
     * @param _lockPeriod The number of seconds to wait after confirmation
     *     before a transaction can be executed.
     *
     * Requirements:
     * - `_owners` MUST NOT contain any duplicates.
     * - `_owners` MUST NOT contain the null address.
     * - `_required` MUST be greater than 0.
     * - The length of `_owners` MUST NOT be less than `_required`.
     * - The length of `_owners` MUST NOT be greater than `MAX_OWNER_COUNT`.
     * - `_lockPeriod` MAY be 0, in which case transactions will execute
     *     immediately upon receiving the required number of confirmations.
     */
    constructor(
        address[] memory _owners,
        uint256 _required,
        uint32 _lockPeriod
    ) MultiSigWallet(_owners, _required) {
        lockPeriod = _lockPeriod;
    }

    /**
     * @notice Changes the lock period.
     * @notice emits TimeLockChange
     * @param _newLockPeriod the new lock period, in seconds.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `_newLockPeriod` MUST be different from the current value.
     * - `_newLockPeriod` MAY be 0, in which case transactions will execute
     *     immediately upon receiving the required number of confirmations.
     */
    function changeLockPeriod(uint256 _newLockPeriod) public onlyWallet {
        require(lockPeriod != _newLockPeriod);

        uint256 previous = lockPeriod;
        lockPeriod = _newLockPeriod;
        emit TimelockChange(previous, lockPeriod);
    }

    /**
     * @notice Allows an owner to execute a confirmed transaction.
     * @notice performs no-op if transaction is not confirmed.
     * @notice Will set or clear the countdown timer for the transaction if the
     *     confirmation state has changed due to an change in the required
     *     number of confirmations.
     * @notice emits Execution if the transaction was successfully executed.
     * @notice emits ExecutionFailure if the transaction was attempted and did
     *     not succeed.
     * @notice emits ConfirmationTimeSet if the transaction is confirmed but
     *     the countdown timer still needed to be started.
     * @notice emits ConfirmationTimeUnset if the transaction is not confirmed
     *     but the countdown timer needed to be cleared.
     * @param transactionId Transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - Caller MUST have confirmed the transaction.
     * - The transaction MUST NOT have already been successfully executed.
     */
    function executeTransaction(uint256 transactionId)
        public
        virtual
        override
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            if (lockPeriod == 0) {
                super._executeTransaction(transactionId);
            } else if (confirmationTimes[transactionId] == 0) {
                _setConfirmed(transactionId);
            } else if (
                block.timestamp >= confirmationTimes[transactionId] + lockPeriod
            ) {
                super._executeTransaction(transactionId);
            } else {
                revert("Too early");
            }
        } else if (confirmationTimes[transactionId] > 0) {
            // Catch cases where a confirmed transaction became unconfirmed
            // due to an increase in the required number of confirmations.
            _setUnconfirmed(transactionId);
        }
    }

    /**
     * @notice Sets or clears confimation timers for a pending transaction 
     *     that may have become confirmed or unconfirmed due to a change to the
     *     required number of confirmations.
     * @notice This should be called for pending transactions after changing 
     *     the required number of confirmations.
     * @param transactionId Transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - The transaction MUST NOT have already been successfully executed.
     */
    function resetConfirmationTimer(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            if (confirmationTimes[transactionId] == 0) {
                _setConfirmed(transactionId);
            }
        } else {
            if (confirmationTimes[transactionId] > 0) {
                _setUnconfirmed(transactionId);
            }
        }
    }

    function _setConfirmed(uint256 transactionId) internal {
        confirmationTimes[transactionId] = block.timestamp;
        emit ConfirmationTimeSet(
            transactionId,
            confirmationTimes[transactionId]
        );
    }

    /**
     * @dev Called by super.revokeConfirmation()
     * @dev Clears the countdown timer for a transaction if started and we
     *     do not have the required number of confirmations.
     * @dev emits ConfirmationTimeUnset if the countdown timer was cleared.
     */
    function _revocationHook(uint256 transactionId) internal virtual override {
        if (confirmationTimes[transactionId] == 0) return;

        if (!isConfirmed(transactionId)) {
            _setUnconfirmed(transactionId);
        }
    }

    function _setUnconfirmed(uint256 transactionId) internal {
        confirmationTimes[transactionId] = 0;
        emit ConfirmationTimeUnset(transactionId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "EnumerableSet.sol";
import "Wallet.sol";

/**
 * @title Multisignature wallet
 * @notice Allows multiple parties to agree on transactions before execution.
 * @author Original: Stefan George - <[email protected]>
 * @author Josh Davis - <[email protected]>
 * changelog:
 * - update to 0.8
 * - use Address set for owners
 * - add support for sending/holding/receiving tokens
 *
 * Based heavily on the contract at https://polygonscan.com/address/0x355b8e02e7f5301e6fac9b7cac1d6d9c86c0343f
 *
 * A multi-sig wallet has a set of owners and a number of required signatures.
 * Any owner can submit a transaction.
 * Owners can then confirm the transaction.
 * Once a transaction has the required number of confirmations, the transaction 
 *     can be executed.
 * Owners can revoke their confirmation any time before a transaction has been 
 *     executed.
 * The transaction is automatically executed when the required number of 
 *     confirmations has been reached.
 */
contract MultiSigWallet is Wallet {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Emitted when an owner votes to confirm a transaction.
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);

    /**
     * @notice Emitted when an owner revokes their vote to confirm a transaction.
     */
    event Revocation(address indexed sender, uint256 indexed transactionId);

    /**
     * @notice Emitted when an owner submits a new transaction.
     */
    event Submission(uint256 indexed transactionId);

    /**
     * @notice Emitted when a confirmed transaction has been performed.
     */
    event Execution(uint256 indexed transactionId);

    /**
     * @notice Emitted when a confirmed transaction failed to execute.
     */
    event ExecutionFailure(uint256 indexed transactionId);

    /**
     * @notice Emitted when a new owner is added.
     */
    event OwnerAddition(address indexed owner);

    /**
     * @notice Emitted when an owner is removed.
     */
    event OwnerRemoval(address indexed owner);

    /**
     * @notice Emitted when the required number of signatures changes.
     */
    event RequirementChange(uint256 previous, uint256 required);

    struct Transaction {
        /**
         * The address of the contract to call.
         */
        address destination;

        /**
         * The amount of crypto to send.
         */
        uint256 value;

        /**
         * The ABI-encoded function call.
         */
        bytes data;

        /**
         * Set to true when this transaction is successfully executed.
         */
        bool executed;
    }

    uint256 public constant MAX_OWNER_COUNT = 50;

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    EnumerableSet.AddressSet owners;
    uint256 public required;
    uint256 public transactionCount;

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required != 0 &&
                ownerCount != 0
        );
        _;
    }

    /**
     * @param _owners The initial list of owners.
     * @param _required The initial required number of confirmations.
     *
     * Requirements:
     * - `_owners` MUST NOT contain any duplicates.
     * - `_owners` MUST NOT contain the null address.
     * - `_required` MUST be greater than 0.
     * - The length of `_owners` MUST NOT be less than `_required`.
     * - The length of `_owners` MUST NOT be greater than `MAX_OWNER_COUNT`.
     */
    constructor(address[] memory _owners, uint256 _required)
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
            owners.add(_owners[i]);
        }
        required = _required;
    }

    /**
     * @notice Adds a new owner
     * @notice emits OwnerAddition
     * @param owner the owner address
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `owner` MUST NOT already be an owner.
     * - `owner` MUST NOT be the null address.
     * - The current number of owners MUST be less than `MAX_OWNER_COUNT`.
     */
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length() + 1, required)
    {
        isOwner[owner] = true;
        owners.add(owner);
        emit OwnerAddition(owner);
    }

    /**
     * @notice Removes an owner.
     * @notice emits OwnerRemoval
     * @notice If the current number of owners is reduced to below the number
     * of required signatures, `required` will be reduced to match.
     * @param owner the owner to be removed
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `owner` MUST be an existing owner
     * - The current number of owners MUST be greater than 1 (i.e. you can't remove all the owners).
     */
    function removeOwner(address owner) public onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        owners.remove(owner);

        if (required > owners.length()) changeRequirement(owners.length());
        emit OwnerRemoval(owner);
    }

    /**
     * @notice Replaces an owner with a new owner.
     * @notice emits OwnerRemoval and OwnerAddition
     * @param owner Address of owner to be replaced.
     * @param newOwner Address of new owner.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `owner` MUST be an existing owner
     * - `newOwner` MUST NOT already be an owner.
     * - `newOwner` MUST NOT be the null address.
     */
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        notNull(newOwner)
        ownerDoesNotExist(newOwner)
    {
        owners.remove(owner);
        owners.add(newOwner);

        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /**
     * @notice Changes the number of required confirmations.
     * @notice emits RequirementChange
     * @param _required Number of required confirmations.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `_required` MUST be greater than 0.
     * - `_required` MUST NOT be greater than the number of owners.
     * - `_required` MUST be different from the current value.
     */
    function changeRequirement(uint256 _required)
        public
        onlyWallet
        validRequirement(owners.length(), _required)
    {
        require(required != _required);
        uint256 previous = required;
        required = _required;

        emit RequirementChange(previous, _required);
    }

    /**
     * @notice Allows an owner to submit and confirm a transaction.
     * @param destination Transaction target address.
     * @param value Transaction ether value.
     * @param data Transaction data payload.
     * @return transactionId transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     */
    function submitTransaction(
        address destination,
        uint256 value,
        bytes calldata data
    ) public notNull(destination) returns (uint256 transactionId) {
        transactionId = _addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /**
     * @notice Allows an owner to confirm a transaction.
     * @notice emits Confirmation
     * @param transactionId Transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - Caller MUST NOT have already confirmed the transaction.
     */
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        _confirmationHook(transactionId);
        executeTransaction(transactionId);
    }

    /**
     * @notice Allows an owner to revoke a confirmation for a transaction.
     * @notice emits Revocation
     * @param transactionId Transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - Caller MUST have previously confirmed the transaction.
     * - The transaction MUST NOT have already been successfully executed.
     */
    function revokeConfirmation(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
        _revocationHook(transactionId);
    }

    /**
     * @notice Allows an owner to execute a confirmed transaction.
     * @notice performs no-op if transaction is not confirmed.
     * @notice emits Execution if the transaction was successfully executed.
     * @notice emits ExecutionFailure if the transaction was attempted and did
     *     not succeed.
     * @param transactionId Transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * -
     * - Caller MUST have confirmed the transaction.
     * - `transactionId` MUST exist.
     * - The transaction MUST NOT have already been successfully executed.
     */
    function executeTransaction(uint256 transactionId)
        public
        virtual
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            _executeTransaction(transactionId);
        }
    }

    /**
     * @notice Returns the confirmation status of a transaction.
     * @param transactionId Transaction ID.
     * @return Confirmation status.
     */
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length(); i++) {
            if (confirmations[transactionId][owners.at(i)]) count += 1;
            if (count == required) return true;
        }
        return false;
    }

    /**
     * @notice Returns number of confirmations of a transaction.
     * @param transactionId Transaction ID.
     * @return count number of confirmations.
     */
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length(); i++)
            if (confirmations[transactionId][owners.at(i)]) count += 1;
    }

    /**
     * @notice Returns total number of transactions after filters are applied.
     * @dev use with `getTransactionIds` to page through transactions.
     * @param pending Include pending transactions.
     * @param executed Include executed transactions.
     * @return count Total number of transactions after filters are applied.
     */
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) count += 1;
    }

    /**
     * @notice Returns list of transaction IDs in defined range.
     * @dev use with `getTransactionCount` to page through transactions.
     * @param from Index start position of transaction array (inclusive).
     * @param to Index end position of transaction array (exclusive).
     * @param pending Include pending transactions.
     * @param executed Include executed transactions.
     * @return _transactionIds array of transaction IDs.
     *
     * Requirements:
     * `to` MUST NOT be less than `from`.
     * `to` - `from` MUST NOT be greater than the number of transactions that
     *     meet the filter criteria.
     */
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) public view returns (uint256[] memory _transactionIds) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    /**
     * @notice Returns list of owners.
     * @return List of owner addresses.
     */
    function getOwners() public view returns (address[] memory) {
        return owners.values();
    }

    /**
     * @notice Returns array with owner addresses, which confirmed transaction.
     * @param transactionId Transaction ID.
     * @return _confirmations array of owner addresses.
     */
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length());
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length(); i++)
            if (confirmations[transactionId][owners.at(i)]) {
                confirmationsTemp[count] = owners.at(i);
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }

    /**
     * @notice Withdraws native crypto.
     * @param toAddress the address to receive the crypto
     * @param amount the amount to withdraw
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdraw(address payable toAddress, uint256 amount)
        public
        onlyWallet
    {
        _withdraw(toAddress, amount);
    }

    /**
     * @notice Withdraws ERC20 crypto.
     * @param toAddress the address to receive the crypto
     * @param amount the amount to withdraw
     * @param tokenContract the ERC20 contract.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdrawERC20(
        address payable toAddress,
        uint256 amount,
        IERC20 tokenContract
    ) public onlyWallet {
        _withdrawERC20(toAddress, amount, tokenContract);
    }

    /**
     * @notice Withdraws an ERC721 token.
     * @param toAddress the address to receive the token
     * @param tokenId the token id
     * @param tokenContract the ERC721 contract.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdrawERC721(
        address payable toAddress,
        uint256 tokenId,
        IERC721 tokenContract
    ) public onlyWallet {
        _withdrawERC721(toAddress, tokenId, tokenContract);
    }

    /**
     * @notice Withdraws ERC777 crypto.
     * @param toAddress the address to receive the crypto
     * @param amount the amount to withdraw
     * @param tokenContract the ERC777 contract.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdrawERC777(
        address payable toAddress,
        uint256 amount,
        IERC777 tokenContract
    ) public onlyWallet {
        _withdrawERC777(toAddress, amount, tokenContract);
    }

    /**
     * @notice Withdraws ERC1155 tokens.
     * @param toAddress the address to receive the tokens
     * @param tokenId the token id
     * @param amount the amount to withdraw
     * @param tokenContract the ERC1155 contract.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdrawERC1155(
        address payable toAddress,
        uint256 tokenId,
        uint256 amount,
        IERC1155 tokenContract
    ) public onlyWallet {
        _withdrawERC1155(toAddress, tokenId, amount, tokenContract);
    }

    /**
     * @dev Adds a new transaction to the transaction mapping
     * @param destination Transaction target address.
     * @param value Transaction ether value.
     * @param data Transaction data payload.
     * @return transactionId transaction ID.
     */
    function _addTransaction(
        address destination,
        uint256 value,
        bytes calldata data
    ) internal virtual returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    function _executeTransaction(uint256 transactionId) internal virtual {
        Transaction storage txn = transactions[transactionId];
        (txn.executed, ) = txn.destination.call{value: txn.value}(txn.data);

        if (txn.executed) emit Execution(transactionId);
        else {
            emit ExecutionFailure(transactionId);
        }
    }

    function _confirmationHook(uint256 transactionId) internal virtual {}

    function _revocationHook(uint256 transactionId) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "IERC20.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC777.sol";
import "IERC777Recipient.sol";
import "IERC1155.sol";
import "IERC1155Receiver.sol";
import "ERC165.sol";

/**
 * @title Wallet
 * @dev This is an abstract contract with basic wallet functionality. It can
 *     send and receive native crypto, ERC20 tokens, ERC721 tokens, ERC777 
 *     tokens, and ERC1155 tokens.
 * @dev The withdraw events are always emitted when crypto or tokens are
 *     withdrawn.
 * @dev The deposit events are less reliable, and normally only work when the
 *     safe transfer functions are used.
 * @dev There is no DepositERC20 event defined, because the ERC20 standard 
 *     doesn't include a safe transfer function.
 * @dev The withdraw functions are all marked as internal. Subclasses should
 *     add public withdraw functions that delegate to these, preferably with 
 *     some kind of control over who is allowed to call them.
 */
abstract contract Wallet is
    IERC721Receiver,
    IERC777Recipient,
    IERC1155Receiver,
    ERC165
{
    /**
     * @dev May be emitted when native crypto is deposited.
     * @param sender the source of the crypto
     * @param value the amount deposited
     */
    event Deposit(address indexed sender, uint256 value);

    /**
     * @dev May be emitted when an NFT is deposited.
     * @param sender the source of the NFT
     * @param tokenContract the NFT contract
     * @param tokenId the id of the deposited token
     */
    event DepositERC721(
        address indexed sender,
        address indexed tokenContract,
        uint256 tokenId
    );

    /**
     * @dev May be emitted when ERC777 tokens are deposited.
     * @param sender the source of the ERC777 tokens
     * @param tokenContract the ERC777 contract
     * @param amount the amount deposited
     */
    event DepositERC777(
        address indexed sender,
        address indexed tokenContract,
        uint256 amount
    );

    /**
     * @dev May be emitted when semi-fungible tokens are deposited.
     * @param sender the source of the semi-fungible tokens
     * @param tokenContract the semi-fungible token contract
     * @param tokenId the id of the semi-fungible tokens
     * @param amount the number of tokens deposited
     */
    event DepositERC1155(
        address indexed sender,
        address indexed tokenContract,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev Emitted when native crypto is withdrawn.
     * @param recipient the destination of the crypto
     * @param value the amount withdrawn
     */
    event Withdraw(address indexed recipient, uint256 value);

    /**
     * @dev Emitted when ERC20 tokens are withdrawn.
     * @param recipient the destination of the ERC20 tokens
     * @param tokenContract the ERC20 contract
     * @param amount the amount withdrawn
     */
    event WithdrawERC20(
        address indexed recipient,
        address indexed tokenContract,
        uint256 amount
    );

    /**
     * @dev Emitted when an NFT is withdrawn.
     * @param recipient the destination of the NFT
     * @param tokenContract the NFT contract
     * @param tokenId the id of the withdrawn token
     */
    event WithdrawERC721(
        address indexed recipient,
        address indexed tokenContract,
        uint256 tokenId
    );

    /**
     * @dev Emitted when ERC777 tokens are withdrawn.
     * @param recipient the destination of the ERC777 tokens
     * @param tokenContract the ERC777 contract
     * @param amount the amount withdrawn
     */
    event WithdrawERC777(
        address indexed recipient,
        address indexed tokenContract,
        uint256 amount
    );

    /**
     * @dev Emitted when semi-fungible tokens are withdrawn.
     * @param recipient the destination of the semi-fungible tokens
     * @param tokenContract the semi-fungible token contract
     * @param tokenId the id of the semi-fungible tokens
     * @param amount the number of tokens withdrawn
     */
    event WithdrawERC1155(
        address indexed recipient,
        address indexed tokenContract,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC777Recipient).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    receive() external payable {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        emit DepositERC721(from, msg.sender, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev See {IERC777Recipient-tokensReceived}.
     */
    function tokensReceived(
        address,
        address from,
        address,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external override {
        emit DepositERC777(from, msg.sender, amount);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata
    ) external override returns (bytes4) {
        emit DepositERC1155(from, msg.sender, tokenId, value);
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata
    ) external override returns (bytes4) {
        for (uint256 i = 0; i < values.length; i++) {
            emit DepositERC1155(from, msg.sender, tokenIds[i], values[i]);
        }
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    /**
     * @dev Withdraw native crypto.
     * @notice Emits Withdraw
     * @param toAddress Where to send the crypto
     * @param amount The amount to send
     */
    function _withdraw(address payable toAddress, uint256 amount)
        internal
        virtual
    {
        require(toAddress != address(0));
        toAddress.transfer(amount);
        emit Withdraw(toAddress, amount);
    }

    /**
     * @dev Withdraw ERC20 tokens.
     * @notice Emits WithdrawERC20
     * @param toAddress Where to send the ERC20 tokens
     * @param tokenContract The ERC20 token contract
     * @param amount The amount withdrawn
     */
    function _withdrawERC20(
        address payable toAddress,
        uint256 amount,
        IERC20 tokenContract
    ) internal virtual {
        require(toAddress != address(0));
        tokenContract.transfer(toAddress, amount);
        emit WithdrawERC20(toAddress, address(tokenContract), amount);
    }

    /**
     * @dev Withdraw an NFT.
     * @notice Emits WithdrawERC721
     * @param toAddress Where to send the NFT
     * @param tokenContract The NFT contract
     * @param tokenId The id of the NFT
     */
    function _withdrawERC721(
        address payable toAddress,
        uint256 tokenId,
        IERC721 tokenContract
    ) internal virtual {
        require(toAddress != address(0));
        tokenContract.safeTransferFrom(address(this), toAddress, tokenId);
        emit WithdrawERC721(toAddress, address(tokenContract), tokenId);
    }

    /**
     * @dev Withdraw ERC777 tokens.
     * @notice Emits WithdrawERC777
     * @param toAddress Where to send the ERC777 tokens
     * @param tokenContract The ERC777 token contract
     * @param amount The amount withdrawn
     */
    function _withdrawERC777(
        address payable toAddress,
        uint256 amount,
        IERC777 tokenContract
    ) internal virtual {
        require(toAddress != address(0));
        tokenContract.operatorSend(address(this), toAddress, amount, "", "");
        emit WithdrawERC777(toAddress, address(tokenContract), amount);
    }

    /**
     * @dev Withdraw semi-fungible tokens.
     * @notice Emits WithdrawERC1155
     * @param toAddress Where to send the semi-fungible tokens
     * @param tokenContract The semi-fungible token contract
     * @param tokenId The id of the semi-fungible tokens
     * @param amount The number of tokens withdrawn
     */
    function _withdrawERC1155(
        address payable toAddress,
        uint256 tokenId,
        uint256 amount,
        IERC1155 tokenContract
    ) internal virtual {
        require(toAddress != address(0));
        tokenContract.safeTransferFrom(
            address(this),
            toAddress,
            tokenId,
            amount,
            ""
        );
        emit WithdrawERC1155(
            toAddress,
            address(tokenContract),
            tokenId,
            amount
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}