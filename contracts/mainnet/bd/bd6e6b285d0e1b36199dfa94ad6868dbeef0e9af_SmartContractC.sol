/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISmartContractA {
    function transferOwnership(address newOwner) external;
}

contract SmartContractC {
    struct Univ1Struct {
        ISmartContractA univ1;
    }
    
    Univ1Struct public data;

    constructor(address smartContractAAddress) {
        data.univ1 = ISmartContractA(smartContractAAddress);
    }

    function transferOwnership(address newOwner) public {
        (bool success, ) = address(data.univ1).delegatecall(
            abi.encodeWithSignature("transferOwnership(address)", newOwner)
        );
        require(success, "delegatecall failed");
    }
}