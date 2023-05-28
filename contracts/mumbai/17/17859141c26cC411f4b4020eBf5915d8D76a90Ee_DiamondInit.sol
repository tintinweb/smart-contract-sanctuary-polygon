// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Diamond Cut Interface
 * @dev This interface lays out the structure for adding, replacing, or removing functions
 * in a Diamond contract architecture. It also includes the logic for executing a function
 * with delegatecall.
 */
interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice This function allows to add, replace, or remove any number of functions
     * and optionally execute a function with delegatecall.
     * @param diamondCut_ An array of FacetCut structs containing the facet addresses
     * and function selectors for the cut.
     * @param init_ The address of the contract or facet to execute calldata_.
     * @param calldata_ A bytes array containing the function call data,
     * including function selector and arguments. calldata_ is executed with delegatecall on init_.
     */
    function diamondCut(FacetCut[] calldata diamondCut_, address init_, bytes calldata calldata_) external;

    /**
     * @dev Emitted after a successful `diamondCut` operation.
     * @param diamondCut_ The array of FacetCut structs that was passed to the function.
     * @param init_ The address of the contract or facet that was executed with delegatecall.
     * @param calldata_ The function call data that was passed to the function.
     */
    event DiamondCut(FacetCut[] diamondCut_, address init_, bytes calldata_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondLoupe Interface
 * @dev IDiamondLoupe provides a standardized way to inspect a diamond contract's facets and their function selectors.
 * The naming convention is inspired by the diamond industry, where a loupe is a small magnifying glass used to inspect diamonds.
 */
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Fetches all facet addresses along with their associated function selectors.
     * @dev This function is expected to be used frequently by tools for inspecting the contract.
     * @return facets_ An array of Facet structs, each containing the facet address and its corresponding function selectors.
     */
    function facets() external view returns (Facet[] memory facets_);

    /**
     * @notice Retrieves all the function selectors supported by a specified facet.
     * @param facet_ The address of the facet to inspect.
     * @return facetFunctionSelectors_ An array of function selectors supported by the facet.
     */
    function facetFunctionSelectors(address facet_) external view returns (bytes4[] memory facetFunctionSelectors_);

    /**
     * @notice Fetches all the facet addresses utilized by the diamond contract.
     * @return facetAddresses_ An array containing all facet addresses employed by the contract.
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**
     * @notice Gets the facet that supports the provided function selector.
     * @dev If no facet is found, the function will return address(0).
     * @param functionSelector_ The function selector for which to find the supporting facet.
     * @return facetAddress_ The address of the facet that supports the provided function selector.
     */
    function facetAddress(bytes4 functionSelector_) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC165 Interface
 * @dev This interface adheres to the ERC165 standard. It is used for querying whether a contract implements an interface.
 */
interface IERC165 {
    /**
     * @notice Checks if a contract supports a specified interface.
     * @dev Interface identification aligns with the ERC165 standard. This method utilizes less than 30,000 gas.
     * @param interfaceId_ Identifier of the interface to query for.
     * @return true if the contract implements `interfaceId_` and `interfaceId_` is not 0xffffffff, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC-173 Standard for Contract Ownership
 * @dev Note that the ERC-165 identifier for this interface is 0x7f5828d0. This interface must also follow the ERC165 standard.
 */
interface IERC173 {
    /**
     * @dev Emitted when the ownership of a contract changes.
     * @param previousOwner_ The address of the previous owner.
     * @param newOwner_ The address of the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner_, address indexed newOwner_);

    /**
     * @notice Retrieves the address of the current owner.
     * @return owner_ The address of the current owner.
     */
    function owner() external view returns (address owner_);

    /**
     * @notice Sets the address of the new owner of the contract.
     * @dev Set newOwner_ to address(0) to relinquish any ownership.
     * @param newOwner_ The address of the new contract owner.
     */
    function transferOwnership(address newOwner_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

/**
 * @title LibDiamond - A library implementing the EIP-2535 Diamond Standard
 * @dev This library is responsible for managing the storage and functionality related to diamonds.
 * It provides functions for adding, updating, and removing facets and their function selectors,
 * as well as managing contract ownership and supported interfaces.
 */
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        /// Maps function selectors to the facets that execute the functions
        /// and maps the selectors to their position in the selectorSlots array
        /// func selector => (address facet, selector position)
        mapping(bytes4 => bytes32) facets;
        /// Array of slots holding function selectors, with each slot containing 8 selectors
        mapping(uint256 => bytes32) selectorSlots;
        /// The total number of function selectors in selectorSlots
        uint16 selectorCount;
        /// A mapping used to query if a contract implements an interface
        /// This is utilized for ERC-165 implementation
        mapping(bytes4 => bool) supportedInterfaces;
        /// The owner of the contract
        address contractOwner;
    }

    /**
     * @notice Retrieves the DiamondStorage struct instance that holds the
     *         storage data for the diamond contract.
     *
     * @dev This function utilizes assembly to access the storage slot where
     *      the DiamondStorage struct data is stored.
     *
     * @return ds The DiamondStorage struct instance containing the contract's storage data
     */
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Transfers ownership of the diamond contract to a new owner.
     *
     * @dev This internal function updates the contract owner in the DiamondStorage struct
     *      and emits an OwnershipTransferred event.
     *
     * @param newOwner_ The address of the new owner to whom ownership is being transferred
     *
     * Emits an {OwnershipTransferred} event.
     */
    function setContractOwner(address newOwner_) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = newOwner_;
        emit OwnershipTransferred(previousOwner, newOwner_);
    }

    /**
     * @notice Gets the current owner of the diamond contract.
     *
     * @dev This internal view function retrieves the contract owner from the DiamondStorage struct.
     *
     * @return contractOwner_ The address of the current contract owner.
     */
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /**
     * @notice Verifies that the caller of the function is the contract owner.
     *
     * @dev This internal view function checks if the sender is the contract owner stored
     *      in the DiamondStorage struct, and reverts if the condition is not met.
     *
     * Reverts with "LibDiamond: Must be contract owner" if the sender is not the contract owner.
     */
    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address init_,
        bytes _calldata
    );

    /// A constant mask used to clear the address part of a bytes32 value
    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    /// A constant mask used to clear the function selector part of a bytes32 value
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    /**
     * @notice Executes an internal diamond cut, modifying the contract's facets by adding,
     *         replacing, or removing functions, and optionally initializing a facet or contract.
     * @dev This internal version of diamondCut is almost identical to the external version,
     *      but it uses a memory array instead of a calldata array. This approach avoids copying
     *      calldata to memory, which would result in errors for two-dimensional arrays. The
     *      function iterates through the _diamondCut array, performing actions as specified
     *      and updating the contract's selector slots accordingly.
     *
     *      Note: This code is almost the same as the external diamondCut,
     *      except it is using 'Facet[] memory _diamondCut' instead of
     *      'Facet[] calldata _diamondCut'.
     *      The code is duplicated to prevent copying calldata to memory which
     *      causes an error for a two-dimensional array.
     *
     * @param diamondCut_ An array of FacetCut structs containing facet addresses, actions, and
     *                    function selectors to be added, replaced, or removed
     * @param init_ The address of the contract or facet to execute calldata_ using delegatecall
     * @param calldata_ Encoded function call, including function selector and arguments, to be
     *                  executed using delegatecall on init_
     *
     * Emits a {DiamondCut} event.
     *
     * Requirements:
     * - The `diamondCut_` array must not be empty.
     * - The `init_` address must contain contract code if it is non-zero.
     * - If an add action is performed, the function selector must not already exist.
     * - If a replace action is performed, the function selector must exist and cannot be replaced with the same function.
     * - If a remove action is performed, the function selector must exist and the `init_` address must be a zero address.
     * - The contract must have enough storage to store the new function selectors.
     */
    function diamondCut(
        IDiamondCut.FacetCut[] memory diamondCut_,
        address init_,
        bytes memory calldata_
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        /// Determine if the last selector slot is not fully occupied
        /// Efficient modulo by eight using bitwise AND
        if (selectorCount & 7 > 0) {
            /// Retrieve the last selectorSlot using bitwise shift for efficient division by 8
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        /// Iterate through the diamond cut array
        for (uint256 facetIndex; facetIndex < diamondCut_.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                diamondCut_[facetIndex].facetAddress,
                diamondCut_[facetIndex].action,
                diamondCut_[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        /// Check if the last selector slot is not fully occupied
        /// Efficient modulo by eight using bitwise AND
        if (selectorCount & 7 > 0) {
            /// Update the selector slot using bitwise shift for efficient division by 8
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(diamondCut_, init_, calldata_);
        initializeDiamondCut(init_, calldata_);
    }

    /**
     * @dev This internal function adds, replaces, or removes function selectors for facets based on the action provided.
     *      This function ensures the selectors are properly stored in the contract's storage and maintain the gas efficient design.
     *      It also checks for valid inputs, ensuring that facets and selectors conform to the requirements of each action.
     *
     * @param selectorCount_ The current count of total selectors. This value is adjusted based on the action taken.
     * @param selectorSlot_ The current selector slot. This value is adjusted based on the action taken.
     * @param newFacetAddress_ The address of the new facet to be added or replaced. It must be address(0) when removing facets.
     * @param action_ The action to execute, which can be adding, replacing, or removing a facet.
     * @param selectors_ Array of function selectors to be added, replaced, or removed in the facet.
     *
     * @return selectorCount_ The updated count of total selectors after the function execution.
     * @return selectorSlot_ The updated selector slot after the function execution.
     *
     * Requirements:
     * - The `selectors_` array must not be empty.
     * - In the case of adding a new facet, the `newFacetAddress_` must not be a zero address, and the facet must contain code.
     * - In the case of replacing a facet, the `newFacetAddress_` must not be a zero address, and the facet must contain code. The function to be replaced must exist, and cannot be the same as the replacement function.
     * - In the case of removing a facet, the `newFacetAddress_` must be a zero address. The function to be removed must exist.
     */

    function addReplaceRemoveFacetSelectors(
        uint256 selectorCount_,
        bytes32 selectorSlot_,
        address newFacetAddress_,
        IDiamondCut.FacetCutAction action_,
        bytes4[] memory selectors_
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(
            selectors_.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        if (action_ == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(
                newFacetAddress_,
                "LibDiamondCut: Add facet has no code"
            );
            for (uint256 selectorIndex; selectorIndex < selectors_.length; ) {
                bytes4 selector = selectors_[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibDiamondCut: Can't add function that already exists"
                );

                /// Adding the facet address and the selector count to the facet
                ds.facets[selector] =
                    bytes20(newFacetAddress_) |
                    bytes32(selectorCount_);

                /// Utilizing bitwise operations for efficient modulo by 8 and multiplication by 32
                uint256 selectorInSlotPosition = (selectorCount_ & 7) << 5;

                /// Clearing the selector's position in the slot and adding the selector
                selectorSlot_ =
                    (selectorSlot_ &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                /// If the slot is filled, then it is written to storage
                if (selectorInSlotPosition == 224) {
                    /// Utilizing bitwise operation for efficient division by 8
                    ds.selectorSlots[selectorCount_ >> 3] = selectorSlot_;
                    selectorSlot_ = 0;
                }

                selectorCount_++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (action_ == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                newFacetAddress_,
                "LibDiamondCut: Replace facet has no code"
            );
            for (uint256 selectorIndex; selectorIndex < selectors_.length; ) {
                bytes4 selector = selectors_[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                /// This check is relevant if immutable functions are present
                require(
                    oldFacetAddress != address(this),
                    "LibDiamondCut: Immutable functions cannot be replaced"
                );

                /// Prevents replacement of a function with an identical one
                require(
                    oldFacetAddress != newFacetAddress_,
                    "LibDiamondCut: A function cannot be replaced with the same function"
                );

                /// Ensures the function to be replaced exists
                require(
                    oldFacetAddress != address(0),
                    "LibDiamondCut: Non-existent functions cannot be replaced"
                );

                /// Substituting the old facet address with the new one
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(newFacetAddress_);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (action_ == IDiamondCut.FacetCutAction.Remove) {
            /// The address for the removed facet should be null
            require(
                newFacetAddress_ == address(0),
                "LibDiamondCut: Address for removed facet must be null address"
            );

            /// "selectorCount_ >> 3" is a computational optimization for division by 8
            uint256 selectorSlotCount = selectorCount_ >> 3;

            /// "selectorCount_ & 7" is a computational optimization for modulo by eight
            uint256 selectorInSlotIndex = selectorCount_ & 7;
            for (uint256 selectorIndex; selectorIndex < selectors_.length; ) {
                if (selectorSlot_ == 0) {
                    /// Retrieve the last selectorSlot
                    selectorSlotCount--;
                    selectorSlot_ = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                /// Adding this block helps to avoid 'Stack too deep' error
                {
                    bytes4 selector = selectors_[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];

                    /// Check if function to remove exists
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibDiamondCut: Function to remove does not exist"
                    );

                    /// Immutable functions cannot be removed
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibDiamondCut: Immutable function cannot be removed"
                    );

                    /// Retrieve the last selector
                    /// " << 5" is a computational optimization for multiplication by 32
                    lastSelector = bytes4(
                        selectorSlot_ << (selectorInSlotIndex << 5)
                    );

                    if (lastSelector != selector) {
                        /// Update the last selector's slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }

                    /// Remove the selector from the facets
                    delete ds.facets[selector];

                    uint256 oldSelectorCount = uint16(uint256(oldFacet));

                    /// "oldSelectorCount >> 3" is a computational optimization for division by 8
                    oldSelectorsSlotCount = oldSelectorCount >> 3;

                    /// "oldSelectorCount & 7" is a computational optimization for modulo by eight
                    /// " << 5" is a computational optimization for multiplication by 32
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];

                    /// Clear the selector being deleted and replace it with the last selector
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    /// Update the storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    /// Clear the selector being deleted and replace it with the last selector
                    selectorSlot_ =
                        (selectorSlot_ &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    selectorSlot_ = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            selectorCount_ = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (selectorCount_, selectorSlot_);
    }

    /**
     * @dev This internal function is used to initialize a diamond cut. It performs a delegate call to
     *      the provided address with the given calldata. This is typically used to call a function on
     *      a facet that sets initial state in the diamond storage.
     *
     * @param init_ The address of the contract to delegate call. This address should contain the logic
     *              that needs to be executed for the initialization. If it is address(0), the function
     *              returns without doing anything.
     * @param calldata_ The calldata to be passed to the delegate call. This should include the
     *                  function selector for the initialization function and any necessary parameters.
     *
     * @notice If the delegate call is not successful, the function will revert. If the call returns
     *         an error message, it will be bubbled up and reverted with. Otherwise, it will revert
     *         with the `InitializationFunctionReverted` error, which includes the `init_` address
     *         and the `calldata_`.
     *
     * Requirements:
     * - The `init_` address must contain contract code. If it is a zero address or an address without
     *   contract code, the function will revert with the "LibDiamondCut: init_ address has no code"
     *   error.
     */
    function initializeDiamondCut(
        address init_,
        bytes memory calldata_
    ) internal {
        if (init_ == address(0)) {
            return;
        }
        enforceHasContractCode(
            init_,
            "LibDiamondCut: init_ address has no code"
        );
        (bool success, bytes memory error) = init_.delegatecall(calldata_);
        if (!success) {
            if (error.length > 0) {
                /// bubble up error
                /// @solidity memory-safe-assembly
                /// Use inline assembly to load the size of the error message and revert with it.
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(init_, calldata_);
            }
        }
    }

    /**
     * @dev This internal function checks if the provided address (contract_) contains contract code.
     *      It uses low-level EVM instructions to access the contract size directly.
     *      If the contract size is 0 (meaning there's no contract code at the address), it reverts with the provided error message.
     *
     * @param contract_ The address to be checked for the presence of contract code.
     * @param errorMessage_ The error message to be reverted with if there's no contract code at the provided address.
     *
     * Requirements:
     * - The `contract_` must contain contract code. If not, it reverts with the provided `errorMessage_`.
     */
    function enforceHasContractCode(
        address contract_,
        string memory errorMessage_
    ) internal view {
        uint256 contractSize;
        /// Using EVM assembly to get the size of the code at address `contract_`
        assembly {
            contractSize := extcodesize(contract_)
        }

        /// Reverting if the contract size is zero (i.e., the address does not contain contract code)
        require(contractSize > 0, errorMessage_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {IERC165} from "../interfaces/IERC165.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init() external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}