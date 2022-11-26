/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

pragma solidity ^0.8.13;

// SPDX-License-Identifier: MIT

contract MultiSigOwner {
    event AddOwner(address owner, uint256 txIndex);
    event DeleteOwner(address owner, uint256 txIndex);

    struct AuthTransaction {
        address toAddress;
        bool executed;
        uint256 numConfirmations;
        uint256 voteType;
    }
    address[] public owners;
    address[] public admins;
    mapping(address => bool) public isOwner;
    mapping(address => bool) public isAdmin;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    AuthTransaction[] public authTransactions;

    constructor() {
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier allOwnerAllowed(uint256 txIndex) {
        require(



                 
            authTransactions[txIndex].numConfirmations == owners.length,
            "not enough vote" 


              
        );
        _;
    }
    modifier halfOwnerAllowed(uint256 txIndex) {
        require(
            authTransactions[txIndex].numConfirmations >= owners.length / 2,
            "not enough vote"
        );
        _;
    }
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < authTransactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!authTransactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    function addAdminTransaction(address _toAddress) private {
        admins.push(_toAddress);
        isAdmin[_toAddress] = true;
    }

    function addOwnerTransaction(address _toAddress) private {
        owners.push(_toAddress);
        isOwner[_toAddress] = true;
    }

    function deleteOwnerTransaction(address _toAddress) private {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _toAddress) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
            }
        }
        if (owners[owners.length - 1] == _toAddress) {
            owners.pop();
        }
        isOwner[_toAddress] = false;
    }

    function deleteAdminTransaction(address _toAddress) private {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _toAddress) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
            }
        }
        if (admins.length > 0) {
            if (admins[admins.length - 1] == _toAddress) {
                admins.pop();
            }
        }
        isAdmin[_toAddress] = false;
    }

    function addVote(address _toAddress, uint256 _voteType)
        public
        onlyOwner
        returns (uint256 txIndex)
    {
        if (_voteType == 0) {
            require(!isOwner[_toAddress], "Already is owner!");
        }
        if (_voteType == 1) {
            require(!isAdmin[_toAddress], "Already is Admin!");
        }

        txIndex = authTransactions.length;
        isConfirmed[txIndex][msg.sender] = true;
        authTransactions.push(
            AuthTransaction({
                toAddress: _toAddress,
                executed: false,
                numConfirmations: 1,
                voteType: _voteType
            })
        );
    }

    function confirmVote(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        AuthTransaction storage transaction = authTransactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
    }

    function excuteAddOwner(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
        allOwnerAllowed(_txIndex)
    {
        require(authTransactions[_txIndex].voteType == 0, "type error!");
        addOwnerTransaction(authTransactions[_txIndex].toAddress);
        authTransactions[_txIndex].executed = true;
    }

    function excuteAddAdmin(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
        halfOwnerAllowed(_txIndex)
    {
        require(authTransactions[_txIndex].voteType == 1, "type error!");
        addAdminTransaction(authTransactions[_txIndex].toAddress);
        authTransactions[_txIndex].executed = true;
    }

    function excuteDeleteOwner(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
        allOwnerAllowed(_txIndex)
    {
        require(authTransactions[_txIndex].voteType == 10, "type error!");
        require(owners.length > 1, "Last Owner");
        deleteOwnerTransaction(authTransactions[_txIndex].toAddress);
        authTransactions[_txIndex].executed = true;
    }

    function excuteDeleteAdmin(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
        halfOwnerAllowed(_txIndex)
    {
        require(authTransactions[_txIndex].voteType == 11, "type error!");
        deleteAdminTransaction(authTransactions[_txIndex].toAddress);
        authTransactions[_txIndex].executed = true;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getAdmins() public view returns (address[] memory) {
 
        return admins;
    }
}