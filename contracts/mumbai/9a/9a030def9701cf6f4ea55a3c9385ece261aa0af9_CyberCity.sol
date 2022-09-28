/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File contracts/interfaces/ICyberSpawnAccessControl.sol



pragma solidity ^0.8.0;

interface ICyberSpawnAccessControl {
  function hasAdminRole(address account) external view returns (bool);
  function hasSpawnerRole(address account) external view returns (bool);
  function hasGovernanceRole(address account) external view returns (bool);
  function hasGameRole(address account) external view returns (bool);
}


// File contracts/cybercity/CyberCity.sol


pragma solidity 0.8.0;


contract CyberCity {

  address immutable public cyberSpawnNft;
  address public accessControl;
  address public feeAddress;
  address public css;
  address public cnd;
  address public currency;
  address public presale;
  address public marketplace;
  address public auction;

  event AccessControlUpdated(address accessControl);
  event FeeAddressUpdated(address feeAddress);
  event PresaleAddressUpdated(address presale);
  event MarketplaceAddressUpdated(address marketplace);
  event AuctionAddressUpdated(address auction);

  modifier onlyAdmin() {
    require(ICyberSpawnAccessControl(accessControl).hasAdminRole(msg.sender), "not an admin");
    _;
  }

  constructor(
    address _cyberspawn,
    address _accessControl,
    address _feeAddress,
    address _css,
    address _cnd,
    address _currency
  ) {
    require(_cyberspawn != address(0), "!zero address");
    require(_accessControl != address(0), "!zero address");
    require(_feeAddress != address(0), "!zero address");
    require(_css != address(0), "!zero address");
    require(_cnd != address(0), "!zero address");
    require(_currency != address(0), "!zero address");
    cyberSpawnNft = _cyberspawn;
    accessControl = _accessControl;
    feeAddress = _feeAddress;
    css = _css;
    cnd = _cnd;
    currency = _currency;
  }

  /**
   @notice Method for updating the access controls contract used by the NFT
   @dev Only admin
   @param _accessControl Address of the new access controls contract (Cannot be zero address)
   */
  function updateAccessControls(address _accessControl) external onlyAdmin {
    require(_accessControl != address(0), "!zero address");
    accessControl = _accessControl;
    emit AccessControlUpdated(address(_accessControl));
  }

  function updateFeeAddress(address _feeAddress) external onlyAdmin {
    require(_feeAddress != address(0), "!zero address");
    feeAddress = _feeAddress;
    emit FeeAddressUpdated(_feeAddress);
  }

  function updatePresaleAddress(address _presale) external onlyAdmin {
    require(_presale != address(0), "!zero address");
    presale = _presale;
    emit PresaleAddressUpdated(_presale);
  }

  function updateMarketplaceAddress(address _marketplace) external onlyAdmin {
    require(_marketplace != address(0), "!zero address");
    marketplace = _marketplace;
    emit MarketplaceAddressUpdated(_marketplace);
  }

  function updateAuctionAddress(address _auction) external onlyAdmin {
    require(_auction != address(0), "!zero address");
    auction = _auction;
    emit AuctionAddressUpdated(_auction);
  }

}