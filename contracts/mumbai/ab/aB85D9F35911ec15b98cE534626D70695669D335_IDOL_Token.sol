/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract IDOL_Token {
    string private _name = "HIGH-DOL";
    string private constant _symbol = "IDOL";
    uint256 private Total_supply = 500000000000000000000000;
    uint256 private constant decimals = 18;

    //Token Distribution Between 4 Rounds
    uint256 private FirstRoundnumToken = 125000000000000000000000;
    uint256 private SecondRoundnumToken = 37500000000000000000000;
    uint256 private ThirdRoundnumToken = 62500000000000000000000;
    uint256 private ForthRoundnumToken = 200000000000000000000000;
    //Tokens for Bonus in each Rounds
    uint256 private FirstRoundBonusTokens = 2000000000000000000000;
    uint256 private SecondRoundBonusTokens = 2000000000000000000000;
    uint256 private ThirdRoundBonusTokens = 2000000000000000000000;
    uint256 private ForthRoundBonusTokens = 3000000000000000000000;
    //Rounds Start and End Dates
    uint256 public First_Round_Start_Date;
    uint256 public First_Round_End_Date;
    uint256 public Second_Round_End_Date;
    uint256 public Third_Round_End_Date;

    //Price of IDOL per matic
    uint256 public Private_Angel_Price = 1000; // for Testing Purpose per 1 matic beacuse 5$ =6.25
    uint256 public Private_VCs_Price = 666;
    uint256 public Public_Price = 500;

    //FirstRoundBalance if none Trascation cofirm it will transfer to Main Balance after stacking Periods
    uint256 public firstRoundBalance = 125000000000000000000000;
    //SecondRoundBalance
    uint256 public SecondRoundBalance = 37500000000000000000000;
    //thirdRoundBalance
    uint256 public ThirdRoundBalance = 62500000000000000000000;
    //first Round Stacking Period
    uint256 _firstroundStacking_Period = 7257600;
    //Second Round Stacking Period
    uint256 _secondroundStacking_Period = 6048000;
    //event for second round stacking Period
    event secondRoundStack(uint256 timestamp);
    //Third Round Sracking Period
    uint256 _thirdroundStacking_Period = 4838400;
    //event event for third round stacking Period
    event thirdRoundStack(uint256 timestamp);
    event forthRoundStack(uint256 timestamp);
    uint256 _forthroundStacking_Period = 3628800;
    uint256 _TxCount = 0;
    //Intial Tranferred Token in First Round
    uint256 public FirstRoundnumToken_initialToken = 0;
    //Intial Tranferred Token in Second Round
    uint256 public SecondRoundnumToken_initialToken = 0;
    //Intial Tranferred Token in Third Round
    uint256 public ThirdRoundnumToken_initialToken = 0;
    //Intial Tranferred Token in Forth Round
    uint256 public ForthRoundnumToken_initialToken = 0;
    // uint256 private FirstRBonusAmount;
    uint256 public FirstRBonusAmount;
    event EFirstRBonusAmount (uint256 FirstRBonusAmount, uint256 FirstRliquidityPool);
    // uint256 private SecondRBonusAmount;
    uint256 public SecondRBonusAmount;
    event ESecondRBonusAmount (uint256 SecondRBonusAmount, uint256 FirstRliquidityPool);
    // uint256 private ThirdRBonusAmount;
    uint256 public ThirdRBonusAmount;
    event EThirdRBonusAmount (uint256 ThirdRBonusAmount, uint256 ThirdRliquitityPool);
    uint256 public ForthRBonusAmount;
    event EForthRBonusAmount (uint256 ThirdRBonusAmount, uint256 ForthRliquitityPool);
    //Liquidity Pools
    uint256 public FirstRliquidityPool;
    uint256 public SecondRliquidityPool;
    uint256 public ThirdRliquitityPool;
    uint256 public ForthRliquitityPool;
    //Time for first Round Transactions
    uint256 private firstroundTranfer_Time;
    //Time for Second Round
    uint256 private SecondroundBuy_Time;
    //Time for Third Round
    uint256 private ThirdroundBuy_Time;
    //Time for Forth Round
    uint256 private ForthroundBuy_Time;
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
    //for remaining transfer to main wallet
    uint256 private count;
    //tranfer Tokens after Confirmation
    uint256 private NumofTokens;
    //Tranferee Address appending
    mapping(address => bool) ownerAppended;
    //Events for Return Trsacations Index
     event EFirstRoundTrasactions(uint256 txnIndex, address, uint _value);
    //Event for First Round Transactions Time
    event FirstRound_timeEvent(uint256 firstroundTranfer_Time);
    //Event for Second Round Transactions Time
    event SecondRound_timeEvent(uint256 SecondroundBuy_Time);
    //Event for Third Round Transactions Time
    event ThirdRound_timeEvent(uint256 ThirdroundBuy_Time);
    //Event for Forth Round Transactions Time
    event ForthRound_timeEvent(uint256 ForthroundBuy_Time);
    //First Round Transfer Events
    uint calcuationofTotal;
    event EfirstroundTranfer(
        uint256 indexed txIndex,
        address indexed owner,
        address indexed to,
        uint256 value,
        uint256 timestamp
    );
    //Second Round Transfer Events
    event ESecondroundTranfer(
        uint256 indexed txIndex,
        address indexed owner,
        address indexed to,
        uint256 SecondRoundnumToken_initialToken,
        uint256 TransferToWallet,
        uint256 timestamp
    );
    //Third Round Transfer Events
    event EThirdroundTranfer(
        uint256 indexed txIndex,
        address indexed owner,
        address indexed to,
        uint256 ThirdRoundnumToken_initialToken,
        uint256 TransferToWallet,
        uint256 timestamp
    );
    event EForthroundTranfer(
        uint256 indexed txIndex,
        address indexed owner,
        address indexed to,
        uint256 ThirdRoundnumToken_initialToken,
        uint256 TransferToWallet,
        uint256 timestamp
    );
    //Forth Round Transfer Events
    event EForthroundTranfer(
        uint256 indexed txIndex,
        address indexed owner,
        address indexed to,
        uint256 value,
        uint256 timestamp
    );
    //Events for Timestamp for all 4 Rounds
    event FirstRoundStart(uint256 timestamp);
    event FirstRoundEnd(uint256 timestamp);
    event SeconDroundEnd(uint256 timestamp);
    event ThirdRoundEnd(uint256 timestamp);
    //Events for transactionTime and Stacking Periods
    event FirstRoundStack(uint256 timestamp, uint256 stackPeriods);
    //Events for Transfer Token into User Wallets after Stacking periods
    event EFirstTranferTowallet(
        address indexed _user,
        uint256 timestamp,
        uint256 _value
    );
    event ESecondTranferTowallet(
        address indexed _user,
        uint256 timestamp,
        uint256 _value
    );
    event EThirdTranferTowallet(
        address indexed _user,
        uint256 timestamp,
        uint256 _value
    );
     event EForthTranferTowallet(
        address indexed _user,
        uint256 timestamp,
        uint256 _value
    );
    //Array for all owners
    address[] public owners;
    //for checking owner or not?
    mapping(address => bool) public isOwner;
    //For Multi Sign Confirmation
    uint256 public numConfirmationsRequired;
    //Mapping for balance in address
    mapping(address => uint256) balances;
    //Mapping for boolean to check transaction confirmed or not  (from tx index => owner => bool)
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    //maping for Number of Tokens Tranfer to Users
    mapping(uint256 => mapping(address => uint256)) private numberOfTokens;
    //Maping for Stacking Lock Periods
    mapping(uint256 => mapping(address => uint256)) private locktime;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    //event for MultiSign Wallet Transactions Confirmations
    event FirstRoundTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        uint256 FirstRoundnumToken_initialToken,
        uint256 _actualToWallet,
        uint _Lock
    );
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    //Events for TokenDistibutions for Rounds
    event EFirstRoundnumToken(uint256 _FirstRoundnumTokens);
    event ESecondRoundnumToken(uint256 _SecondRoundnumToken);
    event EThirdRoundnumToken(uint256 _ThirdRoundnumToken);
    event EForthRoundnumToken(uint256 _ForthRoundnumToken);
    //Transaction Confirmation
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }
    Transaction[] public transactions;

    constructor(
        address[] memory _founders,
        address _MainWallet,
        address _Team,
        address _Private_Angel,
        address _Private_VCs,
        address _Public,
        uint256 _numConfirmationsRequired
        // uint256 _First_Round_Start_Date,
        // uint256 _First_Round_End_Date,
        // uint256 _Second_Round_End_Date,
        // uint256 _Third_Round_End_Date
    ) {
        MainWallet = _MainWallet;
        Team = _Team;
        Private_Angel = _Private_Angel;
        Private_VCs = _Private_VCs;
        Public = _Public;
        balances[MainWallet] = Total_supply;
        balances[MainWallet] -= FirstRoundnumToken;
        balances[Team] += FirstRoundnumToken;
        balances[MainWallet] -= SecondRoundnumToken;
        balances[Private_Angel] += SecondRoundnumToken;
        balances[MainWallet] -= ThirdRoundnumToken;
        balances[Private_VCs] += ThirdRoundnumToken;
        balances[MainWallet] -= ForthRoundnumToken;
        balances[Public] += ForthRoundnumToken;
        // First_Round_Start_Date = _First_Round_Start_Date;
        // First_Round_End_Date = _First_Round_End_Date;
        // Second_Round_End_Date = _Second_Round_End_Date;
        // Third_Round_End_Date = _Third_Round_End_Date;
        require(_founders.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _founders.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _founders.length; i++) {
            address owner = _founders[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
        // emit FirstRoundStart(First_Round_Start_Date);
        // emit FirstRoundEnd(First_Round_End_Date);
        // emit SeconDroundEnd(Second_Round_End_Date);
        // emit ThirdRoundEnd(Third_Round_End_Date);
        //Tokens for Each Rounds
        emit EFirstRoundnumToken(FirstRoundnumToken);
        emit ESecondRoundnumToken(SecondRoundnumToken);
        emit EThirdRoundnumToken(ThirdRoundnumToken);
        emit EForthRoundnumToken(ForthRoundnumToken);
    }
    function Timestamp (uint256 _First_Round_Start_Date,
        uint256 _First_Round_End_Date,
        uint256 _Second_Round_End_Date,
        uint256 _Third_Round_End_Date) public onlyOwner returns(bool){
        First_Round_Start_Date = _First_Round_Start_Date;
        First_Round_End_Date = _First_Round_End_Date;
        Second_Round_End_Date = _Second_Round_End_Date;
        Third_Round_End_Date = _Third_Round_End_Date;
        emit FirstRoundStart(First_Round_Start_Date);
        emit FirstRoundEnd(First_Round_End_Date);
        emit SeconDroundEnd(Second_Round_End_Date);
        emit ThirdRoundEnd(Third_Round_End_Date);
        return true;
        }


    //ROUND 1 : TEAM (17-23 October) Tokens 1,25,000
    function firstroundTransfer(address _to, uint256 _numToken)
        public
        onlyOwner
    {
        if (
            block.timestamp > First_Round_Start_Date &&
            block.timestamp <= First_Round_End_Date
        ) {
            require(
                _numToken <= FirstRoundnumToken,
                "Number should be less than allocation "
            );
            require(
                FirstRoundnumToken_initialToken + _numToken <=
                    FirstRoundnumToken,
                "Not Enough Balance in this round"
            );
            transactions.push(
                Transaction({
                    to: _to,
                    value: _numToken,
                    executed: false,
                    numConfirmations: 0
                })
            );
            uint256 txIndex = transactions.length-1;
            emit EFirstRoundTrasactions(txIndex, _to, _numToken);
        } else if (block.timestamp > First_Round_End_Date) {
            balances[Team] -= firstRoundBalance;
            balances[MainWallet] += firstRoundBalance;
        }
    }

    function BuyTokens(address _buyer, uint256 numOfTokens)
        public
        returns (uint256 _Txid)
    {
        require(
            block.timestamp > First_Round_End_Date,
            "Second Round Start Soon..!"
        );
        //ROUND 2 : Private Angel (24-30 October) Tokens 37500
        if (
            block.timestamp > First_Round_End_Date &&
            block.timestamp <= Second_Round_End_Date
        ) {
            if (balances[Team] > 0) {
                balances[Team] -= firstRoundBalance;
                balances[MainWallet] += firstRoundBalance;
            }
            require(
                numOfTokens >= 10000000000000000000 &&
                    numOfTokens <= 5000000000000000000000,
                "buy Between Miniimum 20 tokens and maximum 5000 Tokens"
            );
            SecondroundBuy_Time = block.timestamp;
            require(
                numOfTokens <= SecondRoundnumToken,
                "Number should be less than allocation"
            );
            require(
                SecondRoundnumToken_initialToken + numOfTokens <=
                    SecondRoundnumToken,
                "Not Enough Balance in this round"
            );
            balances[Private_Angel] -= numOfTokens;
            numberOfTokens[_TxCount][_buyer] = numOfTokens;
            SecondRoundnumToken_initialToken += numOfTokens;
            // uint256 confirm_time =block.timestamp + 6048000;
            uint256 confirm_time = block.timestamp + 120;
            locktime[_TxCount][_buyer] = confirm_time;
            _TxCount += 1;
            //balances[_buyer] += numOfTokens;

            balances[Private_Angel] =
                SecondRoundnumToken -
                SecondRoundnumToken_initialToken;
            uint256 _SecondRoundBalance = balances[Private_Angel];
            SecondRoundBalance = _SecondRoundBalance;

            if (!ownerAppended[_buyer]) {
                ownerAppended[_buyer] = true;
                owners.push(_buyer);
            }
            emit ESecondroundTranfer(
                _Txid,
                msg.sender,
                _buyer,
                SecondRoundnumToken_initialToken,
                numOfTokens,
                SecondroundBuy_Time
            );
            emit SecondRound_timeEvent(SecondroundBuy_Time);
            emit secondRoundStack(_secondroundStacking_Period);
        }
        //ROUND 3 : Private VCs (31 Oct.- 06 Nov) Tokens 62,500
        else if (
            block.timestamp > Second_Round_End_Date &&
            block.timestamp <= Third_Round_End_Date
        ) {
            if (count == 0) {
                if (balances[Team] > 0) {
                    balances[Team] -= firstRoundBalance;
                    balances[MainWallet] += firstRoundBalance;
                }
                balances[Private_Angel] -= SecondRoundBalance;
                balances[MainWallet] += SecondRoundBalance;
                count += 1;
            }
            require(
                numOfTokens >= 500000000000000000000 &&
                    numOfTokens <= 12500000000000000000000,
                "buy Between Miniimum 500 tokens and maximum 12500 Tokens"
            );
            ThirdroundBuy_Time = block.timestamp;
            require(
                numOfTokens <= ThirdRoundnumToken,
                "Number should be less than allocation"
            );
            require(
                ThirdRoundnumToken_initialToken + numOfTokens <=
                    ThirdRoundnumToken,
                "Not Enough Balance in this round"
            );
            balances[Private_VCs] -= numOfTokens;
            // balances[_buyer] += numOfTokens;
            numberOfTokens[_TxCount][_buyer] = numOfTokens;
            ThirdRoundnumToken_initialToken += numOfTokens;
            // uint256 confirm_time =block.timestamp + 4838400;
            uint256 confirm_time = block.timestamp + 4838400;
            locktime[_TxCount][_buyer] = confirm_time;
            _TxCount = 1;
            ThirdRoundnumToken_initialToken += numOfTokens;
            balances[Private_VCs] =
                ThirdRoundnumToken -
                ThirdRoundnumToken_initialToken;
            uint256 _ThirdRoundBalance = balances[Private_VCs];
            ThirdRoundBalance = _ThirdRoundBalance;

            if (!ownerAppended[_buyer]) {
                ownerAppended[_buyer] = true;
                owners.push(_buyer);
            }
        
            emit EThirdroundTranfer(
                _Txid,
                msg.sender,
                _buyer,
                ThirdRoundnumToken_initialToken,
                numOfTokens,
                ThirdroundBuy_Time
            );
            emit ThirdRound_timeEvent(ThirdroundBuy_Time);
            emit thirdRoundStack(_thirdroundStacking_Period);
        }
        //ROUND 4 : Public 07 October Tokens 200,000
        

        return _Txid++;
    }
     function PublicBuy(address _buyer, uint256 numOfTokens, bool _NeedStack )
        public
        returns (uint256 _Txid){
            if(_NeedStack ==false){
                require (block.timestamp > Third_Round_End_Date,"Public Sale start Soon");
            if (count == 0) {
                if (balances[Team] > 0) {
                    balances[Team] -= firstRoundBalance;
                    balances[MainWallet] += firstRoundBalance;
                }
                balances[Private_Angel] -= SecondRoundBalance;
                balances[MainWallet] += SecondRoundBalance;
                balances[Private_VCs] -= ThirdRoundBalance;
                balances[MainWallet] += ThirdRoundBalance;
                count += 2;
            } else if (count == 1) {
                if (balances[Team] > 0) {
                    balances[Team] -= firstRoundBalance;
                    balances[MainWallet] += firstRoundBalance;
                }
                balances[Private_VCs] -= ThirdRoundBalance;
                balances[MainWallet] += ThirdRoundBalance;
                count += 1;
            }
            require(
                numOfTokens >= 5000000000000000000 &&
                    numOfTokens <= 12500000000000000000000,
                "buy Between Miniimum 10 tokens and maximum 12500 Tokens"
            );
            ForthroundBuy_Time = block.timestamp;
            require(
                numOfTokens <= ForthRoundnumToken,
                "Number should be less than allocation"
            );
            require(
                ForthRoundnumToken_initialToken + numOfTokens <=
                    ForthRoundnumToken,
                "Not Enough Balance in this round"
            );
            balances[Public] -= numOfTokens;
            balances[_buyer] += numOfTokens;
            ForthRoundnumToken_initialToken += numOfTokens;
            if (!ownerAppended[_buyer]) {
                ownerAppended[_buyer] = true;
                owners.push(_buyer);
            }
            // uint256 txIndex = transactions.length;
            emit EForthroundTranfer(_Txid, msg.sender, _buyer, numOfTokens,ForthroundBuy_Time);
            emit ForthRound_timeEvent(ForthroundBuy_Time);
    
            }
            else {
                require (block.timestamp > Third_Round_End_Date,"Public Sale start Soon");
                // require(block.timestamp > Third_Round_End_Date+3628800,"now cannot stack");
                uint256 Fortround = Third_Round_End_Date + 180;
                require(block.timestamp <= Fortround,"now cannot stack");
            if (count == 0) {
                if (balances[Team] > 0) {
                    balances[Team] -= firstRoundBalance;
                    balances[MainWallet] += firstRoundBalance;
                }
                balances[Private_Angel] -= SecondRoundBalance;
                balances[MainWallet] += SecondRoundBalance;
                balances[Private_VCs] -= ThirdRoundBalance;
                balances[MainWallet] += ThirdRoundBalance;
                count += 2;
            } else if (count == 1) {
                if (balances[Team] > 0) {
                    balances[Team] -= firstRoundBalance;
                    balances[MainWallet] += firstRoundBalance;
                }
                balances[Private_VCs] -= ThirdRoundBalance;
                balances[MainWallet] += ThirdRoundBalance;
                count += 1;
            }
            require(
                numOfTokens >= 5000000000000000000 &&
                    numOfTokens <= 12500000000000000000000,
                "buy Between Miniimum 10 tokens and maximum 12500 Tokens"
            );
            ForthroundBuy_Time = block.timestamp;
            require(
                numOfTokens <= ForthRoundnumToken,
                "Number should be less than allocation"
            );
            require(
                ForthRoundnumToken_initialToken + numOfTokens <=
                    ForthRoundnumToken,
                "Not Enough Balance in this round"
            );
            balances[Public] -= numOfTokens;
            numberOfTokens[_TxCount][_buyer] = numOfTokens;

            ForthRliquitityPool += numOfTokens;
            uint256 confirm_time = block.timestamp + 180;
            locktime[_TxCount][_buyer] = confirm_time;
            _TxCount += 1;
            if (!ownerAppended[_buyer]) {
                ownerAppended[_buyer] = true;
                owners.push(_buyer);
            }
            // uint256 txIndex = transactions.length;
            emit EForthroundTranfer(
                _Txid,
                msg.sender,
                _buyer,
                ForthRliquitityPool,
                numOfTokens
            );
            emit ForthRound_timeEvent(ForthroundBuy_Time);
            emit forthRoundStack(_forthroundStacking_Period);
            }
            return _Txid++;

        }

    //Transactions Confirmations by Owners
    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        address user = transactions[_txIndex].to;
        uint256 VALUE = transactions[_txIndex].value;
        numberOfTokens[_txIndex][user] = VALUE;
        FirstRoundnumToken_initialToken += VALUE;
        balances[Team] = FirstRoundnumToken - FirstRoundnumToken_initialToken;
        uint256 _firstRoundBalance = balances[Team];
        firstRoundBalance = _firstRoundBalance;
        // uint256 confirm_time =block.timestamp + 7257600;
        uint256 confirm_time = block.timestamp + 300;
        locktime[_txIndex][user] = confirm_time;
        emit FirstRoundTransaction(
            user,
            _txIndex,
            FirstRoundnumToken_initialToken,
            numberOfTokens[_txIndex][user],
            locktime[_txIndex][user]
        );
        emit FirstRoundStack(block.timestamp, _firstroundStacking_Period);
    }

    function FirstcalcuationofTotalSold() public onlyOwner returns (bool){
        uint256 fraction = 10**decimals;
        require(block.timestamp> First_Round_End_Date,"First Round not Over");
        
        if(block.timestamp > First_Round_End_Date){
        uint256 _FirstRliquidityPool =FirstRoundnumToken_initialToken;
        FirstRliquidityPool = _FirstRliquidityPool;
        if(FirstRliquidityPool>0){
        uint256 _FirstRBonusAmount = (FirstRoundBonusTokens*fraction)/
                FirstRliquidityPool;
            FirstRBonusAmount = _FirstRBonusAmount;
        }
        }
        emit EFirstRBonusAmount(FirstRBonusAmount, FirstRliquidityPool);
        return true;
    }

        function SecondcalcuationofTotalSold() public onlyOwner returns (bool){
        uint256 fraction = 10**decimals;
        require(block.timestamp> Second_Round_End_Date,"Second Round not Over");
        if(block.timestamp > Second_Round_End_Date){
        uint256 _SecondRliquitityPool = SecondRoundnumToken_initialToken;
        SecondRliquidityPool = _SecondRliquitityPool; 
        if(SecondRliquidityPool>0){
            uint256 _SecondRBonusAmount = (SecondRoundBonusTokens*fraction)/
                SecondRliquidityPool;
            SecondRBonusAmount = _SecondRBonusAmount;
        }
        }
         emit ESecondRBonusAmount(SecondRBonusAmount, SecondRliquidityPool);
          calcuationofTotal +=1;
        return true;
        }

        function ThirdcalcuationofTotalSold() public onlyOwner returns (bool){
        if(block.timestamp > Third_Round_End_Date){
        uint256 fraction = 10**decimals;
        require(block.timestamp> Third_Round_End_Date,"Third Round not Over");
        uint256 _ThirdRliquitityPool = ThirdRoundnumToken_initialToken;
        ThirdRliquitityPool = _ThirdRliquitityPool;
        if(ThirdRliquitityPool>0){
            uint256 _ThirdRBonusAmount = (ThirdRoundBonusTokens*fraction) /
                ThirdRliquitityPool;
            ThirdRBonusAmount = _ThirdRBonusAmount;
        }
        }
        emit EThirdRBonusAmount(ThirdRBonusAmount, ThirdRliquitityPool);
        calcuationofTotal +=1;
        return true;
        }

        function ForthcalcuationofTotalSold() public onlyOwner returns (bool){
        // if(block.timestamp > Third_Round_End_Date+3628800){
        uint256 fortstack =Third_Round_End_Date + 180;
        if(block.timestamp >=fortstack){
        uint256 fraction = 10**decimals;
        require(block.timestamp> fortstack,"Stacking Period not Over");
        if(ForthRliquitityPool>0){
            uint256 _ForthRBonusAmount = (ForthRoundBonusTokens*fraction) /
                ForthRliquitityPool;
            ForthRBonusAmount = _ForthRBonusAmount;
        }
        }
        emit EForthRBonusAmount(ForthRBonusAmount, ForthRliquitityPool);
        calcuationofTotal +=1;
        return true;
        }

    //After Confirmation Transactions will Wxecuted
    function FirstTransferToWallets(address _user, uint256 _txIndex)
        public
        returns (bool)
    {
        require(
            block.timestamp >= locktime[_txIndex][_user],
            "Stacking Periods Not Over"
        );
        require(calcuationofTotal >=1, "Transfer to liquidty Pool First" );
        uint256 IDOLToWallet;
        uint256 Fraction=10**decimals;
            IDOLToWallet = (numberOfTokens[_txIndex][_user]+((numberOfTokens[_txIndex][_user]*FirstRBonusAmount)))/Fraction;
            
        balances[_user] += IDOLToWallet;

         emit EFirstTranferTowallet(
            _user,
            block.timestamp,
            IDOLToWallet
        );
        return true;
    }
    function SecondTransferToWallets(address _user, uint256 _txIndex)
        public
        returns (bool)
    {
        require(
            block.timestamp >= locktime[_txIndex][_user],
            "Stacking Periods Not Over"
        );
        require(calcuationofTotal >=1, "Transfer to liquidty Pool First" );
        uint256 IDOLToWallet;
        uint256 Fraction=10**decimals;
       
            IDOLToWallet = (numberOfTokens[_txIndex][_user]+((numberOfTokens[_txIndex][_user]*SecondRBonusAmount)))/Fraction;
        balances[_user] += IDOLToWallet;
         emit ESecondTranferTowallet(
            _user,
            block.timestamp,
            IDOLToWallet
        );
        return true;
    }
    function ThirdTransferToWallets(address _user, uint256 _txIndex)
        public
        returns (bool)
    {
        require(
            block.timestamp >= locktime[_txIndex][_user],
            "Stacking Periods Not Over"
        );
        require(calcuationofTotal >=1, "Transfer to liquidty Pool First" );
        uint256 IDOLToWallet;
        uint256 Fraction=10**decimals;
            IDOLToWallet = (numberOfTokens[_txIndex][_user]+((numberOfTokens[_txIndex][_user]*ThirdRBonusAmount)))/Fraction;
        balances[_user] += IDOLToWallet;
        emit EThirdTranferTowallet(
            _user,
            block.timestamp,
            IDOLToWallet
        );
        return true;
    }
    function forthTransferToWallets(address _user, uint256 _txIndex)
        public
        returns (bool)
    {
        require(
            block.timestamp >= locktime[_txIndex][_user],
            "Stacking Periods Not Over"
        );
        require(calcuationofTotal >=1, "Transfer to liquidty Pool First" );
        uint256 IDOLToWallet;
        uint256 Fraction=10**decimals;
       
            IDOLToWallet = (numberOfTokens[_txIndex][_user]+((numberOfTokens[_txIndex][_user]*ForthRBonusAmount)))/Fraction;
        balances[_user] += IDOLToWallet;
        emit EForthTranferTowallet(
            _user,
            block.timestamp,
            IDOLToWallet
        );
        return true;
    }

    //cancel Transations
    function revokeConfirmation(uint256 _txIndex)
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

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

  

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owners[0] = newOwner;
        }
    }
}