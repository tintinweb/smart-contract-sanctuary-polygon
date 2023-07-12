// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestImported.sol";

contract TestImport {

    int8 public _number1;
    int8 public _number2;
    address public testImportedContractAddress;
    TestImported _testImportedContract;

    function setTestImported(address contract_) public {
        require(contract_ != address(0), "TestImported contract address is not valid");
        testImportedContractAddress = contract_;
    }

    function giveMeANumber(int8 number) public returns (int8) {
        require(number > 1, "number shoud be higher than 1");
        _number1 = number;

        _testImportedContract = TestImported(testImportedContractAddress);
        int8 _newNumber = _testImportedContract.giveNumber(number);

        _number2 = _newNumber;

        return _newNumber;
    }


    function newFunction(int8 newNumber) public returns (bool) {
        require(newNumber > 1, "invalid number");
        _number1 = newNumber + 10;

        return true;
    }

    function newFunction2(int8 newNumber1) public returns (bool) {
        require(newNumber1 > 1, "invalid number1");
        _number1 = newNumber1 + 10;

        return true;
    }

    function newFunction3(int8 newNumber3) public returns (bool) {
        require(newNumber3 > 1, "invalid number3");
        _number1 = newNumber3 + 10;

        return true;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestImported {

    int8 public _number;

    function giveNumber(int8 number) public returns (int8) {
        require(number > 10, "number shoud be higher than 10");
        _number = number;
        return number * 2;
    }
}