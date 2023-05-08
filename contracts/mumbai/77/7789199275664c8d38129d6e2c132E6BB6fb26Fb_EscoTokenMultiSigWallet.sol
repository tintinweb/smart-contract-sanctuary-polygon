// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract EscoTokenMultiSigWallet {
    uint256 public constant TOTAL_OWNER_COUNT = 5;

    event TransactionConfirmed(
        address indexed sender,
        uint256 indexed transactionId
    );
    event TransactionSubmitted(uint256 indexed transactionId);
    event TransactionExecuted(uint256 indexed transactionId);
    event TransactionExecutionFailed(uint256 indexed transactionId);
    event Deposited(address indexed sender, uint256 value);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address public admin;
    uint256 public constant requiredConfirmations = 3;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        uint256 confirmations;
        bool executed;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "Owner already exixts");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner does not exixts");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            "Transaction does not exists"
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(
            confirmations[transactionId][owner],
            "Transaction is not confirmed"
        );
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(
            !confirmations[transactionId][owner],
            "Transaction is confirmed"
        );
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            !transactions[transactionId].executed,
            "Transaction is already executed"
        );
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "Address cannot be null");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Only admin can call this function");
        _;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owner can call this function");
        _;
    }

    modifier canExecute(uint256 transactionId) {
        require(
            transactions[transactionId].confirmations >= requiredConfirmations,
            "Not enough confirmations"
        );
        _;
    }

    modifier validRequirementForConstructor(
        address owner1,
        address owner2,
        address owner3,
        address owner4,
        address owner5
    ) {
        require(
            owner1 != address(0) ||
                owner2 != address(0) ||
                owner3 != address(0) ||
                owner4 != address(0) ||
                owner5 != address(0),
            "Owner cannot be null"
        );
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) emit Deposited(msg.sender, msg.value);
    }

    constructor(
        address owner1,
        address owner2,
        address owner3,
        address owner4,
        address owner5
    ) validRequirementForConstructor(owner1, owner2, owner3, owner4, owner5) {
        isOwner[owner1] = true;
        isOwner[owner2] = true;
        isOwner[owner3] = true;
        isOwner[owner4] = true;
        isOwner[owner5] = true;

        admin = msg.sender;
    }

    function replaceOwner(
        address previousOwner,
        address newOwner
    )
        external
        onlyAdmin
        ownerExists(previousOwner)
        ownerDoesNotExist(newOwner)
        notNull(newOwner)
    {
        isOwner[previousOwner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoved(previousOwner);
        emit OwnerAdded(newOwner);
    }

    function submitTransaction(
        address destination,
        uint256 value,
        bytes calldata data
    ) public onlyOwner returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data);

        confirmations[transactionId][msg.sender] = true;
        emit TransactionConfirmed(msg.sender, transactionId);
    }

    function addTransaction(
        address destination,
        uint256 value,
        bytes calldata data
    ) internal notNull(destination) returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId].destination = destination;
        transactions[transactionId].value = value;
        transactions[transactionId].data = data;
        transactions[transactionId].executed = false;
        transactions[transactionId].confirmations = 1;

        transactionCount += 1;
        emit TransactionSubmitted(transactionId);
    }

    function confirmTransaction(
        uint256 transactionId
    )
        external
        onlyOwner
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        transactions[transactionId].confirmations =
            transactions[transactionId].confirmations +
            1;
        emit TransactionConfirmed(msg.sender, transactionId);
    }

    function executeTransaction(
        uint256 transactionId
    )
        public
        transactionExists(transactionId)
        notExecuted(transactionId)
        canExecute(transactionId)
        onlyOwner
    {
        Transaction memory transactionData = transactions[transactionId];
        transactions[transactionId].executed = true;
        (bool success, ) = transactionData.destination.call{
            value: transactionData.value
        }(transactionData.data);
        if (success) emit TransactionExecuted(transactionId);
        else {
            emit TransactionExecutionFailed(transactionId);
        }
    }
}