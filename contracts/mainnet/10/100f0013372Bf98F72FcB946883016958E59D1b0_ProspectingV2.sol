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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title Interface default functionality for traders.
*/
interface ITrader {

    /**
    * @notice Generic struct containing information about a timed build for a ITrader.
    * @param orderId, id for unique order.
    * @param orderAmount, amount of tokens requested in order.
    * @param createdAt, timestamp of creation for order.
    * @param speedUpDeductedAmount, total speed up time for order.
    * @param totalCompletionTime, default time for creation minus speedUpDeductedAmount.
    */
    struct Order {
        uint orderId;
        uint orderAmount; //can be multiple on wasteToCash, will be 1 on IfacilityStore, multiple for prospecting?
        uint createdAt; //start time for order. epoch Time
        uint speedUpDeductedAmount; //time that has been deducted.
        uint totalCompletionTime; // defaultOrdertime - speedUpDeductedAmount. In seconds.
    }

    /**
    * @notice Get all active orders for user.
    * @param _player, address for orders to be requested from.
    * @return All unclaimed orders.
    */
    function getOrders(address _player) external view returns (Order[] memory);

    /**
    * @notice Speed up one order.
    * @param _numSpeedUps, how many times you want to speed up an order.
    * @param _orderId, chosen order to speed up.
    */
    function speedUpOrder(uint _numSpeedUps, uint _orderId) external;

    /**
    * @notice Claim order single order.
    * @param _orderId, chosen order to claim
    */
    function claimOrder(uint _orderId) external;

    /**
    * @notice Claim all orders that are finished for user.
    */
    function claimBatchOrder() external;

    function setIXTSpeedUpParams(address _pixt, address _beneficiary, uint _pixtSpeedupSplitBps, uint _pixtSpeedupCost) external;

    function IXTSpeedUpOrder(uint _numSpeedUps, uint _orderId) external;

    function setBaseLevelAddress(address _baseLevelAddress) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract responsible for minting rewards and burning payment in the context of the mission control
interface IAssetManager {
    enum AssetIds {
        UNUSED_0, // 0, unused
        GoldBadge, //1
        SilverBadge, //2
        BronzeBadge, // 3
        GenesisDrone, //4
        PiercerDrone, // 5
        YSpaceShare, //6
        Waste, //7
        AstroCredit, // 8
        Blueprint, // 9
        BioModOutlier, // 10
        BioModCommon, //11
        BioModUncommon, // 12
        BioModRare, // 13
        BioModLegendary, // 14
        LootCrate, // 15
        TicketRegular, // 16
        TicketPremium, //17
        TicketGold, // 18
        FacilityOutlier, // 19
        FacilityCommon, // 20
        FacilityUncommon, // 21
        FacilityRare, //22
        FacilityLegendary, // 23,
        Energy, // 24
        LuckyCatShare, // 25,
        GravityGradeShare, // 26
        NetEmpireShare, //27
        NewLandsShare, // 28
        HaveBlueShare, //29
        GlobalWasteSystemsShare, // 30
        EternaLabShare // 31
    }

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens
     * @param _amount Number of tokens to mint
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens
     * @param _amounts Number of tokens to mint
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenId Id of to-be-burnt tokens
     * @param _amount Number of tokens to burn
     */
    function trustedBurn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenIds Ids of to-be-burnt tokens
     * @param _amounts Number of tokens to burn
     */
    function trustedBatchBurn(
        address _from,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IBaseLevel {

    /**
    * @notice Set super app address.
    * @param _superAppAddress address of MissionControlStream.
    */
    function setSuperAppAddress(address _superAppAddress) external;

    /**
    * @notice Set sf flow per month per level.
    * @param _superFluidPerLevel flow per level.
    */
    function setSuperFluidPerLevel(uint _superFluidPerLevel) external;

    /**
    * @notice Set numbers of orders for a ITrader depending users level.
    * @param _trader address of ITrader.
    * @param _fromLevel from this level to _toLevel will be set to _additionalOrders.
    * @param _toLevel from this level to _fromLevel  will be set to _additionalOrders.
    * @param _additionalOrders number of orders a trader will have for input level range.
    */
    function setOrderCapacity(address _trader, uint _fromLevel, uint _toLevel, uint _additionalOrders) external;

    /**
    * @notice Set address for super token and super token lite.
    * @param _superToken address for super token.
    * @param _superTokenLite address for super token lite.
    */
    function setSuperTokens(address _superToken, address _superTokenLite) external;

    /**
    * @notice Get number of orders for a user for a ITrader.
    * @param _trader address of ITrader.
    * @param _user user to look up capacity for.
    */
    function getOrderCapacity(address _trader, address _user) external view returns(uint _extraOrders);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/ITrader.sol";

/// @title The Prospector allows the user to "prospect" their waste
interface IProspector is ITrader {
    /**
     * @notice Places orders for "prospecting"
     * @param _numOrders How many orders to place simultaneously
     */
    function placeProspectingOrders(uint256 _numOrders) external;

    /**
     * @notice Used to fetch the price of prospecting
     * @return _wastePrice The amount of waste one has to pay to prospect
     */
    function getProspectingPrice() external view returns (uint256 _wastePrice);

    /**
     * @notice Used to fetch weights for each token.
     * @return _weights base amount. Can be used to calculate probability for each token.
     */
    function getProspectingWeights() external view returns (uint256[] memory _weights);

    function getProspectingMaxOrders() external view returns (uint256 _maxOrders);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IProspector.sol";
import "./IAssetManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../util/Burnable.sol";
import "./IBaseLevel.sol";
interface IVRFConsumerBaseV2 {
    function getRandomNumber(uint32 _num_words) external returns (uint256 requestID);
}

error Prospector__InvalidOrderId(uint orderId);
error Prospector__MaxOrdersExceeded(uint256 amount);
error Prospector__InvalidId(uint256 id);
error Prospector__NoOrders(address player);
error Prospector__NoClaimableOrders(address player);
error Prospector__ZeroAddress();
error Prospector__NonmatchingArrays();
error Prospector__InvalidArray();
error Prospecting__OrderNotYetCompleted(address player, uint256 id);
error Prospector__IndexOutOfBounds(uint256 index);
error Prospector__InvalidSpeedupAmount();
error Prospector__NotOracle();
error Prospector__NoSpeedUpAvailable(uint orderId);

contract ProspectingV2 is OwnableUpgradeable, ReentrancyGuardUpgradeable, IProspector {
    struct ProspectingOrder {
        uint256 effectiveStartTime;
    }

    IAssetManager private s_assetManager;
    IVRFConsumerBaseV2 private s_randNumOracle;
    address private s_moderator;
    address private s_feeWallet;

    uint256 public s_prospectorFee;
    uint256 public s_prospectingTime;
    uint256 public s_prospectorMaxOrders; //disabled
    uint256 public s_speedupTime;
    uint256 public s_speedupCost;
    uint256 public s_prospectorTax;

    IAssetManager.AssetIds[] public s_biomodTypes;
    uint256[] public s_biomodWeights;
    uint256 public s_totalBiomodWeights;
    uint256 public s_randNonce;

    mapping(address => Order[]) s_prospectingOrders;
    mapping(uint256 => address) s_requestIds;

    uint256 constant WASTE_ID = uint256(IAssetManager.AssetIds.Waste);
    uint256 constant ASTRO_CREDIT_ID = uint256(IAssetManager.AssetIds.AstroCredit);
    uint256 public nextOrderId;

    address public pixt;
    address beneficiary;
    uint public pixtSpeedupSplitBps;
    uint public pixtSpeedupCost;

    mapping(uint => uint) s_reqIdToOrder;
    mapping(uint => uint) s_randomResult;

    address public baseLevelAddress;

    event ProspectingOrderSpedUp(
        address indexed player,
        uint256 amount,
        uint orderId
    );
    event ProspectingOrderPlaced(address indexed player, uint256 amount);
    event ProspectingOrderCompleted(address indexed player, uint256 id);
    event RandomBiomodMinted(address indexed player, uint256 tokenId, uint256 orderId);

    modifier onlyOracle() {
        if (msg.sender != address(s_randNumOracle)) revert Prospector__NotOracle();
        _;
    }

    function initialize(
        address _feeWallet,
        uint256 _prospectorFee,
        uint256 _prospectingTime,
        uint256 _prospectingMaxOrders,
        uint256 _speedupTime,
        uint256 _speedupCost,
        uint256 _prospectingTax
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        s_moderator = msg.sender;
        s_feeWallet = _feeWallet;
        s_prospectorFee = _prospectorFee;
        s_prospectingTime = _prospectingTime;
        s_prospectorMaxOrders = _prospectingMaxOrders;
        s_speedupTime = _speedupTime;
        s_speedupCost = _speedupCost;
        s_prospectorTax = _prospectingTax;
    }

    /// @inheritdoc IProspector
    function placeProspectingOrders(uint256 _numOrders) external nonReentrant {
        Order[] memory orders = s_prospectingOrders[msg.sender];
        if (orders.length + _numOrders > IBaseLevel(baseLevelAddress).getOrderCapacity(address(this), msg.sender))
            revert Prospector__MaxOrdersExceeded(orders.length + _numOrders);

        for (uint256 i; i < _numOrders; ) {
            uint256 _orderId = nextOrderId;
            nextOrderId++;
            s_prospectingOrders[msg.sender].push(Order({
                orderId: _orderId,
                orderAmount: 1,
                createdAt: block.timestamp,
                speedUpDeductedAmount: 0,
                totalCompletionTime: s_prospectingTime}));
            _burnAssets();
            _requestBiomod(_orderId);
            unchecked {
                ++i;
            }
        }
        emit ProspectingOrderPlaced(msg.sender, _numOrders);
    }

    /// @inheritdoc ITrader
    function claimOrder(uint _orderId) external override {
        Order[] storage orders = s_prospectingOrders[msg.sender];
        if (orders.length == 0) revert Prospector__NoOrders(msg.sender);
        for(uint256 i=0; i < orders.length; i++) {
            if (orders[i].orderId == _orderId){
                if (isFinished(orders[i])) {
                    _mintBiomod(_orderId);
                    _removeOrder(i);
                    return;
                }
                else
                    revert Prospecting__OrderNotYetCompleted(msg.sender, _orderId);
            }
        }
        revert Prospector__InvalidId(_orderId);
    }

    /// @inheritdoc ITrader
    function claimBatchOrder() external override {
        Order[] memory orders = s_prospectingOrders[msg.sender];
        if (orders.length <= 0) revert Prospector__NoOrders(msg.sender);
        for(uint i=orders.length; i > 0; i--) {
            if ((orders[i-1].createdAt + orders[i-1].totalCompletionTime) < block.timestamp) {
                _mintBiomod(orders[i-1].orderId);
                _removeOrder(i-1);
            }
        }
    }

    /// @inheritdoc ITrader
    function speedUpOrder(uint _numSpeedUps, uint _orderId) external override {
        Order[] storage orders = s_prospectingOrders[msg.sender];
        if (orders.length == 0) revert Prospector__NoOrders(msg.sender);
        if (_numSpeedUps == 0) revert Prospector__InvalidSpeedupAmount();

        for (uint256 orderIndex; orderIndex < orders.length; orderIndex++) {
            if (orders[orderIndex].orderId == _orderId) {
                if (isFinished(orders[orderIndex])) revert Prospector__NoSpeedUpAvailable(_orderId);

                orders[orderIndex].speedUpDeductedAmount += s_speedupTime * _numSpeedUps;
                orders[orderIndex].totalCompletionTime =
                int(s_prospectingTime) - int(orders[orderIndex].speedUpDeductedAmount) > 0 ? s_prospectingTime - orders[orderIndex].speedUpDeductedAmount : 0;

                s_assetManager.trustedBurn(msg.sender, ASTRO_CREDIT_ID, s_speedupCost * _numSpeedUps);
                emit ProspectingOrderSpedUp(msg.sender, _numSpeedUps, _orderId);
                return;
            }
        }
        revert Prospector__InvalidOrderId(_orderId);
    }

    function isFinished(Order memory order) internal view returns(bool _isFinished){
        _isFinished = (order.createdAt + order.totalCompletionTime) < block.timestamp;
    }

    function IXTSpeedUpOrder(uint _numSpeedUps, uint _orderId) external override { // add in interface and add override.
        require(pixt != address (0), "IXT address not set");
        Order[] storage orders = s_prospectingOrders[msg.sender];
        if (orders.length == 0) revert Prospector__NoOrders(msg.sender);
        if (_numSpeedUps == 0) revert Prospector__InvalidSpeedupAmount();

        for (uint256 orderIndex; orderIndex < orders.length; orderIndex++) {
            if (orders[orderIndex].orderId == _orderId) {
                if (isFinished(orders[orderIndex])) revert Prospector__NoSpeedUpAvailable(_orderId);

                orders[orderIndex].speedUpDeductedAmount += s_speedupTime * _numSpeedUps;
                orders[orderIndex].totalCompletionTime =
                int(s_prospectingTime) - int(orders[orderIndex].speedUpDeductedAmount) > 0 ? s_prospectingTime - orders[orderIndex].speedUpDeductedAmount : 0;

                require(IERC20(pixt).transferFrom(msg.sender, address(this), pixtSpeedupCost * _numSpeedUps), "Transfer of funds failed"); // transfer 100% to this contract.
                Burnable(pixt).burn((pixtSpeedupCost * _numSpeedUps * pixtSpeedupSplitBps) / 10000);
                emit ProspectingOrderSpedUp(msg.sender, _numSpeedUps, _orderId);
                return;
            }
        }
        revert Prospector__InvalidOrderId(_orderId);
    }

    function setIXTSpeedUpParams(address _pixt, address _beneficiary, uint _pixtSpeedupSplitBps, uint _pixtSpeedupCost) external override onlyOwner{
        pixt = _pixt;
        beneficiary = _beneficiary;
        pixtSpeedupSplitBps = _pixtSpeedupSplitBps;
        pixtSpeedupCost = _pixtSpeedupCost;
    }

    function _burnAssets() internal {
        uint256 taxPayable = (s_prospectorFee * s_prospectorTax) / 10000;

        s_assetManager.trustedBurn(msg.sender, WASTE_ID, s_prospectorFee);
        s_assetManager.trustedMint(s_feeWallet, WASTE_ID, taxPayable);
    }

    function _requestBiomod(uint _orderId) internal {
        uint256 requestId = s_randNumOracle.getRandomNumber(1);
        s_requestIds[requestId] = msg.sender;
        s_reqIdToOrder[requestId] = _orderId;
    }

    function _mintBiomod(uint _orderId) internal {
        if (s_biomodTypes.length == 0 || s_biomodWeights.length == 0)
            revert Prospector__InvalidArray();

        uint random = s_randomResult[_orderId] % s_totalBiomodWeights;
        address player = msg.sender;
        uint256 weight;
        IAssetManager.AssetIds resultantBiomod;

        for (uint256 i; i < s_biomodWeights.length; i++) {
            weight += s_biomodWeights[i];
            if (random <= weight) {
                resultantBiomod = s_biomodTypes[i];
                break;
            }
        }
        ///@dev Using Asset ID 0 to mean no mint
        if (uint256(resultantBiomod) > 0) {
            s_assetManager.trustedMint(player, uint256(resultantBiomod), 1);
            emit RandomBiomodMinted(player, uint256(resultantBiomod), _orderId);
        } else {
            emit RandomBiomodMinted(player, 0, _orderId);
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        external
        onlyOracle
    {
        s_randomResult[s_reqIdToOrder[requestId]] = randomWords[0];
    }

    function _removeOrder(uint _index) internal {
        if (_index < s_prospectingOrders[msg.sender].length -1)
            s_prospectingOrders[msg.sender][_index] = s_prospectingOrders[msg.sender][s_prospectingOrders[msg.sender].length-1];
        s_prospectingOrders[msg.sender].pop();

    }

    function setBiomodWeights(
        IAssetManager.AssetIds[] calldata _biomodTypes,
        uint256[] calldata _biomodWeights
    ) external onlyOwner {
        if (_biomodTypes.length == 0 || _biomodWeights.length == 0)
            revert Prospector__InvalidArray();
        if (_biomodTypes.length != _biomodWeights.length) revert Prospector__NonmatchingArrays();
        s_biomodTypes = _biomodTypes;
        s_biomodWeights = _biomodWeights;

        uint256 sum;
        for (uint256 i; i < _biomodWeights.length; i++) {
            sum += _biomodWeights[i];
        }
        s_totalBiomodWeights = sum;
    }

    /** @notice change Moderator
     *  @param _moderator new moderator
     */
    function setModerator(address _moderator) external onlyOwner {
        if (_moderator == address(0)) revert Prospector__ZeroAddress();
        s_moderator = _moderator;
    }

    function setOracle(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert Prospector__ZeroAddress();
        s_randNumOracle = IVRFConsumerBaseV2(_oracle);
    }

    function setNextOrderId(uint256 _orderId) external onlyOwner {
        nextOrderId = _orderId;
    }

    /** @notice retreive Moderator
     */
    function getModerator() public view returns (address) {
        return s_moderator;
    }

    function setProspectingPrice(uint256 price) external onlyOwner {
        s_prospectorFee = price;
    }
    /// @inheritdoc IProspector
    function getProspectingPrice() external view returns (uint256 _prospectorFee) {
        _prospectorFee = s_prospectorFee;
    }
    /// @inheritdoc IProspector
    function getProspectingWeights() external view returns (uint256[] memory _weights){
        _weights = s_biomodWeights;
    }
    /// @inheritdoc IProspector
    function getProspectingMaxOrders() external view returns (uint256 _maxOrders){
        _maxOrders = s_prospectorMaxOrders;
    }


    /** @notice change Fee Wallet Address
     *  @param _feeWallet new fee wallet address
     */

    function setFeeWallet(address _feeWallet) external onlyOwner {
        if (_feeWallet == address(0)) revert Prospector__ZeroAddress();
        s_feeWallet = _feeWallet;
    }

    /** @notice retreive Fee Wallet Address
     */
    function getFeeWallet() public view returns (address) {
        return s_feeWallet;
    }

    /** @notice change duration of time to prospect
     *  @param _prospectingTime converting time duration
     */
    function setProspectingTime(uint256 _prospectingTime) external onlyOwner {
        s_prospectingTime = _prospectingTime;
    }

    /** @notice retreive duration of time prospect
     */
    function getProspectingTime() public view returns (uint256) {
        return s_prospectingTime;
    }

    /** @notice change amount of Astro Credits to speed up 
        prospecting
     *  @param _speedupCost Astro Credits amount
     */
    function setSpeedupCost(uint256 _speedupCost) external onlyOwner {
        s_speedupCost = _speedupCost;
    }

    /** @notice retreive amount of Astro Credits to speed up 
        prospecting
     */
    function getSpeedupCost() public view returns (uint256) {
        return s_speedupCost;
    }

    /** @notice change the reduction time to prospect
     *  @param _speedupTime reduction time amount
     */
    function setSpeedupTime(uint256 _speedupTime) external onlyOwner {
        s_speedupTime = _speedupTime;
    }

    /** @notice retreive the reduction time to prospect
     */
    function getSpeedupTime() public view returns (uint256) {
        return s_speedupTime;
    }

    /** @notice change basis points for the fee
     *  @param _tax fee represented as basis points e.g. 500 == 5 pct
     */
    function setProspectorTax(uint16 _tax) external onlyOwner {
        s_prospectorTax = _tax;
    }

    /** @notice retreive basis points for the fee
     */
    function getProspectorTax() public view returns (uint256) {
        return s_prospectorTax;
    }

    /** @notice change the implementation address for the iAssetManager
     *  @param _iAssetManager implementation address
     */
    function setIAssetManager(address _iAssetManager) external onlyOwner {
        s_assetManager = IAssetManager(_iAssetManager);
    }

    function setBaseLevelAddress(address _baseLevelAddress) external override onlyOwner {
        baseLevelAddress = _baseLevelAddress;
    }

    /** @notice returns the iAssetManager
     */
    function getIAssetManager() public view returns (IAssetManager) {
        return s_assetManager;
    }

    /// @inheritdoc ITrader
    function getOrders(address _player) external view returns (Order[] memory){
        return s_prospectingOrders[_player];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


/// @title Generic interface for burning.
interface Burnable {
    function burn(uint256 amount) external;
}