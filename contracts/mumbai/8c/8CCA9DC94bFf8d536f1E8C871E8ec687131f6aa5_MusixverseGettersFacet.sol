// contracts/Musixverse/facets/MusixverseGettersFacet.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { MusixverseAppStorage, TrackNFT, RoyaltyInfo } from "../libraries/LibMusixverseAppStorage.sol";
import { MusixverseEternalStorage } from "../common/MusixverseEternalStorage.sol";

contract MusixverseGettersFacet is MusixverseEternalStorage {
	using Counters for Counters.Counter;

	/// @notice Return the universal name of the NFT
	function name() external view returns (string memory) {
		return s.name;
	}

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory) {
		return s.symbol;
	}

	function contractURI() external view returns (string memory) {
		return s.contractURI;
	}

	function baseURI() external view returns (string memory) {
		return s.baseURI;
	}

	function PLATFORM_FEE_PERCENTAGE() external view returns (uint8) {
		return s.PLATFORM_FEE_PERCENTAGE;
	}

	function PLATFORM_ADDRESS() external view returns (address) {
		return s.PLATFORM_ADDRESS;
	}

	function mxvLatestTokenId() external view returns (Counters.Counter memory) {
		return s.mxvLatestTokenId;
	}

	function totalTracks() external view returns (Counters.Counter memory) {
		return s.totalTracks;
	}

	function trackNFTs(uint256 tokenId) external view returns (TrackNFT memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.trackNFTs[tokenId];
	}

	function royalties(uint256 tokenId) external view returns (RoyaltyInfo[] memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.royalties[tokenId];
	}

	function getCommentOnToken(uint256 tokenId) external view virtual returns (string memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.commentWall[tokenId];
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