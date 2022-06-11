// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./base64.sol";

contract HockTest is ERC721URIStorage, Ownable {
    uint256 public maxSupply=108;
    uint256 public totalSupply;

    mapping(uint256=>string) private images;

    constructor() ERC721("HockTest", "HTT") {
        totalSupply=0;
    }

    function safeMint(address to, string memory svg) public onlyOwner{
        require(totalSupply<maxSupply, "You can't mint any more");
        totalSupply++;
        images[totalSupply]=string(abi.encodePacked(images[totalSupply], svg));
        _safeMint(to, totalSupply);
    }

    function resetImages(uint256 tokenId, string memory svg) public onlyOwner{
        images[tokenId]=string(abi.encodePacked(images[tokenId], svg));
    }

    function svgToImageURI(string memory svg) internal pure returns (string memory){
        string memory baseURL="data:image/svg+xml;base64,";
        string memory svgBase64Encoded=Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function formatTokenURI(string memory imageURI, uint256 tokenId) internal pure returns (string memory){
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(abi.encodePacked(
                    '{"name":"#',Strings.toString(tokenId),'", "description": "HockTest", "image":"',imageURI,'"}'                            
                )
            ))
        ));
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory output) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory img=images[tokenId];
        string memory imageURI=svgToImageURI(img);
        return formatTokenURI(imageURI, tokenId);
    }
}