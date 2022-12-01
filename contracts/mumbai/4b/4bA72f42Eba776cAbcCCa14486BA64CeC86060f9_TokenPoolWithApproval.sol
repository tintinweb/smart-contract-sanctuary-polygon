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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITokenPool} from "./interfaces/ITokenPool.sol";
import {IAavePool, IAavePoolAddressesProvider} from "./deps/Aave.sol";

/**
 * @title Yieldgate Token Pool
 * @author Sebastian Stammler
 * @notice Users can stake any token on the TokenPool while a designated
 * beneficiary can claim any generated yield. Users can unstake their previously
 * staked tokens at any time. Aave is used as a yield generator.
 * @dev Prior to staking a new token, the AavePool has to be approved as a
 * spender of this contract's token once by calling approvePool with the token
 * address. The alternative constructor contract TokenPoolWithApproval can be
 * used to deploy this contract and approve a list of tokens at the same time.
 */
contract TokenPool is ITokenPool {
    /*
     * @notice Provider of AAVE protocol contract instance addresses. This
     *   address is fixed for a particular market.
     * @dev Since the actual AAVE Pool address is subject to change, AAVE
     *   advices to always read the pool address from the PoolAddressesProvider.
     */
    IAavePoolAddressesProvider public immutable aavePoolAddressesProvider;

    /*
     * @notice address of beneficiary that can claim generated yield.
     */
    address public immutable beneficiary;

    /*
     * @notice Amount staked by token and by user.
     * @dev Mapping format is token address -> user -> amount.
     */
    mapping(address => mapping(address => uint256)) public stakes;

    // Total stake, by token address.
    mapping(address => uint256) internal totalStake;

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "only beneficiary");
        _;
    }

    constructor(address _aavePoolAddressesProvider, address _beneficiary) {
        aavePoolAddressesProvider = IAavePoolAddressesProvider(_aavePoolAddressesProvider);
        beneficiary = _beneficiary;
    }

    /*
     * @notice Approves the Aave Pool to spend the given token on behalf of this
     * token pool. Trusting the Aave pool implementation, the maximum allowance
     * is set to save on repeated approve calls.
     * @dev Has to be called once before staking a new token, by any user.
     * A new call would be necessary in the unlikely event that the Aave pool
     * proxy address, returned by the PoolAddressesProvider, changes.
     */
    function approvePool(address token) public {
        require(
            IERC20(token).approve(address(aavePool()), type(uint256).max),
            "AavePool approval failed"
        );
    }

    /**
     * @inheritdoc ITokenPool
     * @dev Prio to calling stake, a respective allowance for the token pool has
     * to be set.
     * When staking a token for the first time, the (infinite) ERC20 allowance
     * for the Aave Pool has to be approved first by calling function
     * approvePool (with any user). stake emits a Staked event on success.
     */
    function stake(
        address token,
        address supporter,
        uint256 amount
    ) public virtual {
        require(amount > 0, "zero amount");

        stakes[token][supporter] += amount;
        totalStake[token] += amount;

        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "token transfer failed"
        );
        // For the next step to succeed, approvePool must have been called once before.
        aavePool().supply(token, amount, address(this), 0);

        emit Staked(token, supporter, amount);
    }

    /// @inheritdoc ITokenPool
    function unstake(address token) public virtual returns (uint256) {
        address supporter = msg.sender;
        uint256 amount = stakes[token][supporter];
        require(amount > 0, "no supporter");

        stakes[token][supporter] = 0;
        totalStake[token] -= amount;

        withdraw(token, amount, supporter);

        emit Unstaked(token, supporter, amount);
        return amount;
    }

    /**
     * @inheritdoc ITokenPool
     * @dev Emits a Claimed event on success. Only callable by the beneficiary.
     */
    function claim(address token) public virtual onlyBeneficiary returns (uint256) {
        uint256 amount = claimable(token);
        withdraw(token, amount, beneficiary);

        emit Claimed(token, amount);
        return amount;
    }

    function withdraw(
        address token,
        uint256 amount,
        address receiver
    ) internal {
        aavePool().withdraw(token, amount, receiver);
    }

    /// @inheritdoc ITokenPool
    function claimable(address token) public view returns (uint256) {
        IERC20 aToken = IERC20(aavePool().getReserveData(token).aTokenAddress);
        return aToken.balanceOf(address(this)) - staked(token);
    }

    /// @inheritdoc ITokenPool
    function staked(address token) public view returns (uint256) {
        return totalStake[token];
    }

    function aavePool() internal view returns (IAavePool) {
        return IAavePool(aavePoolAddressesProvider.getPool());
    }
}

/**
 * @dev The TokenPoolWithApproval is the same contract as the
 * TokenPool while its constructor also approves the aavePool to spend the
 * provided list of tokens on behalf of this TokenPool.
 */
contract TokenPoolWithApproval is TokenPool {
    constructor(
        address _aavePoolAddressesProvider,
        address _beneficiary,
        address[] memory _approvedTokens
    ) TokenPool(_aavePoolAddressesProvider, _beneficiary) {
        for (uint256 i = 0; i < _approvedTokens.length; i++) approvePool(_approvedTokens[i]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;
}

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 * https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPoolAddressesProvider.sol
 **/
interface IAavePoolAddressesProvider {
    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     **/
    function getPool() external view returns (address);
}

// https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPool.sol
interface IAavePool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset) external view returns (AaveDataTypes.ReserveData memory);
}

// https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/types/DataTypes.sol
library AaveDataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title Yieldgate Token Pool Interface
 * @author Sebastian Stammler <[email protected]>
 */
interface ITokenPool {
    /**
     * @notice Staked is emitted on every successful stake.
     * @param token Address of staked ERC20 token.
     * @param supporter Addrses of staker.
     * @param amount Amount that got staked.
     */
    event Staked(address indexed token, address indexed supporter, uint256 amount);

    /**
     * @notice Unstaked is cool
     * @param token Address of unstaked ERC20 token.
     * @param supporter Addrses of unstaker.
     * @param amount Amount that got unstaked.
     */
    event Unstaked(address indexed token, address indexed supporter, uint256 amount);

    /**
     * @notice Claimed is emitted on every successful claim.
     * @param token Address of claimed ERC20 token.
     * @param amount Amount that got claimed.
     */
    event Claimed(address indexed token, uint256 amount);

    /**
     * @notice Returns the beneficiary of this pool.
     * @dev Usually this is implemented as a public (immutable) address storage
     * variable.
     */
    function beneficiary() external view returns (address);

    /**
     * @notice Stakes given amount of token on behalf of the provided supporter.
     * @dev Prio to calling stake, a respective allowance for the token pool has
     *   to be set. On success, the implementation must emit a Staked event.
     * @param token Address of ERC20 token to stake.
     * @param supporter The supporter on whose behalf the token is staked.
     * @param amount The amount of token to stake.
     */
    function stake(
        address token,
        address supporter,
        uint256 amount
    ) external;

    /**
     * @notice Unstakes all previously staked token by the calling supporter.
     *   The beneficiary keeps all generated yield.
     * @dev On success, the implementation must emit an Unstaked event.
     * @param token Address of ERC20 token to unstake.
     * @return Returns the unstaked amount.
     */
    function unstake(address token) external returns (uint256);

    /**
     * @notice Sends the accrued yield to the beneficiary of this pool.
     * @dev The implementation should enforce some access control to this
     *   function, e.g., only let it be callable by the beneficiary. It must
     *   emit a Claimed event on success.
     * @param token Address of ERC20 token to claim.
     * @return Returns the claimed amount of yield.
     */
    function claim(address token) external returns (uint256);

    /**
     * @notice Queries the claimable yield for the given ERC20 token.
     * @param token Address of ERC20 token to query.
     * @return Returns the claimable yield.
     */
    function claimable(address token) external view returns (uint256);

    /**
     * @notice Queries the total staked amount for the given ERC20 token.
     * @param token Address of ERC20 token to query.
     * @return Returns the total staked amount.
     */
    function staked(address token) external view returns (uint256);
}