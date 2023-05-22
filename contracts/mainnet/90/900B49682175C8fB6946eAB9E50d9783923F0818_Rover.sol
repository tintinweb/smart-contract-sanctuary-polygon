// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
* @title Interface defining a contract that should manage multiple exchange-oracles
*/
interface IOracleManager {
    /**
    * @notice Function used to exchange currencies
    * @param srcToken The currency to be exchanged
    * @param dstToken The currency to be exchanged for
    * @param amountIn The amount of currency to be exchanged
    * @return The resulting amount of dstToken
    */
    function getAmountOut(
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) external returns (uint256);

    /**
    * @notice Function used to see the current exchange amount
    * @param srcToken The currency to be exchanged
    * @param dstToken The currency to be exchanged for
    * @param amountIn The amount of currency to be exchanged
    * @return The resulting amount of dstToken
    */
    function getAmountOutView(
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) external view returns (uint256);
}

pragma solidity ^0.8.0;


// @title Watered down version of IAssetManager, to be used for Gravity Grade
interface ITrustedMintable {

    error TM__NotTrusted(address _caller);
    /**
    * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens. MUST be ignored on ERC-721
     * @param _amount Number of tokens to mint
     *
     * Throws TM_NotTrusted on caller not being trusted
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens MUST be ignored on ERC-721
     * @param _amounts Number of tokens to mint
     *
     * Throws TM_NotTrusted on caller not being trusted
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev Encode and decode base64 url
 * @author hiromin <[email protected]>
 */
library Base64Url {
    /**
     * @dev Base64Url Encoding/Decoding Table
     */
    string internal constant ENCODING_TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    /**
        @dev fast way to calculate this index table in python:
               encode_table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
               table = [None] * 256
               for i in range(len(encode_table)): # len = 64
                   table[ord(encode_table[i])] = bytes([i]).hex()
     */
    bytes internal constant DECODING_TABLE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"000000000000000000000000003e00403435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f10111213141516171819000000003f"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Load the table into memory
        string memory table = ENCODING_TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        // @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }

    function decode(string memory base64Url)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory data = bytes(base64Url);

        require(data.length > 0, "Invalid base64 string");

        if (data.length == 0) return "";

        // When decoding base64 string, 4 characters are converted back to 3 bytes, skip padding "="
        uint256 decodedLength = (data.length / 4) * 3;

        if (data[data.length - 1] == "=") {
            decodedLength--;
            if (data[data.length - 2] == "=") decodedLength--;
        }

        // Load the table into memory
        bytes memory table = DECODING_TABLE;

        bytes memory result = new bytes(decodedLength);

        // @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 4 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 4 bytes
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract VRFConsumerBaseV2Upgradable is Initializable {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    function __VRFConsumerBaseV2_init(address _vrfCoordinator) internal initializer {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMCCrosschainServices {
    function getNewlandsGenesisBalance(address _user) external view returns (uint256);

    function getYGenesisBalance(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IMissionControlStakeable.sol";

/// @title Interface defining the mission control
/// @dev This defines only essential functionality and not admin functionality
interface IMissionControl {
    error MC__InvalidCoordinates();
    error MC__NotWhitelisted();
    error MC__InvalidSigner();
    error MC__InvalidStreamer();
    error MC__TileNotRented();
    error MC__TilePaused();
    error MC__NoTileContractStaked();
    error MC__InvalidSuperToken();
    error MC__InvalidFlow();
    error MC__TileRentedWithDifferentSuperToken();
    error MC__SenderNotStreamerNorCrosschain();
    error MC__SenderNotTCLockProvider();
    error MC__TileRented();
    error MC__BaseStaked();
    error MC__InvalidPlacement();
    error MC__DuplicateTech();
    error MC__TileEmpty();
    error MC__TopStaked();
    error MC__ZeroRadius();
    error MC__ZeroAddress();

    /**
     * @notice This is a struct which contains information regarding a tile element
     * @param steakeable Address for the stakeable token on the tile
     * @param tokenId Id of the staked token
     * @param nonce Staking nonce
     * @param staked Boolean defining whether the token is actively staked, used as opposed to clearing the previous two on unstaking.
     */
    struct TileElement {
        address stakeable;
        uint256 tokenId;
        uint256 nonce;
    }

    struct TileRentalInfo {
        bool isRented;
        uint256 pausedAt;
        address rentalToken;
    }

    struct TileRequirements {
        uint256 price;
        uint256 tileContractId;
    }

    /**
     * @notice Struct to hold instructions for tile resource collection
     * @param x X-coordinate of tile
     * @param y Y-coordinate of tile
     * @param z Z-coordinate of tile
     */
    struct CollectOrder {
        int256 x;
        int256 y;
        int256 z;
    }

    /**
     * @notice Struct to hold instructions for placing NFTs on tiles
     * @param x X-coordinate of tile
     * @param y Y-coordinate of tile
     * @param z Z-coordinate of tile
     * @param tokenId Token ID of NFT
     * @param tokenAddress Address of NFT, which is presumed to implement the IMissionControlStakeable interface
     */
    struct PlaceOrder {
        CollectOrder order;
        uint256 tokenId;
        address tokenAddress;
    }

    struct HandleTopPlacementArgs {
        int256 x;
        int256 y;
        uint256 tokenId;
        address stakeable;
        uint256 nonce;
        address staker;
    }

    struct RemoveNFTVars {
        uint256 zeroOrOne;
        uint256 tokenId;
        address stakeable;
    }

    struct TotalTileInfo {
        CollectOrder order;
        bool isRented;
        uint256 flowRate;
        address rentalToken;
        int256 timeLeftBottom;
        int256 timeLeftTop1;
        int256 timeLeftTop2;
        TileElement base;
        TileElement top1;
        TileElement top2;
    }

    struct TotalCheckTileInfo {
        CollectOrder order;
        CheckTileOutputs out;
    }

    struct CheckTileInputs {
        address user;
        int256 x;
        int256 y;
        int256 z;
    }

    struct CheckTileOutputs {
        uint256 bottomAmount;
        uint256 bottomId;
        uint256 topAmount1;
        uint256 topId1;
        uint256 topAmount2;
        uint256 topId2;
    }

    struct HandleRaidCollectInputs {
        address defender;
        int256 x;
        int256 y;
    }

    struct HandleRaidCollectVars {
        TileElement tileElement;
        TileRentalInfo tileRentalInfo;
        IMissionControlStakeable iStakeable;
    }

    struct HandleCollectInputs {
        int256 x;
        int256 y;
        int256 z;
        uint256 position;
    }

    struct HandleCollectVars {
        TileElement tileElement;
        TileRentalInfo tileRentalInfo;
    }

    struct UpdateRentTileVars {
        int96 requiredFlow;
        uint256 index;
        uint256 size;
        uint256 removeTileLength;
        TileRentalInfo tile;
        CollectOrder removeTileItem;
        CollectOrder order;
    }

    struct GetAllCheckTileInfoVars {
        uint256 amount;
        uint256 tokenId;
        uint256 count;
        uint256 totalTiles;
        int256 radius;
    }

    struct CollectFromTilesVars {
        uint256 arrayLen;
        uint256[] ids;
        uint256[] amounts;
        uint256 cId;
        uint256 cAmount;
    }

    /**
     * @notice Stakes multiple NFTs on various tiles in one transaction
     * @param _placeOrders Array of structs containing information regarding where to place what
     * @dev Any downside to using structs as an argument?
     */
    function placeNFTs(PlaceOrder[] calldata _placeOrders) external;

    /**
     * @notice Removes multiple NFTs on various tiles in one transaction
     * @param orders Array of structs containing information regarding where to remove something
     * @dev Token id, address are ignored
     */
    function removeNFTs(
        CollectOrder[] memory orders,
        uint256[] memory positions,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Queries a tile regarding the resources which are able to collected from it at the current moment
     * @dev Add support for multiple types of tokens, i.e return would be an array?
     */
    function checkTile(CheckTileInputs memory c) external view returns (CheckTileOutputs memory out);

    /**
     * @notice Collects (mints) tokens from tiles
     * @dev An alternative worth considering would be to have an alternative mint function
     * @param _orders Array containing collect orders
     * @dev Any downside to using structs as an argument?
     */
    function collectFromTiles(
        CollectOrder[] calldata _orders,
        uint256[] memory _positions,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Used to check what a user has staked on a tile
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     */
    function checkStakedOnTile(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z
    ) external view returns (TileElement memory _base, TileElement memory _top1, TileElement memory _top2);

    /**
     * @notice Returns when the tile was last updated
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     * @return _timestamp The time in blockchain seconds
     */
    function checkLastUpdated(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z,
        uint256 _position
    ) external view returns (uint256 _timestamp);

    /**
     * @notice returns the remaining time until a tile is filled
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     */
    function timeLeft(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z
    ) external view returns (int256 _timeLeftBottom, int256 _timeLeftTop1, int256 _timeLeftTop2);

    // user start streaming to the game
    function createRentTiles(
        address supertoken,
        address renter,
        CollectOrder[] memory tiles, // changed to PlaceOrder so that it inclues tokenId and token Address
        int96 flowRate
    ) external;

    // user is streaming and change the rented tiles
    function updateRentTiles(
        address supertoken,
        address renter,
        CollectOrder[] memory addTiles,
        CollectOrder[] memory removeTiles,
        int96 oldFlowRate,
        int96 flowRate
    ) external;

    function toggleTile(address _renter, int256 _x, int256 _y, uint256 rad, bool _shouldPause) external;

    // user stop streaming to the game
    function deleteRentTiles(address supertoken, address renter) external;

    function getAllowedRadius() external view returns (uint256);

    function getTileRentalInfo(address _user, int256 _x, int256 _y) external view returns (TileRentalInfo memory _info);

    function getTileRequirements(int256 _x, int256 _y) external view returns (TileRequirements memory _requirements);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Interface defining a contract which can be staked upon a "tile" in the mission control
interface IMissionControlStakeable {
    enum Rings {
        Apollo,
        Artemis,
        Chronos,
        Helios
    }

    struct CheckTileInputs {
        uint256 tokenId;
        uint256 localSeed;
        uint256 blockTime;
        uint256 elapsed;
        uint256 ret;
    }

    struct ResourceParams {
        uint tier;
        uint256 resourceEV;
        uint256 resourceId;
        uint256 resourceCap;
        bool isBase;
        bool isRaidable;
        uint256 ring;
    }

    struct ResourceParamOut {
        int256 x;
        int256 y;
        int256 z;
        bool isBase;
        bool isRaidable;
        uint256 resourceEV;
        uint256 resourceId;
        uint256 resourceCap;
    }

    struct RingParams {
        int x;
        int y;
        uint ring;
    }

    struct Request {
        address user;
        uint256 m3tam0dChance;
        uint256 tokenId;
    }
    /**
     * @notice Event emitted when a token is staked
     * @param _userAddress address of the staker
     * @param _stakeable Address to either the IMCStakeable implementation or the possibly the underlying token?
     * @param _tokenId Token id which has been staked
     */
    event TokenClaimed(address _userAddress, address _stakeable, uint256 _tokenId);
    /**
     * @notice Event emitted when a token is unstaked
     * @param _userAddress address of the staker
     * @param _stakeable Address to either the IMCStakeable implementation or the possibly the underlying token?
     * @param _tokenId Token id which has been unstaked
     */
    event TokenReturned(address _userAddress, address _stakeable, uint256 _tokenId);

    /**
     * @notice Event emitted when the mission control is set
     * @param missionControl The address of the mission control
     */
    event MissionControlSet(address missionControl);

    /**
     * @notice Resets the seed of a staked token. A cheaper alternative to onCollect when you do not need the number of harvested tokens
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     */
    function reset(address _userAddress, uint256 _nonce) external;

    /**
     * @notice Function to check the number of tokens ready to be harvested from this tile
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _amount Number of tokens that can be collected
     * @return _retTokenId The tokenId of the tokens that can be collected
     */
    function checkTile(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) external view returns (uint256 _amount, uint256 _retTokenId);

    /**
     * @notice Used to fetch new seed time upon collection some resources
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _amount Number of tokens that can be collected
     * @return _retTokenId The tokenId of the tokens that can be collected
     * @dev It is vital for this function to update the rng
     */
    function onCollect(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) external returns (uint256 _amount, uint256 _retTokenId);

    /**
     * @notice Used to see if the token can be used as the base of a tile, or if it is meant to be staked upon another token
     * @param _tokenId The id of the token
     * @return _isBase Whether this token is a base or not
     */
    function isBase(uint256 _tokenId, int256 _x, int256 _y) external view returns (bool _isBase);

    function isRaidable(uint256 _tokenId, int256 _x, int256 _y) external view returns (bool _isRaidable);

    /**
     * @notice transfers ownership of a token from the player to the stakeable contract
     * @param _currentOwner Address of the current owner
     * @param _tokenId The id of the token
     * @param _nonce Tile-staking nonce
     * @param _underlyingToken todo
     * @param _underlyingTokenId todo
     */
    function onStaked(
        address _currentOwner,
        uint256 _tokenId,
        uint256 _nonce,
        address _underlyingToken,
        uint256 _underlyingTokenId,
        address _besideToken,
        uint256 _besideTokenId,
        uint256 _besideNonce,
        int256 _x,
        int256 _y
    ) external;

    function onResume(address _renter, uint256 _nonce) external;

    /**
     * @notice transfers ownership of a token from the stakeable contract back to the player
     * @param _newOwner Address of the soon-to-be owner
     * @param _nonce Tile-staking nonce
     */
    function onUnstaked(address _newOwner, uint256 _nonce, uint256 _besideNonce) external;

    function checkTimestamp(address _userAddress, uint256 _nonce) external view returns (uint256 _timestamp);

    /**
     * @notice returns the remaining time until a tile is filled
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _timeLeft The time left, -1 if the time can not be predicted
     */
    // note: removed tokenId as a param. was unused
    function timeLeft(
        address _userAddress,
        uint256 _nonce,
        int256 _x,
        int256 _y
    ) external view returns (int256 _timeLeft);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRover {
    error Rover__ZeroAddress();
    error Rover__NotOwner();
    error Rover__NotOracle();
    error Rover__IncorrectStatus(uint256 from);
    error Rover__InvalidSkin(uint256 skin);
    error Rover__MaxSupplyReached();
    error Rover__PaymentTooLow();
    error Rover__NotMC();
    error Rover__NoKeyHash();
    error Rover__SaleNotOpen();
    error Rover__WrongPayToken();
    error Rover__WrongPayTokenOrStatus();
    error Rover__InvalidArguments();

    enum Status {
        Pristine,
        Worn,
        Damaged,
        Wrecked
    }

    enum Color {
        Night,
        Genesis,
        Piercer
    }

    struct RoverInfo {
        string name;
        Color color;
        Status status;
        uint256 skin;
    }

    struct YGenesisRepairInfo {
        uint tokenId;
        int256 x;
        int256 y;
        int256 z;
    }

    enum PayableToken {
        IXT,
        AstroCredits,
        USDT,
        Matic
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOracleManager.sol";
import "../interfaces/ITrustedMintable.sol";
import "../libraries/VRFConsumerBaseV2Upgradable.sol";
import "../mission_control/IMCCrosschainServices.sol";
import "../mission_control/IMissionControlStakeable.sol";
import "../mission_control/IMissionControl.sol";
import "./RoverHelper.sol";
import "./IRover.sol";

contract Rover is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    VRFConsumerBaseV2Upgradable,
    ITrustedMintable,
    IRover
{
    IERC20Upgradeable public IXT;
    IERC1155Upgradeable public astroCredits;
    IERC20 public USDT;

    uint256 acTokenId;

    IOracleManager s_oracle;

    VRFCoordinatorV2Interface public COORDINATOR;
    mapping(uint256 => address) public s_requests;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint64 subscriptionId;

    uint256 MAX_SUPPLY;

    string[] public uris;
    mapping(uint256 => uint256) public ixtSkinPrices; // not used
    mapping(uint256 => uint256) public acSkinPrices; // not used
    mapping(uint256 => RoverInfo) public rovers;

    uint256 ixtNamePrice; // not used
    uint256 acNamePrice; // not used

    uint256 ixtRepairWornPrice; // not used
    uint256 ixtRepairDamagedPrice; // not used

    uint256 acRepairWornPrice; // not used
    uint256 acRepairDamagedPrice; // not used

    address public missionControl;

    mapping(address => bool) trusted;

    bool public saleOpen;

    mapping(PayableToken => mapping(Status => uint256)) repairPrice;
    mapping(PayableToken => mapping(uint256 => uint256)) skinPrice;
    mapping(PayableToken => uint256) namePrice;

    uint256 public purchaseUSDTprice;
    IMCCrosschainServices public crosschainServices;
    IMissionControlStakeable public roverAdapter;
    RoverHelper public roverHelper;

    /** Events **/
    event NewRover(address indexed to, uint256 indexed tokenId, Color color);
    event Repaired(uint256 indexed tokenId, Status status);
    event Named(uint256 indexed tokenId, string name);
    event NewSkin(uint256 indexed tokenId, uint256 _skin);
    event Breakdown(uint256 indexed tokenId, Status to);

    modifier trustedOnly() {
        if (!trusted[msg.sender]) revert TM__NotTrusted(msg.sender);
        _;
    }

    modifier onlyRoverAdapter() {
        if (msg.sender != address(roverAdapter)) revert Rover__NotMC();
        _;
    }

    function initialize(
        string calldata uri,
        address _missionControl,
        address _s_oracle,
        address _vrfCoordinator,
        address _USDT,
        address _IXT,
        address _astroCredits,
        uint256 _acTokenId
    ) public initializer {
        __ERC721_init("Rover", "ROVER");
        __Ownable_init();
        __ERC1155Holder_init();
        uris.push(uri);

        if (_missionControl == address(0)) revert Rover__ZeroAddress();
        if (_USDT == address(0)) revert Rover__ZeroAddress();
        if (_IXT == address(0)) revert Rover__ZeroAddress();
        if (_astroCredits == address(0)) revert Rover__ZeroAddress();

        setOracleManager(_s_oracle);

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        __VRFConsumerBaseV2_init(_vrfCoordinator);

        USDT = IERC20(_USDT);
        IXT = IERC20Upgradeable(_IXT);
        astroCredits = IERC1155Upgradeable(_astroCredits);
        acTokenId = _acTokenId;

        // ixtNamePrice = 25 ether;
        // acNamePrice = 1000 ether;

        MAX_SUPPLY = 500_000;
    }

    /** Prices **/
    function _transferERCTokens(PayableToken payToken, uint256 amount) internal {
        if (payToken == PayableToken.IXT) {
            IXT.transferFrom(msg.sender, address(this), amount);
        } else if (payToken == PayableToken.AstroCredits) {
            astroCredits.safeTransferFrom(msg.sender, address(this), acTokenId, amount, "");
        } else if (payToken == PayableToken.USDT) {
            USDT.transferFrom(msg.sender, address(this), amount);
        } else {
            revert Rover__WrongPayToken();
        }
    }

    function setRepairPrice(PayableToken _payToken, Status _roverStatus, uint256 _newPrice) external onlyOwner {
        repairPrice[_payToken][_roverStatus] = _newPrice;
    }

    function getRepairPrice(PayableToken _payToken, Status _roverStatus) public view returns (uint256) {
        if (repairPrice[_payToken][_roverStatus] == 0) {
            revert Rover__WrongPayTokenOrStatus();
        }
        return repairPrice[_payToken][_roverStatus];
    }

    function setPurchaseUSDTprice(uint256 _purchaseUSDTprice) external onlyOwner {
        purchaseUSDTprice = _purchaseUSDTprice;
    }

    function getPurchasePrice(PayableToken _payToken) external view returns (uint256) {
        if (_payToken == PayableToken.USDT) {
            return purchaseUSDTprice;
        } else if (_payToken == PayableToken.Matic) {
            return s_oracle.getAmountOutView(address(USDT), address(0), purchaseUSDTprice);
        } else if (_payToken == PayableToken.IXT) {
            uint256 wmaticAmount = s_oracle.getAmountOutView(address(USDT), address(0), purchaseUSDTprice);
            return s_oracle.getAmountOutView(address(0), address(IXT), wmaticAmount);
        } else {
            revert Rover__WrongPayToken();
        }
    }

    function _getPurchasePriceAndUpdate(PayableToken _payToken) internal returns (uint256) {
        if (_payToken == PayableToken.USDT) {
            return purchaseUSDTprice;
        } else if (_payToken == PayableToken.Matic) {
            return s_oracle.getAmountOut(address(USDT), address(0), purchaseUSDTprice);
        } else if (_payToken == PayableToken.IXT) {
            uint256 wmaticAmount = s_oracle.getAmountOut(address(USDT), address(0), purchaseUSDTprice);
            return s_oracle.getAmountOut(address(0), address(IXT), wmaticAmount);
        } else {
            revert Rover__WrongPayToken();
        }
    }

    function setNamePrice(PayableToken _payToken, uint256 _newPrice) external onlyOwner {
        namePrice[_payToken] = _newPrice;
    }

    function getNamePrice(PayableToken _payToken) public view returns (uint256) {
        if (namePrice[_payToken] == 0) {
            revert Rover__WrongPayToken();
        }
        return namePrice[_payToken];
    }

    function setSkinPrice(PayableToken _payToken, uint256 _skinId, uint256 _newPrice) external onlyOwner {
        skinPrice[_payToken][_skinId] = _newPrice;
    }

    function getSkinPrice(PayableToken _payToken, uint256 _skinId) public view returns (uint256) {
        if (skinPrice[_payToken][_skinId] == 0) {
            revert Rover__InvalidSkin(_skinId);
        }
        return skinPrice[_payToken][_skinId];
    }

    function getTokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 len = balanceOf(owner);
        uint256[] memory tokens = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    /** Minting **/
    /**
     * @notice Pay for rover with USDT and submit a VRF request
     * @param amount The number of rovers to mint
     */
    function purchaseWithUSDT(uint32 amount) public returns (uint256 requestId) {
        return _purchaseRover(PayableToken.USDT, amount);
    }

    /**
     * @notice Pay for rover with MATIC and submit a VRF request
     * @param amount The number of rovers to mint
     */
    function purchaseWithMatic(uint32 amount) public payable returns (uint256 requestId) {
        return _purchaseRover(PayableToken.Matic, amount);
    }

    /**
     * @notice Pay for rover with IXT and submit a VRF request
     * @param amount The number of rovers to mint
     */
    function purchaseWithIXT(uint32 amount) public returns (uint256 requestId) {
        return _purchaseRover(PayableToken.IXT, amount);
    }

    function _purchaseRover(PayableToken _payToken, uint32 amount) internal returns (uint256 requestId) {
        if (_payToken == PayableToken.Matic) {
            if (msg.value < amount * _getPurchasePriceAndUpdate(_payToken)) {
                revert Rover__PaymentTooLow();
            }
        } else {
            _transferERCTokens(_payToken, amount * _getPurchasePriceAndUpdate(_payToken));
        }

        return _vrfRequest(amount);
    }

    function _vrfRequest(uint32 amount) internal returns (uint256 requestId) {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert Rover__MaxSupplyReached();
        }
        if (!saleOpen) {
            revert Rover__SaleNotOpen();
        }
        if (keyHash == bytes32(0)) {
            revert Rover__NoKeyHash();
        }

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            amount
        );
        s_requests[requestId] = msg.sender;
    }

    /**
     * @notice Function for satisfying randomness requests from minting
     * @param requestId The particular request being serviced
     * @param randomWords Array of the random numbers requested
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address to = s_requests[requestId];
        uint256 length = randomWords.length;
        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = totalSupply();
            uint256 randomWord = randomWords[i] % 100;
            Color color;
            if (randomWord < 89) {
                color = Color.Piercer;
            } else if (randomWord < 99) {
                color = Color.Genesis;
            } else {
                color = Color.Night;
            }
            rovers[tokenId] = RoverInfo({name: "", color: Color(color), status: Status.Pristine, skin: 0});
            _safeMint(to, tokenId);
            emit NewRover(to, tokenId, color);
            unchecked {
                ++i;
            }
        }
        delete s_requests[requestId];
    }

    /** Token URIs **/
    function description(Color color) public view returns (string memory) {
        return roverHelper.description(color);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        RoverInfo memory rover = rovers[tokenId];
        return roverHelper.tokenURI(rover, uris[0], uris[rover.skin]);
    }

    function addUri(string calldata uri) public onlyOwner {
        uris.push(uri);
    }

    function addSkin(string memory uri, uint256 ixtPrice, uint256 acPrice) public onlyOwner {
        uris.push(uri);
        skinPrice[PayableToken.IXT][uris.length - 1] = ixtPrice;
        skinPrice[PayableToken.AstroCredits][uris.length - 1] = acPrice;
    }

    /** Repairs **/
    function _repairBatch(PayableToken payToken, uint256[] calldata _tokenIds) internal {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            if (rovers[tokenId].status != Status.Worn && rovers[tokenId].status != Status.Damaged) {
                revert Rover__IncorrectStatus(uint256(rovers[tokenId].status));
            }
            totalPrice += getRepairPrice(payToken, rovers[tokenId].status);

            rovers[tokenId].status = Status.Pristine;
            emit Repaired(tokenId, Status.Pristine);
        }

        _transferERCTokens(payToken, totalPrice);
    }

    function repairBatchIXT(uint256[] calldata _tokenIds) external {
        _repairBatch(PayableToken.IXT, _tokenIds);
    }

    function repairBatchAC(uint256[] calldata _tokenIds) external {
        _repairBatch(PayableToken.AstroCredits, _tokenIds);
    }

    function repairBatchYGenesis(YGenesisRepairInfo[] memory repairs) external {
        require(crosschainServices.getYGenesisBalance(msg.sender) != 0, "ROVER: NO_Y_GENESIS_BALANCE");
        for (uint256 i = 0; i < repairs.length; i++) {
            uint tokenToRepair;
            if (ownerOf(repairs[i].tokenId) == msg.sender) {
                tokenToRepair = repairs[i].tokenId;
            } else {
                (, IMissionControl.TileElement memory top1, IMissionControl.TileElement memory top2) = IMissionControl(
                    missionControl
                ).checkStakedOnTile(msg.sender, repairs[i].x, repairs[i].y, repairs[i].z);

                if (top1.stakeable == address(roverAdapter)) tokenToRepair = top1.tokenId;
                else if (top2.stakeable == address(roverAdapter)) tokenToRepair = top2.tokenId;
                else revert("ROVER: NO_ROVER_ON_THIS_TILE");
            }

            if (rovers[tokenToRepair].status != Status.Worn && rovers[tokenToRepair].status != Status.Damaged) {
                revert Rover__IncorrectStatus(uint256(rovers[tokenToRepair].status));
            }
            rovers[tokenToRepair].status = Status.Pristine;
            emit Repaired(tokenToRepair, Status.Pristine);
        }
    }

    function breakdown(uint256 tokenId, uint256 to) external onlyRoverAdapter {
        if (to > uint(Status.Wrecked)) return;
        rovers[tokenId].status = Status(to);
        emit Breakdown(tokenId, Status(to));
    }

    /** Set Name **/
    function setNameWithIXT(uint256 tokenId, string memory name) public {
        _setName(PayableToken.IXT, tokenId, name);
    }

    function setNameWithAC(uint256 tokenId, string memory name) public {
        _setName(PayableToken.AstroCredits, tokenId, name);
    }

    function _setName(PayableToken _payToken, uint256 tokenId, string memory name) internal {
        if (ownerOf(tokenId) != msg.sender) revert Rover__NotOwner();
        _transferERCTokens(_payToken, getNamePrice(_payToken));
        rovers[tokenId].name = name;
        emit Named(tokenId, name);
    }

    /** Upgrade Skin **/
    function upgradeSkinIXT(uint256 tokenId, uint256 _skin) public {
        _upgradeSkin(PayableToken.IXT, tokenId, _skin);
    }

    function upgradeSkinAC(uint256 tokenId, uint256 _skin) public {
        _upgradeSkin(PayableToken.AstroCredits, tokenId, _skin);
    }

    function _upgradeSkin(PayableToken _payToken, uint256 tokenId, uint256 _skin) internal {
        if (ownerOf(tokenId) != msg.sender) revert Rover__NotOwner();
        if (_skin >= uris.length) revert Rover__InvalidSkin(_skin);
        _transferERCTokens(_payToken, getSkinPrice(_payToken, _skin));
        rovers[tokenId].skin = _skin;
        emit NewSkin(tokenId, _skin);
    }

    /** Burn **/
    function burn(uint256 tokenId) public {
        if (ownerOf(tokenId) != msg.sender) revert Rover__NotOwner();
        _burn(tokenId);
    }

    /** Admin Functions **/

    /**
     * @notice set keyHash by owner
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @notice set callbackGasLimit by owner
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    /**
     * @notice set subscriptionId by owner
     */
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    /**
     * @notice set requestConfirmations by owner
     */
    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function setOracleManager(address _oracleManager) public onlyOwner {
        if (_oracleManager == address(0)) revert Rover__ZeroAddress();
        s_oracle = IOracleManager(_oracleManager);
    }

    function setCrosschain(IMCCrosschainServices _crosschain) external onlyOwner {
        crosschainServices = _crosschain;
    }

    function setRoverAdapter(IMissionControlStakeable _stakeable) external onlyOwner {
        roverAdapter = _stakeable;
    }

    function setMissionControl(IMissionControl _missionControl) external onlyOwner {
        missionControl = address(_missionControl);
    }

    function setRoverHelper(RoverHelper _roverHelper) external onlyOwner {
        roverHelper = _roverHelper;
    }

    function withdraw() public onlyOwner {
        IXT.transfer(msg.sender, IXT.balanceOf(address(this)));
        astroCredits.safeTransferFrom(
            address(this),
            msg.sender,
            acTokenId,
            astroCredits.balanceOf(address(this), acTokenId),
            ""
        );
        USDT.transfer(msg.sender, USDT.balanceOf(address(this)));
        require(payable(msg.sender).send(address(this).balance));
    }

    function setSaleOpen(bool _saleOpen) public onlyOwner {
        saleOpen = _saleOpen;
    }

    function setAstroCredits(address _astroCredits) external onlyOwner {
        astroCredits = IERC1155Upgradeable(_astroCredits);
    }

    /** Interface **/
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155ReceiverUpgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function setTrusted(address _trusted, bool _isTrusted) external onlyOwner {
        trusted[_trusted] = _isTrusted;
    }

    function trustedMint(address _to, uint256 _tokenId, uint256 _amount) external trustedOnly {
        for (uint256 i; i < _amount; i++) {
            uint256 tokenId = totalSupply();
            Color color;
            if (_tokenId == 3) {
                color = Color.Piercer;
            } else if (_tokenId == 2) {
                color = Color.Genesis;
            } else if (_tokenId == 1) {
                color = Color.Night;
            }
            rovers[tokenId] = RoverInfo({name: "", color: Color(color), status: Status.Pristine, skin: 0});
            _safeMint(_to, tokenId);
            emit NewRover(_to, tokenId, color);
        }
    }

    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external trustedOnly {}

    function tokensOfOwner(address _owner) external view returns (uint[] memory _tokens) {
        _tokens = new uint[](balanceOf(_owner));
        for (uint i; i < balanceOf(_owner); i++) {
            _tokens[i] = tokenOfOwnerByIndex(_owner, i);
        }
    }

    function airdrop(address[] memory _receipients, uint256[] memory _colours) external onlyOwner {
        uint256 length = _receipients.length;
        if (_colours.length != length) revert Rover__InvalidArguments();
        if (totalSupply() + length > MAX_SUPPLY) revert Rover__MaxSupplyReached();
        for (uint256 i; i < length; i++) {
            uint256 tokenId = totalSupply();
            Color color;
            if (_colours[i] == 3) {
                color = Color.Piercer;
            } else if (_colours[i] == 2) {
                color = Color.Genesis;
            } else if (_colours[i] == 1) {
                color = Color.Night;
            }
            rovers[tokenId] = RoverInfo({name: "", color: Color(color), status: Status.Pristine, skin: 0});
            _safeMint(_receipients[i], tokenId);
            emit NewRover(_receipients[i], tokenId, color);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IRover.sol";
import "../libraries/Base64Url.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RoverHelper is OwnableUpgradeable {

  function initialize() public initializer {
      __Ownable_init();
  }

  function description(IRover.Color color) public pure returns (string memory) {
    if (color == IRover.Color.Piercer) {
        return
            "The Piercer Rover is designed for the harsh terrain of Planet IX. Utilizing standard propulsion and power systems, it is able to collect waste in the immediate area. However, long-term use without maintenance will result in mechanical malfunction.";
    } else if (color == IRover.Color.Genesis) {
        return
            "The Genesis Rover is designed for the harsh terrains of Planet IX. Its advanced sensors and mapping technology allow it to locate and collect waste with pinpoint accuracy. However, regular maintenance is required to avoid potential system failure.";
    } else {
        return
            "The Night Rover is designed to navigate the rugged terrains of Planet IX. Equipped with cutting-edge thermal and infrared sensors, it efficiently collects waste in extremely low-light conditions. However, regular maintenance is required to avoid potential system failure.";
    }
  }

  function tokenURI(IRover.RoverInfo memory rover, string memory baseUri, string memory skinUri) public pure returns(string memory) {
    string memory image;
    string memory video;
    if (rover.status == IRover.Status.Wrecked) {
        image = string.concat(baseUri, "/3.gif");
        video = string.concat(baseUri, "/3.mp4");
    } else {
        if (rover.skin == 0) {
            image = string.concat(
                baseUri,
                "/",
                Strings.toString(uint256(rover.status)),
                "-",
                Strings.toString(uint256(rover.color)),
                ".gif"
            );
            video = string.concat(
                baseUri,
                "/",
                Strings.toString(uint256(rover.status)),
                "-",
                Strings.toString(uint256(rover.color)),
                ".mp4"
            );
        } else {
            image = skinUri;
            video = skinUri;
            // video = uris[rover.skin];
        }
    }

    string memory status;
    if (rover.status == IRover.Status.Pristine) {
        status = "Pristine";
    } else if (rover.status == IRover.Status.Worn) {
        status = "Worn";
    } else if (rover.status == IRover.Status.Damaged) {
        status = "Damaged";
    } else {
        status = "Wrecked";
    }
    string memory color;
    string memory roverType;
    if (rover.color == IRover.Color.Piercer) {
        roverType = "RVR Piercer";
        color = "White";
    } else if (rover.color == IRover.Color.Genesis) {
        roverType = "RVR Genesis";
        color = "Green";
    } else {
        roverType = "RVR Night";
        color = "Black";
    }
    string memory attributes = string.concat(
        '"attributes":[{"trait_type":"Corporation","value":"Y_"},{"trait_type":"Family","value":"Harvester Vehicle"},{"trait_type":"Type","value":"',
        roverType,
        '"},{"trait_type":"Color","value":"',
        color,
        '"},{"trait_type":"Material","value":"Hardened Bioplastics"},{"trait_type":"State","value":"',
        status,
        '"}]'
    );
    string memory json = string.concat(
        '{"name": "',
        bytes(rover.name).length == 0 ? roverType : rover.name,
        '", "description": "',
        description(rover.color),
        '", "image": "',
        image,
        '", "animation_url": "',
        video,
        '", ',
        attributes,
        "}"
    );
    string memory base = "data:application/json;base64,";

    return string.concat(base, Base64Url.encode(bytes(json)));
  }
}