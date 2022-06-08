// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./interfaces/IInitialReSeller.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ITangibleMarketplace.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IFactoryExt is IFactory {
    function fractionToTnftAndId(ITangibleFractionsNFT fraction)
        external
        view
        returns (TnftWithId memory);

    function takeFtnftForReemburse(
        ITangibleFractionsNFT ftnft,
        uint256 fractionId
    ) external;

    function paymentTokens(IERC20 token) external returns (bool);
}

interface IMarketplaceExt is ITangibleMarketplace {
    function stopFractSale(ITangibleFractionsNFT ftnft, uint256 tokenId)
        external;

    function sellFraction(
        ITangibleFractionsNFT ftnft,
        uint256 fractTokenId,
        uint256[] calldata shares,
        uint256 price,
        uint256 minPurchaseShare
    ) external;
}

contract InitialReSeller is IInitialReSeller, IERC721Receiver {
    using SafeERC20 for IERC20;

    IFactoryExt factory;
    //handle multiple sales
    mapping(ITangibleFractionsNFT => FractionSaleData) public saleData;
    //data used for reembursing if sale fails
    // ftnft and fractionId identify buyer
    mapping(ITangibleFractionsNFT => mapping(uint256 => FractionBuyer))
        public saleBuyersData;

    address[] public currentlySellingRe;
    address[] public soldRe;

    modifier onlyFactoryAdmin() {
        require(factory.isFactoryAdmin(msg.sender), "NFA");
        _;
    }

    modifier onlyMarketplace() {
        require(address(factory.marketplace()) == msg.sender, "NMAR");
        _;
    }

    constructor(address _factory) {
        require(_factory != address(0), "ZA");
        factory = IFactoryExt(_factory);
    }

    function getSoldRealEstate() external view returns (address[] memory) {
        return soldRe;
    }

    function getCurrentlySellingRealEstate()
        external
        view
        returns (address[] memory)
    {
        return currentlySellingRe;
    }

    function withdrawFtnft(
        ITangibleFractionsNFT ftnft,
        uint256[] calldata tokenIds
    ) external onlyFactoryAdmin {
        //defract tokens and send them as 1
        ftnft.defractionalize(tokenIds);
        ftnft.safeTransferFrom(address(this), msg.sender, tokenIds[0]);
    }

    function updateBuyer(
        ITangibleFractionsNFT ftnft,
        address buyer,
        uint256 fractionId,
        uint256 amountPaid
    ) external override onlyMarketplace {
        //set fraction sale data to update
        FractionBuyer memory fb = FractionBuyer(
            buyer,
            fractionId,
            ftnft.fractionShares(fractionId),
            amountPaid
        );
        //store in db
        saleBuyersData[ftnft][fractionId] = fb;
        //update total
        saleData[ftnft].paidSoFar += amountPaid;
        emit StoreBuyer(ftnft, fractionId, buyer, amountPaid);
    }

    function completeSale(ITangibleFractionsNFT ftnft)
        external
        override
        onlyMarketplace
    {
        uint256 balance = saleData[ftnft].askingPrice ==
            saleData[ftnft].paidSoFar
            ? saleData[ftnft].askingPrice
            : saleData[ftnft].paidSoFar;

        saleData[ftnft].paymentToken.safeTransfer(
            factory.feeStorageAddress(),
            balance
        );
        saleData[ftnft].sold = true;
        _removeCurrentlySelling(saleData[ftnft].indexInCurrentlySelling);
        //store sold RE
        soldRe.push(address(ftnft));
        saleData[ftnft].indexInCurrentlySelling = type(uint256).max;
        saleData[ftnft].indexInSold = soldRe.length - 1;
        //we don't remove saleData because it is permanent record of sale

        emit SaleAmountTaken(ftnft, saleData[ftnft].paymentToken, balance);
    }

    function extendSale(ITangibleFractionsNFT ftnft, uint256 endDate)
        external
        onlyFactoryAdmin
    {
        require(saleData[ftnft].endTimestamp < endDate, "unable to shrink");
        //set new end date
        saleData[ftnft].endTimestamp = endDate;
        emit EndDateExtended(ftnft, endDate);
    }

    function putOnSale(
        ITangibleNFT tnft,
        IERC20 paymentToken,
        uint256 tokenId,
        uint256 askingPrice,
        uint256 minPurchaseShare,
        uint256 endSaleDate
    ) external onlyFactoryAdmin {
        require(tnft.paysRent(), "Only RE");
        require(factory.paymentTokens(paymentToken), "only approved tokens");
        ITangibleFractionsNFT ftnft = factory.fractions(tnft, tokenId);
        if (address(ftnft) != address(0)) {
            require(
                !factory.fractionToTnftAndId(ftnft).initialSaleDone,
                "sale already done"
            );
        }
        //check if payment token is approved
        ITangibleMarketplace marketplace = ITangibleMarketplace(
            factory.marketplace()
        );
        //take tnft
        tnft.safeTransferFrom(msg.sender, address(this), tokenId);
        //approve marketplace
        tnft.approve(address(marketplace), tokenId);
        //sell the fractions from whole nft
        uint256 tokenToSell;
        (ftnft, tokenToSell) = marketplace.sellFractionInitial(
            tnft,
            tokenId,
            0,
            10000000,
            askingPrice,
            minPurchaseShare
        );
        uint256 endTimestamp = endSaleDate == 0
            ? (block.timestamp + (2 * 7 days))
            : endSaleDate;

        //update currently selling array and store it in fsd
        currentlySellingRe.push(address(ftnft));
        FractionSaleData memory fsd = FractionSaleData(
            paymentToken,
            tokenToSell,
            endTimestamp,
            askingPrice,
            0,
            (currentlySellingRe.length - 1),
            type(uint256).max, //index in already sold - default to be max means doesn't exist
            false
        );
        saleData[ftnft] = fsd;

        emit SaleStarted(ftnft, endTimestamp, tokenToSell, askingPrice);
    }

    function modifySale(
        ITangibleFractionsNFT ftnft,
        uint256 fractionId,
        uint256 askingPrice,
        uint256 minPurchaseShare
    ) external onlyFactoryAdmin {
        IMarketplaceExt marketplace = IMarketplaceExt(factory.marketplace());
        marketplace.sellFraction(
            ftnft,
            fractionId,
            new uint256[](0),
            askingPrice,
            minPurchaseShare
        );
    }

    function reemburse(ITangibleFractionsNFT ftnft, uint256[] calldata tokenIds)
        external
        onlyFactoryAdmin
    {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; i++) {
            //take ftnft from buyer
            address owner = saleBuyersData[ftnft][tokenIds[i]].owner;
            require(owner != address(0), "taken");

            factory.takeFtnftForReemburse(ftnft, tokenIds[i]);
            //send back the money
            saleData[ftnft].paymentToken.safeTransfer(
                owner,
                saleBuyersData[ftnft][tokenIds[i]].pricePaid
            );
            //delete records
            delete saleBuyersData[ftnft][tokenIds[i]];
        }
    }

    //call this when everyone is reembuursed
    function stopSale(ITangibleFractionsNFT ftnft) external onlyFactoryAdmin {
        IMarketplaceExt marketplace = IMarketplaceExt(factory.marketplace());
        marketplace.stopFractSale(ftnft, saleData[ftnft].sellingToken);

        //update indexes in saleData and remove from currentlySelling
        _removeCurrentlySelling(saleData[ftnft].indexInCurrentlySelling);
        delete saleData[ftnft];
    }

    //this function is not preserving order, and we don't care about it
    function _removeCurrentlySelling(uint256 index) internal {
        require(index < currentlySellingRe.length);
        //take last ftnft
        ITangibleFractionsNFT ftnft = ITangibleFractionsNFT(
            currentlySellingRe[currentlySellingRe.length - 1]
        );
        //replace it with the one we are removing
        currentlySellingRe[index] = address(ftnft);
        //set it's new index in saleData
        saleData[ftnft].indexInCurrentlySelling = index;
        currentlySellingRe.pop();
    }

    function onERC721Received(
        address, /*operator*/
        address, /*seller*/
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleFractionsNFT.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IInitialReSeller {
    struct FractionSaleData {
        IERC20 paymentToken;
        uint256 sellingToken;
        uint256 endTimestamp;
        uint256 askingPrice;
        uint256 paidSoFar;
        uint256 indexInCurrentlySelling;
        uint256 indexInSold;
        bool sold;
    }

    struct FractionBuyer {
        address owner;
        uint256 fractionId;
        uint256 fractionShare;
        uint256 pricePaid;
    }

    event StoreBuyer(
        ITangibleFractionsNFT indexed ftnft,
        uint256 indexed fractionId,
        address buyer,
        uint256 indexed amount
    );
    event EndDateExtended(
        ITangibleFractionsNFT indexed ftnft,
        uint256 indexed endDate
    );
    event SaleAmountTaken(
        ITangibleFractionsNFT indexed ftnft,
        IERC20 indexed paymentToken,
        uint256 amount
    );
    event SaleStarted(
        ITangibleFractionsNFT indexed ftnft,
        uint256 indexed endDate,
        uint256 sellingTokenId,
        uint256 askingPrice
    );

    // function saleData(address ftnft) external view returns(FractionSaleData calldata);
    // function saleBuyersData(address ftnft, uint256 fractionId) external view returns(FractionBuyer calldata);
    function updateBuyer(
        ITangibleFractionsNFT ftnft,
        address buyer,
        uint256 fractionId,
        uint256 amountPaid
    ) external;

    function completeSale(ITangibleFractionsNFT ftnft) external;
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

    struct TnftWithId {
        ITangibleNFT tnft;
        uint256 tnftTokenId;
        bool initialSaleDone;
    }

    event WhitelistedBuyer(address indexed buyer, bool indexed approved);

    event MintedTokens(address indexed nft, uint256[] tokenIds);
    event PaymentToken(address indexed token, bool approved);
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

    /// @dev The function that redeems tnft/sets status of tnft
    function redeemToggle(RedeemVoucher calldata voucher) external;

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

    //complete initial sale of rent fractions
    function initialSaleFinished(ITangibleFractionsNFT ftnft) external;

    //contract for initial sale of fractions
    function initReSeller() external view returns (address);

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
        returns (uint256 tokenKeep, uint256 tokenSell);

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

    function onlyWhitelistedForUnmintedCategory(ITangibleNFT nft)
        external
        view
        returns (bool);

    function shouldLockTngbl(uint256 tngblAmount) external view returns (bool);

    function whitelistForBuyUnminted(address buyer)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFactory.sol";

/// @title ITangibleMarketplace interface defines the interface of the Marketplace
interface ITangibleMarketplace is IVoucher {
    struct Lot {
        ITangibleNFT nft;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool minted;
    }

    struct LotFract {
        ITangibleFractionsNFT nft;
        uint256 tokenId;
        address seller;
        uint256 price; //total wanted price for share
        uint256 minShare;
        uint256 initialShare;
    }

    event Selling(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price
    );
    event StopSelling(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId
    );
    event Sold(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price
    );
    event Bought(
        address indexed buyer,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event SellingFract(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price
    );
    event StopSellingFract(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId
    );
    event SoldFract(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price
    );
    event BoughtFract(
        address indexed buyer,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event SellFeeAddressSet(address indexed oldFee, address indexed newFee);
    event SellFeeChanged(
        ITangibleNFT indexed nft,
        uint256 oldFee,
        uint256 newFee
    );
    event SetFactory(address indexed oldFactory, address indexed newFactory);
    event StorageFeePaid(
        address indexed payer,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 _years,
        uint256 amount
    );

    /// @dev The function allows anyone to put on sale the TangibleNFTs they own
    /// if price is 0 - use oracle when selling
    function sellBatch(
        ITangibleNFT nft,
        uint256[] calldata tokenIds,
        uint256[] calldata price
    ) external;

    /// @dev The function allows the owner of the minted TangibleNFT items to remove them from the Marketplace
    function stopBatchSale(ITangibleNFT nft, uint256[] calldata tokenIds)
        external;

    /// @dev The function allows the user to buy any TangibleNFT from the Marketplace for USDC
    function buy(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years,
        bool onlyLock
    ) external;

    /// @dev The function allows the user to buy any TangibleNFT from the Marketplace for USDC this is for unminted items
    function buyUnminted(
        ITangibleNFT nft,
        uint256 _fingerprint,
        uint256 _years,
        bool _onlyLock
    ) external;

    /// @dev The function returns the address of the fee storage.
    function sellFeeAddress() external view returns (address);

    /// @dev The function which buys additional storage to token.
    function payStorage(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years
    ) external;

    function sellFractionInitial(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 keepShare,
        uint256 sellShare,
        uint256 sellSharePrice,
        uint256 minPurchaseShare
    ) external returns (ITangibleFractionsNFT ftnft, uint256 tokenToSell);
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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

    function claimFor(address contractAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
        uint256 count,
        uint256 fingerprint,
        address toStock
    ) external returns (uint256[] memory);

    /// @dev Function that allows the Factory change redeem/statuses.
    function setTNFTStatuses(
        uint256[] calldata tokenIds,
        bool[] calldata inOurCustody
    ) external;

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

    function claim(uint256 tokenId, uint256 amount) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
    struct RedeemVoucher {
        ITangibleNFT token;
        uint256[] tokenIds;
        bool[] inOurCustody;
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