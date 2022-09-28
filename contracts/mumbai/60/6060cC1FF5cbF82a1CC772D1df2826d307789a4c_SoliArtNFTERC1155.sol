// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./Ownable.sol";

contract SoliArtNFTERC1155 is ERC1155
{
    uint256 tokenCount;
    constructor(string memory uri_) ERC1155 (uri_)
    {}

    function mint (uint256 amount) public
    {
        tokenCount++;
        _mint(_msgSender(),tokenCount,amount , "");

    }

    function mintBatch (uint256 [] memory ids , uint256 [] memory amount , bytes memory data)public
    {
        _mintBatch(_msgSender(),ids,amount,data);
    }

}