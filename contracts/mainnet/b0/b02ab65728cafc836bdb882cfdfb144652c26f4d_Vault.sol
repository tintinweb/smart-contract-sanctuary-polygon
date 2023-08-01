// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {AccessControlLib} from "./libraries/AccessControlLib.sol";
import {SSTORE2} from "./libraries/utils/SSTORE2.sol";
import {BinarySearch} from "./libraries/utils/BinarySearch.sol";

contract Vault {
    //-----------------------------------------------------------------------//
    // function selectors and logic addresses are stored as bytes data:      //
    // selector . address                                                    //
    // sample:                                                               //
    // 0xaaaaaaaa <- selector                                                //
    // 0xffffffffffffffffffffffffffffffffffffffff <- address                 //
    // 0xaaaaaaaaffffffffffffffffffffffffffffffffffffffff <- one element     //
    //-----------------------------------------------------------------------//

    address private immutable logicsAndSelectorsAddress;

    constructor(bytes4[] memory selectors, address[] memory logicAddresses) {
        uint256 selectorsLength = selectors.length;

        if (selectorsLength != logicAddresses.length) {
            revert Vault_InvalidConstructorData();
        }

        if (selectorsLength > 0) {
            // check that the selectors are sorted and there's no repeating
            for (uint256 i; i < selectorsLength - 1; ) {
                if (selectors[i] >= selectors[i + 1]) {
                    revert Vault_InvalidConstructorData();
                }

                unchecked {
                    ++i;
                }
            }
        }

        bytes memory logicsAndSelectors = new bytes(selectorsLength * 24);

        assembly {
            let logicAndSelectorValue
            let i  // counter
            // offset in memory to the beginning of selectors array values
            let selectorsOffset := add(selectors, 32)
            // offset in memory to beginning of logicsAddresses array values
            let logicsAddressesOffset := add(logicAddresses, 32)
            // offset in memory to beginning of logicsAndSelectorsOffset bytes
            let logicsAndSelectorsOffset := add(logicsAndSelectors, 32)

            for {

            } lt(i, selectorsLength) {
                // post actions
                i := add(i, 1)
                selectorsOffset := add(selectorsOffset, 32)
                logicsAddressesOffset := add(logicsAddressesOffset, 32)
                logicsAndSelectorsOffset := add(logicsAndSelectorsOffset, 24)
            } {
                // value creation like:
                // 0xaaaaaaaaffffffffffffffffffffffffffffffffffffffff0000000000000000
                logicAndSelectorValue := or(
                    mload(selectorsOffset),
                    shl(64, mload(logicsAddressesOffset))
                )
                // store the value in the logicsAndSelectors byte array
                mstore(logicsAndSelectorsOffset, logicAndSelectorValue)
            }
        }

        logicsAndSelectorsAddress = SSTORE2.write(logicsAndSelectors);

        // implementation lock
        AccessControlLib.setContractOwner(msg.sender);
    }

    // Function for initializing a new proxy contract.
    // Reverts if called more than one time.
    function initialize(address owner) external {
        AccessControlLib.setContractOwner(owner);
    }

    // =========================
    // Errors
    // =========================

    error Vault_FunctionDoesNotExist();
    error Vault_AlreadyInitialized();
    error Vault_InvalidConstructorData();

    // =========================
    // Main function
    // =========================

    // Find logic for function that is called and execute the
    // function if a logic is found and return any value.
    fallback() external payable virtual {
        address logic = _getAddress(msg.sig);

        if (logic == address(0)) {
            revert Vault_FunctionDoesNotExist();
        }

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)
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

    receive() external payable virtual {}

    // =======================
    // Internal functions
    // =======================

    function _getAddress(bytes4 sig) internal view returns (address logic) {
        bytes memory logicsAndSelectors = SSTORE2.read(
            logicsAndSelectorsAddress
        );

        if (logicsAndSelectors.length < 24) {
            revert Vault_FunctionDoesNotExist();
        }

        return BinarySearch.binarySearch(sig, logicsAndSelectors);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Constants} from "./Constants.sol";

library AccessControlLib {
    // =========================
    // Storage
    // =========================

    bytes32 constant ROLES_STORAGE_POSITION = keccak256("vault.roles.storage");

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct RolesStorage {
        mapping(bytes32 => RoleData) roles;
        bool initialized;
    }

    function rolesStorage() internal pure returns (RolesStorage storage s) {
        bytes32 position = ROLES_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // =========================
    // Events
    // =========================

    event OwnerAssigned(address indexed owner);

    // =========================
    // Errors
    // =========================

    error AccessControlLib_AlreadyInitialized();

    // =========================
    // Functions
    // =========================

    // Initialize contract with on _newOwner
    function setContractOwner(address _newOwner) internal {
        RolesStorage storage s = rolesStorage();

        if (s.initialized) {
            revert AccessControlLib_AlreadyInitialized();
        }
        s.initialized = true;

        s.roles[Constants.OWNER_ROLE].members[_newOwner] = true;
        emit OwnerAssigned(_newOwner);

        s.roles[Constants.OWNER_ROLE].adminRole = Constants.OWNER_ROLE;
        s.roles[Constants.ADMIN_ROLE].adminRole = Constants.OWNER_ROLE;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        RolesStorage storage s = rolesStorage();
        return s.roles[role].members[account];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return
            readBytecode(
                pointer,
                DATA_OFFSET,
                pointer.code.length - DATA_OFFSET
            );
    }

    function read(
        address pointer,
        uint256 start
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

library BinarySearch {
    function binarySearch(
        bytes4 sig,
        bytes memory logicsAndSelectors
    ) internal pure returns (address logic) {
        bytes4 bytes4Mask = bytes4(0xffffffff);
        address addressMask = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

        // binary search
        assembly {
            // while(low < high)
            for {
                let offset := add(logicsAndSelectors, 32)
                let low
                let high := div(mload(logicsAndSelectors), 24)
                let mid
                let midValue
                let midSelector
            } lt(low, high) {

            } {
                mid := shr(1, add(low, high))
                midValue := mload(add(offset, mul(mid, 24)))
                midSelector := and(midValue, bytes4Mask)

                if eq(midSelector, sig) {
                    logic := and(shr(64, midValue), addressMask)
                    break
                }

                switch lt(midSelector, sig)
                case 1 {
                    low := add(mid, 1)
                }
                default {
                    high := mid
                }
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Constants {
    bytes32 constant internal OWNER_ROLE = keccak256("DITTO_WORKFLOW_OWNER_ROLE");
    bytes32 constant internal ADMIN_ROLE = keccak256("DITTO_WORKFLOW_ADMIN_ROLE");

    address constant internal ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}