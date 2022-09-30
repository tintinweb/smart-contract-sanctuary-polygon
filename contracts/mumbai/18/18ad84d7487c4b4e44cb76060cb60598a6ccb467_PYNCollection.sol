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
		return string.concat("https://pyn.minim.tools/", toString(token));
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