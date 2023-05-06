/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

error CustomError();
error CustomErrorWithParam(uint256 foobar);

contract SimpleStorage {
    uint256 myNumber;
    struct People {
        uint256 myNumber;
        string name;
    }

    People[] public people;
    mapping (string=>uint256) public nameToMyNumber;

    function store(uint256 _myNumber) public {
        myNumber = _myNumber;
    }
    function retrive() public view returns(uint256) {
        return myNumber;
    }

    function addPerson(string memory _name, uint256 _myNumber) public{
        people.push(People(_myNumber,_name));
        nameToMyNumber[_name]=_myNumber;
    }

    function error1() external {
        revert CustomError();
    }
    function error2() external {
        revert CustomErrorWithParam(90);
    }
    function error3() external {
        revert("CustomRevertString");
    }
}