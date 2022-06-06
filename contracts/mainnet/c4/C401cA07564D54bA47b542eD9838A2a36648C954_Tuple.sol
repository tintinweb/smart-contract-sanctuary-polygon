// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Tuple {
    struct Tuple {
        bool boolean;
        uint256 integer;
        address addr;
    }

    function call(Tuple[] calldata tuples) public {
        tuples;
    }
}