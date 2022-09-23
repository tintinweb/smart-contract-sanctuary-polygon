// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract LedgerPayWalletProxy {

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    struct AddressSlot {
        address value;
    }

    constructor(address _entryPoint, address _owner, address _implementation, address _worldId) {

        getAddressSlot(_IMPLEMENTATION_SLOT).value = _implementation;

        (bool success,) = address(_implementation).delegatecall(abi.encodeWithSignature("initialize(address,address,address)", _entryPoint, _owner, _worldId));
        require(success, "Deployment failed");

    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    function _getImplementation() internal view returns (address) {
        return getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    fallback() external payable virtual {

        address implementation = _getImplementation();

         assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }

    }

}