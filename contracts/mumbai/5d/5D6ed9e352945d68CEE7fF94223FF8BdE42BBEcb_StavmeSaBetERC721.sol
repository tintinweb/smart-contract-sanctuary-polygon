// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract OwnableUpgradeable {
  address private __owner;

  error OwnableUserMustBeOwner(address user);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner(address user) {
    if (_owner() != user) {
      revert OwnableUserMustBeOwner(user);
    }

    _;
  }

  function __Ownable__init(address newOwner) internal {
    _setOwner(newOwner);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view virtual returns (address) {
    return _owner();
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function _owner() internal view virtual returns (address) {
    return __owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _setOwner(address newOwner) internal virtual returns (address oldOwner) {
    oldOwner = __owner;
    __owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../../access/OwnableUpgradeable.sol';
import '../../utility/Strings.sol';
import './IERC721Enumerable.sol';
import './IERC721Metadata.sol';
import './IERC721TokenReceiver.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Base is Initializable, OwnableUpgradeable, IERC721Enumerable, IERC721Metadata {
  using Strings for uint256;

  //
  //
  // Errors
  //
  //

  error ERC721InvalidTokenId(uint256 tokenId);
  error ERC721IndexOutOfRange(uint256 index);
  error ERC721InvalidAddress(address addr);
  error ERC721ApprovalToCurrentOwner(address owner);
  error ERC721NotApproved(address user);
  error ERC721IncorrectOwner(address expected, address actual);
  error ERC721NotReceived(address to, uint256 tokenId, bytes reason);
  error ERC721UnableToWithdraw(address to, uint256 value);

  // Token name
  string private __name;

  // Token symbol
  string private __symbol;

  string private __baseURI;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private __owners;

  // Mapping owner address to token count
  mapping(address => uint256) private __balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  function __ERC721Base_init(
    string memory name_,
    string memory symbol_,
    string memory baseURI
  ) internal onlyInitializing {
    __name = name_;
    __symbol = symbol_;
    __baseURI = baseURI;
  }

  modifier onlyIfMinted(uint256 tokenId) {
    _assertMinted(tokenId);

    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) external view virtual returns (uint256) {
    if (owner == address(0)) {
      revert ERC721InvalidAddress(owner);
    }

    return __balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) external view virtual returns (address) {
    address owner = _ownerOf(tokenId);
    if (owner == address(0)) {
      revert ERC721InvalidTokenId(tokenId);
    }

    return owner;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() external view virtual override returns (string memory) {
    return __name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() external view virtual override returns (string memory) {
    return __symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    _assertMinted(tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return __baseURI;
  }

  function _setBaseURI(string memory value) internal virtual {
    __baseURI = value;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) external payable virtual {
    address owner = _ownerOf(tokenId);
    if (owner == to) {
      revert ERC721ApprovalToCurrentOwner(to);
    }

    if (msg.sender != owner && !_isApprovedForAll(owner, msg.sender)) {
      revert ERC721NotApproved(msg.sender);
    }

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) external view virtual returns (address) {
    _assertMinted(tokenId);

    return _getApproved(tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function _getApproved(uint256 tokenId) internal view virtual returns (address) {
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) external virtual override {
    _setApprovalForAll(msg.sender, operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) external view virtual returns (bool) {
    return _isApprovedForAll(owner, operator);
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external payable virtual {
    if (!_isApprovedOrOwner(msg.sender, tokenId)) {
      revert ERC721NotApproved(msg.sender);
    }

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external payable virtual {
    _safeTransferFrom(from, to, tokenId, '');
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) external payable virtual {
    _safeTransferFrom(from, to, tokenId, data);
  }

  function withdraw(address payable to) external virtual onlyOwner(msg.sender) {
    _withdraw(to);
  }

  function _safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    if (!_isApprovedOrOwner(msg.sender, tokenId)) {
      revert ERC721NotApproved(msg.sender);
    }

    _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) external view virtual returns (uint256) {
    if (index > _totalSupply()) {
      // FIXME
      revert ERC721IndexOutOfRange(index);
    }

    return _allTokens[index];
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256) {
    if (index > _balanceOf(owner)) {
      // FIXME
      revert ERC721IndexOutOfRange(index);
    }

    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() external view virtual returns (uint256) {
    return _totalSupply();
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);

    _assertOnERC721Received(from, to, tokenId, data);
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return __owners[tokenId];
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
    return _ownerOf(tokenId) != address(0);
  }

  function _isApprovedForAll(address owner, address operator) internal view virtual returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    address owner = _ownerOf(tokenId);
    return (spender == owner || _isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
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
    _safeMint(to, tokenId, '');
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);

    _assertOnERC721Received(address(0), to, tokenId, data);
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
    if (to == address(0)) {
      revert ERC721InvalidAddress(to);
    }

    if (_exists(tokenId)) {
      revert ERC721InvalidTokenId(tokenId);
    }

    _beforeTokenTransfer(address(0), to, tokenId, 1);

    unchecked {
      // Will not overflow unless all 2**256 token ids are minted to the same owner.
      // Given that tokens are minted one by one, it is impossible in practice that
      // this ever happens. Might change if we allow batch minting.
      // The ERC fails to describe this case.
      __balances[to] += 1;
    }

    __owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId, 1);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = _ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId, 1);

    // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
    owner = _ownerOf(tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    unchecked {
      // Cannot overflow, as that would require more tokens to be burned/transferred
      // out than the owner initially received through minting and transferring in.
      __balances[owner] -= 1;
    }
    delete __owners[tokenId];

    emit Transfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId, 1);
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
    address owner = _ownerOf(tokenId);
    if (from != owner) {
      revert ERC721IncorrectOwner(owner, from);
    }

    if (to == address(0)) {
      revert ERC721InvalidAddress(to);
    }

    _beforeTokenTransfer(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    unchecked {
      // `__balances[from]` cannot overflow for the same reason as described in `_burn`:
      // `from`'s balance is the number of token held, which is at least one before the current
      // transfer.
      // `__balances[to]` could overflow in the conditions described in `_mint`. That would require
      // all 2**256 token ids to be minted, which in practice is impossible.
      __balances[from] -= 1;
      __balances[to] += 1;
    }
    __owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;

    emit Approval(_ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, 'ERC721: approve to caller');
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _totalSupply() internal view virtual returns (uint256) {
    return _allTokens.length;
  }

  function _balanceOf(address owner) internal view virtual returns (uint256) {
    if (owner == address(0)) {
      revert ERC721InvalidAddress(owner);
    }

    return __balances[owner];
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _assertMinted(uint256 tokenId) internal view {
    if (!_exists(tokenId)) {
      revert ERC721InvalidTokenId(tokenId);
    }
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   */
  function _assertOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private {
    // This means the receiving address is not a contract
    if (to.code.length == 0) return;

    try IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
      if (retval != IERC721TokenReceiver.onERC721Received.selector) {
        revert ERC721NotReceived(to, tokenId, bytes('Not implemented'));
      }
    } catch (bytes memory reason) {
      revert ERC721NotReceived(to, tokenId, reason);
    }
  }

  function _withdraw(address payable to) internal virtual {
    (bool success, ) = to.call{value: address(this).balance}('');
    if (!success) {
      revert ERC721UnableToWithdraw(to, address(this).balance);
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {
    // FIXME
    if (batchSize > 1) {
      if (from != address(0)) {
        __balances[from] -= batchSize;
      }
      if (to != address(0)) {
        __balances[to] += batchSize;
      }
    }

    if (batchSize > 1) {
      // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
      revert('ERC721Enumerable: consecutive transfers not supported');
    }

    uint256 tokenId = firstTokenId;

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
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = _balanceOf(to);
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

    uint256 lastTokenIndex = _balanceOf(from) - 1;
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

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[44] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../utility/IERC165.sol";

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
interface IERC721 is IERC165 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
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
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

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
        uint256 _tokenId,
        bytes memory data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
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
        uint256 _tokenId
    ) external payable;

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets.
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC721.sol";

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable is IERC721 {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC721.sol";

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
    function tokenURI(uint256 _tokenId) external view returns (string memory metadataUri);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the
    /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
    /// of other than the magic value MUST result in the transaction being reverted.
    /// @notice The contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev numeric symbols used for conversion. Hexadecimal present just because
     */
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = _length(value);
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            do {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
            } while (value != 0);
            return buffer;
        }
    }

    function _length(uint256 value) private pure returns (uint256 length) {
        if (value == 0) return 1;

        length = 1;

        unchecked {
            uint8 exponent = 64;
            uint256 comparator;

            while (exponent > 0) {
                comparator = 10 ** exponent;
                if (value >= comparator) {
                    value /= comparator;
                    length += exponent + 1;
                }

                exponent >>= 1;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '../common/token/ERC721/IERC721Enumerable.sol';
import '../common/token/ERC721/IERC721Metadata.sol';
import './IStavmeSaEventERC721.sol';

interface IStavmeSaBetERC721 is IERC721Enumerable, IERC721Metadata {
  struct EventToken {
    IStavmeSaEventERC721 eventProvider;
    uint256 eventId;
  }

  event BetCollectionCreated(address indexed owner, string indexed symbol, string name, string baseURI);

  event BetCreated(
    uint256 indexed betId,
    address indexed owner,
    EventToken eventToken,
    uint8 result,
    string metadataUri
  );

  event BetCancelled(uint256 indexed betId);

  struct CreateBetInputDTO {
    EventToken eventToken;
    uint8 result;
  }

  error InvalidEventResult(EventToken eventToken, uint8 result);
  error EventMustNotHaveStartedYet(EventToken eventToken);
  error CallerMustBeTheTokenOwner(address from, uint256 betId);

  function createBet(CreateBetInputDTO memory input) external payable returns (uint256 betId);

  function cancelBet(uint256 betId) external payable;

  function redeemBet(uint256 betId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IStavmeSaEventERC721.sol";

interface IStavmeSaBetERC721AdminInterface {
    event EventProviderRegistered(
        IStavmeSaEventERC721 indexed eventProvider,
        address indexed registerar
    );

    event EventProviderUnregistered(
        IStavmeSaEventERC721 indexed eventProvider,
        address indexed unregisterar
    );

    error EventProviderMustBeRegistered(IStavmeSaEventERC721 eventProvider);
    error EventProviderMustBeValid(IStavmeSaEventERC721 eventProvider);

    struct GetEventProvidersArgumentsDTO {
        uint256 offset;
        uint8 limit;
    }

    struct GetEventProvidersResponseDTO {
        uint256 nextOffset;
        IStavmeSaEventERC721[] eventProviders;
    }

    function registerEventProvider(IStavmeSaEventERC721 eventProvider) external payable;
    
    function unregisterEventProvider(IStavmeSaEventERC721 eventProvider) external payable;

    function isEventProviderRegistered(IStavmeSaEventERC721 eventProvider) external view returns (bool);

    function getEventProviders(GetEventProvidersArgumentsDTO calldata args) external view returns (GetEventProvidersResponseDTO memory response);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '../common/token/ERC721/IERC721Enumerable.sol';
import '../common/token/ERC721/IERC721Metadata.sol';

interface IStavmeSaEventERC721 is IERC721Enumerable, IERC721Metadata {
    enum EventStatus { PENDING, IN_PROGRESS, FINISHED, SETTLED, CANCELLED }

    function getEventStartTime(uint256 eventId) external view returns (uint48);

    function getEventEndTime(uint256 eventId) external view returns (uint48);

    function getAllPossibleEventResults(uint256 eventId) external view returns (uint8[] memory possibleResults);

    function isPossibleEventResult(uint256 eventId, uint8 result) external view returns (bool);

    function getEventStatus(uint256 eventId) external view returns (EventStatus);

    function getEventResults(uint256 eventId) external view returns (uint8[] memory results);
    
    function isEventResult(uint256 eventId, uint8 result) external view returns (bool);

    function getEventCancelledTime(uint256 eventId)
        external
        view
        returns (uint48);

    function getEventSettledTime(uint256 eventId)
        external
        view
        returns (uint48);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './IStavmeSaBetERC721.sol';
import './IStavmeSaBetERC721AdminInterface.sol';
import '../common/token/ERC721/ERC721Base.sol';

uint8 constant MAX_RESULTS = 47;

/**
 * Represents a collection of events. The individual tokens
 * represent events that, on top of the standard ERC721
 *
 *
 */
contract StavmeSaBetERC721 is IStavmeSaBetERC721, IStavmeSaBetERC721AdminInterface, ERC721Base {
  struct BetDefinition {
    EventToken eventToken;
    uint8 result;
    uint256 value;
  }

  uint256 private _lastBetId;

  mapping(uint256 => BetDefinition) _betsById;

  uint256 private _numRegisteredEventProviders;
  IStavmeSaEventERC721[] internal _registeredEventProviders;
  mapping(IStavmeSaEventERC721 => uint256) _registeredEventProviderIndexes;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string memory name,
    string memory symbol,
    string memory baseURI,
    address owner
  ) external initializer {
    __Ownable__init(owner);
    __ERC721Base_init(name, symbol, baseURI);

    emit BetCollectionCreated(owner, symbol, name, baseURI);
  }

  //
  //
  // IStavmeSaBetERC721 methods
  //
  //

  function createBet(CreateBetInputDTO memory input)
    external
    payable
    onlyIfEventProviderRegistered(input.eventToken.eventProvider)
    returns (uint256 betId)
  {
    // Check that the event is still on
    IStavmeSaEventERC721.EventStatus status = input.eventToken.eventProvider.getEventStatus(input.eventToken.eventId);
    if (status != IStavmeSaEventERC721.EventStatus.PENDING) {
      revert EventMustNotHaveStartedYet(input.eventToken);
    }

    // TODO Add an optional delay between betting closing time and event start time

    // Make sure that the event result exists
    if (!input.eventToken.eventProvider.isPossibleEventResult(input.eventToken.eventId, input.result)) {
      revert InvalidEventResult(input.eventToken, input.result);
    }

    // Create bet metadata
    betId = _createBetId();
    _betsById[betId] = BetDefinition(
      input.eventToken,
      input.result,
      // TODO Allow for value to be composed of contract balance and message.value
      msg.value
    );

    _safeMint(msg.sender, betId);

    // TODO Figure out metadata URI
    emit BetCreated(betId, msg.sender, input.eventToken, input.result, '');
  }

  function cancelBet(uint256 betId) external payable onlyIfMinted(betId) {
    if (_ownerOf(betId) != msg.sender) {
      revert CallerMustBeTheTokenOwner(msg.sender, betId);
    }

    BetDefinition memory bet = _betsById[betId];
    IStavmeSaEventERC721.EventStatus status = bet.eventToken.eventProvider.getEventStatus(bet.eventToken.eventId);
    if (status != IStavmeSaEventERC721.EventStatus.PENDING) {
      revert EventMustNotHaveStartedYet(bet.eventToken);
    }

    // FIXME Send money back & adjust balances

    _burn(betId);
    delete _betsById[betId];

    emit BetCancelled(betId);
  }

  function redeemBet(uint256 betId) external onlyIfMinted(betId) {
    // FIXME Check ownership
  }

  //
  //
  // IStavmeSaBetERC721AdminInterface methods
  //
  //

  function registerEventProvider(IStavmeSaEventERC721 eventProvider) external payable onlyOwner(msg.sender) {
    if (!_isValidEventProvider(eventProvider)) {
      revert EventProviderMustBeValid(eventProvider);
    }

    if (_isEventProviderRegistered(eventProvider)) {
      return;
    }

    _registeredEventProviderIndexes[eventProvider] = _numRegisteredEventProviders++;
    _registeredEventProviders.push(eventProvider);

    emit EventProviderRegistered(eventProvider, msg.sender);
  }

  function unregisterEventProvider(IStavmeSaEventERC721 eventProvider)
    external
    payable
    onlyOwner(msg.sender)
    onlyIfEventProviderRegistered(eventProvider)
  {
    // FIXME Cancel all bets from this provider

    uint256 lastEventProviderIndex = --_numRegisteredEventProviders;
    IStavmeSaEventERC721 lastEventProvider = _registeredEventProviders[lastEventProviderIndex];

    if (lastEventProvider != eventProvider) {
      uint256 eventProviderIndex = _registeredEventProviderIndexes[eventProvider];

      _registeredEventProviders[eventProviderIndex] = lastEventProvider;
      _registeredEventProviderIndexes[lastEventProvider] = eventProviderIndex;
    }

    delete _registeredEventProviderIndexes[eventProvider];

    emit EventProviderUnregistered(eventProvider, msg.sender);
  }

  function isEventProviderRegistered(IStavmeSaEventERC721 eventProvider) external view returns (bool) {
    return _isEventProviderRegistered(eventProvider);
  }

  function getEventProviders(GetEventProvidersArgumentsDTO calldata args)
    external
    view
    returns (GetEventProvidersResponseDTO memory)
  {
    if (args.offset >= _numRegisteredEventProviders)
      return GetEventProvidersResponseDTO(0, new IStavmeSaEventERC721[](0));

    uint256 endIndex = args.offset + args.limit;
    if (endIndex > _numRegisteredEventProviders) {
      endIndex = _numRegisteredEventProviders;
    }

    uint256 length = endIndex - args.offset;
    IStavmeSaEventERC721[] memory eventProviders = new IStavmeSaEventERC721[](length);

    for (uint256 index = 0; index < length; index++) {
      eventProviders[index] = _registeredEventProviders[index + args.offset];
    }

    uint256 nextOffset = endIndex == _numRegisteredEventProviders ? 0 : endIndex;

    return GetEventProvidersResponseDTO(nextOffset, eventProviders);
  }

  function _isEventProviderRegistered(IStavmeSaEventERC721 eventProvider) private view returns (bool) {
    if (_numRegisteredEventProviders == 0) return false;

    return _registeredEventProviders[_registeredEventProviderIndexes[eventProvider]] == eventProvider;
  }

  function _isValidEventProvider(IStavmeSaEventERC721 eventProvider) private view returns (bool) {
    if (address(eventProvider) == address(0)) {
      return false;
    }

    if (address(eventProvider).code.length == 0) return false;

    try eventProvider.supportsInterface(type(IStavmeSaEventERC721).interfaceId) returns (
      bool supportsIStavmeSaEventERC721
    ) {
      return supportsIStavmeSaEventERC721;
    } catch {
      return false;
    }
  }

  modifier onlyIfEventProviderRegistered(IStavmeSaEventERC721 eventProvider) {
    if (!_isEventProviderRegistered(eventProvider)) {
      revert EventProviderMustBeRegistered(eventProvider);
    }

    _;
  }

  function _createBetId() private returns (uint256 betId) {
    unchecked {
      betId = ++_lastBetId;
    }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[45] private __gap;
}