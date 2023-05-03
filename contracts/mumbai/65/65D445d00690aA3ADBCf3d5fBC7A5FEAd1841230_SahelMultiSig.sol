// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SahelMultiSig {
    address public owner;
    uint256 public required;
    uint256 public transactionFee = 0;

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    uint256 public transactionCount = 0;

    struct Transaction {
        address[] signers;
        uint256 signaturesRequired;
        mapping(address => bool) signed;
        uint256 signatureCount;
        bool isOpen;
    }

    event NewTransaction(uint256 indexed transactionId);
    event SignedData(address indexed signer, uint256 indexed transactionId);
    event AllSigned(uint256 indexed transactionId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].isOpen,
            "Transaction does not exist"
        );
        _;
    }

    modifier notSigned(uint256 transactionId) {
        require(
            !transactions[transactionId].signed[msg.sender],
            "Data already signed"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTransaction(
        address[] memory signers,
        uint256 signaturesRequired
    ) public payable returns (uint256 transactionId) {
        require(msg.value >= transactionFee, "Insufficient transaction fee");
        require(
            signers.length >= signaturesRequired,
            "Invalid signer count and signatures required."
        );

        transactionId = transactionCount++;
        Transaction storage newTransaction = transactions[transactionId];

        newTransaction.signers = signers;
        newTransaction.signaturesRequired = signaturesRequired;
        newTransaction.isOpen = true;

        emit NewTransaction(transactionId);
    }

    function signData(
        uint256 transactionId
    ) public transactionExists(transactionId) notSigned(transactionId) {
        Transaction storage t = transactions[transactionId];
        require(
            isSigner(transactionId, msg.sender),
            "Not a signer for this transaction"
        );

        t.signed[msg.sender] = true;
        t.signatureCount++;

        emit SignedData(msg.sender, transactionId);

        if (t.signatureCount == t.signaturesRequired) {
            t.isOpen = false;
            emit AllSigned(transactionId);
        }
    }

    function isSigner(
        uint256 transactionId,
        address user
    ) public view returns (bool) {
        Transaction storage t = transactions[transactionId];
        for (uint256 i = 0; i < t.signers.length; i++) {
            if (t.signers[i] == user) {
                return true;
            }
        }
        return false;
    }

    function withdrawFees() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getTransactionSigners(
        uint256 transactionId
    ) public view returns (address[] memory) {
        return transactions[transactionId].signers;
    }
}