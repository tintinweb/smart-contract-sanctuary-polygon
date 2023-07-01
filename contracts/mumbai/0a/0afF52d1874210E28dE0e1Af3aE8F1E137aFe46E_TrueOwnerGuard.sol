// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";

interface Guard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import {GuardManager, Enum} from "../base/GuardManager.sol";
import {ISignatureValidator} from "../interfaces/ISignatureValidator.sol";
import {SignatureDecoder} from "../common/SignatureDecoder.sol";

interface ISafe {
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 nonce
    ) external view returns (bytes32);

    function nonce() external view returns (uint256);

    function getThreshold() external view returns (uint256);

    function getOwners() external view returns (address[] memory);
}

/// @title TrueOwnerGetter - contract that reads the true owner
contract TrueOwnerGetter {
    /// @notice Returns the true owner of the given Safe address.
    /// @param safeAddress The address of the Safe.
    /// @return The true owner address. (Always the last in the list of owners)
    function getTrueOwner(address safeAddress) public view returns (address) {
        address[] memory owners = ISafe(safeAddress).getOwners();
        return owners[owners.length - 1]; // true owner is always the last in the list
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import {GuardManager, Guard, Enum} from "../base/GuardManager.sol";
import {ISignatureValidator} from "../interfaces/ISignatureValidator.sol";
import {SignatureDecoder} from "../common/SignatureDecoder.sol";
import {TrueOwnerGetter, ISafe} from "./TrueOwnerGetter.sol";

/// @title TrueOwnerGuard - A guard for Gnosis Safe that requires transactions to be signed by the true owner (always the last in the list).
/// @notice This contract checks if a transaction is signed by the true owner (always the last in the list) of the Safe before allowing execution.
/// @notice with this Guard enabled it is not allowed to change true owner through Safe transactions. Need a module for that
contract TrueOwnerGuard is Guard, SignatureDecoder, TrueOwnerGetter {
    // solhint-disable-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    /// @notice Checks if the given address is included in the signatures.
    /// @param txHash The transaction hash.
    /// @param signatures The signatures of the transaction.
    /// @param wantedAddress The address to be found among the signatures.
    /// @return True if the address is included in the signatures, false otherwise.
    function isAddressInSignatures(
        bytes32 txHash,
        bytes memory signatures,
        uint256 threshold,
        address wantedAddress
    ) internal pure returns (bool) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        address currentSigner;
        uint256 i;
        for (i = 0; i < threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v < 2) {
                // If v is 0 then it is a contract signature or if it is 1 then it is an approved hash
                // When handling contract signatures the address of the contract is encoded into r
                // When handling approved hashes the address of the approver is encoded into r
                currentSigner = address(uint160(uint256(r)));
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentSigner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", txHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentSigner = ecrecover(txHash, v, r, s);
            }
            if (currentSigner == wantedAddress) return true;
        }
        return false;
    }

    /// @notice Checks if the transaction is signed by the true owner before execution.
    /// @dev This function is called before the transaction is executed.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address
    ) external override {
        ISafe safe = ISafe(payable(msg.sender));

        // using "nonce - 1" because Safe already increased it before the call
        bytes32 txHash = safe.getTransactionHash(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            safe.nonce() - 1
        );

        address trueOwner = getTrueOwner(msg.sender);

        // TrueOwnerGuard: must be signed by the true owner
        require(isAddressInSignatures(txHash, signatures, safe.getThreshold(), trueOwner), "EDCC00");
    }

    /// @notice doesn't check anything. Required to support the interface.
    /// @dev check transaction after execution, is not implemented for this Guard
    function checkAfterExecution(bytes32, bool) external view override {}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}