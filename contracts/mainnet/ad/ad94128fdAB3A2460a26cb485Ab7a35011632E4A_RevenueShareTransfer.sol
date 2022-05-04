// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "../interfaces/IFactory.sol";

library RevenueShareTransfer {
    function burnShare(
        RevenueShare shareContract,
        bool condition,
        address contractAddress,
        uint256 tokenId
    ) internal returns (uint256) {
        if (!condition) return 0;
        return
            transferShare(
                shareContract,
                true,
                contractAddress,
                tokenId,
                address(0),
                0
            );
    }

    function mintShare(
        RevenueShare shareContract,
        bool condition,
        address contractAddress,
        uint256 tokenId,
        uint256 share
    ) internal {
        if (condition) {
            transferShare(
                shareContract,
                true,
                address(0),
                0,
                contractAddress,
                tokenId,
                share
            );
        }
    }

    function transferShare(
        RevenueShare shareContract,
        bool condition,
        address contractAddress,
        uint256 from,
        uint256 to
    ) internal returns (uint256) {
        if (!condition) return 0;
        return
            transferShare(
                shareContract,
                true,
                contractAddress,
                from,
                contractAddress,
                to
            );
    }

    function transferShare(
        RevenueShare shareContract,
        bool condition,
        address fromContractAddress,
        uint256 fromTokenId,
        address toContractAddress,
        uint256 toTokenId
    ) internal returns (uint256 share) {
        if (!condition) return 0;
        share = uint256(
            shareContract.share(
                abi.encodePacked(address(fromContractAddress), fromTokenId)
            )
        );
        transferShare(
            shareContract,
            true,
            fromContractAddress,
            fromTokenId,
            toContractAddress,
            toTokenId,
            share
        );
    }

    function transferShare(
        RevenueShare shareContract,
        bool condition,
        address fromContractAddress,
        uint256 fromTokenId,
        address toContractAddress,
        uint256 toTokenId,
        uint256 share
    ) internal {
        if (condition) {
            if (fromContractAddress != address(0)) {
                shareContract.updateShare(
                    fromContractAddress,
                    fromTokenId,
                    -int256(share)
                );
            }
            if (toContractAddress != address(0)) {
                shareContract.updateShare(
                    toContractAddress,
                    toTokenId,
                    int256(share)
                );
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./IVoucher.sol";
import "./ITangiblePriceManager.sol";
import "./ITangibleFractionsNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RevenueShare {
    function claimForToken(address contractAddress, uint256 tokenId) external;

    function share(bytes memory token) external view returns (int256);

    function updateShare(
        address contractAddress,
        uint256 tokenId,
        int256 amount
    ) external;

    function unregisterContract(address contractAddress) external;
}

interface RentShare {
    function forToken(address contractAddress, uint256 tokenId)
        external
        returns (RevenueShare);
}

interface PassiveIncomeNFT {
    struct Lock {
        uint256 startTime;
        uint256 endTime;
        uint256 lockedAmount;
        uint256 multiplier;
        uint256 claimed;
        uint256 maxPayout;
    }

    function locks(uint256 piTokenId) external view returns (Lock memory lock);

    function burn(uint256 tokenId) external returns (uint256 amount);

    function maxLockDuration() external view returns (uint8);

    function claim(uint256 tokenId, uint256 amount) external;

    function canEarnForAmount(uint256 tngblAmount) external view returns (bool);

    function claimableIncome(uint256 tokenId)
        external
        view
        returns (uint256, uint256);

    function mint(
        address minter,
        uint256 lockedAmount,
        uint8 lockDurationInMonths,
        bool onlyLock,
        bool generateRevenue
    ) external returns (uint256);

    function setGenerateRevenue(uint256 piTokenId, bool generate) external;
}

/// @title IFactory interface defines the interface of the Factory which creates NFTs.
interface IFactory is IVoucher {
    event MarketplaceAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event InstantLiquidityAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );

    event WhitelistedBuyer(address indexed buyer, bool indexed approved);

    event MintedTokens(address indexed nft, uint256[] tokenIds);
    event ApprovedVendor(address vendorId, bool approved);
    event NewCategoryDeployed(address tnftCategory);
    event NewFractionDeployed(address fraction);
    event InitialFract(
        address indexed ftnft,
        uint256 indexed tokenKeep,
        uint256 indexed tokenSell
    );

    function decreaseInstantLiquidityStock(
        ITangibleNFT nft,
        uint256 fingerprint
    ) external;

    /// @dev The function which does lazy minting.
    function mint(MintVoucher calldata voucher)
        external
        returns (uint256[] memory);

    /// @dev The function lazy-burns tokens.
    function burn(BurnVoucher calldata voucher) external;

    /// @dev The function returns the address of the fee storage.
    function feeStorageAddress() external view returns (address);

    /// @dev The function returns the address of the marketplace.
    function marketplace() external view returns (address);

    /// @dev Returns dao owner
    function tangibleDao() external view returns (address);

    /// @dev The function returns the address of the tnft deployer.
    function deployer() external view returns (address);

    /// @dev The function returns the address of the priceManager.
    function priceManager() external view returns (ITangiblePriceManager);

    /// @dev The function returns the address of the USDC token.
    function USDC() external view returns (IERC20);

    /// @dev The function returns the address of the TNGBL token.
    function TNGBL() external view returns (IERC20);

    /// @dev The function creates new category and returns an address of newly created contract.
    function newCategory(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isStoragePriceFixedAmount,
        bool storageRequired,
        address priceOracle,
        uint256 _lockPercentage,
        bool _paysRent
    ) external returns (ITangibleNFT);

    function newFractionTnft(ITangibleNFT _tnft, uint256 _tnftTokenId)
        external
        returns (ITangibleFractionsNFT);

    function initialTnftSplit(MintInitialFractionVoucher calldata voucher)
        external
        returns (uint256 tokenToSell);

    /// @dev The function returns an address of category NFT.
    function category(string calldata name)
        external
        view
        returns (ITangibleNFT);

    function fractions(ITangibleNFT tnft, uint256 tnftTokenId)
        external
        view
        returns (ITangibleFractionsNFT);

    /// @dev The function returns if address is operator in Factory
    function isFactoryOperator(address operator) external view returns (bool);

    /// @dev The function returns if address is vendor in Factory
    function isFactoryAdmin(address admin) external view returns (bool);

    /// @dev The function pays for storage, called only by marketplace
    function adjustStorageAndGetAmount(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 _years
    ) external returns (uint256);

    function payTnftStorageWithManager(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 _years
    ) external;

    function lockTNGBLOnTNFT(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 _years,
        uint256 lockedAmountTNGBL,
        bool onlyLock
    ) external;

    /// @dev return list of all vendors
    function getVendors() external view returns (address[] memory);

    /// @dev returns vendor for provided vendorId
    function idToVendor(uint128 vendorId) external view returns (address);

    /// @dev updates oracle for already deployed tnft
    function updateOracleForTnft(string calldata name, address priceOracle)
        external;

    /// @dev for migration puproses, we must avoid unnecessary deployments on new factories!
    function setCategory(
        string calldata name,
        ITangibleNFT nft,
        address priceOracle
    ) external;

    /// @dev fetches RevenueShareContract
    function revenueShare() external view returns (RevenueShare);

    /// @dev fetches RevenueShareContract
    function rentShare() external view returns (RentShare);

    /// @dev fetches PassiveIncomeNFTContract
    function passiveNft() external view returns (PassiveIncomeNFT);

    function onlyWhitelistedForUnminted() external view returns (bool);

    function shouldLockTngbl(uint256 tngblAmount) external view returns (bool);

    function whitelistForBuyUnminted(address buyer)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";

interface IVoucher {
    /// @dev Voucher for lazy-minting
    struct MintVoucher {
        ITangibleNFT token;
        uint256 mintCount;
        uint256 price;
        address vendor;
        address buyer;
        uint256 fingerprint;
        bool sendToVendor;
    }

    struct MintInitialFractionVoucher {
        address seller;
        address tnft;
        uint256 tnftTokenId;
        uint256 keepShare;
        uint256 sellShare;
        uint256 sellPrice;
    }

    /// @dev Voucher for lazy-burning
    struct BurnVoucher {
        ITangibleNFT token;
        uint256[] tokenIds;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";
import "./IPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ITangiblePriceManager interface gives prices for categories added in TangiblePriceManager.
interface ITangiblePriceManager {
    event CategoryPriceOracleAdded(
        address indexed category,
        address indexed priceOracle
    );

    /// @dev The function returns contract oracle for category.
    function getPriceOracleForCategory(ITangibleNFT category)
        external
        view
        returns (IPriceOracle);

    /// @dev The function returns current price from oracle for provided category.
    function setOracleForCategory(ITangibleNFT category, IPriceOracle oracle)
        external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title ITangibleNFT interface defines the interface of the TangibleNFT
interface ITangibleFractionsNFT is IERC721, IERC721Metadata, IERC721Enumerable {
    event ProducedInitialFTNFTs(uint256 keepToken, uint256 sellToken);
    event ProducedFTNFTs(uint256[] fractionsIds);

    function tnft() external view returns (ITangibleNFT nft);

    function tnftTokenId() external view returns (uint256 tokenId);

    function tnftFingerprint() external view returns (uint256 fingerprint);

    function fullShare() external view returns (uint256 fullShare);

    function fractionShares(uint256 tokenId) external returns (uint256 share);

    function initialSplit(
        address owner,
        address _tnft,
        uint256 _tnftTokenId,
        uint256 keepShare,
        uint256 sellShare
    ) external returns (uint256 tokenKeep, uint256 tokenSell);

    function fractionalize(uint256 fractionTokenId, uint256[] calldata shares)
        external
        returns (uint256[] memory splitedShares);

    function defractionalize(uint256[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title ITangibleNFT interface defines the interface of the TangibleNFT
interface ITangibleNFT is IERC721, IERC721Metadata, IERC721Enumerable {
    event StoragePricePerYearSet(uint256 oldPrice, uint256 newPrice);
    event StoragePercentagePricePerYearSet(
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event StorageFeeToPay(
        uint256 indexed tokenId,
        uint256 _years,
        uint256 amount
    );
    event ProducedTNFTs(uint256[] tokenId);

    function baseSymbolURI() external view returns (string memory);

    /// @dev Function allows a Factory to mint multiple tokenIds for provided vendorId to the given address(stock storage, usualy marketplace)
    /// with provided count.
    function produceMultipleTNFTtoStock(
        uint128 vendorId,
        uint256 count,
        uint256 fingerprint,
        address toStock
    ) external returns (uint256[] memory);

    /// @dev Function allows the Factory to burn all requested token IDs.
    function destroyTNFTs(uint256[] memory tokenId, address burningFrom)
        external;

    /// @dev The function returns whether storage fee is paid for the current time.
    function isStorageFeePaid(uint256 tokenId) external view returns (bool);

    /// @dev The function returns whether tnft is eligible for rent.
    function paysRent() external view returns (bool);

    function storageEndTime(uint256 tokenId)
        external
        view
        returns (uint256 storageEnd);

    function blackListedTokens(uint256 tokenId) external view returns (bool);

    /// @dev The function returns the price per year for storage.
    function storagePricePerYear() external view returns (uint256);

    /// @dev The function returns the percentage of item price that is used for calculating storage.
    function storagePercentagePricePerYear() external view returns (uint256);

    /// @dev The function returns whether storage for the TNFT is paid in fixed amount or in percentage from price
    function storagePriceFixed() external view returns (bool);

    /// @dev The function returns whether storage for the TNFT is required. For example houses don't have storage
    function storageRequired() external view returns (bool);

    function setRolesForFraction(address ftnft, uint256 tnftTokenId) external;

    /// @dev The function returns the token fingerprint - used in oracle
    function tokensFingerprint(uint256 tokenId) external view returns (uint256);

    function tnftToPassiveNft(uint256 tokenId) external view returns (uint256);

    /// @dev The function returns the token string id which is tied to fingerprint
    function fingerprintToProductId(uint256 fingerprint)
        external
        view
        returns (string memory);

    /// @dev The function returns lockable percentage of tngbl token e.g. 5000 - 5% 500 - 0.5% 50 - 0.05%.
    function lockPercent() external view returns (uint256);

    function lockTNGBL(
        uint256 tokenId,
        uint256 _years,
        uint256 lockedAmount,
        bool onlyLock
    ) external;

    /// @dev The function accepts takes tokenId, its price and years sets storage and returns amount to pay for.
    function adjustStorageAndGetAmount(
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITangibleNFT.sol";

/// @title ITangiblePriceManager interface gives prices for categories added in TangiblePriceManager.
interface IPriceOracle {
    /// @dev The function latest price and latest timestamp when price was updated from oracle.
    function latestTimeStamp(uint256 fingerprint)
        external
        view
        returns (uint256);

    /// @dev The function that returns price decimals from oracle.
    function decimals() external view returns (uint8);

    /// @dev The function that returns rescription for oracle.
    function description() external view returns (string memory desc);

    /// @dev The function that returns version of the oracle.
    function version() external view returns (uint256);

    /// @dev The function that reduces sell stock when token is bought.
    function decrementSellStock(uint256 fingerprint) external;

    /// @dev The function reduces buy stock when we buy token.
    function decrementBuyStock(uint256 fingerprint) external;

    /// @dev The function reduces buy stock when we buy token.
    function availableInStock(uint256 fingerprint)
        external
        returns (uint256 weSellAtStock, uint256 weBuyAtStock);

    /// @dev The function that returns item price.
    function usdcPrice(
        ITangibleNFT nft,
        uint256 fingerprint,
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 weSellAt,
            uint256 weSellAtStock,
            uint256 weBuyAt,
            uint256 weBuyAtStock,
            uint256 lockedAmount
        );
}