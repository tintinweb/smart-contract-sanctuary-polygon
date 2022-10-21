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
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {StorageDominiumProxy} from "../storage/StorageDominiumProxy.sol";
import {IDiamondLoupe} from "../external/diamond/interfaces/IDiamondLoupe.sol";

/// @author Amit Molek
/// @dev This contract is designed to forward all calls to the Dominium contract.
/// Please take a look at the Dominium contract.
///
/// The fallback works in two steps:
///     1. Calls the DiamondLoupe to get the facet that implements the called function
///     2. Delegatecalls the facet
///
/// The first step is necessary because the DiamondLoupe stores the facets addresses
/// in storage.
contract DominiumProxy {
    constructor(address implementation) {
        StorageDominiumProxy.DiamondStorage storage ds = StorageDominiumProxy
            .diamondStorage();

        ds.implementation = implementation;
    }

    fallback() external payable {
        // get loupe from storage
        StorageDominiumProxy.DiamondStorage storage ds = StorageDominiumProxy
            .diamondStorage();
        // get facet from loupe
        address facet = IDiamondLoupe(ds.implementation).facetAddress(msg.sig);
        require(facet != address(0), "DominiumProxy: Function does not exist");
        // execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author Amit Molek
/// @dev Diamond compatible storage for DominiumProxy contract
library StorageDominiumProxy {
    struct DiamondStorage {
        address implementation;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.DominiumProxy");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}