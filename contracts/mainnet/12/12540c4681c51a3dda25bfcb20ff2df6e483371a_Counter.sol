// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@remapped/Parent.sol";

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
//import "./Child.sol";