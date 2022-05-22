// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./Base64.sol";

contract NFT is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;
    mapping(uint256 => string) internal cids;
    mapping(address => bool) public hasMinted;

    constructor() ERC721("BUIDLCON 2022", "BUIDL22") {}

    function mint(string memory _hash) public whenNotPaused {
        require(!hasMinted[msg.sender], "duplicated");
        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
        cids[tokenId] = _hash;
        hasMinted[msg.sender] = true;
    }

    function Pause() public onlyOwner {
        _pause();
    }

    function Unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "BUIDLCON2022",',
                        '"description": "ticket BUIDL22.",',
                        '"image": "ipfs://',
                        cids[tokenId],
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}