/**
 *Submitted for verification at polygonscan.com on 2022-02-10
*/

// File: contracts/SmartWallet.sol

pragma solidity ^0.8.0;

contract SmartWallet {
    string public name;
    
    struct Transaction {
        address receiver;
        uint value;
    }

    Transaction[] public transactions;

    address owner;

    event FundsDeposited(address indexed from, uint value);
    event FundsTransfered(address indexed receiver, uint value);

    modifier onlyOwner() {
        require(msg.sender == owner, "FINT: Sender is not the owner");
        _;
    }

    constructor(string memory _name, address _owner) {
        owner = _owner;
        name = _name;
    }

    function deposit() public payable {
        require(msg.value > 0, "FINT: please pay more than 0");

        emit FundsDeposited(msg.sender, msg.value);
    }

    function transfer(address _receiver, uint _value) public onlyOwner {
        require(_value > 0, "FINT: please transfer more than 0");
        require(address(this).balance > 0, "FINT: balance is lower than 0");
        require(address(this).balance >= _value, "FINT: balance is lower value");

        (bool success, ) = payable(_receiver).call{value: _value}("");
        require(success, "FINT: Transaction was not successful");

        Transaction storage transaction = transactions.push();
        transaction.receiver = _receiver;
        transaction.value = _value;

        emit FundsTransfered(_receiver, _value);
    }

    function getBalance() public view returns(uint balance) {
        balance = address(this).balance;
    }
}

// File: contracts/SmartWalletFactory.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract SmartWalletFactory {
	mapping(address => address[]) public contracts;

	event WalletCreated(address indexed owner, address indexed smartWallet);

	function createWallet(string memory name) public {
		SmartWallet smartWallet = new SmartWallet(name, msg.sender);
		contracts[msg.sender].push(address(smartWallet));
		emit WalletCreated(msg.sender, address(smartWallet));
	}

	function getWallet(address sender) public view returns(address[] memory _contracts) {
		_contracts = contracts[sender];
	}
}