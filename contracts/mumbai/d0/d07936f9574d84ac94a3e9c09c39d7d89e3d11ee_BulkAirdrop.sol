/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}


contract BulkAirdrop{
constructor(){}


function bulkAirdropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) public{
 require(_to.length == _id.length, "Receivers and IDs are different length");
   for(uint256 i=0; i <= _to.length; i++){
       _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
   }
}
function bulkAirdropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount) public{
 require(_to.length == _id.length, "Receivers and IDs are different length");
   for(uint256 i=0; i <= _to.length; i++){
       _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i],"");
   }

}

}