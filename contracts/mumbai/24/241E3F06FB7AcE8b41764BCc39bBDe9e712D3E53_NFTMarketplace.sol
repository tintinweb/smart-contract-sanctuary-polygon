// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Counters.sol";
import "../access/Ownable.sol";
import "../token/ERC1155/extensions/ERC1155URIStorage.sol";
import "../token/ERC1155/ERC1155.sol";
import "../token/ERC1155/utils/ERC1155Holder.sol";
import "../utils/introspection/ERC165.sol";
import "./AdminContract.sol";
import "./GenomeNFT.sol";

contract NFTMarketplace is ERC1155Holder {
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;
	Counters.Counter private _itemsSold;

	AdminContract private adminContract;
	GenomeNFT private genomeNFT;

	mapping(uint256 => mapping(uint256 => MarketItem))
		private idToMarketItem;

	mapping(uint256 => uint256) private idToCount;

	struct MarketItem {
		uint256 tokenId;
		address payable seller;
		address payable owner;
		uint256 price;
		uint256 count;
		bool sold;
	}

	event MarketItemCreated(
		uint256 indexed tokenId,
		address seller,
		address owner,
		uint256 price,
		uint256 count,
		bool sold
	);

	event MarketItemSold(
		uint256 indexed tokenId,
		uint256 indexed subIndex,
		address seller,
		address owner,
		uint256 price
	);

	event MarketItemListed(
		uint256 indexed tokenId,
		uint256 indexed subIndex,
		address seller,
		address buyer,
		uint256 price
	);

	constructor(address _adminContract, address _nftContract) {
		adminContract = AdminContract(_adminContract);
		genomeNFT = GenomeNFT(_nftContract);
	}

	receive() external payable {}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC1155Receiver)
		returns (bool)
	{
		return interfaceId == type(IERC165).interfaceId;
	}

	function mintAndListNFT(
		string memory tokenURI,
		uint256 price,
		uint256 count
	) public returns (uint256) {
		_tokenIds.increment();
		uint256 newTokenId = _tokenIds.current();

		genomeNFT.mint(msg.sender, newTokenId, count, "Mint NFT");
		genomeNFT.setURI(newTokenId, tokenURI);
		for (uint256 i = 0; i < count; i++) {
			createMarketItem(newTokenId, price, count, i + 1);
		}

		genomeNFT.safeTransferFrom(
			msg.sender,
			address(this),
			newTokenId,
			count,
			""
		);
		emit MarketItemCreated(
			newTokenId,
			msg.sender,
			address(this),
			price,
			count,
			false
		);

		idToCount[newTokenId] = count;
		return newTokenId;
	}

	function listNFT(
		uint256 tokenId,
		uint256 subIndex,
		uint256 price,
		bytes calldata data
	) public {
		require(
			tokenId != 0 && subIndex != 0,
			"Please input non zero tokenId and subIndex"
		);
		require(_tokenIds.current() >= tokenId, "Please input valid tokenId");
		require(idToCount[tokenId] >= subIndex, "Please input valid subIndex");
		require(
			idToMarketItem[tokenId][subIndex].owner == msg.sender,
			"Can not list other's item"
		);

		genomeNFT.safeTransferFrom(
			msg.sender,
			address(this),
			tokenId,
			1,
			data
		);
		idToMarketItem[tokenId][subIndex].sold = false;
		idToMarketItem[tokenId][subIndex].seller = payable(
			address(msg.sender)
		);
		idToMarketItem[tokenId][subIndex].owner = payable(address(this));
		idToMarketItem[tokenId][subIndex].price = price;

		_itemsSold.decrement();

		emit MarketItemListed(
			tokenId,
			subIndex,
			msg.sender,
			address(this),
			price
		);
	}

	function buyNFT(uint256 tokenId, uint256 subIndex) public payable {
		require(
			tokenId != 0 && subIndex != 0,
			"Please input non zero tokenId and subIndex"
		);
		require(_tokenIds.current() >= tokenId, "Please input valid tokenId");
		require(idToCount[tokenId] >= subIndex, "Please input valid subIndex");

		uint256 price = idToMarketItem[tokenId][subIndex].price;
		address seller = idToMarketItem[tokenId][subIndex].seller;
		require(
			msg.value == price,
			"Please submit the asking price in order to complete the purchase"
		);
		genomeNFT.safeTransferFrom(
			address(this),
			msg.sender,
			tokenId,
			1,
			"Buy NFT"
		);

		idToMarketItem[tokenId][subIndex].owner = payable(address(msg.sender));
		idToMarketItem[tokenId][subIndex].sold = true;
		_itemsSold.increment();
		address feeAccount = adminContract.getFeeAccount();
		uint256 feePercent = adminContract.getFeePercent();
		uint256 fee = (price * feePercent) / 10000;
		payable(feeAccount).transfer(fee);
		payable(address(this)).transfer(fee);
		payable(seller).transfer(price - 2 * fee);

		emit MarketItemSold(
			tokenId,
			subIndex,
			idToMarketItem[tokenId][subIndex].seller,
			msg.sender,
			price
		);
	}

	function createMarketItem(
		uint256 tokenId,
		uint256 price,
		uint256 count,
		uint256 subIndex
	) private {
		require(price > 0, "Price must be at least 1 wei");
		idToMarketItem[tokenId][subIndex] = MarketItem(
			tokenId,
			payable(msg.sender),
			payable(address(this)),
			price,
			count,
			false
		);
	}

	function fetchMarketItems() public view returns (MarketItem[] memory) {
		uint256 tokenIdCount = _tokenIds.current();
		uint256 totalItemCount = 0;
		for (uint256 i = 0; i < tokenIdCount; i++) {
			totalItemCount += idToCount[i + 1];
		}
		uint256 unsoldItemCount = totalItemCount - _itemsSold.current();
		uint256 currentIndex = 0;

		MarketItem[] memory items = new MarketItem[](unsoldItemCount);
		for (uint256 i = 0; i < tokenIdCount; i++) {
			uint256 subCount = idToCount[i + 1];
			for (uint256 j = 0; j < subCount; j++) {
				if (
					idToMarketItem[i + 1][j + 1].owner == address(this) &&
					idToMarketItem[i + 1][j + 1].sold == false
				) {
					uint256 currentId = i + 1;
					uint256 currentSubId = j + 1;
					MarketItem storage currentItem = idToMarketItem[currentId][
						currentSubId
					];
					items[currentIndex] = currentItem;
					currentIndex += 1;
				}
			}
		}
		return items;
	}

	function fetchMyNFTs() public view returns (MarketItem[] memory) {
		uint256 totalIdCount = _tokenIds.current();
		uint256 itemCount = 0;
		uint256 currentIndex = 0;
		for (uint256 i = 0; i < totalIdCount; i++) {
			uint256 subCount = idToCount[i + 1];
			for (uint256 j = 0; j < subCount; j++) {
				if (idToMarketItem[i + 1][j + 1].owner == msg.sender) {
					itemCount += 1;
				}
			}
		}

		MarketItem[] memory items = new MarketItem[](itemCount);
		for (uint256 i = 0; i < totalIdCount; i++) {
			uint256 subCount = idToCount[i + 1];
			for (uint256 j = 0; j < subCount; j++) {
				if (idToMarketItem[i + 1][j + 1].owner == msg.sender) {
					uint256 currentId = i + 1;
					uint256 subId = j + 1;
					MarketItem storage currentItem = idToMarketItem[currentId][
						subId
					];
					items[currentIndex] = currentItem;
					currentIndex += 1;
				}
			}
		}

		return items;
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	// function fetchItemsListed() public view returns (MarketItem[] memory) {
	// 	uint256 totalItemCount = _tokenIds.current();
	// 	uint256 itemCount = 0;
	// 	uint256 currentIndex = 0;

	// 	for (uint256 i = 0; i < totalItemCount; i++) {
	// 		if (idToMarketItem[i + 1].seller == msg.sender) {
	// 			itemCount += 1;
	// 		}
	// 	}

	// 	MarketItem[] memory items = new MarketItem[](itemCount);
	// 	for (uint256 i = 0; i < totalItemCount; i++) {
	// 		if (idToMarketItem[i + 1].seller == msg.sender) {
	// 			uint256 currentId = i + 1;
	// 			MarketItem storage currentItem = idToMarketItem[currentId];
	// 			items[currentIndex] = currentItem;
	// 			currentIndex += 1;
	// 		}
	// 	}

	// 	return items;
	// }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Counters {
	struct Counter {
		uint256 _value;
	}

	function current(Counter storage counter)
		internal
		view
		returns (uint256)
	{
		return counter._value;
	}

	function increment(Counter storage counter) internal {
		unchecked {
			counter._value += 1;
		}
	}

	function decrement(Counter storage counter) internal {
		uint256 value = counter._value;
		require(value > 0, "Counter: decrement overflow");
		unchecked {
			counter._value = value - 1;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	constructor() {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../utils/Strings.sol";
import "../ERC1155.sol";

abstract contract ERC1155URIStorage is ERC1155 {
	using Strings for uint256;

	// Optional base URI
	string private _baseURI = "";

	// Optional mapping for token URIs
	mapping(uint256 => string) private _tokenURIs;

	function uri(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		string memory tokenURI = _tokenURIs[tokenId];

		// If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
		return
			bytes(tokenURI).length > 0
				? string(abi.encodePacked(_baseURI, tokenURI))
				: super.uri(tokenId);
	}

	function _setURI(uint256 tokenId, string memory tokenURI)
		internal
		virtual
	{
		_tokenURIs[tokenId] = tokenURI;
		emit URI(uri(tokenId), tokenId);
	}

	function _setBaseURI(string memory baseURI) internal virtual {
		_baseURI = baseURI;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
	using Address for address;

	mapping(uint256 => mapping(address => uint256)) private _balances;

	mapping(address => mapping(address => bool)) private _operatorApprovals;

	string private _uri;

	constructor(string memory uri_) {
		_setURI(uri_);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC165, IERC165)
		returns (bool)
	{
		return
			interfaceId == type(IERC1155).interfaceId ||
			interfaceId == type(IERC1155MetadataURI).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	function uri(uint256)
		public
		view
		virtual
		override
		returns (string memory)
	{
		return _uri;
	}

	function balanceOf(address account, uint256 id)
		public
		view
		virtual
		override
		returns (uint256)
	{
		require(
			account != address(0),
			"ERC1155: balance query for the zero address"
		);
		return _balances[id][account];
	}

	function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
		public
		view
		virtual
		override
		returns (uint256[] memory)
	{
		require(
			accounts.length == ids.length,
			"ERC1155: accounts and ids length mismatch"
		);

		uint256[] memory batchBalances = new uint256[](accounts.length);

		for (uint256 i = 0; i < accounts.length; i++) {
			batchBalances[i] = balanceOf(accounts[i], ids[i]);
		}

		return batchBalances;
	}

	function setApprovalForAll(address operator, bool approved)
		public
		virtual
		override
	{
		require(
			_msgSender() != operator,
			"ERC1155: setting approval status for self"
		);

		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	function isApprovedForAll(address account, address operator)
		public
		view
		virtual
		override
		returns (bool)
	{
		return _operatorApprovals[account][operator];
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		require(to != address(0), "ERC1155: transfer to the zero address");
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);

		address operator = _msgSender();

		_beforeTokenTransfer(
			operator,
			from,
			to,
			_asSingletonArray(id),
			_asSingletonArray(amount),
			data
		);

		uint256 fromBalance = _balances[id][from];
		require(
			fromBalance >= amount,
			"ERC1155: insufficient balance for transfer"
		);
		_balances[id][from] = fromBalance - amount;
		_balances[id][to] += amount;

		emit TransferSingle(operator, from, to, id, amount);

		_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		require(
			ids.length == amounts.length,
			"ERC1155: ids and amounts length mismatch"
		);
		require(to != address(0), "ERC1155: transfer to the zero address");
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: transfer caller is not owner nor approved"
		);

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; ++i) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(
				fromBalance >= amount,
				"ERC1155: insufficient balance for transfer"
			);
			_balances[id][from] = fromBalance - amount;
			_balances[id][to] += amount;
		}

		emit TransferBatch(operator, from, to, ids, amounts);

		_doSafeBatchTransferAcceptanceCheck(
			operator,
			from,
			to,
			ids,
			amounts,
			data
		);
	}

	function _setURI(string memory newuri) internal virtual {
		_uri = newuri;
	}

	function _mint(
		address account,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(account != address(0), "ERC1155: mint to the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(
			operator,
			address(0),
			account,
			_asSingletonArray(id),
			_asSingletonArray(amount),
			data
		);

		_balances[id][account] += amount;
		emit TransferSingle(operator, address(0), account, id, amount);

		_doSafeTransferAcceptanceCheck(
			operator,
			address(0),
			account,
			id,
			amount,
			data
		);
	}

	function _mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");
		require(
			ids.length == amounts.length,
			"ERC1155: ids and amounts length mismatch"
		);

		address operator = _msgSender();

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; i++) {
			_balances[ids[i]][to] += amounts[i];
		}

		emit TransferBatch(operator, address(0), to, ids, amounts);

		_doSafeBatchTransferAcceptanceCheck(
			operator,
			address(0),
			to,
			ids,
			amounts,
			data
		);
	}

	function _burn(
		address account,
		uint256 id,
		uint256 amount
	) internal virtual {
		require(account != address(0), "ERC1155: burn from the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(
			operator,
			account,
			address(0),
			_asSingletonArray(id),
			_asSingletonArray(amount),
			""
		);

		uint256 accountBalance = _balances[id][account];
		require(
			accountBalance >= amount,
			"ERC1155: burn amount exceeds balance"
		);
		_balances[id][account] = accountBalance - amount;

		emit TransferSingle(operator, account, address(0), id, amount);
	}

	function _burnBatch(
		address account,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal virtual {
		require(account != address(0), "ERC1155: burn from the zero address");
		require(
			ids.length == amounts.length,
			"ERC1155: ids and amounts length mismatch"
		);

		address operator = _msgSender();

		_beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 accountBalance = _balances[id][account];
			require(
				accountBalance >= amount,
				"ERC1155: burn amount exceeds balance"
			);
			_balances[id][account] = accountBalance - amount;
		}

		emit TransferBatch(operator, account, address(0), ids, amounts);
	}

	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}

	function _doSafeTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) private {
		if (to.isContract()) {
			try
				IERC1155Receiver(to).onERC1155Received(
					operator,
					from,
					id,
					amount,
					data
				)
			returns (bytes4 response) {
				if (response != IERC1155Receiver(to).onERC1155Received.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	function _doSafeBatchTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) private {
		if (to.isContract()) {
			try
				IERC1155Receiver(to).onERC1155BatchReceived(
					operator,
					from,
					ids,
					amounts,
					data
				)
			returns (bytes4 response) {
				if (
					response != IERC1155Receiver(to).onERC1155BatchReceived.selector
				) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	function _asSingletonArray(uint256 element)
		private
		pure
		returns (uint256[] memory)
	{
		uint256[] memory array = new uint256[](1);
		array[0] = element;

		return array;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

contract ERC1155Holder is ERC1155Receiver {
	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes memory
	) public virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] memory,
		uint256[] memory,
		bytes memory
	) public virtual override returns (bytes4) {
		return this.onERC1155BatchReceived.selector;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override
		returns (bool)
	{
		return interfaceId == type(IERC165).interfaceId;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../access/Ownable.sol";

contract AdminContract is Ownable {
	address[] private adminMembers;
	address private feeAccount = address(0);
	uint256 private feePercent = 500;

	constructor() {}

	function addMember(address account) external onlyOwner {
		adminMembers.push(account);
	}

	function removeMember(address account) external onlyOwner {
		for (uint256 i = 0; i < adminMembers.length; i++) {
			if (adminMembers[i] == account) {
				adminMembers[i] = adminMembers[adminMembers.length - 1];
				adminMembers.pop();
			}
		}
	}

	function isAdmin(address account) public view returns (bool) {
		for (uint256 i = 0; i < adminMembers.length; i++) {
			if (adminMembers[i] == account) {
				return true;
			}
		}
		return false;
	}

	function setFeeAccount(address account) public onlyOwner {
		feeAccount = account;
	}

	function getFeeAccount() public view returns (address) {
		return feeAccount;
	}

	function setFeePercent(uint256 _feePercent) public onlyOwner {
		feePercent = _feePercent;
	}

	function getFeePercent() public view returns (uint256) {
		return feePercent;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/ERC1155URIStorage.sol";
import "../access/Ownable.sol";

contract GenomeNFT is ERC1155URIStorage, Ownable {
	address private _marketplace = address(0);

	constructor() ERC1155("uri") {}

	function mint(
		address account,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) public virtual {
		require(
			msg.sender == owner() || msg.sender == _marketplace,
			"Only can mint by owner or marketplace"
		);
		_mint(account, id, amount, data);
	}

	function setURI(uint256 tokenId, string memory tokenURI) public virtual {
		require(
			msg.sender == owner() || msg.sender == _marketplace,
			"Only can be set by owner or marketplace"
		);
		_setURI(tokenId, tokenURI);
	}

	function setMarketplace(address marketplace) public onlyOwner {
		_marketplace = marketplace;
	}

	function getMarketplace() public view returns (address) {
		return _marketplace;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this;
		return msg.data;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Strings {
	bytes16 private constant alphabet = "0123456789abcdef";

	function toString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return "0";
		}

		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

	function toHexString(uint256 value)
		internal
		pure
		returns (string memory)
	{
		if (value == 0) {
			return "0x00";
		}

		uint256 temp = value;
		uint256 length = 0;
		while (temp != 0) {
			length++;
			temp >>= 8;
		}
		return toHexString(value, length);
	}

	function toHexString(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; i--) {
			buffer[i] = alphabet[value & 0xf];
			value >>= 4;
		}
		require(value == 0, "Strings: hex length insufficient");
		return string(buffer);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

interface IERC1155 is IERC165 {
	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 value
	);
	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] values
	);
	event ApprovalForAll(
		address indexed account,
		address indexed operator,
		bool approved
	);
	event URI(string value, uint256 indexed id);

	function balanceOf(address account, uint256 id)
		external
		view
		returns (uint256);

	function balanceOfBatch(
		address[] calldata accounts,
		uint256[] calldata ids
	) external view returns (uint256[] memory);

	function setApprovalForAll(address operator, bool approved) external;

	function isApprovedForAll(address account, address operator)
		external
		view
		returns (bool);

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external;

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

interface IERC1155Receiver is IERC165 {
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 value,
		bytes calldata data
	) external returns (bytes4);

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

interface IERC1155MetadataURI is IERC1155 {
	function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{ value: amount }("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
			functionCallWithValue(
				target,
				data,
				value,
				"Address: low-level call with value failed"
			);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{ value: value }(
			data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
		internal
		view
		returns (bytes memory)
	{
		return
			functionStaticCall(
				target,
				data,
				"Address: low-level static call failed"
			);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return
			functionDelegateCall(
				target,
				data,
				"Address: low-level delegate call failed"
			);
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
	function supportsInterface(bytes4 interfaceId)
		external
		view
		returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC165, IERC165)
		returns (bool)
	{
		return
			interfaceId == type(IERC1155Receiver).interfaceId ||
			super.supportsInterface(interfaceId);
	}
}