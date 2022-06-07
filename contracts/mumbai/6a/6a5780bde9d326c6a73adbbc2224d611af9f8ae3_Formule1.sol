// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

contract Formule1 is Ownable, ERC1155Supply {
    using Strings for uint256;

    string public name = "Test F1 3";

    string public symbol = "TF13";

    address public dropperAddress;

    constructor()
    ERC1155("https://server.wagmi-studio.com/metadata/test/global/")
        {
        }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }

    function drop(address targetAddress, uint256 tokenId, uint256 amount) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        _mint(targetAddress, tokenId, amount, "");
    }


    

}