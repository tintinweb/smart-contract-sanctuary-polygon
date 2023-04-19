/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract MATICReceiverERC721 {
    address private _owner;
    mapping(address => TokenInfo[]) private _tokensByContract;

    struct TokenInfo {
        uint256 id;
        bool exists;
    }

    constructor() {
        _owner = msg.sender;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        ERC721 tokenContract = ERC721(msg.sender);
        require(tokenContract.ownerOf(tokenId) == address(this), "TokenReceiver: Sender does not have approved tokens");

        // Add the received token to the contract's list of owned tokens
        _tokensByContract[address(tokenContract)][tokenId] = TokenInfo(tokenId, true);

        // Do something with the received token
        // For example, transfer the token to the contract owner
        tokenContract.transferFrom(from, msg.sender, tokenId);

        return this.onERC721Received.selector;
    }

    function withdrawERC721(address tokenContractAddress, address recipient, uint256 tokenId) public {
        require(msg.sender == _owner, "TokenReceiver: Only contract owner can withdraw tokens");
        ERC721 tokenContract = ERC721(tokenContractAddress);
        require(tokenContract.ownerOf(tokenId) == address(this), "TokenReceiver: Contract does not own specified token");

        // Remove the token info from the mapping
        delete _tokensByContract[tokenContractAddress][tokenId];

        tokenContract.transferFrom(address(this), recipient, tokenId);
    }

    function getTokensByContract(address tokenContractAddress) public view returns (uint256[] memory) {
        TokenInfo[] storage tokens = _tokensByContract[tokenContractAddress];
        uint256[] memory result = new uint256[](tokens.length);

        uint256 i = 0;
        for (uint256 j = 0; j < tokens.length; j++) {
            if (tokens[j].exists) {
                result[i] = tokens[j].id;
                i++;
            }
        }

        return result;
    }
}