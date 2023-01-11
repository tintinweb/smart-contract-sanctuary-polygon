/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Address {

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library StorageSlot {
    
    struct AddressSlot {
        address value;
    }
    
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


abstract contract ERC1967MinimalProxy {

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _fallback() internal {
        _delegate(_implementation());
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    constructor(address newImplementation) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) -1));
        _setAdmin(msg.sender);
        _upgradeTo(newImplementation);
    }

    function _implementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _upgradeTo(address newImplementation) internal {
        require(Address.isContract(newImplementation), "ERC1967Proxy: new implementation is not a contract!");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
        emit Upgraded(newImplementation);
    }

    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    function _setAdmin(address newAdmin) internal {
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    function _changeAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "ERC1967Proxy: new admin is the zero address!");
        address oldAdmin = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
    }
    
    function _checkAdmin() internal view {
        require(_getAdmin() == msg.sender, "ERC1967Proxy: caller is not the admin!");
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }
}


abstract contract ContractUpgradeableName is ERC1967MinimalProxy {
    
    constructor(address newImplementation) payable ERC1967MinimalProxy(newImplementation) { }

    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        _changeAdmin(newAdmin);
    }

    function getImplementation() external view onlyAdmin returns (address) {
        return _implementation();
    }

    function upgradeTo(address newImplementation) external onlyAdmin {
        _upgradeTo(newImplementation);
    }
}

contract ContractNameProxy3 is ContractUpgradeableName {
    bool internal initialized;
    uint public a;
    constructor(address implementation_) payable ContractUpgradeableName(implementation_) {}
}