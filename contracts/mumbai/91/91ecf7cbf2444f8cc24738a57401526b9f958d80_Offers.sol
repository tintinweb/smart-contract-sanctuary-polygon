/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

// SPDX-License-Identifier: MIT

// File contracts/Offer/IOffer.sol

pragma solidity ^0.8.15;

/// Tenure is not within minimum and maximum authorized
/// @param tenure, actual tenure
/// @param minTenure, minimum tenure
/// @param maxTenure, maximum tenure
error InvalidTenure(uint16 tenure, uint16 minTenure, uint16 maxTenure);

/// AdvanceFee is higher than the maxAdvancedRatio
/// @param advanceFee, actual advanceFee
/// @param maxAdvancedRatio, maximum advanced ratio
error InvalidAdvanceFee(uint16 advanceFee, uint16 maxAdvancedRatio);

/// DiscountFee is lower than the minDiscountFee
/// @param discountFee, actual discountFee
/// @param minDiscountFee, minimum discount fee
error InvalidDiscountFee(uint16 discountFee, uint16 minDiscountFee);

/// FactoringFee is lower than the minDiscountFee
/// @param factoringFee, actual factoringFee
/// @param minFactoringFee, minimum factoring fee
error InvalidFactoringFee(uint16 factoringFee, uint16 minFactoringFee);

/// InvoiceAmount is not within minimum and maximum authorized
/// @param invoiceAmount, actual invoice amount
/// @param minAmount, minimum invoice amount
/// @param maxAmount, maximum invoice amount
error InvalidInvoiceAmount(uint invoiceAmount, uint minAmount, uint maxAmount);

/// Available Amount is higher than Invoice Amount
/// @param availableAmount, actual available amount
/// @param invoiceAmount, actual invoice amount
error InvalidAvailableAmount(uint availableAmount, uint invoiceAmount);

/// @title IOffer
/// @author Polytrade
interface IOffer {
    struct OfferItem {
        uint advancedAmount;
        uint reserve;
        uint64 disbursingAdvanceDate;
        OfferParams params;
        OfferRefunded refunded;
    }

    struct OfferParams {
        uint8 gracePeriod;
        uint16 tenure;
        uint16 factoringFee;
        uint16 discountFee;
        uint16 advanceFee;
        address stableAddress;
        uint invoiceAmount;
        uint availableAmount;
    }

    struct OfferRefunded {
        uint16 lateFee;
        uint64 dueDate;
        uint24 numberOfLateDays;
        uint totalCalculatedFees;
        uint netAmount;
    }

    /**
     * @dev Emitted when new offer is created
     */
    event OfferCreated(uint indexed offerId, uint16 pricingId);

    /**
     * @dev Emitted when Reserve is refunded
     */
    event ReserveRefunded(uint indexed offerId, uint refundedAmount);

    /**
     * @dev Emitted when PricingTable Address is updated
     */
    event NewPricingTableContract(
        address oldPricingTableAddress,
        address newPricingTableAddress
    );

    /**
     * @dev Emitted when Treasury Address is updated
     */
    event NewTreasuryAddress(
        address oldTreasuryAddress,
        address newTreasuryAddress
    );

    /**
     * @dev Emitted when stableAddress is mapped to LenderPool
     */
    event StableMappedToLenderPool(
        address stableAddress,
        address lenderPoolAddress
    );
}


// File contracts/ILenderPool.sol

pragma solidity ^0.8.15;

interface ILenderPool {
    function requestFundInvoice(uint amount) external;
}


// File contracts/PricingTable/IPricingTable.sol

pragma solidity ^0.8.15;

/// @title IPricingTable
/// @author Polytrade
interface IPricingTable {
    struct PricingItem {
        uint16 minTenure;
        uint16 maxTenure;
        uint16 maxAdvancedRatio;
        uint16 minDiscountFee;
        uint16 minFactoringFee;
        uint minAmount;
        uint maxAmount;
    }

    event NewPricingItem(uint16 id, PricingItem pricingItem);
    event UpdatedPricingItem(uint16 id, PricingItem pricingItem);
    event RemovedPricingItem(uint16 id);

    /**
     * @notice Add a Pricing Item to the Pricing Table
     * @dev Only Owner is authorized to add a Pricing Item
     * @param pricingId, pricingId (hex format)
     * @param minTenure, minimum tenure expressed in percentage
     * @param maxTenure, maximum tenure expressed in percentage
     * @param maxAdvancedRatio, maximum advanced ratio expressed in percentage
     * @param minDiscountRange, minimum discount range expressed in percentage
     * @param minFactoringFee, minimum Factoring fee expressed in percentage
     * @param minAmount, minimum amount
     * @param maxAmount, maximum amount
     */
    function addPricingItem(
        uint16 pricingId,
        uint16 minTenure,
        uint16 maxTenure,
        uint16 maxAdvancedRatio,
        uint16 minDiscountRange,
        uint16 minFactoringFee,
        uint minAmount,
        uint maxAmount
    ) external;

    /**
     * @notice Add a Pricing Item to the Pricing Table
     * @dev Only Owner is authorized to add a Pricing Item
     * @param pricingId, pricingId (hex format)
     * @param minTenure, minimum tenure expressed in percentage
     * @param maxTenure, maximum tenure expressed in percentage
     * @param maxAdvancedRatio, maximum advanced ratio expressed in percentage
     * @param minDiscountRange, minimum discount range expressed in percentage
     * @param minFactoringFee, minimum Factoring fee expressed in percentage
     * @param minAmount, minimum amount
     * @param maxAmount, maximum amount
     */
    function updatePricingItem(
        uint16 pricingId,
        uint16 minTenure,
        uint16 maxTenure,
        uint16 maxAdvancedRatio,
        uint16 minDiscountRange,
        uint16 minFactoringFee,
        uint minAmount,
        uint maxAmount,
        bool status
    ) external;

    /**
     * @notice Remove a Pricing Item from the Pricing Table
     * @dev Only Owner is authorized to add a Pricing Item
     * @param id, id of the pricing Item
     */
    function removePricingItem(uint16 id) external;

    /**
     * @notice Returns the pricing Item
     * @param id, id of the pricing Item
     * @return returns the PricingItem (struct)
     */
    function getPricingItem(uint16 id)
        external
        view
        returns (PricingItem memory);

    /**
     * @notice Returns if the pricing Item is valid
     * @param id, id of the pricing Item
     * @return returns boolean if pricing is valid or not
     */
    function isPricingItemValid(uint16 id) external view returns (bool);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/Offer/Offer.sol

pragma solidity ^0.8.15;






/// @title Offer
/// @author Polytrade
contract Offers is IOffer, Ownable {

    IPricingTable public pricingTable;

    uint private _countId;
    uint16 private constant _PRECISION = 1E4;

    uint public totalAdvanced;
    uint public totalRefunded;

    address public treasury;

    mapping(uint => uint16) private _offerToPricingId;
    mapping(uint => OfferItem) public offers;
    mapping(address => address) public stableToPool;

    constructor(address pricingTableAddress, address treasuryAddress) {
        require(
            pricingTableAddress != address(0) && treasuryAddress != address(0)
        );
        pricingTable = IPricingTable(pricingTableAddress);
        treasury = treasuryAddress;
    }

    /**
     * @dev Set PricingTable linked to the contract to a new PricingTable (`pricingTable`)
     * Can only be called by the owner
     */
    function setPricingTableAddress(address _newPricingTable)
        external
        onlyOwner
    {
        require(_newPricingTable != address(0));
        address oldPricingTable = address(pricingTable);
        pricingTable = IPricingTable(_newPricingTable);
        emit NewPricingTableContract(oldPricingTable, _newPricingTable);
    }

    /**
     * @dev Set TreasuryAddress linked to the contract to a new treasuryAddress
     * Can only be called by the owner
     */
    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0));
        address oldTreasury = treasury;
        treasury = _newTreasury;
        emit NewTreasuryAddress(oldTreasury, _newTreasury);
    }

    /**
     * @dev Set LenderPoolAddress linked to the contract to a new lenderPoolAddress
     * Can only be called by the owner
     */
    function setLenderPoolAddress(
        address stableAddress,
        address lenderPoolAddress
    ) external onlyOwner {
        require(stableAddress != address(0) && lenderPoolAddress != address(0));
        stableToPool[stableAddress] = lenderPoolAddress;
        emit StableMappedToLenderPool(stableAddress, lenderPoolAddress);
    }

    /**
     * @notice check if params fit with the pricingItem
     * @dev checks every params and returns a custom Error
     * @param pricingId, Id of the pricing Item
     * @param tenure, tenure expressed in number of days
     * @param advanceFee, ratio for the advance Fee
     * @param discountFee, ratio for the discount Fee
     * @param factoringFee, ratio for the factoring Fee
     * @param invoiceAmount, amount for the invoice
     * @param availableAmount, amount for the available amount
     */
    function checkOfferValidity(
        uint16 pricingId,
        uint16 tenure,
        uint16 advanceFee,
        uint16 discountFee,
        uint16 factoringFee,
        uint invoiceAmount,
        uint availableAmount
    ) external view returns (bool) {
        return
            _checkParams(
                pricingId,
                tenure,
                advanceFee,
                discountFee,
                factoringFee,
                invoiceAmount,
                availableAmount
            );
    }

function requestFund(address stable, uint amount) external {
    ILenderPool(stableToPool[address(stable)]).requestFundInvoice(amount);
}

    /**
     * @notice Create an offer, check if it fits pricingItem requirements and send Advance to treasury
     * @dev calls _checkParams and returns Error if params don't fit with the pricingID
     * @dev only `Owner` can create a new offer
     * @dev emits OfferCreated event
     * @dev send Advance Amount to treasury
     * @param pricingId, Id of the pricing Item
     * @param advanceFee;
     * @param discountFee;
     * @param factoringFee;
     * @param gracePeriod;
     * @param availableAmount;
     * @param invoiceAmount;
     * @param tenure;
     * @param stableAddress;
     */
    function createOffer(
        uint16 pricingId,
        uint16 advanceFee,
        uint16 discountFee,
        uint16 factoringFee,
        uint8 gracePeriod,
        uint invoiceAmount,
        uint availableAmount,
        uint16 tenure,
        address stableAddress
    ) public onlyOwner returns (uint) {
        require(
            stableToPool[stableAddress] != address(0),
            "Stable Address not whitelisted"
        );
        require(
            _checkParams(
                pricingId,
                tenure,
                advanceFee,
                discountFee,
                factoringFee,
                invoiceAmount,
                availableAmount
            ),
            "Invalid offer parameters"
        );

        OfferItem memory offer;
        offer.advancedAmount = _calculateAdvancedAmount(
            availableAmount,
            advanceFee
        );

        offer.reserve = (invoiceAmount - offer.advancedAmount);
        offer.disbursingAdvanceDate = uint64(block.timestamp);

        _countId++;
        _offerToPricingId[_countId] = pricingId;
        offer.params = OfferParams({
            gracePeriod: gracePeriod,
            tenure: tenure,
            factoringFee: factoringFee,
            discountFee: discountFee,
            advanceFee: advanceFee,
            stableAddress: stableAddress,
            invoiceAmount: invoiceAmount,
            availableAmount: availableAmount
        });
        offers[_countId] = offer;

        IERC20 stable = IERC20(stableAddress);
        uint8 decimals = IERC20Metadata(address(stable)).decimals();

        uint amount = offers[_countId].advancedAmount * (10**(decimals - 2));

        totalAdvanced += amount;

        stable.transferFrom(
            stableToPool[address(stable)],
            treasury,
            amount
        );

        emit OfferCreated(_countId, pricingId);
        return _countId;
    }

    /**
     * @notice Send the reserve Refund to the treasury
     * @dev checks if Offer exists and if not refunded yet
     * @dev only `Owner` can call reserveRefund
     * @dev emits OfferReserveRefunded event
     * @param offerId, Id of the offer
     * @param dueDate, due date
     * @param lateFee, late fees (ratio)
     */
    function reserveRefund(
        uint offerId,
        uint64 dueDate,
        uint16 lateFee
    ) public onlyOwner {
        require(
            _offerToPricingId[offerId] != 0 &&
                offers[offerId].refunded.netAmount == 0,
            "Invalid Offer"
        );

        OfferItem memory offer = offers[offerId];
        OfferRefunded memory refunded;

        refunded.lateFee = lateFee;
        refunded.dueDate = dueDate;

        uint lateAmount = 0;
        if (block.timestamp > (dueDate + offer.params.gracePeriod)) {
            refunded.numberOfLateDays = _calculateLateDays(
                dueDate,
                offer.params.gracePeriod
            );
            lateAmount = _calculateLateAmount(
                offer.advancedAmount,
                lateFee,
                refunded.numberOfLateDays
            );
        }

        uint factoringAmount = _calculateFactoringAmount(
            offer.params.invoiceAmount,
            offer.params.factoringFee
        );

        uint discountAmount = _calculateDiscountAmount(
            offer.advancedAmount,
            offer.params.discountFee,
            offer.params.tenure
        );

        refunded.totalCalculatedFees = (lateAmount +
            factoringAmount +
            discountAmount);
        refunded.netAmount = offer.reserve - refunded.totalCalculatedFees;

        offers[offerId].refunded = refunded;

        IERC20 stable = IERC20(offer.params.stableAddress);
        uint8 decimals = IERC20Metadata(address(stable)).decimals();

        uint amount = offers[offerId].refunded.netAmount * (10**(decimals - 2));

        totalRefunded += amount;

        stable.transferFrom(
            stableToPool[address(stable)],
            treasury,
            amount
        );

        emit ReserveRefunded(offerId, amount);
    }

    /**
     * @notice check if params fit with the pricingItem
     * @dev checks every params and returns a custom Error
     * @param pricingId, Id of the pricing Item
     * @param tenure, tenure expressed in number of days
     * @param advanceFee, ratio for the advance Fee
     * @param discountFee, ratio for the discount Fee
     * @param factoringFee, ratio for the factoring Fee
     * @param invoiceAmount, amount for the invoice
     * @param availableAmount, amount for the available amount
     */
    function _checkParams(
        uint16 pricingId,
        uint16 tenure,
        uint16 advanceFee,
        uint16 discountFee,
        uint16 factoringFee,
        uint invoiceAmount,
        uint availableAmount
    ) private view returns (bool) {
        require(pricingTable.isPricingItemValid(pricingId));
        IPricingTable.PricingItem memory pricing = pricingTable.getPricingItem(
            pricingId
        );
        if (tenure < pricing.minTenure || tenure > pricing.maxTenure)
            revert InvalidTenure(tenure, pricing.minTenure, pricing.maxTenure);
        if (advanceFee > pricing.maxAdvancedRatio)
            revert InvalidAdvanceFee(advanceFee, pricing.maxAdvancedRatio);
        if (discountFee < pricing.minDiscountFee)
            revert InvalidDiscountFee(discountFee, pricing.minDiscountFee);
        if (factoringFee < pricing.minFactoringFee)
            revert InvalidFactoringFee(factoringFee, pricing.minFactoringFee);
        if (
            invoiceAmount < pricing.minAmount ||
            invoiceAmount > pricing.maxAmount
        )
            revert InvalidInvoiceAmount(
                invoiceAmount,
                pricing.minAmount,
                pricing.maxAmount
            );
        if (invoiceAmount < availableAmount)
            revert InvalidAvailableAmount(availableAmount, invoiceAmount);
        return true;
    }

    /**
     * @notice calculate the number of Late Days (Now - dueDate - gracePeriod)
     * @dev calculate based on `(block.timestamp - dueDate - gracePeriod) / 1 days` formula
     * @param dueDate, due date -> epoch timestamps format
     * @param gracePeriod, grace period -> expressed in seconds
     * @return uint24, number of late Days
     */
    function _calculateLateDays(uint dueDate, uint gracePeriod)
        private
        view
        returns (uint24)
    {
        return uint24(block.timestamp - dueDate - gracePeriod) / 1 days;
    }

    /**
     * @notice calculate the advanced Amount (availableAmount * advanceFee)
     * @dev calculate based on `(availableAmount * advanceFee)/ _precision` formula
     * @param availableAmount, amount for the available amount
     * @param advanceFee, ratio for the advance Fee
     * @return uint amount of the advanced
     */
    function _calculateAdvancedAmount(uint availableAmount, uint16 advanceFee)
        private
        pure
        returns (uint)
    {
        return (availableAmount * advanceFee) / _PRECISION;
    }

    /**
     * @notice calculate the Factoring Amount (invoiceAmount * factoringFee)
     * @dev calculate based on `(invoiceAmount * factoringFee) / _precision` formula
     * @param invoiceAmount, amount for the invoice amount
     * @param factoringFee, ratio for the factoring Fee
     * @return uint amount of the factoring
     */
    function _calculateFactoringAmount(uint invoiceAmount, uint16 factoringFee)
        private
        pure
        returns (uint)
    {
        return (invoiceAmount * factoringFee) / _PRECISION;
    }

    /**
     * @notice calculate the Discount Amount ((advancedAmount * discountFee) / 365) * tenure)
     * @dev calculate based on `((advancedAmount * discountFee) / 365) * tenure) / _precision` formula
     * @param advancedAmount, amount for the advanced amount
     * @param discountFee, ratio for the discount Fee
     * @param tenure, tenure
     * @return uint amount of the Discount
     */
    function _calculateDiscountAmount(
        uint advancedAmount,
        uint16 discountFee,
        uint16 tenure
    ) private pure returns (uint) {
        return (((advancedAmount * discountFee)) * tenure) / 365 / _PRECISION;
    }

    /**
     * @notice calculate the Late Amount (((lateFee * advancedAmount) / 365) * lateDays)
     * @dev calculate based on `(((lateFee * advancedAmount) / 365) * lateDays) / _precision` formula
     * @param advancedAmount, amount for the advanced amount
     * @param lateFee, ratio for the late Fee
     * @param lateDays, number of late days
     * @return uint, Late Amount
     */
    function _calculateLateAmount(
        uint advancedAmount,
        uint16 lateFee,
        uint24 lateDays
    ) private pure returns (uint) {
        return (((lateFee * advancedAmount) / 365) * lateDays) / _PRECISION;
    }
}