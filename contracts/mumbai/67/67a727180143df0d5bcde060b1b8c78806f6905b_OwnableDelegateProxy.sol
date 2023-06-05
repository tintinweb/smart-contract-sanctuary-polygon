/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract OwnedUpgradeabilityStorage {

    address internal _implementation;
    address private _upgradeabilityOwner;

    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

    function implementation() public virtual view returns (address) {
        return _implementation;
    }

    function proxyType() public virtual pure returns (uint256 proxyTypeId) {
        return 2;
    }
}


abstract contract Proxy is OwnedUpgradeabilityStorage {

    function implementation() public override view returns (address) {
        return _implementation;
    }

    function proxyType() public override pure returns (uint256 proxyTypeId) {
        return 2;
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        address _impl = implementation();
        require(_impl != address(0), "Implementation address is not valid");

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

contract OwnedUpgradeabilityProxy is Proxy {

    event ProxyOwnershipTransferred(address previousOwner, address newOwner);
    event Upgraded(address indexed implementation);

    function _upgradeTo(address implementation) internal {
        require(_implementation != implementation, "New address is the same as the current one");
        _implementation = implementation;
        emit Upgraded(implementation);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Only proxy owner can call this function");
        _;
    }

    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "New owner address is not valid");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    function upgradeTo(address implementation) public onlyProxyOwner {
        _upgradeTo(implementation);
    }

    function upgradeToAndCall(address implementation, bytes memory data) payable public onlyProxyOwner {
        upgradeTo(implementation);
        (bool success,) = address(this).delegatecall(data);
        require(success, "Delegatecall failed");
    }
}

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory data) {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success,) = initialImplementation.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}