/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

pragma solidity ^0.8.3;


contract DAOContract {

 address owner;
 enum loanStatus { registered, requested, inprogress, paid, defaulted }

 struct userLoanDetails{
     uint256 issuedDate;
     uint256 issuedAmount;
     loanStatus LoanStatus;
 }

 struct userDetails {
     address userAddress;
     string userName;
     string userRegistrationTimestamp;
     uint256 userId;
     uint256 userCreditScore;
     userLoanDetails userLoans;
 }

 userDetails[] public users;

 mapping ( address => userDetails) public userDetailsMapping;
 mapping ( string => address ) public getAddressFromName;
 
 modifier onlyOwner(){
    require(msg.sender == owner);
    _;
}

event timeDiffEvent(uint256 _time , uint256 _userCreditScore);

function registerUser(address _userAddress, string memory _userName, string memory _userRegistrationTimestamp, uint256 _userId) public {
    userLoanDetails memory _info = userLoanDetails(0,0,loanStatus.registered);

    userDetails memory x = userDetails(
        _userAddress,
        _userName,
        _userRegistrationTimestamp,
        _userId,
        1000,
        _info
    );

    users.push(x);
    userDetailsMapping[msg.sender] = x;
    getAddressFromName[_userName] = msg.sender;

}

function fetchNumberOfUsers() public view returns (uint256) {
   return users.length;
}

function fetchUserByName(string memory _userName)  public view returns (userDetails memory ){
    address contract_addr = getAddressFromName[_userName];
    return userDetailsMapping[contract_addr];
}

function deposit(string memory _userName , uint256 _amount ) public {
    address contract_addr = getAddressFromName[_userName];
    // User can return the whole amount at once
    require (_amount == userDetailsMapping[contract_addr].userLoans.issuedAmount,'Please pay the full amount');
    uint256 timeDiff =  block.timestamp - userDetailsMapping[contract_addr].userLoans.issuedDate;

    if ( timeDiff > 50 ){
        emit timeDiffEvent ( timeDiff , userDetailsMapping[contract_addr].userCreditScore );
        //Decrease user score is paid after deadline
        userDetailsMapping[contract_addr].userCreditScore = 850;
    }
    userDetailsMapping[contract_addr].userLoans.LoanStatus = loanStatus.paid;
}

function requestFund(string memory _userName , address payable _to , uint256 _amount) public returns (bool) {
    uint256 loanRequestTimestamp = block.timestamp;
    address contract_addr = getAddressFromName[_userName];
    // funds requested address should be diff from the requestor address
    require ( userDetailsMapping[contract_addr].userCreditScore > 700,'User shall have credit score greater than 700');
    //require ( userDetailsMapping[contract_addr].userLoans.LoanStatus == loanStatus.paid, 'Its required to pay back your previous loans');
    require ( _amount < 1000, 'Initial Loan cant be greater than 1000 USDC');
    userDetailsMapping[contract_addr].userLoans.issuedAmount = _amount;
    userDetailsMapping[contract_addr].userLoans.issuedDate = loanRequestTimestamp;
    return true;
 }
}