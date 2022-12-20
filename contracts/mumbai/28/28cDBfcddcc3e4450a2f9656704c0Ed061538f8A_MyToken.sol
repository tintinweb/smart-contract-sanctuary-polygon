// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";

contract MyToken is ERC721 {
    constructor() ERC721("MyToken", "MTK") {}
}