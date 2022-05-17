//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";


contract NftyYachtClub is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "NFTy Yacht Club";
    string public symbol = "NFTy Yacht Club";
    
    constructor() ERC1155("ipfs://QmR8F1TWrmSbcpCE2FKaBnFepdA6NuhZPSAhBgBoGzgLyx/{id}.json") {
        
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://QmR8F1TWrmSbcpCE2FKaBnFepdA6NuhZPSAhBgBoGzgLyx/", Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        _mintBatch(msg.sender, _ids, _amounts, "");
    }
}