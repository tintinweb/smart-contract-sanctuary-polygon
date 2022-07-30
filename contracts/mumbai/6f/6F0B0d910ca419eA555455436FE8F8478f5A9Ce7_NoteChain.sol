/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract NoteChain {

    address internal contractAddress;
    address internal contractOwner;
    address internal contractManager;

    uint256 public   registerPrice;
    uint256 public   editPrice;


    struct Note {

        uint256 noteCreateTime;
        uint256 noteEditTime;
        string  noteName;
        string  noteContent;
    }

    struct Profile {

        bool   isRegistered;
        string authorName;
        Note[] authorNotes;
    }
    mapping (address => Profile) internal authorProfile;


    event someFeeReceived(address indexed _authorAddress, uint _paidAmount, uint256 _feeTimestamp);
    event registerFeeReceived(address indexed _authorAddress, uint _paidAmount, uint256 _feeTimestamp);
    event editFeeReceived(address indexed _authorAddress, uint _paidAmount, uint256 _feeTimestamp);
    

    constructor() {

        contractAddress = address(this);
        contractOwner   = msg.sender;
        contractManager = msg.sender;
    }


    modifier requireContractOwner() {

        require(msg.sender == contractOwner, "you are not an owner");
        _;
    }

    modifier requireContractManager() {

        require(msg.sender == contractOwner || msg.sender == contractManager, "you are not an owner or manager");
        _;
    }

    modifier requireRegisteredAuthor() {

        require(authorProfile[msg.sender].isRegistered == true, "you are not an author");
        _;
    }


    receive() external payable {

        emit someFeeReceived(msg.sender, msg.value, block.timestamp);
    }


    function getRegisterPrice() public view returns (uint256) {

        return registerPrice;
    }

    function getEditPrice() public view returns (uint256) {

        return editPrice;
    }


    function getContractManager() public view requireContractOwner returns (address) {

        return contractManager;
    }
    
    function changeContractManager(address _newContractManager) public requireContractOwner {

        contractManager = _newContractManager;
    }


    function withdrawAllContractBalance(address payable _withdrawReceiver) public requireContractManager {

        _withdrawReceiver.transfer(contractAddress.balance);
    }

    function withdrawPartContractBalance(address payable _withdrawReceiver, uint256 _withdrawAmount) public requireContractManager {

        require(_withdrawAmount <= contractAddress.balance, "invalid withdraw amount");

        _withdrawReceiver.transfer(_withdrawAmount);
    }


    function setRegisterPrice(uint256 _newRegisterPrice) public requireContractManager {

        registerPrice = _newRegisterPrice;
    }

    function setUpdatePrice(uint256 _newEditPrice) public requireContractManager {

        editPrice = _newEditPrice;
    }


    function getContractBalance() public view requireContractManager returns (uint256) {

        return contractAddress.balance;
    }


    function getAuthorStatus() public view returns (bool) {

        return authorProfile[msg.sender].isRegistered;
    }

    function getAuthorName() public view requireRegisteredAuthor returns (string memory) {

        return authorProfile[msg.sender].authorName;
    }

    function registerNewAuthor(string memory _authorName) public payable {

        require(authorProfile[msg.sender].isRegistered == false, "you are already an author");
        require(msg.value == registerPrice, "incorrect register fee value");

        authorProfile[msg.sender].isRegistered = true;
        authorProfile[msg.sender].authorName   = _authorName;

        emit registerFeeReceived(msg.sender, msg.value, block.timestamp);
    }

    function setAuthorName(string memory _newAuthorName) public payable requireRegisteredAuthor {

        require(msg.value == editPrice, "incorrect edit fee value");

        authorProfile[msg.sender].authorName = _newAuthorName;

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }


    function getNumberNotes() public view requireRegisteredAuthor returns (uint256) {

        return authorProfile[msg.sender].authorNotes.length;
    }

    function getNoteById(uint256 _noteId) public view requireRegisteredAuthor returns (Note memory) {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");

        return authorProfile[msg.sender].authorNotes[_noteId];
    }

    function getNotes() public view requireRegisteredAuthor returns (uint256, Note[] memory) {

        return (authorProfile[msg.sender].authorNotes.length, authorProfile[msg.sender].authorNotes);
    }

    function addNote(string memory _newNoteName, string memory _newNoteContent) public payable requireRegisteredAuthor {

        require(msg.value == editPrice, "incorrect edit fee value");

        Note memory NewNote = Note(
            block.timestamp,
            block.timestamp,
            _newNoteName,
            _newNoteContent
        );

        authorProfile[msg.sender].authorNotes.push(NewNote);
        
        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }

    function editNote(uint256 _noteId, string memory _noteName, string memory _noteContent) public payable requireRegisteredAuthor {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");
        require(msg.value == editPrice, "incorrect edit fee value");

        authorProfile[msg.sender].authorNotes[_noteId].noteEditTime = block.timestamp;
        authorProfile[msg.sender].authorNotes[_noteId].noteName     = _noteName;
        authorProfile[msg.sender].authorNotes[_noteId].noteContent  = _noteContent;

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }

    function deleteNote(uint256 _noteId) public payable requireRegisteredAuthor {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");
        require(msg.value == editPrice, "incorrect edit fee value");

        if (_noteId < authorProfile[msg.sender].authorNotes.length - 1) {

            authorProfile[msg.sender].authorNotes[_noteId] = authorProfile[msg.sender].authorNotes[authorProfile[msg.sender].authorNotes.length - 1];
        }

        authorProfile[msg.sender].authorNotes.pop();

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }

}