/**
 *Submitted for verification at polygonscan.com on 2022-08-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title MultisigWallet
 * @dev Implements multisig wallet along with rights delegation
 */
contract MultisigWallet {
    address public _owner;
    uint256 public _lockedBalance;
    uint256 public _txnId;
    uint256 public _signerCount;

    // events ----------------------------------------------------
    event WalletCreated(address indexed ownerAddress, string ownerCid);
    event SignerAdded(address indexed signerAddress, string cid);
    event TransactionCreated(uint256 txnId, address indexed to, uint256 amount);
    event TransactionApproved(uint256 txnId, address indexed approver);
    event TransactionExecuted(uint256 txnId, address indexed approver);
    event Delegate(address indexed from, address indexed to);
    event RevokeDelegation(address indexed signer);
    
    // mappings --------------------------------------------------
    struct Signer {
        string cid;
        address delegateTo;
        uint256 weight;
    }

    struct Transaction {
        bool executed;
        address to;
        uint256 amount;
        uint256 approval;
        // address[] approvedBy;
    }

    // mappings --------------------------------------------------
    mapping(address => Signer) public signers;
    mapping(uint256 => Transaction) public transactions;

    // constructor -----------------------------------------------
    constructor(string memory cid_) {
        _owner = msg.sender;
        signers[msg.sender].weight = 1;
        signers[msg.sender].cid = cid_;
        _txnId = 1;
        _signerCount = 1;
        emit WalletCreated(msg.sender, cid_);
    }

    // public functions -----------------------------------------------
    function addSigner(address signer_, string memory cid_) public {
        require(msg.sender == _owner, "Only Owner can add Signer.");
        require(signers[signer_].weight == 0, "Signer already added.");
        signers[signer_].cid = cid_;
        signers[signer_].weight = 1;
        _signerCount += 1;
        emit SignerAdded(signer_, cid_);
    }

    function delegate(address to_) public {
        require(
            signers[msg.sender].weight > 0 && signers[msg.sender].delegateTo == address(0),
            "Invalid request."
        );
        require(signers[to_].weight > 0, "Invalid delegate.");
        require(to_ != msg.sender, "Self-delegation is disallowed.");
        Signer storage signer = signers[msg.sender];
        address to = to_;

        while (signers[to].delegateTo != address(0)) {
            to = signers[to].delegateTo;
            // found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        to = to_;
        while (to != address(0)) {
            Signer storage delegate_ = signers[to];
            delegate_.weight += signer.weight;
            to = delegate_.delegateTo;
        }
        signer.delegateTo = to_;
        emit Delegate(msg.sender, to_);
    }

    function revokeDelegation() public {
        require(
            signers[msg.sender].weight > 0 && signers[msg.sender].delegateTo != address(0),
            "Invalid request."
        );
        Signer storage signer = signers[msg.sender];
        address delegateAddr = signer.delegateTo;
        while (delegateAddr != address(0)) {
            Signer storage delegate_ = signers[delegateAddr];
            delegate_.weight -= signer.weight;
            delegateAddr = delegate_.delegateTo;
        }
        signer.delegateTo = address(0);
        emit RevokeDelegation(msg.sender);
    }

    function createTransaction(address to_, uint256 amount_) public {
        require(
            signers[msg.sender].weight > 0 && signers[msg.sender].delegateTo == address(0),
            "Invalid request."
        );
        require(
            address(this).balance - _lockedBalance >= amount_,
            "Insufficient balance in wallet."
        );
        transactions[_txnId].to = to_;
        transactions[_txnId].amount = amount_;
        _lockedBalance += amount_;
        emit TransactionCreated(_txnId, to_, amount_);

        _approveTransaction(_txnId, msg.sender);
        _txnId += 1;
    }

    function approveTransaction(uint256 txnId_) public {
        require(
            signers[msg.sender].weight > 0 && signers[msg.sender].delegateTo == address(0),
            "Invalid request."
        );
        _approveTransaction(txnId_, msg.sender);
    }

    // private functions -------------------------------------------------
    function _approveTransaction(uint256 txnId_, address approver_) internal {
        Signer memory signer = signers[approver_];
        Transaction storage transaction = transactions[txnId_];
        transaction.approval += signer.weight;
        emit TransactionApproved(txnId_, approver_);
        // transaction.approvedBy.push(approver_);

        if (transaction.approval * 100 >= 51 * _signerCount) {
            _executeTransaction(txnId_, approver_);
        }
    }

    function _executeTransaction(uint256 txnId_, address approver_) internal {
        Transaction storage txn = transactions[txnId_];
        payable(txn.to).transfer(txn.amount);
        txn.executed = true;
        _lockedBalance -= txn.amount;
        emit TransactionExecuted(txnId_, approver_);
    }
}