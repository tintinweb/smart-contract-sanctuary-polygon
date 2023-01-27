/**
 *Submitted for verification at polygonscan.com on 2023-01-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AddAToMyName {
    bytes32 public name = bytes32("Anshu");

    function add_A_to_my_name() public {
        name = bytes32(abi.encodePacked(name,"A"));
    }

        function getName() public pure returns (string memory) {
        bytes memory bytesName;
        assembly {
            bytesName := mload(name.slot)
        }
        return string(bytesName);
    }
}