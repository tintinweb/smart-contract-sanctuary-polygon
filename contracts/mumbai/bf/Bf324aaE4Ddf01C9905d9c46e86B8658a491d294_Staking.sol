// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IAdmin.sol";
import "./interfaces/IAirdrops.sol";
import "./interfaces/ISuperCharge.sol";
import "./libraries/StakingLibrary.sol";

/**
 * @title Staking.
 * @dev contract for staking tokens.
 *
 */
contract Staking is IStaking, Initializable {
    using SafeERC20 for IERC20;
    using StakingLibrary for StakingLibrary.TierDetails;
    using StakingLibrary for StakingLibrary.LevelDetails;
    using StakingLibrary for StakingLibrary.UserState;


    bytes32 public constant OPERATOR = keccak256("OPERATOR");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    uint128 constant POINT_BASE = 1000;
    uint128 constant NO_LOCK_FEE = 50; //5%

    uint256 public MaticFeeLockLevel;
    bool public noLock;

    uint256 public lockLevelCount;
    uint256 public totalStakedAmount;
    IERC20 public ION;
    IAdmin public admin;
    IUniswapV2Router02 public router;
    address public wMatic;

    mapping(uint256 => mapping(uint256 => StakingLibrary.TierDetails))
        public tiers;
    mapping(uint256 => StakingLibrary.LevelDetails) public levels;
    mapping(address => StakingLibrary.UserState) public stateOfUser;

    /**
     @dev Initialize Function
     @param _token: Token Contract
     @param _admin: Admin Contract
     @param _router: Router contract
     @param _wMatic: wMatic contract
     @param _depositAmount[][] : ION amount required for different levels & tiers
     */
    function initialize(
        address _token,
        address _admin,
        address _router,
        address _wMatic,
        uint128[][] memory _depositAmount
    ) public initializer {
        ION = IERC20(_token);
        admin = IAdmin(_admin);
        lockLevelCount = 4;
        levels[1] = StakingLibrary.LevelDetails(0, 6);
        levels[2] = StakingLibrary.LevelDetails(30 days, 6);
        levels[3] = StakingLibrary.LevelDetails(60 days, 6);
        levels[4] = StakingLibrary.LevelDetails(90 days, 7);

        router = IUniswapV2Router02(_router);
        wMatic = _wMatic;
        MaticFeeLockLevel = 1;

        for (uint8 i = 0; i < uint8(_depositAmount.length); i++) {
            for (uint8 j = 0; j < uint8(_depositAmount[i].length); j++) {
                tiers[i + 1][j + 1].amount = _depositAmount[i][j] * 10**9; 
            }
        }
    }

    receive() external payable {}

    /**
    @dev Checks IDO instance
    */
    modifier onlyInstances() {
        require(admin.tokenSalesM(msg.sender), "Staking: Not Instance");
        _;
    }
    modifier validation(address _address) {
        require(_address != address(0), "Staking: zero address");
        _;
    }
    modifier onlyOperator() {
        require(admin.hasRole(OPERATOR, msg.sender), "Staking: Not Operator");
        _;
    }

    modifier onlyAdmin() {
        require(
            admin.hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Staking: Not Admin"
        );
        _;
    }

    /**
     @dev Set admin contract
     @param _address admin contract address
     */
    function setAdmin(address _address)
        external
        validation(_address)
        onlyOperator
    {
        admin = IAdmin(_address);
    }

    /**
     @dev Set Token contract
     @param _address Token contract address
     */
    function setToken(address _address)
        external
        validation(_address)
        onlyOperator
    {
        ION = IERC20(_address);
    }

    /**
     @dev Set tier
     @param _address user address
     @param _tier Tier
     */
    
    function setTierTo(address _address, uint256 _tier)
        external
        override
        onlyOperator
    {
        stateOfUser[_address].Tier = uint32(_tier);
    }

    /**
     @dev get alllocation of user
     @param _address user address
     */
    function getAllocationOf(address _address)
        external
        view
        override
        returns (uint128)
    {
        StakingLibrary.UserState memory state = stateOfUser[_address];
        return (
            tiers[uint256(state.lock)][_getHighestTier(_address)].allocations
        );
    }

    /**
     @dev Sets IDO pool end time
     @param _address IDO address
     @param _time Time in seconds
     */
    function setPoolsEndTime(address _address, uint256 _time)
        external
        override
        onlyInstances
    {
        if (stateOfUser[_address].lockTime < _time) {
            stateOfUser[_address].lockTime = uint64(_time);
        }
    }

    /**
     @dev Staking
     @param _level lock level 
     @param _amount amount
     */
    function stake(uint256 _level, uint256 _amount) external payable {
        uint256 _duration = (block.timestamp +
            uint256(levels[_level].duration));
        StakingLibrary.UserState storage s = stateOfUser[msg.sender];

        uint256 prevLock = s.lock;
        uint256 prevTier = _getHighestTier(msg.sender);
        uint256 prevAmount = s.amount;
        if (prevLock > 1) {
            IAirdrops(admin.airdrop()).userPendingION(msg.sender);
        }

        ISuperCharge superCharge = ISuperCharge(admin.superCharge());
        (uint id,) = superCharge.userDetails(msg.sender);
        if(id == 0){
            superCharge.setUserStateWithDeposit(msg.sender);
        }else if(_superChargeReward(msg.sender)){
            superCharge.setUserStateWithDeposit(msg.sender);
        }

        if (_amount == 0) {
            require(s.amount != 0, "Staking: Amount > 0");
            require(_level > s.lock, "Staking: Invalid lock level");
            s._updateUserState(_amount, _level, _duration);

            if (s.lock > 1) {
                IAirdrops(admin.airdrop()).setShareForIONReward(
                    msg.sender,
                    prevLock,
                    s.amount
                );
            }
            return;
        }

        require(uint8(_level) >= uint8(s.lock), "Staking: level < user level");

        totalStakedAmount += (_amount);

        s._updateUserState(_amount, _level, _duration);

        uint256 highestTier = _getHighestTier(msg.sender);
        require(highestTier > 0, "Staking: No Tier");
        s.Tier = uint32(highestTier);

        if (s.lock == 4 && highestTier == 7) {
            if (prevLock != 4 || prevTier != 7) {
                IAirdrops(admin.airdrop()).setShareForMaticReward(
                    msg.sender,
                    s.amount
                );
            } else if (prevLock == 4 && prevTier == 7) {
                IAirdrops(admin.airdrop()).setShareForMaticReward(
                    msg.sender,
                    _amount
                );
            }
        }

        if (s.lock > 1) {
            if (prevLock <= 1) {
                IAirdrops(admin.airdrop()).setShareForIONReward(
                    msg.sender,
                    prevLock,
                    s.amount
                );
            } else {
                IAirdrops(admin.airdrop()).setShareForIONReward(
                    msg.sender,
                    prevLock,
                    prevAmount
                );
            }
        }

        if (s.lock == MaticFeeLockLevel) {
            _takeMaticFee(_amount, msg.value);
        }

        ION.safeTransferFrom(msg.sender, address(this), _amount);

    }

    /**
     @dev Unstaking total staked
     */
    function unstake() external override {
        require(_canUnstake(), "Staking: Not time");
        StakingLibrary.UserState storage s = stateOfUser[msg.sender];
        uint256 amount = s.amount;

        uint256 prevTier = _getHighestTier(msg.sender);

        if (s.lock > 1) {
            IAirdrops(admin.airdrop()).userPendingION(msg.sender);
            IAirdrops(admin.airdrop()).withdrawION(msg.sender, amount);
        }

        ISuperCharge superCharge = ISuperCharge(admin.superCharge());
        if(_superChargeReward(msg.sender)){
            superCharge.setUserStateWithWithdrawal(msg.sender);
        }

        s.amount = 0;
        totalStakedAmount -= amount;
        s.Tier = 0;

        if (s.lock == 4 && prevTier == 7) {
            IAirdrops(admin.airdrop()).userPendingMatic(msg.sender, amount);
        }

        s.lock = 0;


        ION.safeTransfer(msg.sender, amount);
    }

    /**
     @dev Set $ allocations
     */
    function setAllocations(uint128[][] memory _allocations)
        external
        onlyOperator
    {
        for (uint8 i = 0; i < uint8(_allocations.length); i++) {
            for (uint8 j = 0; j < uint8(_allocations[i].length); j++) {
                require(_allocations[i][j] > 0, "Staking: price > 0");
                tiers[i + 1][j + 1].allocations = _allocations[i][j];
            }
        }
    }

    /**
     @dev Set BNB tx fee level
     @param _level Lock level
     */
    function setMaticFeeLockLevel(uint256 _level) external onlyOperator {
        require(_level <= lockLevelCount, "Staking: Invalid lock level");
        MaticFeeLockLevel = _level;
    }

    /**
     @dev Removes the lock period on all staked users
     @param _noLock bool
     */
    function setNoLock(bool _noLock) external onlyAdmin {
        noLock = _noLock;
    }

    /**
     @dev Change allocations
     @param _level lock level 
     @param _tier Tier
     @param _allocation new allocation
     */
    function changeAllocations(
        uint256 _level,
        uint256 _tier,
        uint128 _allocation
    ) external onlyOperator {
        require(_allocation > 0, "Staking: price > 0");
        tiers[_level][_tier].allocations = _allocation;
    }

    /**
    @dev Set staking deposit amount
    @param _depositAmount array of amounts
    */
    function setDeposits(uint128[][] memory _depositAmount)
        public
        onlyOperator
    {
        for (uint8 i = 0; i < uint8(_depositAmount.length); i++) {
            for (uint8 j = 0; j < uint8(_depositAmount[i].length); j++) {
                tiers[i + 1][j + 1].amount = _depositAmount[i][j];
            }
        }
    }

    /**
     @dev Returns allocation
     @param _level Level
     @param _tier Tier
     */
    function getAllocations(uint256 _level, uint256 _tier)
        external
        view
        returns (uint128)
    {
        return tiers[_level][_tier].allocations;
    }

    /**
     @dev Returns deposit amount
     @param _level Level
     @param _tier Tier
     */
    function getDeposits(uint256 _level, uint256 _tier)
        external
        view
        returns (uint128)
    {
        return tiers[_level][_tier].amount;
    }

    /**
     **@dev Returns user tier,lock,amount and locktime
     */
    function getUserState(address _address)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _getHighestTier(_address),
            uint256(stateOfUser[_address].lock),
            uint256(stateOfUser[_address].amount),
            uint256(stateOfUser[_address].lockTime)
        );
    }

    /**
    @dev Calculates staking fee for no lock
     */
    function _takeMaticFee(uint256 _amount, uint256 _maticValue) internal {
        uint256 feePercent = (_amount * NO_LOCK_FEE) / POINT_BASE;
        address[] memory arr = new address[](2);
        arr[0] = address(ION);
        arr[1] = wMatic;
        uint256[] memory v;
        v = router.getAmountsOut(feePercent, arr);
        uint256 valueInMatic = v[v.length - 1];
        require(_maticValue >= valueInMatic, "Staking: Invalid Matic");
        address payable airdrop = payable(admin.airdrop());
        IAirdrops(admin.airdrop()).setTotalMatic(_maticValue);
        (bool sent, ) = airdrop.call{value: _maticValue}("");
        require(sent, "Staking: Matic Transfer_Failed");
    }

      function getTierOf(address _address)
        external
        view
        override
        returns (uint256)
    {
        return _getHighestTier(_address);
    }

    /**
    @dev returns highest tier of user
     */
    function _getHighestTier(address _address) internal view returns (uint256) {
        uint256 _tier = _tierByAmount(
            uint256(stateOfUser[_address].amount),
            uint256(stateOfUser[_address].lock)
        );
        return _tier;
    }

    /**
    @dev checks epoch for unstaking
     */
    function _canUnstake() internal view returns (bool) {
        if (noLock) {
            return (true);
        } else {
            return block.timestamp > uint256(stateOfUser[msg.sender].lockTime);
        }
    }

    /**
    @dev returns tier 
     */
    function _tierByAmount(uint256 _amount, uint256 _level)
        internal
        view
        returns (uint256)
    {
        if (_level == 0) {
            return 0;
        }
        for (uint256 i = levels[_level].numberOfTiers; i > 0; i--) {
            if (_amount >= tiers[_level][i].amount) {
                return i;
            }
        }
        return 0;
    }

    function _superChargeReward(address user) internal returns(bool){
        ISuperCharge superCharge = ISuperCharge(admin.superCharge()); 
        if(superCharge.canClaim(user)){
            superCharge.claimSuperCharge(user);
            require(!(superCharge.canClaim(user)),"Need to claim superCharge");
            return true;
        }else{
            return true;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
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

// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.4;

/**
 * @title IStaking.
 * @dev interface for staking
 * with params enum and functions.
 */
interface IStaking {
    /**
     * @dev
     * defines privelege type of address.
     */

    function setPoolsEndTime(address, uint256) external;

    function setTierTo(address _address, uint _tier) external;

    function stake(uint256 , uint256) external payable;

    function getAllocationOf(address) external returns (uint128);

    function unstake() external;

    function getUserState(address)
        external
        returns (
            uint,
            uint,
            uint256,
            uint256
        );

    function stateOfUser(address)
        external
        returns (
            uint32,
            uint32,
            uint64,
            uint128
        );

    function getTierOf(address) external view returns (uint);
    function setMaticFeeLockLevel(uint) external;
    function totalStakedAmount() external returns(uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ITokenSale.sol";

/**
 * @title IAdmin.
 * @dev interface of Admin contract
 * which can set addresses for contracts for:
 * airdrop, token sales maintainers, staking.
 * Also Admin can create new pool.
 */
interface IAdmin is IAccessControl {
    function getParams(address)
        external
        view
        returns (ITokenSale.Params memory);

    function airdrop() external returns (address);

    function tokenSalesM(address) external returns (bool);

    function blockClaim(address) external returns (bool);

    function tokenSales(uint256) external returns (address);

    function masterTokenSale() external returns (address);

    function stakingContract() external returns (address);

    function setMasterContract(address) external;

    function setAirdrop(address _newAddress) external;

    function setStakingContract(address) external;

    function createPool(ITokenSale.Params calldata _params) external;

    function getTokenSales() external view returns (address[] memory);

    function wallet() external view returns (address);

    function addToBlackList(address, address[] memory) external;

    function blacklist(address, address) external returns (bool);

    function superCharge() external returns(address);

    function setSuperCharge(address) external;

    /**
     * @dev Emitted when pool is created.
     */
    event CreateTokenSale(address instanceAddress);
    /**
     * @dev Emitted when airdrop is set.
     */
    event SetAirdrop(address airdrop);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/**
 * @title IStaking.
 * @dev interface for staking
 * with params enum and functions.
 */
interface IAirdrops {
    function depositAssets(address, uint256, uint256) external payable;
    function setShareForMaticReward(address, uint256) external;
    function userPendingMatic(address user, uint amount) external;
    function pushIONAmount(uint _amount) external;
    function withdrawION(address user, uint _amount) external;
    function setShareForIONReward (address user,uint _prevLock, uint _amount) external; 
    function userPendingION(address user) external;
    function setTotalMatic(uint _amount) external;
    function distributionION(uint amount) external;
    function distributionMatic() external;
    function setMarketingWallet(address _address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface ISuperCharge {

    function userDetails(address) external returns(uint,bool);
    function superChargeRewards(uint) external returns(uint,uint);
    function superChargeCount() external returns(uint);
    function addSupercharge(uint amount) external;
    function setUserStateWithDeposit(address user) external;
    function setUserStateWithWithdrawal(address user) external;
    function canClaim(address) external returns(bool);
    function claimSuperCharge(address user) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

library StakingLibrary {

    struct TierDetails {
        uint128 amount;
        uint128 allocations;
    }

    struct LevelDetails {
        uint128 duration;
        uint128 numberOfTiers;
    }

    struct UserState {
        uint32 Tier;
        uint32 lock;
        uint64 lockTime;
        uint128 amount;
    }

    function _updateUserState(UserState storage self, uint256 _amount, uint256 _lockLevel, uint256 _lockTime) internal {
        if (_amount > 0) {
            self.amount += uint128(_amount);
        }

        self.lock = uint32(_lockLevel);
        self.lockTime = uint64(_lockTime);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


/**
 * @title ITokenSale.
 * @dev interface of ITokenSale
 * params structure and functions.
 */
pragma solidity ^0.8.4;

interface ITokenSale {

    struct Staked {
        uint128 amount;
        uint120 share;
        bool claimed;
    }

    enum Epoch {
        Incoming,
        Private,
        Finished
    }

    /**
     * @dev describe initial params for token sale
     * @param totalSupply set total amount of tokens. (Token decimals)
     * @param privateStart set starting time for private sale.
     * @param privateEnd set finish time for private sale.
     * @param privateTokenPrice set price for private sale per token in $ (18 decimals).
     * @param airdrop - amount reserved for airdrop
     */
    struct Params {
        uint96 totalSupply; //MUST BE 10**18;
        uint32 privateStart;
        uint96 privateTokenPrice; // MUST BE 10**18 in $  
        uint32 privateEnd;
    }

    struct State {
        uint128 totalPrivateSold;
        uint128 totalSupplyInValue;
    }

 
    /**
     * @dev initialize implementation logic contracts addresses
     * @param _stakingContract for staking contract.
     * @param _admin for admin contract.
     */
    function initialize(
        Params memory params,
        address _stakingContract,
        address _admin
    ) external;

    /**
     * @dev claim to sell tokens in airdrop.
     */
    // function claim() external;

    /**
     * @dev get banned list of addresses from participation in sales in this contract.
     */
    function epoch() external returns (Epoch);
    function destroy() external;
    function checkingEpoch() external;
    function totalTokenSold() external view returns (uint128);
    function giftTier(address[] calldata users, uint256[] calldata tiers) external;
    function stakes(address)
        external
        returns (
            uint128,
            uint120,
            bool
        );

    function takeLocked() external;
    function removeOtherERC20Tokens(address) external;
    function canClaim(address) external returns (uint120, uint256);
    function takeUSDCRaised() external;

    event DepositPrivate(address indexed user, uint256 amount, address instance);
    event Claim(address indexed user, uint256 change);
    event TransferAirdrop(uint256 amount);
    event TransferLeftovers(uint256 earned);
    event ERC20TokensRemoved(address _tokenAddress, address sender, uint256 balance);
    event RaiseClaimed(address _receiver, uint256 _amountInBUSD);
}