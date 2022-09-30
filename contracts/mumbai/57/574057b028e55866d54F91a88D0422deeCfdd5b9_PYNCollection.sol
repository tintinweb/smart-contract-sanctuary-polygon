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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
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
		string memory json = string.concat('{"name":"', "Name", '","description":"', "Description", '","image": "data:image/svg+xml;base64,', Base64.encode(bytes('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-1 -1 2 2"><circle cx="0" cy="0" r="1"/></svg>')), '"}');
    	return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
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