// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import "sol.lib.memory/LibPointer.sol";
import "sol.lib.memory/LibBytes.sol";

import "./LibExtrospectBytecode.sol";
import "./IExtrospectBytecodeV1.sol";
import "./IExtrospectInterpreterV1.sol";

/// @title Extrospection
/// @notice Implements all extrospection interfaces.
contract Extrospection is IExtrospectBytecodeV1, IExtrospectInterpreterV1 {
    using LibBytes for bytes;

    /// @inheritdoc IExtrospectBytecodeV1
    function bytecode(address account_) external view returns (bytes memory) {
        return account_.code;
    }

    /// @inheritdoc IExtrospectBytecodeV1
    function bytecodeHash(address account_) external view returns (bytes32) {
        return account_.codehash;
    }

    /// @inheritdoc IExtrospectBytecodeV1
    function scanEVMOpcodesPresentInAccount(address account_) public view returns (uint256) {
        bytes memory code_ = account_.code;
        return LibExtrospectBytecode.scanEVMOpcodesPresentInMemory(code_.dataPointer(), code_.length);
    }

    /// @inheritdoc IExtrospectInterpreterV1
    function scanOnlyAllowedInterpreterEVMOpcodes(address interpreter_) external view returns (bool) {
        return scanEVMOpcodesPresentInAccount(interpreter_) & INTERPRETER_DISALLOWED_OPS == 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// A pointer to a location in memory. This is a `uint256` to save gas on low
/// level operations on the evm stack. These same low level operations typically
/// WILL NOT check for overflow or underflow, so all pointer logic MUST ensure
/// that reads, writes and movements are not out of bounds.
type Pointer is uint256;

/// @title LibPointer
/// Ergonomic wrappers around common pointer movements, reading and writing. As
/// wrappers on such low level operations often introduce too much jump gas
/// overhead, these functions MAY find themselves used in reference
/// implementations that more optimised code can be fuzzed against. MAY also be
/// situationally useful on cooler performance paths.
library LibPointer {
    /// Cast a `Pointer` to `bytes` without modification or any safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `bytes`.
    /// @param pointer The pointer to cast to `bytes`.
    /// @return data The cast `bytes`.
    function unsafeAsBytes(Pointer pointer) internal pure returns (bytes memory data) {
        assembly ("memory-safe") {
            data := pointer
        }
    }

    /// Increase some pointer by a number of bytes.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// Note that moving a pointer by some bytes offset is likely to unalign it
    /// with the 32 byte increments of the Solidity allocator.
    ///
    /// @param pointer The pointer to increase by `length`.
    /// @param length The number of bytes to increase the pointer by.
    /// @return The increased pointer.
    function unsafeAddBytes(Pointer pointer, uint256 length) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, length)
        }
        return pointer;
    }

    /// Increase some pointer by a single 32 byte word.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to increase by a single word.
    /// @return The increased pointer.
    function unsafeAddWord(Pointer pointer) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, 0x20)
        }
        return pointer;
    }

    /// Increase some pointer by multiple 32 byte words.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to increase.
    /// @param words The number of words to increase the pointer by.
    /// @return The increased pointer.
    function unsafeAddWords(Pointer pointer, uint256 words) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, mul(0x20, words))
        }
        return pointer;
    }

    /// Decrease some pointer by a single 32 byte word.
    ///
    /// This is UNSAFE because it can silently underflow or point below some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to decrease by a single word.
    /// @return The decreased pointer.
    function unsafeSubWord(Pointer pointer) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := sub(pointer, 0x20)
        }
        return pointer;
    }

    /// Decrease some pointer by multiple 32 byte words.
    ///
    /// This is UNSAFE because it can silently underflow or point below some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to decrease.
    /// @param words The number of words to decrease the pointer by.
    /// @return The decreased pointer.
    function unsafeSubWords(Pointer pointer, uint256 words) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := sub(pointer, mul(0x20, words))
        }
        return pointer;
    }

    /// Read the word at the pointer.
    ///
    /// This is UNSAFE because it can read outside any particular data stucture
    /// or even beyond allocated memory. The caller MUST ensure that this is a
    /// safe operation.
    ///
    /// @param pointer Pointer to read the word at.
    /// @return word The word read from the pointer.
    function unsafeReadWord(Pointer pointer) internal pure returns (uint256 word) {
        assembly ("memory-safe") {
            word := mload(pointer)
        }
    }

    /// Write a word at the pointer.
    ///
    /// This is UNSAFE because it can write outside any particular data stucture
    /// or even beyond allocated memory. The caller MUST ensure that this is a
    /// safe operation.
    ///
    /// @param pointer Pointer to write the word at.
    /// @param word The word to write.
    function unsafeWriteWord(Pointer pointer, uint256 word) internal pure {
        assembly ("memory-safe") {
            mstore(pointer, word)
        }
    }

    /// Get the pointer to the end of all allocated memory.
    /// As per Solidity docs, there is no guarantee that the region of memory
    /// beyond this pointer is zeroed out, as assembly MAY write beyond allocated
    /// memory for temporary use if the scratch space is insufficient.
    /// @return pointer The pointer to the end of all allocated memory.
    function allocatedMemoryPointer() internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := mload(0x40)
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibPointer.sol";

/// Thrown when asked to truncate data to a longer length.
/// @param length Actual bytes length.
/// @param truncate Attempted truncation length.
error TruncateError(uint256 length, uint256 truncate);

/// @title LibBytes
/// @notice Tools for working directly with memory in a Solidity compatible way.
library LibBytes {
    /// Truncates bytes of data by mutating its length directly.
    /// Any excess bytes are leaked
    function truncate(bytes memory data, uint256 length) internal pure {
        if (data.length < length) {
            revert TruncateError(data.length, length);
        }
        assembly ("memory-safe") {
            mstore(data, length)
        }
    }

    /// Pointer to the data of a bytes array NOT the length prefix.
    /// @param data Bytes to get the data pointer for.
    /// @return pointer Pointer to the data of the bytes in memory.
    function dataPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, 0x20)
        }
    }

    /// Pointer to the start of a bytes array (the length prefix).
    /// @param data Bytes to get the pointer to.
    /// @return pointer Pointer to the start of the bytes data structure.
    function startPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := data
        }
    }

    /// Pointer to the end of some bytes.
    ///
    /// Note that this pointer MAY NOT BE ALIGNED, i.e. it MAY NOT point to the
    /// start of a multiple of 32, UNLIKE the free memory pointer at 0x40.
    ///
    /// @param data Bytes to get the pointer to the end of.
    /// @return pointer Pointer to the end of the bytes data structure.
    function endDataPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, add(0x20, mload(data)))
        }
    }

    /// Pointer to the end of the memory allocated for bytes.
    ///
    /// The allocator is ALWAYS aligned to whole words, i.e. 32 byte multiples,
    /// for data structures allocated by Solidity. This includes `bytes` which
    /// means that any time the length of some `bytes` is NOT a multiple of 32
    /// the alloation will point past the end of the `bytes` data.
    ///
    /// There is no guarantee that the memory region between `endDataPointer`
    /// and `endAllocatedPointer` is zeroed out. It is best to think of that
    /// space as leaked garbage.
    ///
    /// Almost always, e.g. for the purpose of copying data between regions, you
    /// will want `endDataPointer` rather than this function.
    /// @param data Bytes to get the end of the allocated data region for.
    /// @return pointer Pointer to the end of the allocated data region.
    function endAllocatedPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, and(add(add(mload(data), 0x20), 0x1f), not(0x1f)))
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "sol.lib.memory/LibPointer.sol";

/// @title LibExtrospectBytecode
/// @notice Internal algorithms for extrospecting bytecode. Notably the EVM
/// opcode scanning needs special care, as the other bytecode functions are mere
/// wrappers around native EVM features.
library LibExtrospectBytecode {
    /// Scans opcodes present in a region of memory, as per
    /// `IExtrospectBytecodeV1.scanEVMOpcodesPresentInAccount`. The start cursor
    /// MUST point to the first byte of a region of memory that contract code has
    /// already been copied to, e.g. with `extcodecopy`.
    function scanEVMOpcodesPresentInMemory(Pointer cursor, uint256 length)
        internal
        pure
        returns (uint256 bytesPresent)
    {
        assembly ("memory-safe") {
            cursor := sub(cursor, 0x20)
            let end := add(cursor, length)
            for {} lt(cursor, end) {} {
                cursor := add(cursor, 1)

                let op := and(mload(cursor), 0xFF)
                //slither-disable-next-line incorrect-shift
                bytesPresent := or(bytesPresent, shl(op, 1))

                // The 32 `PUSH*` opcodes starting at 0x60 indicate that the
                // following bytes MUST be skipped as they are inline stack data
                // and NOT opcodes.
                let push := sub(op, 0x60)
                if lt(push, 0x20) { cursor := add(cursor, add(push, 1)) }
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title IExtrospectBytecodeV1
/// @notice External functions for offchain processing to conveniently access the
/// view on contract code that is exposed to EVM opcodes. Generally this is NOT
/// useful onchain as all contracts have access to the same opcodes, so would be
/// more gas efficient and convenient calling the opcodes internally than an
/// external call to an extrospection contract.
interface IExtrospectBytecodeV1 {
    /// Return the bytecode for an address.
    ///
    /// Equivalent to `account.code`.
    ///
    /// @param account The account to get bytecode for.
    /// @return The bytecode of `account`. Will be `0` length for non-contract
    /// accounts.
    function bytecode(address account) external view returns (bytes memory);

    /// Return the hash of the complete bytecode for an address.
    ///
    /// Equivalent to `account.codehash`.
    ///
    /// @param account The account to get the bytecode hash for.
    /// @return The hash of the bytecode of `account`. Will be `0` (NOT the hash
    /// of empty bytes) for non-contract accounts.
    function bytecodeHash(address account) external view returns (bytes32);

    /// Scan every byte of the bytecode in some account and return an encoded
    /// list of every opcode present in that account's code. The list is encoded
    /// as a single `uint256` where each bit is a flag representing the presence
    /// of an opcode in the source bytecode. The opcode byte is the literal
    /// bitwise offset in the final output, starting from least significant bits.
    ///
    /// E.g. opcode `0` sets the 0th bit, i.e. `2 ** 0`, i.e. `1`, i.e. `1 << 0`.
    /// opcode `0x50` sets the `0x50`th bit, i.e. `2 ** 0x50`, i.e. `1 << 0x50`.
    ///
    /// The final output can be bitwise `&` against a reference set of bit flags
    /// to check for the presence of a list of (un)desired opcodes in a single
    /// logical operation. This allows for fewer branching operations (expensive)
    /// per byte, but precludes the ability to break the loop early upon
    /// discovering the prescence of a specific opcode.
    ///
    /// The scan MUST respect the inline skip behaviour of the `PUSH*` family of
    /// evm opcodes, starting from opcode `0x60` through `0x7F` inclusive. These
    /// opcodes are followed by literal bytes that will be pushed to the EVM
    /// stack at runtime and so are NOT opcodes themselves. Even though each byte
    /// of the data following a `PUSH*` is assigned program counter, it DOES NOT
    /// run as an opcode. Therefore, the scanner MUST ignore all push data,
    /// otherwise it will report false positives from stack data being treated as
    /// opcodes. The relative index of each `PUSH` opcode signifies how many
    /// bytes to skip, e.g. `0x60` skips 1 byte, `0x61` skips 2 bytes, etc.
    function scanEVMOpcodesPresentInAccount(address account) external view returns (uint256 scan);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./EVMOpcodes.sol";

/// @dev https://eips.ethereum.org/EIPS/eip-214#specification
uint256 constant NON_STATIC_OPS = (1 << uint256(EVM_OP_CREATE)) | (1 << uint256(EVM_OP_CREATE2))
    | (1 << uint256(EVM_OP_LOG0)) | (1 << uint256(EVM_OP_LOG1)) | (1 << uint256(EVM_OP_LOG2)) | (1 << uint256(EVM_OP_LOG3))
    | (1 << uint256(EVM_OP_LOG4)) | (1 << uint256(EVM_OP_SSTORE)) | (1 << uint256(EVM_OP_SELFDESTRUCT))
    | (1 << uint256(EVM_OP_CALL));

/// @dev The interpreter ops allowlist is stricter than the static ops list.
uint256 constant INTERPRETER_DISALLOWED_OPS = NON_STATIC_OPS
// Interpreter cannot store so it has no reason to load from storage.
| (1 << uint256(EVM_OP_SLOAD))
// Interpreter MUST NOT delegate call as we have no idea what could run and
// it could easily mutate the interpreter if allowed.
| (1 << uint256(EVM_OP_DELEGATECALL))
// Interpreter MUST use static call only.
| (1 << uint256(EVM_OP_CALLCODE))
// Interpreter MUST use static call only.
// Redundant with static list for clarity as static list allows 0 value calls.
| (1 << uint256(EVM_OP_CALL));

/// @title IExtrospectInterpreterV1
/// @notice External functions for offchain processing to
interface IExtrospectInterpreterV1 {
    function scanOnlyAllowedInterpreterEVMOpcodes(address interpreter) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

uint8 constant EVM_OP_STOP = 0x00;

uint8 constant EVM_OP_ADD = 0x01;
uint8 constant EVM_OP_MUL = 0x02;
uint8 constant EVM_OP_SUB = 0x03;
uint8 constant EVM_OP_DIV = 0x04;
uint8 constant EVM_OP_SDIV = 0x05;
uint8 constant EVM_OP_MOD = 0x06;
uint8 constant EVM_OP_SMOD = 0x07;
uint8 constant EVM_OP_ADDMOD = 0x08;
uint8 constant EVM_OP_MULMOD = 0x09;
uint8 constant EVM_OP_EXP = 0x0A;
uint8 constant EVM_OP_SIGNEXTEND = 0x0B;

uint8 constant EVM_OP_LT = 0x10;
uint8 constant EVM_OP_GT = 0x11;
uint8 constant EVM_OP_SLT = 0x12;
uint8 constant EVM_OP_SGT = 0x13;
uint8 constant EVM_OP_EQ = 0x14;
uint8 constant EVM_OP_ISZERO = 0x15;

uint8 constant EVM_OP_AND = 0x16;
uint8 constant EVM_OP_OR = 0x17;
uint8 constant EVM_OP_XOR = 0x18;
uint8 constant EVM_OP_NOT = 0x19;
uint8 constant EVM_OP_BYTE = 0x1A;
uint8 constant EVM_OP_SHL = 0x1B;
uint8 constant EVM_OP_SHR = 0x1C;
uint8 constant EVM_OP_SAR = 0x1D;

uint8 constant EVM_OP_SHA3 = 0x20;

uint8 constant EVM_OP_ADDRESS = 0x30;
uint8 constant EVM_OP_BALANCE = 0x31;

uint8 constant EVM_OP_ORIGIN = 0x32;
uint8 constant EVM_OP_CALLER = 0x33;
uint8 constant EVM_OP_CALLVALUE = 0x34;
uint8 constant EVM_OP_CALLDATALOAD = 0x35;
uint8 constant EVM_OP_CALLDATASIZE = 0x36;
uint8 constant EVM_OP_CALLDATACOPY = 0x37;

uint8 constant EVM_OP_CODESIZE = 0x38;
uint8 constant EVM_OP_CODECOPY = 0x39;

uint8 constant EVM_OP_GASPRICE = 0x3A;

uint8 constant EVM_OP_EXTCODESIZE = 0x3B;
uint8 constant EVM_OP_EXTCODECOPY = 0x3C;

uint8 constant EVM_OP_RETURNDATASIZE = 0x3D;
uint8 constant EVM_OP_RETURNDATACOPY = 0x3E;

uint8 constant EVM_OP_EXTCODEHASH = 0x3F;
uint8 constant EVM_OP_BLOCKHASH = 0x40;

uint8 constant EVM_OP_COINBASE = 0x41;
uint8 constant EVM_OP_TIMESTAMP = 0x42;
uint8 constant EVM_OP_NUMBER = 0x43;
uint8 constant EVM_OP_DIFFICULTY = 0x44;
uint8 constant EVM_OP_GASLIMIT = 0x45;
uint8 constant EVM_OP_CHAINID = 0x46;

uint8 constant EVM_OP_SELFBALANCE = 0x47;

uint8 constant EVM_OP_BASEFEE = 0x48;

uint8 constant EVM_OP_POP = 0x50;
uint8 constant EVM_OP_MLOAD = 0x51;
uint8 constant EVM_OP_MSTORE = 0x52;
uint8 constant EVM_OP_MSTORE8 = 0x53;

uint8 constant EVM_OP_SLOAD = 0x54;
uint8 constant EVM_OP_SSTORE = 0x55;

uint8 constant EVM_OP_JUMP = 0x56;
uint8 constant EVM_OP_JUMPI = 0x57;
uint8 constant EVM_OP_PC = 0x58;
uint8 constant EVM_OP_MSIZE = 0x59;
uint8 constant EVM_OP_GAS = 0x5A;
uint8 constant EVM_OP_JUMPDEST = 0x5B;

uint8 constant EVM_OP_PUSH0 = 0x5F;
uint8 constant EVM_OP_PUSH1 = 0x60;
uint8 constant EVM_OP_PUSH2 = 0x61;
uint8 constant EVM_OP_PUSH3 = 0x62;
uint8 constant EVM_OP_PUSH4 = 0x63;
uint8 constant EVM_OP_PUSH5 = 0x64;
uint8 constant EVM_OP_PUSH6 = 0x65;
uint8 constant EVM_OP_PUSH7 = 0x66;
uint8 constant EVM_OP_PUSH8 = 0x67;
uint8 constant EVM_OP_PUSH9 = 0x68;
uint8 constant EVM_OP_PUSH10 = 0x69;
uint8 constant EVM_OP_PUSH11 = 0x6A;
uint8 constant EVM_OP_PUSH12 = 0x6B;
uint8 constant EVM_OP_PUSH13 = 0x6C;
uint8 constant EVM_OP_PUSH14 = 0x6D;
uint8 constant EVM_OP_PUSH15 = 0x6E;
uint8 constant EVM_OP_PUSH16 = 0x6F;
uint8 constant EVM_OP_PUSH17 = 0x70;
uint8 constant EVM_OP_PUSH18 = 0x71;
uint8 constant EVM_OP_PUSH19 = 0x72;
uint8 constant EVM_OP_PUSH20 = 0x73;
uint8 constant EVM_OP_PUSH21 = 0x74;
uint8 constant EVM_OP_PUSH22 = 0x75;
uint8 constant EVM_OP_PUSH23 = 0x76;
uint8 constant EVM_OP_PUSH24 = 0x77;
uint8 constant EVM_OP_PUSH25 = 0x78;
uint8 constant EVM_OP_PUSH26 = 0x79;
uint8 constant EVM_OP_PUSH27 = 0x7A;
uint8 constant EVM_OP_PUSH28 = 0x7B;
uint8 constant EVM_OP_PUSH29 = 0x7C;
uint8 constant EVM_OP_PUSH30 = 0x7D;
uint8 constant EVM_OP_PUSH31 = 0x7E;
uint8 constant EVM_OP_PUSH32 = 0x7F;

uint8 constant EVM_OP_DUP1 = 0x80;
uint8 constant EVM_OP_DUP2 = 0x81;
uint8 constant EVM_OP_DUP3 = 0x82;
uint8 constant EVM_OP_DUP4 = 0x83;
uint8 constant EVM_OP_DUP5 = 0x84;
uint8 constant EVM_OP_DUP6 = 0x85;
uint8 constant EVM_OP_DUP7 = 0x86;
uint8 constant EVM_OP_DUP8 = 0x87;
uint8 constant EVM_OP_DUP9 = 0x88;
uint8 constant EVM_OP_DUP10 = 0x89;
uint8 constant EVM_OP_DUP11 = 0x8A;
uint8 constant EVM_OP_DUP12 = 0x8B;
uint8 constant EVM_OP_DUP13 = 0x8C;
uint8 constant EVM_OP_DUP14 = 0x8D;
uint8 constant EVM_OP_DUP15 = 0x8E;
uint8 constant EVM_OP_DUP16 = 0x8F;

uint8 constant EVM_OP_SWAP1 = 0x90;
uint8 constant EVM_OP_SWAP2 = 0x91;
uint8 constant EVM_OP_SWAP3 = 0x92;
uint8 constant EVM_OP_SWAP4 = 0x93;
uint8 constant EVM_OP_SWAP5 = 0x94;
uint8 constant EVM_OP_SWAP6 = 0x95;
uint8 constant EVM_OP_SWAP7 = 0x96;
uint8 constant EVM_OP_SWAP8 = 0x97;
uint8 constant EVM_OP_SWAP9 = 0x98;
uint8 constant EVM_OP_SWAP10 = 0x99;
uint8 constant EVM_OP_SWAP11 = 0x9A;
uint8 constant EVM_OP_SWAP12 = 0x9B;
uint8 constant EVM_OP_SWAP13 = 0x9C;
uint8 constant EVM_OP_SWAP14 = 0x9D;
uint8 constant EVM_OP_SWAP15 = 0x9E;
uint8 constant EVM_OP_SWAP16 = 0x9F;

uint8 constant EVM_OP_LOG0 = 0xA0;
uint8 constant EVM_OP_LOG1 = 0xA1;
uint8 constant EVM_OP_LOG2 = 0xA2;
uint8 constant EVM_OP_LOG3 = 0xA3;
uint8 constant EVM_OP_LOG4 = 0xA4;

uint8 constant EVM_OP_CREATE = 0xF0;
uint8 constant EVM_OP_CALL = 0xF1;
uint8 constant EVM_OP_CALLCODE = 0xF2;
uint8 constant EVM_OP_RETURN = 0xF3;
uint8 constant EVM_OP_DELEGATECALL = 0xF4;
uint8 constant EVM_OP_CREATE2 = 0xF5;
uint8 constant EVM_OP_STATICCALL = 0xFA;
uint8 constant EVM_OP_REVERT = 0xFD;
uint8 constant EVM_OP_INVALID = 0xFE;
uint8 constant EVM_OP_SELFDESTRUCT = 0xFF;