// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC721Mint.sol";
import "./IERC1155Mint.sol";
import "./IMintComp.sol";

contract MintComp is Ownable,IMintComp{

    IERC721Mint public erc721;
    IERC1155Mint public erc1155;

    mapping(address => mapping(uint256 => Royalty)) private _royalties;

    constructor(address erc721_, address  erc1155_, address metaTx) ERC2771Context(metaTx) {
        erc721 = IERC721Mint(erc721_);
        erc1155 = IERC1155Mint(erc1155_);
    }

    function setERC721(address token) public onlyOwner{
        erc721 = IERC721Mint(token);
    }

    function setERC1155(address token) public onlyOwner{
        erc1155 = IERC1155Mint(token);
    }

    function mintERC721(address to, string memory uri, uint256 rate) override public{
        address token;
        uint256 id;
        (token,id) = _mintERC721(to,uri);

        _addRoyalty(token, id, Royalty(msg.sender,rate));
        emit MintERC721(token, id);
    }

    function mintERC1155(address to, uint256 value, string memory uri, uint256 rate) override public{
        address token;
        uint256 id;
        (token,id) = _mintERC1155(to,value,"mint by numiscoin",uri);

        _addRoyalty(token, id, Royalty(msg.sender,rate));
        emit MintERC1155(token, id);
    }

    function getRoyalty(address token, uint256 id) override public view returns(address maker,uint256 rate){
        maker = _royalties[token][id].maker;
        rate = _royalties[token][id].rate;
    }

    function _addRoyalty(address token, uint256 id,Royalty memory royalty) internal{
        _royalties[token][id] = royalty;
    }

    function _mintERC721(address to, string memory uri) internal returns(address token,uint256 id){
        id = erc721.mint(to,uri);

        return (address(erc721),id);
    }

    function _mintERC1155(address to, uint256 value, bytes memory data, string memory uri) internal returns(address token,uint256 id){
        id = erc1155.mint(to, value, data, uri);

        return (address(erc1155), id);
    }
}