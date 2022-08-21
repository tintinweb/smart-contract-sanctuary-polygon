/**
 *Submitted for verification at polygonscan.com on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NoteChain {

    address public contractAddress;

    address public contractOwner;
    address public contractManager;

    uint256 public registerPrice;
    uint256 public editPrice;


    struct Note {

        uint256 noteCreateTime;
        uint256 noteEditTime;
        string  noteName;
        string  noteContent;
    }

    struct Profile {

        bool    isRegistered;
        string  authorName;
        uint256 registerTime;
        uint256 lastEditTime;
        Note[]  authorNotes;
    }
    mapping (address => Profile) private authorProfile;


    event registerFeeReceived(address indexed _authorAddress, uint _paidAmount, uint256 _feeTimestamp);
    event editFeeReceived(address indexed _authorAddress, uint _paidAmount, uint256 _feeTimestamp);
    

    constructor() {

        contractAddress = address(this);

        contractOwner   = msg.sender;
        contractManager = msg.sender;
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

    fallback() external payable {
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
        authorProfile[msg.sender].lastEditTime = block.timestamp;

        emit registerFeeReceived(msg.sender, msg.value, block.timestamp);
    }

    function setAuthorName(string calldata _newAuthorName) external payable requireValidOrigin requireRegisteredAuthor requireEditFee {

        authorProfile[msg.sender].authorName   = _newAuthorName;
        authorProfile[msg.sender].lastEditTime = block.timestamp;

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }


    function getAuthorStatus() external view requireValidCaller returns (bool) {

        return authorProfile[msg.sender].isRegistered;
    }

    function getAuthorName() external view requireValidCaller requireRegisteredAuthor returns (string memory) {

        return authorProfile[msg.sender].authorName;
    }

    function getAuthorRegisterTime() external view requireValidCaller requireRegisteredAuthor returns (uint256) {

        return authorProfile[msg.sender].registerTime;
    }

    function getAuthorLastEditTime() external view requireValidCaller requireRegisteredAuthor returns (uint256) {

        return authorProfile[msg.sender].lastEditTime;
    }

    function getNumberNotes() external view requireValidCaller requireRegisteredAuthor returns (uint256) {

        return authorProfile[msg.sender].authorNotes.length;
    }

    function getNotes() external view requireValidCaller requireRegisteredAuthor returns (uint256, Note[] memory) {

        return (authorProfile[msg.sender].authorNotes.length, authorProfile[msg.sender].authorNotes);
    }

    function getNoteById(uint256 _noteId) external view requireValidCaller requireRegisteredAuthor returns (Note memory) {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");

        return authorProfile[msg.sender].authorNotes[_noteId];
    }

    function getAuthorProfile() external view requireValidCaller requireRegisteredAuthor returns (uint256, Profile memory) {

        return (authorProfile[msg.sender].authorNotes.length, authorProfile[msg.sender]);
    }

    function getBootstrap() external view requireValidCaller requireRegisteredAuthor returns (uint256, uint256, uint256, Profile memory) {

        return (registerPrice, editPrice, authorProfile[msg.sender].authorNotes.length, authorProfile[msg.sender]);
    }


    function addNote(string calldata _newNoteName, string calldata _newNoteContent) external payable requireValidOrigin requireRegisteredAuthor requireEditFee {

        Note memory NewNote = Note(
            block.timestamp,
            block.timestamp,
            _newNoteName,
            _newNoteContent
        );

        authorProfile[msg.sender].authorNotes.push(NewNote);

        authorProfile[msg.sender].lastEditTime = block.timestamp;
        
        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }

    function editNote(uint256 _noteId, string calldata _noteName, string calldata _noteContent) external payable requireValidOrigin requireRegisteredAuthor requireEditFee {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");

        authorProfile[msg.sender].authorNotes[_noteId].noteEditTime = block.timestamp;
        authorProfile[msg.sender].authorNotes[_noteId].noteName     = _noteName;
        authorProfile[msg.sender].authorNotes[_noteId].noteContent  = _noteContent;

        authorProfile[msg.sender].lastEditTime = block.timestamp;

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }

    function deleteNote(uint256 _noteId) external payable requireValidOrigin requireRegisteredAuthor requireEditFee {

        require(_noteId < authorProfile[msg.sender].authorNotes.length, "wrong note id");

        if (_noteId < authorProfile[msg.sender].authorNotes.length - 1) {

            authorProfile[msg.sender].authorNotes[_noteId] = authorProfile[msg.sender].authorNotes[authorProfile[msg.sender].authorNotes.length - 1];
        }

        authorProfile[msg.sender].authorNotes.pop();

        authorProfile[msg.sender].lastEditTime = block.timestamp;

        emit editFeeReceived(msg.sender, msg.value, block.timestamp);
    }

}