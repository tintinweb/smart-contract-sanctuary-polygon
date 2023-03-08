/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Test {
    struct B {
    uint value1;
    uint value2;
}

struct A {
    uint value1;
    B[] bees;
}

    A public a;

    constructor()
    { }

    event SetSuccessful(A _a);

    function set(A calldata _a) public {
        a = _a;
        emit SetSuccessful(_a);
    }
}