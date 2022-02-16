/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

pragma solidity ^0.8.10;

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

interface RewardPool {
    function withdraw(address, uint, uint8) external;
}
interface Treasury{
   function withdraw(address, uint, uint8) external;  
}

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
    event TransactionDeclined(address indexed owner, uint indexed txIndex);

    address[] public owners;
    address public admin;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    IERC20 public hiveToken;
    RewardPool public rewardPool;
    Treasury public treasury;

    struct Transaction {
        address to;
        uint value;
        bytes data;
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

    constructor(address[] memory _owners, uint _numConfirmationsRequired, address _token, address _reward,address _treasury) {
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
        rewardPool = RewardPool(_reward);
        treasury = Treasury(_treasury);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value,
        uint8 _txType,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                txType: _txType,
                executed: false,
                numConfirmations: 0,
                declined: false
            })
        );

        isConfirmed[txIndex][msg.sender] = true;
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }
    function ChangeAdmin(address Admin) public onlyAdmin{
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
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notDeclined(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        //Tx types /////////////////////////////////////////////////////////////
        // 10 -- Treasury Matic
        // 11 -- Treasury Hive token
        // 20 -- Reward Matic
        // 21 -- Reward Hive token
        ////////////////////////////////////////////////////////////////////////

        if(transaction.txType == 10) {
            treasury.withdraw(transaction.to, transaction.value, 1);
        } else if(transaction.txType == 11) {
            treasury.withdraw(transaction.to, transaction.value, 2); 
        } else if(transaction.txType == 20) {
            rewardPool.withdraw(transaction.to, transaction.value, 1);
        } else {
            rewardPool.withdraw(transaction.to, transaction.value, 2);
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

    function addOwners(address _addr) public onlyAdmin {
        owners.push(_addr);
        isOwner[_addr] = true;
        numConfirmationsRequired += 1;
    }

    function removeOwners(address _addr) public onlyAdmin {
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
            bytes memory data,
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
            transaction.data,
            transaction.executed,
            transaction.numConfirmations,
            transaction.declined
        );
    }
}