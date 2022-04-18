// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";

contract RedditPost is ERC721, Ownable {
	address[] private approvedSubOwners;
	mapping(address => bool) private subOwners;
	mapping (uint256 => string) private tokenURIs;
	string public baseTokenURI;

	modifier onlyOwners {
		require(subOwners[msg.sender] || msg.sender == owner(), "Only owners");
		_;
	}

	constructor() ERC721("Reddit Post", "RPOST") {}

	function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

	function setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(_exists(_tokenId), "URI set for nonexistent token");
        tokenURIs[_tokenId] = _tokenURI;
    }

	function setSubOwner(address subOwner, bool approved) external onlyOwner {
		subOwners[subOwner] = approved;
		if(approved) approvedSubOwners.push(subOwner);
	}

	function getSubOwners() external view returns (address[] memory) {
		return approvedSubOwners;
	}

	function isSubOwner(address subOwner) external view returns (bool) {
		return subOwners[subOwner];
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "URI query for nonexistent token");

        string memory _tokenURI = tokenURIs[_tokenId];

        if(bytes(baseTokenURI).length == 0) return _tokenURI;
		if(bytes(baseTokenURI).length > 0) return string(abi.encodePacked(baseTokenURI, _tokenURI));

        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function mint(address to, uint id, string memory meta) public onlyOwners {
		_mint(to, id);
		setTokenURI(id, meta);
	}
}