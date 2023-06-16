// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
  // Diamond Loupe Functions
  ////////////////////////////////////////////////////////////////////
  /// These functions are expected to be called frequently by tools.
  //
  // struct Facet {
  //     address facetAddress;
  //     bytes4[] functionSelectors;
  // }

  /// @notice Gets all facets and their selectors.
  /// @return facets_ Facet
  function facets() external view override returns (Facet[] memory facets_) {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    uint256 numFacets = ds.facetAddresses.length;
    facets_ = new Facet[](numFacets);
    for (uint256 i = 0; i < numFacets; i++) {
      address facetaddress = ds.facetAddresses[i];
      facets_[i].facetAddress = facetaddress;
      facets_[i].functionSelectors = ds.facetFunctionSelectors[facetaddress].functionSelectors;
    }
  }

  /// @notice Gets all the function selectors provided by a facet.
  /// @param facet The facet address.
  /// @return facetfunctionselectors
  function facetFunctionSelectors(
    address facet
  ) external view override returns (bytes4[] memory facetfunctionselectors) {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    facetfunctionselectors = ds.facetFunctionSelectors[facet].functionSelectors;
  }

  /// @notice Get all the facet addresses used by a diamond.
  /// @return facetAddresses_
  function facetAddresses() external view override returns (address[] memory facetAddresses_) {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    facetAddresses_ = ds.facetAddresses;
  }

  /// @notice Gets the facet that supports the given selector.
  /// @dev If facet is not found return address(0).
  /// @param functionSelector The function selector.
  /// @return facetAddress_ The facet address.
  function facetAddress(
    bytes4 functionSelector
  ) external view override returns (address facetAddress_) {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    facetAddress_ = ds.selectorToFacetAndPosition[functionSelector].facetAddress;
  }

  // This implements ERC-165.
  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    return ds.supportedInterfaces[interfaceId];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

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

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param diamondcut Contains the facet addresses and function selectors
  /// @param init The address of the contract or facet to execute calldata
  /// @param data A function call, including function selector and arguments
  ///                  data is executed with delegatecall on init
  function diamondCut(FacetCut[] calldata diamondcut, address init, bytes calldata data) external;

  event DiamondCut(FacetCut[] diamondcut, address init, bytes data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
  /// These functions are expected to be called frequently
  /// by tools.

  struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
  }

  /// @notice Gets all facet addresses and their four byte function selectors.
  /// @return facets Facet
  function facets() external view returns (Facet[] memory facets);

  /// @notice Gets all the function selectors supported by a specific facet.
  /// @param facet The facet address.
  /// @return facetfunctionselectors
  function facetFunctionSelectors(
    address facet
  ) external view returns (bytes4[] memory facetfunctionselectors);

  /// @notice Get all the facet addresses used by a diamond.
  /// @return facetaddresses
  function facetAddresses() external view returns (address[] memory facetaddresses);

  /// @notice Gets the facet that supports the given selector.
  /// @dev If facet is not found return address(0).
  /// @param functionselector The function selector.
  /// @return facetaddress The facet address.
  function facetAddress(bytes4 functionselector) external view returns (address facetaddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address initializationcontractaddress, bytes data);

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
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

  function setContractOwner(address newowner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = newowner;
    emit OwnershipTransferred(previousOwner, newowner);
  }

  function contractOwner() internal view returns (address contractowner) {
    contractowner = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
  }

  event DiamondCut(IDiamondCut.FacetCut[] diamondcut, address init, bytes data);

  // Internal function version of diamondCut
  function diamondCut(
    IDiamondCut.FacetCut[] memory diamondcut,
    address init,
    bytes memory data
  ) internal {
    for (uint256 facetIndex = 0; facetIndex < diamondcut.length; facetIndex++) {
      IDiamondCut.FacetCutAction action = diamondcut[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(diamondcut[facetIndex].facetAddress, diamondcut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(
          diamondcut[facetIndex].facetAddress,
          diamondcut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(
          diamondcut[facetIndex].facetAddress,
          diamondcut[facetIndex].functionSelectors
        );
      } else {
        revert("LibDiamondCut: Incorrect FacetCutAction");
      }
    }
    emit DiamondCut(diamondcut, init, data);
    initializeDiamondCut(init, data);
  }

  function addFunctions(address facetaddress, bytes4[] memory functionselectors) internal {
    require(functionselectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(facetaddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[facetaddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, facetaddress);
    }
    for (uint256 selectorIndex = 0; selectorIndex < functionselectors.length; selectorIndex++) {
      bytes4 selector = functionselectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(
        oldFacetAddress == address(0),
        "LibDiamondCut: Can't add function that already exists"
      );
      addFunction(ds, selector, selectorPosition, facetaddress);
      selectorPosition++;
    }
  }

  function replaceFunctions(address facetaddress, bytes4[] memory functionselectors) internal {
    require(functionselectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(facetaddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[facetaddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, facetaddress);
    }
    for (uint256 selectorIndex = 0; selectorIndex < functionselectors.length; selectorIndex++) {
      bytes4 selector = functionselectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(
        oldFacetAddress != facetaddress,
        "LibDiamondCut: Can't replace function with same function"
      );
      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, facetaddress);
      selectorPosition++;
    }
  }

  function removeFunctions(address facetaddress, bytes4[] memory functionselectors) internal {
    require(functionselectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    // if function does not exist then do nothing and return
    require(facetaddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
    for (uint256 selectorIndex = 0; selectorIndex < functionselectors.length; selectorIndex++) {
      bytes4 selector = functionselectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  function addFacet(DiamondStorage storage ds, address facetaddress) internal {
    enforceHasContractCode(facetaddress, "LibDiamondCut: New facet has no code");
    ds.facetFunctionSelectors[facetaddress].facetAddressPosition = ds.facetAddresses.length;
    ds.facetAddresses.push(facetaddress);
  }

  function addFunction(
    DiamondStorage storage ds,
    bytes4 selector,
    uint96 selectorPosition,
    address facetaddress
  ) internal {
    ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
    ds.facetFunctionSelectors[facetaddress].functionSelectors.push(selector);
    ds.selectorToFacetAndPosition[selector].facetAddress = facetaddress;
  }

  function removeFunction(
    DiamondStorage storage ds,
    address facetaddress,
    bytes4 selector
  ) internal {
    require(facetaddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
    // an immutable function is a function defined directly in a diamond
    require(facetaddress != address(this), "LibDiamondCut: Can't remove immutable function");
    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds.selectorToFacetAndPosition[selector].functionSelectorPosition;
    uint256 lastSelectorPosition = ds
      .facetFunctionSelectors[facetaddress]
      .functionSelectors
      .length - 1;
    // if not the same then replace selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[facetaddress].functionSelectors[
        lastSelectorPosition
      ];
      ds.facetFunctionSelectors[facetaddress].functionSelectors[selectorPosition] = lastSelector;
      ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(
        selectorPosition
      );
    }
    // delete the last selector
    ds.facetFunctionSelectors[facetaddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds.facetFunctionSelectors[facetaddress].facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[facetaddress].facetAddressPosition;
    }
  }

  function initializeDiamondCut(address init, bytes memory data) internal {
    if (init == address(0)) {
      return;
    }
    enforceHasContractCode(init, "LibDiamondCut: init address has no code");
    (bool success, bytes memory error) = init.delegatecall(data);
    if (!success) {
      if (error.length > 0) {
        // bubble up error
        /// @solidity memory-safe-assembly
        assembly {
          let returndata_size := mload(error)
          revert(add(32, error), returndata_size)
        }
      } else {
        revert InitializationFunctionReverted(init, data);
      }
    }
  }

  function enforceHasContractCode(address contractAddr, string memory errorMessage) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(contractAddr)
    }
    require(contractSize > 0, errorMessage);
  }
}