// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IGravityGrade.sol";
import "../interfaces/ISwapManager.sol";
import "../interfaces/IOracleManager.sol";
import "./IGravityGrade_Transak.sol";

/* error codes */
error GravityGrade__NotGovernance();
error GravityGrade__NotTrusted(address _address);
error GravityGrade__ZeroAddress();
error GravityGrade__ZeroSaleCap();
error GravityGrade__ZeroUserSaleCap();
error GravityGrade__TokenNotSet(uint256 _tokenId);
error GravityGrade__NonExistentSale(uint256 _tokenId);
error GravityGrade__SaleInactive();
error GravityGrade__ValueTooLarge(uint256 _given, uint256 _max);
error GravityGrade__CurrencyNotWhitelisted(address _address);
error GravityGrade__PurchaseExceedsTotalMax(uint256 _current, uint256 _max);
error GravityGrade__PurchaseExceedsPlayerMax(uint256 _current, uint256 _max);
error GravityGrade__InvalidSaleParameters();
error GravityGrade__WithdrawalFailed();
error GravityGrade__TransferFailed();
error GravityGrade__InsufficientEthValue(uint256 _value, uint256 _required);
error GravityGrade__SenderDoesNotOwnToken(address _token, uint256 _id);
error GravityGrade__TokenNotEligibleForRebate(address _token);
error GravityGrade__RefundFailed();
error GravityGrade__RebateTooLarge(
    uint256 _saleId,
    uint256 _price,
    uint256 _bulkDsc,
    uint256 _ownershipDsc
);

/**@title Gravity Grade
 * @author @Haltoshi
 * @notice This contract is for managing cargo and pack drops
 */
contract GravityGrade is
    IGravityGrade,
    IGravityGrade_Transak,
    OwnableUpgradeable,
    ERC1155Upgradeable
{
    /* Type Declarations */
    struct Sale {
        uint256 saleId;
        uint256 tokenId;
        uint256 salePrice;
        uint256 totalSupply;
        uint256 userCap;
        address defaultCurrency;
        bool profitState;
    }

    struct Beneficiaries {
        uint256[] feeBps;
        address[] beneficiary;
    }

    /* State Variables */
    string public name;
    string public symbol;
    address private s_moderator;
    uint256 private s_saleId;
    Beneficiaries private s_beneficiaries;
    mapping(uint256 => uint256) s_sold;
    mapping(uint256 => string) private s_uris;
    mapping(uint256 => Sale) private s_sales;
    mapping(uint256 => bool) private s_saleStatus;
    mapping(address => bool) private s_trustedAddresses;
    mapping(uint256 => uint256[]) private s_bulkDiscountBreakpoints;
    mapping(uint256 => uint256[]) private s_bulkDiscountBasisPoints;
    mapping(uint256 => mapping(address => bool)) s_whitelistedCurrencies;
    mapping(uint256 => mapping(address => uint256)) s_perPlayerSold;
    mapping(uint256 => OwnershipRebate[]) private s_ownershipDiscounts;
    uint256 public constant MAXIMUM_BASIS_POINTS = 10_000;
    address public constant ADDRESS_ZERO = address(0);

    IOracleManager s_oracle;
    ISwapManager s_swapManager;

    /* Modifiers */
    modifier onlyGov() {
        if (msg.sender != owner() && msg.sender != s_moderator) {
            revert GravityGrade__NotGovernance();
        }
        _;
    }

    modifier onlyTrusted() {
        if (!s_trustedAddresses[msg.sender]) revert GravityGrade__NotTrusted(msg.sender);
        _;
    }

    /* Functions */
    /**
     * @notice Initializer for the GravityGrade contract
     * @param _name Name for this token
     * @param _symbol Symbol for this token
     */
    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        name = _name;
        symbol = _symbol;
        s_moderator = msg.sender;
    }

    /**
     * @notice Assigns the moderator
     * @param _moderatorAddress The moderator-to-be
     */
    function setModerator(address _moderatorAddress) external onlyOwner {
        if (_moderatorAddress == ADDRESS_ZERO) revert GravityGrade__ZeroAddress();
        s_moderator = _moderatorAddress;
    }

    /// @inheritdoc IGravityGrade
    function createNewSale(
        uint256 _tokenId,
        uint256 _salePrice,
        uint256 _totalSupplyAmountToSell,
        uint256 _userCap,
        address _defaultCurrency,
        bool _profitState
    ) external onlyGov returns (uint256 saleId) {
        if (_totalSupplyAmountToSell == 0) revert GravityGrade__ZeroSaleCap();
        if (_userCap == 0) revert GravityGrade__ZeroUserSaleCap();
        if (bytes(s_uris[_tokenId]).length == 0) revert GravityGrade__TokenNotSet(_tokenId);

        uint256 newSaleId = s_saleId++;
        s_sales[newSaleId] = Sale(
            newSaleId,
            _tokenId,
            _salePrice,
            _totalSupplyAmountToSell,
            _userCap,
            _defaultCurrency,
            _profitState
        );
        s_whitelistedCurrencies[newSaleId][_defaultCurrency] = true;
        emit SaleInfoUpdated(
            newSaleId,
            _tokenId,
            _salePrice,
            _totalSupplyAmountToSell,
            _userCap,
            _defaultCurrency
        );
        return newSaleId;
    }

    /// @inheritdoc IGravityGrade
    function modifySale(
        uint256 _saleId,
        uint256 _salePrice,
        uint256 _totalSupplyAmountToSell,
        uint256 _userCap,
        address _defaultCurrency,
        bool _profitState
    ) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert GravityGrade__NonExistentSale(_saleId);
        if (_totalSupplyAmountToSell == 0) revert GravityGrade__ZeroSaleCap();
        if (_userCap == 0) revert GravityGrade__ZeroUserSaleCap();
        if (bytes(s_uris[s_sales[_saleId].tokenId]).length == 0)
            revert GravityGrade__TokenNotSet(s_sales[_saleId].tokenId);

        s_sales[_saleId].salePrice = _salePrice;
        s_sales[_saleId].totalSupply = _totalSupplyAmountToSell;
        s_sales[_saleId].userCap = _userCap;
        s_sales[_saleId].defaultCurrency = _defaultCurrency;
        s_sales[_saleId].profitState = _profitState;
        emit SaleInfoUpdated(
            _saleId,
            s_sales[_saleId].tokenId,
            _salePrice,
            _totalSupplyAmountToSell,
            _userCap,
            _defaultCurrency
        );
    }

    /// @inheritdoc IGravityGrade
    function setTokenUri(uint256 _tokenId, string memory _uri) external onlyGov {
        s_uris[_tokenId] = _uri;
    }

    /** @notice retreive TokenURI
     *  @param _tokenId TokenId
     */
    function getTokenUri(uint256 _tokenId) public view returns (string memory) {
        return s_uris[_tokenId];
    }

    /// @inheritdoc IGravityGrade
    function addBulkDiscount(
        uint256 _saleId,
        uint256 _breakpoint,
        uint256 _basisPoints
    ) external onlyGov {
        // todo: Delete entries when we set _basisPoints = 0
        if (s_sales[_saleId].tokenId == 0) revert GravityGrade__NonExistentSale(_saleId);
        if (s_sales[_saleId].userCap < _breakpoint)
            revert GravityGrade__ValueTooLarge(_breakpoint, s_sales[_saleId].userCap);
        uint256[] storage s_discount = s_bulkDiscountBasisPoints[_saleId];
        uint256[] storage s_break = s_bulkDiscountBreakpoints[_saleId];
        bool overwritten;
        for (uint256 i; i < s_discount.length; i++) {
            if (s_break[i] == _breakpoint) {
                s_discount[i] = _basisPoints;
                overwritten = true;
            }
        }
        if (!overwritten) {
            s_discount.push(_basisPoints);
            s_break.push(_breakpoint);
        }
        _validateRebates(_saleId);
    }

    /// @inheritdoc IGravityGrade
    function addOwnershipDiscount(uint256 _saleId, OwnershipRebate calldata _info)
        external
        onlyGov
    {
        if (_info.tokenAddress == ADDRESS_ZERO) revert GravityGrade__ZeroAddress();
        if (_info.basisPoints > MAXIMUM_BASIS_POINTS) revert GravityGrade__InvalidSaleParameters();

        if (uint256(_info.tokenType) == 0) {
            if (
                !ERC165CheckerUpgradeable.supportsInterface(
                    _info.tokenAddress,
                    type(IERC721Upgradeable).interfaceId
                )
            ) revert GravityGrade__InvalidSaleParameters();
        }
        if (uint256(_info.tokenType) == 1) {
            if (
                !ERC165CheckerUpgradeable.supportsInterface(
                    _info.tokenAddress,
                    type(IERC1155Upgradeable).interfaceId
                )
            ) revert GravityGrade__InvalidSaleParameters();
        }

        OwnershipRebate[] memory rebates = s_ownershipDiscounts[_saleId];
        bool foundRebate;
        for (uint256 i; i < rebates.length; ++i) {
            if (
                rebates[i].tokenAddress == _info.tokenAddress && rebates[i].tokenId == _info.tokenId
            ) {
                foundRebate = true;
                s_ownershipDiscounts[_saleId][i].basisPoints = _info.basisPoints;
            }
        }
        if (!foundRebate) s_ownershipDiscounts[_saleId].push(_info);
        _validateRebates(_saleId);
    }

    /// @inheritdoc IGravityGrade
    function deleteSale(uint256 _saleId) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert GravityGrade__NonExistentSale(_saleId);
        delete s_sales[_saleId];
        if (s_ownershipDiscounts[_saleId].length > 0) {
            delete s_ownershipDiscounts[_saleId];
        }
        emit SaleDeleted(_saleId);
    }

    /// @inheritdoc IGravityGrade
    function setAllowedPaymentCurrencies(uint256 _saleId, address[] calldata _currencyAddresses)
        external
        onlyGov
    {
        for (uint256 i; i < _currencyAddresses.length; i++) {
            s_whitelistedCurrencies[_saleId][_currencyAddresses[i]] = true;
        }
        emit PaymentCurrenciesSet(_saleId, _currencyAddresses);
    }

    /**
     * @notice remove payment currencies on a per saleId basis
     * @param _saleId the sale ID to set revoked payment currencies
     * @param _currencyAddresses the addresses of revoked payment currencies
     */
    function removePaymentCurrencies(uint256 _saleId, address[] calldata _currencyAddresses)
        external
        onlyGov
    {
        for (uint256 i; i < _currencyAddresses.length; ++i) {
            if (s_whitelistedCurrencies[_saleId][_currencyAddresses[i]]) {
                delete s_whitelistedCurrencies[_saleId][_currencyAddresses[i]];
            }
        }
        emit PaymentCurrenciesRevoked(_saleId, _currencyAddresses);
    }

    /// @inheritdoc IGravityGrade
    function setSwapManager(address _swapManager) external onlyGov {
        s_swapManager = ISwapManager(_swapManager);
    }

    /// @inheritdoc IGravityGrade
    function setOracleManager(address _oracleManager) external onlyGov {
        s_oracle = IOracleManager(_oracleManager);
    }

    /// @inheritdoc IGravityGrade
    function setTrusted(address _trusted, bool _isTrusted) external onlyGov {
        s_trustedAddresses[_trusted] = _isTrusted;
    }

    /** @notice retreive Trusted address status
     */
    function getTrusted(address _trusted) public view returns (bool) {
        return s_trustedAddresses[_trusted];
    }

    /// @inheritdoc IGravityGrade
    function withdraw(address _walletAddress, address _currency) external payable onlyGov {
        if (_currency == address(0)) {
            (bool callSuccess, ) = payable(_walletAddress).call{value: address(this).balance}("");
            if (!callSuccess) revert GravityGrade__WithdrawalFailed();
        } else {
            uint256 amount = IERC20(_currency).balanceOf(address(this));
            IERC20(_currency).approve(address(this), amount);
            if (!IERC20(_currency).transferFrom(address(this), _walletAddress, amount))
                revert GravityGrade__WithdrawalFailed();
        }
    }

    /// @inheritdoc IGravityGrade
    function setFeeWalletsAndPercentages(
        address[] calldata _walletAddresses,
        uint256[] calldata _feeBps
    ) external onlyOwner {
        uint256 sum;
        for (uint256 i; i < _feeBps.length; ++i) {
            sum += _feeBps[i];
        }
        if (sum > 10000) revert GravityGrade__ValueTooLarge(sum, 10000);
        s_beneficiaries = Beneficiaries(_feeBps, _walletAddresses);
        emit BeneficiariesUpdated(_walletAddresses, _feeBps);
    }

    function _validateRebates(uint256 _saleId) internal {
        // Not very gas efficient but prevents any and all 100% rebate scenarios
        uint256[] memory bulks = s_bulkDiscountBasisPoints[_saleId];
        uint256 sum;
        for (uint256 i; i < bulks.length; i++) {
            sum += bulks[i];
        }
        OwnershipRebate[] memory ownershipRebates = s_ownershipDiscounts[_saleId];
        uint256 best;
        OwnershipRebate memory current;
        for (uint256 j; j < ownershipRebates.length; j++) {
            current = ownershipRebates[j];
            if (current.basisPoints > best) {
                best = current.basisPoints;
            }
        }
        if (sum >= MAXIMUM_BASIS_POINTS)
            revert GravityGrade__ValueTooLarge(sum, MAXIMUM_BASIS_POINTS);
        if (best >= MAXIMUM_BASIS_POINTS)
            revert GravityGrade__ValueTooLarge(best, MAXIMUM_BASIS_POINTS);
        /*
        This is a pessimistic check since
            (((info.salePrice * (MAXIMUM_BASIS_POINTS - sum)) / MAXIMUM_BASIS_POINTS)
             * (MAXIMUM_BASIS_POINTS - best)) / MAXIMUM_BASIS_POINTS == 0
        Does not necessarily imply that
            (((SOME_BULK_AMOUNT* info.salePrice * (MAXIMUM_BASIS_POINTS - sum)) / MAXIMUM_BASIS_POINTS)
             * (MAXIMUM_BASIS_POINTS - best)) / MAXIMUM_BASIS_POINTS == 0
        */
        Sale memory info = s_sales[_saleId];
        uint256 postRebatePrice = (((info.salePrice * (MAXIMUM_BASIS_POINTS - sum)) /
            MAXIMUM_BASIS_POINTS) * (MAXIMUM_BASIS_POINTS - best)) / MAXIMUM_BASIS_POINTS;
        if (postRebatePrice == 0)
            revert GravityGrade__RebateTooLarge(_saleId, info.salePrice, sum, best);
        //if (sum + best >= MAXIMUM_BASIS_POINTS) revert GravityGrade__ValueTooLarge(sum + best, MAXIMUM_BASIS_POINTS);
    }

    // @inheritdoc IGravityGrade_Transak
    function onTransakOne(
        address _buyer,
        address _paymentToken,
        uint256 _numPurchases,
        uint256 _saleId
    ) external override {
        _buyPacks(_saleId, _numPurchases, 0, address(0), _paymentToken, _buyer);
    }

    /**
     * @notice internal function to faciltate purchasing any active sale in any whitelisted currency
     * @param _saleId the sale ID of the pack to purchase
     * @param _numPurchases the number of packs to purchase
     * @param _tokenId the tokenId claimed to be owned (for rebates)
     * @param _tokenAddress the token address for the tokenId claimed to be owned (for rebates)
     * @param _currency address of currency to use, address(0) for matic
     * @param _recipient the buyers' EOA address
     */
    function _buyPacks(
        uint256 _saleId,
        uint256 _numPurchases,
        uint256 _tokenId,
        address _tokenAddress,
        address _currency,
        address _recipient
    ) internal {
        if (s_sales[_saleId].tokenId == 0) revert GravityGrade__NonExistentSale(_saleId);
        if (s_saleStatus[_saleId] == true) revert GravityGrade__SaleInactive();
        if (s_whitelistedCurrencies[_saleId][_currency] == false)
            revert GravityGrade__CurrencyNotWhitelisted(_currency);
        Sale memory info = s_sales[_saleId];

        calculateTotalPacksBought(
            info.totalSupply,
            info.userCap,
            _saleId,
            _numPurchases,
            _recipient
        );
        uint256 balance = info.salePrice * _numPurchases;
        balance = _apply_bulk_discount(_saleId, balance, _numPurchases);
        if (_tokenAddress != ADDRESS_ZERO) {
            uint256 updatedBalance = applyOwnershipRebates(
                s_ownershipDiscounts[_saleId],
                balance,
                _tokenAddress,
                _tokenId
            );
            balance = updatedBalance > 0 ? updatedBalance : balance;
        }
        if (_currency == ADDRESS_ZERO) {
            ethPayment(_recipient, info.defaultCurrency, _currency, balance);
        } else {
            erc20Payment(info, _saleId, balance, _tokenId, _tokenAddress, _currency, _recipient);
        }
        _mint(_recipient, info.tokenId, _numPurchases, "");

        distributeBeneficiaryTokens(
            _numPurchases * info.salePrice,
            _currency,
            info.defaultCurrency
        );
    }

    /**
     * @notice internal function to validate received payment and refund the difference
     * @param _recipient the buyers' EOA address
     * @param _defaultCurrency default currency (contract address)
     * @param _currency address of currency to use, address(0) for matic
     * @param _balance Total cost of the purchase
     */
    function ethPayment(
        address _recipient,
        address _defaultCurrency,
        address _currency,
        uint256 _balance
    ) internal {
        uint256 ethPrice = s_oracle.getAmountOut(_defaultCurrency, _currency, _balance);
        if (ethPrice > msg.value) {
            revert GravityGrade__InsufficientEthValue(msg.value, ethPrice);
        } else {
            if (msg.value - ethPrice > 0) {
                (bool callSuccess, ) = payable(_recipient).call{value: msg.value - ethPrice}("");
                if (!callSuccess) revert GravityGrade__RefundFailed();
            }
        }
    }

    /**
     * @notice internal function to calculate and take erc20 payments
     * @param _info the Sale information
     * @param _saleId the sale ID of the purchase
     * @param _balance Total cost of the purchase
     * @param _tokenId the tokenId claimed to be owned (for rebates)
     * @param _tokenAddress the token address for the tokenId claimed to be owned (for rebates)
     * @param _currency address of currency to use
     * @param _recipient the buyers' EOA address
     */
    function erc20Payment(
        Sale memory _info,
        uint256 _saleId,
        uint256 _balance,
        uint256 _tokenId,
        address _tokenAddress,
        address _currency,
        address _recipient
    ) internal {
        uint256 balance = _balance;
        if (_currency != _info.defaultCurrency) {
            balance = s_oracle.getAmountOut(_info.defaultCurrency, _currency, balance);
        }
        if (!IERC20(_currency).transferFrom(_recipient, address(this), balance))
            revert GravityGrade__TransferFailed();
        // Todo: swap MATIC for _info.defaultCurrency if they're not eq
        if (!_info.profitState && (_currency != _info.defaultCurrency)) {
            IERC20(_currency).approve(address(s_swapManager), balance);
            s_swapManager.swap(_currency, _info.defaultCurrency, balance, address(this));
        }
    }

    /// @inheritdoc IGravityGrade
    function buyPacks(
        uint256 _saleId,
        uint256 _numPurchases,
        uint256 _tokenId,
        address _tokenAddress,
        address _currency
    ) external payable {
        _buyPacks(_saleId, _numPurchases, _tokenId, _tokenAddress, _currency, msg.sender);
    }

    /** @notice calculates the total packs bought for a given buyer
     *  @param _totalSupply cap on total amount to be sold
     *  @param _userCap a per-user cap
     *  @param _saleId the sale ID of the pack to purchase
     *  @param _numPurchases the number of packs to purchase
     *  @param _buyer the buyers' EOA address
     */
    function calculateTotalPacksBought(
        uint256 _totalSupply,
        uint256 _userCap,
        uint256 _saleId,
        uint256 _numPurchases,
        address _buyer
    ) internal {
        uint256 playerBought = s_perPlayerSold[_saleId][_buyer] + _numPurchases;
        uint256 totalBought = s_sold[_saleId] + _numPurchases;
        if (playerBought > _userCap) {
            revert GravityGrade__PurchaseExceedsPlayerMax(
                s_perPlayerSold[_saleId][_buyer],
                _userCap
            );
        } else {
            s_perPlayerSold[_saleId][_buyer] = playerBought;
        }
        if (totalBought > _totalSupply) {
            revert GravityGrade__PurchaseExceedsTotalMax(s_sold[_saleId], _totalSupply);
        } else {
            s_sold[_saleId] = totalBought;
        }
    }

    /** @notice sends tokens to the beneficaries
     *  @param _salePrice price of the pack
     *  @param _currency address of the currency used to buy the pack
     *  @param _defaultCurrency default currency (contract address)
     */
    function distributeBeneficiaryTokens(
        uint256 _salePrice,
        address _currency,
        address _defaultCurrency
    ) internal {
        Beneficiaries memory beneficiaries = s_beneficiaries;
        uint256 beneficiariesSize = beneficiaries.feeBps.length;
        for (uint256 i; i < beneficiariesSize; ++i) {
            uint256 amount = (beneficiaries.feeBps[i] * _salePrice) / MAXIMUM_BASIS_POINTS;
            if (_currency != _defaultCurrency) {
                IERC20(_currency).approve(address(s_swapManager), amount);
                s_swapManager.swap(
                    _currency,
                    _defaultCurrency,
                    amount,
                    beneficiaries.beneficiary[i]
                );
            } else {
                IERC20(_currency).approve(address(this), amount);
                if (
                    !IERC20(_currency).transferFrom(
                        address(this),
                        beneficiaries.beneficiary[i],
                        amount
                    )
                ) revert GravityGrade__TransferFailed();
            }
        }
    }

    /// @inheritdoc IGravityGrade
    function calculateDiscountedPackPrice(
        uint256 _saleId,
        uint256 _numPurchases,
        address _currency,
        address _tokenAddress
    ) external returns (Discounts memory) {
        Sale memory info = s_sales[_saleId];
        uint256 discountedPrice = info.salePrice * _numPurchases;
        discountedPrice = _apply_bulk_discount(_saleId, discountedPrice, _numPurchases);
        uint256 rebatePrice;
        if (_tokenAddress != ADDRESS_ZERO) {
            OwnershipRebate[] memory ownershipRebates = s_ownershipDiscounts[_saleId];
            uint256 rebateAmount;
            for (uint256 i; i < ownershipRebates.length; ++i) {
                if (ownershipRebates[i].tokenAddress == _tokenAddress) {
                    rebateAmount = ownershipRebates[i].basisPoints;
                }
            }
            if (rebateAmount > 0) {
                rebatePrice = calculateDiscountedPrice(rebateAmount, discountedPrice);
            } else {
                revert GravityGrade__TokenNotEligibleForRebate(_tokenAddress);
            }
        }
        discountedPrice = rebatePrice > 0 ? rebatePrice : discountedPrice;
        if (_currency != info.defaultCurrency) {
            discountedPrice = s_oracle.getAmountOut(
                info.defaultCurrency,
                _currency,
                discountedPrice
            );
        }
        return (
            Discounts(info.salePrice * _numPurchases, discountedPrice, _numPurchases, _tokenAddress)
        );
    }

    /** @notice calculates the balance after any applicable token ownership rebates
     *  @param _rebates applicable to the sale
     *  @param _balance the current pack balance after any applied bulk discounts
     *  @param _tokenAddress the token address for the tokenId claimed to be owned (for rebates)
     *  @param _tokenId the tokenId claimed to be owned (for rebates)
     */
    function applyOwnershipRebates(
        OwnershipRebate[] memory _rebates,
        uint256 _balance,
        address _tokenAddress,
        uint256 _tokenId
    ) internal view returns (uint256) {
        uint256 rebateAmount;
        uint256 tokenType;
        uint256 updatedbalance;
        for (uint256 i; i < _rebates.length; ++i) {
            if (_rebates[i].tokenAddress == _tokenAddress &&
                (_rebates[i].tokenType == TokenType.ERC721 ||
                _rebates[i].tokenType == TokenType.ERC1155 && _rebates[i].tokenId == _tokenId)) {
                rebateAmount = _rebates[i].basisPoints;
                tokenType = uint256(_rebates[i].tokenType);
            }
        }
        if (rebateAmount > 0) {
            bool applyRebate;
            if (tokenType == 0) {
                if (IERC721Upgradeable(_tokenAddress).balanceOf(msg.sender) > 0) {
                    applyRebate = true;
                } else {
                    revert GravityGrade__SenderDoesNotOwnToken(_tokenAddress, 0);
                }
            }
            if (tokenType == 1) {
                if (IERC1155Upgradeable(_tokenAddress).balanceOf(msg.sender, _tokenId) > 0) {
                    applyRebate = true;
                } else {
                    revert GravityGrade__SenderDoesNotOwnToken(_tokenAddress, _tokenId);
                }
            }
            if (applyRebate) updatedbalance = calculateDiscountedPrice(rebateAmount, _balance);
        } else {
            revert GravityGrade__TokenNotEligibleForRebate(_tokenAddress);
        }
        return updatedbalance;
    }

    /** @notice calculates the discounted price
     *  @param _bps discount amount as bps (basis points) e.g. 500 == 5 pct
     *  @param _salePrice the price upon which a discount should be applied
     */
    function calculateDiscountedPrice(uint256 _bps, uint256 _salePrice)
        internal
        pure
        returns (uint256)
    {
        return ((MAXIMUM_BASIS_POINTS - _bps) * _salePrice) / MAXIMUM_BASIS_POINTS;
    }

    /**
     * @notice Applies a bulk discount to a price
     * @param _saleId The id of the sale
     * @param _price The net price (i.e not the unit price)
     * @param _bulk The amount of units being purchased
     */
    function _apply_bulk_discount(
        uint256 _saleId,
        uint256 _price,
        uint256 _bulk
    ) internal view returns (uint256 final_price) {
        uint256 mod = MAXIMUM_BASIS_POINTS;
        uint256[] memory breakpoints = s_bulkDiscountBreakpoints[_saleId];
        uint256[] memory discounts = s_bulkDiscountBasisPoints[_saleId];
        // Todo: If we sort the discounts we can save a slight amount of gas... Let's not bother for the launch
        for (uint256 i; i < breakpoints.length; i++) {
            if (breakpoints[i] <= _bulk) {
                mod -= discounts[i];
            }
        }
        final_price = (mod * _price) / MAXIMUM_BASIS_POINTS;
    }

    /// @inheritdoc IGravityGrade
    function airdrop(
        address[] calldata _recipients,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external onlyTrusted {
        for (uint256 i; i < _recipients.length; i++) {
            if (bytes(s_uris[_tokenIds[i]]).length == 0)
                revert GravityGrade__TokenNotSet(_tokenIds[i]);
            _mint(_recipients[i], _tokenIds[i], _amounts[i], "");
        }
    }

    /**
     * @notice retreive Moderator
     * @return address The address of the current moderator
     */
    function getModerator() public view returns (address) {
        return s_moderator;
    }

    /** @notice change Token Name
     *  @param _name new name
     */
    function setName(string memory _name) external onlyGov {
        name = _name;
    }

    /** @notice change Token Symbol
     *  @param _symbol new symbol
     */
    function setSymbol(string memory _symbol) external onlyGov {
        symbol = _symbol;
    }

    /** @notice retreive the latest SaleId
     * @return uint256 The latest sale id
     */
    function getSaleId() public view returns (uint256) {
        return s_saleId;
    }

    /** @notice retreives the beneficiaries
     * @return Beneficiaries The beneficiaries
     */
    function getBeneficiaries() public view returns (Beneficiaries memory) {
        return s_beneficiaries;
    }

    /** @notice retreives the sale
     *  @param _saleId saleId
     * @return Sale The information regarding the sale
     */
    function getSale(uint256 _saleId) public view returns (Sale memory) {
        return s_sales[_saleId];
    }

    /// @inheritdoc IGravityGrade
    function setSaleState(uint256 _saleId, bool _paused) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert GravityGrade__NonExistentSale(_saleId);
        s_saleStatus[_saleId] = _paused;
        emit SaleState(_saleId, _paused);
    }

    /** @notice retreives the sale status
     *  @param _saleId saleId
     * @return Whether the sale is paused or not
     */
    function getSaleStatus(uint256 _saleId) public view returns (bool) {
        return s_saleStatus[_saleId];
    }

    /// @inheritdoc IGravityGrade
    function burn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external override onlyTrusted {
        if (bytes(s_uris[_tokenId]).length == 0) revert GravityGrade__TokenNotSet(_tokenId);
        _burn(_from, _tokenId, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
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

pragma solidity 0.8.8;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IGravityGrade is IERC1155Upgradeable {
    enum GravityGradeDrops {
        UNUSED,
        CargoDrop3,
        AnniversaryPackMystery,
        AnniversaryPackOutlier,
        AnniversaryPackCommon,
        AnniversaryPackUncommon,
        AnniversaryPackRare,
        AnniversaryPackLegendary,
        StarterPack
    }

    event SaleState(uint256 saleId, bool isPaused);
    event SaleDeleted(uint256 saleId);
    event SaleInfoUpdated(
        uint256 saleId,
        uint256 tokenId,
        uint256 salePrice,
        uint256 totalSupply,
        uint256 userCap,
        address defaultCurrency
    );
    event BeneficiariesUpdated(address[] beneficiaries, uint256[] basisPoints);
    event PaymentCurrenciesSet(uint256 saleId, address[] currencyAddresses);
    event PaymentCurrenciesRevoked(uint256 saleId, address[] currencyAddresses);

    // Used to classify token types in the ownership rebate struct
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @notice Used to provide specifics for ownership based discounts
     * @param tokenType The type of token
     * @param tokenAddress The address of the token contract
     * @param tokenId The token id, ignored if ERC721 is provided for the token type
     * @param basisPoints The discount in basis points
     */
    struct OwnershipRebate {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId; // ignored if ERC721
        uint256 basisPoints;
    }

    /**
     * @notice Used to output pack discount info
     * @param originalPrice The original pack price from calculating the salePrice * purchaseQuantity
     * @param discountedPrice The discounted pack price from calculating bulk purchases and rebates
     * @param purchaseQuantity The number of packs to purchase
     * @param tokenAddress The address of the token contract
     */
    struct Discounts {
        uint256 originalPrice;
        uint256 discountedPrice;
        uint256 purchaseQuantity;
        address tokenAddress;
    }

    /**
     * @notice Calculates the discount pack price
     * @param _saleId The sale ID to query the price against
     * @param _numPurchases The number of packs to query against
     * @param _currency Address of currency to use, address(0) for matic
     * @param _tokenAddress The token address for the token claimed to be held
     * @return Discounts The discount details for the pack
     */
    function calculateDiscountedPackPrice(
        uint256 _saleId,
        uint256 _numPurchases,
        address _currency,
        address _tokenAddress
    ) external returns (Discounts memory);

    /**
     * @notice Sets the TokenURI
     * @param _tokenId The tokenId to set for the URI
     * @param _uri The URI to set for the token
     */
    function setTokenUri(uint256 _tokenId, string memory _uri) external;

    /**
     * @notice Create new emissions/sales
     * @param _tokenId The ERC1155 tokenId to sell
     * @param _salePrice Price in US dollars
     * @param _totalSupplyAmountToSell Cap on total amount to be sold
     * @param _userCap A per-user cap
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     */
    function createNewSale(
        uint256 _tokenId,
        uint256 _salePrice,
        uint256 _totalSupplyAmountToSell,
        uint256 _userCap,
        address _defaultCurrency,
        bool _profitState
    ) external returns (uint256 saleId);

    /**
     * @notice Start and pause sales
     * @param _saleId The sale ID to set the status for
     * @param _paused The sale status
     */
    function setSaleState(uint256 _saleId, bool _paused) external;

    /**
     * @notice Modify sale
     * @param _saleId The sale ID to modify
     * @param _salePrice Price in US dollars
     * @param _totalSupplyAmountToSell Cap on total amount to be sold
     * @param _userCap A per-user cap
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     */
    function modifySale(
        uint256 _saleId,
        uint256 _salePrice,
        uint256 _totalSupplyAmountToSell,
        uint256 _userCap,
        address _defaultCurrency,
        bool _profitState
    ) external;

    /**
     * @notice Adds a bulk discount to a sale
     * @param _saleId The sale id
     * @param _breakpoint At what quantity the discount should be applied
     * @param _basisPoints The non cumulative discount in basis point
     */
    function addBulkDiscount(
        uint256 _saleId,
        uint256 _breakpoint,
        uint256 _basisPoints
    ) external;

    /**
     * @notice Adds a token ownership based discount to a sale
     * @param _saleId The sale id
     * @param _info Struct containing specifics regarding the discount
     */
    function addOwnershipDiscount(uint256 _saleId, OwnershipRebate calldata _info) external;

    /**
     * @notice Delete a sale
     * @param _saleId The sale ID to delete
     */
    function deleteSale(uint256 _saleId) external;

    /**
     * @notice Set the whitelist for allowed payment currencies on a per saleId basis
     * @param _saleId The sale ID to set
     * @param _currencyAddresses The addresses of permissible payment currencies
     */
    function setAllowedPaymentCurrencies(uint256 _saleId, address[] calldata _currencyAddresses)
        external;

    /**
     * @notice Set a swap manager to manage the means through which tokens are exchanged
     * @param _swapManager SwapManager address
     */
    function setSwapManager(address _swapManager) external;

    /**
     * @notice Set a oracle manager to manage the means through which token prices are fetched
     * @param _oracleManager OracleManager address
     */
    function setOracleManager(address _oracleManager) external;

    /**
     * @notice Set administrator
     * @param _moderatorAddress The addresse of an allowed admin
     */
    function setModerator(address _moderatorAddress) external;

    /**
     * @notice Adds a trusted party, which is allowed to mint tokens through the airdrop function
     * @param _trusted The address of the trusted party
     * @param _isTrusted Whether the party is trusted or not
     */
    function setTrusted(address _trusted, bool _isTrusted) external;

    /**
     * @notice Empty the treasury into the owners or an arbitrary wallet
     * @param _walletAddress The withdrawal EOA address
     * @param _currency ERC20 currency to withdraw, ZERO address implies MATIC
     */
    function withdraw(address _walletAddress, address _currency) external payable;

    /**
     * @notice  Set Fee Wallets and fee percentages from sales
     * @param _walletAddresses The withdrawal EOA addresses
     * @param _feeBps Represented as basis points e.g. 500 == 5 pct
     */
    function setFeeWalletsAndPercentages(
        address[] calldata _walletAddresses,
        uint256[] calldata _feeBps
    ) external;

    /**
     * @notice Purchase any active sale in any whitelisted currency
     * @param _saleId The sale ID of the pack to purchase
     * @param _numPurchases The number of packs to purchase
     * @param _tokenId The tokenId claimed to be owned (for rebates)
     * @param _tokenAddress The token address for the tokenId claimed to be owned (for rebates)
     * @param _currency Address of currency to use, address(0) for matic
     */
    function buyPacks(
        uint256 _saleId,
        uint256 _numPurchases,
        uint256 _tokenId,
        address _tokenAddress,
        address _currency
    ) external payable;

    /**
     * @notice Airdrop tokens to arbitrary wallets
     * @param _recipients The recipient addresses
     * @param _tokenIds The tokenIds to mint
     * @param _amounts The amount of tokens to mint
     */
    function airdrop(
        address[] calldata _recipients,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice used to burn tokens by trusted contracts
     * @param _from address to burn tokens from
     * @param _tokenId id of to-be-burnt tokens
     * @param _amount number of tokens to burn
     */
    function burn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapManager {
    function swap(
        address srcToken,
        address dstToken,
        uint256 amount,
        address destination
    ) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracleManager {
    function getAmountOut(
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) external returns (uint256);
}

pragma solidity ^0.8.0;


/// @title Transak extension for Gravity Grade
interface IGravityGrade_Transak {
    /**
     * @notice adaptor to allow purchases via Transak One
     * @dev Price is calculated implicitly from _paymentToken, _saleId, _numPurchases + bulk discounts
     * @param _buyer the buyers' EOA address
     * @param _paymentToken address of currency to use, address(0) for matic
     * @param _numPurchases the number of packs to purchase
     * @param _saleId the sale ID of the pack to purchase
     */
    function onTransakOne(
        address _buyer,
        address _paymentToken,
        uint256 _numPurchases,
        uint256 _saleId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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