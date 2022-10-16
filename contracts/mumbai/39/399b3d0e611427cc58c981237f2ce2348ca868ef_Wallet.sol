/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: Logicalis
pragma solidity >=0.7.0 <0.9.0;

contract Wallet {
    address owner;
        
    struct Data {
        string userEmail;
        uint256 points;
        uint256 neutralizationPoints;
        uint256 lastTransactionAt;
        uint256 createdAt;
    }
   
    Data public data;
    event WalletCreated(Wallet wallet);
    address[] transactions;
   
    constructor(
        uint256 _points,
        uint256 _neutralizationPoints,
        string memory _userEmail,
        uint256 _createdAt
        
    ) {
       owner = msg.sender;
       data.points = _points;
       data.neutralizationPoints = _neutralizationPoints;
       data.createdAt = _createdAt;
       data.lastTransactionAt = _createdAt;
       data.userEmail = _userEmail;
       emit WalletCreated(this);
    }

    function _onlyOwner() private view{
        require(msg.sender == owner,"Not Owner");
    }
   
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
    
    function addCredits(uint256 _points, uint256 _neutralizationPoints, address _transactionAddress, uint256 _timestamp) onlyOwner public {
        data.points += _points;
        data.neutralizationPoints += _neutralizationPoints;
        transactions.push(_transactionAddress);
        data.lastTransactionAt = _timestamp;
    }
    
    function addDebits(uint256 _points, uint256 _neutralizationPoints, address _transactionAddress, uint256 _timestamp) onlyOwner public {
        data.points -= _points;
        data.neutralizationPoints -= _neutralizationPoints;
        transactions.push(_transactionAddress);
        data.lastTransactionAt = _timestamp;
    }
    
    function getPoints() public view returns (uint256) {
        return data.points;
    }
    
    function getNeutralizationPoints() public view returns (uint256) {
        return data.neutralizationPoints;
    }
    
    function getTransactions() public view returns (address[] memory) {
        return transactions;
    }

    function getData() public view returns (Data memory) {
        return data;
    }
}