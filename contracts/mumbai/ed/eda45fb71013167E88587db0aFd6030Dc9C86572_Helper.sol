// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./A.sol";

contract Helper {

    function mult(address addr, int factor) public view returns(int) {
        A instance = A(addr);
        int result = instance.c() * factor;
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
import "./Helper.sol";

contract A {
    int public c;
    address private helperAddress;

    constructor(address helper) {
        helperAddress = helper;
    }
    function add(int a, int b) public returns(int) {
        c = a+b;
        return c;
    }
    function mult(int factor) public view returns(int) {
        Helper helper = Helper(helperAddress);
        return helper.mult(address(this), factor);
    }

}