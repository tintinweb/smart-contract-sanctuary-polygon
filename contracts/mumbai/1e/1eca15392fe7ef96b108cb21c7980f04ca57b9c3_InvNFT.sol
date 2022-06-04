/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.14;


contract InvNFT {

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    string public name = "Inv OZ NFT";
    string public symbol = "INV-OZ-NFT";

    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private tokenApprovals;


    function _exists(uint tokenId) internal view  returns(bool) {
        return owners[tokenId] != address(0);
    }

    function _isOwnedOrApproved(address spender, uint256 tokenId) internal view  returns(bool) {
        require(_exists(tokenId), "non-existent token");
        address owner = owners[tokenId];
        return (owner == spender || getApproved(tokenId) == spender);
    }

    function _beforeTransfer(address from, address to, uint256 tokenId) internal view returns(bool) {
        require(from != address(0), "ERC721: From Address should not be Zero");
        require(to != address(0), "ERC721: To Address should not be Zero");
        require(_exists(tokenId), "ERC721: Call for non existent token");
        require(owners[tokenId] == from, "ERC721: Owner is incorrect");

        return true;
    }

    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns(address) {
        return owners[tokenId];
    }

    function _approve(address to, uint256 tokenId) internal  {
        tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function transfer(address to, uint tokenId) public  {
        require(_isOwnedOrApproved(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        address from = msg.sender;
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint tokenId) internal  {

        require(from != address(0), "ERC721: From Address should not be Zero");
        require(to != address(0), "ERC721: To Address should not be Zero");
        _approve(address(0), tokenId);

        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
        msg.sender == owner,
        "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) internal view returns(address) {
        require(_exists(tokenId), "ERC721: Call for non existent token");
        return tokenApprovals[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isOwnedOrApproved(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function mint(address to, uint256 tokenId) public  {
        require(to != address(0), "ERC721: Address belongs to zero");
        require(!_exists(tokenId), "Token Already Exists");

        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

    }

    function burn(address from, uint256 tokenId) public  {
        require(from != address(0), "ERC721: Addres belongs to zero");
        require(_exists(tokenId), "ERC721: burn call belongs to non-existing token");

        balances[from] -= 1;
        owners[tokenId] = address(0);

        emit Transfer(from, address(0), tokenId);
    }

}