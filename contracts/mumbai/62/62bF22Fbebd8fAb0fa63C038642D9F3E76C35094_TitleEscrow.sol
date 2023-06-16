// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./interfaces/ITitleEscrow.sol";
import "./interfaces/ITradeTrustToken.sol";
import "./interfaces/TitleEscrowErrors.sol";
import "./RelayRecipientV2.sol";

/**
 * @title TitleEscrow
 * @dev Title escrow contract for managing the beneficiaries and holders of a transferable record.
 */
contract TitleEscrow is Initializable, IERC165, TitleEscrowErrors, ITitleEscrow, RelayRecipientV2 {
  address public override registry;
  uint256 public override tokenId;

  address public override beneficiary;
  address public override holder;

  address public override nominee;

  bool public override active;

  constructor() initializer {}

  /**
   * @dev Modifier to make a function callable only by the beneficiary.
   */
  modifier onlyBeneficiary() {
    if (_msgSender() != beneficiary) {
      revert CallerNotBeneficiary();
    }
    _;
  }

  /**
   * @dev Modifier to make a function callable only by the holder.
   */
  modifier onlyHolder() {
    if (_msgSender() != holder) {
      revert CallerNotHolder();
    }
    _;
  }

  /**
   * @dev Modifier to ensure the contract is holding the token.
   */
  modifier whenHoldingToken() {
    if (!_isHoldingToken()) {
      revert TitleEscrowNotHoldingToken();
    }
    _;
  }

  /**
   * @dev Modifier to ensure the registry is not paused.
   */
  modifier whenNotPaused() {
    bool paused = Pausable(registry).paused();
    if (paused) {
      revert RegistryContractPaused();
    }
    _;
  }

  /**
   * @dev Modifier to ensure the title escrow is active.
   */
  modifier whenActive() {
    if (!active) {
      revert InactiveTitleEscrow();
    }
    _;
  }

  /**
   * @notice Initializes the TitleEscrow contract with the registry address and the tokenId
   * @param _registry The address of the registry
   * @param _tokenId The id of the token
   */
  function initialize(address _registry, uint256 _tokenId) public virtual initializer {
    __TitleEscrow_init(_registry, _tokenId);
  }

  /**
   * @notice Initializes the TitleEscrow contract with the registry address and the tokenId
   */
  function __TitleEscrow_init(address _registry, uint256 _tokenId) internal virtual onlyInitializing {
    registry = _registry;
    tokenId = _tokenId;
    active = true;
  }

  /**
   * @dev See {ERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(ITitleEscrow).interfaceId;
  }

  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   */
  function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256 _tokenId,
    bytes calldata data
  ) external virtual override whenNotPaused whenActive returns (bytes4) {
    if (_tokenId != tokenId) {
      revert InvalidTokenId(_tokenId);
    }
    if (_msgSender() != address(registry)) {
      revert InvalidRegistry(_msgSender());
    }
    bool isMinting = false;
    if (beneficiary == address(0) || holder == address(0)) {
      if (data.length == 0) {
        revert EmptyReceivingData();
      }
      (address _beneficiary, address _holder) = abi.decode(data, (address, address));
      if (_beneficiary == address(0) || _holder == address(0)) {
        revert InvalidTokenTransferToZeroAddressOwners(_beneficiary, _holder);
      }
      _setBeneficiary(_beneficiary);
      _setHolder(_holder);
      isMinting = true;
    }

    emit TokenReceived(beneficiary, holder, isMinting, registry, tokenId);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  /**
   * @dev See {ITitleEscrow-nominate}.
   */
  function nominate(address _nominee)
  public
  virtual
  override
  whenNotPaused
  whenActive
  onlyBeneficiary
  whenHoldingToken
  {
    if (beneficiary == _nominee) {
      revert TargetNomineeAlreadyBeneficiary();
    }
    if (nominee == _nominee) {
      revert NomineeAlreadyNominated();
    }

    _setNominee(_nominee);
  }

  /**
   * @dev See {ITitleEscrow-transferBeneficiary}.
   */
  function transferBeneficiary(address _nominee)
  public
  virtual
  override
  whenNotPaused
  whenActive
  onlyHolder
  whenHoldingToken
  {
    if (_nominee == address(0)) {
      revert InvalidTransferToZeroAddress();
    }
    if (!(beneficiary == holder || nominee == _nominee)) {
      revert InvalidNominee();
    }

    _setBeneficiary(_nominee);
  }

  /**
   * @dev See {ITitleEscrow-transferHolder}.
   */
  function transferHolder(address newHolder)
  public
  virtual
  override
  whenNotPaused
  whenActive
  onlyHolder
  whenHoldingToken
  {
    if (newHolder == address(0)) {
      revert InvalidTransferToZeroAddress();
    }
    if (holder == newHolder) {
      revert RecipientAlreadyHolder();
    }

    _setHolder(newHolder);
  }

  /**
   * @dev See {ITitleEscrow-transferOwners}.
   */
  function transferOwners(address _nominee, address newHolder) external virtual override {
    transferBeneficiary(_nominee);
    transferHolder(newHolder);
  }

  /**
   * @dev See {ITitleEscrow-surrender}.
   */
  function surrender() external virtual override whenNotPaused whenActive onlyBeneficiary onlyHolder whenHoldingToken {
    _setNominee(address(0));
    ITradeTrustToken(registry).transferFrom(address(this), registry, tokenId);

    emit Surrender(_msgSender(), registry, tokenId);
  }

  /**
   * @dev See {ITitleEscrow-shred}.
   */
  function shred() external virtual override whenNotPaused whenActive {
    if (_isHoldingToken()) {
      revert TokenNotSurrendered();
    }
    if (_msgSender() != registry) {
      revert InvalidRegistry(_msgSender());
    }

    _setBeneficiary(address(0));
    _setHolder(address(0));
    active = false;

    emit Shred(registry, tokenId);
  }

  /**
   * @dev See {ITitleEscrow-isHoldingToken}.
   */
  function isHoldingToken() external view override returns (bool) {
    return _isHoldingToken();
  }

  /**
   * @notice Internal function to check if the contract is holding a token
   * @return A boolean indicating whether the contract is holding a token
   */
  function _isHoldingToken() internal view returns (bool) {
    return ITradeTrustToken(registry).ownerOf(tokenId) == address(this);
  }

  /**
   * @notice Sets the nominee
   * @param newNominee The address of the new nominee
   */
  function _setNominee(address newNominee) internal virtual {
    emit Nomination(nominee, newNominee, registry, tokenId);
    nominee = newNominee;
  }

  /**
   * @notice Sets the beneficiary
   * @param newBeneficiary The address of the new beneficiary
   */
  function _setBeneficiary(address newBeneficiary) internal virtual {
    emit BeneficiaryTransfer(beneficiary, newBeneficiary, registry, tokenId);
    _setNominee(address(0));
    beneficiary = newBeneficiary;
  }

  /**
   * @notice Sets the holder
   * @param newHolder The address of the new holder
   */
  function _setHolder(address newHolder) internal virtual {
    emit HolderTransfer(holder, newHolder, registry, tokenId);
    holder = newHolder;
  }


  function _msgSender() internal view override(RelayRecipientV2)
  returns (address sender) {
    sender = RelayRecipientV2._msgSender();
  }

  function _msgData() internal view override(RelayRecipientV2)
  returns (bytes calldata) {
    return RelayRecipientV2._msgData();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title ITitleEscrow
 * @notice Interface for TitleEscrow contract. The TitleEscrow contract represents a title escrow for transferable records.
 * @dev Inherits from IERC721Receiver.
 */
interface ITitleEscrow is IERC721Receiver {
  event TokenReceived(
    address indexed beneficiary,
    address indexed holder,
    bool indexed isMinting,
    address registry,
    uint256 tokenId
  );
  event Nomination(address indexed prevNominee, address indexed nominee, address registry, uint256 tokenId);
  event BeneficiaryTransfer(
    address indexed fromBeneficiary,
    address indexed toBeneficiary,
    address registry,
    uint256 tokenId
  );
  event HolderTransfer(address indexed fromHolder, address indexed toHolder, address registry, uint256 tokenId);
  event Surrender(address indexed surrenderer, address registry, uint256 tokenId);
  event Shred(address registry, uint256 tokenId);

  /**
   * @notice Allows the beneficiary to nominate a new beneficiary
   * @dev The nominated beneficiary will need to be transferred by the holder to become the actual beneficiary
   * @param nominee The address of the nominee
   */
  function nominate(address nominee) external;

  /**
   * @notice Allows the holder to transfer the beneficiary role to the nominated beneficiary or to themselves
   * @param nominee The address of the new beneficiary
   */
  function transferBeneficiary(address nominee) external;

  /**
   * @notice Allows the holder to transfer their role to another address
   * @param newHolder The address of the new holder
   */
  function transferHolder(address newHolder) external;

  /**
   * @notice Allows for the simultaneous transfer of both beneficiary and holder roles
   * @param nominee The address of the new beneficiary
   * @param newHolder The address of the new holder
   */
  function transferOwners(address nominee, address newHolder) external;

  function beneficiary() external view returns (address);

  function holder() external view returns (address);

  function active() external view returns (bool);

  function nominee() external view returns (address);

  function registry() external view returns (address);

  function tokenId() external view returns (uint256);

  /**
   * @notice Check if the TitleEscrow is currently holding a token
   * @return A boolean indicating whether the contract is holding a token
   */
  function isHoldingToken() external returns (bool);

  /**
   * @notice Allows the beneficiary and holder to surrender the token back to the registry
   */
  function surrender() external;

  /**
   * @notice Allows the registry to shred the TitleEscrow by marking it as inactive and reset the beneficiary and holder addresses
   */
  function shred() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ITradeTrustSBT.sol";
import "./ITradeTrustTokenRestorable.sol";
import "./ITradeTrustTokenBurnable.sol";
import "./ITradeTrustTokenMintable.sol";

interface ITradeTrustToken is
  ITradeTrustTokenMintable,
  ITradeTrustTokenBurnable,
  ITradeTrustTokenRestorable,
  ITradeTrustSBT
{}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface TitleEscrowErrors {
  error CallerNotBeneficiary();

  error CallerNotHolder();

  error TitleEscrowNotHoldingToken();

  error RegistryContractPaused();

  error InactiveTitleEscrow();

  error InvalidTokenId(uint256 tokenId);

  error InvalidRegistry(address registry);

  error EmptyReceivingData();

  error InvalidTokenTransferToZeroAddressOwners(address beneficiary, address holder);

  error TargetNomineeAlreadyBeneficiary();

  error NomineeAlreadyNominated();

  error InvalidTransferToZeroAddress();

  error InvalidNominee();

  error RecipientAlreadyHolder();

  error TokenNotSurrendered();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RelayRecipientV2 is Ownable {

    address private _relayHub;

    function getHubAddr() public view returns (address) {
        return _relayHub;
    }

    function setRelayHub(address newRelayHub) public onlyOwner {
        address currentRelayHub = _relayHub;
        require(newRelayHub != address(0), "GSNRecipient: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNRecipient: new RelayHub is the current one");
        _relayHub = newRelayHub;
    }

    modifier relayHubOnly() {
        require(msg.sender == getHubAddr(), "Function can only be called by RelayHub");
        _;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (msg.sender != _relayHub) {
            return super._msgSender();
        } else {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (msg.sender != _relayHub) {
            return msg.data;
        } else {
            return msg.data[:msg.data.length - 20];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./ISBTUpgradeable.sol";
import "./ITitleEscrowFactory.sol";

interface ITradeTrustSBT is IERC721ReceiverUpgradeable, ISBTUpgradeable {
  /**
   * @notice Returns the block number when the contract was created.
   * @return The block number of the contract's creation.
   */
  function genesis() external view returns (uint256);

  /**
   * @notice Returns the TitleEscrowFactory address associated with this contract.
   * @return The address of the TitleEscrowFactory contract.
   */
  function titleEscrowFactory() external view returns (ITitleEscrowFactory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITradeTrustTokenRestorable {
  /**
   * @dev Restore a surrendered token.
   * @param tokenId The ID of the token to restore.
   * @return The address of the TitleEscrow contract.
   */
  function restore(uint256 tokenId) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITradeTrustTokenBurnable {
  /**
   * @dev Burn a token.
   * @param tokenId The ID of the token to burn.
   */
  function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITradeTrustTokenMintable {
  /**
   * @dev Mint a TradeTrust token.
   * @param beneficiary The beneficiary of the token.
   * @param holder The holder of the token.
   * @param tokenId The ID of the token to mint.
   * @return The address of the corresponding TitleEscrow.
   */
  function mint(
    address beneficiary,
    address holder,
    uint256 tokenId
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ISBTUpgradeable is IERC165Upgradeable {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

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
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITitleEscrowFactory {
  event TitleEscrowCreated(address indexed titleEscrow, address indexed tokenRegistry, uint256 indexed tokenId);

  function implementation() external view returns (address);

  /**
   * @notice Creates a new clone of the TitleEscrow contract and initializes it with the sender's address and the provided token ID.
   * @dev The function will revert if it is called by an EOA.
   * @param tokenId The ID of the token.
   * @return The address of the newly created TitleEscrow contract.
   */
  function create(uint256 tokenId) external returns (address);

  /**
   * @notice Returns the address of a TitleEscrow contract that would be created with the provided token registry address and token ID.
   * @param tokenRegistry The address of the token registry.
   * @param tokenId The ID of the token.
   * @return The address of the TitleEscrow contract.
   */
  function getAddress(address tokenRegistry, uint256 tokenId) external view returns (address);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}