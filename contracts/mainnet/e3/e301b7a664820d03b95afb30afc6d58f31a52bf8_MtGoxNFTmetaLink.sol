// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./MtGoxNFT.sol";
import "./MtGoxNFTmetaLinkInterface.sol";

// the MtGox NFT metalink contract only handles generation of URIs for contractURI and tokenURI.

contract MtGoxNFTmetaLink is Ownable, MtGoxNFTmetaLinkInterface {
	constructor() {
	}

	function contractURI(MtGoxInfoApi) external pure returns (string memory) {
		return "https://data.mtgoxnft.net/contract-meta.json";
	}

	function tokenURI(MtGoxInfoApi _contract, uint256 _tokenId) external view returns (string memory) {
		// string(abi.encodePacked(...)) means concat strings
		// Strings.toString() returns an int value
		// Strings.toHexString() returns a hex string starting with 0x
		// see: https://docs.opensea.io/docs/metadata-standards

		string memory tokenIdStr = Strings.toString(_tokenId);
		string memory tokenUrl = _contract.getUrl(_tokenId);
		// TODO uncomment once we have token images
		if (bytes(tokenUrl).length == 0) {
			tokenUrl = string(abi.encodePacked("https://data.mtgoxnft.net/image/v20220613/", tokenIdStr, ".svg"));
			//tokenUrl = "https://data.mtgoxnft.net/notavailableyet.svg";
		}

		string memory tokenName;
		if (_tokenId > 0xffffffff) {
			// if anonymous token, do not show the token id
			tokenName = "Anonymous MtGox NFT";
		} else {
			// show the token id (= MtGox account ID)
			tokenName = string(abi.encodePacked("MtGox NFT #", tokenIdStr));
		}

		// Note: OpenSea requires data uri to be base64 encoded

		bytes memory json = abi.encodePacked(
			// name
			"{\"name\":\"",
			tokenName,
			// external_url
			"\",\"external_url\":\"https://data.mtgoxnft.net/by-id/",
			tokenIdStr,
			// image
			"\",\"image\":\"",
			tokenUrl,
			// attributes → Registered (date)
			"\",\"attributes\":[{\"display_type\":\"date\",\"trait_type\":\"Registered\",\"value\":",
			Strings.toString(_contract.registrationDate(_tokenId)),
			// attributes → Fiat
			"},{\"trait_type\":\"Fiat\",\"value\":",
			Strings.toString(_contract.fiatWeight(_tokenId)),
			"},{\"trait_type\":\"Bitcoin\",\"value\":",
			Strings.toString(_contract.satoshiWeight(_tokenId)),
			"},{\"trait_type\":\"Trade Volume\",\"value\":",
			Strings.toString(_contract.tradeVolume(_tokenId)),
			"}]}"
		);

		// TODO keep this as data uri or just point to a static file? Seems json takes a lot of room in the contract code

		return string(abi.encodePacked(
			"data:application/json;base64,",
			Base64.encode(json)
		));
	}
}