//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract Mazolu is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "MAZOLU";
    string public symbol = "MAZOLU";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeiaqrxadhtgmtf72nm65p4ujh3abbgip2wp2jkzzarjtcfrieg7qby/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeiaqrxadhtgmtf72nm65p4ujh3abbgip2wp2jkzzarjtcfrieg7qby/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}