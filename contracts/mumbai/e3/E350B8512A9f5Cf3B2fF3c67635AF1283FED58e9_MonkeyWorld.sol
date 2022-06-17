//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract MonkeyWorld is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "Monkey World";
    string public symbol = "Monkey World";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeigqneewsxg2cvchls4uqoowxcwz2oc3mwff5fcv5ioxayiybqoch4/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeigqneewsxg2cvchls4uqoowxcwz2oc3mwff5fcv5ioxayiybqoch4/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}