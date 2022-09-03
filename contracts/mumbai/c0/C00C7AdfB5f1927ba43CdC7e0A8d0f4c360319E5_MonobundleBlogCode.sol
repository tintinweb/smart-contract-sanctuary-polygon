pragma solidity 0.8.9;

contract MonobundleBlogCode {

    struct Account {
        string name;
        uint256 balance;
    }

    mapping(address => Account) public accounts;
    constructor() {}

    function setAccount(string calldata _newName) external payable {
        Account storage account = accounts[msg.sender];
        account.name = _newName;
        account.balance += msg.value;
    }
}