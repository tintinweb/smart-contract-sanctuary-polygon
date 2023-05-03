/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSig {
    /*
     *  Events
     */
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner, string roundId);
    event OwnerRemoval(address indexed owner, string roundId);
    event RequirementChange(uint256 required);

    /*
     *  Constants
     */
    uint256 public constant MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        bytes data;
        bool executed;
    }

    /// @notice For each transaction, a mapping of owners approving or not the transaction.
    mapping(uint256 => mapping(address => bool)) public confirmations;

    mapping(uint256 => Transaction) public transactions;

    /// @notice The number of transactions that have been submitted to the contract.
    uint256 public transactionCount;

    /*
    *  Modifiers
    */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
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

    modifier txExists(uint256 transactionId) {
        require(transactions[transactionId].to != address(0), "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!confirmations[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "Address must not be null");
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

    /// @dev Contract constructor sets initial owners and required number of isConfirmed.
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired)
    validRequirement(_owners.length, _numConfirmationsRequired)
    {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
            _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
        }
        owners = _owners;
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner, string calldata roundId)
    public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, numConfirmationsRequired)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner, roundId);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner, string calldata roundId) public onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        if (numConfirmationsRequired > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner, roundId);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(
        address owner,
        address newOwner,
        string calldata roundId
    ) public onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner) {
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner, roundId);
        emit OwnerAddition(newOwner, roundId);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required)
    public
    onlyWallet
    validRequirement(owners.length, _required)
    {
        numConfirmationsRequired = _required;
        emit RequirementChange(_required);
    }

    /// @notice Allows an owner to submit a transaction. The transaction will be automatically confirmed.
    /// @param destination The address to which the transaction will be sent.
    /// @param payload The data of the transaction.
    /// @return transactionId Returns the transaction id.
    function submitTransaction(
        address payable destination,
        bytes calldata payload
    ) external returns (uint256 transactionId) {
        // store the submitted transaction
        transactionId = addTransaction(destination, payload);

        // the sender also confirms it
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param _txIndex Transaction ID.
    function confirmTransaction(uint256 _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notConfirmed(_txIndex)
    {
        // confirm transaction
        confirmations[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);

        // attempt its execution
        executeTransaction(_txIndex);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param _txIndex Transaction ID.
    function executeTransaction(uint256 _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
        if (isConfirmed(_txIndex)) {
            Transaction storage t = transactions[_txIndex];

            (bool success, ) = t.to.call(t.data);
            if (success) {
                t.executed = true;
                emit Execution(_txIndex);
            } else {
                emit ExecutionFailure(_txIndex);
            }
        }
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param _txIndex Transaction ID.
    function revokeConfirmation(uint256 _txIndex)
    external
    onlyOwner
    notExecuted(_txIndex)
    {
        require(confirmations[_txIndex][msg.sender], "tx not confirmed");

        confirmations[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count++;
            if (count == numConfirmationsRequired) return true;
        }
        return false;
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param payload Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function addTransaction(address destination, bytes calldata payload)
    private
    notNull(destination)
    returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
        to: destination,
        data: payload,
        executed: false
        });

        transactionCount++;
        emit SubmitTransaction(msg.sender, transactionId, destination, payload);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint256 transactionId)
    public
    view
    returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) count += 1;
        return count;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
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
        return count;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }
}