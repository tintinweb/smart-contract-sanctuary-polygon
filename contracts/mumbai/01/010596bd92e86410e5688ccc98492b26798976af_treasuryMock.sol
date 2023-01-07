// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 indexed value, uint256 balance);
    event SubmittedTx(address indexed to, uint256 indexed value, bytes indexed data);
    event ApprovedTx(uint256 indexed txId, address indexed approver);
    event RevokeApproval(address indexed owner, uint indexed txId);
    event TxExecuted(address indexed to, uint256 indexed value, bytes indexed data, address executor);

    mapping(address => bool) private isOwner;

    struct Transaction {
        uint256 id;
        address to;
        uint256 value;
        bytes data;
        uint256 confirmations;
        bool executed;
    }

    mapping(uint256 => Transaction) private transactions;
    mapping(uint256 => mapping(address => bool)) private approved;

    uint256 public required;
    uint256 public txId;

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert NotOwner();
        }
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId > txId - 1) {
            revert TxDoesNotExist();
        }
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) {
            revert TxAlreadyExecuted();
        }
        _;
    }

    modifier notApproved(uint256 _txId) {
        if (approved[_txId][msg.sender]) {
            revert TxAlreadyApproved();
        }
        _;
    }

    error InvalidNumRequired();
    error InvalidOwnerAddress();
    error AlreadyOwner();
    error NotOwner();
    error TxDoesNotExist();
    error TxAlreadyExecuted();
    error TxAlreadyApproved();
    error TxNotApproved();
    error LessConfirmationsThanRequired();
    error TxExecutionFailed();

    constructor(address[] memory _owners, uint256 _required) {
        if (_required > _owners.length) {
            revert InvalidNumRequired();
        }
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) {
                revert InvalidOwnerAddress();
            }
            if (isOwner[owner]) {
                revert AlreadyOwner();
            }
            isOwner[owner] = true;
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTx(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner {
        Transaction storage transaction = transactions[txId];
        transaction.id = txId;
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;
        txId++;
        emit SubmittedTx(_to, _value, _data);
    }

    function approveTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        transactions[_txId].confirmations++;
        approved[_txId][msg.sender] = true;
        emit ApprovedTx(_txId, msg.sender);
    }

    function executeTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        if (transaction.confirmations < required) {
            revert LessConfirmationsThanRequired();
        }
        transaction.executed = true;
        (bool success, ) = payable(transaction.to).call{
            value: transaction.value
        }(transaction.data);
        if (!success) {
            revert TxExecutionFailed();
        }
        emit TxExecuted(
            transaction.to,
            transaction.value,
            transaction.data,
            msg.sender
        );
    }

    function revokeApproval(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        if (approved[_txId][msg.sender]) {
            transactions[_txId].confirmations--;
            approved[_txId][msg.sender] = false;
        } else {
            revert TxNotApproved();
        }
        emit RevokeApproval(msg.sender, _txId);
    }

    function getTransaction(uint256 _txId) external view txExists(_txId) returns (Transaction memory) {
        return transactions[_txId];
    }

    function checkOwner(address _owner) external view returns (bool) {
        return isOwner[_owner];
    }

    function checkApproved(uint256 _txId, address _approver) external view returns (bool) {
        return approved[_txId][_approver];
    }
}

pragma solidity ^0.8.4;

import "../../src/treasury.sol";

contract treasuryMock is MultiSigWallet {
    address[] owners_ = [0xC5Fcd6be4a3b187Cb9B3Bbd9aAD047767DAEF344,0x7022B9FDf874b1Ed8d2AC98846650c030ACC8d88,0x2a4B8d4bF3814E7975b6d367Fc3071a4c32370E8];
    uint256 required_ = 2;

    constructor()
    MultiSigWallet(owners_, required_)
    {}
}