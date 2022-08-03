// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAstroSapiens_NFT {

    function withdraw() external;

    function AllowSaleAction() external;

    function VIPSaleAction() external;

    function VIPSale2Action() external;

    function GiftList(uint256 _start, uint256 end) external;

    function OnwershipChange(address _newOnwer) external;
}

contract MultiSigWallet {

    // @dev Owners address
    address[] public owners;

    // @dev Codition to check still Owner address or not
    mapping(address => bool) public isOwner;
    // @dev Min number of confirmation
    uint public numConfirmationsRequired;

    // @dev NFT smart contract interface
    IAstroSapiens_NFT public immutable NFT_Astro_Address;

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    mapping(uint => mapping(address => bool)) public isConfirmedwt;

    struct Transaction {
        uint256 ID;
        uint numConfirmations;
        bool executed;
    }


    Transaction[] public transactions;

    /** 
    * @dev _owners : Admins
    * @dev _numConfirmationsRequired : Number of Vote required
    */
    constructor(address[] memory _owners, uint _numConfirmationsRequired,address _smartContract) {
        require(_owners.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        NFT_Astro_Address = IAstroSapiens_NFT(_smartContract); 
    }

    event Deposit(address indexed sender, uint amount, uint balance);
    event CreateVoting( address indexed owner, uint indexed txIndex);
    event Voting(address indexed owner, uint indexed txIndex);
    event ExecuteWithdrawal(address indexed owner, uint indexed txIndex);
    event ExecuteAllowSale(address indexed owner, uint indexed txIndex);
    event ExecuteVIPSale(address indexed owner, uint indexed txIndex);
    event ExecuteVIP2Sale(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ConfirmTransaction(address indexed owner, uint indexed wtIndex);
    event ExecuteTransaction(address indexed owner, uint indexed wtIndex);
    event CreatePermission(address indexed owner, uint indexed pIndexed);
    event AllowPermission(address  indexed owner,uint indexed pIndexed);
    event SubmitTransaction( address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only Owners allowed!");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier wtExists(uint _wtIndex) {
        require(_wtIndex < walletTransfers.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notExecutedwt(uint _wtIndex) {
        require(!walletTransfers[_wtIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier notConfirmedwt(uint _wtIndex) {
        require(!isConfirmedwt[_wtIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner],"Onwer not exits");
        _;
    }

     modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    function createVoting() public onlyOwner {
        uint txIndex = transactions.length;
        transactions.push (
            Transaction({
                ID : txIndex,
                numConfirmations : 0,
                executed : false
            })
        );
        emit CreateVoting(msg.sender, txIndex);
    }

    function voting(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit Voting(msg.sender, _txIndex);
    }

    function executeWithdrawal(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");
        transaction.executed = true;
        NFT_Astro_Address.withdraw();
        emit ExecuteWithdrawal(msg.sender, _txIndex);
    }

    function executeAllowSale(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        transaction.executed = true;
        NFT_Astro_Address.AllowSaleAction();
        emit ExecuteAllowSale(msg.sender, _txIndex);
    }

    function executeVIPSale(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        transaction.executed = true;
        NFT_Astro_Address.VIPSaleAction();
        emit ExecuteVIPSale(msg.sender, _txIndex);
    }

    function executeVIP2Sale(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        transaction.executed = true;
        NFT_Astro_Address.VIPSaleAction();
        emit ExecuteVIPSale(msg.sender, _txIndex);
    }

    function executeOwnerChange(uint _txIndex,address newOwner) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        transaction.executed = true;
        NFT_Astro_Address.OnwershipChange(newOwner);
        emit ExecuteVIPSale(msg.sender, _txIndex);
    }

    function ChangeOwner(uint _txIndex, address oldOwner, address _newWalletAddress) public onlyOwner ownerExists(oldOwner) ownerDoesNotExist(_newWalletAddress) notExecuted(_txIndex) txExists(_txIndex) {
         Transaction storage transaction = transactions[_txIndex];
        for (uint i = 0; i < owners.length;i++) {
            if (owners[i] == oldOwner) {
                owners[i] = _newWalletAddress;
                break;
            }
            isOwner[oldOwner] = false;
            isOwner[_newWalletAddress] = true;
            transaction.executed = true;
        }
    }


    function getRevokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
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

    function getTransaction(uint _txIndex) public view returns(uint numConfirmations, bool executed) {
        Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.numConfirmations,
             transaction.executed
        );
    }

    function allowPermisson(uint _txIndex) public onlyOwner notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        emit AllowPermission(msg.sender, _txIndex);
    }

    

    struct WalletTransfer {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    WalletTransfer[] public walletTransfers;

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint wtIndex = walletTransfers.length;

        walletTransfers.push(
            WalletTransfer({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, wtIndex, _to, _value, _data);
    }


    function confirmTransaction(uint _wtIndex)
        public
        onlyOwner
        wtExists(_wtIndex)
        notExecutedwt(_wtIndex)
        notConfirmedwt(_wtIndex)
    {
        WalletTransfer storage walletTransfer = walletTransfers[_wtIndex];
        walletTransfer.numConfirmations += 1;
        isConfirmedwt[_wtIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _wtIndex);
    }

    function executeTransaction(uint _wtIndex) public onlyOwner wtExists(_wtIndex) notExecutedwt(_wtIndex) {

        WalletTransfer storage walletTransfer = walletTransfers[_wtIndex];

        require( walletTransfer.numConfirmations >= numConfirmationsRequired, "cannot execute tx");

        walletTransfer.executed = true;

        (bool success, ) = walletTransfer.to.call{value: walletTransfer.value}(
            walletTransfer.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _wtIndex);
    }

}