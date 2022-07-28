/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//main contract
contract NoteChain {

    address internal contractOwner;
    address internal contractAddress;

    uint256 internal registerPrice = 0;
    uint256 internal updatePrice   = 0;


    struct Note {

        uint256 id;
        string  name;
        string  content;
    }
    mapping (address => Note[]) internal authorNotes;

    struct Profile {

        bool flag;
        string name;
    }
    mapping (address => Profile) internal authorProfile;
    

    constructor() {

        contractOwner   = msg.sender;
        contractAddress = address(this);
    }


    modifier requireOwner() {

        require(msg.sender == contractOwner, "You're not an owner");
        _;
    }

    modifier requireAuthor() {

        require(authorProfile[msg.sender].flag == true, "You're not an author");
        _;
    }


    receive() external payable {
    }

    function receiveRegisterFee() external payable returns (bool success) {

        require(authorProfile[msg.sender].flag == false, "You're already an author");
        require(msg.value == registerPrice, "Incorrect register fee value");

        authorProfile[msg.sender].flag = true;

        return true;
    }

    function receiveUpdateFee() external payable requireAuthor returns (bool success) {

        require(msg.value == updatePrice, "Incorrect update fee value");

        return true;
    }


    function withdrawAllContractBalance(address payable _withdrawReceiver) external requireOwner returns (bool success) {

        _withdrawReceiver.transfer(contractAddress.balance);

        return true;
    }

    function withdrawPartContractBalance(address payable _withdrawReceiver, uint256 _withdrawAmount) external requireOwner returns (bool success) {

        require(_withdrawAmount <= contractAddress.balance, "Invalid withdraw amount");

        _withdrawReceiver.transfer(_withdrawAmount);

        return true;
    }


    function setRegisterPrice(uint256 _registerPrice) public requireOwner returns (bool success) {

        registerPrice = _registerPrice;

        return true;
    }

    function setUpdatePrice(uint256 _updatePrice) public requireOwner returns (bool success) {

        updatePrice = _updatePrice;

        return true;
    }


    function getContractBalance() public view returns (uint256) {

        return contractAddress.balance;
    }


    function getAuthorFlag() public view returns (bool) {

        return authorProfile[msg.sender].flag;
    }

    function getAuthorName() public view requireAuthor returns (string memory) {

        return authorProfile[msg.sender].name;
    }

    function setAuthorName(string memory _newName) public requireAuthor returns (bool success) {

        authorProfile[msg.sender].name = _newName;

        return true;
    }


    function getNotes() public view requireAuthor returns (uint256, Note[] memory) {

        return (authorNotes[msg.sender].length, authorNotes[msg.sender]);
    }

    function addNote(string memory _name, string memory _content) public requireAuthor returns (bool success) {

        Note memory NewNote;
        NewNote.id      = authorNotes[msg.sender].length;
        NewNote.name    = _name;
        NewNote.content = _content;

        authorNotes[msg.sender].push(NewNote);
        
        return true;
    }

    function deleteNote(uint256 _id) public requireAuthor returns (bool success) {

        for (uint256 i = 0; i < authorNotes[msg.sender].length; i++) {

            if (authorNotes[msg.sender][i].id == _id) {

                authorNotes[msg.sender][i] = authorNotes[msg.sender][authorNotes[msg.sender].length - 1];
                authorNotes[msg.sender].pop();

                break;
            }
        }

        for (uint256 i = 0; i < authorNotes[msg.sender].length; i++) {

            authorNotes[msg.sender][i].id = i;
        }

        return true;
    }

}