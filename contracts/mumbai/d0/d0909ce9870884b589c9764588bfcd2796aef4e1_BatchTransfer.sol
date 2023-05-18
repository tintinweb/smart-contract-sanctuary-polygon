/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

pragma solidity 0.8.0;

interface ERC721Partial {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BatchTransfer {

    function batchTransferToOne(
        ERC721Partial tokenContract,
        address recipient,
        uint256[] memory tokenIds
    ) external {
        uint256 length = tokenIds.length;
        for (uint256 index; index < length; ++index) {
            tokenContract.safeTransferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }
}