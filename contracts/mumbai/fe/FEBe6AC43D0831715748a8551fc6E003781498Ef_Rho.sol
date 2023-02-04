//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract Rho is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "RHO";
    string public symbol = "RHO";
    
    event NFTBulkMint(uint256 bulk);

    constructor() ERC1155("ipfs://bafybeig2bycscmtdbvjv44slgf7fqy3rfzggis26aor3wti4fyl2lueuq4/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeig2bycscmtdbvjv44slgf7fqy3rfzggis26aor3wti4fyl2lueuq4/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts, uint256 bulk) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
        emit NFTBulkMint(bulk);
    }
}