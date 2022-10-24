/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NoteChain {

    address public contractAddress;

    address public contractOwner;
    address public contractManager;

    uint256 public registerPrice;
    uint256 public editPrice;


    struct Profile {

        bool    isRegistered;
        string  authorName;
        uint256 registerTime;
        uint256 lastEditTime;
        string  ipfsCurrentFileHash;
        string  ipfsPreviousFileHash;
    }
    mapping (address => Profile) private authorProfile;


    event registerEvent(address indexed _authorAddress, uint _paidAmount, uint256 _feeTimestamp);
    event editEvent(address indexed _authorAddress, uint _paidAmount, uint256 _feeTimestamp);
    event unregisterEvent(address indexed _authorAddress, uint _paidAmount, uint256 _feeTimestamp);
    

    constructor() {

        contractAddress = address(this);

        contractOwner   = msg.sender;
        contractManager = msg.sender;

        registerPrice   = 0;
        editPrice       = 0;
    }


    modifier requireValidCaller() {

        require(msg.sender != address(0), "wrong caller address");
        _;
    }

    modifier requireValidOrigin() {

        require(msg.sender != address(0), "wrong caller address");
        require(msg.sender == tx.origin, "wrong origin address");
        require(msg.sender.code.length == 0, "contracts not allowed");
        _;
    }

    modifier requireContractOwner() {

        require(msg.sender == contractOwner, "you are not an owner");
        _;
    }

    modifier requireContractManager() {

        require(msg.sender == contractOwner || msg.sender == contractManager, "you are not a manager");
        _;
    }

    modifier requireRegisteredAuthor() {

        require(authorProfile[msg.sender].isRegistered == true, "you are not an author");
        _;
    }

    modifier requireRegisterFee() {

        require(msg.value == registerPrice, "incorrect register fee value");
        _;
    }

    modifier requireEditFee() {

        require(msg.value == editPrice, "incorrect edit fee value");
        _;
    }


    receive() external payable {
    }


    function setContractManager(address _newContractManager) external requireValidOrigin requireContractOwner {

        contractManager = _newContractManager;
    }

    function setRegisterPrice(uint256 _newRegisterPrice) external requireValidOrigin requireContractManager {

        registerPrice = _newRegisterPrice;
    }

    function setEditPrice(uint256 _newEditPrice) external requireValidOrigin requireContractManager {

        editPrice = _newEditPrice;
    }


    function withdrawAllContractBalance(address payable _withdrawReceiver) external requireValidOrigin requireContractManager {

        _withdrawReceiver.transfer(contractAddress.balance);
    }

    function withdrawPartContractBalance(address payable _withdrawReceiver, uint256 _withdrawAmount) external requireValidOrigin requireContractManager {

        require(_withdrawAmount <= contractAddress.balance, "invalid withdraw amount");

        _withdrawReceiver.transfer(_withdrawAmount);
    }


    function registerNewAuthor(string calldata _authorName) external payable requireValidOrigin requireRegisterFee {

        require(authorProfile[msg.sender].isRegistered == false, "you are already an author");

        authorProfile[msg.sender].isRegistered = true;
        authorProfile[msg.sender].authorName   = _authorName;
        authorProfile[msg.sender].registerTime = block.timestamp;

        emit registerEvent(msg.sender, msg.value, block.timestamp);
    }

    function setAuthorName(string calldata _newAuthorName) external payable requireValidOrigin requireRegisteredAuthor requireEditFee {

        authorProfile[msg.sender].authorName   = _newAuthorName;
        authorProfile[msg.sender].lastEditTime = block.timestamp;

        emit editEvent(msg.sender, msg.value, block.timestamp);
    }

    function setIpfsFileHash(string calldata _newIpfsFileHash) external payable requireValidOrigin requireRegisteredAuthor requireEditFee {

        authorProfile[msg.sender].ipfsPreviousFileHash = authorProfile[msg.sender].ipfsCurrentFileHash;
        authorProfile[msg.sender].ipfsCurrentFileHash  = _newIpfsFileHash;
        authorProfile[msg.sender].lastEditTime = block.timestamp;

        emit editEvent(msg.sender, msg.value, block.timestamp);
    }


    function getBootstrap() external view requireValidCaller returns (uint256, uint256, Profile memory) {

        return (registerPrice, editPrice, authorProfile[msg.sender]);
    }


    function removeRegisteredAuthor() external payable requireValidOrigin requireRegisteredAuthor requireEditFee {

        authorProfile[msg.sender].isRegistered         = false;
        authorProfile[msg.sender].authorName           = "";
        authorProfile[msg.sender].registerTime         = 0;
        authorProfile[msg.sender].lastEditTime         = 0;
        authorProfile[msg.sender].ipfsCurrentFileHash  = "";
        authorProfile[msg.sender].ipfsPreviousFileHash = "";

        emit unregisterEvent(msg.sender, msg.value, block.timestamp);
    }

}