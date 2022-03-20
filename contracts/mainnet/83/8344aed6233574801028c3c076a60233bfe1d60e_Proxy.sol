/**
 *Submitted for verification at polygonscan.com on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
    bytes32 internal constant implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    constructor() {
        setSlot(adminSlot, msg.sender);
    }
    function updateImplementation(address _implementation) public {
        require(msg.sender == getSlot(adminSlot));
        setSlot(implementationSlot, _implementation);
    }
    function implementation() public view returns(address) {
        return getSlot(implementationSlot);
    }
    fallback() payable external {
        delegate();
    }
    receive() payable external {
        delegate();
    }
    function getSlot(bytes32 slot) internal view returns(address) {
        address a;
        assembly {
            a := sload(slot)
        }
        return a;
    }
    function setSlot(bytes32 slot, address a) internal {
        assembly {
            sstore(slot, a)
        }
    }
    function delegate() internal {
        address i = implementation();
        assembly {
            let p := mload(0x40)
            calldatacopy(p, 0, calldatasize())
            let r := delegatecall(gas(), i, p, calldatasize(), 0, 0)
            let s := returndatasize()
            returndatacopy(p, 0, s)
            if eq(r, 0) {
                revert(p, s)
            }
            return(p, s)
        }
    }
}