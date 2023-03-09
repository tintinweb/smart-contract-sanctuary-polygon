/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Test {
    struct B {
    uint value1;
    uint value2;
}

struct A {
    uint aa;
    B[] bees;
}

    A public a;

    event SetSuccessfulA(A _a);
    event SetSuccessfulUint(uint myUint);
    event SetSuccessfulB(B _b);

    function setCalldata(A calldata _a) public {
        a = _a;
        emit SetSuccessfulA(_a);
        emit SetSuccessfulUint(123);

        B memory b = B({value1: 11, value2: 12});
        emit SetSuccessfulB(b);
    }

    function setMemory(A memory _a) public {
        a.bees.push(_a.bees[0]);
        a.bees.push(_a.bees[1]);
        emit SetSuccessfulA(_a);
        emit SetSuccessfulUint(123);
        
        B memory b = B({value1: 11, value2: 12});
        emit SetSuccessfulB(b);
    }

    function getArray() public view returns(B[] memory){
        return a.bees;
    }
}