// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IAttestationsRegistry} from './interfaces/IAttestationsRegistry.sol';
import {ConfigLogic} from './libs/attestations-registry/ConfigLogic.sol';
import {AttestationsRegistryState} from './libs/attestations-registry/AttestationsRegistryState.sol';
import {Range, RangeUtils} from './libs/utils/RangeLib.sol';
import {Attestation, AttestationData} from './libs/CoreLib.sol';
import {IBadges} from './interfaces/IBadges.sol';

contract AttestationsRegistry is AttestationsRegistryState, IAttestationsRegistry, ConfigLogic {
  IBadges immutable BADGES;

  constructor(address owner, address badgesAddress) {
    initialize(owner);
    BADGES = IBadges(badgesAddress);
  }

  function initialize(address owner) public initializer {
    _transferOwnership(owner);
  }

  function recordAttestation(Attestation calldata attestation) external override whenNotPaused {
    address attester = _msgSender();

    if (!_isAuthorized(attester, attestation.collectionId))
      revert AttesterNotAuthorized(attester, attestation.collectionId);

    // assign previous value before recording new attestation
    uint256 previousValue = _attestationsData[attestation.collectionId][attestation.owner].value;

    _attestationsData[attestation.collectionId][attestation.owner] = AttestationData(
      attestation.recorder,
      attestation.value,
      attestation.timestamp,
      attestation.extraData
    );

    _triggerBadgeTransferEvent(
      attestation.collectionId,
      attestation.owner,
      previousValue,
      attestation.value
    );
    emit AttestationRecorded(attestation);
  }

  function deleteAttestation(Attestation memory attestation) external override whenNotPaused {
    address attester = _msgSender();
    uint256 previousValue = _attestationsData[attestation.collectionId][attestation.owner].value;

    if (!_isAuthorized(attester, attestation.collectionId))
      revert AttesterNotAuthorized(attester, attestation.collectionId);
    delete _attestationsData[attestation.collectionId][attestation.owner];

    _triggerBadgeTransferEvent(attestation.collectionId, attestation.owner, previousValue, 0);

    emit AttestationDeleted(
      Attestation(
        attestation.collectionId,
        attestation.owner,
        attestation.recorder,
        attestation.value,
        attestation.timestamp,
        attestation.extraData
      )
    );
  }

  function _triggerBadgeTransferEvent(
    uint256 badgeTokenId,
    address owner,
    uint256 previousValue,
    uint256 newValue
  ) internal {
    // Checks if user has a greater attestation value than previously
    bool isGreaterValue = newValue > previousValue;
    address operator = address(this);
    address from = isGreaterValue ? address(0) : owner;
    address to = isGreaterValue ? owner : address(0);
    uint256 value = isGreaterValue ? newValue - previousValue : previousValue - newValue;

    // if isGreaterValue is true, function triggers mint event. Otherwise triggers burn event.
    BADGES.triggerTransferEvent(operator, from, to, badgeTokenId, value);
  }

  function getAttestationData(uint256 collectionId, address owner)
    external
    view
    override
    returns (AttestationData memory)
  {
    return (_attestationsData[collectionId][owner]);
  }

  function getAttestationExtraData(uint256 collectionId, address owner)
    external
    view
    override
    returns (bytes memory)
  {
    return _attestationsData[collectionId][owner].extraData;
  }

  function getAttestationRecorder(uint256 collectionId, address owner)
    external
    view
    override
    returns (address)
  {
    return _attestationsData[collectionId][owner].recorder;
  }

  function getAttestationValue(uint256 collectionId, address owner)
    external
    view
    override
    returns (uint256)
  {
    return _attestationsData[collectionId][owner].value;
  }

  function getAttestationTimestamp(uint256 collectionId, address owner)
    external
    view
    override
    returns (uint32)
  {
    return _attestationsData[collectionId][owner].timestamp;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {Attestation, AttestationData} from '../libs/CoreLib.sol';

/**
 * @title IAttestationsRegistry
 * @author Sismo
 * @notice This is the interface of the AttestationRegistry
 */
interface IAttestationsRegistry {
  event AttestationRecorded(Attestation attestation);
  event AttestationDeleted(Attestation attestation);

  function recordAttestation(Attestation calldata attestation) external;

  function deleteAttestation(Attestation calldata attestation) external;

  function getAttestationData(uint256 collectionId, address owner)
    external
    view
    returns (AttestationData memory);

  function getAttestationExtraData(uint256 collectionId, address owner)
    external
    view
    returns (bytes memory);

  function getAttestationRecorder(uint256 collectionId, address owner)
    external
    view
    returns (address);

  function getAttestationValue(uint256 collectionId, address owner) external view returns (uint256);

  function getAttestationTimestamp(uint256 collectionId, address owner)
    external
    view
    returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.12;

import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IBadges {
  function initialize(string memory uri, address owner) external;

  function triggerTransferEvent(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 value
  ) external;
}

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import {Range, RangeUtils} from '../libs/utils/RangeLib.sol';

interface IConfigLogic {
  error AttesterNotAuthorized(address attester, uint256 collectionId);
  error AttesterNotFound(address attester);
  error RangeIndexOutOfBounds(address attester, uint256 expectedArrayLength, uint256 rangeIndex);
  error IdsMismatch(
    address attester,
    uint256 rangeIndex,
    uint256 expectedFirstId,
    uint256 expectedLastId,
    uint256 FirstId,
    uint256 lastId
  );
  event AttesterAuthorized(address attester, uint256 firstId, uint256 lastId);
  event AttesterUnauthorized(address attester, uint256 rangeIndex, uint256 firstId, uint256 lastId);

  function authorizeRange(
    address attester,
    uint256 firstId,
    uint256 lastId
  ) external;

  function unauthorizeRange(
    address attester,
    uint256 rangeIndex,
    uint256 firstId,
    uint256 lastId
  ) external;

  function authorizeRanges(address attester, Range[] memory ranges) external;

  function unauthorizeRanges(
    address attester,
    Range[] memory ranges,
    uint256[] memory rangeIndexes
  ) external;

  function isAuthorized(address attester, uint256 collectionId) external view returns (bool);

  function getAuthorizedRange(address attester, uint256 rangeIndex)
    external
    view
    returns (uint256, uint256);

  function pause() external;

  function unpause() external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

// User Attestation Request, can be made by any user
// The context of an Attestation Request is a specific attester contract
struct AttestationRequest {
  // implicit address attester;
  // imlicit uint256 chainId;
  uint256[] claimIds; // identifiers of the claims targeted by the user
  uint256[] claimValues; // targeted values for each claim
  address destination; // destination that will receive the end attestation
  bytes extraData; // arbitrary data, may be required by the attester to verify a claim or generate a specific attestation
}

// Attestation, the context is the Attestation Regsitry.
struct Attestation {
  // imlicit uint256 chainId;
  uint256 collectionId; // Id of the attestation collection (in the registry)
  address owner; // Owner of the attestation
  address recorder; // Contract that created or last updated the record.
  uint256 value; // Value of the attestation
  uint32 timestamp; // Timestamp chosen by the attester, should correspond to the effective date of the attestation
  // it is different from the recording timestamp (date when the attestation was recorded)
  // e.g a proof of NFT ownership may have be recorded today which is 2 month old data.
  bytes extraData; // extra data that can be added by the attester
}

// Attestation Data, stored in the registry
// The context is a specific owner of a specific collecton
struct AttestationData {
  // implicit uint256 chainId
  // implicit uint256 collectionId - from context
  // implicit owner
  address recorder; // Addresss
  uint256 value; // Value of the attestation
  uint32 timestamp; // Effective date of issuance of the attestation. (can be different from the recording timestamp)
  bytes extraData;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {Range} from '../utils/RangeLib.sol';
import {Attestation, AttestationData} from '../CoreLib.sol';

contract AttestationsRegistryState {
  bool internal _initialized;
  bool internal _initializing;
  bool internal _paused;
  address internal _owner;

  mapping(address => Range[]) internal _authorizedRanges;
  mapping(uint256 => mapping(address => AttestationData)) internal _attestationsData;
}

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import './OwnableLogic.sol';
import './PausableLogic.sol';
import './InitializableLogic.sol';
import './AttestationsRegistryState.sol';
import {IConfigLogic} from './../../interfaces/IConfigLogic.sol';
import {Range, RangeUtils} from '../utils/RangeLib.sol';

contract ConfigLogic is
  AttestationsRegistryState,
  IConfigLogic,
  OwnableLogic,
  PausableLogic,
  InitializableLogic
{
  using RangeUtils for Range[];

  function authorizeRange(
    address attester,
    uint256 firstId,
    uint256 lastId
  ) external override onlyOwner {
    _authorizeRange(attester, firstId, lastId);
  }

  function authorizeRanges(address attester, Range[] memory ranges) external override onlyOwner {
    for (uint256 i = 0; i < ranges.length; i++) {
      _authorizeRange(attester, ranges[i].min, ranges[i].max);
    }
  }

  function unauthorizeRange(
    address attester,
    uint256 rangeIndex,
    uint256 firstId,
    uint256 lastId
  ) external override onlyOwner {
    _unauthorizeRange(attester, rangeIndex, firstId, lastId);
  }

  function unauthorizeRanges(
    address attester,
    Range[] memory ranges,
    uint256[] memory rangeIndexes
  ) external override onlyOwner {
    for (uint256 i = 0; i < rangeIndexes.length; i++) {
      _unauthorizeRange(attester, rangeIndexes[i], ranges[i].min, ranges[i].max);
    }
  }

  function isAuthorized(address attester, uint256 collectionId) external view returns (bool) {
    return _isAuthorized(attester, collectionId);
  }

  function getAuthorizedRange(address attester, uint256 rangeIndex)
    external
    view
    returns (uint256, uint256)
  {
    if (rangeIndex >= _authorizedRanges[attester].length)
      revert RangeIndexOutOfBounds(attester, _authorizedRanges[attester].length, rangeIndex);
    return (
      _authorizedRanges[attester][rangeIndex].min,
      _authorizedRanges[attester][rangeIndex].max
    );
  }

  function pause() external override onlyOwner {
    _pause();
  }

  function unpause() external override onlyOwner {
    _unpause();
  }

  function _isAuthorized(address attester, uint256 collectionId) internal view returns (bool) {
    return _authorizedRanges[attester]._includes(collectionId);
  }

  function _authorizeRange(
    address attester,
    uint256 firstId,
    uint256 lastId
  ) internal {
    Range memory newRange = Range(firstId, lastId);
    _authorizedRanges[attester].push(newRange);
    emit AttesterAuthorized(attester, firstId, lastId);
  }

  function _unauthorizeRange(
    address attester,
    uint256 rangeIndex,
    uint256 firstId,
    uint256 lastId
  ) internal onlyOwner {
    if (rangeIndex >= _authorizedRanges[attester].length)
      revert RangeIndexOutOfBounds(attester, _authorizedRanges[attester].length, rangeIndex);

    uint256 expectedFirstId = _authorizedRanges[attester][rangeIndex].min;
    uint256 expectedLastId = _authorizedRanges[attester][rangeIndex].max;
    if (firstId != expectedFirstId || lastId != expectedLastId)
      revert IdsMismatch(attester, rangeIndex, expectedFirstId, expectedLastId, firstId, lastId);

    _authorizedRanges[attester][rangeIndex] = _authorizedRanges[attester][
      _authorizedRanges[attester].length - 1
    ];
    _authorizedRanges[attester].pop();
    emit AttesterUnauthorized(attester, rangeIndex, firstId, lastId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import '../utils/Address.sol';
import './AttestationsRegistryState.sol';

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
abstract contract InitializableLogic is AttestationsRegistryState {
  // only diff with oz
  // /**
  //  * @dev Indicates that the contract has been initialized.
  //  */
  // bool private _initialized;

  // /**
  //  * @dev Indicates that the contract is in the process of being initialized.
  //  */
  // bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
    // contract may have been reentered.
    require(
      _initializing ? _isConstructor() : !_initialized,
      'Initializable: contract is already initialized'
    );

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
    require(_initializing, 'Initializable: contract is not initializing');
    _;
  }

  function _isConstructor() private view returns (bool) {
    return !Address.isContract(address(this));
  }
}

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import '../utils/Context.sol';
import './AttestationsRegistryState.sol';

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
abstract contract OwnableLogic is Context, AttestationsRegistryState {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // This is the only diff with OZ contract
  // address private _owner;

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import '../utils/Context.sol';
import './AttestationsRegistryState.sol';

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableLogic is Context, AttestationsRegistryState {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  // this is the only diff with OZ contract
  // bool private _paused;

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
    require(!paused(), 'Pausable: paused');
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
    require(paused(), 'Pausable: not paused');
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCall(target, data, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    require(isContract(target), 'Address: static call to non-contract');

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
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
    require(isContract(target), 'Address: delegate call to non-contract');

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

pragma solidity ^0.8.12;

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.12;

struct Range {
  uint256 min;
  uint256 max;
}

// Range [0;3] includees 0 and 3
library RangeUtils {
  function _includes(Range[] storage ranges, uint256 collectionId) internal view returns (bool) {
    for (uint256 i = 0; i < ranges.length; i++) {
      if (collectionId >= ranges[i].min && collectionId <= ranges[i].max) {
        return true;
      }
    }
    return false;
  }
}