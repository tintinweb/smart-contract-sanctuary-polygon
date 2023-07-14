//SPDX-License-Identifier: none
pragma solidity 0.8.19;
import {IAIGC_NFT_PROXY} from "./interfaces/IAIGC_NFT_PROXY.sol";

contract AIGC_NFT_PROXY is IAIGC_NFT_PROXY {
    bytes32 internal constant _BEACON_STORAGE_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);

    struct AddressSlot {
        address value;
    }

    /// @dev returns the storage slot where the beacon address is stored
    function _getAddressSlot(
        bytes32 slot
    ) internal pure returns (AddressSlot storage r) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }
    }

    /* ------CONSTRUCTOR------ */
    
    /// @notice constructor for proxy
    /// @param _beaconAddress: address of beacon (i.e. factory address)
    /// @dev {Factory.sol} will store the implementation address,
    /// thus acting as the beacon
    constructor(address _beaconAddress) {
        _getAddressSlot(_BEACON_STORAGE_SLOT).value = _beaconAddress;
    }

    function _beacon() internal view returns (address beacon) {
        beacon = _getAddressSlot(_BEACON_STORAGE_SLOT).value;
        if (beacon == address(0)) revert BeaconNotSet();
    }

    /// @return implementation address (i.e. the account logic address)
    function _implementation() internal returns (address implementation) {
        (bool success, bytes memory data) = _beacon().call(
            abi.encodeWithSignature("implementation()")
        );
        if (!success) revert BeaconCallFailed();
        implementation = abi.decode(data, (address));
        if (implementation == address(0)) revert ImplementationNotSet();
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        _delegate(_implementation());
    }

    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

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

//SPDX-License-Identifier: none
pragma solidity 0.8.19;

interface IAIGC_NFT_PROXY {
    error BeaconNotSet();
    error ImplementationNotSet();
    error BeaconCallFailed();
}