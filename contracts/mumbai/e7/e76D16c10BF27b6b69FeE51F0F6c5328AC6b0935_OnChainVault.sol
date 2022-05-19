// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract OnChainVault {
	mapping(uint256 => mapping(string => string)) public data;

	event Store(address, uint256);

	function store(string memory _data, string memory _secret) public virtual {
		uint256 id = uint256(keccak256(abi.encodePacked(_data)));
		string memory secret = decodeSecret(_secret);
		data[id][secret] = _data;

		emit Store(msg.sender, id);
	}

	function decodeSecret(string memory secret) internal pure returns (string memory) {
		bytes32 b = keccak256(abi.encodePacked(secret));
		uint8 i = 0;
		while (i < 32 && b[i] != 0) {
			i++;
		}

		bytes memory arr = new bytes(i);
		for (i = 0; i < 32 && b[i] != 0; i++) {
			arr[i] = bytes1(uint8tohexchar(uint8(b[i])));
		}

		return string(arr);
	}

	function uint8tohexchar(uint8 i) public pure returns (uint8) {
        return (i > 9) ?
            (i + 87) : // ascii a-f
            (i + 48); // ascii 0-9
  }
}