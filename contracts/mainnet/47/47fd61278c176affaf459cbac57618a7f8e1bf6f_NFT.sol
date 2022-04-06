// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Base64.sol";


contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function mint(address to) public onlyOwner {
        _safeMint(to, totalSupply() + 1);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "RSS3 1st Anniversary",',
                        '"description": "Good company in a journey makes the way seem shorter.",',
                        '"image": "ipfs://QmfKyMowdVGnMpbbX4G127JFofUTPpCUiCaQDn4czVbT9j"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}