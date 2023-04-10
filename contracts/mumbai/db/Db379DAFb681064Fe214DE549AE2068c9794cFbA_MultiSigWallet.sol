// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract MultiSigWallet is ReentrancyGuard {
    event Deposit(
        address indexed sender,
        uint amount,
        uint balance
    );
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value
    );
    event ConfirmTransaction(
        address indexed owner,
        uint indexed txIndex,
        uint indexed numConfirmations
    );
    event RevokeConfirmation(
        address indexed owner,
        uint indexed txIndex,
        uint indexed numConfirmations
    );
    event ExecuteTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to    
    );
    event WhiteListedUser(
        address indexed user,
        bool indexed deliveryStatus,
        uint indexed userIndex
    );

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
    }

    struct WhiteListed {
        address user;
        bool deliveryStatus;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;
    WhiteListed[] public whiteListed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function addWhiteListedUser() public payable {
        require(msg.value == 0.0001 ether, "Please send 0.0001 ether");

        whiteListed.push(WhiteListed({
            user: msg.sender,
            deliveryStatus: false
        }));

        (bool success, ) = msg.sender.call{value: msg.value}("");
        require(success, "tx failed");

        emit WhiteListedUser(msg.sender, false, whiteListed.length-1);
    }

    function updateDeliveryStatus(address _user, uint userIndex) public onlyOwner {
        require(whiteListed[userIndex].user == _user, "User not found");
        whiteListed[userIndex].deliveryStatus = true;
        emit WhiteListedUser(_user, true, userIndex);
    }

    function submitTransaction(
        address _to,
        uint _value
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value);
    }

    function confirmTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex, transaction.numConfirmations);
    }

    function executeTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) noReentrant {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex, transaction.to);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex, transaction.numConfirmations);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}