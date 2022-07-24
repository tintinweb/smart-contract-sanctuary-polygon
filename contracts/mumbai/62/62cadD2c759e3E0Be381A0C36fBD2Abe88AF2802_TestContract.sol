// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestContract {

    struct Test {
        string cidImage;
        string cidTest;
        address ownerTest;
        address test;
        uint256 date;
    }

    mapping(address => string[]) public listOfAllTestsOfACompany; // Test -> Array uid Test
    mapping(string => Test) public listOfTests; // uid Test -> Test
    

    address owner;    

    event NewTest(address indexed from, address indexed test, string indexed uid);

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner of this smart contract");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function newTest(string calldata _cidImage, string calldata _cidTest, address _test, string calldata _uid) public onlyOwner {
        Test memory test = Test(
            _cidImage,
            _cidTest,
            tx.origin,
            _test,
            block.timestamp
        );
        listOfAllTestsOfACompany[_test].push(_uid);
        listOfTests[_uid] = test;
        emit NewTest(tx.origin,_test,_uid);
    }

    function getAllTestsOfACompany(address _company) public view returns(string[] memory) {
        return listOfAllTestsOfACompany[_company];
    }

    function getTest(string calldata _uid) public view returns(Test memory) {
        return listOfTests[_uid];
    }

}