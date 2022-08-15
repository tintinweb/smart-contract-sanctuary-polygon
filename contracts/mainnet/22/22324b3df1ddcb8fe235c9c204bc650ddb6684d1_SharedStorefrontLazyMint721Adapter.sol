// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SharedStorefrontLazyMint721Adapter {
    IERC721 immutable ssfToken;
    //TODO
    // need reset
    address private constant SEAPORT =
        0xd1814cc78128A1C7ad3A34fD22E0f498dDE4Feb8;
    address private constant CONDUIT =
        0x03257C5f75031287487a5a2DDd2df9c7A771F167;

    error InsufficientBalance();
    error UnauthorizedCaller();

    modifier onlySeaportOrConduit() {
        if (msg.sender != CONDUIT && msg.sender != SEAPORT) {
            revert UnauthorizedCaller();
        }
        _;
    }

    /// @dev parameterless constructor allows us to CREATE2 this contract at the same address on each network
    constructor() {
        // can't set immutables within an if statement; use temp var
        address tokenAddress;

        uint256 chainId = block.chainid;
        //TODO
        // need reset
        // use chainId to get network SSF address
         if (chainId == 3) {
            // ropsten SSF
            tokenAddress = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
        } else if (chainId == 4) {
            // rinkeby SSF
            tokenAddress = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
        } else if (chainId == 137 || chainId == 80001) {
            // polygon + mumbai SSF
            tokenAddress = 0xCb9115b653F99094377ae333F0A34303e727E5Db;
        } else {
            // mainnet SSF
            tokenAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
        }

        ssfToken = IERC721(tokenAddress);
    }

    /**
     * @notice stub method that performs two checks before calling real SSF safeTransferFrom
     *   1. check that the caller is a valid proxy (Seaport or OpenSea conduit)
     *   2. check that the token spender owns enough tokens, or is the creator of
     *      the token and not all tokens have been minted yet
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory
    ) public onlySeaportOrConduit {
        // Seaport 1.1 always calls safeTransferFrom with empty data
        ssfToken.safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice pass-through balanceOf method to the SSF for backwards-compatibility with seaport-js
     * @param owner address to check balance of
     * @return uint256 balance of tokenId for owner
     */
    function balanceOf(address owner)
        public
        view
        returns (uint256)
    {
        return ssfToken.balanceOf(owner);
    }

    /**
     * @notice stub isApprovedForAll method for backwards-compatibility with seaport-js
     * @param operator address to check approval of
     * @return bool if operator is Conduit or Seaport
     */
    function isApprovedForAll(address, address operator)
        public
        pure
        returns (bool)
    {
        return operator == CONDUIT || operator == SEAPORT;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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