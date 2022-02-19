/**
 *Submitted for verification at polygonscan.com on 2022-02-18
*/

pragma solidity ^0.8.7;

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Reward {

    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed to,
        uint indexed txIndex,
        uint value
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event TransactionDeclined(address indexed owner, uint indexed txIndex);

    address[] public owners;
    address public admin;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    address public Treasury;
    IERC20 public hiveToken;

    struct Transaction {
        address to;
        uint value;
        uint8 txType;
        bool executed;
        uint numConfirmations;
        bool declined;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
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

    modifier notDeclined(uint _txIndex) {
        require(!transactions[_txIndex].declined, "tx declined");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == Treasury, "Not authorized to edit team members!");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired, address _token, address _treasury) {
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

        admin = msg.sender;
        numConfirmationsRequired = _numConfirmationsRequired;
        hiveToken = IERC20(_token);
        Treasury = _treasury;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    modifier checkBalance(uint value, uint txType) {
        if(txType == 1) {
            require(address(this).balance >= value, "Insufficient matic balance");
        } else {
            require(hiveToken.balanceOf(address(this)) >= value, "Insufficient token balance");
        }

        _;
    }

    function submitTransaction(
        uint _value,
        uint8 _txType
    ) public onlyOwner checkBalance(_value, _txType) {

        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: msg.sender,
                value: _value,
                txType: _txType,
                executed: false,
                numConfirmations: 0,
                declined: false
            })
        );

        isConfirmed[txIndex][msg.sender] = true;
        emit SubmitTransaction(msg.sender, txIndex, _value);
    }

    function TransferOwnership(address Admin) public onlyAdmin{
        admin=Admin; 
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        notDeclined(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);

        if(transaction.numConfirmations >= numConfirmationsRequired) {
            executeTransaction(_txIndex);
        }
    }

    function executeTransaction(uint _txIndex)
        private
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notDeclined(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require( isOwner[transaction.to], "To address is not the owner!");

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        //Tx types /////////////////////////////////////////////////////////////
        // 1 -- Matic
        // 2 -- Hive token
        ////////////////////////////////////////////////////////////////////////

        if(transaction.txType == 1) {
            require(address(this).balance >= transaction.value, "Insufficient matic balance to withdraw");
            payable(transaction.to).transfer(transaction.value);
        } else {
            require(hiveToken.balanceOf(address(this)) >= transaction.value, "Insufficient token balance to withdraw");
            hiveToken.transfer(transaction.to, transaction.value);
        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }
    function declineTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notDeclined(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.declined = true;

        emit TransactionDeclined(msg.sender, _txIndex);
    }

    function addTeamMember(address _addr) external onlyTreasury {
        owners.push(_addr);
        isOwner[_addr] = true;
        numConfirmationsRequired += 1;
    }

    function removeTeamMember(address _addr) external onlyTreasury {
        require(isOwner[_addr], "The input address is not an owner");

        for(uint256 i = 0; i < owners.length; i++) {
            if(owners[i] == _addr) {
                owners[i] = owners[owners.length - 1];
                delete isOwner[_addr];
                owners.pop();
                numConfirmationsRequired -= 1;
                break;
            }
        }
    }


    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            uint8 txType,
            bool executed,
            uint numConfirmations,
            bool declined
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.txType,
            transaction.executed,
            transaction.numConfirmations,
            transaction.declined
        );
    }
}