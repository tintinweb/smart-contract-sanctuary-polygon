/**
 *Submitted for verification at polygonscan.com on 2022-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
    bytes32 internal constant implementationSlotEip1967 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant adminSlotEip1967 = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant implementationSlotEip897 = 0xbaab7dbf64751104133af04abc7d9979f0fda3b059a322a8333f533d3f32bf7f;
    bytes32 internal constant adminSlotEip897 = 0x44f6e2e8884cba1236b7f22f351fa5d88b17292b7e0225ca47e5ecdf6055cdd6;
    event Upgraded(address indexed);
    event AdminChanged(address, address);
    event ProxyUpdated(address indexed, address indexed);
    event ProxyOwnerUpdate(address, address);
    constructor() {
        setSlot(adminSlotEip1967, msg.sender);
        emit AdminChanged(address(0), msg.sender);
        setSlot(adminSlotEip897, msg.sender);
        emit ProxyOwnerUpdate(msg.sender, address(0));
    }
    function proxyType() public pure returns(uint256) {
        return 2;
    }
    function proxyOwner() public view returns(address) {
        return getSlot(adminSlotEip1967);
    }
    function implementation() public view returns(address) {
        return getSlot(implementationSlotEip1967);
    }
    function updateImplementation(address _implementation) public {
        address old;
        require(msg.sender == getSlot(adminSlotEip1967));
        setSlot(implementationSlotEip1967, _implementation);
        emit Upgraded(_implementation);
        old = getSlot(adminSlotEip897);
        setSlot(adminSlotEip897, _implementation);
        emit ProxyUpdated(_implementation, old);
    }
    function updateAdmin(address _admin) public {
        require(msg.sender == getSlot(adminSlotEip1967));
        setSlot(adminSlotEip1967, _admin);
        emit AdminChanged(msg.sender, _admin);
        setSlot(adminSlotEip897, _admin);
        emit ProxyOwnerUpdate(_admin, msg.sender);
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