// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Counter2} from "./stuff/Counter2.sol";

contract Counter {
    Counter2 public c2;
    uint256 public number;

    constructor() {
        c2 = new Counter2();
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter2 {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}