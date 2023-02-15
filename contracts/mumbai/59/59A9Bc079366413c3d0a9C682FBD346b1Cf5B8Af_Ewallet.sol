// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Ewallet {

    struct Individual {
        string name;
        uint256 balance;
        uint256 amountPayableToAdmin;
    }

    struct IndividualCredentials {
        string username;
        string password;
    }

    struct Team {
        string name;
        uint256 balance;
    }

    struct Transaction {
        uint256 fromIndividualID;
        uint256 toTeamID;
        uint256 amount;
        string description;
    }

    struct wheelTransaction {
        uint256 toIndividualID;
        uint256 fromTeamID;
        uint256 amount;
        string description;
    }

    struct VoucherCodeTransaction {
        uint256 fromTeamID;
        uint256 toTeamID;
        uint256 amount;
        string description;
    }

    uint256 public individualIDCount = 0;
    uint256 public teamIDCount = 0;
    uint256 public globalIndividualID = 0;
    uint256 public constant teamSize = 5;
    uint256 public miniPoolProfitTracker = 0;
    uint256 public voucherCodeCount = 0;

    mapping(uint256 => IndividualCredentials) private IDToIndividualCredentials;
    mapping(uint256 => Individual) public IDToIndividual;
    mapping(uint256 => Team) public IDToTeam;
    mapping(uint256 => uint256) public individualIDToTeamID;
    mapping(uint256 => uint256[]) public teamIDToTeamMembersID;

    mapping(uint256 => string) public voucherCodeIDToVoucherCode;
    mapping(uint256 => uint256) public voucherCodeIDToVoucherCodeStatus;
    // Voucher Code Status 0 = new
    // Voucher Code Status 1 = used

    mapping(uint256 => Transaction[]) public individualToTransactions; // My Transactions (Outgoing)
    mapping(uint256 => Transaction[]) public teamToTransactions; // My Team's Transactions (Incoming)
    mapping(uint256 => wheelTransaction[]) public miniPoolIndividualToTransactions; // My Transactions (Incoming)
    mapping(uint256 => wheelTransaction[]) public miniPoolTeamToTransactions; // My Team's Transactions (Outgoing)
    
    VoucherCodeTransaction[] public organizingTeamVoucherCodeTransactions;

    // Functions
    // addIndividual
    // addTeam
    // Top up
    // Transfer
    // View individual balance
    // View team balance

     modifier enoughBalance(uint256 _individualID, uint256 _amount) {
        require(IDToIndividual[_individualID].balance >= _amount);
        _;
    }

    modifier enoughTeamBalance(uint256 _fromTeamID, uint256 _amount) {
        require(IDToTeam[_fromTeamID].balance >= _amount);
        _;
    }

    modifier lesserThanMiniPoolProfitTracker(uint256 amount) {
        require(amount <= (miniPoolProfitTracker/2));
        _;
    }

     function addVoucherCode(string memory _voucherCode) public {
        voucherCodeCount += 1;
        voucherCodeIDToVoucherCode[voucherCodeCount] = _voucherCode;
        voucherCodeIDToVoucherCodeStatus[voucherCodeCount] = 0;
     }

     function updateVoucherCodeStatus(uint256 _voucherCodeID, uint256 _voucherCodeStatus) public {
        voucherCodeIDToVoucherCodeStatus[_voucherCodeID] = _voucherCodeStatus;
     }

     function addIndividual(string memory _name, string memory _username, string memory _password, uint256 _teamID) public returns(uint256){
        individualIDCount += 1;
        IndividualCredentials memory individualCredentials = IndividualCredentials(_username, _password);
        IDToIndividualCredentials[individualIDCount] = individualCredentials;
        Individual memory individual = Individual(_name, 30, 30);
        IDToIndividual[individualIDCount] = individual;
        
        // map individual ID to team ID
        // push individual ID into team ID mapping
        individualIDToTeamID[individualIDCount] = _teamID;
        teamIDToTeamMembersID[_teamID].push(individualIDCount);

        return individualIDCount;
     }

     function addTeam(string memory _name) public returns(uint256){
        Team memory team = Team(_name, 0);
        teamIDCount += 1;
        IDToTeam[teamIDCount] = team;
        return teamIDCount;
     }

     function topUp(uint256 _individualID, uint256 _amount) public {
        IDToIndividual[_individualID].balance = IDToIndividual[_individualID].balance + _amount;
        IDToIndividual[_individualID].amountPayableToAdmin = IDToIndividual[_individualID].amountPayableToAdmin + _amount;
     }

     function voucherCodeTransfer(uint256 _fromTeamID, uint256 _toTeamID, string memory _description, uint256 _amount) public
     enoughTeamBalance(_fromTeamID, _amount) {
        IDToTeam[_fromTeamID].balance = IDToTeam[_fromTeamID].balance - _amount;
        IDToTeam[_toTeamID].balance = IDToTeam[_toTeamID].balance + _amount;
        // record transaction related to voucher code paying and receiving team
        VoucherCodeTransaction memory voucherCodeTransaction = VoucherCodeTransaction(_fromTeamID, _toTeamID, _amount, _description);
        organizingTeamVoucherCodeTransactions.push(voucherCodeTransaction);
     }

     function transfer(uint256 _individualID, uint256 _teamID, string memory _description, uint256 _amount) public 
     enoughBalance(_individualID, _amount) {
        IDToIndividual[_individualID].balance = IDToIndividual[_individualID].balance - _amount;
        IDToTeam[_teamID].balance = IDToTeam[_teamID].balance + _amount;
        // record transaction related to every team and individual
        Transaction memory transaction = Transaction(_individualID, _teamID, _amount, _description);
        individualToTransactions[_individualID].push(transaction);
        teamToTransactions[_teamID].push(transaction);
     }

     function prizeTransfer(uint256 _individualID, uint256 _teamID, string memory _description, uint256 _amount) public {
        IDToIndividual[_individualID].balance = IDToIndividual[_individualID].balance + _amount;
        IDToTeam[_teamID].balance = IDToTeam[_teamID].balance - _amount;
         // record transaction related to every team and individual
        wheelTransaction memory wheeltransaction = wheelTransaction(_individualID, _teamID, _amount, _description);
        miniPoolIndividualToTransactions[_individualID].push(wheeltransaction);
        miniPoolTeamToTransactions[_teamID].push(wheeltransaction);
     }

     function addToMiniPoolProfit(uint256 _profit) public {
        miniPoolProfitTracker = miniPoolProfitTracker + _profit;
     }

     function subtractFromMiniPoolProfit(uint256 _amount) public lesserThanMiniPoolProfitTracker(_amount) {
        miniPoolProfitTracker = miniPoolProfitTracker - _amount;
     }

     function viewIndividualBalance(uint256 _individualID) public view returns(uint256){
        return IDToIndividual[_individualID].balance;
     }

     function viewTeamBalance(uint256 _teamID) public view returns(uint256){
        return IDToTeam[_teamID].balance;
     }

     function getIndividualIDByName(string memory _name) public view returns(uint256){
        uint256 localIndividualID;
        for(uint256 i = 1; i <= individualIDCount; i++) {
            if(keccak256(abi.encodePacked(IDToIndividual[i].name)) == keccak256(abi.encodePacked(_name))) {
                localIndividualID = i;
                break;
            }
        }

        return localIndividualID;
     }

     function getTeamIDByName(string memory _name) public view returns(uint256){
        uint256 localTeamID;
        for(uint256 i = 1; i <= teamIDCount; i++) {
            if(keccak256(abi.encodePacked(IDToTeam[i].name)) == keccak256(abi.encodePacked(_name))) {
                localTeamID = i;
                break;
            }
        }

        return localTeamID;
     }

     function getTransactionsByTeamID(uint256 _teamID) public view returns(Transaction[] memory){
            return teamToTransactions[_teamID];
     }

     function getMiniPoolTransactionsByTeamID(uint256 _teamID) public view returns(wheelTransaction[] memory){
            return miniPoolTeamToTransactions[_teamID];
     }

     function getTransactionsByIndividualID(uint256 _individualID) public view returns(Transaction[] memory){
            return individualToTransactions[_individualID];
     }

     function getMiniPoolTransactionsByIndividualID(uint256 _individualID) public view returns(wheelTransaction[] memory){
            return miniPoolIndividualToTransactions[_individualID];
     }

     function getTeamSize(uint256 _teamID) public view returns (uint){
    return teamIDToTeamMembersID[_teamID].length;
    }

    function getIndividualTransactionSize(uint256 _individualID) public view returns (uint){
    return individualToTransactions[_individualID].length;
    }

    function getMiniPoolIndividualTransactionSize(uint256 _individualID) public view returns (uint){
    return miniPoolIndividualToTransactions[_individualID].length;
    }

    function getTeamTransactionSize(uint256 _teamID) public view returns (uint){
    return teamToTransactions[_teamID].length;
    }

    function getMiniPoolTeamTransactionSize(uint256 _teamID) public view returns (uint){
    return miniPoolTeamToTransactions[_teamID].length;
    }



     function getIDByIndividualCredentials(string memory _username, string memory _password) public returns(uint256){
        globalIndividualID = 0;

        for(uint256 i = 1; i <= individualIDCount; i++) {
            string memory tempUsername = IDToIndividualCredentials[i].username;
            string memory tempPassword = IDToIndividualCredentials[i].password;
            if(keccak256(abi.encodePacked(tempUsername)) == keccak256(abi.encodePacked(_username)) &&
            keccak256(abi.encodePacked(tempPassword)) == keccak256(abi.encodePacked(_password))) {
                globalIndividualID = i;
                break;
            }
        }

        return globalIndividualID;
     }


}