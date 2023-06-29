// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

/// @title IDAO
/// @author Aragon Association - 2022-2023
/// @notice The interface required for DAOs within the Aragon App DAO framework.
interface IDAO {
    /// @notice The action struct to be consumed by the DAO's `execute` function resulting in an external call.
    /// @param to The address to call.
    /// @param value The native token value to be sent with the call.
    /// @param data The bytes-encoded function selector and calldata for the call.
    struct Action {
        address to;
        uint256 value;
        bytes data;
    }

    /// @notice Checks if an address has permission on a contract via a permission identifier and considers if `ANY_ADDRESS` was used in the granting process.
    /// @param _where The address of the contract.
    /// @param _who The address of a EOA or contract to give the permissions.
    /// @param _permissionId The permission identifier.
    /// @param _data The optional data passed to the `PermissionCondition` registered.
    /// @return Returns true if the address has permission, false if not.
    function hasPermission(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) external view returns (bool);

    /// @notice Updates the DAO metadata (e.g., an IPFS hash).
    /// @param _metadata The IPFS hash of the new metadata object.
    function setMetadata(bytes calldata _metadata) external;

    /// @notice Emitted when the DAO metadata is updated.
    /// @param metadata The IPFS hash of the new metadata object.
    event MetadataSet(bytes metadata);

    /// @notice Executes a list of actions. If a zero allow-failure map is provided, a failing action reverts the entire excution. If a non-zero allow-failure map is provided, allowed actions can fail without the entire call being reverted.
    /// @param _callId The ID of the call. The definition of the value of `callId` is up to the calling contract and can be used, e.g., as a nonce.
    /// @param _actions The array of actions.
    /// @param _allowFailureMap A bitmap allowing execution to succeed, even if individual actions might revert. If the bit at index `i` is 1, the execution succeeds even if the `i`th action reverts. A failure map value of 0 requires every action to not revert.
    /// @return The array of results obtained from the executed actions in `bytes`.
    /// @return The resulting failure map containing the actions have actually failed.
    function execute(
        bytes32 _callId,
        Action[] memory _actions,
        uint256 _allowFailureMap
    ) external returns (bytes[] memory, uint256);

    /// @notice Emitted when a proposal is executed.
    /// @param actor The address of the caller.
    /// @param callId The ID of the call.
    /// @param actions The array of actions executed.
    /// @param failureMap The failure map encoding which actions have failed.
    /// @param execResults The array with the results of the executed actions.
    /// @dev The value of `callId` is defined by the component/contract calling the execute function. A `Plugin` implementation can use it, for example, as a nonce.
    event Executed(
        address indexed actor,
        bytes32 callId,
        Action[] actions,
        uint256 failureMap,
        bytes[] execResults
    );

    /// @notice Emitted when a standard callback is registered.
    /// @param interfaceId The ID of the interface.
    /// @param callbackSelector The selector of the callback function.
    /// @param magicNumber The magic number to be registered for the callback function selector.
    event StandardCallbackRegistered(
        bytes4 interfaceId,
        bytes4 callbackSelector,
        bytes4 magicNumber
    );

    /// @notice Deposits (native) tokens to the DAO contract with a reference string.
    /// @param _token The address of the token or address(0) in case of the native token.
    /// @param _amount The amount of tokens to deposit.
    /// @param _reference The reference describing the deposit reason.
    function deposit(address _token, uint256 _amount, string calldata _reference) external payable;

    /// @notice Emitted when a token deposit has been made to the DAO.
    /// @param sender The address of the sender.
    /// @param token The address of the deposited token.
    /// @param amount The amount of tokens deposited.
    /// @param _reference The reference describing the deposit reason.
    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        string _reference
    );

    /// @notice Emitted when a native token deposit has been made to the DAO.
    /// @dev This event is intended to be emitted in the `receive` function and is therefore bound by the gas limitations for `send`/`transfer` calls introduced by [ERC-2929](https://eips.ethereum.org/EIPS/eip-2929).
    /// @param sender The address of the sender.
    /// @param amount The amount of native tokens deposited.
    event NativeTokenDeposited(address sender, uint256 amount);

    /// @notice Setter for the trusted forwarder verifying the meta transaction.
    /// @param _trustedForwarder The trusted forwarder address.
    function setTrustedForwarder(address _trustedForwarder) external;

    /// @notice Getter for the trusted forwarder verifying the meta transaction.
    /// @return The trusted forwarder address.
    function getTrustedForwarder() external view returns (address);

    /// @notice Emitted when a new TrustedForwarder is set on the DAO.
    /// @param forwarder the new forwarder address.
    event TrustedForwarderSet(address forwarder);

    /// @notice Setter for the [ERC-1271](https://eips.ethereum.org/EIPS/eip-1271) signature validator contract.
    /// @param _signatureValidator The address of the signature validator.
    function setSignatureValidator(address _signatureValidator) external;

    /// @notice Emitted when the signature validator address is updated.
    /// @param signatureValidator The address of the signature validator.
    event SignatureValidatorSet(address signatureValidator);

    /// @notice Checks whether a signature is valid for the provided hash by forwarding the call to the set [ERC-1271](https://eips.ethereum.org/EIPS/eip-1271) signature validator contract.
    /// @param _hash The hash of the data to be signed.
    /// @param _signature The signature byte array associated with `_hash`.
    /// @return Returns the `bytes4` magic value `0x1626ba7e` if the signature is valid.
    function isValidSignature(bytes32 _hash, bytes memory _signature) external returns (bytes4);

    /// @notice Registers an ERC standard having a callback by registering its [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID and callback function signature.
    /// @param _interfaceId The ID of the interface.
    /// @param _callbackSelector The selector of the callback function.
    /// @param _magicNumber The magic number to be registered for the function signature.
    function registerStandardCallback(
        bytes4 _interfaceId,
        bytes4 _callbackSelector,
        bytes4 _magicNumber
    ) external;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/mudgen/diamond-2-hardhat/blob/main/contracts/interfaces/IDiamondCut.sol
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove, AddWithInit, RemoveWithDeinit}
    // Add=0, Replace=1, Remove=2, AddWithInit=3, RemoveWithDeinit=4

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
        bytes initCalldata;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    function diamondCut(
        FacetCut[] calldata _diamondCut
    ) external;

    event DiamondCut(FacetCut[] _diamondCut);
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

import { IDAO } from "@aragon/osx/core/dao/IDAO.sol";
import { IDAOReferenceFacet } from "./IDAOReferenceFacet.sol";
import { IFacet } from "../IFacet.sol";

import { LibDAOReferenceStorage } from "../../libraries/storage/LibDAOReferenceStorage.sol";

/**
 * @title DAOReferenceFacet
 * @author Utrecht University
 * @notice Implementation of IDAOReferenceFacet.
 */
contract DAOReferenceFacet is IDAOReferenceFacet, IFacet {
    /// @inheritdoc IDAOReferenceFacet
    function dao() external view returns (IDAO) {
        return LibDAOReferenceStorage.getStorage().dao;
    }

    /// @inheritdoc IFacet
    function init(bytes memory/* _initParams*/) public virtual override {
        __DAOReferenceFacet_init();
    }

    function __DAOReferenceFacet_init() public virtual {
        registerInterface(type(IDAOReferenceFacet).interfaceId);
    }

    /// @inheritdoc IFacet
    function deinit() public virtual override {
        unregisterInterface(type(IDAOReferenceFacet).interfaceId);
        super.deinit();
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

import { IDAO } from "@aragon/osx/core/dao/IDAO.sol";

/**
 * @title IDAOReferenceFacet
 * @author Utrecht University
 * @notice This facet keeps track of the DAO linked to the Diamond Governace instance. 
 */
interface IDAOReferenceFacet {
    /// @notice Returns the DAO contract.
    /// @return The DAO contract.
    function dao() external view returns (IDAO);
}

// SPDX-License-Identifier: MIT
/**
 * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
 * © Copyright Utrecht University (Department of Information and Computing Sciences)
 */

pragma solidity ^0.8.0;

import { LibDiamond } from  "../libraries/LibDiamond.sol";

/**
 * @title IFacet
 * @author Utrecht University
 * @notice This interface is the base of all facets.
 * @dev Alwasys inherit this interface of all facets you create and use it to (un)register interfaces.
 */
abstract contract IFacet {
    // Should be called by inheritors too, thats why public
    function init(bytes memory _initParams) public virtual {}

    function deinit() public virtual {}

    function registerInterface(bytes4 _interfaceId) internal virtual {
        LibDiamond.diamondStorage().supportedInterfaces[_interfaceId] = true;
    }

    function unregisterInterface(bytes4 _interfaceId) internal virtual {
        LibDiamond.diamondStorage().supportedInterfaces[_interfaceId] = false;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "LibDiamond: Facet method can only be called by itself");
        _;
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */
 // This contract is based on https://github.com/mudgen/diamond-2-hardhat/blob/main/contracts/libraries/LibDiamond.sol

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../additional-contracts/IDiamondCut.sol";
import { IFacet } from "../facets/IFacet.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex]
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        IDiamondCut.FacetCut memory _facetCut
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_facetCut.functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");

        if (_facetCut.action == IDiamondCut.FacetCutAction.AddWithInit || _facetCut.action == IDiamondCut.FacetCutAction.RemoveWithDeinit) {
            // Call IFacet (de)init function on diamond cut add/remove action
            (bool success, bytes memory error) = _facetCut.facetAddress.delegatecall(_facetCut.initCalldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up error
                    /// @solidity memory-safe-assembly
                    assembly {
                        let returndata_size := mload(error)
                        revert(add(32, error), returndata_size)
                    }
                } else {
                    revert InitializationFunctionReverted(_facetCut.facetAddress, _facetCut.initCalldata);
                }
            }
        }

        if (_facetCut.action == IDiamondCut.FacetCutAction.Add || _facetCut.action == IDiamondCut.FacetCutAction.AddWithInit) {
            enforceHasContractCode(_facetCut.facetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _facetCut.functionSelectors.length; ) {
                bytes4 selector = _facetCut.functionSelectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_facetCut.facetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_facetCut.action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_facetCut.facetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _facetCut.functionSelectors.length; ) {
                bytes4 selector = _facetCut.functionSelectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _facetCut.facetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_facetCut.facetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_facetCut.action == IDiamondCut.FacetCutAction.Remove || _facetCut.action == IDiamondCut.FacetCutAction.RemoveWithDeinit) {
            require(_facetCut.facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");

            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _facetCut.functionSelectors.length; ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _facetCut.functionSelectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8" 
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

import { IDAO } from "@aragon/osx/core/dao/IDAO.sol";

library LibDAOReferenceStorage {
    bytes32 constant DAOREFERENCE_STORAGE_POSITION =
        keccak256("daoreference.diamond.storage.position");

    struct Storage {
        IDAO dao;
    }

    function getStorage() internal pure returns (Storage storage ds) {
        bytes32 position = DAOREFERENCE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}