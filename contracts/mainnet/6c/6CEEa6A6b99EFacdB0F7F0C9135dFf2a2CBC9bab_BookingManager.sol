// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "./interfaces/ISwixCity.sol";
import "./interfaces/IBookingManager.sol";
import "./interfaces/IFinancialParams.sol";
import "./interfaces/ICancelPolicyManager.sol";
import "./interfaces/IRevenueSplitCalculator.sol";

import "./abstracts/SwixContract.sol";

contract BookingManager is
    ILeaseStructs,
    IFinancialParams,
    IBookingManager,
    SwixContract,
    ReentrancyGuard,
    ERC1155Receiver,
    KeeperCompatibleInterface
{
    using SafeERC20 for IERC20;


    /* =====================================================
                          CONSTANTS
    ===================================================== */

    /// Constant to denominate the percentages in
    uint256 constant public ONE_HUNDRED_PERCENT = 10_000;

    
    /* =====================================================
                          STATE VARIABLES
    ===================================================== */

    /// Mapping of booking indexes
    /// City => leaseIndex => startNight => bookingIndex
    mapping(ISwixCity => mapping(uint256 => mapping(uint256 => Index))) public bookingIndexes;

    /// Array of all active bookings
    Booking[] public bookings;

    /// Costs aggregated on a global level
    uint256 public globalCosts;

    /// Expense Wallet address
    address public expenseWallet;
    /// DAO Treasury Wallet address
    address public dao;
    /// Tokenback Wallet address
    ITokenback public tokenbackWallet;
    /// Refund Wallet address
    address public refundWallet;

    /// Token used for payments
    IERC20 public stablecoin;
    /// Calculator of revenue split
    IRevenueSplitCalculator public calculator;
    /// Manager of cancel policies
    ICancelPolicyManager public cancelPolicyManager;

    
    /* =====================================================
                          CONSTRUCTOR
    ===================================================== */

    /// @param setEcosystem current SwixEcosystem contract
    constructor(ISwixEcosystem setEcosystem) SwixContract(setEcosystem) {}


    /* =====================================================
                          ECOSYSTEM
    ===================================================== */

    /// Initialize the state variable 
    /// set the initialized to true, log the timestamp
    function initialize()
        public
        nonReentrant
        ecosystemInitialized
        onlyContractManager
    {
        require(initialized == false);
        
        // Get contracts and accounts used within BookingManager from Ecosystem
        calculator          = _revenueSplitCalculator();
        cancelPolicyManager = _cancelPolicyManager();
        stablecoin          = _stablecoinToken();
        tokenbackWallet     = _tokenback();
        dao                 = _dao();
        expenseWallet       = _expenseWallet();
        refundWallet        = _refundWallet();

        // Mark contract as initialized
        initialized = true;
        // Save timestamp as time of last update
        lastUpdated = block.timestamp;
    }

    /// Update state variables from SwixEcosystem
    function update()
        public
        nonReentrant
        onlyContractManager
    {
        // Get contracts and accounts used within BookingManager from Ecosystem
        calculator          = _revenueSplitCalculator();
        cancelPolicyManager = _cancelPolicyManager();
        stablecoin          = _stablecoinToken();
        tokenbackWallet     = _tokenback();
        dao                 = _dao();
        refundWallet        = _refundWallet();

        // Save timestamp as time of last update
        lastUpdated = block.timestamp;
    }


    /* =====================================================
                          USER FUNCTIONS
    ===================================================== */

    /// Book a stay in a particular property belonging to a chosen City
    /// Nights provided as input need to be consecutive and increasing
    /// Chosen Cancellation Policy must be allowed for Lease in City
    /// 
    /// @param city         chosen City contract
    /// @param leaseIndex   index of particular Lease in City's Leases array
    /// @param nights       indexes of nights to book in Lease
    /// @param cancelPolicy index of Cancellation Policy
    function book(
        ISwixCity city,
        uint256 leaseIndex,
        uint256[] calldata nights,
        uint256 cancelPolicy
    )
        external
        nonReentrant
        override
    {
        ///  Get timestamp of check-in
        uint256 checkInTimestamp = city.getLease(leaseIndex).leaseContract.START_TIMESTAMP() + nights[0] * 1 days;
        /// Check if the booked stay is in the future
        require(checkInTimestamp > block.timestamp, "TOO_LATE");

        /// Check if chosen cancellation policy is allowed in the lease
        require(city.getLease(leaseIndex).cancelPolicies[cancelPolicy], "WRONG_POLICY");

        /// Define counter for loops
        uint256 i;
        
        for (i = 0; i<nights.length; i++) {
            /// Check if the nights in array are increasing and consecutive
            if (i > 0) require(nights[i] == nights[i-1] + 1, "NOT_CONSECUTIVE");
        }
        
        /// Get joined price of stay and check availability
        uint256 price = city.getPriceOfStay(leaseIndex, nights);

        /// Pull funds from the user
        stablecoin.safeTransferFrom(
            msg.sender,
            address(this),
            price
        );

        /// Get cancellation policy data
        (uint256 fullRefundUntil, uint256 halfRefundUntil) = cancelPolicyManager.getCancelTimes(
            cancelPolicy,
            checkInTimestamp
        );

        /// Create a booking
        bookings.push(Booking(
            city,
            leaseIndex,
            nights[0],
            nights[nights.length - 1],
            fullRefundUntil,
            halfRefundUntil,
            price,
            city.getLease(leaseIndex).tokenbackRate,
            msg.sender,
            false
        ));

        /// Set the counter equal to the new booking index
        i = bookings.length - 1;

        /// Push booking index in the array to mapping
        bookingIndexes[city][leaseIndex][nights[0]].index   = i;
        bookingIndexes[city][leaseIndex][nights[0]].exists  = true;

        /// Pull the night tokens from City
        _getNights(
            city,
            leaseIndex,
            nights
        );

        /// Get first and last night of booking
        uint256 startNight = nights[0];

        /// Emit event
        emit Book(
            i,
            address(city),
            leaseIndex,
            startNight
        );
    }

    /// Cancel booking
    /// Price of booking will be refunded based on the time of cancel and chosen cancellation policy
    /// 
    /// @param bookingIndex index of booking in `bookings` array
    function cancel(
        uint256 bookingIndex
    ) 
        external
        nonReentrant
    {
        /// Check if sender is authorized to cancel booking
        require(msg.sender == bookings[bookingIndex].user);

        Booking memory booking = bookings[bookingIndex];

        /// Delete cancelled booking and update booking array
        _deleteBooking(bookingIndex);

        /// Update avaiability and send nights tokens back to City
        _refundNights(booking);
        if (false == booking.released) {
            /// Refund funds to user (if elligable) and return the remaining value
            uint256 remaining = _refund(
                booking.fullRefundUntil,
                booking.halfRefundUntil,
                booking.bookingPrice
            );
            
            /// Inject remaining value to Swix system
            /// Tokenback applies to non-refunded value
            if (remaining > 0) {
                // tokenback set to false for internal testing
                _injectFunds(booking, remaining, true);
            }
        }
        emit Cancel(bookingIndex);
    }
    
    /// Release funds from booking into Swix ecosystem
    /// Applicable ancellation periods must have passed
    ///
    /// @param bookingIndex index of booking in `bookings` array
    function releaseFunds(uint256 bookingIndex)
        public
    {
        /// Check if funds haven't been released
        require(false == bookings[bookingIndex].released, "RELEASED");

        /// Check if cancellation periods passed
        require(bookings[bookingIndex].fullRefundUntil < block.timestamp, "NOT_YET");
        require(bookings[bookingIndex].halfRefundUntil < block.timestamp, "NOT_YET");

        /// Inject funds into Swix ecosystem
        _injectFunds(bookings[bookingIndex], bookings[bookingIndex].bookingPrice, true);

        /// Mark booking funds as released
        bookings[bookingIndex].released = true;

        /// Emit event
        emit ReleaseFunds(bookingIndex);
    }

    /// Claim tokenback for active booking
    /// Can only be done by account which made the booking
    /// Will zero out cancellation periods
    ///
    /// @param bookingIndex index of the booking in `bookings` array
    function claimTokenback(uint256 bookingIndex)
        external
    {
        /// Check if sender is authorized to cancel booking
        require(msg.sender == bookings[bookingIndex].user);
        /// Check if funds haven't been released
        require(false == bookings[bookingIndex].released, "RELEASED");

        /// Zero out cancellation deadlines, booking price will not be refunded after tokenback
        if (bookings[bookingIndex].fullRefundUntil > 0) {
            bookings[bookingIndex].fullRefundUntil = 0;
        }
        if (bookings[bookingIndex].halfRefundUntil > 0) {
            bookings[bookingIndex].halfRefundUntil = 0;
        }

        /// Distribute funds into Swix ecosystem
        _injectFunds(bookings[bookingIndex], bookings[bookingIndex].bookingPrice, true);

        /// Mark booking funds as released
        bookings[bookingIndex].released = true;

        emit ClaimTokenback(bookingIndex);
    }

    // TODO: add cleanup function for bookings which have already passed

    /* =====================================================
                    BOOKING MASTER FUNCTIONS
    ===================================================== */

    /// Reject booking
    ///
    /// @param bookingIndex index of the booking in `bookings` array
    function reject(uint256 bookingIndex) 
        external
        nonReentrant
        onlyBookingMaster
    {
        /// Get booking by index
        Booking memory booking = bookings[bookingIndex];
                
        /// Delete cancelled booking and update booking array
        _deleteBooking(bookingIndex);

        /// Update avaiability and send nights tokens back to City
        _refundNights(booking);

        /// If booking funds have been released already
        if (booking.released == true) {
            /// Refund booking from refund wallet
            stablecoin.safeTransferFrom(
                refundWallet,
                booking.user,
                booking.bookingPrice
            );
        }
        else {
            /// Otherwise send funds back to user from this contract
            stablecoin.safeTransfer(
                booking.user,
                booking.bookingPrice
            );
        }

        emit Reject(bookingIndex);
    }


    /* =====================================================
                    COST MANAGER FUNCTIONS
    ===================================================== */

    /// This function will add global cost to the BookingManager
    ///
    /// @param addedCost cost to be added to global costs
    function addGlobalCosts(uint256 addedCost)
        external
        onlyCostManager
    {
        globalCosts += addedCost;
    }

    /// This function will subtract global cost to the BookingManager
    ///
    /// @param subtractedCost cost to be subtracted from global costs
    function subtractGlobalCosts(uint256 subtractedCost)
        external
        onlyCostManager
    {
        globalCosts -= subtractedCost;
    }


    /* =====================================================
                        INTERNAL FUNCTIONS
    ===================================================== */

    /// This function will inject funds into Swix ecosystem
    /// Funds will be split between tokenback, dao and expenseWallet according to the defined rates
    ///
    /// @param booking      booking located in `bookings`
    /// @param revenue      revenue to inject
    /// @param tokenback    whether tokenback is eligible for this booking
    function _injectFunds(Booking memory booking, uint256 revenue, bool tokenback)
        internal
    {
        /// Define a struct to store profit parameters of lease relevant to the booking
        FinancialParams memory params;
        uint256 daoProfit;
        /// Get global costs
        params.globalCosts = globalCosts;
        
        /// Get profit parameters from City
        (
            params.cityCosts,
            params.hurdleRate,
            params.daoProfitRate,
            params.target,
            params.profit
        ) = booking.city.getFinancialParams(booking.leaseIndex);

        /// If tokenback is applicable
        if (tokenback) {
            /// Calculate tokenback amount
            uint256 tokenbackAmount = revenue * booking.tokenbackRate /ONE_HUNDRED_PERCENT;
            /// Subtract tokenback amount from revenue
            revenue -= tokenbackAmount;

            stablecoin.safeIncreaseAllowance(address(tokenbackWallet), tokenbackAmount);

            tokenbackWallet.tokenback(booking.user, tokenbackAmount);
        }
        
        /// Get `params` updated by the calculator
        (params, daoProfit) = calculator.getProfitRates(params, revenue);
        
        /// Update global costs
        globalCosts = params.globalCosts;
        /// Update cityCosts and Lease profit in City
        booking.city.updateFinancials(booking.leaseIndex, params.cityCosts, params.profit);

        /// Transfer tokenback to user
        stablecoin.safeTransfer(
            expenseWallet,
            revenue - daoProfit
        );

        /// Transfer tokenback to user
        stablecoin.safeTransfer(
            dao,
            daoProfit
        );        
    }

    /// Create an array filled with 1s
    ///
    /// @param length length of array produced     
     function _arrayOfOnes(uint256 length)
        internal
        pure
        returns (uint256[] memory balances)
    {
        balances = new uint256[](length);

        /// Populate balances array with 1
        for (uint256 i = 0; i<length; i++) {
            balances[i] = 1;
        }
    }

    /// Get the requested nights from Lease in chosen City
    ///
    /// @param city         address of chosen City
    /// @param leaseIndex   leaseIndex in the `leases` array
    /// @param nights       array of nights to book
    function _getNights(
        ISwixCity city,
        uint256 leaseIndex,
        uint256[] memory nights
    )
        internal
    {
        // Update availbility on City
        city.updateAvailability(
            leaseIndex,
            nights,
            false
        );

        // Transfer nights to this address
        city.getLease(leaseIndex).leaseContract.safeBatchTransferFrom(
            address(city),
            address(this),
            nights,
            _arrayOfOnes(nights.length),
            ""
        );
    }

    /// Function to send the night tokens back to the SwixCity
    ///
    /// @param booking booking located in `bookings`
    function _refundNights(
        Booking memory booking
    )
        internal
        returns (uint256[] memory nights)
    {
        /// Create empty array for nights
        uint256 window = booking.end - booking.start + 1;
        nights = new uint256[](window);

        /// Populate the array with nights from refunded booking
        for (uint256 i = 0; i < window; i++) {
            nights[i] = booking.start + i;
        }

        /// Update availbility on City
        booking.city.updateAvailability(
            booking.leaseIndex,
            nights,
            true
        );

        /// Transfer nights to City
        booking.city.getLease(booking.leaseIndex).leaseContract.safeBatchTransferFrom(
            address(this),
            address(booking.city),
            nights,
            _arrayOfOnes(nights.length),
            ""
        );
    }


    /// Refund bookingPrice back to user based on the eligiblity of full or half refund
    ///
    /// @param fullRefundUntil  timestamp before fullRefund expires
    /// @param halfRefundUntil  timestamp before halfRefund expires
    /// @param price            price of the booking
    ///
    /// @return                 amount passed to DAO after refund
    function _refund(
        uint256 fullRefundUntil,
        uint256 halfRefundUntil,
        uint256 price
    )
        internal
        returns (uint256)
    {        
        /// Check if user is elligable for full refund
        if (fullRefundUntil > block.timestamp) {
            // Transfer full price of booking back to user
            stablecoin.safeTransfer(
                msg.sender,
                price
            );

            return 0;
        }
        /// If not, check if user is elligable for 50% refund
        else if (halfRefundUntil > block.timestamp) {
            // Transfer half of price to user (rounded up)
            stablecoin.safeTransfer(
                msg.sender,
                (price / 2) + (price % 2)
            );

            /// Return half of price rounded down
            return price / 2;
        }

        /// Return full price as user was not elligable for refund
        return price;
    }

    /// Delete a booking from the `bookings` array
    /// If deleted booking is not the most recent one `bookingIndexes` will be updated as well
    ///
    /// @param bookingIndex bookingIndex in the `bookings` array
    function _deleteBooking(uint256 bookingIndex) internal {
        /// Swap last element of booking index to index of cancelled booking
        bookings[bookingIndex] = bookings[bookings.length - 1];

        /// Update bookingIndexes mapping after the swap
        bookingIndexes
            [bookings[bookingIndex].city]
            [bookings[bookingIndex].leaseIndex]
            [bookings[bookingIndex].start]
            .index
            = bookingIndex;

        /// Delete last booking
        delete bookings[bookings.length - 1];
        // pop the last element to update the length
        bookings.pop();
    }


    /* =====================================================
                        VIEW FUNCTIONS
    ===================================================== */

    /// Get bookingIndex from `bookingIndexes` mapping based on its unique characteristics
    ///
    /// @param city         City contract
    /// @param leaseIndex   leaseIndex in the `leases` array
    /// @param startNight   index of first night of booking
    function getBookingIndex(
        ISwixCity city,
        uint256 leaseIndex,
        uint256 startNight        
    )
        public
        view
        returns (uint256)
    {
        require(bookingIndexes[city][leaseIndex][startNight].exists, "NOT_FOUND");

        uint256 index = bookingIndexes[city][leaseIndex][startNight].index;
        return index;
    }

    /// Return length of bookings
    function getBookingsLength()
        public
        view
        returns (uint256)
    {
        return bookings.length;
    }

    /* =====================================================
                        ERC1155Receiver
    ===================================================== */

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }


    /* =====================================================
                    CHAINLINK KEEPER INTGRATION
    ===================================================== */

    /// Verifies if there is a booking that is ready for releasing fund
    /// Returns index of first found booking as data for performUpkeep
    ///
    /// @return upkeepNeeded    marks if upkeep is necessary
    /// @return performData   bookingIndex passed as data to `performUpkeep`
    function checkUpkeep(bytes calldata /* checkData */)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        /// Check if there are bookings in contract
        require(bookings.length > 0, "NO_BOOKINGS");
    
        /// Check funds release conditions for each booking
        for (uint256 i = 0; i < bookings.length; i++) {
            if (
                /// If full refund deadline has passed...
                bookings[i].fullRefundUntil < block.timestamp
                /// and half refund deadline has passed...
                && bookings[i].halfRefundUntil < block.timestamp
                /// and funds haven't been released yet
                && false == bookings[i].released
            ) {
                /// Encode current booking index and pass as data to `performUpkeep`
                performData = abi.encodePacked(i);
                /// Mark upkeep as needed
                upkeepNeeded = true;

                return (upkeepNeeded, performData);
            }
        }
    }

    /// Releases funds of a booking where refund dates have passed
    ///
    /// @param performData bookingIndex of a booking to be released encoded as `bytes`
    function performUpkeep(bytes calldata performData)
        external
        override
    {
        /// Get bookingIndex for booking which needs releasing of funds
        uint256 bookingIndex = abi.decode(performData, (uint256));
        /// Release funds
        /// Upkeep revalidation is performed in `releaseFunds`
        releaseFunds(bookingIndex);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ILeaseStructs.sol";

interface ISwixCity is ILeaseStructs {

    function getLease(uint256 leaseIndex) external view returns(Lease memory);
    function addLease( ILeaseAgreement leaseContract, uint256 target, uint256 tokenbackRate, bool[] calldata cancelPolicies) external;
    function updateAvailability( uint256 leaseIndex, uint256[] memory nights, bool available) external;
    function updateFinancials(uint256 leaseIndex, uint256 newCost, uint256 newProfit) external;
    function getPriceOfStay(uint256 leaseIndex, uint256[] memory nights) external view returns (uint256);
    function getFinancialParams(uint256 leaseIndex) external view returns ( uint256, uint256, uint256, uint256, uint256);

    /* =====================================================
                            EVENTS
    ===================================================== */

    event AddLease(address indexed leaseContract, uint256 indexed newLeaseIndex);
    event UpdateNights(address indexed leaseContract, uint256[] nights);
    event UpdateCancelPolicy(uint256 indexed leaseIndex, uint256 cancelPolicy, bool allow);
    event UpdatedPriceManager(address indexed newPriceManager);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./IIndex.sol";
import "./IBooking.sol";
import "./ISwixCity.sol";

interface IBookingManager is
    IBooking,
    IIndex
{
    function book(
        ISwixCity city,
        uint256 leaseIndex,
        uint256[] memory nights,
        uint256 cancelPolicy
    ) external;
    function cancel(uint256 bookingIndex) external;
    function claimTokenback(uint256 bookingIndex) external;
    function getBookingIndex(ISwixCity city, uint256 leaseIndex, uint256 startNight) external returns (uint256);

    /* =====================================================
                          EVENTS
    ===================================================== */
    
    event Book(
        uint256 indexed bookingIndex,
        address city,
        uint256 leaseIndex,
        uint256 startNight
    );
    event Cancel(uint256 indexed bookingIndex);
    event Reject(uint256 indexed bookingIndex);
    event ClaimTokenback(uint256 indexed bookingIndex);
    event ReleaseFunds(uint256 indexed bookingIndex);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;
interface IFinancialParams {
    struct FinancialParams {
        /// global operation cost to be collected before spliting profit to DAO
        uint256 globalCosts;
        /// cityCosts to be collected before spliting profit to DAO
        uint256 cityCosts;
        /// final rate for spliting profit once profit of a lease reaches target
        uint256 hurdleRate;
        /// current rate for spliting profit
        uint256 daoProfitRate;
        /// target profit for each lease
        uint256 target;
        /// accumulative profit for each lease
        uint256 profit;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

interface ICancelPolicyManager {

    function getCancelTimes(uint256 policyIndex, uint256 start)
        external
        returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./IFinancialParams.sol";

interface IRevenueSplitCalculator is IFinancialParams {


    function getProfitRates(FinancialParams memory params, uint256 amount) external returns (FinancialParams memory, uint256 );

}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "../interfaces/ISWIX.sol";
import "../interfaces/ITokenback.sol";
import "../interfaces/ISwixEcosystem.sol";
import "../interfaces/IBookingManager.sol";
import "../interfaces/ICancelPolicyManager.sol";
import "../interfaces/IRevenueSplitCalculator.sol";

import "../abstracts/SwixRoles.sol";

abstract contract SwixContract is
    SwixRoles
{
    
    /* =====================================================
                        STATE VARIABLES
     ===================================================== */

    /// Stores address of current Ecosystem
    ISwixEcosystem public ecosystem;

    /// Marks if the contract has been initialized
    bool public initialized;
    /// Timestamp when the ecosystem addreses were updated last time
    uint256 public lastUpdated;


    /* =====================================================
                      CONTRACT MODIFIERS
     ===================================================== */

    modifier onlySwix() {
        ecosystem.checkRole(SWIX_TOKEN_CONTRACT, msg.sender);
        _;
    }

    modifier onlyLeaseAgreement() {
        ecosystem.checkRole(LEASE_AGREEMENT_CONTRACT, msg.sender);
        _;
    }

    modifier onlyCity() {
        ecosystem.checkRole(CITY_CONTRACT, msg.sender);
        _;
    }

    modifier onlyBookingManager() {
        ecosystem.checkRole(BOOKING_MANAGER_CONTRACT, msg.sender);
        _;
    }

    modifier onlyCancelPolicy() {
        ecosystem.checkRole(CANCEL_POLICY_CONTRACT, msg.sender);
        _;
    }

    modifier onlyRevenueSplit() {
        ecosystem.checkRole(REVENUE_SPLIT_CONTRACT, msg.sender);
        _;
    }

    modifier onlyTokenback() {
        ecosystem.checkRole(TOKENBACK_CONTRACT, msg.sender);
        _;
    }

    /* =====================================================
                        ROLE MODIFIERS
     ===================================================== */

    modifier onlyGovernance() {
        ecosystem.checkRole(GOVERNANCE_ROLE, msg.sender);
        _;
    }

    modifier onlyLeaseManager() {
        ecosystem.checkRole(LEASE_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyLeasePolicy() {
        ecosystem.checkRole(LEASE_POLICY_ROLE, msg.sender);
        _;
    }

    modifier onlyCostManager() {
        ecosystem.checkRole(COST_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyCancelPolicyManager() {
        ecosystem.checkRole(CANCEL_POLICY_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyContractManager() {
        ecosystem.checkRole(CONTRACT_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyBookingMaster() {
        ecosystem.checkRole(BOOKING_MASTER_ROLE, msg.sender);
        _;
    }

    modifier onlyGovernanceOrContractManager() {
        require(ecosystem.hasRole(GOVERNANCE_ROLE, msg.sender) || ecosystem.hasRole(CONTRACT_MANAGER_ROLE, msg.sender));
        _;
    }

    modifier ecosystemInitialized() {
        require(ecosystem.ecosystemInitialized());
        _;
    }
    

    /* =====================================================
                        CONSTRUCTOR
     ===================================================== */

    constructor(ISwixEcosystem setSwixEcosystem) {
        ecosystem = setSwixEcosystem.currentEcosystem();
        emit EcosystemUpdated(ecosystem);
    }


    /* =====================================================
                        GOVERNOR FUNCTIONS
     ===================================================== */

    function updateEcosystem()
        external
        onlyContractManager
    {
        ecosystem = ecosystem.currentEcosystem();
        require(ecosystem.ecosystemInitialized());

        lastUpdated = block.timestamp;

        emit EcosystemUpdated(ecosystem);
    }

    
    /* =====================================================
                        VIEW FUNCTIONS
    ===================================================== */

    /// Return currently used SwixToken contract
    function _swixToken()
        internal
        view
        returns (ISWIX)
    {
        return ISWIX(ecosystem.getRoleMember(SWIX_TOKEN_CONTRACT, 0));
    }

    /// Return currently used DAI contract
    function _stablecoinToken()
        internal
        view
        returns (IERC20)
    {
        return IERC20(ecosystem.getRoleMember(STABLECOIN_TOKEN_CONTRACT, 0));
    }

    /// Return BookingManager contract
    function _bookingManager()
        internal
        view
        returns (IBookingManager)
    {
        return IBookingManager(ecosystem.getRoleMember(BOOKING_MANAGER_CONTRACT, 0));
    }
    
    /// Return currently used CancelPolicyManager contract
    function _cancelPolicyManager()
        internal
        view
        returns (ICancelPolicyManager)
    {
        return ICancelPolicyManager(ecosystem.getRoleMember(CANCEL_POLICY_CONTRACT, 0));
    }


    /// Return currently used RevenueSplitCalculator contract
    function _revenueSplitCalculator()
        internal
        view
        returns (IRevenueSplitCalculator)
    {
        return IRevenueSplitCalculator(ecosystem.getRoleMember(REVENUE_SPLIT_CONTRACT, 0));
    }
    
    /// return tokenback contract
    function _tokenback()
        internal
        view
        returns (ITokenback)
    {
        return ITokenback(ecosystem.getRoleMember(TOKENBACK_CONTRACT, 0));
    }

    /// return DAO address
    function _dao()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(DAO_ROLE, 0);
    }

    /// return expenseWallet address
    function _expenseWallet()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(EXPENSE_WALLET_ROLE, 0);
    }

    /// return expenseWallet address
    function _refundWallet()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(REFUND_WALLET_ROLE, 0);
    }


    /* =====================================================
                            EVENTS
     ===================================================== */

    event EcosystemUpdated(ISwixEcosystem indexed ecosystem);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ILeaseAgreement.sol";
import "./IIndex.sol";

interface ILeaseStructs is IIndex {
    struct Lease {
        /// unique identifier for the Lease and it's contract address
        ILeaseAgreement leaseContract;
        /// Current tokenback rate given to guests on purchase
        uint256 tokenbackRate;
        /// Target profit for the Lease, adjusted by hurdleRate
        uint256 target;
        /// Profit earned on the Lease
        uint256 profit;
        /// Available cancellation policies for this lease
        bool[] cancelPolicies;
    }

    struct Night {
        /// Price of a night in US dollars
        uint256 price;
        /// Setting to 'true' will publish the night for booking and update availability
        bool available;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

/// ERC1155 token representation of a booking; used to confirm at LeaseManager when burnt.
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
interface ILeaseAgreement is IERC1155 {
    function START_TIMESTAMP() external view returns (uint256);
    function swixCity() external view returns (address);
    function duration() external view returns (uint256);
    
    function initialize() external;

    event LeaveCity(address oldSwixCity);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

interface IIndex {

    struct Index {
        uint256 index;
        bool exists;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ISwixCity.sol";
import "./IIndex.sol";
interface IBooking {
    struct Booking {
        /// Contract of city in which the booking takes place
        ISwixCity city;
        /// Index of Lease in the chosen City
        uint256 leaseIndex;
        /// Start night number
        uint256 start;
        /// End night number
        uint256 end;
        /// Timestamp until which user will get full refund on cancellation
        uint256 fullRefundUntil;
        /// Timestamp until which user will get 50% refund on cancellation
        uint256 halfRefundUntil;
        /// Total price of booking
        uint256 bookingPrice;
        /// Percentage rate of tokenback, 100 = 1%
        uint256 tokenbackRate;
        /// User's address
        address user;
        /// Marker if funds were released from booking
        bool released;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISWIX is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

interface ITokenback {
    function tokenback(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
interface ISwixEcosystem is IAccessControlEnumerable {

    function currentEcosystem() external returns (ISwixEcosystem);
    function initialize() external;
    function ecosystemInitialized() external returns (bool);
    function updateGovernance(address newGovernance) external;
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function checkRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

abstract contract SwixRoles {
    /* =====================================================
                            CONTRACTS
     ===================================================== */
    /// All contracts within Swix Ecosystem are tracked here
    
    /// SWIX Token contract
    bytes32 constant public SWIX_TOKEN_CONTRACT         = keccak256("SWIX_TOKEN_CONTRACT");
    /// DAI Token contract
    bytes32 constant public STABLECOIN_TOKEN_CONTRACT   = keccak256("STABLECOIN_TOKEN_CONTRACT");

    /// Booking Manager. This contract is responsible for reserving, storing and cancelling bookings.
    bytes32 constant public BOOKING_MANAGER_CONTRACT    = keccak256("BOOKING_MANAGER_CONTRACT");
    /// Swix City. Each contract represents a city in which Swix is operating as a Real World Business.
    bytes32 constant public CITY_CONTRACT               = keccak256("CITY_CONTRACT");
    /// Lease Agreements. Each contract represents a property.
    bytes32 constant public LEASE_AGREEMENT_CONTRACT    = keccak256("LEASE_AGREEMENT_CONTRACT");

    /// Cancellation Policy. This contract calculates refund deadlines based on given policy parameters.
    bytes32 constant public CANCEL_POLICY_CONTRACT      = keccak256("CANCEL_POLICY_CONTRACT");
    /// Revenue Split Calculator. This contract directs the split of revenue throughout Swix Ecosystem.
    bytes32 constant public REVENUE_SPLIT_CONTRACT      = keccak256("REVENUE_SPLIT_CONTRACT");

    /// Simplified implementation of SWIX tokenback. During MVP test will have rights to mint SWIX tokens.
    bytes32 constant public TOKENBACK_CONTRACT          = keccak256("TOKENBACK_CONTRACT");


    /* =====================================================
                              ROLES
     ===================================================== */
    /// All roles within Swix Ecosystem are tracked here

    /// Community Governance. This is the most powerful role and represents the voice of the community.
    bytes32 constant public GOVERNANCE_ROLE             = keccak256("GOVERNANCE_ROLE");

    /// Lease Manager. This role is responsible for deploying new Leases and adding them to a corresponding city.
    bytes32 constant public LEASE_MANAGER_ROLE          = keccak256("LEASE_MANAGER_ROLE");
    /// Lease Policy Counseal. This role is responsible for setting and adjusting rates related to Real World Business.
    bytes32 constant public LEASE_POLICY_ROLE           = keccak256("LEASE_POLICY_ROLE");

    /// Cost Manager. This role is responsible for adding global and city costs.
    bytes32 constant public COST_MANAGER_ROLE           = keccak256("COST_MANAGER_ROLE");

    /// Cancellation Policy Manager. This role is responsible for adding and removing cancellation policies.
    bytes32 constant public CANCEL_POLICY_MANAGER_ROLE  = keccak256("CANCEL_POLICY_MANAGER_ROLE");

    /// Contract Manager. This role is responsible for adding and removing contracts from Swix Ecosystem.
    bytes32 constant public CONTRACT_MANAGER_ROLE       = keccak256("CONTRACT_MANAGER_ROLE");

    /// DAO Reserves. This account will receive all profit going to DAO
    bytes32 constant public DAO_ROLE                    = keccak256("DAO_ROLE");

    /// Expense Wallet. This account will receive all funds going to Real World Business
    bytes32 constant public EXPENSE_WALLET_ROLE         = keccak256("EXPENSE_WALLET_ROLE");

    /// Booking Master. This account will be handling booking rejections
    bytes32 constant public BOOKING_MASTER_ROLE         = keccak256("BOOKING_MASTER_ROLE");

    /// Booking Master. This account will be funding booking rejections
    bytes32 constant public REFUND_WALLET_ROLE         = keccak256("REFUND_WALLET_ROLE");
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

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