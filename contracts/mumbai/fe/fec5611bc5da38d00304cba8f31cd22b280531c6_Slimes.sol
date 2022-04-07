// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Slimes is ERC721, Ownable {
	using Counters for Counters.Counter;

	Counters.Counter private _tokenIdCounter;

	constructor() ERC721("Slimes", "SLM") {}

	function toString(uint256 value, uint256 length) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
		// heavily altered for fixed digits

		bytes memory buffer = new bytes(length);
		while (length > 0) {
			length -= 1;
			buffer[length] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}

		return string(buffer);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

		// url: ipfs://xxx/000/11/22.json

		string memory baseURI = "ipfs://QmfPW4w9dts4Wc2Q2y2Zu8fQ6S3cy4ztt7B9WiXgpxfepD/";

		uint256 p1 = _tokenId / 10000;
		uint256 p2 = (_tokenId / 100) % 100;
		uint256 p3 = _tokenId % 100;

		return string(abi.encodePacked(baseURI, toString(p1, 3), "/", toString(p2, 2), "/", toString(p3, 2), ".json"));
	}

	function safeMint(address to) public onlyOwner {
		uint256 tokenId = _tokenIdCounter.current();
		require(tokenId <= 492748, "Slimes: out of mintable slimes");
		_tokenIdCounter.increment();
		_safeMint(to, tokenId);
	}
}