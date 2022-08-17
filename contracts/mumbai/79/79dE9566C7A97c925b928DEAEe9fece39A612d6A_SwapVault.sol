// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ITrufinVault} from "../../interfaces/ITrufinVault.sol";
import {ISwapVault} from "../../interfaces/ISwapVault.sol";
import {IMasterWhitelist} from "../../interfaces/IMasterWhitelist.sol";
import {Compute} from "../../libraries/Compute.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
    @title This Vault allows Trufin Vaults to swap between asset pairs internally,
    as well as externally with KYCed Market Makers 
    @author Tanishk Goyal 
*/

/** 
    @dev all assets within the swap vault are scaled to 10**18,
    But this does not affect the users in execution, they still deposit and withdraw, 
    in the original asset decimals.
    Users should only be aware of this if they are trying to view their positions
    User positions will be scaled to 10**18 in the vault,
    but actual position size remains same
*/

/** @dev every Trufin vault needs a function with this signature - 
    receiveSwappedFunds(
        uint256 spotRate,
        uint256 midSpotRate,
        uint256 amountSwapped,
        uint256 amountLeftover
    ) external
*/
contract SwapVault is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ISwapVault
{
    using SafeERC20Upgradeable for IERC20Metadata;
    // ====================================================================
    //                       INITIALIZATION
    // ====================================================================

    /// @dev pools the mapping of all available swap pools in the vault
    mapping(bytes32 => SwapPool) public pools;

    /// @dev swapRequests the mapping of all generated Requests in the vault
    mapping(bytes32 => SwapRequest) public swapRequests;

    /// @dev swapOrder the mapping of all generated External MM Orders in the vault
    mapping(uint256 => SwapOrder) public swapOrders;

    /** @dev SPOT_RATE_MULTIPLIER returns the value to scale any swap rate,
    Currently every swap rate will have precision of 18 decimal places*/
    uint256 public constant SPOT_RATE_MULTIPLIER = 10**18;

    /** @dev EMERGENCY_WITHDRAW_TIME the delay after which pool emergency can be declared,
    calculated starting from lastLockedTime */
    uint256 public constant EMERGENCY_WITHDRAW_TIME = 72 hours;

    /// @dev should never be incremented or decremented except after creating new order
    uint256 public orderCounter;

    /// @dev whitelistAddress is the address of the master whitelist contract
    address public whitelistAddress;

    // https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    uint256[50] private __gap;

    /** 
        @notice Checks if the pool status is correct or not
        @param poolId Id of the pool, whose status needs to be checked
        @param __status Valid status of the pool with Id poolId
    */
    modifier onlyDuringPoolState(bytes32 poolId, PoolStatus __status) {
        require(pools[poolId].status == __status, "Pool Status Does Not Match");
        _;
    }

    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
    /// @dev if this fails to compile for you, use yarn install
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /** @dev Initializes the vault according to open zepellin's initalization procotol
        @param _whitelist is the address of the master whitelist contract
    */
    function initialize(address _whitelist) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        require(_whitelist != address(0), "Whitelist Address Cannot Be 0");
        whitelistAddress = _whitelist;
    }

    // ====================================================================
    //                          VAULT UTILITY FUNCTIONS
    // ====================================================================

    /** @dev utility function to reset the pool's variables
        @param poolId Id of the pool, whose variables needs to be reset
        @param __status New status that we want to set for the pool
    */
    function _resetPoolStorage(bytes32 poolId, PoolStatus __status) internal {
        pools[poolId].status = __status;
        pools[poolId].lastLockedTime = 0;
        pools[poolId].fromLiquidAmount = 0;
        pools[poolId].toLiquidAmount = 0;
        pools[poolId].originalAmount = 0;
        pools[poolId].internalSwapRate = 0;
        pools[poolId].aggregateSwapRate = 0;
        pools[poolId].toLockedAmount = 0;
        pools[poolId].totalAmountSwappedinFrom = 0;
        pools[poolId].midSwapRate = 0;

        emit ResetPool(poolId, __status);
    }

    /**
        @notice utility function to be called whenever a pool's status is going to be changed
        @dev any changes to pool status, has to be made only through this function
        @dev OppPool refers to the pool that is giving the reverse swap of the current Pool
        @dev changes to the pool with poolId, also changes the status of the oppPool 
            i.e if you change status of a ETH/USD pool , the status of USD/ETH pool will also be changed
        @param poolId Id of the pool, whose status needs to be changed
        @param __status New status that we want to set for the pool
        @return success if the status can be changed then true, else false
        @dev changePoolStatus doesn't revert on illogical changes to the state, instead it returns false
            which can then be used by caller to revert
    */
    function _changePoolStatus(bytes32 poolId, PoolStatus __status)
        internal
        returns (bool)
    {
        PoolStatus currentStatus = pools[poolId].status;
        bytes32 oppPoolId = getPoolId(
            pools[poolId].assetTo,
            pools[poolId].assetFrom
        );
        // If pool is already in this status
        if (__status == currentStatus && __status != PoolStatus.LOCKED) {
            return true;
        }
        // If pool is Locked
        if (__status == PoolStatus.LOCKED) {
            if (currentStatus == PoolStatus.UNLOCKED) {
                _rebalanceVault(poolId);
                pools[poolId].status = __status;
                pools[oppPoolId].status = __status;
                pools[oppPoolId].lastLockedTime = block.timestamp;
                pools[poolId].lastLockedTime = block.timestamp;
                return true;
            } else {
                return false;
            }
        }
        // If Pool is Unlocked
        else if (__status == PoolStatus.UNLOCKED) {
            if (currentStatus == PoolStatus.WAITING_FOR_RATE) {
                pools[poolId].status = __status;
                pools[oppPoolId].status = __status;
                return true;
            } else {
                return false;
            }
        }
        // If Pool is WaitingForRate
        else if (__status == PoolStatus.WAITING_FOR_RATE) {
            require(
                pools[poolId].requestIds.length == 0,
                "There are still requests pending"
            );
            require(
                pools[poolId].orderIds.length == 0,
                "There are still orders pending"
            );
            require(
                pools[oppPoolId].orderIds.length == 0,
                "There are still orders pending"
            );
            require(
                pools[oppPoolId].requestIds.length == 0,
                "There are still requests pending"
            );

            _resetPoolStorage(poolId, __status);
            _resetPoolStorage(oppPoolId, __status);

            return true;
        }
        // If Pool is in Emergency
        else if (__status == PoolStatus.EMERGENCY) {
            if (
                currentStatus == PoolStatus.WAITING_FOR_RATE ||
                currentStatus == PoolStatus.LOCKED
            ) {
                pools[poolId].status = __status;
                pools[oppPoolId].status = __status;

                return true;
            } else {
                return false;
            }
        }
        // If Pool is INACTIVE
        else if (__status == PoolStatus.INACTIVE) {
            if (currentStatus == PoolStatus.WAITING_FOR_RATE) {
                pools[poolId].status = __status;
                pools[oppPoolId].status = __status;

                return true;
            } else {
                return false;
            }
        }
        // If Status is anything else
        else {
            return false;
        }
    }

    /**
        @dev utility function to set the aggregate swap rate for any pool pairs
        @dev aggregate swap rates for both pool and oppPool is set
        @param poolId of any of the pools - poolId or oppPoolId
    */
    function _setAggregateSwapRate(bytes32 poolId) internal {
        bytes32 oppPoolId = getPoolId(
            pools[poolId].assetTo,
            pools[poolId].assetFrom
        );
        uint256 totalAmountTo = pools[poolId].toLiquidAmount +
            pools[poolId].toLockedAmount;
        pools[poolId].aggregateSwapRate =
            (totalAmountTo * SPOT_RATE_MULTIPLIER) /
            pools[poolId].totalAmountSwappedinFrom;
        pools[oppPoolId].aggregateSwapRate =
            (SPOT_RATE_MULTIPLIER * SPOT_RATE_MULTIPLIER) /
            pools[poolId].aggregateSwapRate;
    }

    /** 
        @dev utility function to delete a specific orderId, from orderIds array of a pool
        @dev this is a O(Number of total orders) operation, which should always be pretty small
        @param poolId Id of the pool
        @param orderId Id of the order to be deleted
    */
    function _deleteSwapOrder(bytes32 poolId, uint256 orderId) internal {
        SwapPool memory tempPool = pools[poolId];
        uint256 tempPoolLength = tempPool.orderIds.length;
        for (uint256 i = 0; i < tempPoolLength; ) {
            if (tempPool.orderIds[i] == orderId) {
                pools[poolId].orderIds[i] = tempPool.orderIds[
                    tempPool.orderIds.length - 1
                ];
                pools[poolId].orderIds.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
        emit DeleteSwapOrder(poolId, orderId);
        delete swapOrders[orderId];
    }

    /**
        @dev utility function to delete a specific requestId, from requestIds array of a pool
        @dev this is a O(Number of total trufin vaults) operation, which should always be pretty small
        @param poolId Id of the pool
        @param requestId Id of the request to be deleted
    */
    function _deleteSwapRequest(bytes32 poolId, bytes32 requestId) internal {
        SwapPool memory tempPool = pools[poolId];
        uint256 tempPoolLength = tempPool.requestIds.length;
        for (uint256 i = 0; i < tempPoolLength; ) {
            if (tempPool.requestIds[i] == requestId) {
                pools[poolId].requestIds[i] = tempPool.requestIds[
                    tempPool.requestIds.length - 1
                ];
                pools[poolId].requestIds.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
        emit DeleteSwapRequest(poolId, requestId);
        delete swapRequests[requestId];
    }

    /** 
        @dev utility function that does internal swapping between pool and oppPool at internalSwapRate
        After this function is called, the liquid amounts in either one of pool or oppPool will become 0 
        @dev this function is called after every deposit, and every withdrawInstantly
        @param poolId id of either pool or oppPool 
    */
    function _rebalanceVault(bytes32 poolId) internal {
        // OppPool refers to the vault that is giving the reverse swap of the currentPoolId
        bytes32 oppPoolId = getPoolId(
            pools[poolId].assetTo,
            pools[poolId].assetFrom
        );

        // Whichever value is greater has to be reduced by the smaller value
        uint256 oppVaultFunds = pools[oppPoolId].originalAmount; // in assetTo
        uint256 currVaultFunds = (pools[poolId].originalAmount *
            pools[poolId].internalSwapRate) / SPOT_RATE_MULTIPLIER;

        if (oppVaultFunds > currVaultFunds) {
            pools[oppPoolId].fromLiquidAmount = oppVaultFunds - currVaultFunds;
            pools[oppPoolId].toLockedAmount = pools[poolId].originalAmount;
            pools[poolId].fromLiquidAmount = 0;
            pools[poolId].toLockedAmount = currVaultFunds;
        } else {
            pools[poolId].fromLiquidAmount =
                pools[poolId].originalAmount -
                (oppVaultFunds * pools[oppPoolId].internalSwapRate) /
                SPOT_RATE_MULTIPLIER;
            pools[poolId].toLockedAmount = pools[oppPoolId].originalAmount;
            pools[oppPoolId].fromLiquidAmount = 0;
            pools[oppPoolId].toLockedAmount =
                (pools[oppPoolId].originalAmount *
                    pools[oppPoolId].internalSwapRate) /
                SPOT_RATE_MULTIPLIER;
        }
        pools[poolId].totalAmountSwappedinFrom =
            (pools[poolId].toLockedAmount * pools[oppPoolId].internalSwapRate) /
            SPOT_RATE_MULTIPLIER;
        pools[oppPoolId].totalAmountSwappedinFrom =
            (pools[oppPoolId].toLockedAmount * pools[poolId].internalSwapRate) /
            SPOT_RATE_MULTIPLIER;
        pools[poolId].aggregateSwapRate = pools[poolId].internalSwapRate;
        pools[oppPoolId].aggregateSwapRate = pools[oppPoolId].internalSwapRate;
    }

    /** 
        @dev utility function to approve the correct amount of assets for withdrawal
        @dev this function only approves the amounts, it doesn't call any function in the user's contract
        @notice _amount number of tokens are approved from the vault,
            user has to complete withdrawal by calling safeTransferFrom in asset contract 
        @param requestId id of the request which is being withdrawn
    */
    function _withdraw(bytes32 requestId, SwapPool memory tempPool)
        internal
        returns (
            address,
            uint256,
            uint256,
            bool
        )
    {
        SwapRequest memory tempRequest = swapRequests[requestId];
        address user = tempRequest.userAddress;
        uint256 shares = tempRequest.amount;
        uint256 userSwappedAmount = ((tempPool.toLiquidAmount +
            tempPool.toLockedAmount) * shares) / tempPool.originalAmount;
        uint256 userLeftoverAmount = (tempPool.fromLiquidAmount * shares) /
            tempPool.originalAmount;

        uint256 allowanceAssetTo = IERC20Metadata(tempPool.assetTo).allowance(
            address(this),
            user
        );
        bool isSuccess = IERC20Metadata(tempPool.assetTo).approve(
            user,
            allowanceAssetTo +
                Compute._unscaleAssetAmountToOriginal(
                    tempPool.assetTo,
                    userSwappedAmount
                )
        );
        if (isSuccess) {
            isSuccess = IERC20Metadata(tempPool.assetFrom).approve(
                user,
                IERC20Metadata(tempPool.assetFrom).allowance(
                    address(this),
                    user
                ) +
                    Compute._unscaleAssetAmountToOriginal(
                        tempPool.assetFrom,
                        userLeftoverAmount
                    )
            );
            if (!isSuccess) {
                //if failed, it means than we can't decrease allowance for user,
                //so user can withdraw more than we expected => should revert dispite of loop
                require(
                    IERC20Metadata(tempPool.assetTo).approve(
                        user,
                        allowanceAssetTo
                    ),
                    "Can't return approve to initial state"
                );
            }
        }
        return (user, userSwappedAmount, userLeftoverAmount, isSuccess);
    }

    /** 
        @dev utility function that calls receiveSwappedFunds in Trufin Vaults,
        with the following information - 
        1. requestId
        2. aggregateSwapRate (S1)
        3. midSwapRate (S2)
        4. amount swapped (in assetTo)
        5. amount not swapped (in assetFrom)
        @param requestId of the request for which receiveSwappedFunds has to be called
        @param user address of the user the call will be made to
        @param userSwappedAmount amount of funds swapped successfully ( in assetTo)
        @param userLeftoverAmount amount of funds not swapped ( in assetFrom)

    */
    function _callReceiveFunds(
        bytes32 requestId,
        address user,
        uint256 userSwappedAmount,
        uint256 userLeftoverAmount,
        SwapPool memory tempPool
    ) internal {
        ITrufinVault(user).receiveSwappedFunds(
            requestId,
            tempPool.aggregateSwapRate, // 10**18
            tempPool.midSwapRate, //10**18
            Compute._unscaleAssetAmountToOriginal(
                tempPool.assetTo,
                userSwappedAmount
            ),
            Compute._unscaleAssetAmountToOriginal(
                tempPool.assetFrom,
                userLeftoverAmount
            )
        );
    }

    // ====================================================================
    //                          VAULT EXTERNAL FUNCTIONS
    // ====================================================================

    /** 
        @notice This function is used to deposit funds to be swapped
        @notice remember to approve _amount of tokens for the swapVault before depositing
        @notice user should be whitelisted as a vault in the master whitelist
        @param _poolId The Id of the swapPool you want to participate in
        @param _amount The amount of tokens you want to deposit (denominated in assetFrom)
    */
    function deposit(bytes32 _poolId, uint256 _amount)
        external
        nonReentrant
        onlyDuringPoolState(_poolId, PoolStatus.UNLOCKED)
        returns (bytes32)
    {
        require(
            IMasterWhitelist(whitelistAddress).isVaultWhitelisted(msg.sender),
            "Not Allowed To Deposit"
        );
        require(_amount > 0, "Amount can't be 0");
        SwapPool memory tempPool = pools[_poolId];

        // An approve() by the msg.sender is required beforehand
        require(
            //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
            IERC20Metadata(tempPool.assetFrom).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Failed to recieve funds"
        );
        emit DepositAsset(tempPool.assetFrom, msg.sender, _amount);

        uint256 scaledAmount = Compute._scaleAssetAmountTo18(
            tempPool.assetFrom,
            _amount
        );

        pools[_poolId].originalAmount += scaledAmount;
        bytes32 requestId = getRequestId(_poolId, msg.sender);
        if (swapRequests[requestId].amount == 0) {
            pools[_poolId].requestIds.push(requestId);
            swapRequests[requestId].userAddress = msg.sender;
            swapRequests[requestId].poolId = _poolId;
        }

        swapRequests[requestId].amount += scaledAmount;
        return requestId;
    }

    /** 
        @notice This function is called by market makers to take a swap
        @notice correct amount of the asset must be approved before calling this function
        @notice MM can use any wallet address that is associated to their MMId in the master whitelist
        @param orderId Id of the order, which MM is trying to fill
    */
    function fillSwapOrder(uint256 orderId) external nonReentrant {
        SwapOrder memory order = swapOrders[orderId];
        require(swapOrders[orderId].amount > 0, "Order amount can't be 0");
        require(
            IMasterWhitelist(whitelistAddress).getIdMM(msg.sender) ==
                order.MMId,
            "MM address does not match"
        );

        SwapPool memory pool = pools[order.poolId];
        address transferAsset;
        address approveAsset;

        if (!order.isReverseOrder) {
            // If it is a forward order
            transferAsset = pool.assetTo;
            approveAsset = pool.assetFrom;

            pools[order.poolId].fromLiquidAmount -= order.amount;
            pools[order.poolId].totalAmountSwappedinFrom += order.amount;
            pools[order.poolId].toLiquidAmount +=
                (order.amount * order.rate) /
                SPOT_RATE_MULTIPLIER;
        } else {
            // If it is a reverse order
            transferAsset = pool.assetFrom;
            approveAsset = pool.assetTo;
            pools[order.poolId].fromLiquidAmount +=
                (order.amount * order.rate) /
                SPOT_RATE_MULTIPLIER;
            pools[order.poolId].totalAmountSwappedinFrom -=
                (order.amount * order.rate) /
                SPOT_RATE_MULTIPLIER;
            pools[order.poolId].toLiquidAmount += order.amount;
        }
        _setAggregateSwapRate(order.poolId);
        _deleteSwapOrder(order.poolId, orderId);
        uint256 unscaledAmount = Compute._unscaleAssetAmountToOriginal(
            transferAsset,
            (order.amount * order.rate) / SPOT_RATE_MULTIPLIER
        );
        emit DepositAsset(transferAsset, msg.sender, unscaledAmount);
        require(
            IERC20Metadata(transferAsset).transferFrom(
                msg.sender,
                address(this),
                unscaledAmount
            ),
            "Failed to recieve funds"
        );
        // makes direct transfer instead of approve for MM for UX
        require(
            IERC20Metadata(approveAsset).transfer(
                msg.sender,
                Compute._unscaleAssetAmountToOriginal(
                    approveAsset,
                    order.amount
                )
            ),
            "Failed to send funds to MM"
        );
        emit FilledSwapOrder(orderId, order.poolId, order.MMId);
    }

    /** 
        @notice Function to withdraw unswapped funds if they user't been locked yet
        @notice _amount number of tokens are approved from the vault,
        user has to complete withdrawal by calling safeTransferFrom in asset contract 
        @param requestId Id of the request user wants to withdraw from
        @param _amount amount of funds to withdraw from the swapRequest
    */
    function withdrawInstantly(bytes32 requestId, uint256 _amount)
        external
        nonReentrant
        onlyDuringPoolState(swapRequests[requestId].poolId, PoolStatus.UNLOCKED)
    {
        require(
            swapRequests[requestId].userAddress == msg.sender,
            "RequestId doesn't belong to sender"
        );

        bytes32 poolId = swapRequests[requestId].poolId;
        uint256 scaledAmount = Compute._scaleAssetAmountTo18(
            pools[poolId].assetFrom,
            _amount
        );
        require(
            swapRequests[requestId].amount >= scaledAmount,
            "Not enough funds"
        );

        swapRequests[requestId].amount -= scaledAmount;
        pools[poolId].originalAmount -= scaledAmount;
        if (swapRequests[requestId].amount == 0) {
            _deleteSwapRequest(poolId, requestId);
        }
        address assetAddress = pools[poolId].assetFrom;
        require(
            IERC20Metadata(assetAddress).approve(
                msg.sender,
                IERC20Metadata(assetAddress).allowance(
                    address(this),
                    msg.sender
                ) + _amount
            ),
            "Approve failed"
        );
    }

    function _withdrawFromPool(bytes32 poolId) private {
        //SwapPool memory tempPool = pools[poolId];
        require(pools[poolId].midSwapRate != 0, "Mid Swap Rate is Zero");
        //bytes32[] memory requestArr = tempPool.requestIds;
        uint256 requestArrLength = pools[poolId].requestIds.length;
        for (uint256 i = 0; i < requestArrLength; ) {
            bytes32 id = pools[poolId].requestIds[i];
            address user;
            uint256 swapped;
            uint256 leftover;
            bool isSuccess;
            //slither-disable-next-line reentrancy-no-eth
            (user, swapped, leftover, isSuccess) = _withdraw(id, pools[poolId]);
            if (isSuccess) {
                _callReceiveFunds(id, user, swapped, leftover, pools[poolId]);
                delete swapRequests[id];
                unchecked {
                    --requestArrLength;
                }
                pools[poolId].requestIds[i] = pools[poolId].requestIds[
                    requestArrLength
                ];
                pools[poolId].requestIds.pop();
            } else {
                unchecked {
                    ++i;
                }
            }
        }
    }

    // ====================================================================
    //                          OWNER UTILITY FUNCTIONS
    // ====================================================================

    /** @dev called at the end of the epoch, to return funds to all the users of the pool
        and the oppPool.
        @dev this function will approve withdrawals, and call receiveSwappedFunds for all the users
        in both pools and oppPools.
        @param poolId Id of either the pool or the oppPool
    */

    function distributeFundsAutomatically(bytes32 poolId)
        public
        onlyOwner
        onlyDuringPoolState(poolId, PoolStatus.LOCKED)
        nonReentrant
    {
        bytes32 oppPoolId = getPoolId(
            pools[poolId].assetTo,
            pools[poolId].assetFrom
        );
        //slither-disable-next-line reentrancy-no-eth
        _withdrawFromPool(poolId);
        _withdrawFromPool(oppPoolId);

        require(
            _changePoolStatus(poolId, PoolStatus.WAITING_FOR_RATE),
            "Pool Status Change Failed"
        );
        emit PoolStatusChange(poolId, PoolStatus.WAITING_FOR_RATE);
    }

    /**
        @dev function to add the swap Pool of an asset pair
        @dev both pool and oppPool will be created together
        @param swapFrom address of asset from which the swap will be made
        @param swapTo address of asset to which the original asset will be swapped
    */
    function addSwapPool(address swapFrom, address swapTo) external onlyOwner {
        require(
            IMasterWhitelist(whitelistAddress).isAssetWhitelisted(swapFrom),
            "AssetFrom Not Whitelisted"
        );
        require(
            IMasterWhitelist(whitelistAddress).isAssetWhitelisted(swapTo),
            "AssetTo Not Whitelisted"
        );
        SwapPool memory newPool = SwapPool(
            PoolStatus.WAITING_FOR_RATE,
            swapFrom,
            swapTo,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            new bytes32[](0),
            new uint256[](0)
        );
        SwapPool memory oppPool = SwapPool(
            PoolStatus.WAITING_FOR_RATE,
            swapTo,
            swapFrom,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            new bytes32[](0),
            new uint256[](0)
        );
        require(
            pools[getPoolId(swapFrom, swapTo)].status == PoolStatus.INACTIVE,
            "Pool Already Exists"
        );
        require(
            pools[getPoolId(swapTo, swapFrom)].status == PoolStatus.INACTIVE,
            "Pool Already Exists"
        );
        pools[getPoolId(swapFrom, swapTo)] = newPool;
        pools[getPoolId(swapTo, swapFrom)] = oppPool;

        emit AddSwapPool(
            getPoolId(swapFrom, swapTo),
            getPoolId(swapTo, swapFrom),
            swapFrom,
            swapTo
        );
    }

    /**
        @dev function to remove the swap Pools of an asset pair
        @dev both pool and oppPool will be removed together
        @notice both pool and oppPool should be have a status WAITING_FOR_RATE
        @param poolId Id of either pool or oppPool
    */
    function removeSwapPool(bytes32 poolId)
        external
        onlyOwner
        onlyDuringPoolState(poolId, PoolStatus.WAITING_FOR_RATE)
    {
        bytes32 oppPoolId = getPoolId(
            pools[poolId].assetTo,
            pools[poolId].assetFrom
        );
        require(
            pools[oppPoolId].status == PoolStatus.WAITING_FOR_RATE,
            "Opposite Pool is not waiting for rate"
        );
        require(
            _changePoolStatus(poolId, PoolStatus.INACTIVE),
            "Pool Status Change Failed"
        );
        emit PoolStatusChange(poolId, PoolStatus.INACTIVE);
        delete pools[oppPoolId];
        delete pools[poolId];
        emit DeleteSwapPool(poolId, oppPoolId);
    }

    /**
        @dev function to unlock pools
        @dev both pool and oppPool will be unlocked together
        @param poolId Id of either pool or oppPool
    */
    function unlockPool(bytes32 poolId)
        public
        onlyOwner
        onlyDuringPoolState(poolId, PoolStatus.WAITING_FOR_RATE)
    {
        // rate should not be zero
        require(
            _changePoolStatus(poolId, PoolStatus.UNLOCKED),
            "Pool Status Change Failed"
        );
        emit PoolStatusChange(poolId, PoolStatus.UNLOCKED);
    }

    /**
        @dev function to lock pools 
        @dev both pool and oppPool will be unlocked together
        @param poolId Id of either pool or oppPool
    */
    function lockPool(bytes32 poolId)
        external
        onlyOwner
        onlyDuringPoolState(poolId, PoolStatus.UNLOCKED)
    {
        require(
            _changePoolStatus(poolId, PoolStatus.LOCKED),
            "Pool Status Change Failed"
        );
        emit PoolStatusChange(poolId, PoolStatus.LOCKED);
    }

    /**
        @notice function to create a swap order for an external MM
        @param _isReverseOrder bool: true if this is a reverse order i.e swap is from (assetTo-> assetFrom)
        else false
        @param _poolId the pool for which the order is being created
        @param _MMId the ID for the approved MM who can fill this order
        @param  _amount should have decimals in assetFrom for forward order, and assetTo for reverse order
        @param _rate should be in correct decimals according to SPOT_RATE_MULTIPLIER (currently 18)
    */
    function createSwapOrder(
        bool _isReverseOrder,
        bytes32 _poolId,
        bytes32 _MMId,
        uint256 _amount,
        uint256 _rate
    ) external onlyOwner onlyDuringPoolState(_poolId, PoolStatus.LOCKED) {
        require(_amount > 0, "Order Amount can't be zero");
        uint256 scaledAmount;
        if (_isReverseOrder) {
            scaledAmount = Compute._scaleAssetAmountTo18(
                pools[_poolId].assetTo,
                _amount
            );
            require(
                pools[_poolId].toLiquidAmount >= scaledAmount,
                "amount is too large"
            );
            swapOrders[orderCounter].isReverseOrder = true;
        } else {
            scaledAmount = Compute._scaleAssetAmountTo18(
                pools[_poolId].assetFrom,
                _amount
            );
            require(
                pools[_poolId].fromLiquidAmount >= scaledAmount,
                "amount is too large"
            );
            swapOrders[orderCounter].isReverseOrder = false;
        }

        swapOrders[orderCounter].MMId = _MMId;
        swapOrders[orderCounter].poolId = _poolId;
        swapOrders[orderCounter].amount = scaledAmount;
        swapOrders[orderCounter].rate = _rate;
        pools[_poolId].orderIds.push(orderCounter);
        emit CreatedSwapOrder(
            orderCounter,
            _poolId,
            _isReverseOrder,
            _MMId,
            scaledAmount,
            _rate
        );
        orderCounter++;
    }

    /**
        @notice function set the internal swap rate (S) for a pool
        @notice internal swap rate for both pool and oppPool is set together
        @param poolId Id of the pool for which rate is being set
        @param rate swap rate scaled according to SPOT_RATE_MULTIPLIER (currently 18) 
        if rate is X, this means (X/SPOT_RATE_MULTIPLIER) amount of assetTo per AssetFrom
    */
    function setInternalSwapRate(bytes32 poolId, uint256 rate)
        public
        onlyOwner
        onlyDuringPoolState(poolId, PoolStatus.WAITING_FOR_RATE)
    {
        address assetTo = pools[poolId].assetTo;
        address assetFrom = pools[poolId].assetFrom;
        bytes32 oppPoolId = getPoolId(assetTo, assetFrom);
        uint256 oppRate = (SPOT_RATE_MULTIPLIER * SPOT_RATE_MULTIPLIER) / rate;
        pools[poolId].internalSwapRate = rate;
        pools[oppPoolId].internalSwapRate = oppRate;
    }

    /**
        @notice utility function to set the internal swap rate and unlock in the same transaction
        @notice both pool and oppPool are set and unlocked
        @param poolId Id of the pool
        @param rate swap rate scaled according to SPOT_RATE_MULTIPLIER (currently 18)  
        if rate is X, this means (X/SPOT_RATE_MULTIPLIER) amount of assetTo per AssetFrom
    */
    function setSwapRateAndUnlock(bytes32 poolId, uint256 rate)
        external
        onlyOwner
        onlyDuringPoolState(poolId, PoolStatus.WAITING_FOR_RATE)
    {
        setInternalSwapRate(poolId, rate);
        unlockPool(poolId);
    }

    /**
        @notice function set the MID swap rate (S2) for a pool
        @notice mid swap rate for both pool and oppPool is set together
        @param poolId Id of the pool for which rate is being set
        @param rate swap rate scaled according to SPOT_RATE_MULTIPLIER (currently 18) 
        if rate is X, this means (X/SPOT_RATE_MULTIPLIER) amount of assetTo per AssetFrom
    */
    function setMidSwapRate(bytes32 poolId, uint256 rate)
        external
        onlyOwner
        onlyDuringPoolState(poolId, PoolStatus.LOCKED)
    {
        address assetTo = pools[poolId].assetTo;
        address assetFrom = pools[poolId].assetFrom;
        bytes32 oppPoolId = getPoolId(assetTo, assetFrom);
        pools[poolId].midSwapRate = rate;
        pools[oppPoolId].midSwapRate =
            (SPOT_RATE_MULTIPLIER * SPOT_RATE_MULTIPLIER) /
            rate;
    }

    /**
        @notice function that allows owner to close a swapOrder after creating it
        @param orderId Id of the order to be closed
    */
    function closeSwapOrder(uint256 orderId)
        external
        onlyOwner
        onlyDuringPoolState(swapOrders[orderId].poolId, PoolStatus.LOCKED)
    {
        _deleteSwapOrder(swapOrders[orderId].poolId, orderId);
    }

    /**
        @notice function to close all remaining orders in the pool
        @param poolId Id of the pool whose orders are to be closed
    */
    function closeAllPoolOrders(bytes32 poolId)
        external
        onlyOwner
        onlyDuringPoolState(poolId, PoolStatus.LOCKED)
    {
        uint256 orderIdsLength = pools[poolId].orderIds.length;
        for (uint256 i = 0; i < orderIdsLength; ) {
            //slither-disable-next-line costly-loop
            delete swapOrders[pools[poolId].orderIds[i]];
            unchecked {
                ++i;
            }
        }
        pools[poolId].orderIds = new uint256[](0);
        emit CloseAllPoolOrders(poolId);
    }

    /**
        @notice function to reset the poolStatus to WAITING_FOR_RATE
        @notice all pending requests and all pending orders for the pool
        have to be closed before calling this function
        @param poolId Id of the pool whose status has to be changed
    */
    function resetPoolState(bytes32 poolId) external onlyOwner {
        require(
            _changePoolStatus(poolId, PoolStatus.WAITING_FOR_RATE),
            "Pool Status Change Failed"
        );
        emit PoolStatusChange(poolId, PoolStatus.WAITING_FOR_RATE);
    }

    // ====================================================================
    //                          EMERGENCY FUNCTIONS
    // ====================================================================

    /** 
        @notice function to declare emergency to withdraw funds
        should be called if owners don't unlock a pool within 72 hours
        @param poolId is the Id of the pool for which emergency is being declared
    */
    function declareEmergency(bytes32 poolId) external {
        require(
            block.timestamp >=
                pools[poolId].lastLockedTime + EMERGENCY_WITHDRAW_TIME,
            "Not in Emergency Period"
        );
        require(
            _changePoolStatus(poolId, PoolStatus.EMERGENCY),
            "Pool Status Change Failed"
        );
        emit PoolStatusChange(poolId, PoolStatus.EMERGENCY);
    }

    /**
        @notice function to withdraw funds from pool in emergency state
        @notice msg.sender should be the same as request.userAddress
        @param requestId is the request Id for which you want to withdraw the funds
        @dev every Trufin Vault should have a funtion emergency withdraw,
        that can be called by any user. This emergency withdraw function would then call 
        the swap vault's emergency withdraw. msg.sender should be the Trufin Vault not the
        original user.
    */
    function emergencyWithdraw(bytes32 requestId)
        external
        onlyDuringPoolState(
            (swapRequests[requestId].poolId),
            PoolStatus.EMERGENCY
        )
        nonReentrant
    {
        SwapRequest memory tempRequest = swapRequests[requestId];
        require(
            msg.sender == tempRequest.userAddress,
            "Access to Request Denied"
        );
        SwapPool memory tempPool = pools[tempRequest.poolId];
        //slither-disable-next-line reentrancy-no-eth
        (, , , bool isSuccess) = _withdraw(requestId, tempPool);
        require(isSuccess, "Can't withdraw funds");
        _deleteSwapRequest(tempRequest.poolId, requestId);

        emit EmergencyWithdraw(tempRequest.poolId, requestId);
    }

    /** 
        @notice function to distribute funds one by one for each request ID
        Should be called for all request Ids in case one of the TrufinVaults starts 
        throwing errors when receiveSwappedFunds is called and distributeFundsAutomatically reverts
        @param requestId is the Id of the request whose funds are to be distributed
    */
    function distributeFundsManually(bytes32 requestId)
        external
        onlyOwner
        onlyDuringPoolState(swapRequests[requestId].poolId, PoolStatus.LOCKED)
        nonReentrant
    {
        SwapRequest memory tempRequest = swapRequests[requestId];
        require(
            pools[tempRequest.poolId].midSwapRate != 0,
            "Mid Swap Rate is Zero"
        );
        SwapPool memory tempPool = pools[tempRequest.poolId];
        address user;
        uint256 swapped;
        uint256 leftover;
        bool isSuccess;
        //slither-disable-next-line reentrancy-no-eth
        (user, swapped, leftover, isSuccess) = _withdraw(requestId, tempPool);
        require(isSuccess, "Can't withdraw funds");
        _callReceiveFunds(requestId, user, swapped, leftover, tempPool);
        _deleteSwapRequest(tempRequest.poolId, requestId);
    }

    /** 
        @notice utility function to withdraw funds for a vault without calling
        receiveSwappedFunds for it. This function will not revert even for vaults that
        throws errors on a normal withdraw.
        @param requestId is the Id of the request whose funds are to be distributed
    */
    function distributeFundsForcefully(bytes32 requestId)
        external
        onlyOwner
        onlyDuringPoolState(swapRequests[requestId].poolId, PoolStatus.LOCKED)
        nonReentrant
    {
        SwapRequest memory tempRequest = swapRequests[requestId];
        require(
            pools[tempRequest.poolId].midSwapRate != 0,
            "Mid Swap Rate is Zero"
        );
        SwapPool memory tempPool = pools[tempRequest.poolId];
        //slither-disable-next-line reentrancy-no-eth
        (, , , bool isSuccess) = _withdraw(requestId, tempPool);
        require(isSuccess, "Can't withdraw funds");
        _deleteSwapRequest(tempRequest.poolId, requestId);
    }

    // ====================================================================
    //                              GETTERS
    // ====================================================================
    function getPoolById(bytes32 poolId)
        external
        view
        returns (SwapPool memory)
    {
        return pools[poolId];
    }

    function getOrderById(uint256 orderId)
        external
        view
        returns (SwapOrder memory)
    {
        return swapOrders[orderId];
    }

    function getPoolId(address assetFrom, address assetTo)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(assetFrom, assetTo));
    }

    function getRequestId(bytes32 poolId, address user)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(poolId, user));
    }

    function getInternalSwapRate(bytes32 poolId)
        external
        view
        returns (uint256)
    {
        return pools[poolId].internalSwapRate;
    }

    function getPoolRequestArrLength(bytes32 poolId)
        external
        view
        returns (uint256)
    {
        return pools[poolId].requestIds.length;
    }

    function getPoolOrderArrLength(bytes32 poolId)
        external
        view
        returns (uint256)
    {
        return pools[poolId].orderIds.length;
    }

    function getPoolRequestArrValue(bytes32 poolId, uint256 index)
        external
        view
        returns (bytes32)
    {
        return pools[poolId].requestIds[index];
    }

    function getPoolOrderArrValue(bytes32 poolId, uint256 index)
        external
        view
        returns (uint256)
    {
        return pools[poolId].orderIds[index];
    }

    function getAssetFromRequestId(bytes32 requestId)
        external
        view
        returns (
            address,
            address,
            bytes32
        )
    {
        bytes32 poolId = swapRequests[requestId].poolId;
        address from = pools[poolId].assetFrom;
        address to = pools[poolId].assetTo;
        return (from, to, getPoolId(from, to));
    }

    // ====================================================================
    //                              SETTERS
    // ====================================================================
    function setWhitelist(address _whitelist) external onlyOwner {
        require(_whitelist != address(0), "Whitelist can't be zero address");
        whitelistAddress = _whitelist;
    }
}

/* Swap Vault Workflow -->
    1. Owner sets a spot rate for a given pool, epoch begins
    2. Vaults are allowed to deposit until owner calls lock pool
    3. Amount of external swap is decided by the internal spot rate S
    4. Owner creates as many swap orders as he wants with the amount left for external swap
    5. Owner manually unlocks pools by redistributing the swap
    6. pool now goes back to waiting_for_rate state 
    7. pool can only be reset if there are no pending swapOrders or swapRequests
*/

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/// @title
/// @author Tanishk Goyal
interface ITrufinVault {
    function receiveSwappedFunds(
        bytes32 _requestId,
        uint256 spotRate,
        uint256 midSpotRate,
        uint256 amountSwapped,
        uint256 amountLeftover
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface ISwapVault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    enum PoolStatus {
        INACTIVE,
        WAITING_FOR_RATE,
        UNLOCKED,
        LOCKED,
        EMERGENCY
    }

    // toLockedAmount -- never change
    // fromLiquidAmount
    // toLiquidAmount

    struct SwapPool {
        PoolStatus status; // Current Status of the Pool
        address assetFrom; // Address of the asset which needs to be swapped
        address assetTo; // Address of the asset which the assetFrom is being swapped to
        uint256 lastLockedTime; // the most recent time this pool was locked
        uint256 fromLiquidAmount; // amount of liquid funds in the pool in assetFrom
        uint256 toLiquidAmount; // amount of liquid funds in the pool in assetTo
        uint256 originalAmount; // total amount of deposits in the pool in assetFrom
        uint256 internalSwapRate; // Spot Rate S, at which internal swap happens
        uint256 aggregateSwapRate; // Spot Rate S1, which is aggregated from both internal and external swaps
        uint256 toLockedAmount; // Total Amount of assetTo which was swapped in internal Rebalancing
        uint256 totalAmountSwappedinFrom; // Total amount of assetFrom which was swapped successfully
        uint256 midSwapRate; // Mid Swap Rate S2
        bytes32[] requestIds; // Array of requestIds pending in the pool
        uint256[] orderIds; // Array of orderIds pending in the pool
    }

    // User will receive
    // totalAmountSwappedinFrom * aggregateSwapRate = amount of assetTo
    // originalAmount - totalAmountSwappedinFrom =  amount of assetFrom
    // aggregateSwapRate
    // midSwapRate
    struct SwapRequest {
        address userAddress; // Address of the user who made the deposit
        bytes32 poolId; // Id of the pool to which the deposit belongs
        uint256 amount; // Amount of deposit (in assetFrom)
    }

    struct SwapOrder {
        bool isReverseOrder; // True if swap is from assetTo to assetFrom
        bytes32 MMId; // ID of MM who can fill swap order
        bytes32 poolId; // ID of pool from which funds are swapped
        uint256 amount; // Amount of funds to be swapped ( in assetFrom or assetTo depending on isReverseOrder)
        uint256 rate; // Swap Rate at which swap is offered
    }

    function getPoolId(address assetFrom, address assetTo)
        external
        returns (bytes32);

    function deposit(bytes32 _poolId, uint256 _amount)
        external
        returns (bytes32);

    function fillSwapOrder(uint256 orderId) external;

    function withdrawInstantly(bytes32 requestId, uint256 _amount) external;

    function emergencyWithdraw(bytes32 requestId) external;

    function getInternalSwapRate(bytes32 poolId)
        external
        view
        returns (uint256);

    function getAssetFromRequestId(bytes32 requestId)
        external
        view
        returns (
            address,
            address,
            bytes32
        );

    /************************************************
     *  EVENTS
     ***********************************************/
    event DepositAsset(address asset, address from, uint256 _amount);
    event PoolStatusChange(bytes32 indexed poolId, PoolStatus status);
    event ResetPool(bytes32 indexed poolId, PoolStatus status);
    event DeleteSwapRequest(bytes32 indexed poolId, bytes32 requestId);
    event AddSwapPool(
        bytes32 indexed poolId,
        bytes32 indexed oppPoolId,
        address from,
        address to
    );
    event CreatedSwapOrder(
        uint256 indexed orderId,
        bytes32 indexed poolId,
        bool isReverseOrder,
        bytes32 mmId,
        uint256 amount,
        uint256 rate
    );
    event FilledSwapOrder(
        uint256 indexed orderId,
        bytes32 indexed poolId,
        bytes32 mmId
    );
    event DeleteSwapOrder(bytes32 indexed poolId, uint256 orderId);
    event DeleteSwapPool(bytes32 indexed poolId, bytes32 indexed oppPoolId);
    event EmergencyWithdraw(bytes32 indexed poolId, bytes32 requestId);
    event CloseAllPoolOrders(bytes32 indexed poolId);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

/**
 * @title Master Whitelist Interface
 * @notice Interface for contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
interface IMasterWhitelist {
    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool);

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool);

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a User is in the Blacklist
     * @param _user is the User address
     */
    function isUserBlacklisted(address _user) external view returns (bool);

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool);

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (bytes32);

    function isLawyer(address _lawyer) external view returns (bool);

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     * @param _auctionId is not needed for now
     * @param _callData is not needed for now
     */
    function isAllowed(
        address _user,
        uint256 _auctionId,
        bytes calldata _callData
    ) external view returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./WadRay.sol";

library Compute {
    using WadRayMath for uint256;

    function mulPrice(
        uint256 _price1,
        uint8 _decimals1,
        uint256 _price2,
        uint8 _decimals2,
        uint8 _outDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier = 18 - _decimals1;
        uint8 multiplier2 = 18 - _decimals2;
        uint8 outMultiplier = 18 - _outDecimals;

        _price1 *= 10**multiplier;
        _price2 *= 10**multiplier2;

        uint256 output = _price1.wadMul(_price2);

        return output / (10**outMultiplier);
    }

    function divPrice(
        uint256 _numerator,
        uint8 _numeratorDecimals,
        uint256 _denominator,
        uint8 _denominatorDecimals,
        uint8 _outDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier = 18 - _numeratorDecimals;
        uint8 multiplier2 = 18 - _denominatorDecimals;
        uint8 outMultiplier = 18 - _outDecimals;
        _numerator *= 10**multiplier;
        _denominator *= 10**multiplier2;

        uint256 output = _numerator.wadDiv(_denominator);
        return output / (10**outMultiplier);
    }

    function scaleDecimals(
        uint256 value,
        uint8 _oldDecimals,
        uint8 _newDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier;
        if (_oldDecimals > _newDecimals) {
            multiplier = _oldDecimals - _newDecimals;
            return value / (10**multiplier);
        } else {
            multiplier = _newDecimals - _oldDecimals;
            return value * (10**multiplier);
        }
    }

    function wadDiv(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        return value1.wadDiv(value2);
    }

    function wadMul(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        return value1.wadMul(value2);
    }

    function _scaleAssetAmountTo18(address _asset, uint256 _originalAmount)
        internal
        view
        returns (uint256)
    {
        uint8 decimals = IERC20Metadata(_asset).decimals();
        uint256 scaledAmount;
        if (decimals <= 18) {
            scaledAmount = _originalAmount * (10**(18 - decimals));
        } else {
            scaledAmount = _originalAmount / (10**(decimals - 18));
        }
        return scaledAmount;
    }

    function _unscaleAssetAmountToOriginal(
        address _asset,
        uint256 _scaledAmount
    ) internal view returns (uint256) {
        uint8 decimals = IERC20Metadata(_asset).decimals();
        uint256 unscaledAmount;
        if (decimals <= 18) {
            unscaledAmount = _scaledAmount / (10**(18 - decimals));
        } else {
            unscaledAmount = _scaledAmount * (10**(decimals - 18));
        }
        return unscaledAmount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library WadRayMath {
    using SafeMath for uint256;

    uint256 public constant WAD = 1e18;
    uint256 public constant halfWAD = WAD / 2;

    uint256 public constant RAY = 1e27;
    uint256 public constant halfRAY = RAY / 2;

    uint256 public constant WAD_RAY_RATIO = 1e9;

    function ray() public pure returns (uint256) {
        return RAY;
    }

    function wad() public pure returns (uint256) {
        return WAD;
    }

    function halfRay() public pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() public pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) public pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) public pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) public pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) public pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }

    //solium-disable-next-line
    function rayPow(uint256 x, uint256 n) public pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}