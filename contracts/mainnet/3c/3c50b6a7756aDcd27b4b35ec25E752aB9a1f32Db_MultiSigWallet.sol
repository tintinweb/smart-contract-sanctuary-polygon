/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data)
        external
        onlyOwner
    {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));

        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId)
        private
        view
        returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

      function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
            require(_getApprovalCount(_txId) >= required, "cannot execute tx");
            Transaction storage txn = transactions[_txId];
            (bool success, ) = txn.to.call{value: txn.value}(txn.data);
            require(success, "tx failed");
            txn.executed = true;

            emit Execute(_txId);
      }

      function revoke(uint _txId)
            external
            onlyOwner
            txExists(_txId)
            notExecuted(_txId)
      {
            require(approved[_txId][msg.sender], "tx not approved");
            approved[_txId][msg.sender] = false;
            emit Revoke(msg.sender, _txId);
      }
}