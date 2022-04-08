// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./interfaces/ERC721Metadata.sol";

contract NftCollectible is ERC721, ERC721Metadata {
	string public name;
	string public symbol;
	uint public tokenCount;
	mapping(uint => string) private _tokenURIs;

	constructor(string memory _name, string memory _symbol) {
		name = _name;
		symbol = _symbol;
	}

	function tokenURI(uint _tokenId) external view returns (string memory) {
		require(_owners[_tokenId] != address(0), "token does not exist");
		return _tokenURIs[_tokenId];
	}

	function mint(string memory _tokenURI) public {
		tokenCount += 1; // _tokenId
		_balances[msg.sender] += 1;
		_owners[tokenCount] = msg.sender;
		_tokenURIs[tokenCount] = _tokenURI;

		emit Transfer(address(0), msg.sender, tokenCount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./libraries/Address.sol";

contract ERC721 is IERC721 {
	using Address for address;

	mapping(address => uint) internal _balances;
	mapping(uint => address) internal _owners;
	mapping(address => mapping(address => bool)) private _operatorApprovals;
	mapping(uint => address) private _tokenApprovals;

	modifier noZeroAddress(address _owner) {
		require(_owner != address(0), "invalid address");
		_;
	}

	function balanceOf(address _owner)
		external
		view
		noZeroAddress(_owner)
		returns (uint)
	{
		return _balances[_owner];
	}

	function ownerOf(uint _tokenId) public view override returns (address) {
		address _owner = _owners[_tokenId];
		require(_owner != address(0), "token does not exist");
		return _owner;
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint _tokenId,
		bytes memory data
	) public payable {
		transferFrom(_from, _to, _tokenId);
		require(
			_checkOnERC721Received(_from, _to, _tokenId, data),
			"ERC721Receiver not implemeted"
		);
	}

	function _checkOnERC721Received(
		address _from,
		address _to,
		uint _tokenId,
		bytes memory data
	) private returns (bool) {
		if (!_to.isContract()) return true;

		return
			IERC721Receiver(_to).onERC721Received(
				msg.sender,
				_from,
				_tokenId,
				data
			) == IERC721Receiver.onERC721Received.selector;
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint _tokenId
	) external payable {
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function transferFrom(
		address _from,
		address _to,
		uint _tokenId
	) public payable {
		address _owner = ownerOf(_tokenId);

		require(
			msg.sender == _owner ||
				getApproved(_tokenId) == msg.sender ||
				isApprovedForAll(_owner, msg.sender),
			"unauthorized"
		);
		require(_owner == _from, "from address is not the owner");
		require(_to != address(0), "invalid address");
		require(_owner != address(0), "token does not exist");

		approve(address(0), _tokenId);
		_balances[_from] -= 1;
		_balances[_to] += 1;
		_owners[_tokenId] = _to;
		emit Transfer(_from, _to, _tokenId);
	}

	function approve(address _approved, uint _tokenId) public payable {
		address _owner = ownerOf(_tokenId);
		require(
			msg.sender == _owner || isApprovedForAll(_owner, msg.sender),
			"unauthorized"
		);
		_tokenApprovals[_tokenId] = _approved;
		emit Approval(_owner, _approved, _tokenId);
	}

	function setApprovalForAll(address _operator, bool _approved) external {
		_operatorApprovals[msg.sender][_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function getApproved(uint _tokenId) public view returns (address) {
		address _owner = _owners[_tokenId];
		require(_owner != address(0), "token does not exist");
		return _tokenApprovals[_tokenId];
	}

	function isApprovedForAll(address _owner, address _operator)
		public
		view
		returns (bool)
	{
		return _operatorApprovals[_owner][_operator];
	}

	function supportsInterface(bytes4 interfaceID)
		external
		pure
		returns (bool)
	{
		return
			interfaceID == type(IERC165).interfaceId ||
			interfaceID == type(IERC721).interfaceId;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC721Metadata {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC165.sol";

interface IERC721 is IERC165 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint indexed _tokenId
	);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(
		address indexed _owner,
		address indexed _approved,
		uint indexed _tokenId
	);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(
		address indexed _owner,
		address indexed _operator,
		bool _approved
	);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(
		address _from,
		address _to,
		uint _tokenId,
		bytes memory data
	) external payable;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(
		address _from,
		address _to,
		uint _tokenId
	) external payable;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(
		address _from,
		address _to,
		uint _tokenId
	) external payable;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint _tokenId) external payable;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator)
		external
		view
		returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721Receiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param _operator The address which called `safeTransferFrom` function
	/// @param _from The address which previously owned the token
	/// @param _tokenId The NFT identifier which is being transferred
	/// @param _data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(
		address _operator,
		address _from,
		uint _tokenId,
		bytes calldata _data
	) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Address {
	function isContract(address _addr) internal view returns (bool) {
		uint size;
		assembly {
			size := extcodesize(_addr)
		}
		return size > 0;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC165 {
	/// @notice Query if a contract implements an interface
	/// @param interfaceID The interface identifier, as specified in ERC-165
	/// @dev Interface identification is specified in ERC-165. This function
	///  uses less than 30,000 gas.
	/// @return `true` if the contract implements `interfaceID` and
	///  `interfaceID` is not 0xffffffff, `false` otherwise
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}