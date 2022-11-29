// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @custom:unique 706e548b-e356-47e2-b626-ddfb2c0ab958
/// @custom:security-contact [email protected]
contract NoteChain {

    address   public  contractAddress;

    address   public  contractOwner;
    address   public  contractManager;
    address   public  contractOperator;

    uint256   public  registerPrice;
    uint256   public  editPrice;

    bool      public  paused;

    address[] private registeredAuthors;
    uint256   public  numberAuthors;


    struct Profile {

        bool    isRegistered;
        string  authorName;
        uint256 registerTime;
        uint256 lastEditTime;
        string  ipfsCurrentFileHash;
        string  ipfsPreviousFileHash;
    }
    mapping (address => Profile) private authorProfile;


    event registerEvent(address indexed _authorAddress, uint256 _eventTimestamp);
    event editEvent(address indexed _authorAddress, uint256 _eventTimestamp);
    event unregisterEvent(address indexed _authorAddress, uint256 _eventTimestamp);
    

    constructor() {

        contractAddress  = address(this);

        contractOwner    = address(0x6D97236Cdb31733E8354666f29E48E429386F360);
        contractManager  = msg.sender;
        contractOperator = msg.sender;

        registerPrice    = 0;
        editPrice        = 0;

        paused           = false;

        numberAuthors    = 0;
    }


    modifier requireValidCaller() {

        require(msg.sender != address(0), "Wrong caller address!");
        _;
    }

    modifier requireValidOrigin() {

        require(msg.sender != address(0), "Wrong caller address!");
        require(msg.sender == tx.origin, "Wrong origin address!");
        require(msg.sender.code.length == 0, "Contracts not allowed!");
        _;
    }

    modifier requireContractOwner() {

        require(msg.sender == contractOwner, "You are not an owner!");
        _;
    }

    modifier requireContractManager() {

        require(msg.sender == contractOwner || msg.sender == contractManager, "You are not a manager!");
        _;
    }

    modifier requireContractOperator() {

        require(msg.sender == contractOwner || msg.sender == contractManager || msg.sender == contractOperator, "You are not an operator!");
        _;
    }

    modifier requireNotRegisteredAuthor() {

        require(authorProfile[msg.sender].isRegistered == false, "You are already an author!");
        _;
    }

    modifier requireRegisteredAuthor() {

        require(authorProfile[msg.sender].isRegistered == true, "You are not an author!");
        _;
    }

    modifier requireRegisterFee() {

        require(msg.value == registerPrice, "Incorrect register fee value!");
        _;
    }

    modifier requireEditFee() {

        require(msg.value == editPrice, "Incorrect edit fee value!");
        _;
    }

    modifier requireNotPaused() {

        require(paused == false, "Service paused due to maintenance!");
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


    function withdrawContractBalance(address payable _withdrawReceiver, uint256 _withdrawAmount) external requireValidOrigin requireContractManager {

        require(_withdrawAmount <= contractAddress.balance, "Invalid withdraw value!");

        _withdrawReceiver.transfer(_withdrawAmount);
    }


    function switchPaused() external requireValidOrigin requireContractManager {

        paused = !paused;
    }


    function registerNewAuthor(string calldata _authorName) external payable requireNotPaused requireNotRegisteredAuthor requireValidOrigin requireRegisterFee {

        authorProfile[msg.sender].isRegistered = true;
        authorProfile[msg.sender].authorName   = _authorName;
        authorProfile[msg.sender].registerTime = block.timestamp;

        registeredAuthors.push(msg.sender);
        numberAuthors++;

        emit registerEvent(msg.sender, block.timestamp);
    }

    function opRegisterNewAuthor(address _authorAddress, string calldata _authorName, string calldata _newIpfsFileHash) external requireValidOrigin requireContractOperator {

        require(authorProfile[_authorAddress].isRegistered == false, "Author already registered!");

        authorProfile[_authorAddress].isRegistered        = true;
        authorProfile[_authorAddress].authorName          = _authorName;
        authorProfile[_authorAddress].ipfsCurrentFileHash = _newIpfsFileHash;
        authorProfile[_authorAddress].registerTime        = block.timestamp;

        registeredAuthors.push(_authorAddress);
        numberAuthors++;

        emit registerEvent(_authorAddress, block.timestamp);
    }

    function setAuthorName(string calldata _newAuthorName) external payable requireNotPaused requireRegisteredAuthor requireValidOrigin requireEditFee {

        authorProfile[msg.sender].authorName   = _newAuthorName;
        authorProfile[msg.sender].lastEditTime = block.timestamp;

        emit editEvent(msg.sender, block.timestamp);
    }

    function setIpfsFileHash(string calldata _newIpfsFileHash) external payable requireNotPaused requireRegisteredAuthor requireValidOrigin requireEditFee {

        authorProfile[msg.sender].ipfsPreviousFileHash = authorProfile[msg.sender].ipfsCurrentFileHash;
        authorProfile[msg.sender].ipfsCurrentFileHash  = _newIpfsFileHash;
        authorProfile[msg.sender].lastEditTime         = block.timestamp;

        emit editEvent(msg.sender, block.timestamp);
    }


    function getBootstrap() external view requireValidCaller returns (bool, uint256, uint256, Profile memory) {

        return (paused, registerPrice, editPrice, authorProfile[msg.sender]);
    }


    function removeRegisteredAuthor() external requireValidOrigin requireRegisteredAuthor {

        delete(authorProfile[msg.sender]);

        numberAuthors--;
        
        emit unregisterEvent(msg.sender, block.timestamp);
    }


    function getAllAuthors() external view requireValidCaller returns (address[] memory) {

        return registeredAuthors;
    }

    function getAuthorProfile() external view requireValidCaller returns (Profile memory) {

        return authorProfile[msg.sender];
    }

}