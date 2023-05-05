/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract TestFunctionValue {

    uint8 public value1;
    uint public value2;
    address public value3;
    string public value4;

    event Value1Set(uint8 value);
    event Value2Set(uint value);
    event Value3Set(address value);
    event Value4Set(string value);
    

    function getValue1() public virtual view returns (uint8) {
        return value1;
    }
    function getValue2() public virtual view returns (uint) {
        return value2;
    }
    function getValue3() public virtual view returns (address) {
        return value3;
    }
    function getValue4() public virtual view returns (string memory) {
        return value4;
    }
    
    function maincall(uint8 param1, uint256 param2, string memory param3) public returns (uint8, uint, string memory, address) {
        require(param1 > 10, "param1 should be higher than 10");
        require(param2 > 100, "param1 should be higher than 10");
        
        uint8 _variable1 = functionA(param1);
        uint256 _variable2 = functionB(param2);
        address _variable3 = functionC(param3);

        value1 = _variable1;
        emit Value1Set(value1);

        value2 = _variable2;
        emit Value2Set(value2);

        value3 = _variable3;
        emit Value3Set(value3);

        value4 = param3;
        emit Value4Set(value4);

        return (_variable1, _variable2, param3, _variable3);
    }

    function functionA(uint8 paramFuncA) pure public returns (uint8) {
        return paramFuncA * 2;
    }

    function functionB(uint paramFuncB) pure public returns (uint) {
        return paramFuncB -1;
    }

    function functionC(string memory paramFuncC) public returns (address) {
        string memory _funcBVariable1 = paramFuncC;

        return address(0xd3BECD25eca23e93F8Ce69AdDDfDb96C924E0e80);
    }

}