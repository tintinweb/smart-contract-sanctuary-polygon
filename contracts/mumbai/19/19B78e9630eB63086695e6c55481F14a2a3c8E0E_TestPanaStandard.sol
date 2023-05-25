pragma solidity >=0.8.17;

// SPDX-License-Identifier: MIT

import "../interfaces/IActionStandard.sol";
import "../lib/String.sol";

contract TestPanaStandard is IActionStandard {
	struct RequiredMetadata {
		string name;
		string description;
		string option;
		uint256 reducedCost;
	}

	function supportsStandard(
		bytes calldata metadata
	) external pure returns (bool) {
		RequiredMetadata memory decodedMetadata = abi.decode(
			metadata,
			(RequiredMetadata)
		);
		if (
			!String.isEmpty(decodedMetadata.name) &&
			!String.isEmpty(decodedMetadata.description) &&
			decodedMetadata.reducedCost > 0
		) {
			return true;
		} else {
			return false;
		}
	}
}

pragma solidity >=0.8.17;

// SPDX-License-Identifier: MIT

interface IActionStandard {
	function supportsStandard(bytes memory metadata) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

library String {
	function isEmpty(string memory str) internal pure returns (bool) {
		return bytes(str).length == 0;
	}

	function stringToBytes32(
		string memory source
	) internal pure returns (bytes32 result) {
		require(
			bytes(source).length <= 32,
			"String: string length must be less than 32"
		);
		assembly {
			result := mload(add(source, 32))
		}
	}
}