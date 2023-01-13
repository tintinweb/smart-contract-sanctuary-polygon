/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
interface TokenLike {
    function transferFrom(address,address,uint) external;
}
interface ERC1155Like {
    function safeTransferFrom(address,address,uint,uint,bytes calldata) external;
}
contract AutoTranster  {

    function autotransfer(address _asset,address[] memory usr, uint256 _wad) public{
        uint n = usr.length;
        for (uint i = 0;i<n;++i) {
            TokenLike(_asset).transferFrom(msg.sender,usr[i],_wad);
        }
    }
    function autotransfers(address _asset,address[] memory usr, uint256[] memory _wad) public{
        require(usr.length == _wad.length ,"AutoTranster/Address and quantity do not match");
        uint n = usr.length;
        for (uint i = 0;i<n;++i) {
            TokenLike(_asset).transferFrom(msg.sender,usr[i],_wad[i]);
        }
    }
    function autotransferBnb(address[] memory usr) public payable{
        uint n = usr.length;
        uint256 _wad = msg.value/n;
        for (uint i = 0;i<n;++i) {
            payable(usr[i]).transfer(_wad);
        }
    }
    function autotransfersBnb(address[] memory usr, uint256[] memory _wad) public payable{
        require(usr.length == _wad.length ,"AutoTranster/Address and quantity do not match");
        uint n = usr.length;
        uint256 tatalBNB;
        for (uint i = 0;i<n;++i) {
            tatalBNB +=_wad[i];
        }
        require(msg.value == tatalBNB ,"AutoTranster/002");
        for (uint i = 0;i<n;++i) {
            payable(usr[i]).transfer(_wad[i]);
        }
    }
    function autotransferERC1155(address _asset,address[] memory usr, uint256 nftid,uint256 _wad) public{
        uint n = usr.length;
        for (uint i = 0;i<n;++i) {
            ERC1155Like(_asset).safeTransferFrom(msg.sender,usr[i],nftid,_wad,"");
        }
    }
    function autotransfersERC1155(address _asset,address[] memory usr,uint256 nftid, uint256[] memory _wad) public{
        require(usr.length == _wad.length ,"AutoTranster/Address and quantity do not match");
        uint n = usr.length;
        for (uint i = 0;i<n;++i) {
            ERC1155Like(_asset).safeTransferFrom(msg.sender,usr[i],nftid,_wad[i],"");
        }
    }
 }