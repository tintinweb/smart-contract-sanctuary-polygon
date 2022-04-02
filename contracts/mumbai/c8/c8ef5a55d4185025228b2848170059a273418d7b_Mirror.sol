/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";

error TokenNotFound();
error NotOwner();

contract Mirror {
    mapping(uint => address) private tokensMinted;

    event Mint(uint indexed token, address indexed owner);
    event Burn(uint indexed token, address indexed burner);

    constructor() {}

    function mint(uint[][] memory tokens, address[] memory owner) public {
        for (uint i = 0; i < owner.length; i++) {
            for (uint j = 0; j < tokens[i].length; j++) {
                uint tokenId = tokens[i][j];
                if (tokensMinted[tokenId] == address(0)) {
                    tokensMinted[tokenId] = owner[i];
                    emit Mint(tokenId, owner[i]);
                    // console.log("Minted %i to %s", tokenId, owner[i]);
                }
            }
        }
    }

    function burn(uint[] memory tokens) public {
        for (uint i = 0; i < tokens.length; i++) {
            uint tokenId = tokens[i];
            if (tokensMinted[tokenId] == address(0)) {
                revert TokenNotFound();
            }
            if (tokensMinted[tokenId] != msg.sender) {
                revert NotOwner();
            }
            tokensMinted[tokenId] = address(0);
            emit Burn(tokenId, msg.sender);
            // console.log("Burn %i", tokenId);
        }
    }
}