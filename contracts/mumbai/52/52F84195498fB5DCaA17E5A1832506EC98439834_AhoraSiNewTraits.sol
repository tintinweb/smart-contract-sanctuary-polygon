//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract AhoraSiNewTraits is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "Ahora si new traits";
    string public symbol = "Ahora si new traits";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeigz7f5c4lfhnvs75ydqifgym3daaiahoebh4afaxxvelqx6owk4ku/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeigz7f5c4lfhnvs75ydqifgym3daaiahoebh4afaxxvelqx6owk4ku/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}