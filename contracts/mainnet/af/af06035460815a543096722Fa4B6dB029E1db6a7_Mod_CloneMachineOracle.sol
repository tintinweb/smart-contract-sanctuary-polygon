//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

abstract contract Authentication {
	address public deployer;
	/// @notice for re-entry prevention, keeps track of a methods execution count
	uint256 private executionCount;

	mapping(address => bool) public approved;

	constructor() {
		deployer = msg.sender;
		approved[msg.sender] = true;
		executionCount = 0;
	}

	event PermissionChange(
		address indexed sender,
		address indexed changee,
		bool value
	);

	event TransferedOwnership(address indexed from, address indexed to);

	/// @notice Limits execution of a method to once in the given context.
	/// @dev prevents re-entry attack
	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	modifier onlyDeployer() {
		require(deployer == msg.sender, "not deployer");
		_;
	}

	modifier onlyApproved() {
		require(deployer == msg.sender || approved[msg.sender], "not approved");
		_;
	}

	function setPrivilages(address addr, bool value) public onlyDeployer {
		require(addr != deployer, "cannot modify deployer");
		approved[addr] = value;

		emit PermissionChange(msg.sender, addr, value);
	}

	function multiApprove(address[] memory addrs) public onlyDeployer {
		require(addrs.length != 0);
		for (uint256 i = 0; i < addrs.length; ) {
			approved[addrs[i]] = true;
			unchecked {
				++i;
			}
		}
	}

	function isAuthenticated(address addr) external view returns (bool) {
		return addr == deployer || approved[addr];
	}

	function transferOwnership(address addr) public onlyDeployer {
		approved[deployer] = false;
		deployer = addr;
		approved[addr] = true;

		emit TransferedOwnership(msg.sender, addr);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC165.sol";
import "./IERC165.sol";

/// @title ERC-721 Infinity Mint Implementation
/// @author Llydia Cross
/// @notice This is a basic ERC721 Implementation that is designed to be as simple and gas efficient as possible.
/// @dev This contract supports tokenURI (the Metadata extension) but does not include the Enumerable extension.
contract ERC721 is ERC165, IERC721, IERC721Metadata {
	///@notice Storage for the tokens
	///@dev indexed by tokenId
	mapping(uint256 => address) internal tokens; //(slot 0)
	///@notice Storage the token metadata
	///@dev indexed by tokenId
	mapping(uint256 => string) internal uri; //(slot 1)
	///@notice Storage the token metadata
	///@dev indexed by tokenId
	mapping(uint256 => address) internal approvedTokens; //(slot 2)
	///@notice Stores approved operators for the addresses tokens.
	mapping(address => mapping(address => bool)) internal operators; //(slot 3)
	///@notice Stores the balance of tokens
	mapping(address => uint256) internal balance; //(slot 4)

	///@notice The name of the ERC721
	string internal _name; //(slot 5)
	///@notice The Symbol of the ERC721
	string internal _symbol; //(slot 6)

	/**
        @notice ERC721 Constructor takes tokenName and tokenSymbol
     */
	constructor(string memory tokenName, string memory tokenSymbol) {
		_name = tokenName;
		_symbol = tokenSymbol;
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 * @notice this is used by opensea/polyscan to detect our ERC721
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC165, IERC165)
		returns (bool)
	{
		return
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
        @notice blanceOf returns the number of tokens an address currently holds.
     */
	function balanceOf(address _owner) public view override returns (uint256) {
		return balance[_owner];
	}

	/**
        @notice Returns the owner of a current token
        @dev will Throw if the token does not exist
     */
	function ownerOf(uint256 _tokenId)
		public
		view
		virtual
		override
		returns (address)
	{
		require(exists(_tokenId), "invalid tokenId");
		return tokens[_tokenId];
	}

	/**
        @notice Will approve an operator for the senders tokens
    */
	function setApprovalForAll(address _operator, bool _approved)
		public
		override
	{
		operators[_sender()][_operator] = _approved;
		emit ApprovalForAll(_sender(), _operator, _approved);
	}

	/**
        @notice Will returns true if the operator is approved by the owner address
    */
	function isApprovedForAll(address _owner, address _operator)
		public
		view
		override
		returns (bool)
	{
		return operators[_owner][_operator];
	}

	/**
        @notice Returns the tokens URI Metadata object
    */
	function tokenURI(uint256 _tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		return uri[_tokenId];
	}

	/**
        @notice Returns the name of the ERC721  for display on places like Etherscan
    */
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	/**
        @notice Returns the symbol of the ERC721 for display on places like Polyscan
    */
	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	/**
        @notice Returns the approved adress for this token.
    */
	function getApproved(uint256 _tokenId)
		public
		view
		override
		returns (address)
	{
		return approvedTokens[_tokenId];
	}

	/**
        @notice Sets an approved adress for this token
        @dev will Throw if tokenId does not exist
    */
	function approve(address _to, uint256 _tokenId) public override {
		address owner = ERC721.ownerOf(_tokenId);

		require(_to != owner, "cannot approve owner");
		require(
			_sender() == owner || isApprovedForAll(owner, _sender()),
			"ERC721: approve caller is not token owner or approved for all"
		);
		approvedTokens[_tokenId] = _to;
		emit Approval(owner, _to, _tokenId);
	}

	/**
        @notice Mints a token.
        @dev If you are transfering a token to a contract the contract will make sure that it can recieved the ERC721 (implements a IERC721Receiver) if it does not it will revert the transcation. Emits a {Transfer} event.
    */
	function mint(
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) internal {
		require(_to != address(0x0), "0x0 mint");
		require(!exists(_tokenId), "already minted");

		balance[_to] += 1;
		tokens[_tokenId] = _to;

		emit Transfer(address(0x0), _to, _tokenId);

		//check that the ERC721 has been received
		require(
			checkERC721Received(_sender(), address(this), _to, _tokenId, _data)
		);
	}

	/**
        @notice Returns true if a token exists.
     */
	function exists(uint256 _tokenId) public view returns (bool) {
		return tokens[_tokenId] != address(0x0);
	}

	/// @notice Is ran before every transfer, overwrite this function with your own logic
	/// @dev Must return true else will revert
	function beforeTransfer(
		address _from,
		address _to,
		uint256 _tokenId
	) internal virtual {}

	/**
        @notice Transfers a token fsrom one address to another. Use safeTransferFrom as that will double check that the address you send this token too is a contract that can actually receive it.
		@dev Emits a {Transfer} event.
     */
	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override {
		require(
			isApprovedOrOwner(_sender(), _tokenId),
			"not approved or owner"
		);
		require(_from != address(0x0), "sending to null address");

		//before the transfer
		beforeTransfer(_from, _to, _tokenId);

		delete approvedTokens[_tokenId];
		balance[_from] -= 1;
		balance[_to] += 1;
		tokens[_tokenId] = _to;

		emit Transfer(_from, _to, _tokenId);
	}

	/// @notice will returns true if the address is apprroved for all, approved operator or is the owner of a token
	/// @dev same as open zepps
	function isApprovedOrOwner(address addr, uint256 tokenId)
		public
		view
		returns (bool)
	{
		address owner = ERC721.ownerOf(tokenId);
		return (addr == owner ||
			isApprovedForAll(owner, addr) ||
			getApproved(tokenId) == addr);
	}

	/**
        @notice Just like transferFrom except we will check if the to address is a contract and is an IERC721Receiver implementer
		@dev Emits a {Transfer} event.
     */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) public virtual override {
		_safeTransferFrom(_from, _to, _tokenId, _data);
	}

	/**
        @notice Just like the method above except with no data field we pass to the implemeting contract.
		@dev Emits a {Transfer} event.
     */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override {
		_safeTransferFrom(_from, _to, _tokenId, "");
	}

	/**
        @notice Internal method to transfer the token and require that checkERC721Recieved is equal to true.
     */
	function _safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) private {
		transferFrom(_from, _to, _tokenId);
		//check that it implements an IERC721 receiver if it is a contract
		require(
			checkERC721Received(_sender(), _from, _to, _tokenId, _data),
			"ERC721 Receiver Confirmation Is Bad"
		);
	}

	/**
        @notice Checks first if the to address is a contract, if it is it will confirm that the contract is an ERC721 implentor by confirming the selector returned as documented in the ERC721 standard. If the to address isnt a contract it will just return true. Based on the code inside of OpenZeppelins ERC721
     */
	function checkERC721Received(
		address _operator,
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) private returns (bool) {
		if (!isContract(_to)) return true;

		try
			IERC721Receiver(_to).onERC721Received(
				_operator,
				_from,
				_tokenId,
				_data
			)
		returns (bytes4 confirmation) {
			return (confirmation == IERC721Receiver.onERC721Received.selector);
		} catch (bytes memory reason) {
			if (reason.length == 0) {
				revert("This contract does not implement an IERC721Receiver");
			} else {
				assembly {
					revert(add(32, reason), mload(reason))
				}
			}
		}
	}

	///@notice secures msg.sender so it cannot be changed
	function _sender() internal view returns (address) {
		return (msg.sender);
	}

	///@notice Returns true if the address is a contract
	///@dev Sometimes doesnt work and contracts might be disgused as addresses
	function isContract(address _address) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(_address)
		}
		return size > 0;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol) (Thanks <3)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
	/**
	 * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
	 */
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
	 */
	event Approval(
		address indexed owner,
		address indexed approved,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
	 */
	event ApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);

	/**
	 * @dev Returns the number of tokens in ``owner``'s account.
	 */
	function balanceOf(address owner) external view returns (uint256 balance);

	/**
	 * @dev Returns the owner of the `tokenId` token.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function ownerOf(uint256 tokenId) external view returns (address owner);

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
	 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	/**
	 * @dev Transfers `tokenId` token from `from` to `to`.
	 *
	 * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	/**
	 * @dev Gives permission to `to` to transfer `tokenId` token to another account.
	 * The approval is cleared when the token is transferred.
	 *
	 * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
	 *
	 * Requirements:
	 *
	 * - The caller must own the token or be an approved operator.
	 * - `tokenId` must exist.
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address to, uint256 tokenId) external;

	/**
	 * @dev Returns the account approved for `tokenId` token.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function getApproved(uint256 tokenId)
		external
		view
		returns (address operator);

	/**
	 * @dev Approve or remove `operator` as an operator for the caller.
	 * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
	 *
	 * Requirements:
	 *
	 * - The `operator` cannot be the caller.
	 *
	 * Emits an {ApprovalForAll} event.
	 */
	function setApprovalForAll(address operator, bool _approved) external;

	/**
	 * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
	 *
	 * See {setApprovalForAll}
	 */
	function isApprovedForAll(address owner, address operator)
		external
		view
		returns (bool);

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes calldata data
	) external;
}

/// @title ERC-721 Non-Fungible Token Standard, ERC721 Receiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface IERC721Receiver {
	/**
	 * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
	 * by `operator` from `from`, this function is called.
	 *
	 * It must return its Solidity selector to confirm the token transfer.
	 * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
	 *
	 * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
	 */
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata is IERC721 {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";
import "./IntegrityInterface.sol";
import "./InfinityMintStorage.sol";

/// @title InfinityMint Linker
/// @author Llydia Cross
/// @notice Serves as a utility contract which manages the destinations field of an InfinityMint token
/// @dev Allows content owners to add pre-validated links the user can add to their destinations field, contract creator sets links through build tools
contract InfinityMintLinker is Authentication, InfinityMintObject {
	/// @notice the location of the main ERC721 contract
	address public erc721Location;
	/// @notice location of the storage contract
	InfinityMintStorage internal storageController;
	/// @notice holds all of the links its length is linkCount
	mapping(uint256 => Link) internal links;
	/// @notice the length of links mapping or the amount of links setup
	uint256 linkCount = 0;

	struct Link {
		uint256 index;
		bytes versionType;
		bytes4 interfaceId;
		string key;
		bool erc721;
		bool verifyIntegrity;
		bool forcedOnly;
		bool permanent;
		bool active;
	}

	constructor(address _storageDestination, address erc721Destination) {
		storageController = InfinityMintStorage(_storageDestination);
		erc721Location = erc721Destination;
	}

	function getLink(uint256 index) external view returns (Link memory) {
		require(bytes(links[index].key).length != 0, "link is invalid");
		return links[index];
	}

	function getLinkByKey(string calldata key)
		external
		view
		returns (Link memory)
	{
		return requireLinkFromKey(key);
	}

	function addSupport(
		uint256 index,
		string memory key,
		bytes memory versionType,
		bool isErc721,
		bool verifyIntegrity,
		bool forcedOnly,
		bool permanent
	) public onlyApproved {
		require(index < 32, "can only have a maximum index of 32");
		require(links[index].active != true, "link already established");
		links[index] = Link(
			index,
			versionType,
			type(IntegrityInterface).interfaceId,
			key,
			isErc721,
			verifyIntegrity,
			forcedOnly,
			permanent,
			true
		);
		unchecked {
			linkCount++;
		}
	}

	/// @notice disables this link from being used in the future
	function toggleSupport(uint256 index) public onlyApproved {
		require(bytes(links[index].key).length != 0, "invalid link");
		links[index].active = false;
	}

	/// @notice used by build tools to redeploy
	function clearLinks() public onlyDeployer {
		for (uint256 i = 0; i < linkCount; ) {
			if (links[i].active) links[i].active = false;
			unchecked {
				++i;
			}
		}

		linkCount = 0;
	}

	function changeLinkKey(string calldata keyToChange, string calldata key)
		public
		onlyApproved
	{
		Link memory tempLink = requireLinkFromKey(keyToChange);
		require(
			hasKey(key) == false,
			"cannot change key to that key as that key already exists"
		);

		tempLink.key = key;
		links[tempLink.index] = tempLink;
	}

	function hasKey(string calldata key) internal view returns (bool) {
		require(bytes(key).length != 0, "blank key");

		for (uint256 i = 0; i < linkCount; ) {
			if (
				InfinityMintUtil.isEqual(bytes(links[i].key), bytes(key)) &&
				links[i].active
			) return true;

			unchecked {
				++i;
			}
		}

		return false;
	}

	/// @notice gets link type from string key name
	/// @dev if two or more keys are present with the same name then this is designed to return the newest object which has been added.
	function requireLinkFromKey(string calldata key)
		internal
		view
		returns (Link memory)
	{
		require(bytes(key).length != 0, "blank key");

		Link memory tempLink;
		bool hasFound = false;
		for (uint256 i = 0; i < linkCount; ) {
			if (
				InfinityMintUtil.isEqual(bytes(links[i].key), bytes(key)) &&
				links[i].active
			) {
				hasFound = true;
				tempLink = links[i];
			}
			unchecked {
				++i;
			}
		}

		require(hasFound, "key invalid");
		return tempLink;
	}

	/// @notice has to be called by token owner
	function setLink(
		uint256 tokenId,
		string calldata key,
		address destination
	) public {
		require(isApprovedOrOwner(sender(), tokenId), "not owner");
		_setLink(tokenId, key, destination);
	}

	/// @notice Can be called by other contracts who are approved
	function forceLink(
		uint256 tokenId,
		string calldata key,
		address destination
	) public onlyApproved {
		Link memory link = requireLinkFromKey(key); // will throw
		InfinityObject memory token = storageController.get(uint32(tokenId)); // will throw

		if (token.destinations.length == 0) {
			token.destinations = new address[](link.index + 1);
			token.destinations[link.index] = destination;
		} else {
			if (link.index >= token.destinations.length) {
				address[] memory tempCopy = new address[](link.index + 1);
				for (uint256 i = 0; i < tempCopy.length; ) {
					if (i == link.index) tempCopy[i] = destination;
					else if (
						i < token.destinations.length &&
						token.destinations[i] != address(0x0)
					) tempCopy[i] = token.destinations[i];

					unchecked {
						++i;
					}
				}

				token.destinations = tempCopy;
			} else {
				token.destinations[link.index] = destination;
			}
		}

		storageController.set(uint32(tokenId), token);
	}

	function unlink(uint256 tokenId, string calldata key) public {
		require(isApprovedOrOwner(sender(), tokenId), "not owner");

		Link memory link = requireLinkFromKey(key); // will throw
		InfinityObject memory token = storageController.get(uint32(tokenId)); // will throw
		require(link.permanent != true, "link can never be unlinked");
		require(
			link.forcedOnly != true,
			"link must be managed through an external contract"
		);

		//the first two indexes should always be index 0 (wallet) and index 1 (stickers), the erc721
		//will set a token flag allowing you to unlink the contracts upon transfer unless it is
		//disabled in the values controller. it is up to the deployer to decide if they will
		//allow people to unlink the wallet/sticker when they transfer, bare in mind this does
		//potentially allow them to transfer the token, unlink and re-establish new links
		//burning eads contracts.
		require(
			link.index != 0 ||
				storageController.flag(tokenId, "canUnlinkIndex0"),
			"index 0 cannot be unlinked at this time"
		);
		require(
			link.index != 1 ||
				storageController.flag(tokenId, "canUnlinkIndex1"),
			"index 1 cannot be unlinked at this time"
		);

		token.destinations[link.index] = address(0x0);
		storageController.set(uint32(tokenId), token);
	}

	function _setLink(
		uint256 tokenId,
		string calldata key,
		address destination
	) internal {
		Link memory link = requireLinkFromKey(key); // will throw
		InfinityObject memory token = storageController.get(uint32(tokenId)); // will throw

		//must be set by another contract
		require(link.forcedOnly != true, "cannot be set by linker");
		//if the destinations isnt zero require it to be a new index or an unmapped but created inex
		require(
			token.destinations.length == 0 ||
				(
					link.index < token.destinations.length
						? token.destinations[link.index] == address(0x0)
						: true
				),
			"previous link already established"
		);

		// for stuff like ENS Registry contracts and the like outside of InfinityMint we can chose not to verify
		if (link.verifyIntegrity) {
			(
				address from,
				address _deployer,
				uint256 _tokenId,
				bytes memory versionType,
				bytes4 interfaceId
			) = IntegrityInterface(destination).getIntegrity();

			require(_deployer == sender(), "mismatch 0");
			require(from == destination, "mismatch 1");
			require(tokenId == _tokenId, "mismatch 2");
			require(
				InfinityMintUtil.isEqual(versionType, link.versionType),
				"mismatch 3"
			);
			require(interfaceId == link.interfaceId, "mismatch 4");
		}

		if (token.destinations.length == 0) {
			token.destinations = new address[](link.index + 1);
			token.destinations[link.index] = destination;
		} else {
			if (link.index >= token.destinations.length) {
				address[] memory tempCopy = new address[](link.index + 1);
				for (uint256 i = 0; i < tempCopy.length; ) {
					if (i == link.index) tempCopy[i] = destination;
					else if (
						i < token.destinations.length &&
						token.destinations[i] != address(0x0)
					) tempCopy[i] = token.destinations[i];

					unchecked {
						++i;
					}
				}

				token.destinations = tempCopy;
			} else {
				token.destinations[link.index] = destination;
			}
		}

		storageController.set(uint32(tokenId), token);
	}

	/// @notice gets token
	/// @dev erc721 address must be ERC721 implementor.
	function isApprovedOrOwner(address owner, uint256 tokenId)
		private
		view
		returns (bool)
	{
		(bool success, bytes memory returnData) = erc721Location.staticcall(
			abi.encodeWithSignature(
				"isApprovedOrOwner(address,uint256)",
				owner,
				tokenId
			)
		);

		if (!success) {
			if (returnData.length == 0) revert("is approved or owner reverted");
			else
				assembly {
					let returndata_size := mload(returnData)
					revert(add(32, returnData), returndata_size)
				}
		}

		bool result = abi.decode(returnData, (bool));
		return result == true;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//this is implemented by every contract in our system
import "./InfinityMintUtil.sol";
import "./InfinityMintValues.sol";

abstract contract InfinityMintObject {
	/// @notice The main InfinityMint object, TODO: Work out a way for this to easily be modified
	struct InfinityObject {
		uint32 pathId;
		uint32 pathSize;
		uint32 currentTokenId;
		address owner;
		uint32[] colours;
		bytes mintData;
		uint32[] assets;
		string[] names;
		address[] destinations;
	}

	/// @notice Creates a new struct from arguments
	/// @dev Stickers are not set through this, structs cannot be made with sticker contracts already set and have to be set manually
	/// @param currentTokenId the tokenId,
	/// @param pathId the infinity mint paths id
	/// @param pathSize the size of the path (only for vectors)
	/// @param assets the assets which make up the token
	/// @param names the names of the token, its just the name but split by the splaces.
	/// @param colours decimal colours which will be convered to hexadecimal colours
	/// @param mintData variable dynamic field which is passed to ERC721 Implementor contracts and used in a lot of dynamic stuff
	/// @param _sender aka the owner of the token
	/// @param destinations a list of contracts associated with this token
	function createInfinityObject(
		uint32 currentTokenId,
		uint32 pathId,
		uint32 pathSize,
		uint32[] memory assets,
		string[] memory names,
		uint32[] memory colours,
		bytes memory mintData,
		address _sender,
		address[] memory destinations
	) internal pure returns (InfinityObject memory) {
		return
			InfinityObject(
				pathId,
				pathSize,
				currentTokenId,
				_sender, //the sender aka owner
				colours,
				mintData,
				assets,
				names,
				destinations
			);
	}

	/// @notice basically unpacks a return object into bytes.
	function encode(InfinityObject memory data)
		internal
		pure
		returns (bytes memory)
	{
		return
			abi.encode(
				data.pathId,
				data.pathSize,
				data.currentTokenId,
				data.owner,
				abi.encode(data.colours),
				data.mintData,
				data.assets,
				data.names,
				data.destinations
			);
	}

	/// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
	function sender() internal view returns (address) {
		return (msg.sender);
	}

	/// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
	function value() internal view returns (uint256) {
		return (msg.value);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";
import "./Authentication.sol";

/// @title InfinityMint storage controller
/// @author Llydia Cross
/// @notice Stores the outcomes of the mint process and previews and also unlock keys
/// @dev Attached to to an InfinityMint
contract InfinityMintStorage is Authentication, InfinityMintObject {
	/// @notice previews
	mapping(address => mapping(uint256 => InfinityObject)) public previews;
	/// @notice previews timestamps of when new previews can be made
	mapping(address => uint256) public previewTimestamp;
	/// @notice all of the token data
	mapping(uint32 => InfinityObject) private tokens;
	/// @notice Address flags can be toggled and effect all of the tokens
	mapping(address => mapping(string => bool)) private flags;
	/// @notice a list of tokenFlags associated with the token
	mapping(uint256 => mapping(string => bool)) public tokenFlags;
	/// @notice a list of options
	mapping(address => mapping(string => string)) private options;
	/// @notice private mapping holding a list of tokens for owned by the address for quick look up
	mapping(address => uint32[]) private registeredTokens;

	/// @notice returns true if the address is preview blocked and unable to receive more previews
	function getPreviewTimestamp(address addr) external view returns (uint256) {
		return previewTimestamp[addr];
	}

	/// @notice sets a time in the future they an have more previews
	function setPreviewTimestamp(address addr, uint256 timestamp)
		public
		onlyApproved
	{
		require(timestamp > block.timestamp, "timestamp must be in the future");
		previewTimestamp[addr] = timestamp;
	}

	/**
		@notice Returns true if address in destinations array is valid,
		destinations array is managed by InfinityMintLinker and i used to associate contract destinations on chain with a token
	*/
	function hasDestinaton(uint32 tokenId, uint256 index)
		external
		view
		returns (bool)
	{
		return
			tokens[tokenId].destinations.length < index &&
			tokens[tokenId].destinations[index] != address(0x0);
	}

	/// @notice Allows those approved with the contract to directly force a token flag. The idea is a seperate contract would control immutable this way
	/// @dev NOTE: This can only be called by contracts to curb rugging potential
	function forceTokenFlag(
		uint256 tokenId,
		string memory _flag,
		bool position
	) public onlyApproved {
		tokenFlags[tokenId][_flag] = position;
	}

	//// @notice Allows the current token owner to toggle a flag on the token, for instance, locked flag being true will mean token cannot be transfered
	function setTokenFlag(
		uint256 tokenId,
		string memory _flag,
		bool position
	) public onlyApproved {
		require(this.flag(tokenId, "immutable") != true, "token is immutable");
		require(
			!InfinityMintUtil.isEqual(bytes(_flag), "immutable"),
			"token immutable/mutable state cannot be modified this way for security reasons"
		);
		tokenFlags[tokenId][_flag] = position;
	}

	/// @notice returns the value of a flag
	function flag(uint256 tokenId, string memory _flag)
		external
		view
		returns (bool)
	{
		return tokenFlags[tokenId][_flag];
	}

	/// @notice sets an option for a users tokens
	/// @dev this is used for instance inside of tokenURI
	function setOption(
		address addr,
		string memory key,
		string memory option
	) public onlyApproved {
		options[addr][key] = option;
	}

	/// @notice deletes an option
	function deleteOption(address addr, string memory key) public onlyApproved {
		delete options[addr][key];
	}

	/// @notice returns a global option for all the addresses tokens
	function getOption(address addr, string memory key)
		external
		view
		returns (string memory)
	{
		return options[addr][key];
	}

	//// @notice Allows the current token owner to toggle a flag on the token, for instance, locked flag being true will mean token cannot be transfered
	function setFlag(
		address addr,
		string memory _flag,
		bool position
	) public onlyApproved {
		flags[addr][_flag] = position;
	}

	function tokenFlag(uint32 tokenId, string memory _flag)
		external
		view
		returns (bool)
	{
		return tokenFlags[tokenId][_flag];
	}

	function validDestination(uint32 tokenId, uint256 index)
		external
		view
		returns (bool)
	{
		return (tokens[tokenId].owner != address(0x0) &&
			tokens[tokenId].destinations.length != 0 &&
			index < tokens[tokenId].destinations.length &&
			tokens[tokenId].destinations[index] != address(0x0));
	}

	/// @notice returns the value of a flag
	function flag(address addr, string memory _flag)
		external
		view
		returns (bool)
	{
		return flags[addr][_flag];
	}

	/// @notice returns address of the owner of this token
	/// @param tokenId the tokenId to get the owner of
	function getOwner(uint32 tokenId) public view returns (address) {
		return tokens[tokenId].owner;
	}

	/// @notice returns an integer array containing the token ids owned by the owner address
	/// @dev NOTE: This will only track 256 tokens
	/// @param owner the owner to look for
	function getAllRegisteredTokens(address owner)
		public
		view
		returns (uint32[] memory)
	{
		return registeredTokens[owner];
	}

	/// @notice this method adds a tokenId from the registered tokens list which is kept for the owner. these methods are designed to allow limited data retrival functionality on local host environments
	/// @dev for local testing purposes mostly, to make it scalable the length is capped to 128. Tokens should be indexed by web2 server not on chain.
	/// @param owner the owner to add the token too
	/// @param tokenId the tokenId to add
	function addToRegisteredTokens(address owner, uint32 tokenId)
		public
		onlyApproved
	{
		//if the l
		if (registeredTokens[owner].length < 256)
			registeredTokens[owner].push(tokenId);
	}

	/// @notice Gets the amount of registered tokens
	/// @dev Tokens are indexable instead by their current positon inside of the owner wallets collection, returns a tokenId
	/// @param owner the owner to get the length of
	function getRegisteredTokenCount(address owner)
		public
		view
		returns (uint256)
	{
		return registeredTokens[owner].length;
	}

	/// @notice returns a token
	/// @dev returns an InfinityObject defined in {InfinityMintObject}
	/// @param tokenId the tokenId to get
	function get(uint32 tokenId) public view returns (InfinityObject memory) {
		if (tokens[tokenId].owner == address(0x0)) revert("invalid token");

		return tokens[tokenId];
	}

	/// @notice Sets the owner field in the token to another value
	function transfer(address to, uint32 tokenId) public onlyApproved {
		//set to new owner
		tokens[tokenId].owner = to;
	}

	function set(uint32 tokenId, InfinityObject memory data)
		public
		onlyApproved
	{
		require(data.owner != address(0x0), "null owner");
		require(data.currentTokenId == tokenId, "tokenID mismatch");
		tokens[tokenId] = data;
	}

	/// @notice use normal set when can because of the checks it does before the set, this does no checks
	function setUnsafe(uint32 tokenId, bytes memory data) public onlyApproved {
		tokens[tokenId] = abi.decode(data, (InfinityObject));
	}

	function setPreview(
		address owner,
		uint256 index,
		InfinityObject memory data
	) public onlyApproved {
		previews[owner][index] = data;
	}

	function getPreviewAt(address owner, uint256 index)
		external
		view
		returns (InfinityObject memory)
	{
		require(
			previews[owner][index].owner != address(0x0),
			"invalid preview"
		);

		return previews[owner][index];
	}

	function findPreviews(address owner, uint256 previewCount)
		public
		view
		onlyApproved
		returns (InfinityObject[] memory)
	{
		InfinityObject[] memory temp = new InfinityObject[](previewCount);
		for (uint256 i = 0; i < previewCount; ) {
			temp[i] = previews[owner][i];

			unchecked {
				++i;
			}
		}

		return temp;
	}

	function deletePreview(address owner, uint256 previewCount)
		public
		onlyApproved
	{
		for (uint256 i = 0; i < previewCount; ) {
			delete previews[owner][i];

			unchecked {
				++i;
			}
		}

		delete previewTimestamp[owner];
	}

	/// @notice this method deletes a tokenId from the registered tokens list which is kept for the owner. these methods are designed to allow limited data retrival functionality on local host environments
	/// @dev only works up to 256 entrys, not scalable
	function deleteFromRegisteredTokens(address sender, uint32 tokenId)
		public
		onlyApproved
	{
		if (registeredTokens[sender].length - 1 <= 0) {
			registeredTokens[sender] = new uint32[](0);
			return;
		}

		uint32[] memory newArray = new uint32[](
			registeredTokens[sender].length - 1
		);
		uint256 index = 0;
		for (uint256 i = 0; i < registeredTokens[sender].length; ) {
			if (index == newArray.length) break;
			if (tokenId == registeredTokens[sender][i]) {
				unchecked {
					++i;
				}
				continue;
			}

			newArray[index++] = registeredTokens[sender][i];

			unchecked {
				++i;
			}
		}

		registeredTokens[sender] = newArray;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

library InfinityMintUtil {
	function toString(uint256 _i)
		internal
		pure
		returns (string memory _uintAsString)
	{
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function filepath(
		string memory directory,
		string memory file,
		string memory extension
	) internal pure returns (string memory) {
		return
			abi.decode(abi.encodePacked(directory, file, extension), (string));
	}

	//checks if two strings (or bytes) are equal
	function isEqual(bytes memory s1, bytes memory s2)
		internal
		pure
		returns (bool)
	{
		bytes memory b1 = bytes(s1);
		bytes memory b2 = bytes(s2);
		uint256 l1 = b1.length;
		if (l1 != b2.length) return false;
		for (uint256 i = 0; i < l1; i++) {
			//check each byte
			if (b1[i] != b2[i]) return false;
		}
		return true;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

contract InfinityMintValues {
	mapping(string => uint256) private values;
	mapping(string => bool) private booleanValues;
	mapping(string => bool) private registeredValues;

	address deployer;

	constructor() {
		deployer = msg.sender;
	}

	modifier onlyDeployer() {
		if (msg.sender != deployer) revert();
		_;
	}

	function setValue(string memory key, uint256 value) public onlyDeployer {
		values[key] = value;
		registeredValues[key] = true;
	}

	function setupValues(
		string[] memory keys,
		uint256[] memory _values,
		string[] memory booleanKeys,
		bool[] memory _booleanValues
	) public onlyDeployer {
		require(keys.length == _values.length);
		require(booleanKeys.length == _booleanValues.length);
		for (uint256 i = 0; i < keys.length; i++) {
			setValue(keys[i], _values[i]);
		}

		for (uint256 i = 0; i < booleanKeys.length; i++) {
			setBooleanValue(booleanKeys[i], _booleanValues[i]);
		}
	}

	function setBooleanValue(string memory key, bool value)
		public
		onlyDeployer
	{
		booleanValues[key] = value;
		registeredValues[key] = true;
	}

	function isTrue(string memory key) external view returns (bool) {
		return booleanValues[key];
	}

	function getValue(string memory key) external view returns (uint256) {
		if (!registeredValues[key]) revert("Invalid Value");

		return values[key];
	}

	/// @dev Default value it returns is zero
	function tryGetValue(string memory key) external view returns (uint256) {
		if (!registeredValues[key]) return 0;

		return values[key];
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

interface IntegrityInterface {
	/**
		@notice Verifys that a deployed contract matches the one we want.
	 */
	function getIntegrity()
		external
		returns (
			address from,
			address owner,
			uint256 tokenId,
			bytes memory versionType,
			bytes4 intefaceId
		);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./../InfinityMintObject.sol";
import "./../InfinityMintLinker.sol";
import "./../ERC721.sol";
import "./../Authentication.sol";

contract Mod_CloneMachineOracle is Authentication, InfinityMintObject {
	mapping(uint256 => address[]) internal heldMinters;

	function addPermissions(uint256 cloneId, address[] memory addresses)
		public
		onlyApproved
	{
		require(addresses.length > 0, "no addresses given");
		heldMinters[cloneId] = new address[](addresses.length);
		for (uint256 i = 0; i < addresses.length; ) {
			require(
				Authentication(addresses[i]).deployer() == address(this),
				"one or more addresses still needs its privillages transfered to this contract"
			);

			heldMinters[cloneId][i] = addresses[i];
			unchecked {
				++i;
			}
		}
	}

	function transferPermissions(uint256 cloneId, address newOwner)
		public
		onlyApproved
	{
		require(heldMinters[cloneId].length != 0, "bad clone id");

		for (uint256 i = 0; i < heldMinters[cloneId].length; ) {
			Authentication(heldMinters[cloneId][i]).transferOwnership(newOwner);
			unchecked {
				++i;
			}
		}

		delete heldMinters[cloneId];
	}
}