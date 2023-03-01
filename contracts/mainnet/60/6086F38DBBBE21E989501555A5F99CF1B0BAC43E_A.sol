// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract A {
    function f(bytes memory a, uint b) external {

    }

    function g(bytes calldata a, uint b) external {

    }
}

contract B {
    function f(A a) external {
        bytes memory b = new bytes(33);
        for (uint i =0; i < 33; i++) b[i] = 0xff;
        a.f(b, 42);
    }
}