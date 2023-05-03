/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {

    function foo() public pure returns (bytes memory) {
        bytes10 a = 0xA1646970667358221220;
        bytes32 b = 0xDDAD96EE388EA3A91AFACC6E49450CD0C3AFB02C3A60363D857A1D598C357A5F;
        return abi.encodePacked(a,b);
    }

    function malicious() public pure returns (bool) {
        return true;
    }
}