// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./interfaces/IMarketplace.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/ISellFeeDistributor.sol";
import "./interfaces/IOwnable.sol";

import "./abstract/Exchange.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Marketplace is Exchange, IMarketplace, IERC721Receiver {
    using SafeERC20 for IERC20;
    IFactory public factory;

    struct PricesOracle {
        uint256 _weSellAt;
        uint256 _weSellAtStock;
        uint256 _weBuyAt;
        uint256 _weBuyAtStock;
        uint256 _lockedAmount;
    }

    struct PricesOracleArrays {
        uint256[] weSellAt;
        uint256[] weSellAtStock;
        uint256[] weBuyAt;
        uint256[] weBuyAtStock;
        uint256[] lockedAmount;
    }

    mapping(address => mapping(uint256 => Lot)) marketplace;
    mapping(address => mapping(uint256 => LotFract)) marketplaceFract;

    address public override sellFeeAddress;

    // Default sell fee is 2.5%
    uint256 public sellFee = 250;

    constructor(address _uniswapV2Router) Exchange(_uniswapV2Router) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit SellFeeChanged(0, sellFee);
    }

    /// @inheritdoc IMarketplace
    function sellBatch(
        ITangibleNFT nft,
        uint256[] calldata tokenIds,
        uint256[] calldata price
    ) external override {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _sell(nft, tokenIds[i], price[i]);
        }
    }

    function sellFractionInitial(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 keepShare,
        uint256 sellShare,
        uint256 sellSharePrice,
        uint256 minPurchaseShare
    ) external {
        address tokenOwner = msg.sender;
        require(tnft.ownerOf(tokenId) == tokenOwner, "NOW");
        //take token from user

        tnft.safeTransferFrom(
            tokenOwner,
            address(this),
            tokenId,
            abi.encode(0, false)
        );
        //fractionalize
        //check if ftnft already deployed
        ITangibleFractionsNFT ftnft = factory.fractions(tnft, tokenId);
        if (address(ftnft) == address(0)) {
            ftnft = factory.newFractionTnft(tnft, tokenId);
        }
        //approve ftnft to take token
        tnft.approve(address(ftnft), tokenId);
        //set voucher
        MintInitialFractionVoucher memory voucher = MintInitialFractionVoucher({
            seller: tokenOwner,
            tnft: address(tnft),
            tnftTokenId: tokenId,
            keepShare: keepShare,
            sellShare: sellShare,
            sellPrice: sellSharePrice
        });
        (uint256 tokenToKeep, uint256 tokenToSell) = factory.initialTnftSplit(
            voucher
        );
        //adjust other data in lot
        marketplaceFract[address(ftnft)][tokenToSell]
            .minShare = minPurchaseShare;
        marketplaceFract[address(ftnft)][tokenToSell].price = sellSharePrice;
        marketplaceFract[address(ftnft)][tokenToSell].seller = tokenOwner;
        marketplaceFract[address(ftnft)][tokenToSell].initialShare = ftnft
            .fractionShares(tokenToSell);
        //initial token to keep is sent to marketplace,
        //so we need to delete it's record
        delete marketplaceFract[address(ftnft)][tokenToKeep];
        //to send usdc that marketplace received after fractionalizing
        IERC20 usdc = factory.USDC();
        usdc.safeTransfer(
            tokenOwner,
            usdc.balanceOf(address(this))
        );
        //delete record of tnft
        delete marketplace[address(tnft)][tokenId];
    }

    function buyFraction(
        ITangibleFractionsNFT ftnft,
        uint256 fractTokenId,
        uint256 share
    ) public {
        address buyer = msg.sender;
        LotFract memory existing = marketplaceFract[address(ftnft)][
            fractTokenId
        ];
        uint256 remainingShare = ftnft.fractionShares(fractTokenId);
        require(
            (existing.seller != address(0)) && (remainingShare >= share),
            "NEFT"
        );
        uint256 leftover = remainingShare - share;
        require(
            (share >= existing.minShare) &&
                (leftover == 0 || leftover >= existing.minShare),
            "IMP"
        );
        uint256 amount = (existing.price * share) / existing.initialShare;

        //take the fee
        IERC20 usdc = factory.USDC();
        uint256 toPaySeller = amount;
        if (sellFee > 0) {
            // if there is fee set, decrease amount by the fee and send fee
            uint256 fee = ((toPaySeller * sellFee) / 10000);
            toPaySeller = toPaySeller - fee;
            usdc.safeTransferFrom(buyer, sellFeeAddress, fee);
            ISellFeeDistributor(sellFeeAddress).distributeFee(fee);
        }
        usdc.safeTransferFrom(buyer, existing.seller, toPaySeller);

        if (share == remainingShare) {
            ftnft.safeTransferFrom(address(this), buyer, fractTokenId);

            emit SoldFract(
                existing.seller,
                address(ftnft),
                fractTokenId,
                amount
            );
            emit BoughtFract(
                buyer,
                address(ftnft),
                fractTokenId,
                existing.seller,
                amount
            );
            //set initial sale to be done if it is first time selling
            if(ftnft.tnft().paysRent() && (existing.initialShare == ftnft.fullShare())) {
                factory.initialSaleFinished(ftnft);
            }

            delete marketplaceFract[address(ftnft)][fractTokenId];
        } else {
            //we need to split and send to buyer
            uint256[] memory shares = new uint256[](2);
            shares[0] = leftover;
            shares[1] = share;
            uint256[] memory splitedTokens = ftnft.fractionalize(
                fractTokenId,
                shares
            );
            ftnft.safeTransferFrom(address(this), buyer, splitedTokens[1]);

            emit SoldFract(
                existing.seller,
                address(ftnft),
                splitedTokens[1],
                amount
            );
            emit BoughtFract(
                buyer,
                address(ftnft),
                splitedTokens[1],
                existing.seller,
                amount
            );

            delete marketplaceFract[address(ftnft)][splitedTokens[1]];
            //to send usdc that marketplace received after fractionalizing
            usdc.safeTransfer(
                existing.seller,
                usdc.balanceOf(address(this))
            );
        }
    }

    function sellFraction(
        ITangibleFractionsNFT ftnft,
        uint256 fractTokenId,
        uint256[] calldata shares,
        uint256 price,
        uint256 minPurchaseShare
    ) external {
        _sellFraction(ftnft, fractTokenId, shares, price, minPurchaseShare);
    }

    function _sellFraction(
        ITangibleFractionsNFT ftnft,
        uint256 fractTokenId,
        uint256[] calldata shares,
        uint256 price,
        uint256 minPurchaseShare
    ) internal {
        address caller = msg.sender;
        LotFract memory existing = marketplaceFract[address(ftnft)][
            fractTokenId
        ];
        require(
            (ftnft.ownerOf(fractTokenId) == caller) ||
                (existing.seller == caller),
            "NOW"
        );

        //this means that seller updates his sale
        if ((existing.tokenId == fractTokenId) && (existing.seller == caller)) {
            //update necessary info
            marketplaceFract[address(ftnft)][fractTokenId].price = price;
            marketplaceFract[address(ftnft)][fractTokenId]
                .minShare = minPurchaseShare;
        } else {
            //we have 2 cases - 1st selling whole share 2nd selling part of share
            uint256 length = shares.length;
            uint256 initialShare = ftnft.fractionShares(fractTokenId);
            require(length == 2, "WSH");
            //take the token
            ftnft.safeTransferFrom(
                caller,
                address(this),
                fractTokenId,
                abi.encode(price, true)
            );
            if (ftnft.fractionShares(fractTokenId) == shares[0]) {
                //1st case
                marketplaceFract[address(ftnft)][fractTokenId]
                    .minShare = minPurchaseShare;
                marketplaceFract[address(ftnft)][fractTokenId]
                    .initialShare = initialShare;
            } else {
                uint256[] memory splitedTokens = ftnft.fractionalize(
                    fractTokenId,
                    shares
                );
                //return the keepToken to the caller
                ftnft.safeTransferFrom(address(this), caller, fractTokenId);
                delete marketplaceFract[address(ftnft)][fractTokenId];
                //update second piece
                LotFract memory lotFract = marketplaceFract[address(ftnft)][
                    splitedTokens[1]
                ];
                lotFract.price = price;
                lotFract.minShare = minPurchaseShare;
                lotFract.seller = caller;
                marketplaceFract[address(ftnft)][splitedTokens[1]] = lotFract;
            }
        }
    }

    function _sell(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 price
    ) internal {
        //check who is the owner
        address ownerOfNft = IERC721(nft).ownerOf(tokenId);
        //if marketplace is owner and seller wants to update price
        if (
            (address(this) == ownerOfNft) &&
            (msg.sender == marketplace[address(nft)][tokenId].seller)
        ) {
            marketplace[address(nft)][tokenId].price = price;
        } else {
            //here we don't need to check, if not approved trx will fail
            nft.safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                abi.encode(price, false)
            );
        }
    }

    function setFactory(address _factory) external onlyAdmin {
        require(
            (_factory != address(0x0)) && (_factory != address(factory)),
            "WFA"
        );

        _setupRole(FACTORY_ROLE, _factory);
        _revokeRole(FACTORY_ROLE, address(factory));
        emit SetFactory(address(factory), _factory);
        factory = IFactory(_factory);
        factory.USDC().approve(router, type(uint256).max);
    }

    /// @inheritdoc IMarketplace
    function stopBatchSale(ITangibleNFT nft, uint256[] calldata tokenIds)
        external
        override
    {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _stopSale(nft, tokenIds[i]);
        }
    }

    function stopFractSale(ITangibleFractionsNFT ftnft, uint256 tokenId)
        public
    {
        address seller = msg.sender;
        // gas saving
        LotFract memory _lot = marketplaceFract[address(ftnft)][tokenId];
        require(_lot.seller == seller, "NOS");

        emit StopSellingFract(seller, address(ftnft), tokenId);
        delete marketplaceFract[address(ftnft)][tokenId];
        ftnft.safeTransferFrom(address(this), _lot.seller, _lot.tokenId);
    }

    function _stopSale(ITangibleNFT nft, uint256 tokenId) internal {
        address seller = msg.sender;
        // gas saving
        Lot memory _lot = marketplace[address(nft)][tokenId];
        require(_lot.seller == seller, "NOS");

        emit StopSelling(seller, address(nft), tokenId);
        delete marketplace[address(nft)][tokenId];
        IERC721(nft).safeTransferFrom(address(this), _lot.seller, _lot.tokenId);
    }

    /// @inheritdoc IMarketplace
    function buy(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years,
        bool onlyLock
    ) external override {
        Lot memory _lot = marketplace[address(nft)][tokenId];
        //NOTE add code for getting if this is initial sale
        //MUST BE DONE BEFORE DEPLOYMENT!!!!!!
        uint256 tokenPrice = _lot.price;
        uint256 lockedAmount;
        if (tokenPrice == 0) {
            (tokenPrice, , , , lockedAmount) = factory
                .priceManager()
                .getPriceOracleForCategory(nft)
                .usdcPrice(nft, 0, tokenId);
        }
        require(tokenPrice != 0, "P0");

        //pay for storage
        if (
            (!nft.isStorageFeePaid(tokenId) || _years > 0) &&
            nft.storageRequired()
        ) {
            require(_years > 0, "YZ");
            _payStorage(nft, tokenId, _years);
        }
        //buy the token
        _buy(nft, tokenId, true);
    }

    function payStorage(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years
    ) external override {
        require(nft.storageRequired(), "STNR");
        _payStorage(nft, tokenId, _years);
    }

    function _payStorage(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 _years
    ) internal {
        require(_years > 0, "YZ");

        uint256 amount = factory.adjustStorageAndGetAmount(
            nft,
            tokenId,
            _years
        );

        factory.USDC().safeTransferFrom(
            msg.sender,
            factory.feeStorageAddress(),
            amount
        );
        emit StorageFeePaid(msg.sender, address(nft), tokenId, _years, amount);
    }

    /// @inheritdoc IMarketplace
    function buyUnminted(
        ITangibleNFT nft,
        uint256 _fingerprint,
        uint256 _years,
        bool onlyLock
    ) external override {
        if (factory.onlyWhitelistedForUnminted()) {
            require(factory.whitelistForBuyUnminted(msg.sender), "NW");
        }
        //buy unminted is always initial sale!!
        // need to also fetch stock here!! and remove remainingMintsForVendor
        (uint256 tokenPrice, uint256 stock, , , uint256 lockedAmount) = factory
            .priceManager()
            .getPriceOracleForCategory(nft)
            .usdcPrice(nft, _fingerprint, 0);

        require((tokenPrice > 0) && (stock > 0), "!0S");

        MintVoucher memory voucher = MintVoucher({
            token: nft,
            mintCount: 1,
            price: 0,
            vendor: IOwnable(address(factory)).contractOwner(),
            buyer: msg.sender,
            fingerprint: _fingerprint,
            sendToVendor: false
        });
        uint256[] memory tokenIds = factory.mint(voucher);
        //pay for storage
        if (nft.storageRequired()) {
            _payStorage(nft, tokenIds[0], _years);
        }
        uint256 shouldLockTngbl = quoteOut(
            address(factory.USDC()),
            address(factory.TNGBL()),
            lockedAmount
        );
        if (factory.shouldLockTngbl(shouldLockTngbl) && !nft.paysRent()) {
            if (nft.tnftToPassiveNft(tokenIds[0]) == 0) {
                //convert locked amount to tngbl and send to nft contract
                //locktngbl can be called only from factory
                _lockTngbl(nft, tokenIds[0], lockedAmount, _years, onlyLock);
            }
        } else {
            factory.USDC().safeTransferFrom(
                msg.sender,
                factory.feeStorageAddress(), //NOTE: or factory owner?
                lockedAmount
            );
        }
        //pricing should be handled from oracle
        _buy(voucher.token, tokenIds[0], false);
    }

    function _lockTngbl(
        ITangibleNFT nft,
        uint256 tokenId,
        uint256 lockedAmount,
        uint256 _years,
        bool onlyLock
    ) internal {
        factory.USDC().safeTransferFrom(
            msg.sender,
            address(this),
            lockedAmount
        );
        uint256 lockedTNGBL = exchange(
            address(factory.USDC()),
            address(factory.TNGBL()),
            lockedAmount,
            quoteOut(
                address(factory.USDC()),
                address(factory.TNGBL()),
                lockedAmount
            )
        );
        factory.TNGBL().safeTransfer(address(nft), lockedTNGBL);
        factory.lockTNGBLOnTNFT(nft, tokenId, _years, lockedTNGBL, onlyLock);
    }

    function setRouter(address _router) external override onlyAdmin {
        require(_router != address(0), "ZUSR");
        require(_router != router, "SUSR");

        emit NewRouterSet(router, _router);
        router = _router;
        factory.USDC().approve(_router, type(uint256).max);
    }

    function lotBatch(address nft, uint256[] calldata tokenIds)
        external
        view
        returns (Lot[] memory)
    {
        uint256 length = tokenIds.length;
        Lot[] memory result = new Lot[](length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = marketplace[nft][tokenIds[i]];
        }

        return result;
    }

    function lotFractionBatch(address ftnft, uint256[] calldata tokenIds)
        external
        view
        returns (LotFract[] memory)
    {
        uint256 length = tokenIds.length;
        LotFract[] memory result = new LotFract[](length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = marketplaceFract[ftnft][tokenIds[i]];
        }

        return result;
    }

    function itemPriceBatchFingerprints(
        ITangibleNFT nft,
        uint256[] calldata fingerprints
    )
        external
        view
        override
        returns (
            uint256[] memory weSellAt,
            uint256[] memory weSellAtStock,
            uint256[] memory weBuyAt,
            uint256[] memory weBuyAtStock,
            uint256[] memory lockedAmount
        )
    {
        (
            weSellAt,
            weSellAtStock,
            weBuyAt,
            weBuyAtStock,
            lockedAmount
        ) = _itemBatchPrices(nft, fingerprints, true);
    }

    function itemPriceBatchTokenIds(
        ITangibleNFT nft,
        uint256[] calldata tokenIds
    )
        external
        view
        override
        returns (
            uint256[] memory weSellAt,
            uint256[] memory weSellAtStock,
            uint256[] memory weBuyAt,
            uint256[] memory weBuyAtStock,
            uint256[] memory lockedAmount
        )
    {
        (
            weSellAt,
            weSellAtStock,
            weBuyAt,
            weBuyAtStock,
            lockedAmount
        ) = _itemBatchPrices(nft, tokenIds, false);
    }

    function _itemBatchPrices(
        ITangibleNFT nft,
        uint256[] calldata data,
        bool fromFingerprints
    )
        internal
        view
        returns (
            uint256[] memory weSellAt,
            uint256[] memory weSellAtStock,
            uint256[] memory weBuyAt,
            uint256[] memory weBuyAtStock,
            uint256[] memory lockedAmount
        )
    {
        uint256 length = data.length;
        PricesOracleArrays memory pricesOracleArrays;
        pricesOracleArrays.weSellAt = new uint256[](length);
        pricesOracleArrays.weSellAtStock = new uint256[](length);
        pricesOracleArrays.weBuyAt = new uint256[](length);
        pricesOracleArrays.weBuyAtStock = new uint256[](length);
        pricesOracleArrays.lockedAmount = new uint256[](length);
        PricesOracle memory pricesOracle;

        for (uint256 i = 0; i < length; i++) {
            (
                pricesOracle._weSellAt,
                pricesOracle._weSellAtStock,
                pricesOracle._weBuyAt,
                pricesOracle._weBuyAtStock,
                pricesOracle._lockedAmount
            ) = fromFingerprints
                ? factory
                    .priceManager()
                    .getPriceOracleForCategory(nft)
                    .usdcPrice(nft, data[i], 0)
                : factory
                    .priceManager()
                    .getPriceOracleForCategory(nft)
                    .usdcPrice(nft, 0, data[i]);
            pricesOracleArrays.weSellAt[i] = pricesOracle._weSellAt;
            pricesOracleArrays.weSellAtStock[i] = pricesOracle._weSellAtStock;
            pricesOracleArrays.weBuyAt[i] = pricesOracle._weBuyAt;
            pricesOracleArrays.weBuyAtStock[i] = pricesOracle._weBuyAtStock;
            pricesOracleArrays.lockedAmount[i] = pricesOracle._lockedAmount;
        }
        return (
            pricesOracleArrays.weSellAt,
            pricesOracleArrays.weSellAtStock,
            pricesOracleArrays.weBuyAt,
            pricesOracleArrays.weBuyAtStock,
            pricesOracleArrays.lockedAmount
        );
    }

    function _buy(
        ITangibleNFT nft,
        uint256 tokenId,
        bool chargeFee
    ) internal {
        // gas saving
        address buyer = msg.sender;

        Lot memory _lot = marketplace[address(nft)][tokenId];
        require(_lot.seller != address(0), "NLO");

        // if lot.price == 0 it means vendor minted it, we must take price from oracle
        // if lot.price != 0 means some seller posted it and didn't want to use oracle
        uint256 cost = _lot.price;
        if (cost == 0) {
            (cost, , , , ) = factory
                .priceManager()
                .getPriceOracleForCategory(nft)
                .usdcPrice(nft, 0, tokenId);
        }

        require(cost != 0, "P0");

        //take the fee
        uint256 toPayVendor = cost;
        if ((sellFee > 0) && chargeFee) {
            // if there is fee set, decrease amount by the fee and send fee
            uint256 fee = ((toPayVendor * sellFee) / 10000);
            toPayVendor = toPayVendor - fee;
            factory.USDC().safeTransferFrom(buyer, sellFeeAddress, fee);
            ISellFeeDistributor(sellFeeAddress).distributeFee(fee);
        }

        factory.USDC().safeTransferFrom(buyer, _lot.seller, toPayVendor);

        emit Sold(_lot.seller, address(nft), tokenId, cost);
        emit Bought(buyer, address(nft), tokenId, _lot.seller, cost);
        delete marketplace[address(nft)][tokenId];

        nft.safeTransferFrom(address(this), buyer, tokenId);
    }

    /// @notice Sets the feeStorageAddress
    /// @dev Will emit SellFeeAddressSet on change.
    /// @param _sellFeeAddress A new address for fee storage.
    function setSellFeeAddress(address _sellFeeAddress) external onlyAdmin {
        require(_sellFeeAddress != address(0), "SFAZ");
        if (sellFeeAddress != _sellFeeAddress) {
            emit SellFeeAddressSet(sellFeeAddress, _sellFeeAddress);
            sellFeeAddress = _sellFeeAddress;
        }
    }

    function setSellFee(uint256 _sellFee) external onlyAdmin {
        require(sellFee != _sellFee, "SSF");
        emit SellFeeChanged(sellFee, _sellFee);
        sellFee = _sellFee;
    }

    function onERC721Received(
        address operator,
        address seller,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return _onERC721Received(operator, seller, tokenId, data);
    }

    function _onERC721Received(
        address, /*operator*/
        address seller,
        uint256 tokenId,
        bytes calldata data
    ) private returns (bytes4) {
        address nft = msg.sender;
        (uint256 price, bool fraction) = abi.decode(data, (uint256, bool));

        if (!fraction) {
            marketplace[nft][tokenId] = Lot(
                ITangibleNFT(nft),
                tokenId,
                seller,
                price,
                true
            );
            emit Selling(seller, nft, tokenId, price);
        } else {
            marketplaceFract[nft][tokenId] = LotFract(
                ITangibleFractionsNFT(nft),
                tokenId,
                seller,
                price,
                0, //set later minPurchaseShare
                ITangibleFractionsNFT(nft).fractionShares(tokenId) //set later initialShare
            );
            emit SellingFract(seller, nft, tokenId, price);
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFactory.sol";

/// @title IMarketplace interface defines the interface of the Marketplace
interface IMarketplace is IVoucher {
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
    event SellFeeChanged(uint256 indexed oldFee, uint256 indexed newFee);
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

    function itemPriceBatchFingerprints(
        ITangibleNFT nft,
        uint256[] calldata fingerprints
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function itemPriceBatchTokenIds(
        ITangibleNFT nft,
        uint256[] calldata tokenIds
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface ISellFeeDistributor {
    event FeeDistributed(address indexed to, uint256 usdcAmount);
    event TangibleBurned(uint256 burnedTngbl);

    function distributeFee(uint256 feeAmount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IOwnable {
    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    function contractOwner() external view returns (address);

    function renounceOwnership() external;

    function pushOwnership(address newOwner_) external;

    function pullOwnership() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWETH9.sol";
import "./AdminAccess.sol";

abstract contract Exchange is AdminAccess {
    using SafeERC20 for IERC20;

    address public router;

    event NewRouterSet(address indexed oldRouter, address indexed newRouter);

    constructor(address _routerV2) {
        router = _routerV2;
    }

    function exchange(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = IUniswapV2Router01(router)
            .swapExactTokensForTokens(
                amountIn,
                minAmountOut,
                path,
                address(this),
                block.timestamp + 15 // on sushi?
            );
        return amounts[1]; //returns output token amount
    }

    function setRouter(address _router) external virtual onlyAdmin {
        require(_router != address(0), "ZUSR");
        require(_router != router, "SUSR");

        emit NewRouterSet(router, _router);
        router = _router;
    }

    function quoteOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = IUniswapV2Router01(router).getAmountsOut(
            amountIn,
            path
        );
        return amounts[1];
    }
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AdminAccess is AccessControl {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY");
    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not admin");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Restricted to members of the factory role.
    modifier onlyFactory() {
        require(isFactory(msg.sender), "Not in Factory role!");
        _;
    }

    /// @dev Return `true` if the account belongs to the factory role.
    function isFactory(address account) internal view returns (bool) {
        return hasRole(FACTORY_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the factory role or admin role.
    function isAdminOrFactory(address account) internal view returns (bool) {
        return isFactory(account) || isAdmin(account);
    }

    modifier onlyFactoryOrAdmin() {
        require(isAdminOrFactory(msg.sender), "NFAR");
        _;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}