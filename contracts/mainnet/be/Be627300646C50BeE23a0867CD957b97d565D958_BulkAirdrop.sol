/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

pragma solidity >= 0.7.0 < 0.9.0;

// SPDX-License-Identifier: MIT

//      ____       _ _______ _           
//     |  _ \     (_)__   __| |          
//     | |_) |_ __ _   | |  | |__   __ _ 
//     |  _ <| '__| |  | |  | '_ \ / _` |
//     | |_) | |  | |  | |  | | | | (_| |
//     |____/|_|  |_|  |_|  |_| |_|\__,_|
//   _____                  _         _____             
//  / ____|                | |       / ____|            
// | |     _ __ _   _ _ __ | |_ ___ | |  __ _   _ _   _ 
// | |    | '__| | | | '_ \| __/ _ \| | |_ | | | | | | |
// | |____| |  | |_| | |_) | || (_) | |__| | |_| | |_| |
//  \_____|_|   \__, | .__/ \__\___/ \_____|\__,_|\__, |
//               __/ | |                           __/ |
//              |___/|_|                          |___/     

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract BulkAirdrop {

    constructor () {}

    function airdrop_erc721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) external {

        require(_to.length == _id.length, "ERR:ML"); //ERR-> Mixmatched Lengths

        for (uint256 i = 0; i < _id.length; i++) {

            _token.safeTransferFrom(msg.sender, _to[i], _id[i]);

        }

    }

    function airdrop_erc1155(IERC1155 _token, address[] calldata _to, uint8[] calldata _id, uint16[] calldata _amounts) external {

        require(_to.length == _id.length, "ERR:ML"); //ERR-> Mixmatched Lengths
        require(_to.length == _amounts.length, "ERR:ML"); //ERR-> Mixmatched Lengths

        for (uint256 x = 0; x < _id.length; x++) {

            _token.safeTransferFrom(msg.sender, _to[x], _id[x], _amounts[x], "");

        }
        
    }



}