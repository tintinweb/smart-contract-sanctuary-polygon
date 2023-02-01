// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract DXNFT is ERC721 {
    constructor() ERC721("DXToken", "DXTK") {}
}