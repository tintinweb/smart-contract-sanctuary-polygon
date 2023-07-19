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

    function newfunc7() public {
        int8 _newValue = 100;
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