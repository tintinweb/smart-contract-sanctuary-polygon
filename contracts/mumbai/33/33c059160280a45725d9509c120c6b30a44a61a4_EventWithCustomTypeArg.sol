/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EventWithCustomTypeArg
{
    struct Custom
    {
        uint value;
    }

    Custom private c;

    event CustomValueSet(Custom _c);
    event CustomValueSet(uint _value);

    function setCustomValue(uint _value) public
    {
        c.value = _value;
        emit CustomValueSet(c);
        emit CustomValueSet(_value);
    }
}