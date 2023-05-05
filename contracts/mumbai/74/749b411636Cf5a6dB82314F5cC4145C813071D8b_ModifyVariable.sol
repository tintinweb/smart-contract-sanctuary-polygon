//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ModifyVariable {
    uint public x;
    string public y;

    constructor(uint _x, string memory _y) {
        x = _x;
        y = _y;
    }

    function modifyToLeet() public {
        x = 1337;
    }

    function modifyToDevil() public {
        x = 666;
    }

    function modifyToLeasy() public {
        x = 8 * 8;
    }

    function reset() public {
        x = 0;
    }

    function modifyToLego() public {
        y = "Lego";
    }

    function modifyToCarlsberg() public {
        y = "Carlsberg";
    }
}