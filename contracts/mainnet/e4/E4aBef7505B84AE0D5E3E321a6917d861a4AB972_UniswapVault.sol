// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../lib/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IDeCommasStrategyRouter.sol";
import "../integrations/perpetual/IClearingHouse.sol";
import "../integrations/perpetual/IVault.sol";
import "../integrations/uniswap/IV3SwapRouter.sol";
import "../integrations/perpetual/IIndexPrice.sol";
import "../integrations/stargate/ISgBridge.sol";
import "../integrations/perpetual/IAccountBalance.sol";
import "../integrations/perpetual/IClearingHouseConfig.sol";
import "../integrations/perpetual/IExchange.sol";
import "../interfaces/IDeCommasVault.sol";
import "./BaseBuildingBlock.sol";


/**
    @author DeCommas team
    @title Perp protocol interface to open and close positions for specific pair and leverage size.
 */
/* solhint-disable */
contract UniswapVault is OwnableUpgradeable, PausableUpgradeable, IDeCommasVault, BaseBuildingBlock {

    IDeCommasStrategyRouter public _deCommasStrategyRouter;

    address _uniswapRouterV3;
    address public _usdcToken;
    address public _wToken;
    uint24  public _feeToPair;
    uint160 public _sqrtPriceLimitX96toUni;
    uint256 constant public slippageTolerance = 50000000000000000; //5%

    // the restriction on when this tx should be executed; otherwise, it fails
    uint160 public _deadlineTime;

    event PositionAdjusted(bool operationType,
        uint256 usdcAmount,
        uint256 ethAmount);

    event USDCDeposited(address indexed timeStamp, uint256 amount);
    event Bridged(uint256 amount, address token1, address token2, address sender);
    event USDCWithdrawn(address sender, uint256 amount);
    /**
      * @dev Sets the addresses for USDC stableCoin, wETH token address,UniswapRouter, Perpetual ClearingHouse,
    * Perpetual Vault(AccountBalance contract), Perpetual vToken for Strategy,
    * initialize to base shares for position
    */
    function initialize(
        IDeCommasStrategyRouter deCommasStrategyRouter_,
        address uniswapRouterV3_,
        address usdcToken_,
        address wToken_,
        uint24 feeToPair_,
        uint160 deadlineTime_,
        uint160 sqrtPriceLimitX96toUni_
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        _deCommasStrategyRouter = IDeCommasStrategyRouter(deCommasStrategyRouter_);
        _uniswapRouterV3 = uniswapRouterV3_;
        _usdcToken = usdcToken_;
        _wToken = wToken_;
        _feeToPair = feeToPair_;
        _deadlineTime = deadlineTime_;
        _sqrtPriceLimitX96toUni = sqrtPriceLimitX96toUni_;

        IERC20(_usdcToken).approve(address(_uniswapRouterV3), type(uint256).max);
        IERC20(_wToken).approve(address(_uniswapRouterV3), type(uint256).max);
    }


    modifier onlyDeCommasRouter(){
        require(_msgSender() == address(_deCommasStrategyRouter),
            "DcPVLT: Caller isn't deCommas router");
        _;
    }

    // @notice Puts the token on pause, external operations are not available after
    // access: ADMIN
    function pause() external override onlyOwner {
        _pause();
    }

    // @notice Switch off the pause
    // access: ADMIN
    function unpause() external override onlyOwner {
        _unpause();
    }


    /**
    * @dev User can to deposit USDC for strategy
    * @param _data encoded amount USDC token amount
    * @notice deposit USDC to the strategy. User will receive LP tokens proportionally to the pool share
    */
    function deposit(bytes memory _data) public override whenNotPaused {
        (uint256 amount) = abi.decode(_data, (uint256));
        require(amount != 0, "DcPVLT: zero amount");

        require(IERC20(_usdcToken).transferFrom(_msgSender(), address(this), amount), "DcPVLT: usdc transfer failed");
        emit USDCDeposited(_msgSender(), amount);
    }

    /**
    * @notice Function to Adjust/open -short-long and fullclose positions
    * @dev User must deposit usdc prior to calling this method
    */
    function adjustPosition(bytes memory _data) public override whenNotPaused {
        (bool operationType, uint256 amount) = abi.decode(_data,(bool,uint256));
        require(amount != 0, "DcPVLT: zero amount");
        if (operationType) {
                uint256 ethAmount = swapExactInput(_usdcToken, _wToken, amount);
                emit PositionAdjusted(operationType,
                    amount,
                    ethAmount);
        } else {
            revert("Not supported");
        }
    }

    /**
     *  @notice Router Withdraw USDC
     *  @param _data decode: amount to withdraw usdc
     *  @dev closes position if amount is bigger than reserves usdc
     */
    function withdrawUSDC(bytes memory _data) public whenNotPaused  {
        (uint256 amount) = abi.decode(_data,(uint256));
        require(amount != 0, "DcPVLT: zero amount");
        uint256 poolShare = amount / getReserve();
        uint256 result = Math.mulDiv(getTotalUSDCValue(), poolShare, 1e18);
        require(result <= getTotalUSDCValue(), "DcPVLT: trying to withdraw more than pool contains");

        require(IERC20(_usdcToken).transfer(_msgSender(), result), "DcPVLT: usdc transfer failed");
        emit USDCWithdrawn(_msgSender(), result);
    }

    function _calculateAmountToPosition(uint256 amount, uint256 share) internal pure returns (uint256) {
        return (amount * share) / 100;
    }

    function _fullClose() internal {
        if (IERC20(_wToken).balanceOf(address(this)) > 0) {
            swapExactInput(_wToken, _usdcToken, IERC20(_wToken).balanceOf(address(this)));
        }
        emit PositionAdjusted(false, IERC20(_usdcToken).balanceOf(address(this)), 0);
    }


    /**
    * @notice Cross chain usdc withdrawals
    * @param _data : decode to
    * @dev vaultLZId LayerZero chain Id
    * @dev nativeStableToken Token address to rbidge
    * @dev destinationStableToken Destination token address to redeem bridged asset
    * @dev sgBridge Star Gate bridge address
    * @dev targetRouter Target remote router address
    * @dev stableAmount amount to wirhdraw
    */
    function bridgeToRouterBack(bytes memory _data) external payable whenNotPaused{
        (uint16 vaultLZId,
        address nativeStableToken,
        address destinationStableToken,
        address sgBridge,
        address targetRouter,
        uint256 stableAmount) = abi.decode(_data, (uint16, address, address, address, address, uint256));

        IERC20(nativeStableToken).approve(sgBridge, stableAmount);

        ISgBridge(sgBridge).bridge{value: msg.value}(nativeStableToken,
            stableAmount,
            vaultLZId,
            targetRouter,
            destinationStableToken
        );
        emit Bridged(stableAmount,nativeStableToken,destinationStableToken,targetRouter);
    }
    /**
    * @notice USDC on the strategy balance
    */
    function getReserve() public view returns (uint256) {
        return (IERC20(_usdcToken).balanceOf(address(this)));
    }

    /**
    * @notice Strategy worth nominated in the USDC
    */
    function getTotalUSDCValue() public view returns (uint256) {
        return getReserve();
    }

    function _abs(int256 value) private pure returns (uint256) {
        return value >= 0 ? uint256(value) : uint256(- value);
    }


    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    }
    /**
    * Updste uniswap trade params in case of fee change or net congestion
    */
    function updateSwapInfo(
        uint24 feeToPair_,
        uint160 deadlineTime_,
        uint160 sqrtPriceLimitX96toUni_
    ) external {
        _feeToPair =  feeToPair_;
        _deadlineTime =  deadlineTime_;
        _sqrtPriceLimitX96toUni =  sqrtPriceLimitX96toUni_;
    }


    /**
    * @notice swap exact imput single to uniswap v3
    * @param _tokenA address
    * @param _tokenB address
    * @param _amount to swap
    * @return amountOut of tokenB
     */
    function swapExactInput(address _tokenA, address _tokenB, uint256 _amount) internal returns(uint256){
        return IV3SwapRouter(_uniswapRouterV3).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: _tokenA,
                tokenOut: _tokenB,
                fee: _feeToPair,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: _sqrtPriceLimitX96toUni
            }
        ));
    }

    /**
    * @notice swap exact imput single to uniswap v3
    * @param _tokenA address
    * @param _tokenB address
    * @param _amount to swap
    * @param _amountInMaximum max in
    * @dev We want to sell `tokenA` for `tokenB` and receive `amount` of `tokenB`
    * @dev We want to spend no more than `amountInMaximum` of tokenA
    * @return amountOut of tokenB
     */
    function swapExactOutput(address _tokenA, address _tokenB, uint256 _amount, uint256 _amountInMaximum) internal returns(uint256){
        uint256 _amountInMax = _amountInMaximum;
        if (_amountInMaximum == 0) {
            _amountInMax = Math.mulDiv(_amount, slippageTolerance + 1e18, 1e18);
        }
        return IV3SwapRouter(_uniswapRouterV3).exactOutputSingle(
            IV3SwapRouter.ExactOutputSingleParams({
        tokenIn: _tokenA,
        tokenOut: _tokenB,
        fee: _feeToPair,
        recipient: address(this),
        deadline: block.timestamp,
        amountOut: _amount,
        amountInMaximum: _amountInMax,
        sqrtPriceLimitX96: _sqrtPriceLimitX96toUni
        }));
    }

    function borrow(address baseAsset, uint256 amount, bool /*positionType*/) external{
        revert("Unsupported operation.");
    }
    function repay(address baseAsset, uint256 amount, bool /*positionType*/) external{
        revert("Unsupported operation.");
    }
    function openPosition(address baseAsset, uint256 amount,  bool positionType) external{
        revert("Unsupported operation.");
    }
    function closePosition(address baseAsset, uint256 amount, bool /*positionType*/) external{
        revert("Unsupported operation.");
    }
    function claim(address /*baseAsset*/, uint256 amount, bool /*positionType*/) external{
        revert("Unsupported operation.");
    }
    function submitNativeToken(address /*baseAsset*/, uint256 amount, bool /*positionType*/) external payable{
        revert("Unsupported operation.");
    }
    function withdrawNativeToken(address /*baseAsset*/, uint256 amount, bool /*positionType*/) external payable{
        revert("Unsupported operation.");
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/* solhint-disable */

import "./FixedPoint96.sol";

library Math {
    /// @notice Calculates floor(a×b÷denominator) with full precision.
    /// Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
    
    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }
    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }
    
}
/* solhint-enable */

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

interface IDeCommasStrategyRouter {

    function deposit(uint256 strategyId, uint256 stableAmount) external;


    function withdraw(uint256 strategyId, uint256 deTokenAmount) external ;


    function withdrawOrdersToUser(address user, uint256 strategyId, uint256 tvl) external;


    function startStrategyList(uint256 strategyId) external;


    function stopStrategyList(uint256 strategyId) external;


    function bridge(address nativeStableToken,
                    uint256 stableAmount,
                    uint16 vaultLZId,
                    address vaultAddress,
                    address destinationStableToken) external;


    function adjustPosition(uint256 strategyId,
                            uint16 vaultLZId,
                            address vault1,
                            string memory func,
                            bytes memory _actionData) external payable;


    function setRemote(uint16 _chainId, bytes calldata _remoteAddress) external;


    function getDeCommasRegister() external view returns(address);


    function isDeCommasActionStrategy(uint256 strategyId) external view returns(bool);


    function getNativeChainId() external view returns(uint16) ;


    function getNativeLZEndpoint() external view returns(address);


    function getNativeSGBridge() external view returns(address);


    function getStrategyInfo(uint256 strategyId) external view returns(bool status,
                                                                        uint16 sgId1Vault,
                                                                        uint16 sgId2Vault);


    function getUserShares(address user, uint256 strategyId) external view returns(uint256);


    function getPendingTokensToWithdraw(address user, uint256 strategyId) external view returns(uint256);


    function totalSupply(uint256 strategyId) external view returns(uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IClearingHouse {
    /// @param useTakerBalance only accept false now
    struct AddLiquidityParams {
        address baseToken;
        uint256 base;
        uint256 quote;
        int24 lowerTick;
        int24 upperTick;
        uint256 minBase;
        uint256 minQuote;
        bool useTakerBalance;
        uint256 deadline;
    }

    /// @param liquidity collect fee when 0
    struct RemoveLiquidityParams {
        address baseToken;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        uint256 minBase;
        uint256 minQuote;
        uint256 deadline;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
        uint256 liquidity;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
    }

    /// @param oppositeAmountBound
    // B2Q + exact input, want more output quote as possible, so we set a lower bound of output quote
    // B2Q + exact output, want less input base as possible, so we set a upper bound of input base
    // Q2B + exact input, want more output base as possible, so we set a lower bound of output base
    // Q2B + exact output, want less input quote as possible, so we set a upper bound of input quote
    // when it's set to 0, it will disable slippage protection entirely regardless of exact input or output
    // when it's over or under the bound, it will be reverted
    /// @param sqrtPriceLimitX96
    // B2Q: the price cannot be less than this value after the swap
    // Q2B: the price cannot be greater than this value after the swap
    // it will fill the trade until it reaches the price limit but WON'T REVERT
    // when it's set to 0, it will disable price limit;
    // when it's 0 and exact output, the output amount is required to be identical to the param amount
    struct OpenPositionParams {
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint256 deadline;
        uint160 sqrtPriceLimitX96;
        bytes32 referralCode;
    }

    struct ClosePositionParams {
        address baseToken;
        uint160 sqrtPriceLimitX96;
        uint256 oppositeAmountBound;
        uint256 deadline;
        bytes32 referralCode;
    }

    struct CollectPendingFeeParams {
        address trader;
        address baseToken;
        int24 lowerTick;
        int24 upperTick;
    }

    event ReferredPositionChanged(bytes32 indexed referralCode);

    event PositionLiquidated(
        address indexed trader,
        address indexed baseToken,
        uint256 positionNotional,
        uint256 positionSize,
        uint256 liquidationFee,
        address liquidator
    );

    /// @param base the amount of base token added (> 0) / removed (< 0) as liquidity; fees not included
    /// @param quote the amount of quote token added ... (same as the above)
    /// @param liquidity the amount of liquidity unit added (> 0) / removed (< 0)
    /// @param quoteFee the amount of quote token the maker received as fees
    event LiquidityChanged(
        address indexed maker,
        address indexed baseToken,
        address indexed quoteToken,
        int24 lowerTick,
        int24 upperTick,
        int256 base,
        int256 quote,
        int128 liquidity,
        uint256 quoteFee
    );

    event PositionChanged(
        address indexed trader,
        address indexed baseToken,
        int256 exchangedPositionSize,
        int256 exchangedPositionNotional,
        uint256 fee,
        int256 openNotional,
        int256 realizedPnl,
        uint256 sqrtPriceAfterX96
    );

    /// @param fundingPayment > 0: payment, < 0 : receipt
    event FundingPaymentSettled(address indexed trader, address indexed baseToken, int256 fundingPayment);

    event TrustedForwarderChanged(address indexed forwarder);

    /// @dev tx will fail if adding base == 0 && quote == 0 / liquidity == 0
    function addLiquidity(AddLiquidityParams calldata params) external returns (AddLiquidityResponse memory);

    function removeLiquidity(RemoveLiquidityParams calldata params) external returns
                                                            (RemoveLiquidityResponse memory response);

    function settleAllFunding(address trader) external;

    function openPosition(OpenPositionParams memory params) external returns (uint256 base, uint256 quote);

    function closePosition(ClosePositionParams calldata params) external returns (uint256 base, uint256 quote);

    function liquidate(address trader, address baseToken) external;

    function cancelExcessOrders(
        address maker,
        address baseToken,
        bytes32[] calldata orderIds
    ) external;

    function cancelAllExcessOrders(address maker, address baseToken) external;

    /// @dev accountValue = totalCollateralValue + totalUnrealizedPnl, in 18 decimals
    function getAccountValue(address trader) external view returns (int256);

    function getQuoteToken() external view returns (address);

    function getUniswapV3Factory() external view returns (address);

    function getClearingHouseConfig() external view returns (address);

    function getVault() external view returns (address);

    function getExchange() external view returns (address);

    function getOrderBook() external view returns (address);

    function getAccountBalance() external view returns (address);

    function getInsuranceFund() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IVault {
    /// @notice Emitted when trader deposit collateral into vault
    /// @param collateralToken The address of token deposited
    /// @param trader The address of trader
    /// @param amount The amount of token deposited
    event Deposited(address indexed collateralToken, address indexed trader, uint256 amount);

    /// @notice Emitted when trader withdraw collateral from vault
    /// @param collateralToken The address of token withdrawn
    /// @param trader The address of trader
    /// @param amount The amount of token withdrawn
    event Withdrawn(address indexed collateralToken, address indexed trader, uint256 amount);

    /// @notice Emitted when a trader's collateral is liquidated
    /// @param trader The address of trader
    /// @param collateralToken The address of the token that is liquidated
    /// @param liquidator The address of liquidator
    /// @param collateral The amount of collateral token liquidated
    /// @param repaidSettlementWithoutInsuranceFundFeeX10_S The amount of settlement token repaid
    ///        for trader (in settlement token's decimals)
    /// @param insuranceFundFeeX10_S The amount of insurance fund fee paid(in settlement token's decimals)
    /// @param discountRatio The discount ratio of liquidation price
    event CollateralLiquidated(
        address indexed trader,
        address indexed collateralToken,
        address indexed liquidator,
        uint256 collateral,
        uint256 repaidSettlementWithoutInsuranceFundFeeX10_S,
        uint256 insuranceFundFeeX10_S,
        uint24 discountRatio
    );

    /// @notice Emitted when trustedForwarder is changed
    /// @dev trustedForwarder is only used for metaTx
    /// @param trustedForwarder The address of trustedForwarder
    event TrustedForwarderChanged(address indexed trustedForwarder);

    /// @notice Emitted when clearingHouse is changed
    /// @param clearingHouse The address of clearingHouse
    event ClearingHouseChanged(address indexed clearingHouse);

    /// @notice Emitted when collateralManager is changed
    /// @param collateralManager The address of collateralManager
    event CollateralManagerChanged(address indexed collateralManager);

    /// @notice Emitted when WETH9 is changed
    /// @param WETH9 The address of WETH9
    event WETH9Changed(address indexed WETH9);

    /// @notice Deposit collateral into vault
    /// @param token The address of the token to deposit
    /// @param amount The amount of the token to deposit
    function deposit(address token, uint256 amount) external;

    /// @notice Deposit the collateral token for other account
    /// @param to The address of the account to deposit to
    /// @param token The address of collateral token
    /// @param amount The amount of the token to deposit
    function depositFor(
        address to,
        address token,
        uint256 amount
    ) external;

    /// @notice Deposit ETH as collateral into vault
    function depositEther() external payable;

    /// @notice Deposit ETH as collateral for specified account
    /// @param to The address of the account to deposit to
    function depositEtherFor(address to) external payable;

    /// @notice Withdraw collateral from vault
    /// @param token The address of the token to withdraw
    /// @param amount The amount of the token to withdraw
    function withdraw(address token, uint256 amount) external;

    /// @notice Withdraw ETH from vault
    /// @param amount The amount of the ETH to withdraw
    function withdrawEther(uint256 amount) external;

    /// @notice Liquidate trader's collateral by given settlement token amount or non settlement token amount
    /// @param trader The address of trader that will be liquidated
    /// @param token The address of non settlement collateral token that the trader will be liquidated
    /// @param amount The amount of settlement token that the liquidator will repay for trader or
    ///               the amount of non-settlement collateral token that the liquidator will charge from trader
    /// @param isDenominatedInSettlementToken Whether the amount is denominated in settlement token or not
    /// @return amount The amount of a non-settlement token (in its native decimals) that is liquidated
    ///         when `isDenominatedInSettlementToken` is true or the amount of settlement token that is repaid
    ///         when `isDenominatedInSettlementToken` is false
    function liquidateCollateral(
        address trader,
        address token,
        uint256 amount,
        bool isDenominatedInSettlementToken
    ) external returns (uint256);

    /// @notice Get the specified trader's settlement token balance, without pending fee, funding payment
    ///         and owed realized PnL
    /// @dev The function is equivalent to `getBalanceByToken(trader, settlementToken)`
    ///      We keep this function solely for backward-compatibility with the older single-collateral system.
    ///      In practical applications, the developer might want to use `getSettlementTokenValue()` instead
    ///      because the latter includes pending fee, funding payment etc.
    ///      and therefore more accurately reflects a trader's settlement (ex. USDC) balance
    /// @return balance The balance amount (in settlement token's decimals)
    function getBalance(address trader) external view returns (int256 balance);

    /// @notice Get the balance of Vault of the specified collateral token and trader
    /// @param trader The address of the trader
    /// @param token The address of the collateral token
    /// @return balance The balance amount (in its native decimals)
    function getBalanceByToken(address trader, address token) external view returns (int256 balance);

    /// @notice Get they array of collateral token addresses that a trader has
    /// @return collateralTokens array of collateral token addresses
    function getCollateralTokens(address trader) external view returns (address[] memory collateralTokens);

    /// @notice Get account value (denominated in settlement token) of the specified trader
    /// @param trader The address of the trader
    /// @return accountValue account value (in settlement token's decimals)
    function getAccountValue(address trader) external view returns (int256);

    /// @notice Get the free collateral value denominated in the settlement token of the specified trader
    /// @param trader The address of the trader
    /// @return freeCollateral the value (in settlement token's decimals) of free collateral available
    ///         for withdraw or opening new positions or orders)
    function getFreeCollateral(address trader) external view returns (uint256 freeCollateral);

    /// @notice Get the free collateral amount of the specified trader and collateral ratio
    /// @dev There are three configurations for different insolvency risk tolerances:
    ///      **conservative, moderate &aggressive**. We will start with the **conservative** one
    ///      and gradually move to **aggressive** to increase capital efficiency
    /// @param trader The address of the trader
    /// @param ratio The margin requirement ratio, imRatio or mmRatio
    /// @return freeCollateralByRatio freeCollateral (in settlement token's decimals), by using the
    ///         input margin requirement ratio; can be negative
    function getFreeCollateralByRatio(address trader, uint24 ratio)
        external
        view
        returns (int256 freeCollateralByRatio);

    /// @notice Get the free collateral amount of the specified collateral token of specified trader
    /// @param trader The address of the trader
    /// @param token The address of the collateral token
    /// @return freeCollateral amount of that token (in the token's native decimals)
    function getFreeCollateralByToken(address trader, address token) external view returns (uint256 freeCollateral);

    /// @notice Get the specified trader's settlement value, including pending fee, funding payment,
    ///         owed realized PnL and unrealized PnL
    /// @dev Note the difference between `settlementTokenBalanceX10_S`, `getSettlementTokenValue()` and `getBalance()`:
    ///      They are all settlement token balances but with or without
    ///      pending fee, funding payment, owed realized PnL, unrealized PnL, respectively
    ///      In practical applications, we use `getSettlementTokenValue()` to get the trader's debt (if < 0)
    /// @param trader The address of the trader
    /// @return balance The balance amount (in settlement token's decimals)
    function getSettlementTokenValue(address trader) external view returns (int256);

    /// @notice Get the settlement token address
    /// @dev We assume the settlement token should match the denominator of the price oracle.
    ///      i.e. if the settlement token is USDC, then the oracle should be priced in USD
    /// @return settlementToken The address of the settlement token
    function getSettlementToken() external view returns (address settlementToken);

    /// @notice Check if a given trader's collateral token can be liquidated; liquidation criteria:
    ///         1. margin ratio falls below maintenance threshold + 20bps (mmRatioBuffer)
    ///         2. USDC debt > nonSettlementTokenValue * debtNonSettlementTokenValueRatio (ex: 75%)
    ///         3. USDC debt > debtThreshold (ex: $10000)
    //          USDC debt = USDC balance + Total Unrealized PnL
    /// @param trader The address of the trader
    /// @return true If the trader can be liquidated
    function isLiquidatable(address trader) external view returns (bool);

    /// @notice get the margin requirement for collateral liquidation of a trader
    /// @dev this value is compared with `ClearingHouse.getAccountValue()` (int)
    /// @param trader The address of the trader
    /// @return margin requirement (in 18 decimals)
    function getMarginRequirementForCollateralLiquidation(address trader) external view returns (int256);

    /// @notice Get the maintenance margin ratio for collateral liquidation
    /// @return collateralMmRatio The maintenance margin ratio for collateral liquidation
    function getCollateralMmRatio() external view returns (uint24);

    /// @notice Get a trader's liquidatable collateral amount by a given settlement amount
    /// @param token The address of the token of the trader's collateral
    /// @param settlementX10_S The amount of settlement token the liquidator wants to pay
    /// @return collateral The collateral amount(in its native decimals) the liquidator can get
    function getLiquidatableCollateralBySettlement(address token, uint256 settlementX10_S)
        external
        view
        returns (uint256 collateral);

    /// @notice Get a trader's repaid settlement amount by a given collateral amount
    /// @param token The address of the token of the trader's collateral
    /// @param collateral The amount of collateral token the liquidator wants to get
    /// @return settlementX10_S The settlement amount(in settlement token's decimals) the liquidator needs to pay
    function getRepaidSettlementByCollateral(address token, uint256 collateral)
        external
        view
        returns (uint256 settlementX10_S);

    /// @notice Get a trader's max repaid settlement & max liquidatable collateral by a given collateral token
    /// @param trader The address of the trader
    /// @param token The address of the token of the trader's collateral
    /// @return maxRepaidSettlementX10_S The maximum settlement amount(in settlement token's decimals)
    ///         the liquidator needs to pay to liquidate a trader's collateral token
    /// @return maxLiquidatableCollateral The maximum liquidatable collateral amount
    ///         (in the collateral token's native decimals) of a trader
    function getMaxRepaidSettlementAndLiquidatableCollateral(address trader, address token)
        external
        view
        returns (uint256 maxRepaidSettlementX10_S, uint256 maxLiquidatableCollateral);

    /// @notice Get settlement token decimals
    /// @dev cached the settlement token's decimal for gas optimization
    /// @return decimals The decimals of settlement token
    function decimals() external view returns (uint8);

    /// @notice Get the borrowed settlement token amount from insurance fund
    /// @return debtAmount The debt amount (in settlement token's decimals)
    function getTotalDebt() external view returns (uint256 debtAmount);

    /// @notice Get `ClearingHouseConfig` contract address
    /// @return clearingHouseConfig The address of `ClearingHouseConfig` contract
    function getClearingHouseConfig() external view returns (address clearingHouseConfig);

    /// @notice Get `AccountBalance` contract address
    /// @return accountBalance The address of `AccountBalance` contract
    function getAccountBalance() external view returns (address accountBalance);

    /// @notice Get `InsuranceFund` contract address
    /// @return insuranceFund The address of `InsuranceFund` contract
    function getInsuranceFund() external view returns (address);

    /// @notice Get `Exchange` contract address
    /// @return exchange The address of `Exchange` contract
    function getExchange() external view returns (address);

    /// @notice Get `ClearingHouse` contract address
    /// @return clearingHouse The address of `ClearingHouse` contract
    function getClearingHouse() external view returns (address);

    /// @notice Get `CollateralManager` contract address
    /// @return clearingHouse The address of `CollateralManager` contract
    function getCollateralManager() external view returns (address);

    /// @notice Get `WETH9` contract address
    /// @return clearingHouse The address of `WETH9` contract
    function getWETH9() external view returns (address);
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function WETH9() external view returns (address);

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IIndexPrice {
    /// @dev Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    function getIndexPrice(uint256 interval) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISgBridge  {

    function bridge(address token,
        uint256 amount,
        uint16 destChainId,
        address destinationAddress,
        address destinationToken) external payable;


    function swap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        address recipient
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library AccountMarket {
    /// @param lastTwPremiumGrowthGlobalX96 the last time weighted premiumGrowthGlobalX96
    struct Info {
        int256 takerPositionSize;
        int256 takerOpenNotional;
        int256 lastTwPremiumGrowthGlobalX96;
    }
}

interface IAccountBalance {
    /// @param vault The address of the vault contract
    event VaultChanged(address indexed vault);

    /// @dev Emit whenever a trader's `owedRealizedPnl` is updated
    /// @param trader The address of the trader
    /// @param amount The amount changed
    event PnlRealized(address indexed trader, int256 amount);

    function modifyTakerBalance(
        address trader,
        address baseToken,
        int256 base,
        int256 quote
    ) external returns (int256, int256);

    function modifyOwedRealizedPnl(address trader, int256 amount) external;

    /// @dev this function is now only called by Vault.withdraw()
    function settleOwedRealizedPnl(address trader) external returns (int256 pnl);

    function settleQuoteToOwedRealizedPnl(
        address trader,
        address baseToken,
        int256 amount
    ) external;

    /// @dev Settle account balance and deregister base token
    /// @param maker The address of the maker
    /// @param baseToken The address of the market's base token
    /// @param realizedPnl Amount of pnl realized
    /// @param fee Amount of fee collected from pool
    function settleBalanceAndDeregister(
        address maker,
        address baseToken,
        int256 takerBase,
        int256 takerQuote,
        int256 realizedPnl,
        int256 fee
    ) external;

    /// @dev every time a trader's position value is checked, the base token list of this trader will be traversed;
    ///      thus, this list should be kept as short as possible
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function registerBaseToken(address trader, address baseToken) external;

    /// @dev this function is expensive
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function deregisterBaseToken(address trader, address baseToken) external;

    function updateTwPremiumGrowthGlobal(
        address trader,
        address baseToken,
        int256 lastTwPremiumGrowthGlobalX96
    ) external;

    function getClearingHouseConfig() external view returns (address);

    function getOrderBook() external view returns (address);

    function getVault() external view returns (address);

    function getBaseTokens(address trader) external view returns (address[] memory);

    function getAccountInfo(address trader, address baseToken) external view returns (AccountMarket.Info memory);

    function getTakerOpenNotional(address trader, address baseToken) external view returns (int256);

    /// @return totalOpenNotional the amount of quote token paid for a position when opening
    function getTotalOpenNotional(address trader, address baseToken) external view returns (int256);

    function getTotalDebtValue(address trader) external view returns (uint256);

    /// @dev this is different from Vault._getTotalMarginRequirement(), which is for freeCollateral calculation
    /// @return int instead of uint, as it is compared with ClearingHouse.getAccountValue(), which is also an int
    function getMarginRequirementForLiquidation(address trader) external view returns (int256);

    /// @return owedRealizedPnl the pnl realized already but stored temporarily in AccountBalance
    /// @return unrealizedPnl the pnl not yet realized
    /// @return pendingFee the pending fee of maker earned
    function getPnlAndPendingFee(address trader)
    external
    view
    returns (
        int256 owedRealizedPnl,
        int256 unrealizedPnl,
        uint256 pendingFee
    );

    function hasOrder(address trader) external view returns (bool);

    function getBase(address trader, address baseToken) external view returns (int256);

    function getQuote(address trader, address baseToken) external view returns (int256);

    function getTakerPositionSize(address trader, address baseToken) external view returns (int256);

    function getTotalPositionSize(address trader, address baseToken) external view returns (int256);

    /// @dev a negative returned value is only be used when calculating pnl
    /// @dev we use 15 mins twap to calc position value
    function getTotalPositionValue(address trader, address baseToken) external view returns (int256);

    /// @return sum up positions value of every market, it calls `getTotalPositionValue` internally
    function getTotalAbsPositionValue(address trader) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IClearingHouseConfig {
    function getMaxMarketsPerAccount() external view returns (uint8);

    function getImRatio() external view returns (uint24);

    function getMmRatio() external view returns (uint24);

    function getLiquidationPenaltyRatio() external view returns (uint24);

    function getPartialCloseRatio() external view returns (uint24);

    /// @return twapInterval for funding and prices (mark & index) calculations
    function getTwapInterval() external view returns (uint32);

    function getSettlementTokenBalanceCap() external view returns (uint256);

    function getMaxFundingRate() external view returns (uint24);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IExchange {
    /// @notice Get the square root of the market twap price with the given time interval
    /// @dev The return value is a X96 number
    /// @param baseToken Address of the base token
    /// @param twapInterval The time interval in seconds
    /// @return sqrtMarkTwapX96 The square root of the market twap price
    function getSqrtMarkTwapX96(address baseToken, uint32 twapInterval) external view returns (uint160 sqrtMarkTwapX96);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IDeCommasVault {

    function borrow(address baseAsset, uint256 amount, bool /*positionType*/) external;

    function repay(address baseAsset, uint256 amount, bool /*positionType*/) external;

    function openPosition(address baseAsset, uint256 amount,  bool positionType) external;

    function closePosition(address baseAsset, uint256 amount, bool /*positionType*/) external;

    function claim(address /*baseAsset*/, uint256 amount, bool /*positionType*/) external;

    function submitNativeToken(address /*baseAsset*/, uint256 amount, bool /*positionType*/) external payable;

    function withdrawNativeToken(address /*baseAsset*/, uint256 amount, bool /*positionType*/) external payable;

    function adjustPosition (bytes memory data) external;

    function deposit(bytes memory data) external;

    function pause() external;

    function unpause() external;
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../SmartLZBase.sol";

abstract contract BaseBuildingBlock is SmartLZBase {

    event PayloadReceived(bytes payload);

    address public nativeRouter;

    function setNativeRouter(address _new) public {
      //  require(_msgSender() == address(this));
       // (address _new) = abi.decode(_data, (address));
        nativeRouter = _new;
    }

    // todo only ActionPool
    function setNativeLZEndpoint(address  _endpoint) public {
        _nativeLZEndpoint = _endpoint;
    }


    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64, /*_nonce*/
        bytes memory payload
    ) external override {
          //  require(_msgSender() == address(_nativeLZEndpoint), "BBB: Sender isn't lzEndpoint");
          //  require(
          //      srcAddress.length == remotes[srcChainId].length
          //      && keccak256(srcAddress) == keccak256(remotes[srcChainId]),
          //      "BBB:Invalid remote,call setRemote(srcAddr)"
          //  );

        (uint16 flag, bytes memory funcSignature) = abi.decode(payload,(uint16, bytes));
        if(flag == 1) { // bridge

            (uint256 stableAmount,
            uint16 recipientLZId,
            address recipientAddress,
            address destinationStableToken,
            address nativeStableToken) = abi.decode(funcSignature, (uint256, uint16, address, address, address));

            IERC20(nativeStableToken).approve(_sgBridge, stableAmount);
            ISgBridge(_sgBridge).bridge{value: address(this).balance}(nativeStableToken,
                stableAmount,
                recipientLZId,
                recipientAddress,
                destinationStableToken
            );
        } else if(flag == 2) { // action
            emit PayloadReceived(funcSignature);
            (bool success, bytes memory returnData) = address(this).call(funcSignature);
            require(success, "BBB: Call to Destination bb failed");
        } else {
            revert("Unsupported flag type");
        }
    }


    function backTokensToNative(bytes memory _data) public {
        (address _token, uint256 amount) = abi.decode(_data, (address, uint256));
        IERC20(_token).transfer(nativeRouter, amount);
    }



    function approve(bytes memory _data) public {
       // require(_msgSender() == address(this));
        (address baseAsset, address sender, uint256 amount) = abi.decode(_data, (address, address, uint256));
    }


    function balanceOf(address _token) external view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./integrations/stargate/ISgBridge.sol";
import "./integrations/layerzero/ILayerZeroReceiver.sol";
import "./integrations/layerzero/ILayerZeroEndpoint.sol";
import "./integrations/layerzero/ILayerZeroUserApplicationConfig.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract SmartLZBase is OwnableUpgradeable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig  {

    /// lz native endpoint address ID,e.g.
    /// https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    address internal _nativeLZEndpoint;

    /// Mapping from chain ID to endpoint address
    mapping(uint16 => bytes) public remotes;

    /// lz native chain ID, e.g. https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 internal _nativeChain;

    /// address of native stargateRouter for swap
    /// https://stargateprotocol.gitbook.io/stargate/interfaces/evm-solidity-interfaces/istargaterouter.sol
    /// https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
    address internal  _sgBridge;


    /**
    * @notice
    * @param actionData
    * chainId - target chain id in LayerZero, see more:
    *        (https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses)
    *  remoteAddress - RouterAddress in target Chain
    * @dev only deCommas Register Address
    */
    // todo - DELETE!!!!!
    function setRemote(uint16 chainId, bytes memory remoteAddress) public {
        remotes[chainId] = remoteAddress;
    }


    function setBridge(bytes memory actionData) public {
       // require(_msgSender() == address(this));
        (address newSgBridge) = abi.decode(actionData, (address));
        _sgBridge = newSgBridge;
    }


    receive() external payable { }


    fallback() external payable { }


    /////////// LZ SPECIAL FUNC \\\\\\\\\\\\\\
    /**
    * @notice LZ Config
    * @dev special lz functionality
    */
     function setSendVersion(uint16 version) external override {
        ILayerZeroEndpoint(_nativeLZEndpoint).setSendVersion(version);
    }

    /**
    * @notice LZ Config
    * @dev special lz functionality
    */
    function setReceiveVersion(uint16 version) external override {
        ILayerZeroEndpoint(_nativeLZEndpoint).setReceiveVersion(version);
    }


    /**
    * @notice LZ Config - set the inbound block confirmations
    * @dev special lz functionality
    */
    function setInboundConfirmations(uint16 remoteChainId, uint16 confirmations) external onlyOwner {
        ILayerZeroEndpoint(_nativeLZEndpoint).setConfig(
            ILayerZeroEndpoint(_nativeLZEndpoint).getSendVersion(address(this)),
            remoteChainId,
            2, // CONFIG_TYPE_INBOUND_BLOCK_CONFIRMATIONS
            abi.encode(confirmations)
        );
    }

    /**
    * @notice LZ Config set outbound block confirmations
    * @dev special lz functionality
    */
    function setOutboundConfirmations(uint16 remoteChainId, uint16 confirmations) external onlyOwner {
        ILayerZeroEndpoint(_nativeLZEndpoint).setConfig(
            ILayerZeroEndpoint(_nativeLZEndpoint).getSendVersion(address(this)),
            remoteChainId,
            5, // CONFIG_TYPE_OUTBOUND_BLOCK_CONFIRMATIONS
            abi.encode(confirmations)
        );
    }

    /**
    * @notice LZ Config
    * @dev special lz functionality
    */
    function setConfig(uint16 /*_version*/,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config) external override {
        ILayerZeroEndpoint(_nativeLZEndpoint).setConfig(ILayerZeroEndpoint(_nativeLZEndpoint).getSendVersion(
                address(this)),
            _chainId,
            _configType,
            _config);
    }

    /**
    * @notice LZ Config
    * @dev special lz functionality
    */
     function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
        ILayerZeroEndpoint(_nativeLZEndpoint).forceResumeReceive(_srcChainId, _srcAddress);
    }

    /**
    * @notice LZ Config
    * @dev special lz functionality
    */
    function getSendVersion() external view returns (uint16) {
        return ILayerZeroEndpoint(_nativeLZEndpoint).getSendVersion(address(this));
    }

    /**
    * @notice LZ Config
    * @dev special lz functionality
    */
    function getReceiveVersion() external view returns (uint16) {
        return ILayerZeroEndpoint(_nativeLZEndpoint).getReceiveVersion(address(this));
    }

    /**
    * @notice LZ Config
    * @dev special lz functionality
    */
    function getConfig(uint16 /*_dstChainId*/,
                        uint16 _chainId,
                        address /*_dst*/,
                        uint _configType) external view returns (bytes memory) {
        return ILayerZeroEndpoint(_nativeLZEndpoint).getConfig(ILayerZeroEndpoint(_nativeLZEndpoint).getSendVersion(
                                                                                                    address(this)),
                                                                                                    _chainId,
                                                                                                    address(this),
                                                                                                    _configType);
    }
 }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}