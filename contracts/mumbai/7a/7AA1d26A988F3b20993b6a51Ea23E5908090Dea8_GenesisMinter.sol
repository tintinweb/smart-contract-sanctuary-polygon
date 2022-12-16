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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../types/PookyballMetadata.sol";

/**
 * @title IPookyball
 * Minimal Pookyball interface.
 */
interface IPookyball is IERC721 {
  function metadata(uint256 tokenId) external view returns (PookyballMetadata memory);

  function mint(address recipient, PookyballRarity rarity, uint256 luxury) external returns (uint256);

  function setLevel(uint256 tokenId, uint256 newLevel) external;

  function setPXP(uint256 tokenId, uint256 newPXP) external;
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (interfaces/IWaitList.sol)
pragma solidity ^0.8.17;

interface IWaitList {
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
 * @notice Mint contract for the Pooky "genesis" collection.
 */
contract GenesisMinter {
  IPookyball public immutable pookyball;
  address immutable treasury;

  uint256 public lastTemplateId;
  mapping(uint256 => Template) public templates;

  IWaitList public immutable waitlist;

  event Sale(address indexed account, uint256 indexed templateId, uint256 quantity, uint256 value);

  /// Thrown when an account is not eligible from the waitlist point of view.
  error Ineligible(address account);
  /// Thrown when a mint would exceed the template supply.
  error InsufficientSupply(uint256 templateId, uint256 remaining);
  /// Thrown when the msg.value of the mint function does not cover the mint cost.
  error InsufficientValue(uint256 expected, uint256 actual);
  /// Thrown when the native transfer has failed.
  error TransferFailed(address recipient, uint256 amount);

  constructor(IPookyball _pookyball, IWaitList _waitlist, address _treasury, Template[] memory _templates) {
    pookyball = _pookyball;
    waitlist = _waitlist;
    treasury = _treasury;

    for (uint i = 0; i < _templates.length; i++) {
      templates[++lastTemplateId] = _templates[i];
    }
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

    // Actual Pookyball token mint
    for (uint256 i = 0; i < quantity; i++) {
      pookyball.mint(recipient, template.rarity, template.luxury);
    }

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