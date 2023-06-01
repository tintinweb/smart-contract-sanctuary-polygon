//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract AiSuperSaiyanSkull is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "AI Super Saiyan Skull";
    string public symbol = "AI Super Saiyan Skull";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeic5gyndpz53c2sv63csejmqpdkrpzh7eg4nqstiwbhjsby7vnqzwe/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeic5gyndpz53c2sv63csejmqpdkrpzh7eg4nqstiwbhjsby7vnqzwe/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}