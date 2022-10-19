// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./RandomEngineConfig.sol";
import "./RandomEngineLogic.sol";

/**
 * @title RandomEngine contract
 * @author Debet
 * @notice Implemention of the RandomEngine contract in debet protocol
 */
contract RandomEngine is RandomEngineConfig, RandomEngineLogic {
    /**
     * @dev Constructor.
     * @param _linkToken The address of the vrf link token
     * @param _coordinator The address of the vrf coordinator
     * @param _linkNativeFeed The address of the chainlink feed contract (NativeToken/LINK)
     * @param _linkPremium The amount of link token for vrf request fee
     * @param _keyHash The bytes for maximum gas limit in vrf callback transaction
     */
    constructor(
        address _linkToken,
        address _coordinator,
        address _linkNativeFeed,
        uint128 _linkPremium,
        bytes32 _keyHash
    )
        RandomEngineStorage(
            _linkToken,
            _coordinator,
            _linkNativeFeed,
            _linkPremium,
            _keyHash
        )
    {}

    /**
     * @notice Initialize the RandomEngine contract
     * @dev Create the subscription account in vrf
     * @param _factory The address of the factory contract
     * @param _stakingPool The address of the staking pool contract
     * @param _stakingPool The address of the swap provider contract
     * @param _distributionPool The address of the distribution pool contract
     */
    function initialize(
        address _factory,
        address _stakingPool,
        address _swapProvider,
        address _distributionPool
    ) external initializer {
        __Ownable_init();

        deployTime = uint128(block.timestamp);
        requestBaseFee = 0;
        engineCallbackGas = 40000;
        distributionCallbackGas = 60000;
        extraCallbackGas = 100000;
        thresholdToAddRewards = 1e18;
        intervalTimeToSwap = 4 hours;
        minLinkBalanceToSwap = 2 * 1e18;

        factory = _factory;
        swapProvider = _swapProvider;
        stakingPool = _stakingPool;
        distributionPool = _distributionPool;

        setVRFCoordinator(address(COORDINATOR));
        createNewSubscription();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IRandomEngineConfig.sol";

import "./RandomEngineStorage.sol";

/**
 * @title RandomEngineConfig contract
 * @author Debet
 * @notice Configuration of the RandomEngine
 */
abstract contract RandomEngineConfig is
    IRandomEngineConfig,
    OwnableUpgradeable,
    RandomEngineStorage
{
    /**
     * @notice Set the base fee that player pay each time they bet
     * @dev Emit the SetRequestBaseFee event
     * @param _requestBaseFee The amount of base Fee
     */
    function setRequestBaseFee(uint128 _requestBaseFee)
        external
        override
        onlyOwner
    {
        requestBaseFee = _requestBaseFee;
        emit SetRequestBaseFee(_requestBaseFee);
    }

    /**
     * @notice Set the maximum interval time of swapping native token to link
     * @dev Emit the SetIntervalTimeToSwap event
     * @param _intervalTimeToSwap The interval time
     */
    function setIntervalTimeToSwap(uint32 _intervalTimeToSwap)
        external
        override
        onlyOwner
    {
        intervalTimeToSwap = _intervalTimeToSwap;
        emit SetIntervalTimeToSwap(_intervalTimeToSwap);
    }

    /**
     * @notice Set the callback gas limit in random engine
     * @dev Emit the SetCallbackGas event
     * @dev Including gas in request function and distribute function
     * @param _engineCallbackGas The gas limit in randomEngine request function
     * @param _distributionCallbackGas The gas limit in distribution rewards function
     */
    function setCallbackGas(
        uint32 _engineCallbackGas,
        uint32 _distributionCallbackGas
    ) external override onlyOwner {
        engineCallbackGas = _engineCallbackGas;
        distributionCallbackGas = _distributionCallbackGas;
        emit SetCallbackGas(_engineCallbackGas, _distributionCallbackGas);
    }

    /**
     * @notice Set the extra gas added to callBackGasLimit when call chainlink vrf
     * @dev Emit the SetExtraCallbackGas event
     * @dev The extra gas would not be used in transaction
     * @param _extraCallbackGas The amount of extra gas
     */
    function setExtraCallbackGas(uint32 _extraCallbackGas)
        external
        override
        onlyOwner
    {
        extraCallbackGas = _extraCallbackGas;
        emit SetExtraCallbackGas(_extraCallbackGas);
    }

    /**
     * @notice set the rewards threshold to adding rewards to rewards pool
     * @dev Emit the SetThresholdToAddRewards event
     * @param _thresholdToAddRewards The threshold
     */
    function setThresholdToAddRewards(uint128 _thresholdToAddRewards)
        external
        override
        onlyOwner
    {
        thresholdToAddRewards = _thresholdToAddRewards;
        emit SetThresholdToAddRewards(_thresholdToAddRewards);
    }

    /**
     * @notice Set the minimum link balance of subscription account
     * @dev Emit the SetMinLinkBalanceToSwap event
     * @dev Swap the native token to link if the link balance of
     * subscription account is less than this value
     * @param _minLinkBalanceToSwap The minimum link balance
     */
    function setMinLinkBalanceToSwap(uint128 _minLinkBalanceToSwap)
        external
        override
        onlyOwner
    {
        minLinkBalanceToSwap = _minLinkBalanceToSwap;
        emit SetMinLinkBalanceToSwap(_minLinkBalanceToSwap);
    }

    /**
     * @notice Set the address of swap provider
     * @dev Emit the SetSwapProvider event
     * @param _swapProvider The address of swap provider contract
     */
    function setSwapProvider(address _swapProvider)
        external
        override
        onlyOwner
    {
        swapProvider = _swapProvider;
        emit SetSwapProvider(_swapProvider);
    }

    /**
     * @notice Set the address of staking pool
     * @dev Emit the SetStakingPool event
     * @param _stakingPool The address of staking pool contract
     */
    function setStakingPool(address _stakingPool) external override onlyOwner {
        stakingPool = _stakingPool;
        emit SetStakingPool(_stakingPool);
    }

    /**
     * @notice Set the address of distribution pool
     * @dev Emit the SetDistributionPool event
     * @param _distributionPool The address of distribution pool contract
     */
    function setDistributionPool(address _distributionPool)
        external
        override
        onlyOwner
    {
        distributionPool = _distributionPool;
        emit SetDistributionPool(_distributionPool);
    }

    /**
     * @notice Set the address of factory contract
     * @dev Emit the SetFactory event
     * @param _factory The address of factory contract
     */
    function setFactory(address _factory) external override onlyOwner {
        factory = _factory;
        emit SetFactory(_factory);
    }

    /**
     * @notice Stop the Random engine and cancel subscription of chainlink vrf
     * @dev Emit the StopEngine event
     * @param linkReceiver The address to receive the remain link token in
     * subscription account
     */
    function stopEngine(address linkReceiver) external onlyOwner {
        require(block.timestamp - deployTime <= 60 days, "forbidden");
        cancelSubscription(linkReceiver);
        emit StopEngine(linkReceiver);
    }

    function cancelSubscription(address receivingWallet) private {
        COORDINATOR.cancelSubscription(subscription_id, receivingWallet);
        subscription_id = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../interfaces/IRandomEngineLogic.sol";
import "../../interfaces/IStakingPool.sol";
import "../../interfaces/IDistributionPool.sol";
import "../../interfaces/ISwapProvider.sol";
import "../../interfaces/IRandomCaller.sol";

import "../../utils/VRFConsumerBaseV2.sol";
import "./RandomEngineStorage.sol";

/**
 * @title RandomEngineLogic contract
 * @author Debet
 * @notice Core logic functions of the RandomEngine
 */
abstract contract RandomEngineLogic is
    IRandomEngineLogic,
    VRFConsumerBaseV2,
    RandomEngineStorage
{
    /**
     * @notice Request the random works
     * @dev Emit the RandomRequest event
     * @dev Only valid caller set by factory can call ths function
     * @param callbackGasLimit The gas required by the callback
     * function of caller contract
     * @param numWords The number of random words that caller required
     * @param rewardsReceiver The address receive rewards of random engine and refund gas
     * @return requestId The request id from chainlink vrf service
     */
    function request(
        uint32 callbackGasLimit,
        uint32 numWords,
        address rewardsReceiver
    ) external payable override returns (uint256 requestId) {
        require(isValidCaller[msg.sender], "invalid caller");

        (uint128 gasRequired, uint32 consumerGasLimit) = calculateGasRequired(
            callbackGasLimit,
            tx.gasprice
        );

        uint128 baseFee = requestBaseFee;
        uint256 nativeTokenRequired = gasRequired + baseFee;
        require(msg.value >= nativeTokenRequired, "insufficient bet fee");

        requestId = requestRandomWords(gasRequired, consumerGasLimit, numWords);

        requestRecords[requestId] = Request(
            requestId,
            msg.sender,
            rewardsReceiver,
            0,
            false
        );

        if (baseFee > 0 && stakingPool != address(0)) {
            addToRewards(baseFee);
        }

        if (msg.value > nativeTokenRequired) {
            uint256 refundValue = msg.value - nativeTokenRequired;
            refundNativeToken(refundValue, rewardsReceiver);
        }

        emit RandomRequest(msg.sender, rewardsReceiver, requestId);
    }

    /**
     * @notice Top up link token for subcription account of random engine
     * @dev Emit the TopUpLink event
     */
    function topUpLink() external payable override {
        uint256 totalAmountToSwap = nativeTokenToSwap + msg.value;
        swapAndTopUp(totalAmountToSwap);
        nativeTokenToSwap = 0;
    }

    /**
     * @notice Set the caller enable or not
     * @dev Emit the SetCaller event
     * @param caller The address of the caller
     * @param enable Whether enable the caller or not
     */
    function setCaller(address caller, bool enable) external override {
        require(msg.sender == factory, "forbidden");
        isValidCaller[caller] = enable;
        emit SetCaller(caller, enable);
    }

    /**
     * @notice get the amount of native token required as gas when call the request function
     * @param callbackGasLimit The gas required by the callback
     * function of caller contract
     * @param gasPriceWei Estimated gas price at time of request
     * @return The amount of native token required
     */
    function calculateNativeTokenRequired(
        uint32 callbackGasLimit,
        uint256 gasPriceWei
    ) external view override returns (uint256) {
        (uint256 gasRequired, ) = calculateGasRequired(
            callbackGasLimit,
            gasPriceWei
        );
        return (gasRequired + requestBaseFee);
    }

    /**
     * @dev callback function called by VRFConsumerBaseV2
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        Request memory requestRecord = requestRecords[requestId];
        require(
            requestRecord.caller != address(0),
            "the record does not exist"
        );

        if (distributionPool != address(0)) {
            requestRecord.rewards = IDistributionPool(distributionPool)
                .distribute(
                    requestRecord.caller,
                    requestRecord.rewardsReceiver,
                    randomWords[0]
                );
        }

        requestRecord.callback = true;
        requestRecords[requestId] = requestRecord;

        IRandomCaller(requestRecord.caller).callback(
            requestId,
            randomWords,
            requestRecord.rewards
        );

        emit RandomCallback(
            requestRecord.caller,
            requestRecord.rewardsReceiver,
            requestId,
            requestRecord.rewards
        );
    }

    function requestRandomWords(
        uint128 gasRequired,
        uint32 callbackGasLimit,
        uint32 numWords
    ) internal returns (uint256 requestId) {
        nativeTokenToSwap += gasRequired;
        if (isTimeToSwap()) {
            swapAndTopUp(nativeTokenToSwap);
            nativeTokenToSwap = 0;
        }

        uint32 totalCallbackGasLimit = callbackGasLimit + extraCallbackGas;
        requestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            subscription_id,
            REQUEST_CONFIRMATIONS,
            totalCallbackGasLimit,
            numWords
        );
    }

    function isTimeToSwap() internal returns (bool) {
        uint96 subscriptioBalance;
        (subscriptioBalance, , , ) = COORDINATOR.getSubscription(
            subscription_id
        );

        if (subscriptioBalance <= minLinkBalanceToSwap) {
            return true;
        }

        if (block.timestamp - lastSwapTime >= intervalTimeToSwap) {
            lastSwapTime = uint32(block.timestamp);
            return true;
        }

        return false;
    }

    function swapAndTopUp(uint256 amount) internal {
        ISwapProvider(swapProvider).swapNativeTokenToLink{value: amount}(
            0,
            address(this)
        );

        topUpSubscription(LINKTOKEN.balanceOf(address(this)));
    }

    function topUpSubscription(uint256 amount) private {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(subscription_id)
        );

        emit TopUpLink(amount);
    }

    function createNewSubscription() internal {
        subscription_id = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscription_id, address(this));
    }

    function addToRewards(uint128 baseFee) internal {
        nativeTokenToRewards += baseFee;
        if (nativeTokenToRewards >= thresholdToAddRewards) {
            IStakingPool(stakingPool).addNativeRewards{
                value: nativeTokenToRewards
            }();
            nativeTokenToRewards = 0;
        }
    }

    function refundNativeToken(uint256 refundValue, address rewardsReceiver)
        internal
    {
        (bool success, ) = payable(rewardsReceiver).call{
            value: refundValue,
            gas: 8000
        }("");
        require(success, "refund native token failed");
    }

    function calculateGasRequired(uint32 callbackGasLimit, uint256 gasPrice)
        internal
        view
        returns (uint128, uint32)
    {
        uint256 weiPerUnitLink = getFeedData();

        uint32 consumerGasLimit;
        if (distributionPool == address(0)) {
            consumerGasLimit = engineCallbackGas + callbackGasLimit;
        } else {
            consumerGasLimit =
                engineCallbackGas +
                distributionCallbackGas +
                callbackGasLimit;
        }
        uint32 totalGasLimit = consumerGasLimit + MAX_VERIFICATION_GAS;

        uint256 gas_required = gasPrice * totalGasLimit;
        uint256 link_premium_to_gas = (LINK_PREMIUM * weiPerUnitLink) / 1e18;
        uint256 total_gas_required = gas_required + link_premium_to_gas;
        assert(total_gas_required < type(uint128).max);

        return (uint128(total_gas_required), consumerGasLimit);
    }

    function getFeedData() private view returns (uint256) {
        uint256 timestamp;
        int256 weiPerUnitLink;

        (, weiPerUnitLink, , timestamp, ) = LINK_NATIVE_FEED.latestRoundData();

        if (STALENESS_SECONDS < block.timestamp - timestamp) {
            uint256 weiPerUnitLinkFromDex = ISwapProvider(swapProvider)
                .getWeiPerUnitLink();
            return weiPerUnitLinkFromDex;
        }

        require(weiPerUnitLink >= 0, "Invalid LINK wei price");
        return uint256(weiPerUnitLink);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IRandomEngineConfig contract
 * @author Debet
 * @notice The interface for RandomEngineConfig contract
 */
interface IRandomEngineConfig {
    /**
     * @dev Emit on setRequestBaseFee function
     * @param requestBaseFee The amount of base Fee
     */
    event SetRequestBaseFee(uint128 requestBaseFee);

    /**
     * @dev Emit on setIntervalTimeToSwap function
     * @param intervalTimeToSwap The interval time
     */
    event SetIntervalTimeToSwap(uint32 intervalTimeToSwap);

    /**
     * @dev Emit on setCallbackGas function
     * @param engineCallbackGas The gas limit in randomEngine request function
     * @param distributionCallbackGas The gas limit in distribution rewards function
     */
    event SetCallbackGas(
        uint32 engineCallbackGas,
        uint32 distributionCallbackGas
    );

    /**
     * @dev Emit on setExtraCallbackGas function
     * @param extraCallbackGas The amount of extra gas
     */
    event SetExtraCallbackGas(uint32 extraCallbackGas);

    /**
     * @dev Emit on setMinLinkBalanceToSwap function
     * @param minLinkBalanceToSwap The minimum link balance of subscription account
     */
    event SetMinLinkBalanceToSwap(uint128 minLinkBalanceToSwap);

    /**
     * @dev Emit on setThresholdToAddRewards function
     * @param thresholdToAddRewards The rewards threshold to adding rewards to rewards pool
     */
    event SetThresholdToAddRewards(uint128 thresholdToAddRewards);

    /**
     * @dev Emit on setSwapProvider function
     * @param swapProvider The address of swap provider contract
     */
    event SetSwapProvider(address swapProvider);

    /**
     * @dev Emit on setStakingPool function
     * @param stakingPool The address of staking pool contract
     */
    event SetStakingPool(address stakingPool);

    /**
     * @dev Emit on setDistributionPool function
     * @param distributionPool The address of distribution pool contract
     */
    event SetDistributionPool(address distributionPool);

    /**
     * @dev Emit on setFactory function
     * @param factory The address of factory contract
     */
    event SetFactory(address factory);

    /**
     * @dev Emit on stopEngine function
     * @param linkReceiver The address to receive the remain link token in
     * subscription account
     */
    event StopEngine(address linkReceiver);

    /**
     * @notice Set the base fee that player pay each time they bet
     * @dev Emit the SetRequestBaseFee event
     * @param _requestBaseFee The amount of base Fee
     */
    function setRequestBaseFee(uint128 _requestBaseFee) external;

    /**
     * @notice Set the maximum interval time of swapping native token to link
     * @dev Emit the SetIntervalTimeToSwap event
     * @param _intervalTimeToSwap The interval time
     */
    function setIntervalTimeToSwap(uint32 _intervalTimeToSwap) external;

    /**
     * @notice Set the callback gas limit in random engine
     * @dev Emit the SetCallbackGas event
     * @dev Including gas in request function and distribute function
     * @param _engineCallbackGas The gas limit in randomEngine request function
     * @param _distributionCallbackGas The gas limit in distribution rewards function
     */
    function setCallbackGas(
        uint32 _engineCallbackGas,
        uint32 _distributionCallbackGas
    ) external;

    /**
     * @notice Set the extra gas added to callBackGasLimit when call chainlink vrf
     * @dev Emit the SetExtraCallbackGas event
     * @dev The extra gas would not be used in transaction
     * @param _extraCallbackGas The amount of extra gas
     */
    function setExtraCallbackGas(uint32 _extraCallbackGas) external;

    /**
     * @notice set the rewards threshold to adding rewards to rewards pool
     * @dev Emit the SetThresholdToAddRewards event
     * @param _thresholdToAddRewards The threshold
     */
    function setThresholdToAddRewards(uint128 _thresholdToAddRewards) external;

    /**
     * @notice Set the minimum link balance of subscription account
     * @dev Emit the SetMinLinkBalanceToSwap event
     * @dev Swap the native token to link if the link balance of
     * subscription account is less than this value
     * @param _minLinkBalanceToSwap The minimum link balance
     */
    function setMinLinkBalanceToSwap(uint128 _minLinkBalanceToSwap) external;

    /**
     * @notice Set the address of swap provider
     * @dev Emit the SetSwapProvider event
     * @param _swapProvider The address of swap provider contract
     */
    function setSwapProvider(address _swapProvider) external;

    /**
     * @notice Set the address of staking pool
     * @dev Emit the SetStakingPool event
     * @param _stakingPool The address of staking pool contract
     */
    function setStakingPool(address _stakingPool) external;

    /**
     * @notice Set the address of distribution pool
     * @dev Emit the SetDistributionPool event
     * @param _distributionPool The address of distribution pool contract
     */
    function setDistributionPool(address _distributionPool) external;

    /**
     * @notice Set the address of factory contract
     * @dev Emit the SetFactory event
     * @param _factory The address of factory contract
     */
    function setFactory(address _factory) external;

    /**
     * @notice Stop the Random engine and cancel subscription of chainlink vrf
     * @dev Emit the StopEngine event
     * @param linkReceiver The address to receive the remain link token in
     * subscription account
     */
    function stopEngine(address linkReceiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * @title RandomEngineStorage contract
 * @author Debet
 * @notice Storage of the RandomEngine
 */
contract RandomEngineStorage {
    struct Request {
        uint256 requestId;
        address caller;
        address rewardsReceiver;
        uint256 rewards;
        bool callback;
    }

    /// @dev Parameter of VRF, the number of block confirmations before the callback
    uint16 internal immutable REQUEST_CONFIRMATIONS;
    /// @dev Maximum tolerance time for chainlink price updates
    uint32 internal immutable STALENESS_SECONDS;
    /// @dev The maximum gas that needs to be used internally during a VRF callback
    uint32 internal immutable MAX_VERIFICATION_GAS;
    /// @dev The amount of link token for vrf request fee
    uint128 internal immutable LINK_PREMIUM;
    /// @dev The bytes for maximum gas limit in vrf callback transaction
    bytes32 internal immutable KEY_HASH;
    /// @dev The link token that used in vrf
    LinkTokenInterface internal immutable LINKTOKEN;
    /// @dev The vrf coordinator contract
    VRFCoordinatorV2Interface internal immutable COORDINATOR;
    /// @dev The chainlink feed contract (NativeToken/LINK)
    AggregatorV3Interface internal immutable LINK_NATIVE_FEED;

    /// @notice The gas limit in randomEngine request function
    uint32 public engineCallbackGas;
    /// @notice The extra gas added to callBackGasLimit when call chainlink vrf
    uint32 public extraCallbackGas;
    /// @notice The gas limit in distribution rewards function
    uint32 public distributionCallbackGas;
    /// @notice The maximum interval time of swapping native token to link
    uint32 public intervalTimeToSwap;

    /// @notice The timestamp swap native token to link last time
    uint64 public lastSwapTime;
    /// @notice The id of the subscription account in vrf service
    uint64 public subscription_id;

    /// @notice The amount of native token accumulated
    /// that waiting to be added to staking pool
    uint128 public nativeTokenToRewards;
    /// @notice The rewards threshold of adding rewards to rewards pool
    uint128 public thresholdToAddRewards;
    /// @notice The timestamp of this contract deployment
    uint128 public deployTime;
    /// @notice The base fee that player pay each time they bet
    uint128 public requestBaseFee;
    /// @notice The amount of native token accumulated
    /// that waiting to be swaped to link token
    uint128 public nativeTokenToSwap;
    ///@notice The minimum link balance of subscription account
    uint128 public minLinkBalanceToSwap;

    /// @notice The address of swapProvider contract
    address public swapProvider;
    /// @notice The address of stakingPool contract
    address public stakingPool;
    /// @notice The address of distributionPool contract
    address public distributionPool;
    /// @notice The address of factory contract
    address public factory;

    /// @notice The mapping from chainlink request id to information of request
    mapping(uint256 => Request) public requestRecords;

    /// @notice The mapping from caller address to the effectiveness of caller
    mapping(address => bool) public isValidCaller;

    /**
     * @dev Constructor.
     * @param _linkToken The address of the vrf link token
     * @param _coordinator The address of the vrf coordinator
     * @param _linkNativeFeed The address of the chainlink feed contract (NativeToken/LINK)
     * @param _linkPremium The amount of link token for vrf request fee
     * @param _keyHash The bytes for maximum gas limit in vrf callback transaction
     */
    constructor(
        address _linkToken,
        address _coordinator,
        address _linkNativeFeed,
        uint128 _linkPremium,
        bytes32 _keyHash
    ) {
        REQUEST_CONFIRMATIONS = 3;
        STALENESS_SECONDS = 4 hours;
        MAX_VERIFICATION_GAS = 100000;
        LINK_PREMIUM = _linkPremium;
        KEY_HASH = _keyHash;
        LINKTOKEN = LinkTokenInterface(_linkToken);
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
        LINK_NATIVE_FEED = AggregatorV3Interface(_linkNativeFeed);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IRandomEngineLogic interface
 * @author Debet
 * @notice The interface for RandomEngineLogic contract
 */
interface IRandomEngineLogic {
    /**
     * @dev Emit on request function
     * @param caller the address of caller contract
     * @param rewardsReceiver The address receive rewards of random engine and refund gas
     * @param requestId The request id from chainlink vrf service
     */
    event RandomRequest(
        address caller,
        address rewardsReceiver,
        uint256 requestId
    );

    /**
     * @dev Emit on fulfillRandomWords function
     * @param caller the address of caller contract
     * @param rewardsReceiver the address receive rewards of random engine and refund gas
     * @param requestId The request id from chainlink vrf service
     * @param rewards The amount of random engine rewards
     */
    event RandomCallback(
        address caller,
        address rewardsReceiver,
        uint256 requestId,
        uint256 rewards
    );

    /**
     * @dev Emit on setCaller function
     * @param caller the address of caller contract
     * @param enable Whether enable the caller or not
     */
    event SetCaller(address caller, bool enable);

    /**
     * @dev Emit on set TopUpLink function
     * @param linkAmount The amount of link to top up
     */
    event TopUpLink(uint256 linkAmount);

    /**
     * @notice Request the random works
     * @dev Emit the RandomRequest event
     * @dev Only valid caller set by factory can call ths function
     * @param callbackGasLimit The gas required by the callback
     * function of caller contract
     * @param numWords The number of random words that caller required
     * @param rewardsReceiver The address receive rewards of random engine and refund gas
     * @return requestId The request id from chainlink vrf service
     */
    function request(
        uint32 callbackGasLimit,
        uint32 numWords,
        address rewardsReceiver
    ) external payable returns (uint256 requestId);

    /**
     * @notice Top up link token for subcription account of random engine
     * @dev Emit the TopUpLink event
     */
    function topUpLink() external payable;

    /**
     * @notice Set the caller enable or not
     * @dev Emit the SetCaller event
     * @param caller The address of the caller
     * @param enable Whether enable the caller or not
     */
    function setCaller(address caller, bool enable) external;

    /**
     * @notice get the amount of native token required as gas when call the request function
     * @param callbackGasLimit The gas required by the callback
     * function of caller contract
     * @param gasPriceWei Estimated gas price at time of request
     * @return The amount of native token required
     */
    function calculateNativeTokenRequired(
        uint32 callbackGasLimit,
        uint256 gasPriceWei
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IStakingPool {
    function addRewards(address token, uint256 rewards) external;

    function addNativeRewards() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IDistributionPool {
    function distribute(
        address game,
        address receiver,
        uint256 randomWord
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title ISwapProvider interface
 * @author Debet
 * @notice The interface for swap provider
 */
interface ISwapProvider {
    /**
     * @dev Emit on setSwapRouter and initialize
     * @param router The address of swap router
     */
    event SetSwapRouter(address router);

    /**
     * @dev Emit on setPegSwap and initialize
     * @param pegSwap The address of peg swap
     */
    event SetPegSwap(address pegSwap);

    /**
     * @dev Emit on setLinkToken and initialize
     * @param link The address of vrf link token
     */
    event SetLinkToken(address link);

    /**
     * @dev Emit on setNativeLinkToken and initialize
     * @param nativeLinkToken The address of bridge link token
     */
    event SetNativeLinkToken(address nativeLinkToken);

    /**
     * @dev Emit on setSwapPath and initialize
     * @param path The address array of swap path from native token to link
     */
    event SetSwapPath(address[] path);

    /**
     * @notice Initialize the swap provider
     * @dev From Wrapped native token to native link token will be set as the default swap path
     * @dev Native link token will be approved for peg swap
     * @param _swapRouter The address of the dex router
     * @param _pegSwap The address of the peg swap
     * @param _linkToken The address of the vrf link token
     * @param _nativeLinkToken The address of the nattive link token
     */
    function initialize(
        address _swapRouter,
        address _pegSwap,
        address _linkToken,
        address _nativeLinkToken
    ) external;

    /**
     * @notice Set the address of dex router (UniswapV2 type dex)
     * @dev Emit the SetSwapRouter event
     * @param _swapRouter The address of the dex router
     */
    function setSwapRouter(address _swapRouter) external;

    /**
     * @notice Set the address of peg swap which is used to swap bridge
     * link token to VRF link token
     * @dev Emit the SetPegSwap event
     * @param _pegSwap The address of the peg swap
     */
    function setPegSwap(address _pegSwap) external;

    /**
     * @notice Set the address of link token for VRF
     * @dev Emit the SetLinkToken event
     * @param _linkToken The address of the vrf link token
     */
    function setLinkToken(address _linkToken) external;

    /**
     * @notice Set the address of native link token(link token from bridge)
     * @dev Emit the SetNativeLinkToken event
     * @dev Native link token will be approved for peg swap
     * @param _nativeLinkToken The address of the nattive link token
     */
    function setNativeLinkToken(address _nativeLinkToken) external;

    /**
     * @notice Set the swap path from native token to link
     * @dev Emit the SetSwapPath event
     * @param path The address array of swap path
     */
    function setSwapPath(address[] memory path) external;

    /**
     * @notice Swap native token to native link token and then swap native link token to vrf link token
     * @param amountOutMin The minimum amount of vrf link token to return
     * @param to The address to receive the vrf link token
     * @return amountOfLink The amount of vrf link token to return
     */
    function swapNativeTokenToLink(uint256 amountOutMin, address to)
        external
        payable
        returns (uint256 amountOfLink);

    /**
     * @notice Get the amount of native token that each link token can swap
     * @return The amount of native token
     */
    function getWeiPerUnitLink() external view returns (uint256);

    /**
     * @notice Get current swap path from native token to native link token
     * @return The address array of swap path
     */
    function getSwapPath() external view returns (address[] memory);

    /**
     * @notice Get the address of swap router
     * @return The address of swap router
     */
    function swapRouter() external view returns (address);

    /**
     * @notice Get the address of peg swap
     * @return The address of peg swap
     */
    function pegSwap() external view returns (address);

    /**
     * @notice Get the address of vrf link token
     * @return The address of vrf link token
     */
    function linkToken() external view returns (address);

    /**
     * @notice Get the address of bridge link token
     * @return The address of bridge link token
     */
    function nativeLinkToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IRandomCaller {
    function callback(
        uint256 requestId,
        uint256[] memory randomWords,
        uint256 rewards
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    function setVRFCoordinator(address _vrfCoordinator) internal virtual {
        require(
            vrfCoordinator == address(0),
            "vrfCoordinator gas been set already"
        );
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IRandomEngineConfig.sol";
import "./IRandomEngineLogic.sol";

/**
 * @title IRandomEngine interface
 * @author Debet
 * @notice The interface for RandomEngine
 */
interface IRandomEngine is IRandomEngineConfig, IRandomEngineLogic {

}