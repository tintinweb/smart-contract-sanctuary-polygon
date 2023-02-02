/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 value) public virtual;

    function burn(address from, uint256 value) public virtual;
}

library DigitalInvestmentLibrary {
    // Get reference number for an account number of a relation
    // RefNum = <RelationshipNumber>|<ExternalAccountNumber>
    function GetRefNum(
        uint256 relationshipNumber,
        string memory externalAccountNumber
    ) internal pure returns (string memory) {
        // string memory refNum = ConcatStrings(
        //     uintToString(relationshipNumber),
        //     "|"
        // );
        // refNum = ConcatStrings(refNum, externalAccountNumber);
        // return refNum;

        return
            string(
                abi.encodePacked(
                    uintToString(relationshipNumber),
                    "|",
                    externalAccountNumber
                )
            );
    }

    // Form TA Transaction Reference by concatenating Relationship Number, TA Transaction ID and TA FundTransactionLineNo
    function GetTATransactionReference(
        uint256 relationshipNumber,
        uint256 taTransactionId,
        uint256 taTransactionLineNo
    ) internal pure returns (string memory) {
        string[3] memory parts;
        parts[0] = uintToString(relationshipNumber);
        parts[1] = uintToString(taTransactionId);
        parts[2] = uintToString(taTransactionLineNo);
        return ArrayToString(parts, "-");
    }

    // Compare two strings
    function CompareStrings(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    // Convert uint (number) to string
    function uintToString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Search for a string in an array of strings
    function GetIndexOf(string[] memory array, string memory searchItem)
        internal
        pure
        returns (int256)
    {
        uint256 i;
        for (i = 0; i < array.length; i++) {
            if (CompareStrings(array[i], searchItem)) return int256(i);
        }
        return -1;
    }

    // Convert elements of string array to a string, separated by a separator
    // TO DO: Enhance to make array length dynamic.. currently dynamic array fails when deployed
    function ArrayToString(string[3] memory values, string memory separator)
        internal
        pure
        returns (string memory)
    {
        if (values.length == 0) return "";

        uint256 i = 1;
        string memory result = values[0]; //Initialize with first element

        //Concatenate other elements, separated using "separator"
        for (i = 1; i < values.length; i++) {
            result = string(abi.encodePacked(result, separator, values[i]));
        }
        return result;
    }

    // Substring function - endIndex is not considered in result
    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    // Absolute value of a number
    function Abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    // Check if passed address is of a contract
    function isContract(address _a) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_a)
        }
        return size > 0;
    }

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    
}

contract DigitalInvestmentsCore {
    address public owner;
    address[] authenticatedSenders;

    constructor() {
        owner = msg.sender;
    }

    function checkForError(string memory errorMsg) pure internal {
        require(DigitalInvestmentLibrary.CompareStrings(errorMsg, ""), errorMsg);
    }

    modifier onlyOwner() {
        //Wrapping the "require" statement of the modifier in a function reduced 252 bytes
        //No further reduction found when onlyOwner modifier was replaced by _onlyOwner() method call in applicable functions
        if (msg.sender != owner)
            checkForError("NOT_OWNER"); // "Unauthorized operation. Operations is allowed only for Transfer Agent!"

        _;
    }

    modifier onlyAuthenticatedSender() {
        //Allow only if sender is in authenticated senders list
        if (getAuthenticatedSenderIndex(msg.sender) < 0)
            checkForError("NOT_AUTH"); // "Unauthorized operation. Operations is allowed only for Transfer Agent!"
            //checkForError(toString(abi.encodePacked("NOT_OWNER ", msg.sender))); // "Unauthorized operation. Operations is allowed only for Transfer Agent!"

        _;
    }

    function getAuthenticatedSenderIndex(address senderAddress) 
    public view returns (int) {
        for (uint i = 0; i < authenticatedSenders.length; i++) {
            if (authenticatedSenders[i] == senderAddress)
                return int(i);
        }

        return -1;
    }

    function addAuthenticatedSender(address senderAddress) 
    public onlyOwner {
        //Add to list, if not added already
        if (getAuthenticatedSenderIndex(senderAddress) < 0)
            authenticatedSenders.push(senderAddress);
    }

    function removeAuthenticatedSender(address senderAddress) 
    public onlyOwner {
        int index = getAuthenticatedSenderIndex(senderAddress);
        if (index < 0 )
            return;

        //Move elements after given index, forward by one position.. to retain order
        for (uint i = uint(index); i < authenticatedSenders.length - 1; i++) {
           authenticatedSenders[i] = authenticatedSenders[i+1];
        }

        //Remove one item from the end
        authenticatedSenders.pop();
    }

    function getAuthenticatedSenders() 
    public view returns (address[] memory) {
        return authenticatedSenders;
    }
    
    event New_Account_Created(
        address BCAccountAddress,
        string ExternalAccountNumber,
        string AccountName,
        uint16 AccountType,
        uint256 RelationshipNumber,
        string CustomerName,
        string AddressLines
        // Add all columns from new account api
    );

    event Account_Created_On_TA (
        address BCAccountAddress,
        string ExternalAccountNumber,
        string TAAccountNumber,
        uint256 RelationshipNumber,
        uint256 BCAccountStatus
    );

    event Trade_Created(TradeCreatedParam Params);

    struct TradeCreatedParam {
        string BCTransactionId;
        uint8 TransactionType;
        string ExternalTransactionId;
        uint256 RelationshipNumber;
        string ExternalAccountNumber;
        address BCAccountAddress;
        string FundSymbol;
        uint256 Shares;
        uint256 Amount;
        uint256 TradeDate;
    }

    event Trade_Created_On_TA(TradeCreatedOnTAParam);

    struct TradeCreatedOnTAParam {
        string BCTransactionId;
        string ExternalTransactionId;
        address BCAccountAddress;
        string FundSymbol;
        uint8 TransactionType;
        uint256 Shares;
        uint256 Amount;
        uint256 TradeDate;
        uint256 TATransactionId;
        uint256 TATransactionLineNo;
    }

    //Struct to hold account information
    struct Account {
        uint256 RelationshipNumber;
        string ExternalAccountNumber;
        string TAAccountNumber;
        string AccountName;
        uint16 AccountType;
        uint8 BCAccountStatus; //0 - initiated, 1 - Created on TA, 2 - Activated on TA, 3 - Deactivated on TA
    }

    //Struct to hold Relationship information
    struct Relationship {
        uint256 RelationshipNumber;
        string RelationshipName;
        string TransactionPrefix;
        uint8 RelationshipStatus; //Active / Inactive
        bool Initialized; //Track valid entries
    }

    //Struct to hold Fund information
    struct Fund {
        string FundSymbol;
        string FundName;
        address ContractAddress;
        bool Initialized; //Track valid entries
    }

    //Struct to hold Fund Transaaction information
    struct FundTransaction {
        uint256 InternalTxId;
        uint8 TransactionType; // 1: Buy, 2: Sell
        string ExternalTransactionId;
        address BCAccountAddress;
        string FundSymbol;
        uint256 Shares;
        uint256 Amount;
        uint256 TradeDate;
        uint8 BCTransactionStatus; //0 - initiated, 1 - Created on TA, 2 - Posted on TA, 3 - Voided on TA
        bool Initialized; //Track valid entries
    }

    //Struct to return transaction list (similar to FundTransaction)
    struct TradeInfo {
        string BCTransactionId;
        uint256 RelationshipNumber;
        uint256 InternalTxId;
        uint8 TransactionType; // 1: Buy, 2: Sell
        string ExternalTransactionId;
        address BCAccountAddress;
        string FundSymbol;
        uint256 Shares;
        uint256 Amount;
        uint256 TradeDate;
        uint8 BCTransactionStatus; //0 - initiated, 1 - Created on TA, 2 - Posted on TA, 3 - Voided on TA
    }

    struct SubaccountHoldings {
        string FundSymbol;
        string FundName;
        uint256 Balance;
    }

    //Account storage
    mapping(address => Account) internal Accounts; // BCAccountAddress => Account
    mapping(string => address) internal ExternalAccountAddresses; // RelationshipNumber|ExternalAccount => BCAccountAddress
    mapping(string => Fund) internal Funds; // FundSymbol => Fund
    mapping(uint256 => Relationship) internal Relationships; // RelationshipNumber => Relationship
    mapping(string => uint256) internal TransactionPrefixes; // TransactionPrefix => RelationshipNumber
    mapping(string => FundTransaction) internal FundTransactions; // BCTransactionId => FundTransaction
    mapping(uint256 => uint256) internal LastTransactionId; // RelationshipNumber => LastTransactionId
    mapping(address => string[]) internal AccountTransactions; //  BCAccountAddress => BCTransactionId[]
    mapping(address => string[]) internal Subaccounts; //  BCAccountAddress => FundSymbol[]

    string[] FundsList; //List of fund symbols
    string[] ExternalAccountList; // List of Relationship Account Numbers
    uint256[] RelationshipList; // List of Relationship Numbers

    //Helper functions
    function IsFundInitialized(string memory fundSymbol) 
    public view returns (bool) {
        return Funds[fundSymbol].Initialized;
    }

    function AddNewFund(
        string memory fundSymbol,
        string memory fundName,
        address fundContractAddress
    ) external onlyAuthenticatedSender {  // TO DO: onlyOwner has to be replaced to allow list of senders
        // Validations are performed in calling contract

        Funds[fundSymbol].FundSymbol = fundSymbol;
        Funds[fundSymbol].FundName = fundName;
        Funds[fundSymbol].ContractAddress = fundContractAddress;
        Funds[fundSymbol].Initialized = true;

        FundsList.push(fundSymbol);
    }

    function UpdateFundName(
        string memory fundSymbol,
        string memory fundName
    ) external onlyAuthenticatedSender {
        Funds[fundSymbol].FundName = fundName;
    }

    function GetFundContract(string memory fundSymbol) 
    public view  
    returns(ERC20) {
        return ERC20(Funds[fundSymbol].ContractAddress);
    }

    function GetFundsList() 
    public view 
    returns (Fund[] memory) {
        uint256 i = 0;
        Fund[] memory allFunds = new Fund[](FundsList.length);

        for (i = 0; i < FundsList.length; i++) {
            allFunds[i] = Funds[FundsList[i]];
        }

        return allFunds;
    }
    
    function GetBCAccountAddress(
        uint256 relationshipNumber,
        string memory externalAccountNumber
    ) public view 
    returns (address) {
        //Get Account address
        return ExternalAccountAddresses[DigitalInvestmentLibrary.GetRefNum(relationshipNumber, externalAccountNumber)];
    }

    function GetAccountByBCAccountAddress(address bcAccountAddress) 
    public view 
    returns (Account memory) {
        //Return Account
        return Accounts[bcAccountAddress];
    }

    function GetAccountRelationshipNumber(address bcAccountAddress) 
    public view 
    returns (uint256) {
        //Get Account's RelationshipNumber
        return Accounts[bcAccountAddress].RelationshipNumber;
    }

    function UpdateTAAccountNumber(
        address bcAccountAddress,
        string memory taAccountNumber
    ) public onlyAuthenticatedSender {
        //Change account status and update TA Account Number
        Accounts[bcAccountAddress].TAAccountNumber = taAccountNumber;
        Accounts[bcAccountAddress].BCAccountStatus = 1; // Created on TA

        emit Account_Created_On_TA(
            bcAccountAddress,
            Accounts[bcAccountAddress].ExternalAccountNumber,
            taAccountNumber,
            Accounts[bcAccountAddress].RelationshipNumber,
            1
        );
    }

    function CreateOrder(
        uint8 transactionType,
        uint256 relationshipNumber,
        string memory externalAccountNumber,
        string memory fundSymbol,
        uint256 shares,
        uint256 amount,
        string memory txReferenceNumber
    ) public onlyAuthenticatedSender 
    returns (string memory) {
        address bcAccountAddress = GetBCAccountAddress(relationshipNumber, externalAccountNumber);
        
        //Generate new BC transaction Id
        string memory bcTranId = GenerateBCTransactionId(relationshipNumber);
        uint256 lastTranId = GetLastTransactionId(relationshipNumber);

        //Add transaction to the stucture
        FundTransactions[bcTranId].InternalTxId = lastTranId;
        FundTransactions[bcTranId].TransactionType = transactionType;
        FundTransactions[bcTranId].ExternalTransactionId = txReferenceNumber;
        FundTransactions[bcTranId].BCAccountAddress = bcAccountAddress;
        FundTransactions[bcTranId].FundSymbol = fundSymbol;
        FundTransactions[bcTranId].Shares = shares;
        FundTransactions[bcTranId].Amount = amount;
        FundTransactions[bcTranId].TradeDate = block.timestamp;
        FundTransactions[bcTranId].BCTransactionStatus = 0; //0 - initiated, 1 - Created on TA, 2 - Posted on TA, 3 - Voided on TA
        FundTransactions[bcTranId].Initialized = true;

        //Add transaction id to account's list of transactions
        AccountTransactions[bcAccountAddress].push(bcTranId);

        //Add fund to the list of holdings
        if (DigitalInvestmentLibrary.GetIndexOf(Subaccounts[bcAccountAddress], fundSymbol) < 0) {
            Subaccounts[bcAccountAddress].push(fundSymbol);
        }

        //Do not effect the fund balance now... just emit the event
        emit Trade_Created(TradeCreatedParam(bcTranId,  // BCTransactionId
                            transactionType,        
                            txReferenceNumber,      // ExternalTransactionId
                            relationshipNumber,     
                            externalAccountNumber,
                            bcAccountAddress,
                            fundSymbol,
                            shares,
                            amount,
                            block.timestamp));  // TradeDate

        return bcTranId;
    }

    function GetFundTransaction(string memory bcTransactionId) 
    public 
    view returns (FundTransaction memory){
        //Get stored Fund Transaction
        return FundTransactions[bcTransactionId];        
    }

    function AcknowledgeTradeOrder(
        uint256 taTransactionId,
        uint256 taTransactionLineNo,
        string memory bcTransactionId
    ) 
    public 
    onlyAuthenticatedSender {
        // Validations are done in calling contract
        // Effecting fund balance is done in calling contract

        //Change transaction status to "Created on TA"
        FundTransactions[bcTransactionId].BCTransactionStatus = 1;

        FundTransaction memory tran = FundTransactions[bcTransactionId];

        emit Trade_Created_On_TA(DigitalInvestmentsCore.TradeCreatedOnTAParam(bcTransactionId, 
                                                        tran.ExternalTransactionId, 
                                                        tran.BCAccountAddress,
                                                        tran.FundSymbol,
                                                        tran.TransactionType,
                                                        tran.Shares,
                                                        tran.Amount,
                                                        tran.TradeDate,
                                                        taTransactionId,
                                                        taTransactionLineNo));
    }

    function IsRelationshipInitialized(uint256 relationshipNumber)
    public view 
    returns (bool) {
        return Relationships[relationshipNumber].Initialized;
    }

    function GetRelationshipByTransactionPrefix (string memory transactionPrefix)
    public view 
    returns (uint256) {
        return TransactionPrefixes[transactionPrefix];
    }

    // function SetRelationshipForTransactionPrefix (uint256 relationshipNumber, string memory transactionPrefix)
    // public {
    //     TransactionPrefixes[transactionPrefix] = relationshipNumber;
    // }

    function SetRelationship(Relationship memory relation) 
    public onlyAuthenticatedSender {
        uint256 relNo = relation.RelationshipNumber;
        Relationships[relNo] = relation;
        TransactionPrefixes[relation.TransactionPrefix] = relNo;
        RelationshipList.push(relNo);
    }

    function UpdateRelationshipDetails(
        uint256 relationshipNumber, 
        string memory relationshipName,
        string memory transactionPrefix) 
    public onlyAuthenticatedSender {
        string memory oldTranPrefix = Relationships[relationshipNumber].TransactionPrefix;

        Relationships[relationshipNumber] = Relationship(
            relationshipNumber,
            relationshipName,
            transactionPrefix,
            1,
            true
        );
        
        //Delete all transaction prefix mapping and add new one
        if (DigitalInvestmentLibrary.CompareStrings(oldTranPrefix, transactionPrefix) == false) {
            delete TransactionPrefixes[oldTranPrefix];
            TransactionPrefixes[transactionPrefix] = relationshipNumber;
        }
    }

    function GetRelationshipsList()
    public view
    returns (DigitalInvestmentsCore.Relationship[] memory)
    {
        uint256 i = 0;
        Relationship[] memory allRelationships = new Relationship[](RelationshipList.length);

        for (i = 0; i < RelationshipList.length; i++) {
            allRelationships[i] = Relationships[RelationshipList[i]];
        }

        return allRelationships;
    }

    function CreateNewAccountForBCAddress(
        string memory externalAccountNumber,
        string memory accountName,
        uint16 accountType,
        uint256 relationshipNumber,
        string memory customerName,
        string memory addressLines,
        address bcAccountAddress
    ) public onlyAuthenticatedSender 
    returns (address) {
        //Get relationship specific reference account number
        string memory refNum = DigitalInvestmentLibrary.GetRefNum(
            relationshipNumber,
            externalAccountNumber
        );

        Account memory acct;
        acct.RelationshipNumber = relationshipNumber;
        acct.ExternalAccountNumber = externalAccountNumber;
        acct.AccountName = accountName;
        acct.AccountType = accountType;
        acct.BCAccountStatus = 0; //Inactive by defafult

        //Store new account info
        Accounts[bcAccountAddress] = acct;

        //Store ref account number to new address map
        ExternalAccountAddresses[refNum] = bcAccountAddress;

        //Store new account reference in a list
        ExternalAccountList.push(refNum);

        //Emit new account creation event
        emit New_Account_Created(
            bcAccountAddress,
            externalAccountNumber,
            accountName,
            accountType,
            relationshipNumber,
            customerName,
            addressLines        );
        return bcAccountAddress;
    }

    function AddFundTransaction(
        uint256 relationshipNumber,
        string memory externalAccountNumber,
        string memory fundSymbol,
        uint8 transactionType,
        uint256 shares,
        uint256 amount,
        uint256 taTransactionId,
        uint256 taTransactionLineNo
    ) 
    public 
    onlyAuthenticatedSender 
    returns (string memory) {
        //Generate new BC transaction Id
        string memory bcTranId = GenerateBCTransactionId(relationshipNumber);
        uint256 lastTranId = GetLastTransactionId(relationshipNumber);
        address bcAccountAddress = GetBCAccountAddress(relationshipNumber, externalAccountNumber);

        FundTransactions[bcTranId].InternalTxId = lastTranId;
        FundTransactions[bcTranId].TransactionType = transactionType;
        FundTransactions[bcTranId].ExternalTransactionId = DigitalInvestmentLibrary.GetTATransactionReference(
            relationshipNumber,
            taTransactionId,
            taTransactionLineNo
        );

        FundTransactions[bcTranId].BCAccountAddress = bcAccountAddress;
        FundTransactions[bcTranId].FundSymbol = fundSymbol;
        FundTransactions[bcTranId].Shares = shares;
        FundTransactions[bcTranId].Amount = amount;
        FundTransactions[bcTranId].TradeDate = block.timestamp;
        FundTransactions[bcTranId].BCTransactionStatus = 1; //0 - initiated, 1 - Created on TA, 2 - Posted on TA, 3 - Voided on TA
        FundTransactions[bcTranId].Initialized = true;

        //Add transaction id to account's list of transactions
        AccountTransactions[bcAccountAddress].push(bcTranId);

        //Add fund to the list of holdings
        if (DigitalInvestmentLibrary.GetIndexOf(Subaccounts[bcAccountAddress], fundSymbol) < 0) {
            Subaccounts[bcAccountAddress].push(fundSymbol);
        }

        //Effect the fund balance for reinvestment trades. No change in balance for cash trades
        if (transactionType % 2 == 1) {
            // Reinvestment Trades.. adjust  balance
            AdjustFundBalance(fundSymbol, bcAccountAddress, int256(shares));
        }

        //Emit confirmation event
        emit Trade_Created_On_TA(DigitalInvestmentsCore.TradeCreatedOnTAParam(bcTranId, 
                                                        FundTransactions[bcTranId].ExternalTransactionId, 
                                                        bcAccountAddress,
                                                        fundSymbol,
                                                        transactionType,
                                                        shares,
                                                        amount,
                                                        FundTransactions[bcTranId].TradeDate,
                                                        taTransactionId,
                                                        taTransactionLineNo));
    
        return bcTranId;
    }

    function GetTradesByAccount(
        uint256 relationshipNumber,
        string calldata externalAccountNumber
    ) public view 
    returns (TradeInfo[] memory) {
        address bcAccountAddress = GetBCAccountAddress(relationshipNumber, externalAccountNumber);
        
        //Get list of transaction ids for the account
        string[] memory bcTranIds = AccountTransactions[bcAccountAddress];

        TradeInfo[] memory trades = new TradeInfo[](bcTranIds.length);

        // Copy all trades into an array
        uint256 i;
        for (i = 0; i < bcTranIds.length; i++) {
            FundTransaction memory tran = FundTransactions[bcTranIds[i]];
            trades[i] = TradeInfo(
                bcTranIds[i],
                relationshipNumber,
                tran.InternalTxId,
                tran.TransactionType,
                tran.ExternalTransactionId,
                tran.BCAccountAddress,
                tran.FundSymbol,
                tran.Shares,
                tran.Amount,
                tran.TradeDate,
                tran.BCTransactionStatus
            );
        }

        return trades;
    }

    function GetAccountBalances(
        uint256 relationshipNumber,
        string calldata externalAccountNumber
    ) public view returns (SubaccountHoldings[] memory) {
        address bcAccountAddress = GetBCAccountAddress(relationshipNumber, externalAccountNumber);
        
        //Get of list of funds held
        //string[] memory fundSymbols = Subaccounts[bcAccountAddress];
        uint256 subaccountCount = Subaccounts[bcAccountAddress].length;

        SubaccountHoldings[] memory fundBalances = new SubaccountHoldings[](
            subaccountCount
        );
        //Find holdings in each fund
        uint256 i;
        for (i = 0; i < subaccountCount; i++) {
            string memory fundSymbol = Subaccounts[bcAccountAddress][i];
            ERC20 FundContract = ERC20(Funds[fundSymbol].ContractAddress);
            fundBalances[i] = SubaccountHoldings(
                fundSymbol,
                Funds[fundSymbol].FundName,
                FundContract.balanceOf(bcAccountAddress)
            );
        }

        return fundBalances;
    }

    /**** Internal Methods * START *****/
    //Update fund balance
    function AdjustFundBalance(
        string memory fundSymbol,
        address bcAccountAddress,
        int256 adjustAmount
    ) internal {
        // require(Funds[fundSymbol].Initialized, "Invalid Fund!");
        // require(bcAccountAddress != address(0), "Invalid Account!");

        ERC20 FundContract = ERC20(Funds[fundSymbol].ContractAddress);

        uint256 unsignedAmount = uint256(DigitalInvestmentLibrary.Abs(adjustAmount));
        //Mint token for BUY
        if (adjustAmount > 0) {
            FundContract.mint(bcAccountAddress, unsignedAmount);
        } else if (adjustAmount < 0) {
            //Check if there is sufficient shares for redemption
            // require(
            //     FundContract.balanceOf(bcAccountAddress) - unsignedAmount >= 0,
            //     "Insufficient balance!"
            // );

            if (FundContract.balanceOf(bcAccountAddress) < unsignedAmount)
                checkForError("INSUF_BAL");

            FundContract.burn(bcAccountAddress, unsignedAmount);
        }
    }

    // Generate new BC transaction id for a relation
    // BCTransactionId = <TransactionPrefix><ExternalAccountNumber>
    function GenerateBCTransactionId(uint256 relationshipNumber)
        internal
        returns (string memory)
    {
        uint256 newTranId = LastTransactionId[relationshipNumber] + 1;
        LastTransactionId[relationshipNumber] = newTranId;
        // return
        // ConcatStrings(
        //     Relationships[relationshipNumber].TransactionPrefix,
        //     uintToString(newTranId)
        // );
        return
            string(
                abi.encodePacked(
                    Relationships[relationshipNumber].TransactionPrefix,
                    DigitalInvestmentLibrary.uintToString(newTranId)
                )
            );
    }

    // Compute BCTransactionId from relationshipnumber and internal transaction id
    function GetBCTransactionId(
        uint256 relationshipNumber,
        uint256 internalTxId
    ) internal view 
    returns (string memory) {
        // return
        //     ConcatStrings(
        //         Relationships[relationshipNumber].TransactionPrefix,
        //         uintToString(internalTxId)
        //     );
        return
            string(
                abi.encodePacked(
                    Relationships[relationshipNumber].TransactionPrefix,
                    DigitalInvestmentLibrary.uintToString(internalTxId)
                )
            );
    }

    // Return last used Transaction Id for a relationship
    function GetLastTransactionId(uint256 relationshipNumber)
        internal
        view
        returns (uint256)
    {
        return LastTransactionId[relationshipNumber];
    }

    // function GetAllAccounts(uint256 relationshipNumber) /* 2.557 KB */
    //     external
    //     view
    //     returns (AccountWithBCAddress[] memory)
    // {
    //     uint256 accountCount = ExternalAccountList.length;
    //     string memory refNum = "";
    //     uint256 showAllAccounts = 1;
    //     uint256 cnt = 0;
    //     uint256 refNumLength = 0;

    //     // If relationship number is passed, return accounts of that relationship number.. if not return all accounts
    //     if (relationshipNumber > 0) {
    //         //refNum = ConcatStrings(uintToString(relationshipNumber), "|");
    //         refNum = string(abi.encodePacked(uintToString(relationshipNumber), "|"));

    //         refNumLength = strlen(refNum);
    //         showAllAccounts = 0;

    //         // Count applicable accounts
    //         cnt = 0;
    //         for (uint256 i = 0; i < accountCount; i++) {
    //             // Check if relationship number of the account matches passed relationship number
    //             if (
    //                 CompareStrings(
    //                     substring(ExternalAccountList[i], 0, refNumLength),
    //                     refNum
    //                 )
    //             ) cnt++;
    //         }

    //         accountCount = cnt;
    //     }

    //     AccountWithBCAddress[] memory accountsList = new AccountWithBCAddress[](
    //         accountCount
    //     );

    //     if (accountCount == 0) return accountsList;

    //     //Iterate again to get the details of applicable accounts
    //     cnt = 0;
    //     for (uint256 i = 0; i < ExternalAccountList.length; i++) {
    //         // Check if relationship number of the account matches passed relationship number
    //         if (
    //             showAllAccounts == 1 ||
    //             CompareStrings(
    //                 substring(ExternalAccountList[i], 0, refNumLength),
    //                 refNum
    //             )
    //         ) {
    //             address bcAccountAddress = ExternalAccountAddresses[
    //                 ExternalAccountList[i]
    //             ];
    //             Account memory acct = Accounts[bcAccountAddress];
    //             accountsList[cnt] = AccountWithBCAddress(
    //                 acct.RelationshipNumber,
    //                 acct.ExternalAccountNumber,
    //                 acct.TAAccountNumber,
    //                 acct.AccountName,
    //                 acct.AccountType,
    //                 bcAccountAddress,
    //                 acct.BCAccountStatus //0 - initiated, 1 - Created on TA, 2 - Activated on TA, 3 - Deactivated on TA
    //             );

    //             cnt++; // Increment and keep for next iteration
    //         }
    //     }

    //     return accountsList;
    // }

    
    /**** Internal Methods * END *****/

}

contract DigitalInvestments {
    address public owner;
    address[] authenticatedSenders;
    DigitalInvestmentsCore _coreContract;
    
    constructor(address coreContractAddress) {
        owner = msg.sender;
        _coreContract = DigitalInvestmentsCore(coreContractAddress);
    }
    
    function checkForError(string memory errorMsg) pure internal {
        require(DigitalInvestmentLibrary.CompareStrings(errorMsg, ""), errorMsg);
    }

    modifier onlyOwner() {
        //Wrapping the "require" statement of the modifier in a function reduced 252 bytes
        //No further reduction found when onlyOwner modifier was replaced by _onlyOwner() method call in applicable functions
        if (msg.sender != owner)
            checkForError("NOT_OWNER"); // "Unauthorized operation. Operations is allowed only for Transfer Agent!"

        _;
    }

    /**** TA-Only Methods * START *****/
    function AddNewFund(
        string memory fundSymbol,
        string memory fundName,
        address fundContractAddress
    ) external onlyOwner {
        string memory errorMsg;

        if (DigitalInvestmentLibrary.CompareStrings(fundSymbol, ""))
            errorMsg = "INVALID_FS"; // Invalid Fund Symbol
        else if (fundContractAddress == address(0) || !DigitalInvestmentLibrary.isContract(fundContractAddress))
            errorMsg = "INVALID_FCADDR"; // "Invalid Fund Contract Address!"
        else if (_coreContract.IsFundInitialized(fundSymbol)) 
            errorMsg = "FUND_EXISTS"; // "Fund already exists!");

        // 284 bytes saved by replacing 4 "require" statements with single one as below
        // require(CompareStrings(errorMsg, ""), errorMsg);
        checkForError(errorMsg);

        _coreContract.AddNewFund(fundSymbol, fundName, fundContractAddress);
    }

    function UpdateFundName(
        string memory fundSymbol,
        string memory fundName
    ) external onlyOwner {
        // 102 bytes saved by replacing a direct "require" statement with function call
        if (DigitalInvestmentLibrary.CompareStrings(fundSymbol, "") || !(_coreContract.IsFundInitialized(fundSymbol)))
            checkForError("INVALID_FS");

        _coreContract.UpdateFundName(fundSymbol, fundName);
    }

    function AcknowledgeNewAccountCreation(
        uint256 relationshipNumber,
        string memory externalAccountNumber,
        string memory taAccountNumber
    ) internal {
        //Get Account address
        address bcAccountAddress = _coreContract.GetBCAccountAddress(relationshipNumber, externalAccountNumber);
        
        if (bcAccountAddress == address(0) || _coreContract.GetAccountRelationshipNumber(bcAccountAddress) != relationshipNumber)
            checkForError("INVALID_ACCT");

        //Change account status and update TA Account Number
        _coreContract.UpdateTAAccountNumber(bcAccountAddress, taAccountNumber);
    }

    function AcknowledgeTradeOrder(
        uint256 taTransactionId,
        uint256 taTransactionLineNo,
        string memory bcTransactionId
    ) internal {
        //Get stored Fund Transaction
        DigitalInvestmentsCore.FundTransaction memory tran = _coreContract.GetFundTransaction(bcTransactionId);
        
        string memory errorMsg;
        
        if (!tran.Initialized)
            errorMsg = "INVALID_BCTXID";    // "Invalid Blockchain Transaction Id!");
        else if (tran.BCTransactionStatus != 0)
            errorMsg = "INVALID_BCTXSTAT";  //"Invalid Blockchain Transaction Status for this operation!"

        checkForError(errorMsg);

        //Update fund balance
        ERC20 FundContract = _coreContract.GetFundContract(tran.FundSymbol);

        //Mint token for BUY
        if (tran.TransactionType == 1) {
            FundContract.mint(tran.BCAccountAddress, tran.Shares);
        } else if (tran.TransactionType == 2) {
            if (FundContract.balanceOf(tran.BCAccountAddress) < tran.Shares)
                checkForError("INSUF_BAL");

            FundContract.burn(tran.BCAccountAddress, tran.Shares);
        }

        //Change transaction status to "Created on TA"
        _coreContract.AcknowledgeTradeOrder(taTransactionId, taTransactionLineNo, bcTransactionId);
    }

    function AcknowledgeBCTransaction(
        string memory eventType,
        uint256 number1,
        uint256 number2,
        string memory string1,
        string memory string2) 
    external 
    onlyOwner
    {
        if (DigitalInvestmentLibrary.CompareStrings(eventType, "new_account_created")) {
            AcknowledgeNewAccountCreation(number1, string1, string2);
        } else if (DigitalInvestmentLibrary.CompareStrings(eventType, "trade_created")) {
            AcknowledgeTradeOrder(number1, number2, string1);
        }
    }

    function AddNewRelationship(
        uint256 relationshipNumber,
        string memory relationshipName,
        string memory transactionPrefix)
    external 
    onlyOwner 
    {
        string memory errorMsg;

        if (relationshipNumber <= 0)
            errorMsg = "INVALD_RN"; // Invalid Relationship Number
        else if (DigitalInvestmentLibrary.CompareStrings(transactionPrefix, "") == true)
            errorMsg = "INVALD_TXPFX"; // Invalid Transaction Prefix";
        else if (_coreContract.IsRelationshipInitialized(relationshipNumber))
            errorMsg = "RN_INUSE"; // "Relationship already exists!";
        else if (_coreContract.GetRelationshipByTransactionPrefix(transactionPrefix) != 0)
            errorMsg = "TXPFX_INUSE!"; // "Transaction prefix in use!";

        checkForError(errorMsg);

        _coreContract.SetRelationship(DigitalInvestmentsCore.Relationship(
                                                relationshipNumber,
                                                relationshipName,
                                                transactionPrefix,
                                                1,
                                                true));
    }

    function ModifyRelationship(
        uint256 relationshipNumber,
        string memory relationshipName,
        string memory transactionPrefix)
    external 
    onlyOwner
    {
        uint256 txnPrefixRelation = _coreContract.GetRelationshipByTransactionPrefix(transactionPrefix);

        string memory errorMsg;

        if (relationshipNumber <= 0)
            errorMsg = "INVALD_RN"; // Invalid Relationship Number
        else if (DigitalInvestmentLibrary.CompareStrings(transactionPrefix, "") == true)
            errorMsg = "INVALD_TXPFX"; // Invalid Transaction Prefix";
        else if (!_coreContract.IsRelationshipInitialized(relationshipNumber))
            errorMsg = "INVALD_RN"; // Invalid Relationship Number
        else if (
            txnPrefixRelation != relationshipNumber && txnPrefixRelation != 0
        ) errorMsg = "TXPFX_INUSE"; // "Transaction prefix in use!";

        checkForError(errorMsg);

        _coreContract.UpdateRelationshipDetails(relationshipNumber, relationshipName, transactionPrefix);
    }

    function GetRelationshipsList()
    external
    view
    returns (DigitalInvestmentsCore.Relationship[] memory)
    {
        return _coreContract.GetRelationshipsList();
    }

    function Distribution(
        uint256 relationshipNumber,
        string memory externalAccountNumber,
        string memory fundSymbol,
        uint8 transactionType,
        uint256 shares,
        uint256 amount,
        uint256 taTransactionId,
        uint256 taTransactionLineNo
    ) external 
    onlyOwner 
    returns (string memory) {
        address bcAccountAddress = _coreContract.GetBCAccountAddress(relationshipNumber, externalAccountNumber);
        
        string memory errorMsg;
        
        if (transactionType < 51 || transactionType > 60)
            errorMsg = "INVALID_DISTTXTYP";  // "Invalid Transaction Type for Distribution!"
        else if (!_coreContract.IsFundInitialized(fundSymbol))
            errorMsg = "INVALID_FUND";  // "Invalid Fund!");
        else if (bcAccountAddress == address(0))
            errorMsg = "INVALID_ACCT";  // "Invalid Account!");
        else if (transactionType % 2 == 0 && shares <= 0)   //Share amount is mandatory for reinvestment trades
            errorMsg = "INVALID_DISTSHR";  //"Invalid Shares for Distribution!"

        checkForError(errorMsg);

        //Add transaction to the stucture
        return _coreContract.AddFundTransaction(relationshipNumber,
                externalAccountNumber,
                fundSymbol,
                transactionType,
                shares,
                amount,
                taTransactionId,
                taTransactionLineNo);
    }

    /****** Custodian / Investor Functions  */    
    function CreateNewAccountForBCAddress(
        string memory externalAccountNumber,
        string memory accountName,
        uint16 accountType,
        uint256 relationshipNumber,
        string memory customerName,
        string memory addressLines,
        address bcAccountAddress
    ) public 
    returns (address) {
        //BC Account Address should be valid and unused
        string memory errorMsg;
        
        if (bcAccountAddress != address(bcAccountAddress))
            errorMsg = "INVALID_BCADDR";    //"Invalid Blockchain Address!"
        else if (_coreContract.GetBCAccountAddress(relationshipNumber, externalAccountNumber) != address(0))
            errorMsg = "ACCT_EXISTS";  // "Account already exists!"

        checkForError(errorMsg);
        
        _coreContract.CreateNewAccountForBCAddress(externalAccountNumber, accountName, accountType,
                        relationshipNumber, customerName, addressLines, bcAccountAddress);

        return bcAccountAddress;
    }

    function CreateNewAccount(
        string memory externalAccountNumber,
        string memory accountName,
        uint16 accountType,
        uint256 relationshipNumber,
        string memory customerName,
        string memory addressLines
    ) external 
    returns (address) {
        // Generate new blockchain account address
        address bcAccountAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(block.timestamp))))
        );
        return
            CreateNewAccountForBCAddress(
                externalAccountNumber,
                accountName,
                accountType,
                relationshipNumber,
                customerName,
                addressLines,
                bcAccountAddress
            );
    }

    function Buy(
        uint256 relationshipNumber,
        string memory externalAccountNumber,
        string memory fundSymbol,
        uint256 shares,
        uint256 amount,
        string memory txReferenceNumber
    ) external 
    returns (string memory) {
        return
            CreateOrder(
                1,
                relationshipNumber,
                externalAccountNumber,
                fundSymbol,
                shares,
                amount,
                txReferenceNumber
            );
    }

    function Sell(
        uint256 relationshipNumber,
        string memory externalAccountNumber,
        string memory fundSymbol,
        uint256 shares,
        uint256 amount,
        string memory txReferenceNumber
    ) external 
    returns (string memory) {
        return
            CreateOrder(
                2,
                relationshipNumber,
                externalAccountNumber,
                fundSymbol,
                shares,
                amount,
                txReferenceNumber
            );
    }

    function CreateOrder(
        uint8 transactionType,
        uint256 relationshipNumber,
        string memory externalAccountNumber,
        string memory fundSymbol,
        uint256 shares,
        uint256 amount,
        string memory txReferenceNumber
    ) internal returns (string memory) {
        address bcAccountAddress = _coreContract.GetBCAccountAddress(relationshipNumber, externalAccountNumber);
        
        string memory errorMsg;

        if (transactionType != 1 && transactionType != 2)
           errorMsg = "INVALID_TXTYPE"; // "Invalid Transaction Type!"
        else if (!_coreContract.IsFundInitialized(fundSymbol))
            errorMsg = "INVALID_FUND";  // "Invalid Fund!");
        else if (bcAccountAddress == address(0))
            errorMsg = "INVALID_ACCT";  // "Invalid Account!");
        else if (shares <= 0)
            errorMsg = "INVALID_SHARES";  // "Invalid Shares!");

        // 107 bytes saved by replacing 2 "require" statements with single one as below
        // require(CompareStrings(errorMsg, ""), errorMsg);
        checkForError(errorMsg); //Replacing "require" with function call saves 81 bytes per call

        return _coreContract.CreateOrder(transactionType, relationshipNumber, externalAccountNumber, 
                                        fundSymbol, shares, amount, txReferenceNumber);
    }

    /**** Common Methods * START *****/
    function GetFundsList() 
    external view 
    returns (DigitalInvestmentsCore.Fund[] memory) 
    {
        return _coreContract.GetFundsList();
    }

    function GetAccountDetails(
        uint256 relationshipNumber,
        string memory externalAccountNumber) 
    external view 
    returns (DigitalInvestmentsCore.Account memory) 
    {
        address bcAccountAddress = _coreContract.GetBCAccountAddress(relationshipNumber, externalAccountNumber);
        
        DigitalInvestmentsCore.Account memory acct = _coreContract.GetAccountByBCAccountAddress(bcAccountAddress);
        //Validate that the account belongs to this relationship
        //require(acct.RelationshipNumber == relationshipNumber, "INVALID_ACCTNBR"); //"Invalid Account Number"
        
        if (acct.RelationshipNumber != relationshipNumber)
            checkForError("INVALID_ACCTNBR");

        return acct;
    }

    function GetTradesByAccount(
        uint256 relationshipNumber,
        string calldata externalAccountNumber
    ) public view 
    returns (DigitalInvestmentsCore.TradeInfo[] memory) {
        address bcAccountAddress = _coreContract.GetBCAccountAddress(relationshipNumber, externalAccountNumber);
        
        if (bcAccountAddress == address(0))
            checkForError("INVALID_ACCTNBR");

        return _coreContract.GetTradesByAccount(relationshipNumber, externalAccountNumber);
    }

    function GetAccountBalances(
        uint256 relationshipNumber,
        string calldata externalAccountNumber
    ) public view returns (DigitalInvestmentsCore.SubaccountHoldings[] memory) {
        return _coreContract.GetAccountBalances(relationshipNumber, externalAccountNumber);
    }
}