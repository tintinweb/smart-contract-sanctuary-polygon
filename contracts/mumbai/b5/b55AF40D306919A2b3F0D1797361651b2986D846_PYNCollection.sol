/**
 *Submitted for verification at polygonscan.com on 2022-09-29
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.x;

interface ERC721TokenReceiver
{
	function onERC721Received(address operator, address from, uint token, bytes calldata data) external returns(bytes4);
}

bytes4 constant transferCheck = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
bytes4 constant ERC721InterfaceId = 0x80ac58cd;

contract MaximalNFTCollection
{
	address immutable creator;

	mapping(uint => address) owner;
	mapping(address => uint) balance;
	mapping(uint => address) public getApproved;
	mapping(address => mapping(address => bool)) public isApprovedForAll;

	constructor ()
	{
		creator = msg.sender;

		balance[creator] = type(uint).max;
	}

	function ownerOf (uint token) public view returns (address)
	{
		return owner[token] == address(0) ? creator : owner[token];
	}

	function balanceOf (address account) external view returns (uint)
	{
		require (account != address(0), "Queries for the address 0 are invalid");

		return balance[account];
	}

	function approve (address to, uint token) external
	{
		require(msg.sender == ownerOf(token) || isApprovedForAll[ownerOf(token)][msg.sender], "No permission to control this token");

		getApproved[token] = to;

		emit Approval(ownerOf(token), to, token);
	}

	function setApprovalForAll(address operator, bool approval) external
	{
		isApprovedForAll[msg.sender][operator] = approval;

		emit ApprovalForAll(msg.sender, operator, approval);
	}

	function supportsInterface(bytes4 interfaceID) external pure returns (bool)
	{
		return interfaceID == ERC721InterfaceId;
	}

	function transferFrom(address from, address to, uint token) public
	{
		require(from == ownerOf(token), "Token not owned by from address");
		require(to != address(0), "Cannot transfer to the zero address");
		require(msg.sender == from || msg.sender == getApproved[token] || isApprovedForAll[ownerOf(token)][msg.sender], "No permission over this token");

		owner[token] = to;
		balance[from]--;
		balance[to]++;
		getApproved[token] = address(0);

		emit Transfer(from, to, token);
		emit Approval(to, address(0), token);
	}

	function safeTransferFrom(address from, address to, uint token, bytes memory data) public
	{
		transferFrom(from, to, token);

		uint toCodeSize;
		assembly { toCodeSize := extcodesize(to) }
		if (toCodeSize > 0)
		{
			require(ERC721TokenReceiver(to).onERC721Received(msg.sender, from, token, data) == transferCheck, "The to address has code but does not implement the ERC721TokenReceiver interface");
		}
	}

	function safeTransferFrom(address from, address to, uint token) public
	{
		safeTransferFrom(from, to, token, bytes(""));
	}

	event Transfer(address indexed from, address indexed to, uint indexed token);
	event Approval(address indexed from, address indexed to, uint indexed token);
	event ApprovalForAll(address indexed from, address indexed to, bool approval);
}

contract PYNCollection is MaximalNFTCollection
{
	string public constant name = "Paint your NFT";
	string public constant symbol = "PYN";

	mapping(uint => uint) public priceOf;
	mapping(uint => bool) public isForSale;

	event Pricing (uint indexed token, uint indexed price);
	event Availability (uint indexed token, bool forSale);

	function tokenURI (uint token) external pure returns (string memory)
	{
		string memory svg = '<svg id="canvas" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><rect x="0" y="0" width="1" height="1" fill="black"></rect><rect fill="white" x="0" y="1" width="1" height="1"></rect><rect x="0" y="2" width="1" height="1"></rect><rect x="0" y="3" width="1" height="1"></rect><rect x="0" y="4" width="1" height="1"></rect><rect x="0" y="5" width="1" height="1"></rect><rect x="0" y="6" width="1" height="1"></rect><rect x="0" y="7" width="1" height="1"></rect><rect x="0" y="8" width="1" height="1"></rect><rect x="0" y="9" width="1" height="1"></rect><rect x="0" y="10" width="1" height="1"></rect><rect x="0" y="11" width="1" height="1"></rect><rect x="0" y="12" width="1" height="1"></rect><rect x="0" y="13" width="1" height="1"></rect><rect x="0" y="14" width="1" height="1"></rect><rect x="0" y="15" width="1" height="1"></rect><rect x="1" y="0" width="1" height="1"></rect><rect x="1" y="1" width="1" height="1"></rect><rect x="1" y="2" width="1" height="1"></rect><rect x="1" y="3" width="1" height="1"></rect><rect x="1" y="4" width="1" height="1"></rect><rect x="1" y="5" width="1" height="1"></rect><rect x="1" y="6" width="1" height="1"></rect><rect x="1" y="7" width="1" height="1"></rect><rect x="1" y="8" width="1" height="1"></rect><rect x="1" y="9" width="1" height="1"></rect><rect x="1" y="10" width="1" height="1"></rect><rect x="1" y="11" width="1" height="1"></rect><rect x="1" y="12" width="1" height="1"></rect><rect x="1" y="13" width="1" height="1"></rect><rect x="1" y="14" width="1" height="1"></rect><rect x="1" y="15" width="1" height="1"></rect><rect x="2" y="0" width="1" height="1"></rect><rect x="2" y="1" width="1" height="1"></rect><rect x="2" y="2" width="1" height="1"></rect><rect x="2" y="3" width="1" height="1"></rect><rect x="2" y="4" width="1" height="1"></rect><rect x="2" y="5" width="1" height="1"></rect><rect x="2" y="6" width="1" height="1"></rect><rect x="2" y="7" width="1" height="1"></rect><rect x="2" y="8" width="1" height="1"></rect><rect x="2" y="9" width="1" height="1"></rect><rect x="2" y="10" width="1" height="1"></rect><rect x="2" y="11" width="1" height="1"></rect><rect x="2" y="12" width="1" height="1"></rect><rect x="2" y="13" width="1" height="1"></rect><rect x="2" y="14" width="1" height="1"></rect><rect x="2" y="15" width="1" height="1"></rect><rect x="3" y="0" width="1" height="1"></rect><rect x="3" y="1" width="1" height="1"></rect><rect x="3" y="2" width="1" height="1"></rect><rect x="3" y="3" width="1" height="1"></rect><rect x="3" y="4" width="1" height="1"></rect><rect x="3" y="5" width="1" height="1"></rect><rect x="3" y="6" width="1" height="1"></rect><rect x="3" y="7" width="1" height="1"></rect><rect x="3" y="8" width="1" height="1"></rect><rect x="3" y="9" width="1" height="1"></rect><rect x="3" y="10" width="1" height="1"></rect><rect x="3" y="11" width="1" height="1"></rect><rect x="3" y="12" width="1" height="1"></rect><rect x="3" y="13" width="1" height="1"></rect><rect x="3" y="14" width="1" height="1"></rect><rect x="3" y="15" width="1" height="1"></rect><rect x="4" y="0" width="1" height="1"></rect><rect x="4" y="1" width="1" height="1"></rect><rect x="4" y="2" width="1" height="1"></rect><rect x="4" y="3" width="1" height="1"></rect><rect x="4" y="4" width="1" height="1"></rect><rect x="4" y="5" width="1" height="1"></rect><rect x="4" y="6" width="1" height="1"></rect><rect x="4" y="7" width="1" height="1"></rect><rect x="4" y="8" width="1" height="1"></rect><rect x="4" y="9" width="1" height="1"></rect><rect x="4" y="10" width="1" height="1"></rect><rect x="4" y="11" width="1" height="1"></rect><rect x="4" y="12" width="1" height="1"></rect><rect x="4" y="13" width="1" height="1"></rect><rect x="4" y="14" width="1" height="1"></rect><rect x="4" y="15" width="1" height="1"></rect><rect x="5" y="0" width="1" height="1"></rect><rect x="5" y="1" width="1" height="1"></rect><rect x="5" y="2" width="1" height="1"></rect><rect x="5" y="3" width="1" height="1"></rect><rect x="5" y="4" width="1" height="1"></rect><rect x="5" y="5" width="1" height="1"></rect><rect x="5" y="6" width="1" height="1"></rect><rect x="5" y="7" width="1" height="1"></rect><rect x="5" y="8" width="1" height="1"></rect><rect x="5" y="9" width="1" height="1"></rect><rect x="5" y="10" width="1" height="1"></rect><rect x="5" y="11" width="1" height="1"></rect><rect x="5" y="12" width="1" height="1"></rect><rect x="5" y="13" width="1" height="1"></rect><rect x="5" y="14" width="1" height="1"></rect><rect x="5" y="15" width="1" height="1"></rect><rect x="6" y="0" width="1" height="1"></rect><rect x="6" y="1" width="1" height="1"></rect><rect x="6" y="2" width="1" height="1"></rect><rect x="6" y="3" width="1" height="1"></rect><rect x="6" y="4" width="1" height="1"></rect><rect x="6" y="5" width="1" height="1"></rect><rect x="6" y="6" width="1" height="1"></rect><rect x="6" y="7" width="1" height="1"></rect><rect x="6" y="8" width="1" height="1"></rect><rect x="6" y="9" width="1" height="1"></rect><rect x="6" y="10" width="1" height="1"></rect><rect x="6" y="11" width="1" height="1"></rect><rect x="6" y="12" width="1" height="1"></rect><rect x="6" y="13" width="1" height="1"></rect><rect x="6" y="14" width="1" height="1"></rect><rect x="6" y="15" width="1" height="1"></rect><rect x="7" y="0" width="1" height="1"></rect><rect x="7" y="1" width="1" height="1"></rect><rect x="7" y="2" width="1" height="1"></rect><rect x="7" y="3" width="1" height="1"></rect><rect x="7" y="4" width="1" height="1"></rect><rect x="7" y="5" width="1" height="1"></rect><rect x="7" y="6" width="1" height="1"></rect><rect x="7" y="7" width="1" height="1"></rect><rect x="7" y="8" width="1" height="1"></rect><rect x="7" y="9" width="1" height="1"></rect><rect x="7" y="10" width="1" height="1"></rect><rect x="7" y="11" width="1" height="1"></rect><rect x="7" y="12" width="1" height="1"></rect><rect x="7" y="13" width="1" height="1"></rect><rect x="7" y="14" width="1" height="1"></rect><rect x="7" y="15" width="1" height="1"></rect><rect x="8" y="0" width="1" height="1"></rect><rect x="8" y="1" width="1" height="1"></rect><rect x="8" y="2" width="1" height="1"></rect><rect x="8" y="3" width="1" height="1"></rect><rect x="8" y="4" width="1" height="1"></rect><rect x="8" y="5" width="1" height="1"></rect><rect x="8" y="6" width="1" height="1"></rect><rect x="8" y="7" width="1" height="1"></rect><rect x="8" y="8" width="1" height="1"></rect><rect x="8" y="9" width="1" height="1"></rect><rect x="8" y="10" width="1" height="1"></rect><rect x="8" y="11" width="1" height="1"></rect><rect x="8" y="12" width="1" height="1"></rect><rect x="8" y="13" width="1" height="1"></rect><rect x="8" y="14" width="1" height="1"></rect><rect x="8" y="15" width="1" height="1"></rect><rect x="9" y="0" width="1" height="1"></rect><rect x="9" y="1" width="1" height="1"></rect><rect x="9" y="2" width="1" height="1"></rect><rect x="9" y="3" width="1" height="1"></rect><rect x="9" y="4" width="1" height="1"></rect><rect x="9" y="5" width="1" height="1"></rect><rect x="9" y="6" width="1" height="1"></rect><rect x="9" y="7" width="1" height="1"></rect><rect x="9" y="8" width="1" height="1"></rect><rect x="9" y="9" width="1" height="1"></rect><rect x="9" y="10" width="1" height="1"></rect><rect x="9" y="11" width="1" height="1"></rect><rect x="9" y="12" width="1" height="1"></rect><rect x="9" y="13" width="1" height="1"></rect><rect x="9" y="14" width="1" height="1"></rect><rect x="9" y="15" width="1" height="1"></rect><rect x="10" y="0" width="1" height="1"></rect><rect x="10" y="1" width="1" height="1"></rect><rect x="10" y="2" width="1" height="1"></rect><rect x="10" y="3" width="1" height="1"></rect><rect x="10" y="4" width="1" height="1"></rect><rect x="10" y="5" width="1" height="1"></rect><rect x="10" y="6" width="1" height="1"></rect><rect x="10" y="7" width="1" height="1"></rect><rect x="10" y="8" width="1" height="1"></rect><rect x="10" y="9" width="1" height="1"></rect><rect x="10" y="10" width="1" height="1"></rect><rect x="10" y="11" width="1" height="1"></rect><rect x="10" y="12" width="1" height="1"></rect><rect x="10" y="13" width="1" height="1"></rect><rect x="10" y="14" width="1" height="1"></rect><rect x="10" y="15" width="1" height="1"></rect><rect x="11" y="0" width="1" height="1"></rect><rect x="11" y="1" width="1" height="1"></rect><rect x="11" y="2" width="1" height="1"></rect><rect x="11" y="3" width="1" height="1"></rect><rect x="11" y="4" width="1" height="1"></rect><rect x="11" y="5" width="1" height="1"></rect><rect x="11" y="6" width="1" height="1"></rect><rect x="11" y="7" width="1" height="1"></rect><rect x="11" y="8" width="1" height="1"></rect><rect x="11" y="9" width="1" height="1"></rect><rect x="11" y="10" width="1" height="1"></rect><rect x="11" y="11" width="1" height="1"></rect><rect x="11" y="12" width="1" height="1"></rect><rect x="11" y="13" width="1" height="1"></rect><rect x="11" y="14" width="1" height="1"></rect><rect x="11" y="15" width="1" height="1"></rect><rect x="12" y="0" width="1" height="1"></rect><rect x="12" y="1" width="1" height="1"></rect><rect x="12" y="2" width="1" height="1"></rect><rect x="12" y="3" width="1" height="1"></rect><rect x="12" y="4" width="1" height="1"></rect><rect x="12" y="5" width="1" height="1"></rect><rect x="12" y="6" width="1" height="1"></rect><rect x="12" y="7" width="1" height="1"></rect><rect x="12" y="8" width="1" height="1"></rect><rect x="12" y="9" width="1" height="1"></rect><rect x="12" y="10" width="1" height="1"></rect><rect x="12" y="11" width="1" height="1"></rect><rect x="12" y="12" width="1" height="1"></rect><rect x="12" y="13" width="1" height="1"></rect><rect x="12" y="14" width="1" height="1"></rect><rect x="12" y="15" width="1" height="1"></rect><rect x="13" y="0" width="1" height="1"></rect><rect x="13" y="1" width="1" height="1"></rect><rect x="13" y="2" width="1" height="1"></rect><rect x="13" y="3" width="1" height="1"></rect><rect x="13" y="4" width="1" height="1"></rect><rect x="13" y="5" width="1" height="1"></rect><rect x="13" y="6" width="1" height="1"></rect><rect x="13" y="7" width="1" height="1"></rect><rect x="13" y="8" width="1" height="1"></rect><rect x="13" y="9" width="1" height="1"></rect><rect x="13" y="10" width="1" height="1"></rect><rect x="13" y="11" width="1" height="1"></rect><rect x="13" y="12" width="1" height="1"></rect><rect x="13" y="13" width="1" height="1"></rect><rect x="13" y="14" width="1" height="1"></rect><rect x="13" y="15" width="1" height="1"></rect><rect x="14" y="0" width="1" height="1"></rect><rect x="14" y="1" width="1" height="1"></rect><rect x="14" y="2" width="1" height="1"></rect><rect x="14" y="3" width="1" height="1"></rect><rect x="14" y="4" width="1" height="1"></rect><rect x="14" y="5" width="1" height="1"></rect><rect x="14" y="6" width="1" height="1"></rect><rect x="14" y="7" width="1" height="1"></rect><rect x="14" y="8" width="1" height="1"></rect><rect x="14" y="9" width="1" height="1"></rect><rect x="14" y="10" width="1" height="1"></rect><rect x="14" y="11" width="1" height="1"></rect><rect x="14" y="12" width="1" height="1"></rect><rect x="14" y="13" width="1" height="1"></rect><rect x="14" y="14" width="1" height="1"></rect><rect x="14" y="15" width="1" height="1"></rect><rect x="15" y="0" width="1" height="1"></rect><rect x="15" y="1" width="1" height="1"></rect><rect x="15" y="2" width="1" height="1"></rect><rect x="15" y="3" width="1" height="1"></rect><rect x="15" y="4" width="1" height="1"></rect><rect x="15" y="5" width="1" height="1"></rect><rect x="15" y="6" width="1" height="1"></rect><rect x="15" y="7" width="1" height="1"></rect><rect x="15" y="8" width="1" height="1"></rect><rect x="15" y="9" width="1" height="1"></rect><rect x="15" y="10" width="1" height="1"></rect><rect x="15" y="11" width="1" height="1"></rect><rect x="15" y="12" width="1" height="1"></rect><rect x="15" y="13" width="1" height="1"></rect><rect x="15" y="14" width="1" height="1"></rect><rect x="15" y="15" width="1" height="1"></rect></svg>';
		return string.concat('data:application/json,{"name": "Name", "description": "Description", "image_data": "data:text/plain,',svg,'"}');
	}

	function buy (uint token) external payable
	{
		require(isForSale[token], "Token is not for sale");
		require(priceOf[token] == msg.value, "Incorrect amount sent. Send exact price amount.");

      payable(ownerOf(token)).transfer(msg.value);

		getApproved[token] = msg.sender;
		safeTransferFrom(ownerOf(token), msg.sender, token);

		isForSale[token] = false;

		emit Availability (token, false);
	}

	function setPrice (uint token, uint price) external
	{
		require(msg.sender == ownerOf(token) || msg.sender == getApproved[token] || isApprovedForAll[ownerOf(token)][msg.sender], "Only owners and operators can modify the price");

		priceOf[token] = price;
		isForSale[token] = true;

		emit Availability (token, true);
		emit Pricing (token, price);
	}

	function toString(uint number) private pure returns (string memory)
	{
		bytes memory characters = new bytes(78);

		uint remaining = number;

		for (int i = 77; i >= 0; i--)
		{
			characters[uint(i)] = bytes1(uint8(0x30 + remaining % 10));
			remaining /= 10;
		}

		return string(characters);
	}
}