/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Token {
    string private _name = "HIGH-DOL";
    string private constant _symbol = "IDOL";
    uint256 private  Total_supply = 500000000000000000000000;
    uint256 private constant decimals = 18;
    uint256 private FirstRoundnumToken = 125000000000000000000000;
    uint256 public First_Round_Start_Date;
    uint256 public First_Round_End_Date;
    uint256 public Second_Round_End_Date;
    uint256 public Third_Round_End_Date;
    uint256 firstRoundBalance =125000000000000000000000;
    //first Round Stacking Periods
    uint256 _firstroundStacking_Period = 7257600;
    //Intial Tranferred Token in First Round
    uint256 public FirstRoundnumToken_initialToken = 0;
    //Time for first Round Transactions
    uint256 private firstroundTranfer_Time;
    //Wallet To store Total Supply
    address private MainWallet;
    //ROUND 1 : TEAM 17-23 October
    address private Team;
    // ROUND 2 : Private Angel 24-30 October
    address private Private_Angel;
    // ROUND 3 : Private VCs 31 Oct.- 06 Nov
    address private Private_VCs;
    //ROUND 4 : Public 07 October
    address private Public;
    //Tranferee Address appending
    mapping(address => bool) teamAppended;
    //Event for First Round
    event FirstRound_timeEvent(uint256 firstroundTranfer_Time);
    event EfirstroundTranfer(
        uint indexed txIndex,
        address indexed owner,
        address indexed to,
        uint256 value
    );
    //Events for Timestamp for all 4 Rounds
    event FirstRoundStart(uint256 timestamp);
    event FirstRoundEnd(uint256 timestamp);
    event SeconDroundEnd(uint256 timestamp);
    event ThirdRoundEnd(uint256 timestamp);
    //Array for all owners
    address[] public owners;
    mapping(address => bool) public isOwner;
    //For Multi Sign Confirmation
    uint public numConfirmationsRequired;
    //Mapping for balance in address
    mapping(address => uint256) balances;
    //Mapping for boolean to check transaction confirmed or not  (from tx index => owner => bool)
    mapping(uint => mapping(address => bool)) public isConfirmed;

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

    //event for MultiSign Wallet Transactions Confirmations
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    //Transaction Confirmation
     struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
    }
    Transaction[] public transactions;
    constructor(
        address[] memory _owners,
        address _MainWallet,
        address _Team,
        address _Private_Angel,
        address _Private_VCs,
        address _Public,
        uint256 _numConfirmationsRequired,
        uint256 _First_Round_Start_Date,
        uint256 _First_Round_End_Date,
        uint256 _Second_Round_End_Date,
        uint256 _Third_Round_End_Date
    ) {
        MainWallet = _MainWallet;
        Team = _Team;
        Private_Angel = _Private_Angel;
        Private_VCs = _Private_VCs;
        Public = _Public;
        balances[MainWallet] = Total_supply - FirstRoundnumToken;
        balances[_Team] += FirstRoundnumToken;
        First_Round_Start_Date = _First_Round_Start_Date;
        First_Round_End_Date = _First_Round_End_Date;
        Second_Round_End_Date = _Second_Round_End_Date;
        Third_Round_End_Date = _Third_Round_End_Date;
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
        emit FirstRoundStart(First_Round_Start_Date);
        emit FirstRoundEnd(First_Round_End_Date);
        emit SeconDroundEnd(Second_Round_End_Date);
        emit ThirdRoundEnd(Third_Round_End_Date);
    }

    function Name() public view returns (string memory) {
        return _name;
    }

    //First round Tranfer to Team
    function firstroundTranfer(address _to, uint256 _numToken)
        public
        onlyOwner
    {
        if (
            block.timestamp >= First_Round_Start_Date &&
            block.timestamp <= First_Round_End_Date
        ) {
            require(_numToken <= FirstRoundnumToken);
            require(
                FirstRoundnumToken_initialToken + _numToken <=
                    FirstRoundnumToken
            );
        }
        uint txIndex = transactions.length;
         transactions.push(
            Transaction({
                to: _to,
                value: _numToken,
                executed: false,
                numConfirmations: 0
            })
        );
        emit EfirstroundTranfer(txIndex, msg.sender, _to, _numToken);
        
    }



    //Transactions Confirmations by Owners
    function confirmTransaction(uint _txIndex)
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
    //After Confirmation Transactions will Wxecuted
    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
          address user=  transactions[_txIndex].to;
          uint VALUE=transactions[_txIndex].value;
          balances[user] +=VALUE;
           balances[Team] -= VALUE;
            FirstRoundnumToken_initialToken += VALUE;
            balances[Team] =
                FirstRoundnumToken -
                FirstRoundnumToken_initialToken;
            uint256 _firstRoundBalance = balances[Team];
            firstRoundBalance = _firstRoundBalance;
            firstroundTranfer_Time = block.timestamp;
           
           
          transaction.executed = true;
          emit FirstRound_timeEvent(firstroundTranfer_Time);
    }
    function backToMainWallet() public onlyOwner{
         if (block.timestamp > _firstroundStacking_Period) {
                balances[MainWallet] += firstRoundBalance;
            }
     
    }

    //cancel Transations
    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex) 
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function balanceOf(address _owner) public view virtual returns (uint256) {
        return balances[_owner];
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
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.executed,
            transaction.numConfirmations
        );
    }

}