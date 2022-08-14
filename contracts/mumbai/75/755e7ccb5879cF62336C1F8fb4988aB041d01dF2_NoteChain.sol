/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract NoteChain {

    address public contractAddress;
    address private contractOwner;
    address private contractManager;

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
    mapping (address => Profile) private authorProfile;


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

        require(msg.sender == contractOwner || msg.sender == contractManager, "you are not a manager");
        _;
    }

    modifier requireRegisteredAuthor() {

        require(authorProfile[msg.sender].isRegistered == true, "you are not an author");
        _;
    }


    receive() external payable {
    }

    fallback() external payable {
    }


    function getMyAddress() external view returns (address) {

        return msg.sender;
    }

    function getRegisterPrice() external view returns (uint256) {

        return registerPrice;
    }

    function getEditPrice() external view returns (uint256) {

        return editPrice;
    }


    function getContractManager() external view requireContractOwner returns (address) {

        return contractManager;
    }
    
    function setContractManager(address _newContractManager) external requireContractOwner {

        contractManager = _newContractManager;
    }


    function withdrawAllContractBalance(address payable _withdrawReceiver) external requireContractManager {

        _withdrawReceiver.transfer(contractAddress.balance);
    }

    function withdrawPartContractBalance(address payable _withdrawReceiver, uint256 _withdrawAmount) external requireContractManager {

        require(_withdrawAmount <= contractAddress.balance, "invalid withdraw amount");

        _withdrawReceiver.transfer(_withdrawAmount);
    }


    function setRegisterPrice(uint256 _newRegisterPrice) external requireContractManager {

        registerPrice = _newRegisterPrice;
    }

    function setUpdatePrice(uint256 _newEditPrice) external requireContractManager {

        editPrice = _newEditPrice;
    }


    function getContractBalance() external view requireContractManager returns (uint256) {

        return contractAddress.balance;
    }


    function getAuthorStatus() external view returns (bool) {

        return authorProfile[msg.sender].isRegistered;
    }

    function getAuthorName() external view requireRegisteredAuthor returns (string memory) {

        return authorProfile[msg.sender].authorName;
    }

    function registerNewAuthor(string calldata _authorName) external payable {

        require(msg.sender.code.length == 0, "contracts not allowed");
        require(authorProfile[msg.sender].isRegistered == false, "you are already an author");
        require(msg.value == registerPrice, "incorrect register fee value");

        authorProfile[msg.sender].isRegistered = true;
        authorProfile[msg.sender].authorName   = _authorName;

        emit registerFeeReceived(msg.sender, msg.value, block.timestamp);
    }

    function setAuthorName(string calldata _newAuthorName) external payable requireRegisteredAuthor {

        require(msg.value == editPrice, "incorrect edit fee value");

        authorProfile[msg.sender].authorName = _newAuthorName;

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }


    function getNumberNotes() external view requireRegisteredAuthor returns (uint256) {

        return authorProfile[msg.sender].authorNotes.length;
    }

    function getNoteById(uint256 _noteId) external view requireRegisteredAuthor returns (Note memory) {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");

        return authorProfile[msg.sender].authorNotes[_noteId];
    }

    function getNotes() external view requireRegisteredAuthor returns (uint256, Note[] memory) {

        return (authorProfile[msg.sender].authorNotes.length, authorProfile[msg.sender].authorNotes);
    }

    function addNote(string calldata _newNoteName, string calldata _newNoteContent) external payable requireRegisteredAuthor {

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

    function editNote(uint256 _noteId, string calldata _noteName, string calldata _noteContent) external payable requireRegisteredAuthor {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");
        require(msg.value == editPrice, "incorrect edit fee value");

        authorProfile[msg.sender].authorNotes[_noteId].noteEditTime = block.timestamp;
        authorProfile[msg.sender].authorNotes[_noteId].noteName     = _noteName;
        authorProfile[msg.sender].authorNotes[_noteId].noteContent  = _noteContent;

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }

    function deleteNote(uint256 _noteId) external payable requireRegisteredAuthor {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");
        require(msg.value == editPrice, "incorrect edit fee value");

        if (_noteId < authorProfile[msg.sender].authorNotes.length - 1) {

            authorProfile[msg.sender].authorNotes[_noteId] = authorProfile[msg.sender].authorNotes[authorProfile[msg.sender].authorNotes.length - 1];
        }

        authorProfile[msg.sender].authorNotes.pop();

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }

}