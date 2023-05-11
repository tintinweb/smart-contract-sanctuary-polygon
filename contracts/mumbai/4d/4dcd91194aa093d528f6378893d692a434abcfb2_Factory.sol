// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./SimpleAbstract.sol";

contract Factory {
    mapping(address => address) public getAbstractAccount;
    address[] public allAbstracts;

    function allAbstractsLength() external view returns (uint) {
        return allAbstracts.length;
    }

    function createPair(address requestOwner) external returns (address abstractAccount) {
        bytes memory bytecode = type(SimpleAbstract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(requestOwner));
        assembly {
            abstractAccount := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getAbstractAccount[requestOwner] = abstractAccount;
        allAbstracts.push(abstractAccount);
    }
}