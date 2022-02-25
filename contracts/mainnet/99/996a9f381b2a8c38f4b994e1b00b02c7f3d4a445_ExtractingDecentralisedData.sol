/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ExtractingDecentralisedData {

    // Count has initial value of 0
    uint public count;

    // Event stores logs of function parameters
    event Multiplied(address _from, uint value);

    // Event stores logs of function parameters
    event Decreased(address _from, uint value, string reason);

    function increaseValue() public {
        count += 1;
    }

    function decreaseValue(uint value, string memory reason) public {
        require (value >= 1);
        count -= 1;
        emit Decreased(msg.sender, value, reason);
    }

    function multiplyValue(uint value) public {
        require (value >= 2);
        count = count * value;
        emit Multiplied(msg.sender, value);
    }
}