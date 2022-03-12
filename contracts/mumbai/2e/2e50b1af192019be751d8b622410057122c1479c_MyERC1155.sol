// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ERC1155PresetMinterPauser.sol";
import "./Strings.sol";

contract MyERC1155 is ERC1155PresetMinterPauser {
    using Strings for uint256;

    string baseURI;

    constructor(string memory _baseURI) ERC1155PresetMinterPauser(_baseURI) {
        baseURI = _baseURI;
    }


    function uri(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

}