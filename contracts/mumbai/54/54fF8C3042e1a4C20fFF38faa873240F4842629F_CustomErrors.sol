/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

error InvalidCall();
//"0xae962d4e"

contract CustomErrors {

    uint256 public number;
    
    function customError() public {
        number = 12;
        revert InvalidCall();
    }

    function normalError() public {
        number = 12;
        revert("InvalidCall()");
    }

    function encodeAbi(string memory _message) public pure returns(bytes memory) {
        return abi.encodeWithSignature(_message);
    }

}