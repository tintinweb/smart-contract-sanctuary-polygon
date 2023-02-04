// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721.sol";

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bool nftTx,
        address nftContract,
        uint nftId
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    address constant private zeroAddress = 0x1e27d6FE25B54164F4226fAe7F5042be599132FC;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
        bool nftTx;
        address nftContract;
        uint nftId;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    mapping(uint => mapping(address => bool)) public isCreator;

    Transaction[] private _transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < _transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!_transactions[_txIndex].executed, "tx already executed");
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

    function submitTokenTransaction(
        address _to,
        uint _value
    ) external onlyOwner {
        uint txIndex = _transactions.length;

        _transactions.push(
            Transaction({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0,
                nftTx: false,
                nftContract: zeroAddress,
                nftId: 0
            })
        );

        isCreator[txIndex][msg.sender] = true;

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, false, zeroAddress, 0);
    }

    function submitNFTTransaction(
        address _to,
        address nftContract,
        uint nftId
    ) external onlyOwner {
        uint txIndex = _transactions.length;

        _transactions.push(
            Transaction({
                to: _to,
                value: 0,
                executed: false,
                numConfirmations: 0,
                nftTx: true,
                nftContract: nftContract,
                nftId: nftId
            })
        );

        isCreator[txIndex][msg.sender] = true;

        emit SubmitTransaction(msg.sender, txIndex, _to, 0, true, nftContract, nftId);
    }

    function confirmTransaction(uint _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = _transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTokenTransaction(uint _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = _transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function executeNFTTransaction(uint _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = _transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        ERC721 nft = ERC721(transaction.nftContract);
        nft.safeTransferFrom(address(this), transaction.to, transaction.nftId);
        transaction.executed = true;

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = _transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint) {
        return _transactions.length;
    }

    function getTransaction(uint _txIndex)
        external
        view
        returns (Transaction memory)
    {
        Transaction memory transaction = _transactions[_txIndex];
        return transaction;
    }

    function getTransactionHistory() external view returns (Transaction[] memory) {
        Transaction[] memory localList = new Transaction[](_transactions.length);
        for (uint i = 0; i < _transactions.length; i++) {
            if (_transactions[i].executed == true) {
                localList[i] = _transactions[i];
            }
        }
        return localList;
    }

    function getPendingTxs(address wallet) external view returns (uint[] memory) {
        uint[] memory localList = new uint[](_transactions.length);
        for (uint i = 0; i < _transactions.length; i++) {
            if (!isConfirmed[i][wallet] && !_transactions[i].executed) {
                localList[i] = i+1;
            }
        }
        return localList;
    }

    function getPendingToExecuteTxs(address wallet) external view returns (uint[] memory) {
        uint[] memory localList = new uint[](_transactions.length);
        for (uint i = 0; i < _transactions.length; i++) {
            if (
                !_transactions[i].executed && 
                _transactions[i].numConfirmations >= numConfirmationsRequired && 
                isCreator[i][wallet]
            ) {
                localList[i] = i+1;
            }
        }
        return localList;
    }

    function cleanTxHistory() external onlyOwner {
        delete _transactions;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface ERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}