// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ownable.sol';
import './ERC721.sol';

interface ISC05B0 {
    function mint(address to) external;
}

contract SC05B0 is Ownable,ERC721,ISC05B0 {

    constructor(string memory _name, string memory _symbol ) ERC721(_name, _symbol) {

    }

    function mint(address to) external{
        _mint(to, totalSupply);
        totalSupply++;
    }
}