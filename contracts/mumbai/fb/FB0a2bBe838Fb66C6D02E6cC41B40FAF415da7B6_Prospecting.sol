// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IProspector.sol";
import "./IAssetManager.sol";

interface IVRFConsumerBaseV2 {
    function getRandomNumber() external returns (uint256 requestID);
}

error Prospector__InvalidOrderNumber();
error Prospector__MaxOrdersExceeded(uint256 amount);
error Prospector__InvalidId(uint256 id);
error Prospector__NoOrders(address player);
error Prospector__ZeroAddress();
error Prospector__NonmatchingArrays();
error Prospector__InvalidArray();
error Prospecting__OrderNotYetCompleted(address player, uint256 id);
error Prospector__IndexOutOfBounds(uint256 index);
error Prospector__InvalidSpeedupAmount();
error Prospector__NotOracle();

contract Prospecting is OwnableUpgradeable, ReentrancyGuardUpgradeable, IProspector {
    struct ProspectingOrder {
        uint256 effectiveStartTime;
    }

    IAssetManager private s_assetManager;
    IVRFConsumerBaseV2 private s_randNumOracle;
    address private s_moderator;
    address private s_feeWallet;

    uint256 private s_prospectorFee;
    uint256 private s_prospectingTime;
    uint256 private s_prospectorMaxOrders;
    uint256 private s_speedupTime;
    uint256 private s_speedupCost;
    uint256 private s_prospectorTax;

    IAssetManager.AssetIds[] private s_biomodTypes;
    uint256[] private s_biomodWeights;
    uint256 private s_totalBiomodWeights;
    uint256 private s_randNonce;

    mapping(address => ProspectingOrder[]) s_prospectingOrders;
    mapping(uint256 => address) s_requestIds;

    uint256 constant WASTE_ID = uint256(IAssetManager.AssetIds.Waste);
    uint256 constant ASTRO_CREDIT_ID = uint256(IAssetManager.AssetIds.AstroCredit);

    event ProspectingOrderSpedUp(
        address indexed player,
        uint256 amount,
        uint256 effectiveStartTime
    );
    event ProspectingOrderPlaced(address indexed player, uint256 amount);
    event ProspectingOrderCompleted(address indexed player, uint256 id);
    event RandomBiomodMinted(address indexed player, uint256 tokenId);

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

    function placeProspectingOrders(uint256 _numOrders) external nonReentrant {
        ProspectingOrder[] storage orders = s_prospectingOrders[msg.sender];
        if (orders.length + _numOrders > s_prospectorMaxOrders)
            revert Prospector__MaxOrdersExceeded(orders.length + _numOrders);

        if (s_prospectingTime > 0) {
            for (uint256 i; i < _numOrders; ) {
                s_prospectingOrders[msg.sender].push(ProspectingOrder(block.timestamp));
                _burnAssets();
                unchecked {
                    ++i;
                }
            }
            emit ProspectingOrderPlaced(msg.sender, _numOrders);
        } else {
            for (uint256 i; i < _numOrders; ) {
                _burnAssets();
                _requestBiomod();
                unchecked {
                    ++i;
                }
            }
        }
    }

    function claimProspecting(uint256 _id) external nonReentrant {
        ProspectingOrder[] storage orders = s_prospectingOrders[msg.sender];
        if (orders.length == 0) revert Prospector__NoOrders(msg.sender);
        if (_id > orders.length - 1) revert Prospector__InvalidId(_id);

        if ((block.timestamp - orders[_id].effectiveStartTime) > s_prospectingTime) {
            _removeOrder(_id);
            _requestBiomod();

            emit ProspectingOrderCompleted(msg.sender, _id);
        } else {
            revert Prospecting__OrderNotYetCompleted(msg.sender, _id);
        }
    }

    function speedUpProspecting(uint256 _numSpeedups) external {
        uint256 speedupTime = s_speedupTime * _numSpeedups;
        uint256 speedupCost = s_speedupCost;

        ProspectingOrder[] storage orders = s_prospectingOrders[msg.sender];
        if (orders.length == 0) revert Prospector__NoOrders(msg.sender);
        if (_numSpeedups == 0) revert Prospector__InvalidSpeedupAmount();

        for (uint256 orderIndex; orderIndex < orders.length; orderIndex++) {
            uint256 timeElapsed = block.timestamp - orders[orderIndex].effectiveStartTime;
            if (timeElapsed > s_prospectingTime) continue;

            orders[orderIndex].effectiveStartTime -= speedupTime;

            emit ProspectingOrderSpedUp(
                msg.sender,
                _numSpeedups,
                orders[orderIndex].effectiveStartTime
            );
        }
        s_assetManager.trustedBurn(msg.sender, ASTRO_CREDIT_ID, speedupCost * _numSpeedups);
    }

    function _burnAssets() internal {
        uint256 taxPayable = (s_prospectorFee * s_prospectorTax) / 10000;

        s_assetManager.trustedBurn(msg.sender, WASTE_ID, s_prospectorFee);
        s_assetManager.trustedMint(s_feeWallet, WASTE_ID, taxPayable);
    }

    function _requestBiomod() internal {
        uint256 requestId = s_randNumOracle.getRandomNumber();
        s_requestIds[requestId] = msg.sender;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        external
        onlyOracle
    {
        if (s_biomodTypes.length == 0 || s_biomodWeights.length == 0)
            revert Prospector__InvalidArray();

        uint256 random = randomWords[0] % s_totalBiomodWeights;
        address player = s_requestIds[requestId];
        uint256 weight;
        IAssetManager.AssetIds resultantBiomod;
        delete s_requestIds[requestId];

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
            emit RandomBiomodMinted(player, uint256(resultantBiomod));
        } else {
            emit RandomBiomodMinted(player, 0);
        }
    }

    function _removeOrder(uint256 _index) internal {
        if (_index > s_prospectingOrders[msg.sender].length - 1)
            revert Prospector__IndexOutOfBounds(_index);

        for (uint256 i = _index; i < s_prospectingOrders[msg.sender].length - 1; i++) {
            s_prospectingOrders[msg.sender][i] = s_prospectingOrders[msg.sender][i + 1];
        }
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

    /** @notice retreive Moderator
     */
    function getModerator() public view returns (address) {
        return s_moderator;
    }

    function setProspectingPrice(uint256 price) external onlyOwner {
        s_prospectorFee = price;
    }

    function getProspectingPrice() external view returns (uint256 _prospectorFee) {
        _prospectorFee = s_prospectorFee;
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

    /** @notice returns the iAssetManager
     */
    function getIAssetManager() public view returns (IAssetManager) {
        return s_assetManager;
    }

    /** @notice retrieves the player's orders
     *  @param _player player address
     */
    function getProspectingOrders(address _player) public view returns (ProspectingOrder[] memory) {
        ProspectingOrder[] memory orders = s_prospectingOrders[_player];
        return orders;
    }

    function getOrderCompletionTime(uint256 _id, address _player)
        external
        view
        returns (uint256 _waitPeriod)
    {
        ProspectingOrder[] storage orders = s_prospectingOrders[_player];
        if (_id > orders.length - 1) revert Prospector__InvalidId(_id);
        uint256 timeElapsed = block.timestamp - orders[_id].effectiveStartTime;
        _waitPeriod = timeElapsed > s_prospectingTime ? 0 : s_prospectingTime - timeElapsed;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title The Prospector allows the user to "prospect" their waste
interface IProspector {
    /**
     * @notice Places orders for "prospecting"
     * @param _numOrders How many orders to place simultaneously
     */
    function placeProspectingOrders(uint256 _numOrders) external;

    /// @notice Claims completed prospecting orders
    function claimProspecting(uint256 _id) external;

    /**
     * @notice Used to fetch the price of prospecting
     * @return _wastePrice The amount of waste one has to pay to prospect
     */
    function getProspectingPrice() external view returns (uint256 _wastePrice);

    /**
     * @notice Used to speed up prospecting
     * @param _numSpeedups How many "units" of speed up
     */
    function speedUpProspecting(uint256 _numSpeedups) external;
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
        LuckyCatShare // 25
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