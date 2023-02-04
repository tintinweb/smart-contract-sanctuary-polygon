// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// Pooky Game Contracts (interfaces/IPookyball.sol)
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../types/PookyballMetadata.sol";

/**
 * @title IPookyball
 * @author Mathieu Bour
 * @notice Minimal Pookyball interface.
 */
interface IPookyball is IAccessControl, IERC2981, IERC721 {
  /// Fired when the seed of a Pookyball token is set by the VRFCoordinator
  event SeedSet(uint256 indexed tokenId, uint256 seed);
  /// Fired when the level of a Pookyball token is changed
  event LevelChanged(uint256 indexed tokenId, uint256 level);
  /// Fired when the PXP of a Pookyball token is changed
  event PXPChanged(uint256 indexed tokenId, uint256 amount);

  /// Thrown when the length of two parameters mismatch. Used in the mint batched function.
  error ArgumentSizeMismatch(uint256 x, uint256 y, uint256 z);

  /**
   * @notice PookyballMetadata of the token {tokenId}.
   * @dev Requirements:
   * - Pookyball {tokenId} should exist (minted and not burned).
   */
  function metadata(uint256 tokenId) external view returns (PookyballMetadata memory);

  /**
   * @notice Change the secondary sale royalties receiver address.
   */
  function setERC2981Receiver(address newReceiver) external;

  /**
   * @notice Mint a new Pookyball token with a given rarity and luxury.
   */
  function mint(
    address[] memory recipients,
    PookyballRarity[] memory rarities,
    uint256[] memory luxuries
  ) external returns (uint256);

  /**
   * @notice Change the level of a Pookyball token.
   * @dev Requirements:
   * - Pookyball {tokenId} should exist (minted and not burned).
   */
  function setLevel(uint256 tokenId, uint256 newLevel) external;

  /**
   * @notice Change the PXP of a Pookyball token.
   * @dev Requirements:
   * - Pookyball {tokenId} should exist (minted and not burned).
   */
  function setPXP(uint256 tokenId, uint256 newPXP) external;
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (interfaces/IWaitList.sol)
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IWaitList
 * @author Mathieu Bour
 * @notice Minimal tiered waitlist implementation.
 */
interface IWaitList is IAccessControl {
  /// Emitted when the tier of an address is set.
  event TierSet(address indexed account, uint256 tier);

  /// Thrown when the length of two parameters mismatch. Used in batched functions.
  error ArgumentSizeMismatch(uint256 x, uint256 y);

  /**
   * Change the minimum required tier to be considered as "eligible".
   * @param newRequiredTier The new required tier.
   */
  function setRequiredTier(uint256 newRequiredTier) external;

  /**
   * @notice Set the tier of multiple accounts at the same time.
   * @param accounts The account addresses.
   * @param tiers The associated tiers.
   */
  function setBatch(address[] memory accounts, uint256[] memory tiers) external;

  /**
   * @notice Check if an account is eligible.
   * @param account The account address to lookup.
   * @return If the account is eligible.
   */
  function isEligible(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (GenesisMinter.sol)
pragma solidity ^0.8.17;

import "../interfaces/IPookyball.sol";
import "../interfaces/IWaitList.sol";
import "../types/PookyballRarity.sol";

struct Template {
  PookyballRarity rarity;
  uint256 luxury;
  uint256 supply;
  uint256 minted;
  uint256 price;
}

/**
 * @title GenesisMinter
 * @author Mathieu Bour
 * @notice Mint contract for the Pooky "genesis" collection.
 */
contract GenesisMinter {
  // Contracts
  IPookyball public immutable pookyball;
  IWaitList public immutable waitlist;

  /// Where the mint funds will be forwarded
  address immutable treasury;

  /// The lasted assigned template id, useful to iterate over the templates.
  uint256 public nextTemplateId;
  mapping(uint256 => Template) public templates;

  /// Fired when a sale is made
  event Sale(address indexed account, uint256 indexed templateId, uint256 quantity, uint256 value);

  /// Thrown when an account is not eligible from the waitlist point of view.
  error Ineligible(address account);
  /// Thrown when a mint would exceed the template supply.
  error InsufficientSupply(uint256 templateId, uint256 remaining);
  /// Thrown when the msg.value of the mint function does not cover the mint cost.
  error InsufficientValue(uint256 expected, uint256 actual);
  /// Thrown when the native transfer has failed.
  error TransferFailed(address recipient, uint256 amount);

  /**
   * @param _pookyball The Pookyball ERC721 contract address.
   * @param _waitlist The WaitList contract.
   * @param _treasury The account which will receive all the funds.
   * @param _templates The available mint templates.
   */
  constructor(IPookyball _pookyball, IWaitList _waitlist, address _treasury, Template[] memory _templates) {
    pookyball = _pookyball;
    waitlist = _waitlist;
    treasury = _treasury;

    for (uint i = 0; i < _templates.length; i++) {
      templates[nextTemplateId++] = _templates[i];
    }
  }

  /**
   * @return The available mint templates (the same as the ones passed in the constructor).
   */
  function getTemplates() external view returns (Template[] memory) {
    Template[] memory _templates = new Template[](nextTemplateId);

    for (uint i = 0; i < nextTemplateId; i++) {
      _templates[i] = templates[i];
    }

    return _templates;
  }

  /**
   * @notice Mint one or more Pookyball token to a account.
   * @dev Requirements:
   * - template should exists (check with the InsufficientSupply error)
   * - template should have enough supply
   * - enough native currency should be sent to cover the mint price
   */
  function mint(uint256 templateId, address recipient, uint256 quantity) external payable {
    if (!waitlist.isEligible(recipient)) {
      revert Ineligible(recipient);
    }

    Template memory template = templates[templateId];

    if (template.minted + quantity > template.supply) {
      revert InsufficientSupply(templateId, template.supply - template.minted);
    }

    if (msg.value < quantity * template.price) {
      revert InsufficientValue(quantity * template.price, msg.value);
    }

    // Build the arrays for the batched mint
    address[] memory recipients = new address[](quantity);
    PookyballRarity[] memory rarities = new PookyballRarity[](quantity);
    uint[] memory luxuries = new uint[](quantity);

    for (uint256 i = 0; i < quantity; i++) {
      recipients[i] = recipient;
      rarities[i] = template.rarity;
      luxuries[i] = template.luxury;
    }

    // Actual Pookyball token mint
    pookyball.mint(recipients, rarities, luxuries);

    templates[templateId].minted += quantity;

    // Forward the funds to the treasury wallet
    (bool sent, ) = treasury.call{ value: msg.value }("");
    if (!sent) {
      revert TransferFailed(treasury, msg.value);
    }

    emit Sale(recipient, templateId, quantity, msg.value);
  }

  /**
   * @notice return the ineligibility reason of a set of parameters.
   * Required for Paper.xyz custom contract integrations.
   * See https://docs.withpaper.com/reference/eligibilitymethod
   * @return The reason why the parameters are invalid; empty string if teh parameters are valid.
   */
  function ineligibilityReason(
    uint256 templateId,
    address recipient,
    uint256 quantity
  ) external view returns (string memory) {
    if (!waitlist.isEligible(recipient)) {
      return "not eligible yet";
    }

    if (templates[templateId].minted + quantity > templates[templateId].supply) {
      return "insufficient supply";
    }

    return "";
  }
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (types/PookyballMetadata.sol)
pragma solidity ^0.8.17;

import "./PookyballRarity.sol";

/**
 * @title PookyballMetadata
 * @notice Pookyballs NFT have the following features:
 * - rarity: integer enum.
 * - luxury: integer enum, mapping will be published and maintained by Pooky offchain.
 * - level: token level, can be increase by spending token experiences points (PXP).
 * - pxp: token experience points.
 * - seed: a random uint256 word provided by Chainlink VRF service that will be used by Pooky's NFT generator
 *     back-end to generate the NFT visuals and in-game statistics\.
 */
struct PookyballMetadata {
  PookyballRarity rarity;
  uint256 luxury;
  uint256 level;
  uint256 pxp;
  uint256 seed;
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (types/PookyballRarity.sol)
pragma solidity ^0.8.17;

enum PookyballRarity {
  COMMON,
  RARE,
  LEGENDARY,
  EPIC,
  MYTHIC
}