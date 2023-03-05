// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
███████╗██╗    ██╗███████╗███████╗████████╗███╗   ███╗ █████╗ ███╗   ██╗   ███████╗████████╗██╗  ██╗
██╔════╝██║    ██║██╔════╝██╔════╝╚══██╔══╝████╗ ████║██╔══██╗████╗  ██║   ██╔════╝╚══██╔══╝██║  ██║
███████╗██║ █╗ ██║█████╗  █████╗     ██║   ██╔████╔██║███████║██╔██╗ ██║   █████╗     ██║   ███████║
╚════██║██║███╗██║██╔══╝  ██╔══╝     ██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║   ██╔══╝     ██║   ██╔══██║
███████║╚███╔███╔╝███████╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║ ╚████║██╗███████╗   ██║   ██║  ██║
╚══════╝ ╚══╝╚══╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝                                                                                              
*/
import {IERC721Drop} from "./interfaces/IERC721Drop.sol";
import {IERC721A} from "@ERC721A/contracts/IERC721A.sol";

contract ZoraCrossmintAdapter {
    /// @notice mint target ERC721Drop
    /// @param _target ERC721Drop contract address
    /// @param _quantity number of tokens
    /// @param _to recipient of tokens
    function purchase(
        address _target,
        uint256 _quantity,
        address _to
    ) public payable {
        IERC721Drop erc721 = IERC721Drop(_target);
        uint256 start = erc721.purchase{value: msg.value}(_quantity) + 1;
        for (uint256 i = start; i < start + _quantity; i++) {
            IERC721A(_target).transferFrom(address(this), _to, i);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IMetadataRenderer} from "./IMetadataRenderer.sol";

/**

 ________   _____   ____    ______      ____
/\_____  \ /\  __`\/\  _`\ /\  _  \    /\  _`\
\/____//'/'\ \ \/\ \ \ \L\ \ \ \L\ \   \ \ \/\ \  _ __   ___   _____     ____
     //'/'  \ \ \ \ \ \ ,  /\ \  __ \   \ \ \ \ \/\`'__\/ __`\/\ '__`\  /',__\
    //'/'___ \ \ \_\ \ \ \\ \\ \ \/\ \   \ \ \_\ \ \ \//\ \L\ \ \ \L\ \/\__, `\
    /\_______\\ \_____\ \_\ \_\ \_\ \_\   \ \____/\ \_\\ \____/\ \ ,__/\/\____/
    \/_______/ \/_____/\/_/\/ /\/_/\/_/    \/___/  \/_/ \/___/  \ \ \/  \/___/
                                                                 \ \_\
                                                                  \/_/

*/

/// @notice Interface for ZORA Drops contract
interface IERC721Drop {
    // Access errors

    /// @notice Only admin can access this function
    error Access_OnlyAdmin();
    /// @notice Missing the given role or admin access
    error Access_MissingRoleOrAdmin(bytes32 role);
    /// @notice Withdraw is not allowed by this user
    error Access_WithdrawNotAllowed();
    /// @notice Cannot withdraw funds due to ETH send failure.
    error Withdraw_FundsSendFailure();

    // Sale/Purchase errors
    /// @notice Sale is inactive
    error Sale_Inactive();
    /// @notice Presale is inactive
    error Presale_Inactive();
    /// @notice Presale merkle root is invalid
    error Presale_MerkleNotApproved();
    /// @notice Wrong price for purchase
    error Purchase_WrongPrice(uint256 correctPrice);
    /// @notice NFT sold out
    error Mint_SoldOut();
    /// @notice Too many purchase for address
    error Purchase_TooManyForAddress();
    /// @notice Too many presale for address
    error Presale_TooManyForAddress();

    // Admin errors
    /// @notice Royalty percentage too high
    error Setup_RoyaltyPercentageTooHigh(uint16 maxRoyaltyBPS);
    /// @notice Invalid admin upgrade address
    error Admin_InvalidUpgradeAddress(address proposedAddress);
    /// @notice Unable to finalize an edition not marked as open (size set to uint64_max_value)
    error Admin_UnableToFinalizeNotOpenEdition();

    /// @notice Event emitted for each sale
    /// @param to address sale was made to
    /// @param quantity quantity of the minted nfts
    /// @param pricePerToken price for each token
    /// @param firstPurchasedTokenId first purchased token ID (to get range add to quantity for max)
    event Sale(
        address indexed to,
        uint256 indexed quantity,
        uint256 indexed pricePerToken,
        uint256 firstPurchasedTokenId
    );

    /// @notice Sales configuration has been changed
    /// @dev To access new sales configuration, use getter function.
    /// @param changedBy Changed by user
    event SalesConfigChanged(address indexed changedBy);

    /// @notice Event emitted when the funds recipient is changed
    /// @param newAddress new address for the funds recipient
    /// @param changedBy address that the recipient is changed by
    event FundsRecipientChanged(
        address indexed newAddress,
        address indexed changedBy
    );

    /// @notice Event emitted when the funds are withdrawn from the minting contract
    /// @param withdrawnBy address that issued the withdraw
    /// @param withdrawnTo address that the funds were withdrawn to
    /// @param amount amount that was withdrawn
    event FundsWithdrawn(
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount
    );

    /// @notice Event emitted when an open mint is finalized and further minting is closed forever on the contract.
    /// @param sender address sending close mint
    /// @param numberOfMints number of mints the contract is finalized at
    event OpenMintFinalized(address indexed sender, uint256 numberOfMints);

    /// @notice Event emitted when metadata renderer is updated.
    /// @param sender address of the updater
    /// @param renderer new metadata renderer address
    event UpdatedMetadataRenderer(address sender, IMetadataRenderer renderer);

    /// @notice General configuration for NFT Minting and bookkeeping
    struct Configuration {
        /// @dev Metadata renderer (uint160)
        IMetadataRenderer metadataRenderer;
        /// @dev Total size of edition that can be minted (uint160+64 = 224)
        uint64 editionSize;
        /// @dev Royalty amount in bps (uint224+16 = 240)
        uint16 royaltyBPS;
        /// @dev Funds recipient for sale (new slot, uint160)
        address payable fundsRecipient;
    }

    /// @notice Sales states and configuration
    /// @dev Uses 3 storage slots
    struct SalesConfiguration {
        /// @dev Public sale price (max ether value > 1000 ether with this value)
        uint104 publicSalePrice;
        /// @notice Purchase mint limit per address (if set to 0 === unlimited mints)
        /// @dev Max purchase number per txn (90+32 = 122)
        uint32 maxSalePurchasePerAddress;
        /// @dev uint64 type allows for dates into 292 billion years
        /// @notice Public sale start timestamp (136+64 = 186)
        uint64 publicSaleStart;
        /// @notice Public sale end timestamp (186+64 = 250)
        uint64 publicSaleEnd;
        /// @notice Presale start timestamp
        /// @dev new storage slot
        uint64 presaleStart;
        /// @notice Presale end timestamp
        uint64 presaleEnd;
        /// @notice Presale merkle root
        bytes32 presaleMerkleRoot;
    }

    /// @notice Sales states and configuration
    /// @dev Uses 3 storage slots
    struct ERC20SalesConfiguration {
        /// @notice Public sale price
        /// @dev max ether value > 1000 ether with this value
        uint104 publicSalePrice;
        /// @dev ERC20 Token
        address erc20PaymentToken;
        /// @notice Purchase mint limit per address (if set to 0 === unlimited mints)
        /// @dev Max purchase number per txn (90+32 = 122)
        uint32 maxSalePurchasePerAddress;
        /// @dev uint64 type allows for dates into 292 billion years
        /// @notice Public sale start timestamp (136+64 = 186)
        uint64 publicSaleStart;
        /// @notice Public sale end timestamp (186+64 = 250)
        uint64 publicSaleEnd;
        /// @notice Presale start timestamp
        /// @dev new storage slot
        uint64 presaleStart;
        /// @notice Presale end timestamp
        uint64 presaleEnd;
        /// @notice Presale merkle root
        bytes32 presaleMerkleRoot;
    }

    /// @notice Return value for sales details to use with front-ends
    struct SaleDetails {
        // Synthesized status variables for sale and presale
        bool publicSaleActive;
        bool presaleActive;
        // Price for public sale
        uint256 publicSalePrice;
        // Timed sale actions for public sale
        uint64 publicSaleStart;
        uint64 publicSaleEnd;
        // Timed sale actions for presale
        uint64 presaleStart;
        uint64 presaleEnd;
        // Merkle root (includes address, quantity, and price data for each entry)
        bytes32 presaleMerkleRoot;
        // Limit public sale to a specific number of mints per wallet
        uint256 maxSalePurchasePerAddress;
        // Information about the rest of the supply
        // Total that have been minted
        uint256 totalMinted;
        // The total supply available
        uint256 maxSupply;
    }

    /// @notice Return value for sales details to use with front-ends
    struct ERC20SaleDetails {
        /// @notice Synthesized status variables for sale
        bool publicSaleActive;
        /// @notice Synthesized status variables for presale
        bool presaleActive;
        /// @notice Price for public sale
        uint256 publicSalePrice;
        /// @notice ERC20 contract address for payment. address(0) for ETH.
        address erc20PaymentToken;
        /// @notice public sale start
        uint64 publicSaleStart;
        /// @notice public sale end
        uint64 publicSaleEnd;
        /// @notice Timed sale actions for presale start
        uint64 presaleStart;
        /// @notice Timed sale actions for presale end
        uint64 presaleEnd;
        /// @notice Merkle root (includes address, quantity, and price data for each entry)
        bytes32 presaleMerkleRoot;
        /// @notice Limit public sale to a specific number of mints per wallet
        uint256 maxSalePurchasePerAddress;
        /// @notice Total that have been minted
        uint256 totalMinted;
        /// @notice The total supply available
        uint256 maxSupply;
    }

    /// @notice Return type of specific mint counts and details per address
    struct AddressMintDetails {
        /// Number of total mints from the given address
        uint256 totalMints;
        /// Number of presale mints from the given address
        uint256 presaleMints;
        /// Number of public mints from the given address
        uint256 publicMints;
    }

    /// @notice External purchase function (payable in eth)
    /// @param quantity to purchase
    /// @return first minted token ID
    function purchase(uint256 quantity) external payable returns (uint256);

    /// @notice External purchase presale function (takes a merkle proof and matches to root) (payable in eth)
    /// @param quantity to purchase
    /// @param maxQuantity can purchase (verified by merkle root)
    /// @param pricePerToken price per token allowed (verified by merkle root)
    /// @param merkleProof input for merkle proof leaf verified by merkle root
    /// @return first minted token ID
    function purchasePresale(
        uint256 quantity,
        uint256 maxQuantity,
        uint256 pricePerToken,
        bytes32[] memory merkleProof
    ) external payable returns (uint256);

    /// @notice Function to return the global sales details for the given drop
    function saleDetails() external view returns (ERC20SaleDetails memory);

    /// @notice Function to return the specific sales details for a given address
    /// @param minter address for minter to return mint information for
    function mintedPerAddress(address minter)
        external
        view
        returns (AddressMintDetails memory);

    /// @notice This is the opensea/public owner setting that can be set by the contract admin
    function owner() external view returns (address);

    /// @notice Update the metadata renderer
    /// @param newRenderer new address for renderer
    /// @param setupRenderer data to call to bootstrap data for the new renderer (optional)
    function setMetadataRenderer(
        IMetadataRenderer newRenderer,
        bytes memory setupRenderer
    ) external;

    /// @notice This is an admin mint function to mint a quantity to a specific address
    /// @param to address to mint to
    /// @param quantity quantity to mint
    /// @return the id of the first minted NFT
    function adminMint(address to, uint256 quantity) external returns (uint256);

    /// @notice This is an admin mint function to mint a single nft each to a list of addresses
    /// @param to list of addresses to mint an NFT each to
    /// @return the id of the first minted NFT
    function adminMintAirdrop(address[] memory to) external returns (uint256);

    /// @dev Getter for admin role associated with the contract to handle metadata
    /// @return boolean if address is admin
    function isAdmin(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory initData) external;
}