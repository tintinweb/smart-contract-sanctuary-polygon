/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//main contract
contract NoteChain {

    address public contractOwner;
    address public contractAddress;

    uint256 public registerPrice = 0;
    uint256 public updatePrice   = 0;

    mapping(address => bool) internal authors;


    constructor() {

        contractOwner   = msg.sender;
        contractAddress = address(this);
    }


    modifier requireOwner() {

        require(msg.sender == contractOwner, "You're not an owner");
        _;
    }

    
    receive() external payable {
    }


    function receiveRegisterFee() external payable returns(bool) {

        require(authors[msg.sender] == false, "You're already an author");
        require(msg.value == registerPrice, "Incorrect register fee value");

        authors[msg.sender] = true;

        return true;
    }


    function receiveUpdateFee() external payable returns(bool) {

        require(authors[msg.sender] == true, "You're not an author");
        require(msg.value == updatePrice, "Incorrect update fee value");

        return true;
    }


    function setRegisterPrice(uint256 _registerPrice) public requireOwner {

        registerPrice = _registerPrice;
    }


    function setUpdatePrice(uint256 _updatePrice) public requireOwner {

        updatePrice = _updatePrice;
    }


    function getContractBalance() public view returns(uint256) {

        return contractAddress.balance;
    }


    function checkAuthor(address _authorAddress) public view returns(bool) {

        return authors[_authorAddress];
    }


    function withdrawAllContractBalance(address _withdrawReceiver) external requireOwner {

        payable(_withdrawReceiver).transfer(contractAddress.balance);
    }


    function withdrawPartContractBalance(address _withdrawReceiver, uint256 _withdrawAmount) external requireOwner {

        require(_withdrawAmount <= contractAddress.balance, "Invalid withdraw amount");

        payable(_withdrawReceiver).transfer(_withdrawAmount);
    }

}