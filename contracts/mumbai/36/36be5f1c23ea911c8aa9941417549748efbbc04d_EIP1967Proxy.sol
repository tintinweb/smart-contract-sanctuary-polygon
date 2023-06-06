/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Proxy {
    function _implementation() internal view returns(address impl) {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        assembly {
            impl := sload(slot)
        }
    }

    function _upgradeTo(address newImplementation) internal {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _proxyOwner() internal view returns (address owner) {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
        assembly {
            owner := sload(slot)
        }
    }

    function _setProxyOwner(address newOwner) internal {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
        assembly {
            sstore(slot, newOwner)
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        address _impl = _implementation();
        require(_impl != address(0), "EIP1967Proxy: implementation is zero");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract EIP1967Proxy is Proxy {

    event ProxyOwnershipTransferred(address previousOwner, address newOwner);
    event Upgraded(address indexed implementation);

    constructor(address owner, address initialImplementation) {
        require(initialImplementation != address(0), "EIP1967Proxy: initial implementation is zero");
        require(owner != address(0), "EIP1967Proxy: initial owner is zero");
        _setProxyOwner(owner);
        _upgradeTo(initialImplementation);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == _proxyOwner(), "EIP1967Proxy: caller is not the owner");
        _;
    }

    function proxyOwner() public view returns (address) {
        return _proxyOwner();
    }

    function upgradeTo(address newImplementation) public onlyProxyOwner {
        _upgradeTo(newImplementation);
        emit Upgraded(newImplementation);
    }

    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "EIP1967Proxy: new owner is zero");
        emit ProxyOwnershipTransferred(_proxyOwner(), newOwner);
        _setProxyOwner(newOwner);
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data) payable public onlyProxyOwner {
        _upgradeTo(newImplementation);
        (bool success,) = newImplementation.delegatecall(data);
        require(success, "EIP1967Proxy: failed to call into the new implementation");
    }
}