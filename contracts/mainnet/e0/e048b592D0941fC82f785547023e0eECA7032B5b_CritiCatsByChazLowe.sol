//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract CritiCatsByChazLowe is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "Criti Cats by Chaz Lowe";
    string public symbol = "Criti Cats by Chaz Lowe";
    
    constructor() ERC1155("https://ipfs.io/ipfs/QmXDoTk16hhmgwH8RajeAW8NpekXEKEAMK1uB2NdKrvYAX/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://ipfs.io/ipfs/QmXDoTk16hhmgwH8RajeAW8NpekXEKEAMK1uB2NdKrvYAX/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
    }
}