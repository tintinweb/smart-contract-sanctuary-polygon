// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @custom:unique 38eaee7e-0a7f-4538-9f18-84e3ee8ac260
/// @custom:security-contact [email protected]
contract NoteChain {

    uint256   public  registerPrice;
    uint256   public  editPrice;

    uint256   public  promoterRegisterFee;
    uint256   public  promoterEditFee;

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

        // Mainnet values (Wei)
//        registerPrice       = 1000000000000000000;
//        promoterRegisterFee = 500000000000000000;
//        editPrice           = 100000000000000000;
//        promoterEditFee     = 50000000000000000;

        // Mumbai  values (Wei)
        registerPrice       = 40000000000000000;
        promoterRegisterFee = 30000000000000000;
        editPrice           = 20000000000000000;
        promoterEditFee     = 10000000000000000;
    }


    modifier requireValidCaller() {

        require(msg.sender != address(0), "Wrong caller address!");
        _;
    }

    modifier requireValidOrigin() {

        require(msg.sender != address(0),    "Wrong caller address!");
        require(msg.sender == tx.origin,     "Wrong origin address!");
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

        require(authorProfile[msg.sender].isRegistered == true, "You are not an author yet!");
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

        require(_newPromoterRegisterFee < registerPrice, "Wrong promoter register fee value!");
        promoterRegisterFee = _newPromoterRegisterFee;
    }

    function setPromoterEditFee(uint256 _newPromoterEditFee) external requireContractManager {

        require(_newPromoterEditFee < editPrice, "Wrong promoter edit fee value!");
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


    function registerNewAuthor() external payable requireNotPaused requireValidOrigin requireRegisterFee requireNotRegisteredAuthor {

        authorProfile[msg.sender].isRegistered = true;
        authorProfile[msg.sender].registerTime = block.timestamp;

        registeredAuthors.push(msg.sender);

        emit registerEvent(msg.sender, block.timestamp);
    }

    function registerNewPromotedAuthor(address payable _promoterAddress) external payable requireNotPaused requireValidOrigin requireRegisterFee requireNotRegisteredAuthor {

        require(_promoterAddress != address(0), "Wrong promoter address!");
        require(_promoterAddress != msg.sender, "Wrong promoter address!");
        require(authorProfile[_promoterAddress].isRegistered == true, "Wrong promoter address!");

        authorProfile[msg.sender].isRegistered    = true;
        authorProfile[msg.sender].registerTime    = block.timestamp;
        authorProfile[msg.sender].promoterAddress = _promoterAddress;

        registeredAuthors.push(msg.sender);

        if (promoterRegisterFee > 0) {

            _promoterAddress.transfer(promoterRegisterFee);
        }

        emit registerEvent(msg.sender, block.timestamp);
    }

    function opRegisterNewAuthor(address _authorAddress, bytes32 _ipfsCurrentFileHash, bytes32 _ipfsPreviousFileHash, address _promoterAddress) external requireContractOperator {

        require(_authorAddress != address(0), "Wrong author address!");
        require(authorProfile[_authorAddress].isRegistered == false, "Author already registered!");

        require(_promoterAddress != _authorAddress, "Wrong promoter address!");

        authorProfile[_authorAddress].isRegistered         = true;
        authorProfile[_authorAddress].ipfsCurrentFileHash  = _ipfsCurrentFileHash;
        authorProfile[_authorAddress].ipfsPreviousFileHash = _ipfsPreviousFileHash;
        authorProfile[_authorAddress].registerTime         = block.timestamp;
        authorProfile[_authorAddress].promoterAddress      = _promoterAddress;

        registeredAuthors.push(_authorAddress);

        emit opRegisterEvent(_authorAddress, block.timestamp);
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

        emit unregisterEvent(msg.sender, block.timestamp);
    }


    function getBootstrap() external view requireValidCaller returns (bool, uint256, uint256, uint256, uint256, Profile memory) {

        return (contractPaused, registerPrice, editPrice, promoterRegisterFee, promoterEditFee, authorProfile[msg.sender]);
    }

    function getRegisteredAuthors() external view requireValidCaller returns (address[] memory) {

        return registeredAuthors;
    }

    function getAuthorProfile() external view requireValidCaller returns (Profile memory) {

        return authorProfile[msg.sender];
    }

}