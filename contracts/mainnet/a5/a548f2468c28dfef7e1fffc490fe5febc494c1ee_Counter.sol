/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Counter {
    uint public count;
    event Multiplied(address _from, uint value);

    function getValue() public view returns (uint) {
        return count;
    }

    function increaseValue() public {
        count += 1;
    }

    function decreaseValue() public {
        count -= 1;
    }

    function multiplyValue(uint value) public {
        require (value >= 1);
        count = count * value;
        emit Multiplied(msg.sender, value);
    }
}