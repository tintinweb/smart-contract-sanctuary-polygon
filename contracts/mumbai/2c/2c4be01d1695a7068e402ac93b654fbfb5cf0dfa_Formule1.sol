// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";

contract Formule1 is Ownable, ERC1155{

    string public name = "Test F1 2";

    string public symbol = "TF12";

    address public dropperAddress;

    constructor()
    ERC1155()
        {
            _uri = "https://server.wagmi-studio.com/metadata/test/global/";
        }

    function drop(address targetAddress, uint256 tokenId, uint256 amount) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        _mint(targetAddress, tokenId, amount, "");
    }


    

}