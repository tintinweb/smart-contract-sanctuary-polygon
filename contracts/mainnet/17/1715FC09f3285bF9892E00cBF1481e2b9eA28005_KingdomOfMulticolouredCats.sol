//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract KingdomOfMulticolouredCats is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "Kingdom of Multicoloured Cats";
    string public symbol = "Kingdom of Multicoloured Cats";
    
    constructor() ERC1155("ipfs://QmfRg7tPbV3o8Byo5gSWiKhfQhefhGo5KeFH6zgHmkyDJU/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://QmfRg7tPbV3o8Byo5gSWiKhfQhefhGo5KeFH6zgHmkyDJU/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
    }
}