/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

// File: ./Imported.sol

contract Imported {
    function bar() public pure returns (uint) {
        return 1;
    }
}

// File: Import.sol

contract Import {

    Imported imported;

    constructor() {
        imported = new Imported();
    }

    function foo() public pure returns (uint) {
        return 1;
    }

    function bar() public view returns (uint) {
        return imported.bar();
    }
}