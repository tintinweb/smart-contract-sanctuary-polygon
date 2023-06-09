// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IPOK } from "../interfaces/IPOK.sol";
import { IPookyball, PookyballMetadata } from "../interfaces/IPookyball.sol";

struct Pricing {
  uint256 requiredPXP;
  uint256 remainingPXP;
  uint256 newLevel;
  uint256 gapPOK;
  uint256 feePOK;
}

contract PookyballLevel {
  uint256 public constant PXP_DECIMALS = 18;
  uint256 public constant BASE_RATIO = 10000;
  /// @dev How much PXP is necessary is required to pass to the level 0 => 1.
  uint256 public constant BASE_PXP = 60 * 10 ** PXP_DECIMALS;
  /// @dev The POK fee is required to pass the level (over 10000).
  uint256 public constant FEE_RATIO = 800;
  /// @dev Level up POK ratio increase (over 10000).
  uint256 public constant LEVEL_RATIO = 10750;
  /// @dev How much POK is 1 PXP point (over 10000).
  uint256 public constant PXP_POK_RATIO = 1250;
  /// @dev How much POK is 1 MATIC point (over 10000).
  uint256 public constant MATIC_POK_RATIO = 350;

  IPookyball immutable pookyball;
  IPOK immutable pok;
  address immutable treasury;

  mapping(uint256 => uint256) public slots;

  /// Thrown when an account tries to level a ball above its maximum level.
  error MaximumLevelReached(uint256 tokenId, uint256 maxLevel);
  /// Thrown when an account does own enough $POK token to pay the level up fee
  error InsufficientPOK(uint256 expected, uint256 actual);
  /// Thrown when the native transfer has failed.
  error TransferFailed(address recipient, uint256 amount);

  constructor(IPookyball _pookyball, IPOK _pok, address _treasury) {
    pookyball = _pookyball;
    pok = _pok;
    treasury = _treasury;
    slots[1] = BASE_PXP;
    compute(2, 120);
  }

  function compute(uint256 from, uint256 to) public {
    for (uint256 i = from; i <= to;) {
      slots[i] = slots[i - 1] * LEVEL_RATIO / 10000;
      unchecked {
        i++;
      }
    }
  }

  function getPricing(uint256 tokenId, uint256 increase, uint256 value)
    public
    view
    returns (Pricing memory pricing)
  {
    PookyballMetadata memory metadata = pookyball.metadata(tokenId);
    for (uint256 i = 1; i <= increase; i++) {
      pricing.requiredPXP += slots[metadata.level + i];
    }

    if (pricing.requiredPXP > metadata.pxp) {
      pricing.gapPOK = (pricing.requiredPXP - metadata.pxp) * PXP_POK_RATIO / BASE_RATIO;
    } else {
      pricing.remainingPXP = metadata.pxp - pricing.requiredPXP;
    }

    pricing.feePOK = pricing.requiredPXP * FEE_RATIO / BASE_RATIO;
    uint256 coverPOK = value * BASE_RATIO / MATIC_POK_RATIO;

    if (pricing.feePOK > coverPOK) {
      pricing.feePOK -= coverPOK;
    } else {
      pricing.feePOK = 0;
    }

    pricing.newLevel = metadata.level + increase;
  }

  function levelUp(uint256 tokenId, uint256 increase) external payable {
    Pricing memory pricing = getPricing(tokenId, increase, msg.value);
    uint256 requiredPOK = pricing.gapPOK + pricing.feePOK;

    uint256 balancePOK = pok.balanceOf(msg.sender);
    if (requiredPOK > balancePOK) {
      revert InsufficientPOK(requiredPOK, balancePOK);
    }

    // Burn $POK tokens
    pok.burn(msg.sender, requiredPOK);

    // Reset the ball PXP
    pookyball.setPXP(tokenId, pricing.remainingPXP);
    // Increment the ball level
    pookyball.setLevel(tokenId, pricing.newLevel);

    if (msg.value > 0) {
      // Forward the funds to the treasury wallet
      (bool sent,) = treasury.call{ value: msg.value }("");
      if (!sent) {
        revert TransferFailed(treasury, msg.value);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (interfaces/IPOK.sol)
pragma solidity ^0.8.17;

import "openzeppelin/access/IAccessControl.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

/**
 * @title IPOK
 * @author Mathieu Bour
 * @notice Minimal $POK ERC20 token interface.
 */
interface IPOK is IAccessControl, IERC20 {
  /**
   * @notice Mint an arbitrary amount of $POK to an account.
   * @dev Requirements:
   * - only MINTER role can mint $POK tokens
   */
  function mint(address to, uint256 amount) external;

  /**
   * @notice Burn an arbitrary amount of $POK of an sender account.
   * It is acknowledged that burning directly from the user wallet is anti-pattern
   * but since $POK is soulbounded, this allow to skip the ERC20 approve call.
   * @dev Requirements:
   * - only BURNER role can burn $POK tokens
   */
  function burn(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (interfaces/IPookyball.sol)
pragma solidity ^0.8.17;

import "openzeppelin/access/IAccessControl.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/interfaces/IERC2981.sol";

/**
 * @title PookyballMetadata
 * @notice The Pookyball rarities are represented on chain by this enum.
 */
enum PookyballRarity {
  COMMON,
  RARE,
  EPIC,
  LEGENDARY,
  MYTHIC
}

/**
 * @title PookyballMetadata
 * @notice Pookyballs NFT have the following features:
 * - rarity: integer enum.
 * - level: token level, can be increase by spending token experiences points (PXP).
 * - pxp: token experience points.
 * - seed: a random uint256 word provided by Chainlink VRF service that will be used by Pooky's NFT generator
 *     back-end to generate the NFT visuals and in-game statistics\.
 */
struct PookyballMetadata {
  PookyballRarity rarity;
  uint256 level;
  uint256 pxp;
  uint256 seed;
}

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
  error ArgumentSizeMismatch(uint256 x, uint256 y);

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
   * @notice Mint a new Pookyball token with a given rarity.
   */
  function mint(address[] memory recipients, PookyballRarity[] memory rarities)
    external
    returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
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