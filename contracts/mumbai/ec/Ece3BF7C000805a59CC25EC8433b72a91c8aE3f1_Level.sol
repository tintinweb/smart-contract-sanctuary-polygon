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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// Pooky Game Contracts (game/Level.sol)
pragma solidity ^0.8.17;

import "../interfaces/IPookyball.sol";
import "../interfaces/IPOK.sol";
import "../types/PookyballRarity.sol";

/**
 * @title Level
 * @author Mathieu Bour
 * @notice Gameplay contract that allow to level up Pookyball tokens.
 * @dev Technically, this contract is allowed to write the Pookyball.metadata mapping using the setLevel and
 * setPXP functions.
 */
contract Level {
  // Contracts
  IPookyball public immutable pookyball;
  IPOK public immutable pok;

  uint256 public constant PXP_DECIMALS = 18;
  uint256 public constant PXP_BASE = 60 * 10 ** PXP_DECIMALS;
  uint256 public constant RATIO_DECIMALS = 3;
  uint256 public constant RATIO_PXP = 1085; // =1.085: each level costs 1.085 more than the previous one.
  uint256 public constant RATIO_POK = 90; // =0.090: 9% of PXP cost is required in $POK tokens to confirm level up.

  mapping(PookyballRarity => uint256) public maxLevels;

  /// Thrown when an account tries to level up a ball that is not owned the sender.
  error OwnershipRequired(uint256 tokenId, address expected, address actual);
  /// Thrown when an account tries to level a ball above its maximum level.
  error MaximumLevelReached(uint256 tokenId, uint256 maxLevel);
  error InsufficientPOKBalance(uint expected, uint actual);

  constructor(IPOK _pok, IPookyball _pookyball) {
    pok = _pok;
    pookyball = _pookyball;

    // Set the maximum levels as described in the Pooky whitepaper
    // see https://whitepaper.pooky.gg/pookyball-features/levelling-up
    maxLevels[PookyballRarity.COMMON] = 40;
    maxLevels[PookyballRarity.RARE] = 60;
    maxLevels[PookyballRarity.EPIC] = 80;
    maxLevels[PookyballRarity.LEGENDARY] = 100;
    maxLevels[PookyballRarity.MYTHIC] = 100;
  }

  /**
   * Get the PXP required to level up a ball to {level}.
   * @param level The targeted level.
   */
  function levelPXP(uint256 level) public pure returns (uint256) {
    if (level == 0) {
      return 0;
    }

    uint256 acc = PXP_BASE;
    for (uint256 i = 1; i < level; i++) {
      acc = (acc * RATIO_PXP) / 10 ** 3;
    }

    return acc;
  }

  /**
   * Get the $POK tokens required to level up a ball to {level}. This does not take the ball PXP into account.
   * @param level The targeted level.
   */
  function levelPOK(uint256 level) public pure returns (uint256) {
    return (levelPXP(level) * RATIO_POK) / 10 ** RATIO_DECIMALS;
  }

  /**
   * Get the $POK tokens required to level up the ball identified by {tokenId}.
   * This computation the ball PXP into account and add an additional POK fee if ball does not have enough PXP.
   * @param tokenId The targeted token id.
   */
  function levelPOKCost(uint256 tokenId, uint levels) public view returns (uint256) {
    PookyballMetadata memory metadata = pookyball.metadata(tokenId);
    uint256 requiredPXP = 0;
    uint256 requiredPOK = 0;

    for (uint i = 1; i <= levels; i++) {
      requiredPXP += levelPXP(metadata.level + i);
      requiredPOK += levelPOK(metadata.level + i);
    }

    if (requiredPXP <= metadata.pxp) {
      return requiredPOK;
    } else {
      // If the ball has not enough PXP, missing PXP can be covered with $POK tokens at {POK_FACTOR} ratio
      return requiredPOK + ((requiredPXP - metadata.pxp) * RATIO_POK) / 10 ** RATIO_DECIMALS;
    }
  }

  /**
   * @notice Level up a Pookyball in exchange of a certain amount of $POK token.
   * @dev Requirements
   * - msg.sender must be the owner of Pookyball tokenId.
   * - msg.sender must own enough $POK tokens to pay the level up fee.
   * - Pookyball level should be strictly less than the maximum allowed level for its rarity.
   */
  function levelUp(uint256 tokenId, uint levels) external {
    PookyballMetadata memory metadata = pookyball.metadata(tokenId);
    uint256 nextLevel = metadata.level + levels;
    uint256 remainingPXP = 0;
    uint256 requiredPXP = 0;

    for (uint i = 1; i <= levels; i++) {
      requiredPXP += levelPXP(metadata.level + i);
    }

    if (pookyball.ownerOf(tokenId) != msg.sender) {
      revert OwnershipRequired(tokenId, pookyball.ownerOf(tokenId), msg.sender);
    }

    uint256 levelPOKCost_ = levelPOKCost(tokenId, levels);
    if (levelPOKCost_ > pok.balanceOf(msg.sender)) {
      revert InsufficientPOKBalance(levelPOKCost_, pok.balanceOf(msg.sender));
    }

    if (nextLevel > maxLevels[metadata.rarity]) {
      revert MaximumLevelReached(tokenId, maxLevels[metadata.rarity]);
    }

    if (metadata.pxp > requiredPXP) {
      remainingPXP = metadata.pxp - requiredPXP;
    }

    // Burn $POK tokens
    pok.burn(msg.sender, levelPOKCost_);

    // Reset the ball PXP
    pookyball.setPXP(tokenId, remainingPXP);
    // Increment the ball level
    pookyball.setLevel(tokenId, nextLevel);
  }
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (interfaces/IPOK.sol)
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IPOK
 * @author Mathieu Bour
 * Minimal $POK ERC20 token interface.
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

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../types/PookyballMetadata.sol";

/**
 * @title IPookyball
 * Minimal Pookyball interface.
 */
interface IPookyball is IAccessControl, IERC2981, IERC721 {
  /// Thrown when the length of two parameters mismatch. Used in the mint batched function.
  error ArgumentSizeMismatch(uint256 x, uint256 y, uint256 z);

  /**
   * @notice PookyballMetadata of the token {tokenId}.
   * @dev Requirements:
   * - Pookyball {tokenId} should exist (minted and not burned).
   */
  function metadata(uint256 tokenId) external view returns (PookyballMetadata memory);

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