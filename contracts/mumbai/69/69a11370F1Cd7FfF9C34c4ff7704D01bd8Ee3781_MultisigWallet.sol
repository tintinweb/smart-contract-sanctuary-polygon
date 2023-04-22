// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract MultisigWallet {
    ////////////////////EVENTS///////////////////////
    event Deposit(address indexed sender, uint256 amount, uint256 contractBal);
    event TransactionRequested(
        address indexed owner,
        uint256 indexed txnID,
        address indexed to,
        uint256 amount
    );
    event TransactionApproved(address indexed owner, uint256 indexed txnID);

    ///////////////////STATE VARIABLES/////////////////
    uint8 public constant MAX_OWNERS = 20;
    uint8 numofApprovalsRequired;
    address public factory;
    bool initialState;
    address[] validOwners;

    struct Transaction {
        address recipient;
        uint8 numOfConformations;
        bool approved;
        uint80 amountRequested;
    }

    Transaction[] allTransactions;
    uint256[] successfulTxnIDs;

    uint256 txnID = 1;

    //mapping to keep track of all transactions
    mapping(uint256 => Transaction) _transactions;
    //mapping to check if an owner as approved a transaction
    mapping(uint256 => mapping(address => bool)) public hasApprovedtxn;
    //mapping to check if an address is part of the owners
    mapping(address => bool) isOwner;

    ///////////////////CONSTRUCTOR/////////////////////
    function initialize(
        address[] memory _owners,
        uint8 _quorum
    ) external payable {
        require(initialState == false, "Contract Already Initialized");
        require(_quorum <= _owners.length, "Out of Bound!");

        require(_owners.length <= MAX_OWNERS, "Invalid owners");
        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            notAddressZero(owner);
            isOwner[owner] = true;
        }

        validOwners = _owners;
        numofApprovalsRequired = _quorum;
        factory = msg.sender;
        initialState = true;
    }

    /////////////////FUNCTIONS/////////////////
    function requestTransaction(
        address _to,
        uint80 _amount
    ) external returns (uint256) {
        isAnOwner(msg.sender);
        notAddressZero(_to);
        Transaction storage txn = _transactions[txnID];
        txn.recipient = _to;
        txn.amountRequested = _amount;
        uint256 currentTxnID = txnID;
        allTransactions.push(txn);

        txnID = txnID + 1;

        emit TransactionRequested(msg.sender, currentTxnID, _to, _amount);
        return currentTxnID;
    }

    function approveTransaction(uint256 _ID) external {
        isAnOwner(msg.sender);

        require(hasApprovedtxn[_ID][msg.sender] == false, "Already Approved");
        require(_ID > 0 && _ID < txnID, "InvalidID");

        Transaction storage txn = _transactions[_ID];
        require(txn.approved == false, "Txn has been completed");
        txn.numOfConformations = txn.numOfConformations + 1;
        hasApprovedtxn[_ID][msg.sender] = true;

        address beneficiary = txn.recipient;
        uint256 amount = txn.amountRequested;

        if (txn.numOfConformations >= numofApprovalsRequired) {
            txn.approved = true;
            (bool success, ) = payable(beneficiary).call{value: amount}("");
            require(success, "txn failed");
            successfulTxnIDs.push(_ID);
        }

        emit TransactionApproved(msg.sender, _ID);
    }

    function getTxnsCount() external view returns (uint256) {
        return allTransactions.length;
    }

    function isAnOwner(address user) private view {
        require(isOwner[user], "Not a valid owner");
    }

    function notAddressZero(address user) private pure {
        require(user != address(0), "Invalid Address");
    }

    function getAllowners() external view returns (address[] memory) {
        return validOwners;
    }

    function getAlltxnDetails(
        uint256 _ID
    ) external view returns (Transaction memory) {
        Transaction storage txn = _transactions[_ID];
        return txn;
    }

    function getAlltxnsInfo() external view returns (Transaction[] memory) {
        return allTransactions;
    }

    function allSuccessfulTxnIDs() external view returns (uint256[] memory) {
        return successfulTxnIDs;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}