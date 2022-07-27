//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract Meowandme is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "MeowAndMe";
    string public symbol = "MeowAndMe";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeie3impkbl3p55to75hxzh5cxl362hyw4jl5tdhh46x6nca63mez24/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeie3impkbl3p55to75hxzh5cxl362hyw4jl5tdhh46x6nca63mez24/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}