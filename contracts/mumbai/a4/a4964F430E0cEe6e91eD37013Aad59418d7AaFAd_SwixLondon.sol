// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "../SwixCity.sol";

contract SwixLondon is SwixCity {
    constructor(
        ISwixEcosystem setEcosystem,
        address setPriceManager
    )
        SwixCity(
            "LON",
            setEcosystem,
            setPriceManager
        )
    {}
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "./interfaces/ISwixCity.sol";
import "./interfaces/ILeaseAgreement.sol";
import "./interfaces/IFinancialParams.sol";

import "./abstracts/SwixContract.sol";

/// SwixCity holds individual night tokens and allows pricing them and toggling availability.
contract SwixCity is
    ISwixCity,
    SwixContract,
    ERC1155Receiver,
    ReentrancyGuard
{
    /* =====================================================
                            IMMUTABLE
    ===================================================== */

    /// 3 letter code used to identify this City
    string public cityCode;
    
    /* =====================================================
                        STATE VARIABLES
    ===================================================== */

    /// BookingManager contract address
    address bookingManager;
    
    /// Price Manager. This role is granted on a per city basis
    /// Responsible for setting and changing prices and availability for nights
    address public priceManager;

    /// Basis percentage rate to calculate share of revenue that goes to SwixDAO
    ///  Pictured as percentage rate — 100 = 1%
    uint256 public daoProfitRate = 10_000;
    /// Percentage rate used to calculate remaining hurdle target
    uint256 public hurdleRate = 10_000;
    /// Represents ongoing costs of property rental, maintenance, cleaning, etc.
    /// After covering city cost Swix Treasury will start receiving share of revenue
    /// Represented in US Dollars
    uint256 public cityCosts;

    
    /// Mapping used to indentify indexes for Leases and ensure uniqueness
    mapping(ILeaseAgreement => LeaseIndex) public leaseIndexes;

    /// Array used to store all LeaseParameters
    Lease[] public leases;
    /// Mappping of nights for each Lease
    /// (leaseIndex => Night[])
    mapping(uint256 => Night[]) public nightInfo;


    /* =====================================================
                          MODIFIERS
    ===================================================== */

    modifier onlyPriceManager() {
        require(msg.sender == priceManager, "UNAUTHORISED");
        _;
    }


    /* =====================================================
                        CONSTRUCTOR
    ===================================================== */

    /// @param setCityCode      3 letter code used to identify this City
    /// @param setEcosystem     address of Ecosystem contract
    /// @param setPriceManager  priceManager of this City
    constructor(
        string memory   setCityCode,
        ISwixEcosystem  setEcosystem,
        address         setPriceManager
    )
        SwixContract(setEcosystem)
    {
        cityCode        = setCityCode;
        priceManager    = setPriceManager;
    }
    
    /* =====================================================
                    CONTRACT MANAGER FUNCTIONS
    ===================================================== */
    
    /// Initialize contract
    /// Set the initialized to true and mark update timestamp
    function initialize()
        public
        nonReentrant
        ecosystemInitialized
        onlyContractManager
    {
        bookingManager = address(_bookingManager());
    }

    /// Update state variables from SwixEcosystem
    function update()
        public
        nonReentrant
        ecosystemInitialized
        onlyContractManager
    {
        /// For each Lease in City
        for (uint256 i = 0; i < leases.length; i++) {
            /// Block old BookingManager from making more bookings by setting the Lease tokens approval to false
            leases[i].leaseContract.setApprovalForAll(bookingManager, false);
            /// Allow new BookingManager to use City's Lease tokens
            leases[i].leaseContract.setApprovalForAll(address(_bookingManager()), true);
        }
        
        /// Update BookingManager address
        bookingManager = address(_bookingManager());
    }


    /* =====================================================
                    LEASE MANAGER FUNCTIONS
    ===================================================== */

    /// Add new Lease to `leases` array
    ///
    /// @param target           target profit
    /// @param tokenbackRate    percentage of booking price that will back tokenback
    /// @param cancelPolicies   allowences for Cancellation Policies
    function addLease(
        ILeaseAgreement leaseContract,
        uint256         target,
        uint256         tokenbackRate,
        bool[] calldata cancelPolicies
    )
        external
        nonReentrant
        onlyLeaseManager
    {
        /// Check if added contract is acknowledged in Ecosystem
        require(ecosystem.hasRole(LEASE_AGREEMENT_CONTRACT, address(leaseContract)), "NOT_LEASE");
        /// Check if Lease has already been added
        require(false == leaseIndexes[leaseContract].exists, "EXISTS");

        /// Get index of a new Lease
        uint256 newLeaseIndex = leases.length;

        leases.push(Lease(
            leaseContract,
            tokenbackRate,
            target,
            0,
            cancelPolicies
        ));

        /// Set leaseIndex in the mapping
        leaseIndexes[leaseContract].index = newLeaseIndex;
        leaseIndexes[leaseContract].exists = true;

        /// Call underlying Lease to mint nights tokens to City
        leaseContract.initialize();

        /// Give full approval to use City's ERC1155 tokens to BookingManeger
        leaseContract.setApprovalForAll(address(_bookingManager()), true);

        /// Emit event
        emit AddLease(address(leaseContract), newLeaseIndex);
    }

    /// Update PriceManager for this City
    ///
    /// @param newPriceManager - the new PriceManger
    function updatePriceManager(address newPriceManager)
        external
        nonReentrant
        onlyLeaseManager
    {
        priceManager = newPriceManager;

        /// Emit event
        emit UpdatedPriceManager(newPriceManager);
    }


    /* =====================================================
                    PRICE MANAGER FUNCTIONS
    ===================================================== */

    /// Set prices and availability for chosen nights
    ///
    /// @param leaseIndex       leaseIndex in the `leases` array
    /// @param nights           nights to update
    /// @param prices           prices of each night
    /// @param availabilities   availability of each night
    function setPrices(
        uint256             leaseIndex,
        uint256[] calldata  nights,
        uint256[] calldata  prices,
        bool[] calldata     availabilities
    )
        external
        nonReentrant
        onlyPriceManager
    {
        /// Get current Lease
        Lease storage lease = leases[leaseIndex];

        /// Get Lease start timestamp
        uint256 startTimestamp = lease.leaseContract.START_TIMESTAMP();
        /// Define counter
        uint256 i;

        /// For each night check if LeaseHouse has the corresponding token
        for (i = 0; i < nights.length; i++) {
            /// Check if night is in the future
            require(startTimestamp + 1 days * nights[i] > block.timestamp, "PASSED");
            /// Check if City is the owner of chosen night
            require(lease.leaseContract.balanceOf(address(this), nights[i]) == 1, "NOT_CITY_OWNED");
        }

        // For each of the nights
        for (i = 0; i < nights.length; i++) {
            // Set price in City
            _setPrice(
                leaseIndex,
                nights[i],
                prices[i],
                availabilities[i]
            );
        }

        emit UpdateNights(address(lease.leaseContract), nights, prices, availabilities);
    }

    /// Update cancellation policy allowance for Lease
    ///
    /// @param leaseIndex       index of Lease in `leases` array
    /// @param cancelPolicy     index of cancellation policy to update
    /// @param allow            allow/ban chosen cancellation policy
    function setCancelPolicy(
        uint256 leaseIndex,
        uint256 cancelPolicy,
        bool    allow
    )
        external
        nonReentrant
        onlyPriceManager
    {
        /// Update policy status
        leases[leaseIndex].cancelPolicies[cancelPolicy] = allow;

        /// Emit event
        emit UpdateCancelPolicy(leaseIndex, cancelPolicy, allow);
    }

     /// Update availability for nights specfiied
     /// Used only by BookingManager when creating / cancelling bookings
     ///
     /// @param leaseIndex  index of Lease in `leases` array
     /// @param nights      nights to update
     /// @param available   availability of each night
    function updateAvailability(
        uint256             leaseIndex,
        uint256[] memory    nights,
        bool                available
    )
        external
        nonReentrant
        onlyBookingManager
    {
        /// Update availability of each night
        for (uint256 i = 0; i < nights.length; i++) {
            nightInfo[leaseIndex][nights[i]].available = available;
        }
    }


    /* =====================================================
                    COST MANAGER FUNCTIONS
    ===================================================== */

    /// Add costs on a City level
    ///
    /// @param addedCost cost to be added on cityCost
    function addCityCosts(uint256 addedCost)
        external
        nonReentrant
        onlyCostManager
    {
        cityCosts += addedCost;
    }

    /// Subtract costs on a City level
    ///
    /// @param subtractedCost cost to be subtracted from cityCost
    function subtractCityCosts(uint256 subtractedCost)
        external
        onlyCostManager
    {
        /// Underflow protection
        if (cityCosts < subtractedCost) {
            cityCosts = 0;
        }
        else {
            cityCosts -= subtractedCost;
        }
    }


    /* =====================================================
                    LEASE POLICY FUNCTIONS
    ===================================================== */

    /// Update HurdleRate
    ///
    /// @param newHurdleRate adjusted HurdleRate (percentage rate, 100 = 1%)
    function changeHurdleRate(uint256 newHurdleRate)
        external
        nonReentrant
        onlyLeasePolicy
    {
        hurdleRate = newHurdleRate;
    }

    /// Update DaoProfitRate
    ///
    /// @param newDaoProfitRate adjusted DaoProfitRate (percentage rate, 100 = 1%)
    function changeDaoProfitRate(uint256 newDaoProfitRate)
        external
        nonReentrant
        onlyLeasePolicy
    {
        daoProfitRate = newDaoProfitRate;
    }

    /// Update target for particular Lease
    ///
    /// @param leaseIndex   index of Lease in `leases` array
    /// @param newTarget    new target value (in wei)
    function changeTarget(uint256 leaseIndex, uint256 newTarget)
        external
        nonReentrant
        onlyLeasePolicy
    {
        leases[leaseIndex].target = newTarget;
    }


    /* =====================================================
                    BOOKING MANAGER FUNCTIONS
    ===================================================== */

    /// Update profit for a Lease and cityCosts 
    /// Called by BookingManager when funds are injected into Swix ecosystem
    ///
    /// @param leaseIndex   index of Lease in `leases` array
    /// @param costs        updated costs value
    /// @param profit       updated profit value
    function updateFinancials(
        uint256 leaseIndex,
        uint256 costs,
        uint256 profit
    )
        external
        nonReentrant
        onlyBookingManager
    {
        cityCosts = costs;
        leases[leaseIndex].profit = profit;
    }


    /* =====================================================
                        VIEW FUNCTIONS
    ===================================================== */

    /// Get Financial parameters for a particular Lease
    ///
    /// @param leaseIndex       index of Lease in `leases` array
    ///
    /// @return cityCost        costs on City level
    /// @return hurdleRate      Hurdle Rate on City level
    /// @return daoProfitRate   Dao Profit Rate on City level    
    /// @return target          target for particular Lease
    /// @return profit          profit for particular Lease
    function getFinancialParams(uint256 leaseIndex)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            cityCosts,
            hurdleRate,
            daoProfitRate,
            leases[leaseIndex].target,
            leases[leaseIndex].profit
        );
    }

    /// Get price for a set of nights
    ///
    /// @param leaseIndex   index of Lease in `leases` array
    /// @param nights       nights to aggregate price for
    ///
    /// @return price       total price
    function getPriceOfStay(uint256 leaseIndex, uint256[] memory nights)
        external
        view
        returns (uint256 price)
    {
        /// Preset return variables
        price = 0;

        /// For each night in nights input array    
        for (uint256 i = 0; i < nights.length; i++) {
            /// Check if the night is not available
            require(nightInfo[leaseIndex][nights[i]].available, "UNAVAILABLE");

            /// If the night is available add it's price to the total price
            price += nightInfo[leaseIndex][nights[i]].price;
        }
    }

    /// Get lease
    ///
    /// @param leaseIndex   index of Lease in `leases` array
    ///
    /// @return Lease       Lease struct of chosen Lease
    function getLease(uint256 leaseIndex)
        external
        view
        returns (Lease memory)
    {
        return leases[leaseIndex];
    }

    /// Get amount of Leases in this City
    ///
    /// @return uint256     amount of Leases in `leases` array
    function getLeasesAmount()
        external
        view
        returns (uint256)
    {
        return leases.length;
    }

    /// Get amount of nights priced for a particular Lease
    ///
    /// @param leaseIndex   index of Lease in `leases` array
    ///
    /// @return uint256     amount of nights in `nightInfo[leaseIndex]` array
    function getNightsAmount(uint256 leaseIndex)
        external
        view
        returns (uint256)
    {
        return nightInfo[leaseIndex].length;
    }


    /* =====================================================
                        INTERNAL FUNCTIONS
    ===================================================== */

    /// Set price and availability for a particular night
    ///
    /// @param leaseIndex   index of Lease in `leases` array
    /// @param night        chosen night index 
    /// @param price        price to be set for night
    /// @param availability availability to be set for night
    ///
    /// @return uint256     night index
    /// @return uint256     set price
    /// @return bool        set availability
    function _setPrice(
        uint256 leaseIndex,
        uint256 night,
        uint256 price,
        bool    availability
    )
        internal
        returns (uint256, uint256, bool)
    {
        /// If nights array is not long enough to push added price
        if (nightInfo[leaseIndex].length < night) {
            /// Push not-priced, unavailable nights to fill the array
            for (uint256 i = nightInfo[leaseIndex].length; i < night; i++) {
                nightInfo[leaseIndex].push(Night(
                    0,
                    false
                ));
            }
        }
        
        /// If the night added is the next new night in array
        if (nightInfo[leaseIndex].length == night) {
            /// Push new price and availability
            nightInfo[leaseIndex].push(Night(
                price,
                availability
            ));
        }
        /// If the night added already exists in array
        else {
            /// Update price and availability info
            nightInfo[leaseIndex][night] = Night(
                price,
                availability
            );
        }

        return (night, price, availability);
    }

    /* =====================================================
                        ERC1155RECEIVER FUNCTIONS
    ===================================================== */
    
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
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
    event UpdateNights(address indexed leaseContract, uint256[] indexed nights, uint256[] indexed prices, bool[] availabilities);
    event UpdateCancelPolicy(uint256 indexed leaseIndex, uint256 cancelPolicy, bool allow);
    event UpdateAvailability(uint256 indexed leaseIndex, uint256[] indexed nights, bool indexed available);
    // TODO change to capital letter in the beginning
    event UpdatedPriceManager(address indexed newPriceManager);
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

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ILeaseAgreement.sol";

interface ILeaseStructs {
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

    struct LeaseIndex {
        uint256 index;
        bool exists;
    }

    struct Night {
        /// Price of a night in US dollars
        uint256 price;
        /// Setting to 'true' will publish the night for booking and update availability
        bool available;
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

import "./IBooking.sol";
import "./ISwixCity.sol";

interface IBookingManager is IBooking {
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
        address indexed city,
        uint256 indexed leaseIndex,
        uint256 startNight,
        uint256 endNight,
        uint256 bookingIndex,
        Booking booking
    );
    event Cancel(uint256 indexed bookingIndex);
    event ClaimTokenback(uint256 indexed bookingIndex);
    event BookingIndexUpdated(uint256 indexed newBookingIndex, uint256 indexed oldBoookingIndex);
    event ReleaseFunds(uint256 indexed bookingIndex);
    event Reject(uint256 indexed bookingIndex);
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

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ISwixCity.sol";
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