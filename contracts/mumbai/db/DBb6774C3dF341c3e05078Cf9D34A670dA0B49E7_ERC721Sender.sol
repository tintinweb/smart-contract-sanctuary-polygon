//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC721{
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract ERC721Sender{
    function sendERC721(IERC721 _contract, address[] memory recipients, uint256[] memory _tokenIds ) external {
        for(uint i=0; i<recipients.length; i++){
            _contract.transferFrom(msg.sender, recipients[i], _tokenIds[i]);
        }
    }
}