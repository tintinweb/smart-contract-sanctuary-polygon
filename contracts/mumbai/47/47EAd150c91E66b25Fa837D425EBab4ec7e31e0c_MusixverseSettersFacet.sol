// contracts/Musixverse/facets/MusixverseSettersFacet.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { MusixverseEternalStorage } from "../common/MusixverseEternalStorage.sol";
import { Modifiers } from "../common/Modifiers.sol";

contract MusixverseSettersFacet is MusixverseEternalStorage, Modifiers {
	function updateName(string memory newName) public onlyOwner {
		s.name = newName;
	}

	function updateSymbol(string memory newSymbol) public onlyOwner {
		s.symbol = newSymbol;
	}

	function updateContractURI(string memory newURI) public onlyOwner {
		s.contractURI = newURI;
	}

	function updateBaseURI(string memory newURI) public onlyOwner {
		s.baseURI = newURI;
	}

	function updatePlatformFeePercentage(uint8 newPlatformFeePercentage) public onlyOwner {
		s.PLATFORM_FEE_PERCENTAGE = newPlatformFeePercentage;
	}

	function updateReferralCutPercentage(uint8 newReferralCutPercentage) public onlyOwner {
		s.REFERRAL_CUT = newReferralCutPercentage;
	}
}

// contracts/Musixverse/common/MusixverseEternalStorage.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { MusixverseAppStorage } from "../libraries/LibMusixverseAppStorage.sol";

contract MusixverseEternalStorage {
	MusixverseAppStorage internal s;
}

// contracts/Musixverse/common/Modifiers.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";

contract Modifiers {
	modifier onlyOwner() {
		LibDiamond.enforceIsContractOwner();
		_;
	}

	/***********************************|
    |              Events               |
    |__________________________________*/

	event TokenCreated(address creator, uint256 trackId, uint256 tokenId, uint256 price, uint256 localTokenId);

	event TrackMinted(address creator, uint256 trackId, uint256 maxTokenId, uint256 price, string URIHash);

	event TokenPurchased(uint256 tokenId, address referrer, address previousOwner, address newOwner, uint256 price);

	event TokenPriceUpdated(address caller, uint256 tokenId, uint256 oldPrice, uint256 newPrice);

	event TokenOnSaleUpdated(address caller, uint256 tokenId, bool onSale);

	event TokenCommentUpdated(address caller, uint256 tokenId, string previousComment, string newComment);
}

// contracts/Musixverse/libraries/LibMusixverseAppStorage.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

/// @dev Note: This contract is meant to declare any storage and is append-only. DO NOT modify old variables!

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

/***********************************|
|    Variables, structs, mappings   |
|__________________________________*/

struct TrackNftCreationData {
	uint16 amount;
	uint256 price;
	string URIHash;
	string unlockableContentURIHash;
	address[] collaborators;
	uint16[] percentageContributions;
	uint16 resaleRoyaltyPercentage;
	bool onSale;
	uint256 unlockTimestamp;
}

struct TrackNFT {
	uint256 price;
	address artistAddress;
	uint16 resaleRoyaltyPercentage;
	bool onSale;
	bool soldOnce;
	uint256 unlockTimestamp;
}

struct RoyaltyInfo {
	address payable recipient;
	uint256 percentage;
}

struct MusixverseAppStorage {
	string name;
	string symbol;
	string contractURI;
	string baseURI;
	uint8 PLATFORM_FEE_PERCENTAGE;
	address payable PLATFORM_ADDRESS;
	// Cut percentage relative to PLATFORM_FEE_PERCENTAGE
	uint8 REFERRAL_CUT;
	Counters.Counter mxvLatestTokenId;
	Counters.Counter totalTracks;
	mapping(uint256 => string) mxvTokenHashes;
	mapping(uint256 => string) mxvUnlockableContentHashes;
	mapping(uint256 => string) commentWall;
	// Mapping from token ID to owner address
	mapping(uint256 => address) _owners;
	mapping(uint256 => TrackNFT) trackNFTs;
	mapping(uint256 => RoyaltyInfo[]) royalties;
}

library LibMusixverseAppStorage {
	function diamondStorage() internal pure returns (MusixverseAppStorage storage ds) {
		assembly {
			ds.slot := 0
		}
	}

	function abs(int256 x) internal pure returns (uint256) {
		return uint256(x >= 0 ? x : -x);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// contracts/shared/libraries/LibDiamond.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamond standard.

library LibDiamond {
	bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("musixverse.diamond.storage");

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

	event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

	// Internal function version of diamondCut
	function diamondCut(
		IDiamondCut.FacetCut[] memory _diamondCut,
		address _init,
		bytes memory _calldata
	) internal {
		for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
			IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
			if (action == IDiamondCut.FacetCutAction.Add) {
				addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
			} else if (action == IDiamondCut.FacetCutAction.Replace) {
				replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
			} else if (action == IDiamondCut.FacetCutAction.Remove) {
				removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
			} else {
				revert("LibDiamondCut: Incorrect FacetCutAction");
			}
		}
		emit DiamondCut(_diamondCut, _init, _calldata);
		initializeDiamondCut(_init, _calldata);
	}

	function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
		require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
		DiamondStorage storage ds = diamondStorage();
		require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
		uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
		// add new facet address if it does not exist
		if (selectorPosition == 0) {
			addFacet(ds, _facetAddress);
		}
		for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
			require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
			addFunction(ds, selector, selectorPosition, _facetAddress);
			selectorPosition++;
		}
	}

	function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
		require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
		DiamondStorage storage ds = diamondStorage();
		require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
		uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
		// add new facet address if it does not exist
		if (selectorPosition == 0) {
			addFacet(ds, _facetAddress);
		}
		for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
			require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
			removeFunction(ds, oldFacetAddress, selector);
			addFunction(ds, selector, selectorPosition, _facetAddress);
			selectorPosition++;
		}
	}

	function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
		require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
		DiamondStorage storage ds = diamondStorage();
		// if function does not exist then do nothing and return
		require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
		for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
			removeFunction(ds, oldFacetAddress, selector);
		}
	}

	function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
		enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
		ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
		ds.facetAddresses.push(_facetAddress);
	}

	function addFunction(
		DiamondStorage storage ds,
		bytes4 _selector,
		uint96 _selectorPosition,
		address _facetAddress
	) internal {
		ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
		ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
		ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
	}

	function removeFunction(
		DiamondStorage storage ds,
		address _facetAddress,
		bytes4 _selector
	) internal {
		require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
		// an immutable function is a function defined directly in a diamond
		require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
		// replace selector with last selector, then delete last selector
		uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
		uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
		// if not the same then replace _selector with lastSelector
		if (selectorPosition != lastSelectorPosition) {
			bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
			ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
			ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
		}
		// delete the last selector
		ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
		delete ds.selectorToFacetAndPosition[_selector];

		// if no more selectors for facet address then delete the facet address
		if (lastSelectorPosition == 0) {
			// replace facet address with last facet address and delete last facet address
			uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
			uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
			if (facetAddressPosition != lastFacetAddressPosition) {
				address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
				ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
				ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
			}
			ds.facetAddresses.pop();
			delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
		}
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

// contracts/shared/interfaces/IDiamondCut.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

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