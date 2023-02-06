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

    uint256 public individualIDCount = 0;
    uint256 public teamIDCount = 0;
    uint256 public globalIndividualID = 0;
    uint256 public constant teamSize = 5;

    mapping(uint256 => IndividualCredentials) private IDToIndividualCredentials;
    mapping(uint256 => Individual) public IDToIndividual;
    mapping(uint256 => Team) public IDToTeam;
    mapping(uint256 => uint256) public individualIDToTeamID;
    mapping(uint256 => uint256[]) public teamIDToTeamMembersID;

    mapping(uint256 => Transaction[]) public individualToTransactions;
    mapping(uint256 => Transaction[]) public teamToTransactions;

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

     function addIndividual(string memory _name, string memory _username, string memory _password) public returns(uint256){
        individualIDCount += 1;
        IndividualCredentials memory individualCredentials = IndividualCredentials(_username, _password);
        IDToIndividualCredentials[individualIDCount] = individualCredentials;
        Individual memory individual = Individual(_name, 30, 30);
        IDToIndividual[individualIDCount] = individual;

        if(individualIDCount % teamSize == 1) { // start if statement
            addTeam(string(abi.encodePacked(_name, "'s Team")));
        }

        // map individual ID to team ID
        // push individual ID into team ID mapping
        uint256 tempTeamID;
        if(individualIDCount % teamSize != 0) {
            tempTeamID = (individualIDCount/teamSize) + 1;
        }
        else if (individualIDCount % teamSize == 0) {
            tempTeamID = (individualIDCount/teamSize);
        }

        individualIDToTeamID[individualIDCount] = tempTeamID;
        teamIDToTeamMembersID[tempTeamID].push(individualIDCount);

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

     function transfer(uint256 _individualID, uint256 _teamID, string memory _description, uint256 _amount) public 
     enoughBalance(_individualID, _amount){
        IDToIndividual[_individualID].balance = IDToIndividual[_individualID].balance - _amount;
        IDToTeam[_teamID].balance = IDToTeam[_teamID].balance + _amount;
        // record transaction related to every team and individual
        Transaction memory transaction = Transaction(_individualID, _teamID, _amount, _description);
        individualToTransactions[_individualID].push(transaction);
        teamToTransactions[_teamID].push(transaction);
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

     function getTransactionsByIndividualID(uint256 _individualID) public view returns(Transaction[] memory){
            return individualToTransactions[_individualID];
     }

     function getTeamSize(uint256 _teamID) public view returns (uint){
    return teamIDToTeamMembersID[_teamID].length;
    }

    function getIndividualTransactionSize(uint256 _individualID) public view returns (uint){
    return individualToTransactions[_individualID].length;
    }

    function getTeamTransactionSize(uint256 _teamID) public view returns (uint){
    return teamToTransactions[_teamID].length;
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