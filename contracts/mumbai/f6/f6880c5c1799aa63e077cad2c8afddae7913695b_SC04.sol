// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ownable.sol';
import './ERC721.sol';



contract SC04 is Ownable,ERC721 {

    constructor(string memory _name, string memory _symbol, address _deployer) ERC721(_name, _symbol, _deployer) {

    }
}