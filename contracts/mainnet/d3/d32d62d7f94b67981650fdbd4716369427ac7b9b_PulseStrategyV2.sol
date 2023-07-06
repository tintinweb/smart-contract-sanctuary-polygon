// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/external/univ3/IUniswapV3Pool.sol";
import "../interfaces/external/univ3/INonfungiblePositionManager.sol";
import "../interfaces/strategies/IStrategy.sol";

import "../utils/UniV3TokenRegistry.sol";
import "../utils/UniV3MEVProtection.sol";
import "../utils/ProxyToken.sol";

import "../oracles/protocols/UniV3ERC20Oracle.sol";

import "../vaults/interfaces/IRebalanceFacet.sol";
import "../vaults/interfaces/IVaultFacet.sol";
import "../vaults/interfaces/ILpTokenFacet.sol";

contract PulseStrategyV2 is IStrategy {
    error LimitOverflow();
    error ValueZero();
    error Forbidden();

    struct InitParams {
        address vault;
        address owner;
        uint256 desired0;
        uint256 desired1;
        IUniswapV3Pool pool;
    }

    struct ImmutableParams {
        address owner;
        address vault;
        IUniswapV3Pool pool;
        ProxyToken token;
    }

    struct MutableParams {
        int24 defaultIntervalWidth;
        int24 maxPositionLengthInTicks;
        int24 ticksSlippageCoefficient;
        uint256 neighborhoodFactorD;
        uint256 extensionFactorD;
        uint256 allowedTickNeighborhoodD;
        bytes securityParams;
    }

    struct Storage {
        ImmutableParams immutableParams;
        MutableParams mutableParams;
        State state;
    }

    struct State {
        int24 tickLower;
        int24 tickUpper;
        bool forceRebalanceFlag;
    }

    using SafeERC20 for IERC20;

    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant D9 = 10 ** 9;
    bytes32 public constant STORAGE_POSITION = keccak256("strategy.storage");

    INonfungiblePositionManager public immutable positionManager;
    UniV3TokenRegistry public immutable registry;
    UniV3ERC20Oracle public immutable uniV3ERC20Oracle;
    UniV3MEVProtection public immutable mevProtection;

    constructor(
        INonfungiblePositionManager positionManager_,
        UniV3TokenRegistry registry_,
        UniV3ERC20Oracle uniV3ERC20Oracle_,
        UniV3MEVProtection mevProtection_
    ) {
        positionManager = positionManager_;
        registry = registry_;
        uniV3ERC20Oracle = uniV3ERC20Oracle_;
        mevProtection = mevProtection_;
    }

    function _contractStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    modifier onlyOwner() {
        if (_contractStorage().immutableParams.owner != msg.sender) revert Forbidden();
        _;
    }

    modifier onlyVault() {
        if (_contractStorage().immutableParams.vault != msg.sender) revert Forbidden();
        _;
    }

    function _mintToken(
        InitParams memory initParams,
        bytes memory securityParams,
        int24 tickLower,
        int24 tickUpper
    ) private returns (ProxyToken) {
        IUniswapV3Pool pool = initParams.pool;
        address token0 = pool.token0();
        address token1 = pool.token1();

        IERC20(token0).approve(address(positionManager), type(uint256).max);
        IERC20(token1).approve(address(positionManager), type(uint256).max);

        (uint256 uniV3Nft, , , ) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: pool.fee(),
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: initParams.desired0,
                amount1Desired: initParams.desired1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: type(uint256).max
            })
        );
        positionManager.approve(address(registry), uniV3Nft);

        ProxyToken proxyToken = new ProxyToken(address(this));

        UniV3Token.InitParams memory tokenInitParams = UniV3Token.InitParams({
            uniV3Nft: uniV3Nft,
            name: "Mellow Pulse V2 UniV3Token",
            symbol: "MUT",
            admin: address(proxyToken),
            oracle: address(uniV3ERC20Oracle),
            securityParams: securityParams
        });

        (, address uniToken) = registry.createCompoundableToken(tokenInitParams);

        proxyToken.upgradeTo(uniToken);
        proxyToken.transferOwnership(initParams.vault);

        return proxyToken;
    }

    function _calculateDefaultPosition(
        IUniswapV3Pool pool,
        int24 width
    ) private view returns (int24 tickLower, int24 tickUpper) {
        (, int24 tick, , , , , ) = pool.slot0();
        tick -= tick % pool.tickSpacing();
        tickLower = tick - width / 2;
        tickUpper = tick + width / 2;
    }

    function calculateNewPosition(
        State memory state,
        IUniswapV3Pool pool,
        MutableParams memory mutableParams
    ) public view returns (int24 newTickLower, int24 newTickUpper) {
        int24 tickSpacing = pool.tickSpacing();
        if (state.forceRebalanceFlag) {
            return _calculateDefaultPosition(pool, mutableParams.defaultIntervalWidth);
        }

        int24 tickLower = state.tickLower;
        int24 tickUpper = state.tickUpper;
        int24 width = tickUpper - tickLower;

        int24 currentNeighborhood = int24(
            uint24(FullMath.mulDiv(uint24(width), mutableParams.neighborhoodFactorD, D9))
        );

        int24 minAcceptableTick = tickLower + currentNeighborhood;
        int24 maxAcceptableTick = tickUpper - currentNeighborhood;
        (, int24 spotTick, , , , , ) = pool.slot0();

        if (minAcceptableTick <= spotTick && spotTick <= maxAcceptableTick) {
            return (tickLower, tickUpper);
        }

        int24 closeness = minAcceptableTick - spotTick;
        if (spotTick - maxAcceptableTick > closeness) {
            closeness = spotTick - maxAcceptableTick;
        }

        int24 sideExtension = closeness +
            int24(int256(FullMath.mulDiv(uint24(currentNeighborhood), mutableParams.extensionFactorD, D9)));
        if (sideExtension % tickSpacing != 0 || sideExtension == 0) {
            sideExtension += tickSpacing;
            sideExtension -= sideExtension % tickSpacing;
        }

        newTickLower = tickLower - sideExtension;
        newTickUpper = tickUpper + sideExtension;

        if (newTickUpper - newTickLower > mutableParams.maxPositionLengthInTicks) {
            return _calculateDefaultPosition(pool, mutableParams.defaultIntervalWidth);
        }
    }

    function createStrategy(
        InitParams memory initParams,
        MutableParams memory mutableParams
    ) external returns (PulseStrategyV2 strategy) {
        strategy = PulseStrategyV2(
            Clones.cloneDeterministic(address(this), bytes32(abi.encode(address(this), bytes12(0))))
        );
        strategy.initialize(initParams, mutableParams);
    }

    function initialize(InitParams memory initParams, MutableParams memory mutableParams) external {
        Storage storage s = _contractStorage();
        if (s.immutableParams.owner != address(0)) revert Forbidden();

        (int24 tickLower, int24 tickUpper) = _calculateDefaultPosition(
            initParams.pool,
            mutableParams.defaultIntervalWidth
        );

        ProxyToken proxyToken = _mintToken(initParams, mutableParams.securityParams, tickLower, tickUpper);
        s.immutableParams = ImmutableParams({
            owner: initParams.owner,
            vault: initParams.vault,
            pool: initParams.pool,
            token: proxyToken
        });
        s.mutableParams = mutableParams;
        s.state = State({tickLower: tickLower, tickUpper: tickUpper, forceRebalanceFlag: false});
    }

    function parameters()
        public
        pure
        returns (ImmutableParams memory immutableParams, MutableParams memory mutableParams, State memory state)
    {
        Storage memory s = _contractStorage();
        immutableParams = s.immutableParams;
        mutableParams = s.mutableParams;
        state = s.state;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        Storage storage s = _contractStorage();
        s.immutableParams.owner = newOwner;
    }

    function updateMutableParams(MutableParams memory newMutableParams) external onlyOwner {
        if (
            newMutableParams.defaultIntervalWidth == 0 ||
            newMutableParams.maxPositionLengthInTicks <= 0 ||
            newMutableParams.neighborhoodFactorD == 0 ||
            newMutableParams.extensionFactorD == 0 ||
            newMutableParams.securityParams.length == 0
        ) revert ValueZero();

        if (newMutableParams.neighborhoodFactorD > D9) revert LimitOverflow();

        Storage storage s = _contractStorage();
        MutableParams memory mutableParams = s.mutableParams;
        if (
            mutableParams.defaultIntervalWidth != newMutableParams.defaultIntervalWidth ||
            mutableParams.maxPositionLengthInTicks != newMutableParams.maxPositionLengthInTicks ||
            mutableParams.neighborhoodFactorD != newMutableParams.neighborhoodFactorD ||
            mutableParams.extensionFactorD != newMutableParams.extensionFactorD
        ) {
            s.state.forceRebalanceFlag = true;
        }
        s.mutableParams = newMutableParams;
    }

    function checkStateAfterRebalance() external view returns (bool) {
        Storage memory s = _contractStorage();
        mevProtection.ensureNoMEV(address(s.immutableParams.pool), s.mutableParams.securityParams);
        (int24 expectedNewTickLower, int24 expectedNewTickUpper) = calculateNewPosition(
            s.state,
            s.immutableParams.pool,
            s.mutableParams
        );
        int24 newTickLower = UniV3Token(address(s.immutableParams.token)).tickLower();
        int24 newTickUpper = UniV3Token(address(s.immutableParams.token)).tickUpper();

        int24 lowerDelta = expectedNewTickLower - newTickLower;
        int24 upperDelta = expectedNewTickUpper - newTickUpper;
        if (lowerDelta < 0) lowerDelta = -lowerDelta;
        if (upperDelta < 0) upperDelta = -upperDelta;

        int24 maxDelta = s.immutableParams.pool.tickSpacing() * s.mutableParams.ticksSlippageCoefficient;

        return lowerDelta <= maxDelta && upperDelta <= maxDelta;
    }

    function canStartAuction() external view returns (bool) {
        Storage memory s = _contractStorage();

        State memory state = s.state;
        if (state.forceRebalanceFlag) return true;

        mevProtection.ensureNoMEV(address(s.immutableParams.pool), s.mutableParams.securityParams);

        (, int24 spotTick, , , , , ) = s.immutableParams.pool.slot0();

        MutableParams memory mutableParams = s.mutableParams;

        int24 tickNeighborhood = int24(
            uint24(FullMath.mulDiv(uint24(state.tickUpper - state.tickLower), mutableParams.neighborhoodFactorD, D9))
        );

        if (spotTick < state.tickUpper + tickNeighborhood) return true;
        if (spotTick > state.tickLower - tickNeighborhood) return true;

        return false;
    }

    function canStopAuction() external view returns (bool) {
        Storage memory s = _contractStorage();

        State memory state = s.state;
        if (state.forceRebalanceFlag) return false;

        mevProtection.ensureNoMEV(address(s.immutableParams.pool), s.mutableParams.securityParams);

        (, int24 spotTick, , , , , ) = s.immutableParams.pool.slot0();

        MutableParams memory mutableParams = s.mutableParams;

        int24 tickNeighborhood = int24(
            uint24(FullMath.mulDiv(uint24(state.tickUpper - state.tickLower), mutableParams.neighborhoodFactorD, D9))
        );

        int24 allowedTickNeighborhood = int24(
            uint24(FullMath.mulDiv(mutableParams.allowedTickNeighborhoodD, uint24(tickNeighborhood), D9))
        );
        if (
            state.tickUpper + allowedTickNeighborhood < spotTick && spotTick < state.tickLower - allowedTickNeighborhood
        ) return true;

        return false;
    }

    function setForceRebalanceFlag() external onlyOwner {
        _contractStorage().state.forceRebalanceFlag = true;
    }

    function saveState() external onlyVault {
        Storage storage s = _contractStorage();
        UniV3Token token = UniV3Token(address(s.immutableParams.token));
        s.state = State({tickLower: token.tickLower(), tickUpper: token.tickUpper(), forceRebalanceFlag: false});
    }

    function getExpectedRatiosX96() external pure returns (uint256[] memory ratiosX96) {
        ratiosX96 = new uint256[](1);
        ratiosX96[0] = Q96;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./pool/IUniswapV3PoolActions.sol";
import "./pool/IUniswapV3PoolImmutables.sol";
import "./pool/IUniswapV3PoolState.sol";
import "./pool/IUniswapV3PoolDerivedState.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPeripheryImmutableState.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is IPeripheryImmutableState, IERC721 {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStrategy {
    function canStartAuction() external view returns (bool);

    function canStopAuction() external view returns (bool);

    function checkStateAfterRebalance() external view returns (bool);

    function saveState() external;

    function getExpectedRatiosX96() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/external/univ3/IUniswapV3Pool.sol";
import "../interfaces/external/univ3/INonfungiblePositionManager.sol";
import "../interfaces/external/univ3/ISwapRouter.sol";

import "./UniV3Token.sol";
import "./UniV3CompoundableToken.sol";
import "./UniV3MEVProtection.sol";

contract UniV3TokenRegistry {
    using SafeERC20 for IERC20;

    INonfungiblePositionManager public immutable positionManager;
    UniV3CompoundableToken public immutable singletonUniV3CompoundableToken;
    uint256 public numberOfTokens = 1;

    // returns registry id of token by its address
    mapping(address => uint256) private _ids;
    mapping(uint256 => UniV3Token) private _tokenById;

    constructor(
        INonfungiblePositionManager positionManager_,
        ISwapRouter router_,
        UniV3MEVProtection mevProtection,
        bytes32 proxyContractBytecodeHash_
    ) {
        positionManager = positionManager_;
        singletonUniV3CompoundableToken = new UniV3CompoundableToken(
            positionManager_,
            router_,
            UniV3TokenRegistry(address(this)),
            mevProtection,
            proxyContractBytecodeHash_
        );
    }

    function idByToken(address token) external view returns (uint256 tokenId) {
        return _ids[token];
    }

    function tokenById(uint256 tokenId) external view returns (address token) {
        return address(_tokenById[tokenId]);
    }

    function createCompoundableToken(
        UniV3Token.InitParams memory params
    ) external returns (uint256 currentTokenId, address token) {
        currentTokenId = numberOfTokens++;
        UniV3CompoundableToken uniV3Token = UniV3CompoundableToken(
            Clones.cloneDeterministic(address(singletonUniV3CompoundableToken), bytes32(currentTokenId))
        );
        token = address(uniV3Token);
        positionManager.transferFrom(positionManager.ownerOf(params.uniV3Nft), token, params.uniV3Nft);

        uniV3Token.initialize(params);
        _ids[token] = currentTokenId;
        _tokenById[currentTokenId] = uniV3Token;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../libraries/external/OracleLibrary.sol";

import "./IMEVProtection.sol";

contract UniV3MEVProtection is IMEVProtection {
    struct SecurityParams {
        uint16[] observationsAgo;
        int24 maxDeviation;
    }

    function ensureNoMEV(address pool, bytes memory data) external view override {
        SecurityParams memory params = abi.decode(data, (SecurityParams));
        int24[] memory averageTicks = OracleLibrary.consultByObservations(pool, params.observationsAgo);
        for (uint256 i = 1; i < averageTicks.length; i++) {
            int24 delta = averageTicks[i] - averageTicks[i - 1];
            if (delta < 0) delta = -delta;
            if (delta > params.maxDeviation) {
                revert PoolIsNotStable();
            }
        }
        {
            (, int24 spotTick, , , , , ) = IUniswapV3Pool(pool).slot0();
            int24 lastAverageTick = averageTicks[averageTicks.length - 1];
            int24 delta = spotTick - lastAverageTick;
            if (delta < 0) delta = -delta;
            if (delta > params.maxDeviation) {
                revert PoolIsNotStable();
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/utils/IProxyToken.sol";
import "../interfaces/utils/IProxyableToken.sol";

contract ProxyToken is IProxyToken {
    using SafeERC20 for IERC20;

    error RebalanceFlagNotSet();
    error Forbidden();
    error InvalidToken();

    address public token;
    address public owner;
    bool public rebalanceFlag;

    constructor(address owner_) {
        owner = owner_;
    }

    function setRebalanceFlag(bool value) external {
        if (msg.sender != owner) {
            revert Forbidden();
        }
        rebalanceFlag = value;
    }

    function upgradeTo(address newToken) external {
        if (!rebalanceFlag && msg.sender != owner) {
            revert RebalanceFlagNotSet();
        }
        if (token == address(0)) {
            token = newToken;
        } else {
            try IProxyableToken(token).isSameKind(newToken) returns (bool isSameKind) {
                if (isSameKind) {
                    token = newToken;
                    return;
                }
            } catch {}
            revert InvalidToken();
        }
    }

    function transferOwnership(address newAdmin) external {
        if (msg.sender != owner) {
            revert Forbidden();
        }
        owner = newAdmin;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return type(IProxyToken).interfaceId == interfaceId;
    }

    function deposit(uint256[] memory tokenAmounts, bytes memory params) external {
        IProxyableToken(token).deposit(msg.sender, tokenAmounts, params);
    }

    function withdraw(uint256 lpAmount, bytes memory params) external {
        IProxyableToken(token).withdraw(msg.sender, lpAmount, params);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return IProxyableToken(token).transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return IProxyableToken(token).approve(msg.sender, spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return IProxyableToken(token).transferFrom(msg.sender, from, to, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        return IProxyableToken(token).increaseAllowance(msg.sender, spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        return IProxyableToken(token).decreaseAllowance(msg.sender, spender, subtractedValue);
    }

    function _staticcall(address implementation) internal view {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := staticcall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _staticcall(token);
    }

    receive() external payable {
        _staticcall(token);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/oracles/IMellowBaseOracle.sol";
import "../../utils/UniV3TokenRegistry.sol";
import "../../utils/UniV3Token.sol";

contract UniV3ERC20Oracle is IMellowBaseOracle {
    error PoolIsNotStable();

    UniV3TokenRegistry public immutable registry;

    constructor(UniV3TokenRegistry registry_) {
        registry = registry_;
    }

    function isTokenSupported(address token) external view override returns (bool) {
        if (registry.idByToken(token) != 0) {
            return true;
        }

        try IERC165(token).supportsInterface(type(IProxyToken).interfaceId) returns (bool isSupported) {
            if (isSupported) {
                address implementation = ProxyToken(payable(token)).token();
                return (registry.idByToken(implementation) != 0 && UniV3Token(implementation).admin() == token);
            }
        } catch {}
        return false;
    }

    function quote(
        address token,
        uint256 amount,
        bytes memory
    ) public view override returns (address[] memory tokens, uint256[] memory tokenAmounts) {
        tokens = new address[](2);
        tokens[0] = UniV3Token(token).token0();
        tokens[1] = UniV3Token(token).token1();
        (uint256 totalAmount0, uint256 totalAmount1) = UniV3Token(token).tvl();
        uint256 totalSupply = UniV3Token(token).totalSupply();
        tokenAmounts = new uint256[](2);
        tokenAmounts[0] = FullMath.mulDiv(totalAmount0, amount, totalSupply);
        tokenAmounts[1] = FullMath.mulDiv(totalAmount1, amount, totalSupply);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPermissionsFacet.sol";
import "./IDutchAuctionFacet.sol";
import "./IVaultFacet.sol";

interface IRebalanceFacet {
    function rebalance(address callback, bytes calldata data) external;

    function rebalanceInitialized() external view returns (bool);

    function rebalanceSelectors() external view returns (bytes4[] memory selectors_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IOracle, IBaseOracle} from "../../interfaces/oracles/IOracle.sol";
import "./IPermissionsFacet.sol";
import "./ITokensManagementFacet.sol";

import "../../utils/LpToken.sol";

interface IVaultFacet {
    struct Storage {
        bytes securityParams;
        IOracle oracle;
        address[] tokens;
        uint256 proxyTokensMask;
    }

    function initializeVaultFacet(
        address[] memory tokensInOrderOfDifficulty_,
        uint256 proxyTokensMask_,
        IOracle oracle_,
        bytes[] calldata securityParams
    ) external;

    function updateSecurityParams(bytes[] calldata securityParams) external;

    function updateOracle(IOracle newOracle) external;

    function tvl() external view returns (uint256);

    function quote(address[] memory, uint256[] memory) external view returns (uint256);

    function tokens() external view returns (address[] memory);

    function proxyTokensMask() external view returns (uint256);

    function getTokensAndAmounts() external view returns (address[] memory, uint256[] memory);

    function oracle() external view returns (IOracle);

    function securityParams() external view returns (bytes[] memory);

    function vaultInitialized() external view returns (bool);

    function vaultSelectors() external view returns (bytes4[] memory selectors_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPermissionsFacet.sol";
import "../../utils/LpToken.sol";

interface ILpTokenFacet {
    struct Storage {
        LpToken lpToken;
    }

    function initializeLpTokenFacet(LpToken singleton, string memory name, string memory symbol) external;

    function lpToken() external view returns (LpToken);

    function lpTokenInitialized() external view returns (bool);

    function lpTokenSelectors() external view returns (bytes4[] memory selectors_);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolPerformanceFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(
        int24 tick
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(
        bytes32 key
    )
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(
        uint256 index
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(
        uint32[] calldata secondsAgos
    ) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

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
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwapRouter} from "../interfaces/external/univ3/ISwapRouter.sol";
import {IUniswapV3Pool} from "../interfaces/external/univ3/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "../interfaces/external/univ3/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "../interfaces/external/univ3/INonfungiblePositionManager.sol";

import "../interfaces/utils/ISupportedByOracleToken.sol";

import "../libraries/CommonLibrary.sol";
import "../libraries/external/FullMath.sol";
import "../libraries/external/LiquidityAmounts.sol";
import "../libraries/external/TickMath.sol";
import "../libraries/external/PositionValue.sol";

import "./UniV3TokenRegistry.sol";
import "./UniV3MEVProtection.sol";
import "./ProxyableToken.sol";

abstract contract UniV3Token is
    IERC20,
    Context,
    IERC20Metadata,
    ProxyableToken,
    IERC721Receiver,
    ISupportedByOracleToken
{
    using SafeERC20 for IERC20;
    error InvalidConstructorParams();
    error TokenAlreadyInitialized();
    error UnstablePool();
    error LimitUnderflow();
    error InvalidState();
    error Forbidden();

    INonfungiblePositionManager public immutable positionManager;
    IUniswapV3Factory public immutable factory;
    ISwapRouter public immutable router;
    UniV3TokenRegistry public immutable registry;
    UniV3MEVProtection public immutable mevProtection;
    bytes32 public immutable proxyContractBytecodeHash;

    address private _oracle;

    bool public initialized;
    address public token0;
    address public token1;
    uint24 public fee;
    int24 public tickLower;
    int24 public tickUpper;

    uint160 public sqrtLowerPriceX96;
    uint160 public sqrtUpperPriceX96;

    IUniswapV3Pool public pool;
    uint256 public uniV3Nft;
    bytes public securityParams;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    struct InitParams {
        uint256 uniV3Nft;
        string name;
        string symbol;
        address admin;
        address oracle;
        bytes securityParams;
    }

    constructor(
        INonfungiblePositionManager positionManager_,
        ISwapRouter router_,
        UniV3TokenRegistry registry_,
        UniV3MEVProtection mevProtection_,
        bytes32 proxyContractBytecodeHash_
    ) {
        proxyContractBytecodeHash = proxyContractBytecodeHash_;
        positionManager = positionManager_;
        factory = IUniswapV3Factory(positionManager.factory());
        router = router_;
        registry = registry_;
        mevProtection = mevProtection_;
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert Forbidden();
        _;
    }

    function isSameKind(address token) external view override returns (bool) {
        uint256 tokenId = registry.idByToken(token);
        if (
            tokenId != 0 &&
            UniV3Token(token).token0() == token0 &&
            UniV3Token(token).token1() == token1 &&
            UniV3Token(token).fee() == fee &&
            UniV3Token(token).admin() == admin()
        ) {
            bytes memory tokenSecurityParams = securityParams;
            bytes memory newTokenSecurityParams = UniV3Token(token).securityParams();
            return keccak256(tokenSecurityParams) == keccak256(newTokenSecurityParams);
        }
        return false;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function initialize(InitParams memory params) external {
        if (initialized) revert TokenAlreadyInitialized();
        initialized = true;
        uniV3Nft = params.uniV3Nft;
        _name = params.name;
        _symbol = params.symbol;
        _admin = params.admin;
        _oracle = params.oracle;
        securityParams = params.securityParams;

        if (params.admin != address(0)) {
            if (CommonLibrary.getContractBytecodeHash(params.admin) != proxyContractBytecodeHash) {
                revert InvalidState();
            }
        }

        (, , token0, token1, fee, tickLower, tickUpper, _totalSupply, , , , ) = positionManager.positions(
            params.uniV3Nft
        );

        IERC20(token0).safeApprove(address(positionManager), type(uint256).max);
        IERC20(token1).safeApprove(address(positionManager), type(uint256).max);
        IERC20(token0).safeApprove(address(router), type(uint256).max);
        IERC20(token1).safeApprove(address(router), type(uint256).max);

        if (_totalSupply == 0) {
            revert InvalidState();
        }

        pool = IUniswapV3Pool(factory.getPool(token0, token1, fee));

        sqrtLowerPriceX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtUpperPriceX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    }

    function tvl() public view returns (uint256 amount0, uint256 amount1) {
        IUniswapV3Pool pool_ = pool;
        (uint160 sqrtRatioX96, , , , , , ) = pool_.slot0();
        (amount0, amount1) = PositionValue.total(positionManager, uniV3Nft, sqrtRatioX96, pool_);

        amount0 += IERC20(token0).balanceOf(address(this));
        amount1 += IERC20(token1).balanceOf(address(this));
    }

    function oracle() external view override returns (address) {
        return _oracle;
    }

    function deposit(uint256[] memory tokenAmounts, bytes memory params) external {
        _deposit(msg.sender, tokenAmounts, params);
    }

    // everyone can call this function
    function deposit(address sender, uint256[] memory tokenAmounts, bytes memory params) external {
        _deposit(sender, tokenAmounts, params);
    }

    function _deposit(address sender, uint256[] memory tokenAmounts, bytes memory params) private {
        mevProtection.ensureNoMEV(address(pool), securityParams);
        (uint256 currentAmount0, uint256 currentAmount1) = tvl();

        uint256 totalSupply_ = _totalSupply;

        uint256 amount0 = tokenAmounts[0];
        uint256 amount1 = tokenAmounts[1];

        uint256 minLpAmount = abi.decode(params, (uint256));

        uint256 lpAmount0 = FullMath.mulDiv(amount0, totalSupply_, currentAmount0);
        uint256 lpAmount1 = FullMath.mulDiv(amount1, totalSupply_, currentAmount1);

        uint256 lpAmount = lpAmount0;
        if (lpAmount1 < lpAmount) {
            lpAmount = lpAmount1;
        }

        if (minLpAmount > lpAmount) {
            revert LimitUnderflow();
        }

        if (lpAmount == 0) {
            return;
        }

        amount0 = FullMath.mulDiv(lpAmount, currentAmount0, totalSupply_);
        if ((lpAmount * currentAmount0) % totalSupply_ != 0) {
            amount0++;
        }

        amount1 = FullMath.mulDiv(lpAmount, currentAmount1, totalSupply_);
        if ((lpAmount * currentAmount1) % totalSupply_ != 0) {
            amount1++;
        }

        IERC20(token0).safeTransferFrom(sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(sender, address(this), amount1);

        positionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: uniV3Nft,
                amount0Desired: IERC20(token0).balanceOf(address(this)),
                amount1Desired: IERC20(token1).balanceOf(address(this)),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 1
            })
        );

        _mint(sender, lpAmount);
    }

    function withdraw(uint256 lpAmount, bytes memory params) external {
        _withdraw(msg.sender, lpAmount, params);
    }

    function _withdraw(address sender, uint256 lpAmount, bytes memory params) private {
        if (lpAmount == 0) return;
        mevProtection.ensureNoMEV(address(pool), securityParams);
        uint256[] memory minTokenAmounts = abi.decode(params, (uint256[]));
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        (uint256 currentAmount0, uint256 currentAmount1) = tvl();

        uint256 totalSupply_ = _totalSupply;
        uint256 amount0 = FullMath.mulDiv(lpAmount, currentAmount0, totalSupply_);
        uint256 amount1 = FullMath.mulDiv(lpAmount, currentAmount1, totalSupply_);
        if (amount0 < minTokenAmounts[0] || amount1 < minTokenAmounts[1]) {
            revert LimitUnderflow();
        }

        _burn(sender, lpAmount);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        if (balance0 >= amount0 && balance1 >= amount1) {
            IERC20(token0).safeTransfer(sender, amount0);
            IERC20(token1).safeTransfer(sender, amount1);
            return;
        }

        {
            (uint256 fees0, uint256 fees1) = PositionValue.fees(positionManager, uniV3Nft, pool);
            balance0 += fees0;
            balance1 += fees1;
        }

        if (balance0 >= amount0 && balance1 >= amount1) {
            positionManager.collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: uniV3Nft,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            IERC20(token0).safeTransfer(sender, amount0);
            IERC20(token1).safeTransfer(sender, amount1);
            return;
        }

        {
            uint256 amount0ToPull = 0;
            uint256 amount1ToPull = 0;

            if (balance0 < amount0) amount0ToPull = amount0 - balance0;
            if (balance1 < amount1) amount1ToPull = amount1 - balance1;

            uint128 liquidity0ToPull = 0;
            if (amount0ToPull > 0) {
                liquidity0ToPull = LiquidityAmounts.getLiquidityForAmount0(
                    sqrtRatioX96,
                    sqrtUpperPriceX96,
                    amount0ToPull
                );
            }

            uint128 liquidity1ToPull = 0;
            if (amount1ToPull > 0) {
                liquidity1ToPull = LiquidityAmounts.getLiquidityForAmount1(
                    sqrtLowerPriceX96,
                    sqrtRatioX96,
                    amount1ToPull
                );
            }

            uint128 liquidityToPull = liquidity0ToPull;
            if (liquidity1ToPull > liquidityToPull) {
                liquidityToPull = liquidity1ToPull;
            }

            (uint256 expectedAmount0, uint256 expectedAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                sqrtLowerPriceX96,
                sqrtUpperPriceX96,
                liquidityToPull
            );

            if (expectedAmount0 < amount0ToPull || expectedAmount1 < amount1ToPull) {
                ++liquidityToPull;
            }

            positionManager.decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: uniV3Nft,
                    liquidity: liquidityToPull,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 1
                })
            );
        }

        positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: uniV3Nft,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        IERC20(token0).safeTransfer(sender, amount0);
        IERC20(token1).safeTransfer(sender, amount1);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function updateSecurityParams(bytes memory newSecurityParams) external override onlyAdmin {
        securityParams = newSecurityParams;
    }

    function withdraw(address sender, uint256 lpAmount, bytes memory params) external onlyAdmin {
        _withdraw(sender, lpAmount, params);
    }

    function transfer(address sender, address to, uint256 amount) external onlyAdmin returns (bool) {
        _transfer(sender, to, amount);
        return true;
    }

    function approve(address sender, address spender, uint256 amount) external onlyAdmin returns (bool) {
        _approve(sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address from, address to, uint256 amount) external onlyAdmin returns (bool) {
        _spendAllowance(from, sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address sender, address spender, uint256 addedValue) public onlyAdmin returns (bool) {
        _approve(sender, spender, allowance(sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external onlyAdmin returns (bool) {
        uint256 currentAllowance = allowance(sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferOwnership(address newAdmin) external onlyAdmin {
        _admin = newAdmin;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./UniV3Token.sol";
import "../libraries/UniswapCalculations.sol";

contract UniV3CompoundableToken is UniV3Token {
    uint256 public constant MAX_FEES_SWAP_SLIPPAGE = 1 * 10 ** 7; // 1%
    uint256 public constant DENOMINATOR = 10 ** 9;
    uint256 public constant Q96 = 2 ** 96;

    constructor(
        INonfungiblePositionManager positionManager_,
        ISwapRouter router_,
        UniV3TokenRegistry registry_,
        UniV3MEVProtection mevProtection_,
        bytes32 proxyContractBytecodeHash_
    ) UniV3Token(positionManager_, router_, registry_, mevProtection_, proxyContractBytecodeHash_) {}

    function _swapToTargetMEVUnsafe(uint160 sqrtPriceX96, uint256[2] memory currentAmounts) private {
        (uint256 tokenInIndex, uint256 amountIn) = UniswapCalculations.calculateAmountsForSwap(
            UniswapCalculations.PositionParams({
                sqrtLowerPriceX96: sqrtLowerPriceX96,
                sqrtUpperPriceX96: sqrtUpperPriceX96,
                sqrtPriceX96: sqrtPriceX96
            }),
            currentAmounts[0],
            currentAmounts[1],
            pool.fee()
        );

        address tokenIn = token0;
        address tokenOut = token1;
        if (tokenInIndex == 1) {
            (tokenIn, tokenOut) = (tokenOut, tokenIn);
        }

        try
            router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: fee,
                    recipient: address(this),
                    deadline: block.timestamp + 1,
                    amountIn: amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            )
        returns (uint256) {} catch {}
    }

    function compound() external {
        mevProtection.ensureNoMEV(address(pool), securityParams);
        positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: uniV3Nft,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        uint256 fee0 = IERC20(token0).balanceOf(address(this));
        uint256 fee1 = IERC20(token1).balanceOf(address(this));

        if (fee0 + fee1 == 0) return;
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        _swapToTargetMEVUnsafe(sqrtPriceX96, [fee0, fee1]);

        try
            positionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: uniV3Nft,
                    amount0Desired: IERC20(token0).balanceOf(address(this)),
                    amount1Desired: IERC20(token1).balanceOf(address(this)),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 1
                })
            )
        returns (uint128, uint256, uint256) {} catch {}
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/external/univ3/IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    error InvalidLength();
    error InvalidState();
    error InvalidIndex();
    error InvalidValue();

    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    /// @return withFail Flag that true if function observe of IUniswapV3Pool reverts with some error
    function consult(
        address pool,
        uint32 secondsAgo
    ) internal view returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity, bool withFail) {
        if (secondsAgo == 0) revert InvalidValue();

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        try IUniswapV3Pool(pool).observe(secondsAgos) returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        ) {
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[1] -
                secondsPerLiquidityCumulativeX128s[0];

            arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0))
                arithmeticMeanTick--;

            // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
            uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
            harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
        } catch {
            return (0, 0, true);
        }
    }

    function consultMultiple(
        address pool,
        uint32[] memory secondsAgo
    ) internal view returns (int24[] memory arithmeticMeanTicks, bool withFail) {
        if (secondsAgo.length < 2) revert InvalidLength();
        for (uint256 i = 1; i < secondsAgo.length; i++) {
            if (secondsAgo[i] <= secondsAgo[i - 1]) revert InvalidState();
        }

        try IUniswapV3Pool(pool).observe(secondsAgo) returns (int56[] memory tickCumulatives, uint160[] memory) {
            arithmeticMeanTicks = new int24[](secondsAgo.length - 1);

            for (uint256 i = 1; i < secondsAgo.length; i++) {
                int56 tickCumulativesDelta = tickCumulatives[i] - tickCumulatives[i - 1];
                uint32 timespan = secondsAgo[i] - secondsAgo[i - 1];
                arithmeticMeanTicks[i - 1] = int24(tickCumulativesDelta / int56(uint56(timespan)));

                if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(timespan)) != 0))
                    arithmeticMeanTicks[i - 1]--;
            }
            return (arithmeticMeanTicks, false);
        } catch {
            return (new int24[](0), true);
        }
    }

    function consultByObservation(address pool, uint16 observationsAgo) internal view returns (int24) {
        if (observationsAgo == 0) revert InvalidIndex();
        uint16[] memory observationsAgos = new uint16[](2);
        observationsAgos[0] = observationsAgo;
        int24[] memory arithmeticMeanTicks = consultByObservations(pool, observationsAgos);
        return arithmeticMeanTicks[0];
    }

    function consultByObservations(
        address pool,
        uint16[] memory observationsAgos
    ) internal view returns (int24[] memory arithmeticMeanTicks) {
        if (observationsAgos.length < 2) revert InvalidLength();
        uint32[] memory secondsAgo = new uint32[](observationsAgos.length);
        int56[] memory tickCumulatives = new int56[](observationsAgos.length);

        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        uint32 oldestObservation = (observationIndex + 1) % observationCardinality;
        uint32 newestObservation = oldestObservation + observationCardinality - 1;
        for (uint256 i = 0; i < observationsAgos.length; i++) {
            if (observationsAgos[i] >= observationCardinality) revert InvalidIndex();
            uint32 position = uint16((newestObservation - observationsAgos[i]) % observationCardinality);
            (secondsAgo[i], tickCumulatives[i], , ) = IUniswapV3Pool(pool).observations(position);
        }

        unchecked {
            arithmeticMeanTicks = new int24[](secondsAgo.length - 1);
            for (uint256 i = 1; i < secondsAgo.length; i++) {
                int56 tickCumulativesDelta = tickCumulatives[i] - tickCumulatives[i - 1];
                uint32 timespan = secondsAgo[i] - secondsAgo[i - 1];
                arithmeticMeanTicks[i - 1] = int24(tickCumulativesDelta / int56(uint56(timespan)));

                if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(timespan)) != 0))
                    arithmeticMeanTicks[i - 1]--;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMEVProtection {
    error PoolIsNotStable();

    function ensureNoMEV(address pool, bytes memory data) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IProxyToken is IERC165 {
    function rebalanceFlag() external view returns (bool);

    function owner() external view returns (address);

    function token() external view returns (address);

    function setRebalanceFlag(bool value) external;

    function upgradeTo(address newToken) external;

    function transferOwnership(address newAdmin) external;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function deposit(uint256[] memory tokenAmounts, bytes memory params) external;

    function withdraw(uint256 lpAmount, bytes memory params) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxyableToken {
    function deposit(address sender, uint256[] memory tokenAmounts, bytes memory params) external;

    function withdraw(address sender, uint256 lpAmount, bytes memory params) external;

    function transfer(address sender, address to, uint256 amount) external returns (bool);

    function approve(address sender, address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address from, address to, uint256 amount) external returns (bool);

    function increaseAllowance(address sender, address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address sender, address spender, uint256 subtractedValue) external returns (bool);

    function isSameKind(address token) external view returns (bool);

    function updateSecurityParams(bytes memory newSecurityParams) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IBaseOracle.sol";

interface IMellowBaseOracle is IBaseOracle {
    function isTokenSupported(address token) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPermissionsFacet {
    struct Storage {
        bool initialized;
        mapping(address => uint256) userRoles;
        uint256 publicRoles;
        mapping(address => uint256) allowAllSignaturesRoles;
        mapping(address => mapping(bytes4 => uint256)) allowSignatureRoles;
    }

    function initializePermissionsFacet(address admin) external;

    function hasPermission(address user, address contractAddress, bytes4 signature) external view returns (bool);

    function requirePermission(address user, address contractAddress, bytes4 signature) external;

    function grantPublicRole(uint8 role) external;

    function revokePublicRole(uint8 role) external;

    function grantContractRole(address contractAddress, uint8 role) external;

    function revokeContractRole(address contractAddress, uint8 role) external;

    function grantContractSignatureRole(address contractAddress, bytes4 signature, uint8 role) external;

    function revokeContractSignatureRole(address contractAddress, bytes4 signature, uint8 role) external;

    function grantRole(address user, uint8 role) external;

    function revokeRole(address user, uint8 role) external;

    function userRoles(address user) external view returns (uint256);

    function publicRoles() external view returns (uint256);

    function allowAllSignaturesRoles(address contractAddress) external view returns (uint256);

    function allowSignatureRoles(address contractAddress, bytes4 selector) external view returns (uint256);

    function permissionsInitialized() external view returns (bool);

    function permissionsSelectors() external view returns (bytes4[] memory selectors_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IVaultFacet.sol";

interface IDutchAuctionFacet {
    struct Storage {
        uint32 duration;
        uint256 startCoefficientX96;
        uint256 endCoefficientX96;
        uint256 startTimestamp;
        address strategy;
    }

    function checkTvlAfterRebalance(uint256 tvlBefore, uint256 tvlAfter) external returns (bool);

    function updateAuctionParams(
        uint256 startCoefficientX96,
        uint256 endCoefficientX96,
        uint32 duration,
        address strategy
    ) external;

    function auctionParams()
        external
        view
        returns (
            uint256 startCoefficientX96,
            uint256 endCoefficientX96,
            uint32 duration,
            uint256 startTimestamp,
            address strategy
        );

    function finishAuction() external;

    function startAuction() external;

    function stopAuction() external;

    function dutchAuctionInitialized() external view returns (bool);

    function dutchAuctionSelectors() external view returns (bytes4[] memory selectors_);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IBaseOracle.sol";

interface IOracle {
    /// @param tokensInOrderOfDifficulty - tokens are sorted by 'difficulty'
    /// @dev which means that tokens from this array with a lower index are converted by oracles into tokens
    /// @dev from this array with a higher index
    /// @param tokenAmounts - requested number of tokens
    /// @param securityParams - additional security parameters for oracles for MEV protection
    /// @return uint256 - tvl calculated in the last token in tokensInOrderOfDifficulty array
    function quote(
        address[] calldata tokensInOrderOfDifficulty,
        uint256[] memory tokenAmounts,
        bytes[] calldata securityParams
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ITokensManagementFacet.sol";

interface ITokensManagementFacet {
    struct Storage {
        address vault;
    }

    function vault() external pure returns (address);

    function approve(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LpToken is ERC20 {
    error Forbidden();
    address public owner;
    string private _name;
    string private _symbol;

    constructor() ERC20("LpToken", "MLP") {}

    function initialize(string memory name_, string memory symbol_, address owner_) external {
        _name = name_;
        _symbol = symbol_;
        owner = owner_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != owner) revert Forbidden();
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        if (msg.sender != owner) revert Forbidden();
        _burn(to, amount);
    }

    function clone(string memory name_, string memory symbol_, address owner_) external returns (LpToken lpToken) {
        lpToken = LpToken(Clones.cloneDeterministic(address(this), bytes32(abi.encode(owner_, bytes12(0)))));
        lpToken.initialize(name_, symbol_, owner_);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupportedByOracleToken {
    function oracle() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library CommonLibrary {
    function getContractBytecodeHash(address addr) internal view returns (bytes32 bytecodeHash) {
        assembly {
            bytecodeHash := extcodehash(addr)
        }
    }

    /// @dev returns index of element in array or type(uint32).max if not found
    function binarySearch(address[] calldata array, address element) internal pure returns (uint32 index) {
        uint32 left = 0;
        uint32 right = uint32(array.length);
        uint32 mid;
        while (left + 1 < right) {
            mid = (left + right) >> 1;
            if (array[mid] > element) {
                right = mid;
            } else {
                left = mid;
            }
        }
        if (array[left] != element) {
            return type(uint32).max;
        }
        return left;
    }

    function sort(address[] calldata array) internal pure returns (address[] memory) {
        if (isSorted(array)) return array;
        address[] memory sortedArray = array;
        for (uint32 i = 0; i < array.length; i++) {
            for (uint32 j = i + 1; j < array.length; j++) {
                if (sortedArray[i] > sortedArray[j])
                    (sortedArray[i], sortedArray[j]) = (sortedArray[j], sortedArray[i]);
            }
        }
        return sortedArray;
    }

    function isSorted(address[] calldata array) internal pure returns (bool) {
        for (uint32 i = 0; i + 1 < array.length; i++) {
            if (array[i] > array[i + 1]) return false;
        }
        return true;
    }

    function sortAndMerge(address[] calldata a, address[] calldata b) internal pure returns (address[] memory array) {
        address[] memory sortedA = sort(a);
        address[] memory sortedB = sort(b);
        array = new address[](a.length + b.length);
        uint32 i = 0;
        uint32 j = 0;
        while (i < a.length && j < b.length) {
            if (sortedA[i] < sortedB[j]) {
                array[i + j] = sortedA[i];
                i++;
            } else {
                array[i + j] = sortedB[j];
                j++;
            }
        }
        while (i < a.length) {
            array[i + j] = sortedA[i];
            i++;
        }
        while (j < b.length) {
            array[i + j] = sortedB[j];
            j++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
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
            // diff: original uint256 twos = -denominator & denominator;
            uint256 twos = uint256(-int256(denominator)) & denominator;
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
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./FullMath.sol";
import "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        // diff: original require(absTick <= uint256(MAX_TICK), "T");
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/external/univ3/IUniswapV3Pool.sol";
import "../../interfaces/external/univ3/INonfungiblePositionManager.sol";
import "./FixedPoint128.sol";

import "./TickMath.sol";
import "./LiquidityAmounts.sol";

/// @title Returns information about the token value held in a Uniswap V3 NFT
library PositionValue {
    /// @notice Returns the total amounts of token0 and token1, i.e. the sum of fees and principal
    /// that a given nonfungible position manager token is worth
    /// @param positionManager The Uniswap V3 NonfungiblePositionManager
    /// @param tokenId The tokenId of the token for which to get the total value
    /// @param sqrtRatioX96 The square root price X96 for which to calculate the principal amounts
    /// @return amount0 The total amount of token0 including principal and fees
    /// @return amount1 The total amount of token1 including principal and fees
    function total(
        INonfungiblePositionManager positionManager,
        uint256 tokenId,
        uint160 sqrtRatioX96,
        IUniswapV3Pool pool
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (uint256 amount0Principal, uint256 amount1Principal) = principal(positionManager, tokenId, sqrtRatioX96);
        (uint256 amount0Fee, uint256 amount1Fee) = fees(positionManager, tokenId, pool);
        return (amount0Principal + amount0Fee, amount1Principal + amount1Fee);
    }

    /// @notice Calculates the principal (currently acting as liquidity) owed to the token owner in the event
    /// that the position is burned
    /// @param positionManager The Uniswap V3 NonfungiblePositionManager
    /// @param tokenId The tokenId of the token for which to get the total principal owed
    /// @param sqrtRatioX96 The square root price X96 for which to calculate the principal amounts
    /// @return amount0 The principal amount of token0
    /// @return amount1 The principal amount of token1
    function principal(
        INonfungiblePositionManager positionManager,
        uint256 tokenId,
        uint160 sqrtRatioX96
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = positionManager.positions(tokenId);

        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    struct FeeParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 positionFeeGrowthInside0LastX128;
        uint256 positionFeeGrowthInside1LastX128;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    /// @notice Calculates the total fees owed to the token owner
    /// @param positionManager The Uniswap V3 NonfungiblePositionManager
    /// @param tokenId The tokenId of the token for which to get the total fees owed
    /// @return amount0 The amount of fees owed in token0
    /// @return amount1 The amount of fees owed in token1
    function fees(
        INonfungiblePositionManager positionManager,
        uint256 tokenId,
        IUniswapV3Pool pool
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 positionFeeGrowthInside0LastX128,
            uint256 positionFeeGrowthInside1LastX128,
            uint256 tokensOwed0,
            uint256 tokensOwed1
        ) = positionManager.positions(tokenId);

        return
            _fees(
                FeeParams({
                    token0: token0,
                    token1: token1,
                    fee: fee,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidity: liquidity,
                    positionFeeGrowthInside0LastX128: positionFeeGrowthInside0LastX128,
                    positionFeeGrowthInside1LastX128: positionFeeGrowthInside1LastX128,
                    tokensOwed0: tokensOwed0,
                    tokensOwed1: tokensOwed1
                }),
                pool
            );
    }

    function _fees(
        FeeParams memory feeParams,
        IUniswapV3Pool pool
    ) private view returns (uint256 amount0, uint256 amount1) {
        (uint256 poolFeeGrowthInside0LastX128, uint256 poolFeeGrowthInside1LastX128) = _getFeeGrowthInside(
            pool,
            feeParams.tickLower,
            feeParams.tickUpper
        );

        unchecked {
            amount0 =
                FullMath.mulDiv(
                    poolFeeGrowthInside0LastX128 - feeParams.positionFeeGrowthInside0LastX128,
                    feeParams.liquidity,
                    FixedPoint128.Q128
                ) +
                feeParams.tokensOwed0;

            amount1 =
                FullMath.mulDiv(
                    poolFeeGrowthInside1LastX128 - feeParams.positionFeeGrowthInside1LastX128,
                    feeParams.liquidity,
                    FixedPoint128.Q128
                ) +
                feeParams.tokensOwed1;
        }
    }

    function _getFeeGrowthInside(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper
    ) private view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        (, int24 tickCurrent, , , , , ) = pool.slot0();
        (, , uint256 lowerFeeGrowthOutside0X128, uint256 lowerFeeGrowthOutside1X128, , , , ) = pool.ticks(tickLower);
        (, , uint256 upperFeeGrowthOutside0X128, uint256 upperFeeGrowthOutside1X128, , , , ) = pool.ticks(tickUpper);

        unchecked {
            if (tickCurrent < tickLower) {
                feeGrowthInside0X128 = lowerFeeGrowthOutside0X128 - upperFeeGrowthOutside0X128;
                feeGrowthInside1X128 = lowerFeeGrowthOutside1X128 - upperFeeGrowthOutside1X128;
            } else if (tickCurrent < tickUpper) {
                uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
                uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
                feeGrowthInside0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128 - upperFeeGrowthOutside0X128;
                feeGrowthInside1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128 - upperFeeGrowthOutside1X128;
            } else {
                feeGrowthInside0X128 = upperFeeGrowthOutside0X128 - lowerFeeGrowthOutside0X128;
                feeGrowthInside1X128 = upperFeeGrowthOutside1X128 - lowerFeeGrowthOutside1X128;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/utils/IProxyableToken.sol";

import "./ProxyToken.sol";

abstract contract ProxyableToken is IProxyableToken {
    using SafeERC20 for IERC20;
    address internal _admin;

    function admin() public view returns (address) {
        return _admin;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./external/LiquidityAmounts.sol";

library UniswapCalculations {
    uint256 public constant Q96 = 2 ** 96;

    struct PositionParams {
        uint160 sqrtLowerPriceX96;
        uint160 sqrtUpperPriceX96;
        uint160 sqrtPriceX96;
    }

    function calculateTargetRatioOfToken1(
        PositionParams memory position,
        uint256 priceX96
    ) public pure returns (uint256 targetRatioOfToken1X96) {
        if (position.sqrtLowerPriceX96 >= position.sqrtPriceX96) {
            return 0;
        } else if (position.sqrtUpperPriceX96 <= position.sqrtPriceX96) {
            return Q96;
        }

        (uint256 x, uint256 y) = LiquidityAmounts.getAmountsForLiquidity(
            position.sqrtPriceX96,
            position.sqrtLowerPriceX96,
            position.sqrtUpperPriceX96,
            uint128(Q96)
        );

        targetRatioOfToken1X96 = FullMath.mulDiv(y, Q96, FullMath.mulDiv(x, priceX96, Q96) + y);
    }

    function calculateAmountsForSwap(
        PositionParams memory position,
        uint256 amount0,
        uint256 amount1,
        uint24 swapFee
    ) external pure returns (uint256 tokenInIndex, uint256 amountIn) {
        uint256 priceX96 = FullMath.mulDiv(position.sqrtPriceX96, position.sqrtPriceX96, Q96);

        uint256 targetRatioOfToken1X96 = calculateTargetRatioOfToken1(position, priceX96);

        uint256 targetRatioOfToken0X96 = Q96 - targetRatioOfToken1X96;
        uint256 currentRatioOfToken1X96 = FullMath.mulDiv(
            amount1,
            Q96,
            amount1 + FullMath.mulDiv(amount0, priceX96, Q96)
        );

        uint256 feesX96 = FullMath.mulDiv(Q96, uint256(swapFee), 10 ** 6);

        if (currentRatioOfToken1X96 > targetRatioOfToken1X96) {
            tokenInIndex = 1;
            // (dx * y0 - dy * x0 * p) / (1 - dy * fee)
            uint256 invertedPriceX96 = FullMath.mulDiv(Q96, Q96, priceX96);
            amountIn = FullMath.mulDiv(
                FullMath.mulDiv(amount1, targetRatioOfToken0X96, Q96) -
                    FullMath.mulDiv(targetRatioOfToken1X96, amount0, invertedPriceX96),
                Q96,
                Q96 - FullMath.mulDiv(targetRatioOfToken1X96, feesX96, Q96)
            );
        } else {
            // (dy * x0 - dx * y0 / p) / (1 - dx * fee)
            tokenInIndex = 0;
            amountIn = FullMath.mulDiv(
                FullMath.mulDiv(amount0, targetRatioOfToken1X96, Q96) -
                    FullMath.mulDiv(targetRatioOfToken0X96, amount1, priceX96),
                Q96,
                Q96 - FullMath.mulDiv(targetRatioOfToken0X96, feesX96, Q96)
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IBaseOracle {
    function quote(
        address token,
        uint256 amount,
        bytes memory securityParams
    ) external view returns (address[] memory tokens, uint256[] memory prices);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}