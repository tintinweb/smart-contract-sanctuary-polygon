/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

// File contracts/MultiSigWallet.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*
aggiungere le funzioni per permettere di aggiungere e rimuovere partecipanti al multisig (addOwner, removeOwner),quindi implementare il sistema di 
votazione da parte dei membri per l aggiunta e la rimozione della nuova persona(vedere sistema votazione transazione).

implementare per questo multisig l utilizzo di erc20 e erc721 (capire se implementare 1155)
BISOGNA IMPLEMENTARE INTERFACCIA, DEPOSIT, WITHDRAW E EXECUTION


*/

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

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

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(
        uint _txIndex
    )
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // questa funzione non funziona è da rivedere PROBLEMA CON I DATA
    function executeTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
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
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    event AddOwner(address indexed owner, uint indexed operationIndex);
    event ConfirmAddOwner(address indexed owner, uint indexed operationIndex);
    event ExecuteAddOwner(
        address indexed owner,
        address indexed newOwner,
        uint indexed operationIndex
    );

    struct AddOwnerOperation {
        address newOwner;
        bool executed;
        uint numConfirmations;
    }

    // mapping from operation index => owner => bool
    mapping(uint => mapping(address => bool)) public isAddOwnerConfirmed;

    AddOwnerOperation[] public addOwnerOperations;

    function submitAddOwner(address _newOwner) public onlyOwner {
        require(!isOwner[_newOwner], "Address is already an owner");

        uint operationIndex = addOwnerOperations.length;

        addOwnerOperations.push(
            AddOwnerOperation({
                newOwner: _newOwner,
                executed: false,
                numConfirmations: 0
            })
        );

        emit AddOwner(_newOwner, operationIndex);
    }

    function confirmAddOwner(uint _operationIndex) public onlyOwner {
        require(
            _operationIndex < addOwnerOperations.length,
            "Operation does not exist"
        );
        require(
            !addOwnerOperations[_operationIndex].executed,
            "Operation already executed"
        );
        require(
            !isAddOwnerConfirmed[_operationIndex][msg.sender],
            "Operation already confirmed"
        );

        AddOwnerOperation storage operation = addOwnerOperations[
            _operationIndex
        ];
        operation.numConfirmations += 1;
        isAddOwnerConfirmed[_operationIndex][msg.sender] = true;

        emit ConfirmAddOwner(msg.sender, _operationIndex);
    }

    function executeAddOwner(uint _operationIndex) public onlyOwner {
        require(
            _operationIndex < addOwnerOperations.length,
            "Operation does not exist"
        );

        AddOwnerOperation storage operation = addOwnerOperations[
            _operationIndex
        ];

        require(!operation.executed, "Operation already executed");
        require(
            operation.numConfirmations >= numConfirmationsRequired,
            "Not enough confirmations"
        );

        operation.executed = true;
        isOwner[operation.newOwner] = true;
        owners.push(operation.newOwner);

        emit ExecuteAddOwner(msg.sender, operation.newOwner, _operationIndex);
    }

    event RemoveOwner(address indexed owner, uint indexed operationIndex);
    event ConfirmRemoveOwner(
        address indexed owner,
        uint indexed operationIndex
    );
    event ExecuteRemoveOwner(
        address indexed owner,
        address indexed removedOwner,
        uint indexed operationIndex
    );

    struct RemoveOwnerOperation {
        address ownerToRemove;
        bool executed;
        uint numConfirmations;
    }

    // mapping from operation index => owner => bool
    mapping(uint => mapping(address => bool)) public isRemoveOwnerConfirmed;

    RemoveOwnerOperation[] public removeOwnerOperations;

    function submitRemoveOwner(address _ownerToRemove) public onlyOwner {
        require(isOwner[_ownerToRemove], "Address is not an owner");
        require(
            owners.length > numConfirmationsRequired,
            "Cannot remove owner when there are not enough owners left"
        );

        uint operationIndex = removeOwnerOperations.length;

        removeOwnerOperations.push(
            RemoveOwnerOperation({
                ownerToRemove: _ownerToRemove,
                executed: false,
                numConfirmations: 0
            })
        );

        emit RemoveOwner(_ownerToRemove, operationIndex);
    }

    function confirmRemoveOwner(uint _operationIndex) public onlyOwner {
        require(
            _operationIndex < removeOwnerOperations.length,
            "Operation does not exist"
        );
        require(
            !removeOwnerOperations[_operationIndex].executed,
            "Operation already executed"
        );
        require(
            !isRemoveOwnerConfirmed[_operationIndex][msg.sender],
            "Operation already confirmed"
        );

        RemoveOwnerOperation storage operation = removeOwnerOperations[
            _operationIndex
        ];
        operation.numConfirmations += 1;
        isRemoveOwnerConfirmed[_operationIndex][msg.sender] = true;

        emit ConfirmRemoveOwner(msg.sender, _operationIndex);
    }

    function executeRemoveOwner(uint _operationIndex) public onlyOwner {
        require(
            _operationIndex < removeOwnerOperations.length,
            "Operation does not exist"
        );

        RemoveOwnerOperation storage operation = removeOwnerOperations[
            _operationIndex
        ];

        require(!operation.executed, "Operation already executed");
        require(
            operation.numConfirmations >= numConfirmationsRequired,
            "Not enough confirmations"
        );

        operation.executed = true;
        isOwner[operation.ownerToRemove] = false;
        // putting ownerToRemove at end of array and then removing it
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == operation.ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        emit ExecuteRemoveOwner(
            msg.sender,
            operation.ownerToRemove,
            _operationIndex
        );
    }
}


// File contracts/factory.sol

//controllare questa factory


pragma solidity ^0.8.17;

contract MultiSigWalletFactory {
    event MultiSigWalletDeployed(
        address indexed wallet,
        address indexed creator
    );

    MultiSigWallet[] public deployedWallets;

    function createMultiSigWallet(
        address[] memory _owners,
        uint _numConfirmationsRequired
    ) public returns (MultiSigWallet) {
        MultiSigWallet newWallet = new MultiSigWallet(
            _owners,
            _numConfirmationsRequired
        );
        deployedWallets.push(newWallet);

        emit MultiSigWalletDeployed(address(newWallet), msg.sender);
        return newWallet;
    }

    function getDeployedWalletsCount() public view returns (uint) {
        return deployedWallets.length;
    }
}