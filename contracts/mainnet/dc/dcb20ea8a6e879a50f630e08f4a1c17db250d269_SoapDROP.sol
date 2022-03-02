/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155 { 
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    }

contract SoapDROP {
    constructor (){
       
    }
    function SingleERC1155TokenMULTISEND(IERC1155 _token, address[] calldata _accountlist, uint256 _id, uint256[] calldata _amount) public {
    require(_accountlist.length == _amount.length, "Receivers and Amount different length");    
    for(uint i = 0; i < _accountlist.length; i++) {
        _token.safeTransferFrom(msg.sender, _accountlist[i], _id, _amount[i], '');

}}
 function IERC1155BatchTransfer(IERC1155 _token, address[] calldata _to, uint256[] calldata _ids, uint256[] calldata _amounts) public {
        require(_ids.length == _amounts.length, "token and Amount not matched");
        for(uint256 i = 0; i < _to.length; i++) {
            _token.safeBatchTransferFrom(msg.sender, _to[i], _ids, _amounts, '');
        }
    }
}