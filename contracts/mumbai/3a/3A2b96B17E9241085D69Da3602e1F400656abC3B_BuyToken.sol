/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract BuyToken {
    address payable oscowner;

    IERC721 public nft;

    event Transaction(address user, uint256 tokenId, uint256 value);

    constructor(address payable _oscowner, address _nftaddress) {
        nft = IERC721(_nftaddress);
        oscowner = _oscowner;
    }

    function buy_token(uint256 tokenId) public payable {
        require(msg.value > 0, "value error");
        require(address(this) == nft.ownerOf(tokenId), "Owner error");
        oscowner.transfer(msg.value);
        nft.transferFrom(address(this), msg.sender, tokenId);
        emit Transaction(msg.sender, tokenId, msg.value);
    }
}