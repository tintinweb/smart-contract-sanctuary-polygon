// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ILiquidityPool.sol";
import "./TokenLiquidityPool.sol";
import "./NativeLiquidityPool.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Thrown when state of contract is equal to `state`
error DEX__StateIsNot(uint8 state);
/// @notice Thrown when state of contract is not equal to `state`
error DEX__StateIs(uint8 state);
/// @notice Thrown when transfer of tokens at ERC20 `tokenAddress` fails
error DEX__TokenTransferFailed(address tokenAddress);
/// @notice Thrown when approve function of ERC20 at `tokenAddress` fails
error DEX__TokenApprovalFailed(address tokenAddress);
/// @notice Thrown when `liquidityPoolAddress` is not an active liquidity pool
error DEX__LiquidityPoolNotActive(address liquidityPoolAddress);
/// @notice Thrown when liquidity pool at `liquidityPoolAddress` is already activated
error DEX__LiquidityPoolIsActive(address liquidityPoolAddress);
/// @notice Thrown when x and y addresses of new TokenLiquidityPool match
error DEX__TokenAddressesOfTokenLiquidityPoolMatching();

/**
 * @title DEX
 * @author Philipp Keinberger
 * @notice This contract provides a decentralized exchange, where users can use any of the
 * liquidity pools added to the exchange to swap between assets. Liquidity pools can be
 * added and removed through access-restricted functions, favourably
 * controlled by a governor cvontract (e.g. DAO) to allow for decentralized governance of
 * the DEX.
 * @dev This contract implements the IERC20 Openzeppelin interface for the ERC20 token
 * standard. It also implements the ILiquidityPool interface for liquidity pools stored on
 * the exchange.
 *
 * This contract inherits from Openzeppelins OwnableUpgradeable contract in order to
 * allow for owner features, while still keeping upgradeablity functionality.
 *
 * The DEX is designed to be deployed through a proxy to allow for future upgrades of the
 * contract.
 */
contract DEX is OwnableUpgradeable {
    /**
     * @dev Defines the state of the contract, allows for state restricted functionality
     * of the contract.
     */
    enum State {
        CLOSED,
        UPDATING,
        OPEN
    }

    State private s_dexState;
    /// @dev liquidity pool address => active bool
    mapping(address => bool) s_liquidityPools;

    /// @notice Event emitted when the state of the contract gets updated
    event StateUpdated(State newState);
    /// @notice Event emitted when a new liquidity pool is added to the pool
    event LiquidityPoolAdded(address liquidityPoolAddress, ILiquidityPool.Kind liquidityPoolKind);
    /// @notice Event emitted when a liquidity pool is removed from the DEX
    event LiquidityPoolRemoved(address liquidityPoolAddress);
    /// @notice Event emitted when an already existing liquidity pool is activated on the DEX
    event LiquidityPoolActivated(address liquidityPoolAddress);

    /// @notice Checks if state of DEX is equal to `state`
    modifier stateIs(State state) {
        if (state != s_dexState) revert DEX__StateIsNot(uint8(state));
        _;
    }

    /// @notice Checks if state of DEX is not equal to `state`
    modifier stateIsNot(State state) {
        if (state == s_dexState) revert DEX__StateIs(uint8(state));
        _;
    }

    /// @notice Checks if liquidity pool at `liquidityPoolAddress` is not deactivated
    modifier isActiveLiquidityPool(address liquidityPoolAddress) {
        if (!s_liquidityPools[liquidityPoolAddress])
            revert DEX__LiquidityPoolNotActive(liquidityPoolAddress);
        _;
    }

    /// @notice Ensures that initialize can only be called through proxy
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function which replaces constructor for upgradeability
     * functionality.
     * Sets `msg.sender` as owner of the contract
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Function for setting the state of the DEX
     * @param newState is the new state value of the contract
     * @dev This function can only be called by the owner.
     * This function emits the {StateUpdated} event
     */
    function setState(State newState) external onlyOwner {
        s_dexState = newState;
        emit StateUpdated(newState);
    }

    /**
     * @notice Function for adding a NativeLiquidityPool to the DEX
     * @param tokenAddress is the address of the ERC20 contract
     * @param swapFee is the swapFee to be used for swapping in the pool
     * @param tokenDeposit is the amount of tokens to be used for initialization of the
     * liquidity pool
     * @dev The function uses the parameters to deploy a new NativeLiquidityPool and
     * initializes it. The new liuqidity pool is then added to the DEX.
     *
     * Note that already existing liquidity pools with the same parameters as an existing one
     * may still be added to the DEX.
     *
     * This function reverts if the caller is not the owner, or the state of the contract
     * is CLOSED. It also reverts if the transfer of `tokenDeposit` from `msg.sender` fails,
     * or the approval of the new liquidity pool to transfer `tokenDeposit` to itself fails.
     *
     * This function emits the {LiquidityPoolAdded} event.
     */
    function addNativeLiquidityPool(
        address tokenAddress,
        uint16 swapFee,
        uint256 tokenDeposit
    ) external payable onlyOwner stateIsNot(State.CLOSED) {
        IERC20 token = IERC20(tokenAddress);

        if (!token.transferFrom(msg.sender, address(this), tokenDeposit))
            revert DEX__TokenTransferFailed(address(token));

        NativeLiquidityPool newLiquidityPool = new NativeLiquidityPool(tokenAddress, swapFee);

        if (!token.approve(address(newLiquidityPool), tokenDeposit))
            revert DEX__TokenApprovalFailed(address(token));

        newLiquidityPool.initialize{value: msg.value}(tokenDeposit);

        address liquidityPoolAddress = address(newLiquidityPool);
        s_liquidityPools[liquidityPoolAddress] = true;

        emit LiquidityPoolAdded(liquidityPoolAddress, ILiquidityPool.Kind.NativeLiquidityPool);
    }

    /**
     * @notice Function for adding a TokenLiquidityPool to the DEX
     * @param xAddress is the address of the x token in the new pool
     * @param yAddress is the address of the y token in the new pool
     * @param swapFee is the swapFee to be used for swapping in the new pool
     * @param xDeposit is the amount of x tokens to be used of the caller for initialization
     * of the pool
     * @param yDeposit is the amount of y tokens to be used of the caller for initialization
     * of the pool
     * @dev The function uses the parameters to deploy a new TokenLiquidityPool and initializes
     * it. The new liuqidity pool is then added to the DEX.
     *
     * Note that already existing liquidity pools with the same parameters as an existing one
     * may still be added to the DEX.
     *
     * The token addresses `xAddress` and `yAddress` may not match each other.
     * This function reverts if the caller is not the owner, or the state of the contract
     * is CLOSED. It also reverts if the transfer of `xDeposit` or `yDeposit` from `msg.sender`
     * fails, or the approval of the new liquidity pool to transfer `xDeposit` or `yDeposit`
     * to itself fails.
     *
     * This function emits the {LiquidityPoolAdded} event.
     */
    function addTokenLiquidityPool(
        address xAddress,
        address yAddress,
        uint16 swapFee,
        uint256 xDeposit,
        uint256 yDeposit
    ) external onlyOwner stateIsNot(State.CLOSED) {
        if (xAddress == yAddress) revert DEX__TokenAddressesOfTokenLiquidityPoolMatching();

        IERC20 xToken = IERC20(xAddress);
        IERC20 yToken = IERC20(yAddress);

        if (!xToken.transferFrom(msg.sender, address(this), xDeposit))
            revert DEX__TokenTransferFailed(address(xToken));
        if (!yToken.transferFrom(msg.sender, address(this), yDeposit))
            revert DEX__TokenTransferFailed(address(yToken));

        TokenLiquidityPool newLiquidityPool = new TokenLiquidityPool(xAddress, yAddress, swapFee);

        if (!xToken.approve(address(newLiquidityPool), xDeposit))
            revert DEX__TokenApprovalFailed(address(xToken));
        if (!yToken.approve(address(newLiquidityPool), yDeposit))
            revert DEX__TokenApprovalFailed(address(yToken));

        newLiquidityPool.initialize(xDeposit, yDeposit);

        address liquidityPoolAddress = address(newLiquidityPool);
        s_liquidityPools[liquidityPoolAddress] = true;

        emit LiquidityPoolAdded(liquidityPoolAddress, ILiquidityPool.Kind.TokenLiquidityPool);
    }

    /**
     * @notice Function for removing a liquidity pool
     * @param liquidityPoolAddress is the address of the liquidity pool
     * @dev The function can only be called by the owner, if the DEX is not
     * CLOSED and the liquidity pool exists on the DEX. The function will revert if any of
     * these prerequisites is not met.
     *
     * This function emits the {LiquidityPoolRemoved} event.
     */
    function removeLiquidityPool(address liquidityPoolAddress)
        external
        onlyOwner
        stateIsNot(State.CLOSED)
        isActiveLiquidityPool(liquidityPoolAddress)
    {
        delete s_liquidityPools[liquidityPoolAddress];
        emit LiquidityPoolRemoved(liquidityPoolAddress);
    }

    /**
     * @notice Function for activating an already existing liquidity pool on the DEX
     * @param liquidityPoolAddress is the address of the active liquidity pool
     * @dev This function can be used to allow previously used liquidity pools to be
     * (re) activated on the DEX. It also allows for external liquidity pools that
     * implement the ILiquidityPool interface to be activated on (added to) the exchange.
     *
     * The function can only be called by the owner and if the DEX is not CLOSED.
     * The function will revert if any of these prerequisites is not met.
     *
     * This function emits the {LiquidityPoolActivated} event.
     */
    function activateLiquidityPool(address liquidityPoolAddress)
        external
        onlyOwner
        stateIsNot(State.CLOSED)
    {
        if (s_liquidityPools[liquidityPoolAddress])
            revert DEX__LiquidityPoolIsActive(liquidityPoolAddress);

        s_liquidityPools[liquidityPoolAddress] = true;
        emit LiquidityPoolActivated(liquidityPoolAddress);
    }

    /**
     * @notice Function for swapping at liquidity pool at `liquidityPoolAddress`
     * @param liquidityPoolAddress is the address of the liquidity pool
     * @param tokenAmount is the amount of tokens to be swapped.
     * Note that `tokenAmount` can be zero if swapping native for tokens (xToY, NativeLiquidityPool)
     * @dev The function calls the swapFrom function of the liquidity pool at `liquidityPoolAddress`
     * (see ILiquidityPool for more documentation). In order for the DEX to be able to swap from
     * the caller (swap on behalf of `msg.sender`), the DEX needs to be approved with the
     * `tokenAmount` or `msg.value` (depending on the pool and swap direction) by the caller
     * at the liquidity pool prior to calling this function. See `approve` at ILiquidityPool
     * for more documentation.
     *
     * The function can only be called if the DEX is not CLOSED. This implemenation will
     * check for the liquidity pool at `liquidityPoolAddress` being active.
     * The function will revert if any of these prerequisites is not met.
     */
    function swapAt(address liquidityPoolAddress, uint256 tokenAmount)
        external
        payable
        stateIs(State.OPEN)
        isActiveLiquidityPool(liquidityPoolAddress)
    {
        ILiquidityPool liquidityPool = ILiquidityPool(liquidityPoolAddress);
        liquidityPool.swapFrom{value: msg.value}(msg.sender, tokenAmount);
    }

    /**
     * @notice Function for retrieving the current State of the DEX
     * @return State of the DEX
     */
    function getState() public view returns (State) {
        return s_dexState;
    }

    /**
     * @notice Function for retrieving activation status of liquidity pool
     * at `liquidityPoolAddress`
     * @param liquidityPoolAddress is the address of the liquidity pool
     * @return Activation value of liquidity pool at `liquidityPoolAddress`
     */
    function getStatus(address liquidityPoolAddress) public view returns (bool) {
        return s_liquidityPools[liquidityPoolAddress];
    }

    /**
     * @notice Function for retrieving version of the DEX
     * @return Version
     */
    function getVersion() public pure returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/**
 * @dev This is an interface for the TokenLiquidityPool and NativeLiquidityPool contracts
 * to implement standardized functionality of both liquidity pools. Using this interface,
 * third party contracts can use liquidity pools of both types, while keeping core
 * features standardized.
 */
interface ILiquidityPool {
    /// @dev Defines the kind of the liquidity pool
    enum Kind {
        NativeLiquidityPool,
        TokenLiquidityPool
    }

    /**
     * @dev Defines the direction for a swap.
     * Note that in NativeLiquidityPools "x" always refers to the native chain currency, whereas
     * "y" refers to the ERC20 token. In TokenLiquidityPools, "x" and "y" each refer to one of
     * the ERC20 tokens in the pool.
     */
    enum SwapDirection {
        xToY,
        yToX
    }

    /// @dev Defines the structure for Allowance in a liquidity pool
    struct Allowance {
        /// @dev Specifies the amount of the asset that can be swapped
        uint256 amount;
        /// @dev Defines in which direction the swap can be executed
        SwapDirection direction;
    }

    /**
     * @notice Event emitted when `owner` approves `approvee` to swap `amount` in the direction
     * of `direction`
     */
    event Approval(address owner, address approvee, uint256 amount, SwapDirection direction);
    /**
     * @notice Event emitted when `swapee` swaps `amount` in the direction of `direction`.
     * Note that `amount` may be zero.
     */
    event Swap(address swapee, uint256 amount, uint256 output, SwapDirection direction);

    /**
     * @notice Function for approving other users to swap on ones own behalf
     * @param approvee is the address that should be approved
     * @param amount is the amount approved for `approvee` to swap
     * @param direction is the direction to allow swapping in
     * @dev This function approves `approvee` to swap `amount` from caller
     * in direction of `direction`.
     *
     * Calling this function with `amount` equal to zero in effect resets the
     * allowance.
     *
     * This function emits the {Approval} event.
     */
    function approve(
        address approvee,
        uint256 amount,
        SwapDirection direction
    ) external;

    /**
     * @notice Function for retrieving the allowance of `allowee` to swap
     on behalf of `owner`
     * @param owner is the owner the tokens to swap
     * @param allowee is the address allowed to swap according to allowance
     * @return Allowance of `allowee` to swap for `owner`
     */
    function getAllowanceOf(address owner, address allowee)
        external
        view
        returns (Allowance memory);

    /**
     * @notice Function for swapping tokens
     * @param tokenAmount is the amount of tokens to be swapped to native currency.
     * Note that `tokenAmount` can be zero if swapping native for tokens (xToY, NativeLiquidityPool)
     * @param direction defines the direction of the swap (xToY or yToX)
     * @dev This function has to be payable to allow for native currency to token swaps.
     * Note that tn that case, `tokenAmount` may be zero.
     */
    function swap(uint256 tokenAmount, SwapDirection direction) external payable;

    /**
     * @notice Function for swapping tokens on other users behalf
     * @param from is the address from which to swap
     * @param tokenAmount is the amount of tokens to be swapped to native currency.
     * Note that `tokenAmount` can be zero if swapping native for tokens (xToY, NativeLiquidityPool)
     * @dev This function swaps `tokenAmount` from `from` in the direction specified
     * by the allowance and removes `tokenAmount` from the allowance.
     *
     * This function reverts if `tokenAmount` is greater than the allowance set by `from`
     */
    function swapFrom(address from, uint256 tokenAmount) external payable;

    /**
     * @notice Function for retrieving the kind of the liquidity pool
     * @return Kind of the liquidity pool
     */
    function getKind() external returns (Kind);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ILiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice Thrown when `value` is not above zero
error NativeLiquidityPool__NotAboveZero(uint256 value);
/// @notice Thrown when transfer of erc20 token fails
error NativeLiquidityPool__TokenTransferFailed();
/// @notice Thrown when transfer of native currency fails
error NativeLiquidityPool__NativeTransferFailed();
/// @notice Thrown when requested liquidity amount for withdrawal exceeds actual liquidity
error NativeLiquidityPool__NotEnoughLiquidity();
/// @notice Thrown when requested amount to swap is smaller than allowance
error NativeLiquidityPool__NotEnoughAllowance();

/**
 * @title NativeLiquidityPool
 * @author Philipp Keinberger
 * @notice This contract is a liquidity pool, where users can swap between an ERC20
 * token and native blockchain currency (e.g. ETH, MATIC). Users can also provide
 * liquidity to the pool, while accumulating rewards over time from the swapping fee.
 * Liquidity can be withdrawn at all times. Users can swap tokens on behalf of other
 * users by using the Allowance feature. In order to use that feature, one has to approve
 * another user for future swaps on ones own behalf.
 * @dev This contract implements the ILiquidityPool interface to allow for standardized
 * liquidity pool functionality for exchanges.
 *
 * This contract also implements the IERC20 Openzeppelin inteface for the ERC20 token
 * standard.
 *
 * The TokenLiquidityPool inherits from Openzeppelins Ownable contract to allow for
 * owner features. It also inherits from Openzeppelins Initializable contract to allow
 * for a safe initialize function, favourably used by exchanges to initialize the
 * liquidity pool.
 *
 * "X" refers to the native currency, while "Y" refers to the ERC20 token in the contract.
 */
contract NativeLiquidityPool is Ownable, Initializable, ILiquidityPool {
    Kind private constant LP_KIND = Kind.NativeLiquidityPool;
    IERC20 private immutable i_token;
    /// @dev fee in 1/10 percent (i_swapFee = 1, => 0.1 percent)
    uint16 private immutable i_swapFee;

    uint256 private s_poolLiquidity;
    /// @dev userAddress => liquidity
    mapping(address => uint256) private s_liquidityOf;
    /// @dev userAddress => allowedUser => Allowance
    mapping(address => mapping(address => Allowance)) private s_allowanceOf;

    /// @notice Event emitted when new liquidity is provided (added) to the pool
    event LiquidityAdded(
        address liquidityProvider,
        uint256 liquidityAmount,
        uint256 nativeDeposit,
        uint256 tokenDeposit
    );
    /// @notice Event emitted when liquidity is withdrawn (removed) from the pool
    event LiquidityRemoved(
        address liquidityProvider,
        uint256 liquidityAmount,
        uint256 nativeWithdrawn,
        uint256 tokensWithdrawn
    );

    constructor(address tokenAddress, uint16 swapFee) {
        i_token = IERC20(tokenAddress);
        i_swapFee = swapFee;
    }

    /**
     * @notice Function for initializing (setting up) the liquidity pool
     * @param tokenDeposit is the token amount deposited
     * @dev This function initializes the liquidity pool with `msg.value` for x
     * and `tokenDeposit` for y.
     * This function reverts if the caller is not the owner of the contract.
     * The function also reverts if `tokenDeposit` is not greater than zero.
     * If the ERC20 transfer of `tokenDeposit` from caller to the contract fails,
     * the function will revert.
     *
     * Note that this function can only be called once.
     *
     * This function emits the {LiquidityAdded} event.
     */
    function initialize(uint256 tokenDeposit) external payable onlyOwner initializer {
        if (msg.value <= 0) revert NativeLiquidityPool__NotAboveZero(msg.value);
        if (tokenDeposit <= 0) revert NativeLiquidityPool__NotAboveZero(tokenDeposit);

        if (!i_token.transferFrom(msg.sender, address(this), tokenDeposit))
            revert NativeLiquidityPool__TokenTransferFailed();

        s_liquidityOf[msg.sender] = msg.value;
        s_poolLiquidity = msg.value;

        emit LiquidityAdded(msg.sender, msg.value, msg.value, tokenDeposit);
    }

    /**
     * @notice Function for providing liquidity to the pool
     * @dev The function uses `msg.value` to calculate the amount of tokens required
     * for deposit. The amount of tokens has to be calculated, because it and
     * `msg.value` have to be in ratio with the reserves of X and Y in the pool.
     * Otherwise, a random amount of tokens would change the price of the assets in the
     * pool. The amount of tokens required for a deposit of `msg.value` can be retrieved
     * by the getTokenAmountForNativeDeposit function.
     *
     * Before calling the function, the caller has to approve the liquidity pool
     * to transfer the amount of tokens required (getTokenAmountForNativeDeposit).
     * It is advised to set allowance at the ERC20 higher than the output of
     * getTokenAmountForNativeDeposit because of price fluctuations.
     *
     * This function reverts if the transfer of the required (calculated)
     * deposit of tokens fails.
     *
     * This function emits the {LiquidityAdded} event.
     */
    function provideLiquidity() external payable {
        uint256 xReservesMinusMsgValue = address(this).balance - msg.value;
        uint256 yReserves = i_token.balanceOf(address(this));

        uint256 tokenAmountRequired = (msg.value * yReserves) / xReservesMinusMsgValue;
        if (!i_token.transferFrom(msg.sender, address(this), tokenAmountRequired))
            revert NativeLiquidityPool__TokenTransferFailed();

        uint256 userLiquidity = (msg.value * s_poolLiquidity) / xReservesMinusMsgValue;

        s_liquidityOf[msg.sender] += userLiquidity;
        s_poolLiquidity += userLiquidity;

        emit LiquidityAdded(msg.sender, userLiquidity, msg.value, tokenAmountRequired);
    }

    /**
     * @notice Function for withdrawing liquidity from the pool
     * @param liquidityAmount is the amount of liquidity to be withdrawn
     * @dev The function calculates the amount of native and tokens eligible
     * for withdrawal and automatically transfers that amount to the caller.
     * The amount of native and tokens eligible is dependent on the pool reserves of both assets,
     * `liquidityAmount` and the total liquidity in the pool. The eligible amount of
     * the assets for withdrawal can be lower than the liquidity provided (Impermantent Loss),
     * but usually is greater than the amount provided, because of accumulating swap fees in
     * the liquidity pool.
     *
     * The function reverts if `liquidityAmount` exceeds the liquidity of the caller.
     * This function also reverts if the native transfer or ERC20 transfer fails.
     *
     * The function emits the {LiquidityRemoved} event.
     */
    function withdrawLiquidity(uint256 liquidityAmount) external {
        if (liquidityAmount > s_liquidityOf[msg.sender])
            revert NativeLiquidityPool__NotEnoughLiquidity();

        uint256 xReserves = address(this).balance;
        uint256 yReserves = i_token.balanceOf(address(this));
        uint256 l_poolLiquidity = s_poolLiquidity;

        uint256 xEligible = (liquidityAmount * xReserves) / l_poolLiquidity;
        uint256 yEligible = (liquidityAmount * yReserves) / l_poolLiquidity;

        s_liquidityOf[msg.sender] -= liquidityAmount;
        s_poolLiquidity -= liquidityAmount;

        if (!i_token.transfer(msg.sender, yEligible))
            revert NativeLiquidityPool__TokenTransferFailed();

        (bool successfulTransfer, ) = msg.sender.call{value: xEligible}("");
        if (!successfulTransfer) revert NativeLiquidityPool__NativeTransferFailed();

        emit LiquidityRemoved(msg.sender, liquidityAmount, xEligible, yEligible);
    }

    /**
     * @inheritdoc ILiquidityPool
     * @dev This function calls _swapXtoY or _swapYtoX depending on `direction`.
     * See _swapXtoY and _swapYtoX for more documentation
     */
    function swap(uint256 tokenAmount, SwapDirection direction) external payable override {
        if (direction == SwapDirection.xToY) _swapXtoY(msg.sender, msg.value);
        else if (direction == SwapDirection.yToX) _swapYtoX(msg.sender, tokenAmount);
    }

    /// @inheritdoc ILiquidityPool
    function approve(
        address approvee,
        uint256 amount,
        SwapDirection direction
    ) external override {
        s_allowanceOf[msg.sender][approvee] = Allowance(amount, direction);
        emit Approval(msg.sender, approvee, amount, direction);
    }

    /**
     * @inheritdoc ILiquidityPool
     * @dev This function calls _swapXtoY or _swapYtoX depending on `direction`.
     * See _swapXtoY and _swapYtoX for more documentation
     */
    function swapFrom(address from, uint256 tokenAmount) external payable override {
        Allowance memory l_allowance = s_allowanceOf[from][msg.sender];

        if (l_allowance.direction == SwapDirection.xToY) {
            if (msg.value > l_allowance.amount) revert NativeLiquidityPool__NotEnoughAllowance();

            s_allowanceOf[from][msg.sender].amount -= msg.value;

            _swapXtoY(from, msg.value);
        } else if (l_allowance.direction == SwapDirection.yToX) {
            if (tokenAmount > l_allowance.amount) revert NativeLiquidityPool__NotEnoughAllowance();

            s_allowanceOf[from][msg.sender].amount -= tokenAmount;

            _swapYtoX(from, tokenAmount);
        }
    }

    /**
     * @notice Function for calculating token or native output for swap
     * @param amount is the amount to be swapped
     * @param fromReserves are the reserves of the asset swapped from
     * @param outputReserves are the reserves of the output asset
     * @param fee is the fee (in 1/10 of percent) to be substracted
     * from the output
     * @return Output for swap of amount
     * @dev This function calculates the amount that one recieves
     * for swapping `amount`. The fee `fee` will be substracted from the
     * output
     */
    function calculateOutput(
        uint256 amount,
        uint256 fromReserves,
        uint256 outputReserves,
        uint256 fee
    ) internal pure returns (uint256) {
        uint256 amountMinusFee = amount * (1000 - fee);

        uint256 numerator = amountMinusFee * outputReserves;
        uint256 denominator = fromReserves * 1000 + amountMinusFee;
        return numerator / denominator;
    }

    /**
     * @notice Function for executing xToY swap
     * @param swapee is the address to swap from
     * @param amount is the amount of y (native, `msg.value` of swap or swapFrom) to be swapped
     * @dev The function transfers the output tokens (retrieved by calculateTokenOutput)
     * to `swapee`.
     *
     * This function reverts if the transfer of output tokens fails.
     *
     * This function emits the {Swap} event.
     */
    function _swapXtoY(address swapee, uint256 amount) internal {
        uint256 xReservesMinusMsgValue = address(this).balance - amount;
        uint256 yReserves = i_token.balanceOf(address(this));

        uint256 output = calculateOutput(amount, xReservesMinusMsgValue, yReserves, i_swapFee);

        if (!i_token.transfer(swapee, output)) revert NativeLiquidityPool__TokenTransferFailed();

        emit Swap(swapee, amount, output, SwapDirection.xToY);
    }

    /**
     * @notice Function for executing yToX swap
     * @param swapee is the address to swap from
     * @param amount is the amount of y (tokens) to be swapped
     * @dev The function transfers `amount` to the pool and in return transfers the
     * output tokens (retrieved by calculateTokenOutput) to `swapee`.
     *
     * This function reverts if the transfer of output tokens fails.
     *
     * This function emits the {Swap} event.
     */
    function _swapYtoX(address swapee, uint256 amount) internal {
        uint256 xReserves = address(this).balance;
        uint256 yReserves = i_token.balanceOf(address(this));

        uint256 output = calculateOutput(amount, yReserves, xReserves, i_swapFee);

        if (!i_token.transferFrom(swapee, address(this), amount))
            revert NativeLiquidityPool__TokenTransferFailed();

        (bool successfulTransfer, ) = swapee.call{value: output}("");
        if (!successfulTransfer) revert NativeLiquidityPool__NativeTransferFailed();

        emit Swap(swapee, amount, output, SwapDirection.yToX);
    }

    /// @inheritdoc ILiquidityPool
    function getKind() public pure override returns (Kind) {
        return LP_KIND;
    }

    /**
     * @notice Function for retrieving the address of ERC20 token
     * @return Address of ERC20 token
     */
    function getTokenAddress() public view returns (address) {
        return address(i_token);
    }

    /**
     * @notice Function for retrieving the total liquidity in the pool
     * @return Pool liquidity
     */
    function getPoolLiquidity() public view returns (uint256) {
        return s_poolLiquidity;
    }

    /**
     * @notice Function for retrieving liquidity of `addr`
     * @param addr is the address of the liquidity owner
     * @return Liquidity of `addr`
     */
    function getLiquidityOf(address addr) public view returns (uint256) {
        return s_liquidityOf[addr];
    }

    /// @inheritdoc ILiquidityPool
    function getAllowanceOf(address owner, address allowee)
        public
        view
        override
        returns (Allowance memory)
    {
        return s_allowanceOf[owner][allowee];
    }

    /**
     * @notice Function for retrieving token output for swap of `nativeAmount`.
     * Note that token output fluctuates with price and therefore changes constantly
     * @param nativeAmount is the amount of native to be swapped
     * @return Amount of tokens expected to be received for swap
     */
    function getTokenOutputForSwap(uint256 nativeAmount) public view returns (uint256) {
        uint256 xReserves = address(this).balance;
        uint256 yReserves = i_token.balanceOf(address(this));

        return calculateOutput(nativeAmount, xReserves, yReserves, i_swapFee);
    }

    /**
     * @notice Function for retrieving native output for swap of `tokenAmount`.
     * Note that native output fluctuates with price and therefore changes constantly
     * @param tokenAmount is the amount of tokens to be swapped
     * @return Amount of native expected to be received for swap
     */
    function getNativeOutputForSwap(uint256 tokenAmount) public view returns (uint256) {
        uint256 xReserves = address(this).balance;
        uint256 yReserves = i_token.balanceOf(address(this));

        return calculateOutput(tokenAmount, yReserves, xReserves, i_swapFee);
    }

    /**
     * @notice Function for retrieving the amount of tokens required, when providing
     * liquidity with `nativeAmount` to the pool.
     * Note that token amount fluctuates with price and therefore changes constantly
     * @param nativeAmount is the amount of native currency
     * @return Amount of tokens required for deposit of `nativeAmount`
     */
    function getTokenAmountForNativeDeposit(uint256 nativeAmount) public view returns (uint256) {
        uint256 xReserves = address(this).balance;
        uint256 yReserves = i_token.balanceOf(address(this));

        return (nativeAmount * yReserves) / xReserves;
    }

    /**
     * @notice Function for retrieving eligible amount of native when withdrawing
     * `liquidityAmount`.
     * Note that native output fluctuates with price and therefore changes constantly
     * @param liquidityAmount is the amount of liquidity to be withdrawn
     * @return Native output when withdrawing `liquidityAmount`
     */
    function getEligibleNativeOf(uint256 liquidityAmount) public view returns (uint256) {
        uint256 xReserves = address(this).balance;
        return (liquidityAmount * xReserves) / s_poolLiquidity;
    }

    /**
     * @notice Function for retrieving eligible amount of tokens when withdrawing
     * `liquidityAmount`.
     * Note that token output fluctuates with price and therefore changes constantly
     * @param liquidityAmount is the amount of liquidity to be withdrawn
     * @return Token output when withdrawing `liquidityAmount`
     */
    function getEligibleTokensOf(uint256 liquidityAmount) public view returns (uint256) {
        uint256 yReserves = i_token.balanceOf(address(this));
        return (liquidityAmount * yReserves) / s_poolLiquidity;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ILiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice Thrown when `value` is not above zero
error TokenLiquidityPool__NotAboveZero(uint256 value);
/// @notice Thrown when transfer of tokens at erc20 contract `tokenAddress` fails
error TokenLiquidityPool__TokenTransferFailed(address tokenAddress);
/// @notice Thrown when requested liquidity amount for withdrawal exceeds actual liquidity
error TokenLiquidityPool__NotEnoughLiquidity();
/// @notice Thrown when caller sends native currency (eth) to the contract
error TokenLiquidityPool__NativeNotAccepted();
/// @notice Thrown when requested amount to swap is smaller than allowance
error TokenLiquidityPool__NotEnoughAllowance();

/**
 * @title TokenLiquidityPool
 * @author Philipp Keinberger
 * @notice This contract is a liquidity pool, where users can swap between two ERC20
 * tokens. Users can also provide liquidity to the pool, while accumulating rewards
 * over time from the swap fee. Liquidity can be withdrawn at all times. Users can
 * swap tokens on behalf of other users by using the Allowance feature. In order to use
 * that feature, one has to approve another user for future swaps on ones own behalf.
 * @dev This contract implements the ILiquidityPool interface to allow for standardized
 * liquidity pool functionality for exchanges.
 *
 * This contract also implements the IERC20 Openzeppelin inteface for the ERC20 token
 * standard.
 *
 * The TokenLiquidityPool inherits from Openzeppelins Ownable contract to allow for
 * owner features. It also inherits from Openzeppelins Initializable contract to allow
 * for a safe initialize function, favourably used by exchanges to initialize the
 * liquidity pool.
 */
contract TokenLiquidityPool is Ownable, Initializable, ILiquidityPool {
    Kind private constant LP_KIND = Kind.TokenLiquidityPool;
    IERC20 private immutable i_xToken;
    IERC20 private immutable i_yToken;
    /// @dev fee in 1/10 percent (i_swapFee = 1, => 0.1 percent)
    uint16 private immutable i_swapFee;

    uint256 private s_poolLiquidity;
    /// @dev userAddress => liquidity
    mapping(address => uint256) private s_liquidityOf;
    /// @dev userAddress => allowedUser => Allowance
    mapping(address => mapping(address => Allowance)) private s_allowanceOf;

    /// @notice Event emitted when new liquidity is provided (added) to the pool
    event LiquidityAdded(
        address liquidityProvider,
        uint256 liquidityAmount,
        uint256 xDeposit,
        uint256 yDeposit
    );
    /// @notice Event emitted when liquidity is withdrawn (removed) from the pool
    event LiquidityRemoved(
        address liquidityProvider,
        uint256 liquidityAmount,
        uint256 xWithdrawn,
        uint256 yWithdrawn
    );

    constructor(
        address xAddress,
        address yAddress,
        uint16 swapFee
    ) {
        i_xToken = IERC20(xAddress);
        i_yToken = IERC20(yAddress);
        i_swapFee = swapFee;
    }

    /**
     * @notice Function for initializing (setting up) the liquidity pool
     * @param xDeposit is the amount deposited from xToken
     * @param yDeposit is the mamount deposited from yToken
     * @dev This function initializes the liquidity pool with `xDeposit` for x
     * and `yDeposit` for y.
     * This function reverts if the caller is not the owner of the contract.
     * The function also reverts if `xDeposit` or `yDeposit` is not greater than zero.
     * If the transfer of `xDeposit` from xToken fails or the transfer of `yDeposit`
     * from yToken fails, the function will revert.
     *
     * Note that this function can only be called once.
     */
    function initialize(uint256 xDeposit, uint256 yDeposit) external onlyOwner initializer {
        if (xDeposit <= 0) revert TokenLiquidityPool__NotAboveZero(xDeposit);
        if (yDeposit <= 0) revert TokenLiquidityPool__NotAboveZero(yDeposit);

        if (!i_xToken.transferFrom(msg.sender, address(this), xDeposit))
            revert TokenLiquidityPool__TokenTransferFailed(address(i_xToken));
        if (!i_yToken.transferFrom(msg.sender, address(this), yDeposit))
            revert TokenLiquidityPool__TokenTransferFailed(address(i_yToken));

        s_liquidityOf[msg.sender] = xDeposit;
        s_poolLiquidity = xDeposit;

        emit LiquidityAdded(msg.sender, xDeposit, xDeposit, yDeposit);
    }

    /**
     * @notice Function for providing liquidity to the pool
     * @param xDeposit is the amount deposited from xToken
     * @dev The function uses `xDeposit` to calculate the amount of Y required
     * for deposit. The amount of Y has to be calculated, because it and `xDeposit`
     * have to be in ratio with the reserves of X and Y in the pool. Otherwise,
     * a random amount of Y would change the price of the assets in the pool.
     * The amount of Y required for a deposit of `xDeposit` can be retrieved by the
     * getYAmountForDepositOfX function.
     *
     * Before calling the function, the caller has to approve the liquidity pool
     * to transfer `xDeposit` at xToken and the amount of Y required at yToken.
     * It is advised to set allowance at yToken higher than the output of
     * getYAmountForDepositOfX because of price fluctuations.
     *
     * This function reverts if the transfer of `xDeposit` or the required
     * (calculated) deposit of Y fails.
     *
     * This function emits the {LiquidityAdded} event.
     */
    function provideLiquidity(uint256 xDeposit) external {
        uint256 xReserves = i_xToken.balanceOf(address(this));
        uint256 yReserves = i_yToken.balanceOf(address(this));

        uint256 requiredDepositOfY = (xDeposit * yReserves) / xReserves;

        if (!i_xToken.transferFrom(msg.sender, address(this), xDeposit))
            revert TokenLiquidityPool__TokenTransferFailed(address(i_xToken));

        if (!i_yToken.transferFrom(msg.sender, address(this), requiredDepositOfY))
            revert TokenLiquidityPool__TokenTransferFailed(address(i_yToken));

        uint256 userLiquidity = (xDeposit * s_poolLiquidity) / xReserves;
        s_liquidityOf[msg.sender] += userLiquidity;
        s_poolLiquidity += userLiquidity;

        emit LiquidityAdded(msg.sender, userLiquidity, xDeposit, requiredDepositOfY);
    }

    /**
     * @notice Function for withdrawing liquidity from the pool
     * @param liquidityAmount is the amount of liquidity to be withdrawn
     * @dev The function calculates the amount of x and y eligible
     * for withdrawal and automatically transfers that amount to the caller.
     * The amount of x and y eligible is dependent on the pool reserves of both assets,
     * `liquidityAmount` and the total liquidity in the pool. The eligible amount of
     * the assets for withdrawal can be lower than the liquidity provided (Impermantent Loss),
     * but usually is greater than the amount provided, because of accumulating swap fees in
     * the liquidity pool.
     *
     * The function reverts if `liquidityAmount` exceeds the liquidity of the caller.
     * This function also reverts if the transfer of the amount of x or y eligible fails.
     *
     * The function emits the {LiquidityRemoved} event.
     */
    function withdrawLiquidity(uint256 liquidityAmount) external {
        if (liquidityAmount > s_liquidityOf[msg.sender])
            revert TokenLiquidityPool__NotEnoughLiquidity();

        uint256 xReserves = i_xToken.balanceOf(address(this));
        uint256 yReserves = i_yToken.balanceOf(address(this));
        uint256 l_poolLiquidity = s_poolLiquidity;

        uint256 xEligible = (liquidityAmount * xReserves) / l_poolLiquidity;
        uint256 yEligible = (liquidityAmount * yReserves) / l_poolLiquidity;

        s_liquidityOf[msg.sender] -= liquidityAmount;
        s_poolLiquidity -= liquidityAmount;

        if (!i_xToken.transfer(msg.sender, xEligible))
            revert TokenLiquidityPool__TokenTransferFailed(address(i_xToken));
        if (!i_yToken.transfer(msg.sender, yEligible))
            revert TokenLiquidityPool__TokenTransferFailed(address(i_yToken));

        emit LiquidityRemoved(msg.sender, liquidityAmount, xEligible, yEligible);
    }

    /**
     * @inheritdoc ILiquidityPool
     * @dev This function calls _swap (see _swap for more documentation)
     */
    function swap(uint256 tokenAmount, SwapDirection direction) external payable override {
        if (msg.value > 0) revert TokenLiquidityPool__NativeNotAccepted();
        _swap(msg.sender, tokenAmount, direction);
    }

    /// @inheritdoc ILiquidityPool
    function approve(
        address approvee,
        uint256 amount,
        SwapDirection direction
    ) external override {
        s_allowanceOf[msg.sender][approvee] = Allowance(amount, direction);
        emit Approval(msg.sender, approvee, amount, direction);
    }

    /**
     * @inheritdoc ILiquidityPool
     * @dev This function calls _swap (see _swap for more documentation)
     */
    function swapFrom(address from, uint256 amount) external payable override {
        if (msg.value > 0) revert TokenLiquidityPool__NativeNotAccepted();

        Allowance memory l_allowance = s_allowanceOf[from][msg.sender];
        if (amount > l_allowance.amount) revert TokenLiquidityPool__NotEnoughAllowance();

        s_allowanceOf[from][msg.sender].amount -= amount;

        _swap(from, amount, l_allowance.direction);
    }

    /**
     * @notice Function for calculating token output for swap
     * @param amount is the amount to be swapped
     * @param fromTokenReserves are the reserves of the token swapped from
     * @param outputTokenReserves are the reserves of the output token
     * @param fee is the fee (in 1/10 of percent) to be substracted
     * from the token output
     * @return Token output for swap of amount
     * @dev This function calculates the amount of tokens, that one recieves
     * for swapping `amount`. The fee `fee` will be substracted from the token
     * output
     */
    function calculateTokenOutput(
        uint256 amount,
        uint256 fromTokenReserves,
        uint256 outputTokenReserves,
        uint256 fee
    ) internal pure returns (uint256) {
        uint256 amountMinusFee = amount * (1000 - fee);

        uint256 numerator = amountMinusFee * outputTokenReserves;
        uint256 denominator = fromTokenReserves * 1000 + amountMinusFee;
        return numerator / denominator;
    }

    /**
     * @notice Function for executing token swap
     * @param swapee is the address to swap from
     * @param amount is the amount to be swapped
     * @param direction defines the direction of the swap (xToY or yToX)
     * @dev The function transfers `amount` to the pool and in return transfers
     * the output tokens (retrieved by calculateTokenOutput) to `swapee`.
     *
     * This function reverts if the transfer of `amount` or output tokens fails.
     *
     * This function emits the {Swap} event.
     */
    function _swap(
        address swapee,
        uint256 amount,
        SwapDirection direction
    ) internal {
        IERC20 fromToken;
        IERC20 outputToken;

        if (direction == SwapDirection.xToY) {
            fromToken = IERC20(i_xToken);
            outputToken = IERC20(i_yToken);
        } else if (direction == SwapDirection.yToX) {
            fromToken = IERC20(i_yToken);
            outputToken = IERC20(i_xToken);
        }

        uint256 tokenFromReserves = fromToken.balanceOf(address(this));
        uint256 tokenInReserves = outputToken.balanceOf(address(this));

        uint256 tokenOutput = calculateTokenOutput(
            amount,
            tokenFromReserves,
            tokenInReserves,
            i_swapFee
        );

        if (!fromToken.transferFrom(swapee, address(this), amount))
            revert TokenLiquidityPool__TokenTransferFailed(address(fromToken));

        if (!outputToken.transfer(swapee, tokenOutput))
            revert TokenLiquidityPool__TokenTransferFailed(address(outputToken));

        emit Swap(msg.sender, amount, tokenOutput, direction);
    }

    /// @inheritdoc ILiquidityPool
    function getKind() public pure override returns (Kind) {
        return LP_KIND;
    }

    /**
     * @notice Function for retrieving the address of x token
     * @return Address of x token
     */
    function getXTokenAddress() public view returns (address) {
        return address(i_xToken);
    }

    /**
     * @notice Function for retrieving the address of y token
     * @return Address of y token
     */
    function getYTokenAddress() public view returns (address) {
        return address(i_yToken);
    }

    /**
     * @notice Function for retrieving the total liquidity in the pool
     * @return Pool liquidity
     */
    function getPoolLiquidity() public view returns (uint256) {
        return s_poolLiquidity;
    }

    /**
     * @notice Function for retrieving liquidity of `addr`
     * @param addr is the address of the liquidity owner
     * @return Liquidity of `addr`
     */
    function getLiquidityOf(address addr) public view returns (uint256) {
        return s_liquidityOf[addr];
    }

    /// @inheritdoc ILiquidityPool
    function getAllowanceOf(address owner, address allowee)
        public
        view
        override
        returns (Allowance memory)
    {
        return s_allowanceOf[owner][allowee];
    }

    /**
     * @notice Function for retrieving y token output for swap of x tokens `xAmount`
     * Note that token output fluctuates with price and therefore changes constantly
     * @param xAmount is the amount of x tokens to be swapped
     * @return Amount of y tokens expected to be received for swap
     */
    function getYTokenOutputForSwap(uint256 xAmount) public view returns (uint256) {
        uint256 xReserves = i_xToken.balanceOf(address(this));
        uint256 yReserves = i_yToken.balanceOf(address(this));

        return calculateTokenOutput(xAmount, xReserves, yReserves, i_swapFee);
    }

    /**
     * @notice Function for retrieving x token output for swap of y tokens `yAmount`
     * Note that token output fluctuates with price and therefore changes constantly
     * @param yAmount is the amount of y tokens to be swapped
     * @return Amount of x tokens expected to be received for swap
     */
    function getXTokenOutputForSwap(uint256 yAmount) public view returns (uint256) {
        uint256 yReserves = i_yToken.balanceOf(address(this));
        uint256 xReserves = i_xToken.balanceOf(address(this));

        return calculateTokenOutput(yAmount, yReserves, xReserves, i_swapFee);
    }

    /**
     * @notice Function for retrieving the amount of y tokens required, when providing
     * liquidity with `xAmount` to the pool
     * Note that y amount fluctuates with price and therefore changes constantly
     * @param xAmount is the amount of x tokens
     * @return Amount of y tokens required for deposit of `xAmount`
     */
    function getYAmountForDepositOfX(uint256 xAmount) public view returns (uint256) {
        uint256 xReserves = i_xToken.balanceOf(address(this));
        uint256 yReserves = i_yToken.balanceOf(address(this));

        return (xAmount * yReserves) / xReserves;
    }

    /**
     * @notice Function for retrieving eligible amount of x tokens when withdrawing
     * `liquidityAmount`
     * Note that x token output fluctuates with price and therefore changes constantly
     * @param liquidityAmount is the amount of liquidity to be withdrawn
     * @return X token output when withdrawing `liquidityAmount`
     */
    function getEligibleXOf(uint256 liquidityAmount) public view returns (uint256) {
        uint256 xReserves = i_xToken.balanceOf(address(this));
        return (liquidityAmount * xReserves) / s_poolLiquidity;
    }

    /**
     * @notice Function for retrieving eligible amount of y tokens when withdrawing
     * `liquidityAmount`
     * Note that y token output fluctuates with price and therefore changes constantly
     * @param liquidityAmount is the amount of liquidity to be withdrawn
     * @return Y token output when withdrawing `liquidityAmount`
     */
    function getEligibleYOf(uint256 liquidityAmount) public view returns (uint256) {
        uint256 yReserves = i_yToken.balanceOf(address(this));
        return (liquidityAmount * yReserves) / s_poolLiquidity;
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