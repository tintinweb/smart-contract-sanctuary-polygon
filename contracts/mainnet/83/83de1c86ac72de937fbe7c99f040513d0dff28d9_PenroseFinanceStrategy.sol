// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./utils/SafeERC20.sol";
import "./utils/TransferHelper.sol";

import "./interfaces/IUserProxy.sol";
import "./interfaces/IUniversalSingleSidedLiquidity.sol";
import "./interfaces/IPenroseLens.sol";
import "./interfaces/IStakingRewards.sol";
import "./interfaces/IRoute.sol";

contract PenroseFinanceStrategy is Ownable, ReentrancyGuard, IRoute {
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public asset; //DystopiaLP address
    IERC20 public rewardA; //DYST token
    IERC20 public rewardB; //PEN token
    IUserProxy public userProxyInterfaceContract; //UserProxy Interface Contract contract of Penrose Finance
    address public ygnConverter; // YGN Converter address to receive DYST
    address public vault; //Vault Address
    IUniversalSingleSidedLiquidity public universalOneSidedFarm;
    uint256 public reserve = 0;
    uint256 public feepercentage = 75;
    IPenroseLens public PenroseLens =
        IPenroseLens(0x1432c3553FDf7FBD593a84B3A4d380c643cbf7a2);

    bool public isStrategyEnabled = true;
    address public toToken;
    Route[] public swapPathForToTokenRewardA;
    Route[] public swapPathForToTokenRewardB;
    uint256 public rewardsThresholdAmountRewardA;
    uint256 public rewardsThresholdAmountRewardB;

    event SetYGNConverter(address indexed owner, address indexed ygnConverter);
    event RescueAsset(address owner, uint256 rescuedAssetAmount);

    modifier ensureNonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), "No zero address");
        _;
    }

    modifier ensureValidTokenAddress(address _token) {
        require(_token != address(0), "No zero address");
        require(_token == address(asset), "Invalid token");
        _;
    }

    /**
     * @notice Creates a new PenroseFinance Strategy Contract
     * @param _asset Dystopia LP address
     * @param _rewardA DYST token address
     * @param _rewardB PEN token address
     * @param _userProxyInterfaceContract UserProxy Interface Contract contract of Penrose Finance
     * @param _ygnConverter fee address for transferring residues and reward tokens (DYST)
     * @param _universalOneSidedFarm universal one sided farm contract address
     * @param _toToken token address to convert rewards to
     * @param _swapPathForToTokenRewardA swap path for rewardA to toToken
     * @param _swapPathForToTokenRewardB swap path for rewardB to toToken
     * @param _rewardsThresholdAmountRewardA threshold amount for rewardA to convert to toToken
     * @param _rewardsThresholdAmountRewardB threshold amount for rewardB to convert to toToken
     * @dev deployer of contract is set as owner
     */
    constructor(
        IERC20 _asset,
        IERC20 _rewardA,
        IERC20 _rewardB,
        IUserProxy _userProxyInterfaceContract,
        address _ygnConverter,
        IUniversalSingleSidedLiquidity _universalOneSidedFarm,
        address _toToken,
        Route[] memory _swapPathForToTokenRewardA,
        Route[] memory _swapPathForToTokenRewardB,
        uint256 _rewardsThresholdAmountRewardA,
        uint256 _rewardsThresholdAmountRewardB
    ) {
        asset = _asset;

        rewardA = _rewardA;
        rewardB = _rewardB;
        userProxyInterfaceContract = _userProxyInterfaceContract;
        ygnConverter = _ygnConverter;
        universalOneSidedFarm = _universalOneSidedFarm;
        toToken = _toToken;
        require(
            _swapPathForToTokenRewardA.length > 0 &&
                _swapPathForToTokenRewardB.length > 0,
            "Swap Path is incorrrect/empty"
        );
        for (uint256 i; i < _swapPathForToTokenRewardA.length; ++i) {
            swapPathForToTokenRewardA.push(_swapPathForToTokenRewardA[i]);
        }
        for (uint256 i; i < _swapPathForToTokenRewardB.length; ++i) {
            swapPathForToTokenRewardB.push(_swapPathForToTokenRewardB[i]);
        }
        rewardsThresholdAmountRewardA = _rewardsThresholdAmountRewardA;
        rewardsThresholdAmountRewardB = _rewardsThresholdAmountRewardB;

        TransferHelper.safeApprove(
            address(rewardA),
            address(universalOneSidedFarm),
            type(uint256).max
        );

        TransferHelper.safeApprove(
            address(rewardB),
            address(universalOneSidedFarm),
            type(uint256).max
        );
    }

    /**
     * @notice sets/updates the vault address
     * @param _vault vault Address that deposits into this strategy
     * @dev Only owner can call and update the Vault
     **/
    function setVault(address _vault)
        public
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(_vault)
    {
        vault = _vault;
    }

    /**
     * @notice Updates the Strategy Mode for the strategy
     * @param _isStrategyEnabled bool flag to enable disable strategy
     * @dev Only owner can call and update the strategy mode
     */
    function updateStrategyMode(bool _isStrategyEnabled)
        external
        onlyOwner
        nonReentrant
    {
        isStrategyEnabled = _isStrategyEnabled;
    }

    /**
     * @notice Updates the PenroseLens Contract used by Penrose Finance
     * @param _penroseLens Address of the PenroseLens Interface Contract
     *@dev Only owner can call and update the penroseLens address
     **/

    function updatePenroseLensContract(address _penroseLens) public onlyOwner {
        PenroseLens = IPenroseLens(_penroseLens);
    }

    /**
     * @notice Updates the UserProxy Interface Contract used by Penrose Finance
     * @param _userProxyInterfaceContract Address of the UserProxy Interface Contract
     * @dev Only owner can call and update the UserProxy Interface Contract address
     */
    function updateUserProxyInterfaceContract(
        IUserProxy _userProxyInterfaceContract
    )
        external
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(address(_userProxyInterfaceContract))
    {
        userProxyInterfaceContract = _userProxyInterfaceContract;
    }

    /**
     * @notice Updates the Dystopia LP Token Address.
     * @param _asset Address of the Dystopia LP
     * @dev Only owner can call and update the Dystopia LP address
     */
    function updateAsset(IERC20 _asset)
        external
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(address(_asset))
    {
        asset = _asset;
    }

    /**
     * @notice Can be used by the owner to update the address for reward token
     * @param _rewardA ERC20 address for the new reward token
     * @param _rewardB ERC20 address for the new reward token
     * @dev Only owner can call and update the rewardToken.
     */
    function updateRewardToken(IERC20 _rewardA, IERC20 _rewardB)
        external
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(address(_rewardA))
        ensureNonZeroAddress(address(_rewardB))
    {
        rewardA = _rewardA;
        rewardB = _rewardB;
    }

    /**
     * @notice Updates single sided liquidity contract
     * @param _universalOneSidedFarm new contract address
     * @dev Only owner can call and update the  singlesidedliquidity contract
     */
    function updateUniversalSingleSidedLiquidityContract(
        IUniversalSingleSidedLiquidity _universalOneSidedFarm
    ) public onlyOwner nonReentrant {
        universalOneSidedFarm = _universalOneSidedFarm;
    }

    /**
     * @notice Updates feepercentage  which is used in autocompounding
     * @param _feepercentage  new feepercentage
     * @dev Only owner can call and update the feepercentage
     */

    function updateFeePercentage(uint256 _feepercentage)
        public
        onlyOwner
        nonReentrant
    {
        feepercentage = _feepercentage;
    }

    /**
     * @notice Updates _ygnconvertor
     * @param _ygnConverter Address of convertor
     * @dev Only owner can call and update the ygnConverter
     */
    function setYGNConverter(address _ygnConverter)
        external
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(_ygnConverter)
    {
        ygnConverter = _ygnConverter;
        emit SetYGNConverter(_msgSender(), _ygnConverter);
    }

    /**
     * @notice Updates rewardsThresholdAmountRewardA
     * @param _rewardsThresholdAmountRewardA threshold amount for reward A
     * @dev Only owner can call and update the rewardsThresholdAmount
     */
    function updateRewardsThresholdAmountRewardA(
        uint256 _rewardsThresholdAmountRewardA
    ) public onlyOwner nonReentrant {
        rewardsThresholdAmountRewardA = _rewardsThresholdAmountRewardA;
    }

    /**
     * @notice Updates rewardsThresholdAmountRewardB
     * @param _rewardsThresholdAmountRewardB threshold amount for reward B
     * @dev Only owner can call and update the rewardsThresholdAmount
     */
    function updateRewardsThresholdAmountRewardB(
        uint256 _rewardsThresholdAmountRewardB
    ) public onlyOwner nonReentrant {
        rewardsThresholdAmountRewardB = _rewardsThresholdAmountRewardB;
    }

    /**
     * @notice Updates totoken
     * @param _toToken Address of totoken used in singlesidedliquidity contract
     * @dev Only owner can call and update the _totoken
     */

    function updateToToken(address _toToken)
        public
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(_toToken)
    {
        toToken = _toToken;
    }

    /**
     * @notice Updates SwapPathForToTokenRewardA
     * @param _swapPathForToTokenRewardA swap path for Reward TokenA
     * @dev Only owner can call and update the SwapPathForToTokenReward
     */
    function updateSwapPathForToTokenRewardA(
        Route[] memory _swapPathForToTokenRewardA
    ) public onlyOwner nonReentrant {
        require(
            _swapPathForToTokenRewardA.length > 0,
            "Swap Path is incorrrect/empty"
        );

        delete swapPathForToTokenRewardA;

        for (uint256 i = 0; i < _swapPathForToTokenRewardA.length; i++) {
            swapPathForToTokenRewardA[i] = _swapPathForToTokenRewardA[i];
        }
    }

    /**
     * @notice Updates SwapPathForToTokenRewardB
     * @param _swapPathForToTokenRewardB swap path for Reward TokenB
     * @dev Only owner can call and update the SwapPathForToTokenReward
     */
    function updateSwapPathForToTokenRewardB(
        Route[] memory _swapPathForToTokenRewardB
    ) public onlyOwner {
        require(
            _swapPathForToTokenRewardB.length > 0,
            "Swap Path is incorrrect/empty"
        );

        delete swapPathForToTokenRewardB;

        for (uint256 i = 0; i < _swapPathForToTokenRewardB.length; i++) {
            swapPathForToTokenRewardB[i] = _swapPathForToTokenRewardB[i];
        }
    }

    /**
     * @notice this function is used to get totalAssets in the contract
     */

    function totalAssets() external view returns (uint256 totalLPStaked) {
        if (isStrategyEnabled) {
            address ProxyAddress = PenroseLens.userProxyByAccount(
                address(this)
            );
            address StakingPool = PenroseLens.stakingRewardsByDystPool(
                address(asset)
            );

            totalLPStaked = IStakingRewards(StakingPool).balanceOf(
                ProxyAddress
            );
        } else {
            totalLPStaked = reserve; //asset.balanceOf(address(this));
        }
    }

    /**
     * @notice transfer accumulated asset. Shouldn't be called
     since this will transfer community's residue asset to ygnConverter
     * @dev Only owner can call and claim the assets residue
     */
    function transferAssetResidue() external onlyOwner nonReentrant {
        updatePool();
        uint256 assetResidue = asset.balanceOf(address(this));
        if (assetResidue > 0) {
            TransferHelper.safeTransfer(
                address(asset),
                ygnConverter,
                assetResidue
            );
        }
    }

    /**
     * @notice transfer accumulated reward tokens.
     * @dev Only owner can call and claim the reward tokens residue
     */
    function transferRewardTokenRewards() external onlyOwner nonReentrant {
        updatePool();

        uint256 rewardARewards = rewardA.balanceOf(address(this));
        if (rewardARewards > 0) {
            TransferHelper.safeTransfer(
                address(rewardA),
                ygnConverter,
                rewardARewards
            );
        }

        uint256 rewardBRewards = rewardB.balanceOf(address(this));
        if (rewardBRewards > 0) {
            TransferHelper.safeTransfer(
                address(rewardB),
                ygnConverter,
                rewardBRewards
            );
        }
    }

    /**
     * @dev function to claim DYST and PEN rewards
     */
    function _claimRewards() internal {
        userProxyInterfaceContract.claimStakingRewards();
    }

    /**
     * @notice Update reward variables of the pool to be up-to-date. This also claims the rewards generated from staking
     */
    function updatePool() public {
        uint256 addedLiquidityRewardA;
        uint256 addedLiquidityRewardB;

        _claimRewards();

        uint256 rewardARewards = rewardA.balanceOf(address(this));
        uint256 rewardBRewards = rewardB.balanceOf(address(this));

        if (
            rewardARewards > 0 &&
            rewardARewards >= rewardsThresholdAmountRewardA
        ) {
            addedLiquidityRewardA = universalOneSidedFarm.poolLiquidityDystopia(
                    address(this),
                    address(rewardA),
                    rewardARewards,
                    address(asset),
                    toToken,
                    1,
                    swapPathForToTokenRewardA
                );
        }

        if (
            rewardBRewards > 0 &&
            rewardBRewards >= rewardsThresholdAmountRewardB
        ) {
            addedLiquidityRewardB = universalOneSidedFarm.poolLiquidityDystopia(
                    address(this),
                    address(rewardB),
                    rewardBRewards,
                    address(asset),
                    toToken,
                    1,
                    swapPathForToTokenRewardB
                );
        }

        uint256 totalPooledLiquidity = addedLiquidityRewardA +
            addedLiquidityRewardB;
        uint256 lpFees = (feepercentage * totalPooledLiquidity) / 1000;

        TransferHelper.safeTransfer(address(asset), ygnConverter, lpFees);

        uint256 pooledLiquidityForDeposit = totalPooledLiquidity - lpFees;
        if (pooledLiquidityForDeposit > 0) {
            _depositAsset(pooledLiquidityForDeposit);
        }
    }

    /**
     * @notice function to deposit asset to Penrose/Dystopia pools.
     * @param _token Address of the token. (Should be the same as the asset token)
     * @param _amount amount of asset token deposited.
     * @dev Can only be called externally i.e from vaults
     */
    function deposit(address _token, uint256 _amount)
        external
        ensureValidTokenAddress(_token)
        nonReentrant
        returns (uint256 depositedAmount)
    {
        require(isStrategyEnabled, "Strategy is disabled");
        updatePool();

        if (_amount > 0) {
            TransferHelper.safeTransferFrom(
                address(asset),
                address(msg.sender),
                address(this),
                _amount
            );
            depositedAmount = _depositAsset(_amount);
        }
    }

    /**
     * @dev function to deposit asset from strategy to Penrose/Dystopia.
     */
    function _depositAsset(uint256 _amount)
        internal
        returns (uint256 depositedAmount)
    {
        TransferHelper.safeApprove(
            address(asset),
            address(userProxyInterfaceContract),
            _amount
        );
        userProxyInterfaceContract.depositLpAndStake(address(asset), _amount);

        depositedAmount = _amount;
    }

    /**
     * @notice function to withdraw asset from Penrose/Dystopia.
     * @param _token Address of the token. (Should be the same as the asset token)
     * @param _amount amount of asset token the user wants to withdraw.
     * @dev Can only be called from the liquidity manager
     */
    function withdraw(address _token, uint256 _amount)
        external
        nonReentrant
        returns (uint256 withdrawnAmount)
    {
        if (_amount > 0) {
            if (isStrategyEnabled) {
                updatePool();
                withdrawnAmount = _withdrawAsset(_amount);

                TransferHelper.safeApprove(
                    _token,
                    address(msg.sender),
                    withdrawnAmount
                );
            } else {
                withdrawnAmount = _amount;

                TransferHelper.safeApprove(
                    _token,
                    address(msg.sender),
                    withdrawnAmount
                );
            }
        }
    }

    /**
     * @dev function to withdraw asset from Penrose/Dystopia to strategy
     */
    function _withdrawAsset(uint256 _amountToWithdraw)
        internal
        returns (uint256 withdrawnAmount)
    {
        userProxyInterfaceContract.unstakeLpAndWithdraw(
            address(asset),
            _amountToWithdraw
        );
        withdrawnAmount = _amountToWithdraw;
    }

    /**
     * @notice function to withdraw all asset and transfer back to liquidity holder.
     * @dev Can only be called by the owner
     */

    function rescueFunds() external onlyOwner nonReentrant returns (uint256) {
        uint256 assets = this.totalAssets();

        if (assets > 0) {
            reserve = assets;
            _withdrawAsset(assets);
            // rescuedAssetAmount = asset.balanceOf(address(this));
            emit RescueAsset(msg.sender, assets);
            isStrategyEnabled = false;
            return assets;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC2612.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserProxy {
    struct PositionStakingPool {
        address stakingPoolAddress;
        address penPoolAddress;
        address dystPoolAddress;
        uint256 balanceOf;
        RewardToken[] rewardTokens;
    }

    function initialize(
        address,
        address,
        address,
        address[] memory
    ) external;

    struct RewardToken {
        address rewardTokenAddress;
        uint256 rewardRate;
        uint256 rewardPerToken;
        uint256 getRewardForDuration;
        uint256 earned;
    }

    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function convertNftToPenDyst(uint256) external;

    function convertDystToPenDyst(uint256) external;

    function depositLpAndStake(address, uint256) external;

    function depositLp(address, uint256) external;

    function stakingAddresses() external view returns (address[] memory);

    function initialize(address, address) external;

    function stakingPoolsLength() external view returns (uint256);

    function unstakeLpAndWithdraw(
        address,
        uint256,
        bool
    ) external;

    function unstakeLpAndWithdraw(address, uint256) external;

    function unstakeLpWithdrawAndClaim(address) external;

    function unstakeLpWithdrawAndClaim(address, uint256) external;

    function withdrawLp(address, uint256) external;

    function stakePenLp(address, uint256) external;

    function unstakePenLp(address, uint256) external;

    function ownerAddress() external view returns (address);

    function stakingPoolsPositions()
        external
        view
        returns (PositionStakingPool[] memory);

    function stakePenDyst(uint256) external;

    function unstakePenDyst(uint256) external;

    function unstakePenDyst(address, uint256) external;

    function convertDystToPenDystAndStake(uint256) external;

    function convertNftToPenDystAndStake(uint256) external;

    function claimPenDystStakingRewards() external;

    function claimPartnerStakingRewards() external;

    function claimStakingRewards(address) external;

    function claimStakingRewards(address[] memory) external;

    function claimStakingRewards() external;

    function claimVlPenRewards() external;

    function depositPen(uint256, uint256) external;

    function withdrawPen(bool, uint256) external;

    function voteLockPen(uint256, uint256) external;

    function withdrawVoteLockedPen(uint256, bool) external;

    function relockVoteLockedPen(uint256) external;

    function removeVote(address) external;

    function registerStake(address) external;

    function registerUnstake(address) external;

    function resetVotes() external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function votesByAccount(address) external view returns (Vote[] memory);

    function migratePenDystToPartner() external;

    function stakePenDystInPenV1(uint256) external;

    function unstakePenDystInPenV1(uint256) external;

    function redeemPenV1(uint256) external;

    function redeemAndStakePenV1(uint256) external;

    function whitelist(address) external;

    function implementationsAddresses()
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./IRoute.sol";

interface IUniversalSingleSidedLiquidity is IRoute {
    function poolLiquidityUniswapV2(
        address _userAddress,
        address _fromToken,
        uint256 _fromTokenAmount,
        address _pairAddress,
        address _toToken,
        uint256 _slippageAdjustedMinLP,
        address[] memory _swapPathForToToken
    ) external payable returns (uint256 lpBought);

    function poolLiquidityDystopia(
        address _userAddress,
        address _fromToken,
        uint256 _fromTokenAmount,
        address _pairAddress,
        address _toToken,
        uint256 _slippageAdjustedMinLP,
        Route[] calldata _swapPathForToToken
    ) external payable returns (uint256 lpBought);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPenroseLens {
    function userProxyByAccount(address accountAddress)
        external
        view
        returns (address);

    function stakingRewardsByDystPool(address dystPoolAddress)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);
    function earnedA(address account) external view returns (uint256);
    function earnedB(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claimDate() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardsToken() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardRate() external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IRoute {
    struct Route {
        address from;
        address to;
        bool stable;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.4;

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

    //function init(address owner_, string memory name_, string memory symbol_, uint256 totalSupply_)  external ;
    function decimals() external view returns (uint8);

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
// OpenZeppelin Contracts v4.4.1 (interfaces/draft-IERC2612.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC2612 is IERC20Permit {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
interface IERC20Permit {
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