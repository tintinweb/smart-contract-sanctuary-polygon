//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/LibDiamond.sol";
import "./interfaces/IDiamondCutter.sol";

contract DiamondProxy {

    constructor(address _diamondCutterFacet) {
        LibDiamond.setContractOwner(msg.sender);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCutter.FacetCut[] memory cut = new IDiamondCutter.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCutter.diamondCut.selector;

        cut[0] = IDiamondCutter.FacetCut({
            facetAddress : _diamondCutterFacet,
            action : IDiamondCutter.FacetCutAction.Add,
            functionSelectors : functionSelectors
        });

        LibDiamond.diamondCut(cut);
    }



    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // get facet from function selector
        address facet = ds.facets[msg.sig].facetAddress;
        require(facet != address(0), "Signature can't be Zero");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
        // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
        // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
        // get any return value
            returndatacopy(0, 0, returndatasize())
        // return any return value or error back to the caller
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*************************************************************\
Forked from https://github.com/mudgen/diamond
/*************************************************************/

import "../interfaces/IDiamondCutter.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("xyz.swidge.diamond.storage");

    struct Facet {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => Facet) facets;
        bytes4[] selectors;
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

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCutter.FacetCut[] memory _diamondCut
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCutter.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCutter.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCutter.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCutter.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamond: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut);
    }

    event DiamondCut(IDiamondCutter.FacetCut[] _diamondCut);

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamond: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamond: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facets[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamond: Can't add function that already exists");
            ds.facets[selector] = Facet(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamond: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamond: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facets[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamond: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamond: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamond: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facets[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamond: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            Facet memory oldFacet = ds.facets[selector];
            require(oldFacet.facetAddress != address(0), "LibDiamond: Can't remove function that doesn't exist");
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacet.facetAddress != address(this), "LibDiamond: Can't remove immutable function.");
            // replace selector with last selector
            selectorCount--;
            if (oldFacet.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacet.selectorPosition] = lastSelector;
                ds.facets[lastSelector].selectorPosition = oldFacet.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facets[selector];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*************************************************************\
Forked from https://github.com/mudgen/diamond
/*************************************************************/

interface IDiamondCutter {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        FacetCutAction action;
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    function diamondCut(FacetCut[] calldata _diamondCut) external;
}