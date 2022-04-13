// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "../libraries/LibDiamond.sol";
import "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ =LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import '../utils/SafeMath.sol';
import '../defines/dCutFacet.sol';
//import "hardhat/console.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.dotcyz.storage");
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct DiamondStorage {
        mapping(bytes4 => bytes32) facets;
        mapping(uint256 => bytes32) selectorSlots;
        uint16 selectorCount;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
        address contractManager;
    }
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner,_newOwner);
    }
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }
    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }
    function enforceIsContractManager() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(msg.sender!=address(0),'invalid sender');
        require(msg.sender == ds.contractOwner || msg.sender == ds.contractManager , "LibDiamond: Must be contract owner or manager");
    }
    modifier onlyOwner {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
        _;
    }
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut,address _init,bytes memory _calldata) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount % 8 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount / 8];
        }
        // loop through diamond cut
        {
            for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
                FacetInfo memory facetInfo=FacetInfo(
                  selectorCount,
                    selectorSlot,
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].action,
                    _diamondCut[facetIndex].functionSelectors
                );
                (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(facetInfo);
            }
            if (selectorCount != originalSelectorCount) {
                ds.selectorCount = uint16(selectorCount);
            }
            // If last selector slot is not full
            if (selectorCount % 8 > 0) {
                ds.selectorSlots[selectorCount / 8] = selectorSlot;
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }
    function addReplaceRemoveFacetSelectors(FacetInfo memory facetInfo) internal returns (uint256, bytes32) {
        require(facetInfo._selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (facetInfo._action == IDiamondCut.FacetCutAction.Add) {
           (facetInfo._selectorCount, facetInfo._selectorSlot) = _AddFacetSelectors(facetInfo);
        } else if (facetInfo._action == IDiamondCut.FacetCutAction.Replace) {
           (facetInfo._selectorCount, facetInfo._selectorSlot) = _ReplaceFacetSelectors(facetInfo);
        } else if (facetInfo._action == IDiamondCut.FacetCutAction.Remove) {
           (facetInfo._selectorCount, facetInfo._selectorSlot) =_RemoveFacetSelectors(facetInfo);
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (facetInfo._selectorCount, facetInfo._selectorSlot);
    }
    function _AddFacetSelectors(FacetInfo memory facetInfo) internal returns (uint256, bytes32) {
        require(facetInfo._newFacetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(facetInfo._newFacetAddress, "LibDiamondCut: Add facet has no code");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < facetInfo._selectors.length; selectorIndex++) {
            bytes4 selector = facetInfo._selectors[selectorIndex];
            bytes32 oldFacet = ds.facets[selector];
            //check if exists
            require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
            // add facet for selector
            ds.facets[selector] = bytes20(facetInfo._newFacetAddress) | bytes32(facetInfo._selectorCount);
            uint256 selectorInSlotPosition = (facetInfo._selectorCount % 8) * 32;
            // clear selector position in slot and add selector
            facetInfo._selectorSlot = (facetInfo._selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
            // if slot is full then write it to storage
            if (selectorInSlotPosition == 224) {
                ds.selectorSlots[facetInfo._selectorCount / 8] = facetInfo._selectorSlot;
                facetInfo._selectorSlot = 0;
            }
            facetInfo._selectorCount++;
        }
        return (facetInfo._selectorCount, facetInfo._selectorSlot);
    }
    function _ReplaceFacetSelectors(FacetInfo memory facetInfo) internal returns (uint256, bytes32) {
        require(facetInfo._newFacetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(facetInfo._newFacetAddress, "LibDiamondCut: Replace facet has no code");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < facetInfo._selectors.length; selectorIndex++) {
            bytes4 selector = facetInfo._selectors[selectorIndex];
            bytes32 oldFacet = ds.facets[selector];
            address oldFacetAddress = address(bytes20(oldFacet));
            // only useful if immutable functions exist
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != facetInfo._newFacetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(facetInfo._newFacetAddress);
            //update ds.selectorSlots
            uint256 selectorInSlotPosition = (facetInfo._selectorCount % 8) * 32;
            // clear selector position in slot and add selector
            facetInfo._selectorSlot = (facetInfo._selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
            // if slot is full then write it to storage
            if (selectorInSlotPosition == 224) {
                ds.selectorSlots[facetInfo._selectorCount / 8] = facetInfo._selectorSlot;
                facetInfo._selectorSlot = 0;
            }
            facetInfo._selectorCount++;
        }
        return (facetInfo._selectorCount, facetInfo._selectorSlot);
    }
    function _RemoveFacetSelectors(FacetInfo memory facetInfo) internal returns (uint256, bytes32){
        require(facetInfo._newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        uint256 selectorSlotCount = facetInfo._selectorCount / 8;
        uint256 selectorInSlotIndex = (facetInfo._selectorCount % 8) - 1;
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < facetInfo._selectors.length; selectorIndex++) {
            if (facetInfo._selectorSlot == 0) {
                // get last selectorSlot
                selectorSlotCount--;
                facetInfo._selectorSlot = ds.selectorSlots[selectorSlotCount];
                selectorInSlotIndex = 7;
            }
            bytes4 lastSelector;
            uint256 oldSelectorsSlotCount;
            uint256 oldSelectorInSlotPosition;
            // adding a block here prevents stack too deep error
            {
                bytes4 selector = facetInfo._selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                // only useful if immutable functions exist
                require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                // replace selector with last selector in ds.facets
                // gets the last selector
                lastSelector = bytes4(facetInfo._selectorSlot << (selectorInSlotIndex * 32));
                if (lastSelector != selector) {
                    // update last selector slot position info
                    ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                }
                delete ds.facets[selector];
                uint256 oldSelectorCount = uint16(uint256(oldFacet));
                oldSelectorsSlotCount = oldSelectorCount / 8;
                oldSelectorInSlotPosition = (oldSelectorCount % 8) * 32;
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
                facetInfo._selectorSlot =
                    (facetInfo._selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                    (bytes32(lastSelector) >> oldSelectorInSlotPosition);
            }
            if (selectorInSlotIndex == 0) {
                delete ds.selectorSlots[selectorSlotCount];
                facetInfo._selectorSlot = 0;
            }
            selectorInSlotIndex--;
        }
        facetInfo._selectorCount = selectorSlotCount * 8 + selectorInSlotIndex + 1;
        return (facetInfo._selectorCount, facetInfo._selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y>0,'ds-math-div-overflow');
        z = x / y;
        //require((z = x / y) * y == x, 'ds-math-div-overflow');
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "../interfaces/IDiamondCut.sol";

struct FacetInfo{
    uint256 _selectorCount;
    bytes32 _selectorSlot;
    address _newFacetAddress;
    IDiamondCut.FacetCutAction _action;
    bytes4[] _selectors;
}