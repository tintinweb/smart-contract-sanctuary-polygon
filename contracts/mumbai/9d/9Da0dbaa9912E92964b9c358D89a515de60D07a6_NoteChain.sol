// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @custom:unique 37f52983-e61a-4570-9e71-47d985b9315f
/// @custom:security-contact [email protected]
contract NoteChain {

    uint256   public  registerPrice;
    uint256   public  editPrice;

    uint256   public  promoterRegisterFee;
    uint256   public  promoterEditFee;

    uint256   public  numberAuthors;

    address   public  contractAddress;

    address   public  contractOwner;
    address   public  contractManager;
    address   public  contractOperator;

    bool      public  contractPaused;

    address[] private registeredAuthors;


    struct Profile {

        uint256 registerTime;
        uint256 lastEditTime;

        address promoterAddress;

        bytes32 authorName;

        bytes32 ipfsCurrentFileHash;
        bytes32 ipfsPreviousFileHash;

        bool    isRegistered;
    }
    mapping (address => Profile) private authorProfile;


    event registerEvent(address indexed _authorAddress, uint256 _eventTimestamp);
    event opRegisterEvent(address indexed _authorAddress, uint256 _eventTimestamp);
    event editEvent(address indexed _authorAddress, uint256 _eventTimestamp);
    event unregisterEvent(address indexed _authorAddress, uint256 _eventTimestamp);
    

    constructor() {

        contractAddress     = address(this);

        contractOwner       = address(0x6D97236Cdb31733E8354666f29E48E429386F360);
        contractManager     = msg.sender;
        contractOperator    = msg.sender;

        registerPrice       = 1000000000000000000;
        editPrice           = 100000000000000000;

        promoterRegisterFee = 500000000000000000;
        promoterEditFee     = 50000000000000000;
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

        require(msg.sender == contractOwner, "You are not an Owner!");
        _;
    }

    modifier requireContractManager() {

        require(msg.sender == contractOwner || msg.sender == contractManager, "You are not a Manager!");
        _;
    }

    modifier requireContractOperator() {

        require(msg.sender == contractOwner || msg.sender == contractManager || msg.sender == contractOperator, "You are not an Operator!");
        _;
    }

    modifier requireNotRegisteredAuthor() {

        require(authorProfile[msg.sender].isRegistered == false, "You are already an Author!");
        _;
    }

    modifier requireRegisteredAuthor() {

        require(authorProfile[msg.sender].isRegistered == true, "You are not an Author yet!");
        _;
    }

    modifier requireRegisterFee() {

        require(msg.value == registerPrice, "Incorrect Register Fee value!");
        _;
    }

    modifier requireEditFee() {
        require(msg.value == editPrice, "Incorrect Edit Fee value!");
        _;
    }

    modifier requireNotPaused() {

        require(contractPaused == false, "Service paused due to maintenance!");
        _;
    }


    receive() external payable {
    }


    function setContractManager(address _newContractManager) external requireContractOwner {

        require(_newContractManager != address(0), "Wrong address given!");
        contractManager = _newContractManager;
    }

    function setContractOperator(address _newContractOperator) external requireContractManager {

        require(_newContractOperator != address(0), "Wrong address given!");
        contractManager = _newContractOperator;
    }


    function setRegisterPrice(uint256 _newRegisterPrice) external requireContractManager {

        registerPrice = _newRegisterPrice;
    }

    function setEditPrice(uint256 _newEditPrice) external requireContractManager {

        editPrice = _newEditPrice;
    }

    function setPromoterRegisterFee(uint256 _newPromoterRegisterFee) external requireContractManager {

        promoterRegisterFee = _newPromoterRegisterFee;
    }

    function setPromoterEditFee(uint256 _newPromoterEditFee) external requireContractManager {

        promoterEditFee = _newPromoterEditFee;
    }


    function withdrawContractBalance(address payable _withdrawReceiver, uint256 _withdrawAmount) external requireContractOwner {

        require(_withdrawReceiver != address(0), "Wrong address given!");
        require(_withdrawAmount <= contractAddress.balance, "Invalid withdraw value!");

        _withdrawReceiver.transfer(_withdrawAmount);
    }


    function switchPaused() external requireContractManager {

        contractPaused = !contractPaused;
    }


    function registerNewAuthor(bytes32 _authorName) external payable requireNotPaused requireValidOrigin requireRegisterFee requireNotRegisteredAuthor {

        authorProfile[msg.sender].isRegistered = true;
        authorProfile[msg.sender].authorName   = _authorName;
        authorProfile[msg.sender].registerTime = block.timestamp;

        registeredAuthors.push(msg.sender);
        numberAuthors++;

        emit registerEvent(msg.sender, block.timestamp);
    }

    function registerNewPromotedAuthor(bytes32 _authorName, address payable _promoterAddress) external payable requireNotPaused requireValidOrigin requireRegisterFee requireNotRegisteredAuthor {

        require(
            _promoterAddress != address(0) &&
            _promoterAddress != msg.sender &&
            authorProfile[_promoterAddress].isRegistered == true, "Wrong promoter address given!");

        authorProfile[msg.sender].isRegistered    = true;
        authorProfile[msg.sender].authorName      = _authorName;
        authorProfile[msg.sender].registerTime    = block.timestamp;
        authorProfile[msg.sender].promoterAddress = _promoterAddress;

        registeredAuthors.push(msg.sender);
        numberAuthors++;

        if (promoterRegisterFee > 0) {

            _promoterAddress.transfer(promoterRegisterFee);
        }

        emit registerEvent(msg.sender, block.timestamp);
    }

    function opRegisterNewAuthor(address _authorAddress, bytes32 _authorName, bytes32 _ipfsCurrentFileHash, bytes32 _ipfsPreviousFileHash, address _promoterAddress) external requireContractOperator {

        require(authorProfile[_authorAddress].isRegistered == false, "Author already registered!");

        authorProfile[_authorAddress].isRegistered         = true;
        authorProfile[_authorAddress].authorName           = _authorName;
        authorProfile[_authorAddress].ipfsCurrentFileHash  = _ipfsCurrentFileHash;
        authorProfile[_authorAddress].ipfsPreviousFileHash = _ipfsPreviousFileHash;
        authorProfile[_authorAddress].registerTime         = block.timestamp;
        authorProfile[_authorAddress].promoterAddress      = _promoterAddress;

        registeredAuthors.push(_authorAddress);
        numberAuthors++;

        emit opRegisterEvent(_authorAddress, block.timestamp);
    }


    function setAuthorName(bytes32 _newAuthorName) external payable requireNotPaused requireValidOrigin requireEditFee requireRegisteredAuthor {

        authorProfile[msg.sender].authorName   = _newAuthorName;
        authorProfile[msg.sender].lastEditTime = block.timestamp;

        if ( authorProfile[msg.sender].promoterAddress != address(0) && promoterRegisterFee > 0 ) {

            address payable promoterAddress_ = payable(authorProfile[msg.sender].promoterAddress);
            promoterAddress_.transfer(promoterEditFee);
        }

        emit editEvent(msg.sender, block.timestamp);
    }

    function setIpfsFileHash(bytes32 _newIpfsFileHash) external payable requireNotPaused requireValidOrigin requireEditFee requireRegisteredAuthor {

        authorProfile[msg.sender].ipfsPreviousFileHash = authorProfile[msg.sender].ipfsCurrentFileHash;
        authorProfile[msg.sender].ipfsCurrentFileHash  = _newIpfsFileHash;
        authorProfile[msg.sender].lastEditTime         = block.timestamp;

        if ( (promoterRegisterFee > 0) && (authorProfile[msg.sender].promoterAddress != address(0)) ) {

            address payable promoterAddress_ = payable(authorProfile[msg.sender].promoterAddress);
            promoterAddress_.transfer(promoterEditFee);
        }

        emit editEvent(msg.sender, block.timestamp);
    }


    function restoreIpfsFileHash() external requireNotPaused requireValidOrigin requireRegisteredAuthor {

        authorProfile[msg.sender].ipfsCurrentFileHash = authorProfile[msg.sender].ipfsPreviousFileHash;
        authorProfile[msg.sender].lastEditTime        = block.timestamp;

        emit editEvent(msg.sender, block.timestamp);
    }

    function removeRegisteredAuthor() external requireNotPaused requireValidOrigin requireRegisteredAuthor {

        delete(authorProfile[msg.sender]);

        numberAuthors--;
        
        emit unregisterEvent(msg.sender, block.timestamp);
    }


    function getBootstrap() external view requireValidCaller returns (bool, uint256, uint256, uint256, uint256, Profile memory) {

        return (contractPaused, registerPrice, editPrice, promoterRegisterFee, promoterEditFee, authorProfile[msg.sender]);
    }

    function getAllAuthors() external view requireValidCaller returns (address[] memory) {

        return registeredAuthors;
    }

    function getAuthorProfile() external view requireValidCaller returns (Profile memory) {

        return authorProfile[msg.sender];
    }

}