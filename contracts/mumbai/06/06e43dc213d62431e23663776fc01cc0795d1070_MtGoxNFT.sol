// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Strings.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./draft-ERC721Votes.sol";

// The MtGoxNFT contract is based on the ERC-721 standard with some extra features such as NFT weight

contract MtGoxNFT is ERC721, ERC721Enumerable, Ownable, EIP712, ERC721Votes {
	mapping(address => bool) _issuers;

	// meta-data stored for each NFT
	struct MetaInfo {
		uint64 fiatWeight;
		uint64 satoshiWeight;
		uint32 registrationDate;
		uint256 tradeVolume;
		string url;
	}
	mapping(uint256 => MetaInfo) private _meta;

	uint256 public totalFiatWeight;
	uint256 public totalSatoshiWeight;
	uint256 public totalTradeVolume;

	constructor() ERC721("MtGoxNFT", "MGN") EIP712("MtGoxNFT", "1") {}

	function contractURI() public pure returns (string memory) {
		return "https://data.mtgoxnft.net/contract-meta.json";
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		// string(abi.encodePacked(...)) means concat strings
		// Strings.toString() returns an int value
		// Strings.toHexString() returns a hex string starting with 0x
		// see: https://docs.opensea.io/docs/metadata-standards

		string memory tokenIdStr = Strings.toString(_tokenId);
		string memory tokenUrl = _meta[_tokenId].url;
		if (bytes(tokenUrl).length == 0) {
			tokenUrl = string(abi.encodePacked("https://data.mtgoxnft.net/by-id/", tokenIdStr, ".png"));
		}

		// TODO keep this as data uri or just point to a static file? Seems json takes a lot of room in the contract code

		return string(abi.encodePacked(
			// name
			"data:application/json,{%22name%22:%22MtGox NFT %23",
			tokenIdStr,
			// external_url
			"%22,%22external_url%22:%22https://data.mtgoxnft.net/by-id/",
			tokenIdStr,
			// image
			"%22,%22image%22:%22",
			tokenUrl,
			// attributes → Registered (date)
			"%22,%22attributes%22:[{%22display_type%22:%22date%22,%22trait_type%22:%22Registered%22,%22value%22:",
			Strings.toString(_meta[_tokenId].registrationDate),
			// attributes → Fiat
			"},{%22trait_type%22:%22Fiat%22,%22value%22:",
			Strings.toString(_meta[_tokenId].fiatWeight),
			"},{%22trait_type%22:%22Bitcoin%22,%22value%22:",
			Strings.toString(_meta[_tokenId].satoshiWeight),
			"},{%22trait_type%22:%22Trade Volume%22,%22value%22:",
			Strings.toString(_meta[_tokenId].tradeVolume),
			"}]}"
		));
	}

	// mint NFT as issuer directly (not through sign)
	function mint(uint256 tokenId, address recipient, uint64 paramFiatWeight, uint64 paramSatoshiWeight, uint32 paramRegDate, uint256 paramTradeVolume, string memory url) external onlyIssuer {
		_meta[tokenId] = MetaInfo({
			fiatWeight: paramFiatWeight,
			satoshiWeight: paramSatoshiWeight,
			registrationDate: paramRegDate,
			tradeVolume: paramTradeVolume,
			url: url
		});
		totalFiatWeight = totalFiatWeight + paramFiatWeight;
		totalSatoshiWeight = totalSatoshiWeight + paramSatoshiWeight;
		totalTradeVolume = totalTradeVolume + paramTradeVolume;

		_safeMint(recipient, tokenId); // _mint will fail if this NFT was already issued
	}

	// set url for a given token
	function setUrl(uint256 tokenId, string memory url) external onlyIssuer {
		require(_exists(tokenId), "MtGoxNFT: setUrl for nonexistent NFT");
		require(bytes(_meta[tokenId].url).length == 0, "MtGoxNFT: cannot set an URL twice");

		// should we emit an event for the updated url?

		_meta[tokenId].url = url;
	}

	function fiatWeight(uint256 tokenId) external view returns (uint64) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent NFT");

		return _meta[tokenId].fiatWeight;
	}

	function satoshiWeight(uint256 tokenId) external view returns (uint64) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent NFT");

		return _meta[tokenId].satoshiWeight;
	}

	function registrationDate(uint256 tokenId) external view returns (uint32) {
		require(_exists(tokenId), "MtGoxNFT: registration date query for nonexistent NFT");

		return _meta[tokenId].registrationDate;
	}

	function tradeVolume(uint256 tokenId) external view returns (uint256) {
		require(_exists(tokenId), "MtGoxNFT: trade volume query for nonexistent NFT");

		return _meta[tokenId].tradeVolume;
	}

	function grantIssuer(address account) external onlyOwner {
		_issuers[account] = true;
	}

	function revokeIssuer(address account) external onlyOwner {
		delete _issuers[account];
	}

	modifier onlyIssuer {
		require(_issuers[_msgSender()], "MtGoxNFT: method only available to issuers");
		_;
	}

	// The following functions are overrides required by Solidity.

	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _afterTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Votes) {
		super._afterTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}