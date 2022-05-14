// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./libraries/PoolManager.sol";
import "./libraries/LiquidityManager.sol";
import "./libraries/SwapManager.sol";

contract CazzPayDex {
    /////////////////////////
    // EVENTS
    /////////////////////////

    event PoolCreatedWithCZP(
        address poolAddr,
        address otherTokenContractAddr,
        uint24 poolFee
    );

    event MintedNewPositionInCzpAndOtherTokenPool(
        uint256 tokenId,
        uint128 liquidity,
        uint256 czpDeposited,
        uint256 otherTokenDeposited
    );

    event AddedLiquidityToCzpAndOtherTokenPosition(
        uint128 liquidity,
        uint256 czpAdded,
        uint256 otherTokenAdded
    );

    event RemovedLiquidityToCzpAndOtherTokenPosition(
        uint256 czpAmtWithdrawn,
        uint256 otherTokenAmtWithdrawn
    );

    event BoughtWithOtherToken(uint256 otherTokenAmtUsedForTransaction);

    event SwappedCzpForOtherToken(
        address _otherTokenContractAddr,
        uint24 _poolFee,
        uint256 _otherTokenAmt,
        uint256 _czpAmt
    );

    event SwappedOtherTokenForCzp(
        address _otherTokenContractAddr,
        uint24 _poolFee,
        uint256 _otherTokenAmt,
        uint256 _czpAmt
    );

    /////////////////////////
    // STORAGE
    /////////////////////////
    IUniswapV3Factory internal _factoryContract;
    INonfungiblePositionManager internal _positionManager;
    ISwapRouter internal _swapRouter;
    address private _czpContractAddr;

    /////////////////////////
    // FUNCTIONS
    /////////////////////////

    /**
    @notice Constructor
    @param _factoryContractAddr Address of factory contract
    @param _positionManagerContractAddr Address of the nft position manager contract
    @param _swapRouterContractAddr Address of the Swap router
    @param _czpContractAddress Address of the CZP contract
    */
    constructor(
        address _factoryContractAddr,
        address _positionManagerContractAddr,
        address _swapRouterContractAddr,
        address _czpContractAddress
    ) {
        _factoryContract = IUniswapV3Factory(_factoryContractAddr);
        _positionManager = INonfungiblePositionManager(
            _positionManagerContractAddr
        );
        _swapRouter = ISwapRouter(_swapRouterContractAddr);
        _czpContractAddr = _czpContractAddress;
    }

    /**
    @notice Calculates the equivalent $CZP from other token in pool
    @notice Cannot be used for pools other than those that have CZP
    @param _poolWithCzpAndOtherTokenAddr Address of the pool to use for query
    @param _otherTokenContractAddr Address of the other token contract
    @param _secondsAgo Last n seconds interval to use for time-weighted calculation
    @param _otherTokenAmt Other token amount to get equivalent CZP for
    @return czpAmt Equivalent CZP amount
     */
    function calculateCzpFromOtherToken(
        address _poolWithCzpAndOtherTokenAddr,
        address _otherTokenContractAddr,
        uint32 _secondsAgo,
        uint128 _otherTokenAmt
    ) public view returns (uint256 czpAmt) {
        return
            PoolManager.calculateCzpFromOtherToken(
                _poolWithCzpAndOtherTokenAddr,
                _czpContractAddr,
                _otherTokenContractAddr,
                _secondsAgo,
                _otherTokenAmt
            );
    }

    /**
    @notice Calculates the equivalent other token from CZP in pool
    @notice Cannot be used for pools other than those that have CZP
    @param _poolWithCzpAndOtherTokenAddr Address of the pool to use for query
    @param _otherTokenContractAddr Address of the other token contract
    @param _secondsAgo Last n seconds interval to use for time-weighted calculation
    @param _czpAmt CZP amount to get equivalent other token for
    @return otherTokenAmt Equivalent CZP amount
     */
    function calculateOtherTokenFromCzp(
        address _poolWithCzpAndOtherTokenAddr,
        address _otherTokenContractAddr,
        uint32 _secondsAgo,
        uint128 _czpAmt
    ) public view returns (uint256 otherTokenAmt) {
        return
            PoolManager.calculateOtherTokenFromCzp(
                _poolWithCzpAndOtherTokenAddr,
                _czpContractAddr,
                _otherTokenContractAddr,
                _secondsAgo,
                _czpAmt
            );
    }

    /**
    @notice Creates a pool with $CZP and another token
    @param _otherTokenContractAddr Contract address of the other token to form pool with
    @param _poolFee Pool fee for the newly created Pool
    @param _price Price of the pool to initialize; CZP div OtherToken
    @dev Fires event PoolCreatedWithCZP(address poolAddr, address otherTokenContractAddr, uint24 poolFee)
    @return poolAddr Address of the pool created
    */
    function createPoolWithCzp(
        address _otherTokenContractAddr,
        uint24 _poolFee,
        uint256 _price
    ) external returns (address poolAddr) {
        poolAddr = PoolManager.createPoolWithCzp(
            _positionManager,
            _czpContractAddr,
            _otherTokenContractAddr,
            _poolFee,
            _price
        );
        emit PoolCreatedWithCZP(poolAddr, _otherTokenContractAddr, _poolFee);
    }

    /**
    @notice Fetches the pool address of a CZP-OtherToken pool
    @param _otherTokenContractAddr Address of the other token contract
    @return poolAddr Address of the pool
     */
    function getCzpAndOtherTokenPoolAddr(
        address _otherTokenContractAddr,
        uint24 _poolFee
    ) public view returns (address poolAddr) {
        return
            PoolManager.getCzpAndOtherTokenPoolAddr(
                _factoryContract,
                _czpContractAddr,
                _otherTokenContractAddr,
                _poolFee
            );
    }

    /**
    @notice Mints a new position in a CZP-OtherToken pool
    @notice Contract must be approved to transfer the specified tokens BEFORE calling this
    @notice Mints the Position NFT to the caller
    @notice Remaning tokens are refunded to the caller
    @param _otherTokenContractAddr Address of the other token contract
    @param _czpAmtToDeposit Amount of CZP token to deposit in the position
    @param _otherTokenAmtToDeposit Amount of the other token to deposit in the position
    @param _poolFee Swap fees for this position
    @param _tickLower Lower tick for concentrated liquidity range
    @param _tickUpper Upper tick for concentrated liquidity range
    @param _minCzpAmtToDeposit Minimum CZP to deposit
    @param _minOtherTokenAmtToDeposit Minimum other token to deposit
    @param _deadline Deadline (Unix secs) to execute this transaction
    @return tokenId Token id of the new position NFT
    @return liquidity Liquidity that was deposited
    @return czpDeposited Amount of CZP that was deposited
    @dev Emits event MintedNewPositionInCzpAndOtherTokenPool(uint256 tokenId, uint128 liquidity, uint256 czpDeposited, uint256 otherTokenDeposited)
    @return otherTokenDeposited Amount of other token that was deposited
     */
    function mintNewPositionInCzpAndOtherTokenPool(
        address _otherTokenContractAddr,
        uint256 _czpAmtToDeposit,
        uint256 _otherTokenAmtToDeposit,
        uint24 _poolFee,
        int24 _tickLower,
        int24 _tickUpper,
        uint8 _minCzpAmtToDeposit,
        uint8 _minOtherTokenAmtToDeposit,
        uint256 _deadline
    )
        public
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 czpDeposited,
            uint256 otherTokenDeposited
        )
    {
        LiquidityManager.MintNewPositionInCzpAndOtherTokenPoolParams
            memory mintParams = LiquidityManager
                .MintNewPositionInCzpAndOtherTokenPoolParams({
                    _positionManager: _positionManager,
                    _czpContractAddr: _czpContractAddr,
                    _otherTokenContractAddr: _otherTokenContractAddr,
                    _czpAmtToDeposit: _czpAmtToDeposit,
                    _otherTokenAmtToDeposit: _otherTokenAmtToDeposit,
                    _poolFee: _poolFee,
                    _tickLower: _tickLower,
                    _tickUpper: _tickUpper,
                    _minCzpAmtToDeposit: _minCzpAmtToDeposit,
                    _minOtherTokenAmtToDeposit: _minOtherTokenAmtToDeposit,
                    _deadline: _deadline
                });

        (
            tokenId,
            liquidity,
            czpDeposited,
            otherTokenDeposited
        ) = LiquidityManager.mintNewPositionInCzpAndOtherTokenPool(mintParams);

        emit MintedNewPositionInCzpAndOtherTokenPool(
            tokenId,
            liquidity,
            czpDeposited,
            otherTokenDeposited
        );
    }

    /**
    @notice Adds liquidity to an owned position in a CZP-OtherToken pool
    @notice Contract must be approved to transfer the specified tokens BEFORE calling this
    @notice Remaning tokens are refunded to the caller
    @param _otherTokenContractAddr Address of the other token contract
    @param _tokenId Token id of the position's NFT
    @param _czpAmtToAdd Amount of CZP token to add in the position
    @param _otherTokenAmtToAdd Amount of the other token to add in the position
    @param _minCzpAmtToAdd Minimum CZP to add
    @param _minOtherTokenAmtToAdd Minimum other token to add
    @param _deadline Deadline (unix secs) to execute this transaction
    @dev Emits event AddedLiquidityToCzpAndOtherTokenPosition(uint128 liquidity,uint256 czpAdded,uint256 otherTokenAdded)
    @return liquidity Liquidity added to the position
    @return czpAdded Amount of CZP that could be added
    @return otherTokenAdded Amount of other token that could be added
     */
    function addLiquidityToCzpAndOtherTokenPosition(
        address _otherTokenContractAddr,
        uint256 _tokenId,
        uint256 _czpAmtToAdd,
        uint256 _otherTokenAmtToAdd,
        uint256 _minCzpAmtToAdd,
        uint256 _minOtherTokenAmtToAdd,
        uint256 _deadline
    )
        public
        returns (
            uint128 liquidity,
            uint256 czpAdded,
            uint256 otherTokenAdded
        )
    {
        LiquidityManager.AddLiquidityToCzpAndOtherTokenPositionParams
            memory addLiquidityParams = LiquidityManager
                .AddLiquidityToCzpAndOtherTokenPositionParams({
                    _positionManager: _positionManager,
                    _czpContractAddr: _czpContractAddr,
                    _otherTokenContractAddr: _otherTokenContractAddr,
                    _tokenId: _tokenId,
                    _czpAmtToAdd: _czpAmtToAdd,
                    _otherTokenAmtToAdd: _otherTokenAmtToAdd,
                    _minCzpAmtToAdd: _minCzpAmtToAdd,
                    _minOtherTokenAmtToAdd: _minOtherTokenAmtToAdd,
                    _deadline: _deadline
                });

        (liquidity, czpAdded, otherTokenAdded) = LiquidityManager
            .addLiquidityToCzpAndOtherTokenPosition(addLiquidityParams);

        emit AddedLiquidityToCzpAndOtherTokenPosition(
            liquidity,
            czpAdded,
            otherTokenAdded
        );
    }

    /**
    @notice Removes some liquidity from a position in a CZP-other token pool, and transfers tokens to position owner
    @param _tokenId Token id of the position's NFT
    @param _remainingLiquidity Liquidity that should remain after withdrawing
    @param _minCzpToWithdraw Minimum CZP to withdraw
    @param _minOtherTokenToWithdraw Minimum other tokens to withdraw
    @param _deadline Deadline (unix secs) to execute this transaction
    @dev Emits event RemovedLiquidityToCzpAndOtherTokenPosition(uint256 czpAmtWithdrawn,uint256 otherTokenAmtWithdrawn)
    @return czpAmtWithdrawn Amount of CZP that could be withdrawn
    @return otherTokenAmtWithdrawn Amount of other token that could be withdrawn
     */
    function removeLiquidityToCzpAndOtherTokenPosition(
        uint256 _tokenId,
        uint128 _remainingLiquidity,
        uint256 _minCzpToWithdraw,
        uint256 _minOtherTokenToWithdraw,
        uint256 _deadline
    ) public returns (uint256 czpAmtWithdrawn, uint256 otherTokenAmtWithdrawn) {
        LiquidityManager.RemoveLiquidityToCzpAndOtherTokenPosition
            memory removeLiquidityParams = LiquidityManager
                .RemoveLiquidityToCzpAndOtherTokenPosition({
                    _positionManager: _positionManager,
                    _tokenId: _tokenId,
                    _remainingLiquidity: _remainingLiquidity,
                    _minCzpToWithdraw: _minCzpToWithdraw,
                    _minOtherTokenToWithdraw: _minOtherTokenToWithdraw,
                    _deadline: _deadline
                });

        (czpAmtWithdrawn, otherTokenAmtWithdrawn) = LiquidityManager
            .removeLiquidityToCzpAndOtherTokenPosition(removeLiquidityParams);

        emit RemovedLiquidityToCzpAndOtherTokenPosition(
            czpAmtWithdrawn,
            otherTokenAmtWithdrawn
        );
    }

    /**
    @notice This is to be called by buyer when purchasing.
    @notice Buyer must approve this contract to operate the appropriate amount of input tokens
    @dev This swaps input tokens for exact output (CZP) tokens, and burns the CZP tokens, to mimic FIAT transfer to seller
    @dev To get amount of other token, use `calculateOtherTokenFromCzp()`
    @param _otherTokenContractAddr Other token contract address
    @param _otherTokenAmtToPay Amount of other tokens to pay with
    @param _fiatToPay Amount of FIAT to pay with (atomic units, decimals: 18); Note: CZP:FIAT = 1:1 (stable)
    @param _poolFee Pool fees of the pool to be used
    @param _deadline Deadline (unix secs) to execute this transaction
    @dev Emits event BoughtWithOtherToken(uint256 otherTokenAmtUsedForTransaction);
    @return otherTokenAmtUsedForTransaction Amount of other tokens used for the transaction (remaining was refunded)
     */
    function buyWithOtherToken(
        address _otherTokenContractAddr,
        uint256 _otherTokenAmtToPay,
        uint256 _otherTokenMaxAmtToPay,
        uint256 _fiatToPay,
        uint24 _poolFee,
        uint256 _deadline
    ) public returns (uint256 otherTokenAmtUsedForTransaction) {
        SwapManager.BuyWithOtherTokenParams memory params = SwapManager
            .BuyWithOtherTokenParams({
                _swapRouter: _swapRouter,
                _czpContractAddr: _czpContractAddr,
                _otherTokenContractAddr: _otherTokenContractAddr,
                _otherTokenAmtToPay: _otherTokenAmtToPay,
                _otherTokenMaxAmtToPay: _otherTokenMaxAmtToPay,
                _fiatToPay: _fiatToPay,
                _poolFee: _poolFee,
                _deadline: _deadline
            });
        otherTokenAmtUsedForTransaction = SwapManager.buyWithOtherToken(params);

        emit BoughtWithOtherToken(otherTokenAmtUsedForTransaction);
    }

    /**
    @notice Swaps max amount of input tokens for exact amount of output tokens
    @notice Caller should approve contract to transfer input tokens BEFORE calling this
    @notice Caller would be refunded any unused input tokens
    @param _otherTokenContractAddr Address of the other token contract
    @param _poolFee Pool fees
    @param _otherTokenAmt Exact amount of other tokens needed
    @param _czpAmtMax Max CZP to use for swap
    @param _deadline Deadline (unix secs) to execute this transaction
    @dev Emits event SwappedCzpForOtherToken(address _otherTokenContractAddr, uint24 _poolFee, uint256 _otherTokenAmt, uint256 _czpAmt);
    @return czpAmtUsed Amount of CZP tokens used
     */
    function swapCzpForExactOtherToken(
        address _otherTokenContractAddr,
        uint24 _poolFee,
        uint256 _otherTokenAmt,
        uint256 _czpAmtMax,
        uint256 _deadline
    ) public returns (uint256 czpAmtUsed) {
        SwapManager.SwapInputForExactOutputParams
            memory swapParams = SwapManager.SwapInputForExactOutputParams({
                _swapRouter: _swapRouter,
                _inputTokenContractAddr: _czpContractAddr,
                _outputTokenContractAddr: _otherTokenContractAddr,
                _poolFee: _poolFee,
                _outputTokenAmt: _otherTokenAmt,
                _inputTokenAmtMax: _czpAmtMax,
                _deadline: _deadline
            });
        czpAmtUsed = SwapManager.swapInputForExactOutput(swapParams);

        emit SwappedCzpForOtherToken(
            _otherTokenContractAddr,
            _poolFee,
            _otherTokenAmt,
            (_czpAmtMax - czpAmtUsed)
        );
    }

    /**
    @notice Swaps max amount of input tokens for exact amount of output tokens
    @notice Caller should approve contract to transfer input tokens BEFORE calling this
    @notice Caller would be refunded any unused input tokens
    @param _otherTokenContractAddr Address of the other token contract
    @param _poolFee Pool fees
    @param _czpTokenAmt Exact amount of CZP tokens needed
    @param _otherTokenAmtMax Max other tokens to use for swap
    @param _deadline Deadline (unix secs) to execute this transaction
    @dev Emits event SwappedOtherTokenForCzp(address _otherTokenContractAddr, uint24 _poolFee, uint256 _otherTokenAmt, uint256 _czpAmt);
    @return otherTokenAmtUsed Amount of other tokens used
     */
    function swapOtherTokenForExactCzp(
        address _otherTokenContractAddr,
        uint24 _poolFee,
        uint256 _czpTokenAmt,
        uint256 _otherTokenAmtMax,
        uint256 _deadline
    ) public returns (uint256 otherTokenAmtUsed) {
        SwapManager.SwapInputForExactOutputParams
            memory swapParams = SwapManager.SwapInputForExactOutputParams({
                _swapRouter: _swapRouter,
                _inputTokenContractAddr: _otherTokenContractAddr,
                _outputTokenContractAddr: _czpContractAddr,
                _poolFee: _poolFee,
                _outputTokenAmt: _czpTokenAmt,
                _inputTokenAmtMax: _otherTokenAmtMax,
                _deadline: _deadline
            });
        otherTokenAmtUsed = SwapManager.swapInputForExactOutput(swapParams);

        emit SwappedOtherTokenForCzp(
            _otherTokenContractAddr,
            _poolFee,
            _otherTokenAmtMax - otherTokenAmtUsed,
            _czpTokenAmt
        );
    }

    /**
    @notice Swaps exact amount of CZP for max other tokens
    @param _otherTokenContractAddr Output token contract's address
    @param _poolFee Pool fees
    @param _czpTokenAmt Exact amount of input tokens to use
    @param _otherTokenAmtMin Minimum amount of output tokens desired
    @param _deadline Deadline (unix secs) for this transaction to execute
    @dev Emits event SwappedCzpForOtherToken(address _otherTokenContractAddr, uint24 _poolFee, uint256 _otherTokenAmt, uint256 _czpAmt);
    @return otherTokenAmtOut Amount of other token received from swap
     */
    function swapExactCzpForOtherToken(
        address _otherTokenContractAddr,
        uint24 _poolFee,
        uint256 _czpTokenAmt,
        uint256 _otherTokenAmtMin,
        uint256 _deadline
    ) public returns (uint256 otherTokenAmtOut) {
        SwapManager.SwapExactInputForOutputParams
            memory swapParams = SwapManager.SwapExactInputForOutputParams({
                _swapRouter: _swapRouter,
                _inputTokenContractAddr: _czpContractAddr,
                _outputTokenContractAddr: _otherTokenContractAddr,
                _poolFee: _poolFee,
                _inputTokenAmt: _czpTokenAmt,
                _outputTokenAmtMin: _otherTokenAmtMin,
                _deadline: _deadline
            });
        otherTokenAmtOut = SwapManager.swapExactInputForOutput(swapParams);

        emit SwappedCzpForOtherToken(
            _otherTokenContractAddr,
            _poolFee,
            otherTokenAmtOut,
            _czpTokenAmt
        );
    }

    /**
    @notice Swaps exact amount of other tokens for max CZP
    @param _otherTokenContractAddr Output token contract's address
    @param _poolFee Pool fees
    @param _otherTokenAmt Exact amount of other token to use
    @param _czpTokenAmtMin Minimum amount of CZP token desired
    @param _deadline Deadline (unix secs) for this transaction to execute
    @dev Emits event SwappedOtherTokenForCzp(address _otherTokenContractAddr, uint24 _poolFee, uint256 _otherTokenAmt, uint256 _czpAmt);
    @return czpTokenAmtOut Amount of CZP received from swap
     */
    function swapExactOtherTokenForCzp(
        address _otherTokenContractAddr,
        uint24 _poolFee,
        uint256 _otherTokenAmt,
        uint256 _czpTokenAmtMin,
        uint256 _deadline
    ) public returns (uint256 czpTokenAmtOut) {
        SwapManager.SwapExactInputForOutputParams
            memory swapParams = SwapManager.SwapExactInputForOutputParams({
                _swapRouter: _swapRouter,
                _inputTokenContractAddr: _otherTokenContractAddr,
                _outputTokenContractAddr: _czpContractAddr,
                _poolFee: _poolFee,
                _inputTokenAmt: _otherTokenAmt,
                _outputTokenAmtMin: _czpTokenAmtMin,
                _deadline: _deadline
            });
        czpTokenAmtOut = SwapManager.swapExactInputForOutput(swapParams);

        emit SwappedOtherTokenForCzp(
            _otherTokenContractAddr,
            _poolFee,
            _otherTokenAmt,
            czpTokenAmtOut
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
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
    function positions(uint256 tokenId)
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
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

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
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

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
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "./Math.sol";

library PoolManager {
    /**
    @notice Create Pool with CZP
    @notice Creates a pool with $CZP and another token
    @param _positionManager Position manager
    @param _czpContractAddr Contract address of CZP contract
    @param _otherTokenContractAddr Contract address of the other token to form pool with
    @param _poolFee Pool fee for the newly created Pool
    @param _price Price of the pool to initialize; CZP div OtherToken
    @return poolAddr Address of the pool created
    */
    function createPoolWithCzp(
        INonfungiblePositionManager _positionManager,
        address _czpContractAddr,
        address _otherTokenContractAddr,
        uint24 _poolFee,
        uint256 _price
    ) public returns (address poolAddr) {
        poolAddr = _positionManager.createAndInitializePoolIfNecessary(_otherTokenContractAddr, _czpContractAddr, _poolFee, uint160(Math.sqrt(_price) * 2**96));
    }

    /**
    @notice Fetches the pool address of a CZP-OtherToken pool
    @param _factoryContract Factory contract
    @param _czpContractAddr Address of the CZP contract
    @param _otherTokenContractAddr Address of the other token contract
    @return poolAddr Address of the pool
     */
    function getCzpAndOtherTokenPoolAddr(
        IUniswapV3Factory _factoryContract,
        address _czpContractAddr,
        address _otherTokenContractAddr,
        uint24 _poolFee
    ) public view returns (address poolAddr) {
        return
            _factoryContract.getPool(
                _czpContractAddr,
                _otherTokenContractAddr,
                _poolFee
            );
    }

    /**
    @notice Calculates the equivalent $CZP from other token in pool
    @notice Cannot be used for pools other than those that have CZP
    @param _poolWithCzpAndOtherTokenAddr Address of the pool to use for query
    @param _czpContractAddr Address of the CZP contract
    @param _otherTokenContractAddr Address of the other token contract
    @param _secondsAgo Last n seconds interval to use for time-weighted calculation
    @param _otherTokenAmt Other token amount to get equivalent CZP for
    @return czpAmt Equivalent CZP amount
     */
    function calculateCzpFromOtherToken(
        address _poolWithCzpAndOtherTokenAddr,
        address _czpContractAddr,
        address _otherTokenContractAddr,
        uint32 _secondsAgo,
        uint128 _otherTokenAmt
    ) public view returns (uint256 czpAmt) {
        // Verify that the pool consists of CZP
        IUniswapV3Pool pool = IUniswapV3Pool(_poolWithCzpAndOtherTokenAddr);
        require(
            pool.token0() == _czpContractAddr ||
                pool.token1() == _czpContractAddr,
            "NOT A CZP POOL"
        );

        (int24 tick, ) = OracleLibrary.consult(
            _poolWithCzpAndOtherTokenAddr,
            _secondsAgo
        );
        return
            OracleLibrary.getQuoteAtTick(
                tick,
                _otherTokenAmt,
                _otherTokenContractAddr,
                _czpContractAddr
            );
    }

    /**
    @notice Calculates the equivalent other token from CZP in pool
    @notice Cannot be used for pools other than those that have CZP
    @param _poolWithCzpAndOtherTokenAddr Address of the pool to use for query
    @param _czpContractAddr Address of the CZP contract
    @param _otherTokenContractAddr Address of the other token contract
    @param _secondsAgo Last n seconds interval to use for time-weighted calculation
    @param _czpAmt CZP amount to get equivalent other token for
    @return otherTokenAmt Equivalent CZP amount
     */
    function calculateOtherTokenFromCzp(
        address _poolWithCzpAndOtherTokenAddr,
        address _czpContractAddr,
        address _otherTokenContractAddr,
        uint32 _secondsAgo,
        uint128 _czpAmt
    ) public view returns (uint256 otherTokenAmt) {
        // Verify that the pool consists of CZP
        IUniswapV3Pool pool = IUniswapV3Pool(_poolWithCzpAndOtherTokenAddr);
        require(
            pool.token0() == _czpContractAddr ||
                pool.token1() == _czpContractAddr,
            "NOT A CZP POOL"
        );

        (int24 tick, ) = OracleLibrary.consult(
            _poolWithCzpAndOtherTokenAddr,
            _secondsAgo
        );
        return
            OracleLibrary.getQuoteAtTick(
                tick,
                _czpAmt,
                _czpContractAddr,
                _otherTokenContractAddr
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

library LiquidityManager {
    ////////////////////
    // MODIFIERS
    ////////////////////

    /**
    @dev Checks if the caller owns the position
     */
    modifier mustOwnPosition(
        INonfungiblePositionManager _positionManager,
        uint256 _tokenId
    ) {
        require(
            _positionManager.ownerOf(_tokenId) == msg.sender,
            "POSITION NOT OWNED"
        );
        _;
    }

    /////////////////////
    // STRUCTS
    /////////////////////

    /**
    @param _positionManager Nonfungible Position Manager
    @param _czpContractAddr Address of the CZP contract
    @param _otherTokenContractAddr Address of the other token contract
    @param _czpAmtToDeposit Amount of CZP token to deposit in the position
    @param _otherTokenAmtToDeposit Amount of the other token to deposit in the position
    @param _poolFee Swap fees for this position
    @param _tickLower Lower tick for concentrated liquidity range
    @param _tickUpper Upper tick for concentrated liquidity range
    @param _minCzpAmtToDeposit Minimum CZP to deposit
    @param _minOtherTokenAmtToDeposit Minimum other token to deposit
    @param _deadline Deadline (Unix secs) to execute this transaction
     */
    struct MintNewPositionInCzpAndOtherTokenPoolParams {
        INonfungiblePositionManager _positionManager;
        address _czpContractAddr;
        address _otherTokenContractAddr;
        uint256 _czpAmtToDeposit;
        uint256 _otherTokenAmtToDeposit;
        uint24 _poolFee;
        int24 _tickLower;
        int24 _tickUpper;
        uint8 _minCzpAmtToDeposit;
        uint8 _minOtherTokenAmtToDeposit;
        uint256 _deadline;
    }

    /**
    @param _positionManager Nonfungible Position Manager
    @param _czpContractAddr Address of the CZP contract
    @param _otherTokenContractAddr Address of the other token contract
    @param _tokenId Token id of the position's NFT
    @param _czpAmtToAdd Amount of CZP token to add in the position
    @param _otherTokenAmtToAdd Amount of the other token to add in the position
    @param _minCzpAmtToAdd Minimum CZP to add
    @param _minOtherTokenAmtToAdd Minimum other token to add
    @param _deadline Deadline (unix secs) to execute this transaction
     */
    struct AddLiquidityToCzpAndOtherTokenPositionParams {
        INonfungiblePositionManager _positionManager;
        address _czpContractAddr;
        address _otherTokenContractAddr;
        uint256 _tokenId;
        uint256 _czpAmtToAdd;
        uint256 _otherTokenAmtToAdd;
        uint256 _minCzpAmtToAdd;
        uint256 _minOtherTokenAmtToAdd;
        uint256 _deadline;
    }

    /**
    @param _positionManager Nonfungible Position Manager
    @param _tokenId Token id of the position's NFT
    @param _remainingLiquidity Liquidity that should remain after withdrawing
    @param _minCzpToWithdraw Minimum CZP to withdraw
    @param _minOtherTokenToWithdraw Minimum other tokens to withdraw
    @param _deadline Deadline (unix secs) to execute this transaction
     */
    struct RemoveLiquidityToCzpAndOtherTokenPosition {
        INonfungiblePositionManager _positionManager;
        uint256 _tokenId;
        uint128 _remainingLiquidity;
        uint256 _minCzpToWithdraw;
        uint256 _minOtherTokenToWithdraw;
        uint256 _deadline;
    }

    ////////////////////////
    // FUNCTIONS
    ////////////////////////

    /**
    @notice Mints a new position in a CZP-OtherToken pool
    @notice Contract must be approved to transfer the specified tokens BEFORE calling this
    @notice Mints the Position NFT to the caller
    @notice Remaning tokens are refunded to the caller
    @return tokenId Token id of the new position NFT
    @return liquidity Liquidity that was deposited
    @return czpDeposited Amount of CZP that was deposited
    @return otherTokenDeposited Amount of other token that was deposited
     */
    function mintNewPositionInCzpAndOtherTokenPool(
        MintNewPositionInCzpAndOtherTokenPoolParams memory _mintParams
    )
        public
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 czpDeposited,
            uint256 otherTokenDeposited
        )
    {
        // Transfer tokens to this contract, and approve position manager to spend them
        TransferHelper.safeTransferFrom(
            _mintParams._czpContractAddr,
            msg.sender,
            address(this),
            _mintParams._czpAmtToDeposit
        );
        TransferHelper.safeTransferFrom(
            _mintParams._otherTokenContractAddr,
            msg.sender,
            address(this),
            _mintParams._otherTokenAmtToDeposit
        );

        TransferHelper.safeApprove(
            _mintParams._czpContractAddr,
            address(_mintParams._positionManager),
            _mintParams._czpAmtToDeposit
        );
        TransferHelper.safeApprove(
            _mintParams._otherTokenContractAddr,
            address(_mintParams._positionManager),
            _mintParams._otherTokenAmtToDeposit
        );

        // Mint new position
        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: _mintParams._czpContractAddr,
                token1: _mintParams._otherTokenContractAddr,
                fee: _mintParams._poolFee,
                tickLower: _mintParams._tickLower,
                tickUpper: _mintParams._tickUpper,
                amount0Desired: _mintParams._czpAmtToDeposit,
                amount1Desired: _mintParams._otherTokenAmtToDeposit,
                amount0Min: _mintParams._minCzpAmtToDeposit,
                amount1Min: _mintParams._minOtherTokenAmtToDeposit,
                recipient: msg.sender,
                deadline: _mintParams._deadline
            });

        (tokenId, liquidity, czpDeposited, otherTokenDeposited) = _mintParams
            ._positionManager
            .mint(params);

        // Refund the caller with any remaining tokens
        if (czpDeposited < _mintParams._czpAmtToDeposit) {
            TransferHelper.safeApprove(
                _mintParams._czpContractAddr,
                address(_mintParams._positionManager),
                0
            );
            uint256 czpRefund = _mintParams._czpAmtToDeposit - czpDeposited;
            TransferHelper.safeTransfer(
                _mintParams._czpContractAddr,
                msg.sender,
                czpRefund
            );
        }

        if (otherTokenDeposited < _mintParams._otherTokenAmtToDeposit) {
            TransferHelper.safeApprove(
                _mintParams._otherTokenContractAddr,
                address(_mintParams._positionManager),
                0
            );
            uint256 otherTokenRefund = _mintParams._otherTokenAmtToDeposit -
                otherTokenDeposited;
            TransferHelper.safeTransfer(
                _mintParams._otherTokenContractAddr,
                msg.sender,
                otherTokenRefund
            );
        }
    }

    /**
    @notice Adds liquidity to an owned position in a CZP-OtherToken pool
    @notice Contract must be approved to transfer the specified tokens BEFORE calling this
    @notice Remaining tokens are refunded to the caller
    @return liquidity Liquidity added to the position
    @return czpAdded Amount of CZP that could be added
    @return otherTokenAdded Amount of other token that could be added
     */
    function addLiquidityToCzpAndOtherTokenPosition(
        AddLiquidityToCzpAndOtherTokenPositionParams memory _addLiquidityParams
    )
        public
        mustOwnPosition(
            _addLiquidityParams._positionManager,
            _addLiquidityParams._tokenId
        )
        returns (
            uint128 liquidity,
            uint256 czpAdded,
            uint256 otherTokenAdded
        )
    {
        // Transfer tokens to this contract, and approve position manager to spend them
        TransferHelper.safeTransferFrom(
            _addLiquidityParams._czpContractAddr,
            msg.sender,
            address(this),
            _addLiquidityParams._czpAmtToAdd
        );
        TransferHelper.safeTransferFrom(
            _addLiquidityParams._otherTokenContractAddr,
            msg.sender,
            address(this),
            _addLiquidityParams._otherTokenAmtToAdd
        );

        TransferHelper.safeApprove(
            _addLiquidityParams._czpContractAddr,
            address(_addLiquidityParams._positionManager),
            _addLiquidityParams._czpAmtToAdd
        );
        TransferHelper.safeApprove(
            _addLiquidityParams._otherTokenContractAddr,
            address(_addLiquidityParams._positionManager),
            _addLiquidityParams._otherTokenAmtToAdd
        );

        // Provide the liquidity (2 tokens)
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: _addLiquidityParams._tokenId,
                    amount0Desired: _addLiquidityParams._czpAmtToAdd,
                    amount1Desired: _addLiquidityParams._otherTokenAmtToAdd,
                    amount0Min: _addLiquidityParams._minCzpAmtToAdd,
                    amount1Min: _addLiquidityParams._minOtherTokenAmtToAdd,
                    deadline: _addLiquidityParams._deadline
                });

        (liquidity, czpAdded, otherTokenAdded) = _addLiquidityParams
            ._positionManager
            .increaseLiquidity(params);

        // Refund the caller with any remaining tokens
        if (czpAdded < _addLiquidityParams._czpAmtToAdd) {
            TransferHelper.safeApprove(
                _addLiquidityParams._czpContractAddr,
                address(_addLiquidityParams._positionManager),
                0
            );
            uint256 czpRefund = _addLiquidityParams._czpAmtToAdd - czpAdded;
            TransferHelper.safeTransfer(
                _addLiquidityParams._czpContractAddr,
                msg.sender,
                czpRefund
            );
        }

        if (otherTokenAdded < _addLiquidityParams._minOtherTokenAmtToAdd) {
            TransferHelper.safeApprove(
                _addLiquidityParams._otherTokenContractAddr,
                address(_addLiquidityParams._positionManager),
                0
            );
            uint256 otherTokenRefund = _addLiquidityParams
                ._minOtherTokenAmtToAdd - otherTokenAdded;
            TransferHelper.safeTransfer(
                _addLiquidityParams._otherTokenContractAddr,
                msg.sender,
                otherTokenRefund
            );
        }
    }

    /**
    @notice Removes some liquidity from a position in a CZP-other token pool, and transfers tokens to position owner
    @return czpAmtWithdrawn Amount of CZP that could be withdrawn
    @return otherTokenAmtWithdrawn Amount of other token that could be withdrawn
     */
    function removeLiquidityToCzpAndOtherTokenPosition(
        RemoveLiquidityToCzpAndOtherTokenPosition memory _removeLiquidityParams
    )
        public
        mustOwnPosition(
            _removeLiquidityParams._positionManager,
            _removeLiquidityParams._tokenId
        )
        returns (uint256 czpAmtWithdrawn, uint256 otherTokenAmtWithdrawn)
    {
        // Decrease liquidity
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: _removeLiquidityParams._tokenId,
                    liquidity: _removeLiquidityParams._remainingLiquidity,
                    amount0Min: _removeLiquidityParams._minCzpToWithdraw,
                    amount1Min: _removeLiquidityParams._minOtherTokenToWithdraw,
                    deadline: _removeLiquidityParams._deadline
                });

        (czpAmtWithdrawn, otherTokenAmtWithdrawn) = _removeLiquidityParams
            ._positionManager
            .decreaseLiquidity(params);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../../CazzPayToken/CazzPayToken.sol";

library SwapManager {
    ////////////////////////
    // STRUCTS
    ////////////////////////

    /**
    @param _swapRouter Swap router
    @param  _czpContractAddr CZP contract address
    @param _otherTokenContractAddr Other token contract address
    @param _otherTokenAmtToPay Amount of other tokens to pay with
    @param _fiatToPay Amount of FIAT to pay with (atomic units, decimals: 18); Note: CZP:FIAT = 1:1 (stable)
    @param _poolFee Pool fees of the pool to be used
    @param _deadline Deadline (unix secs) to execute this transaction
     */
    struct BuyWithOtherTokenParams {
        ISwapRouter _swapRouter;
        address _czpContractAddr;
        address _otherTokenContractAddr;
        uint256 _otherTokenAmtToPay;
        uint256 _otherTokenMaxAmtToPay;
        uint256 _fiatToPay;
        uint24 _poolFee;
        uint256 _deadline;
    }

    /**
    @param _swapRouter Swap router
    @param _inputTokenContractAddr Input token contract's address 
    @param _outputTokenContractAddr Output token contract's address
    @param _poolFee Pool fees
    @param _inputTokenAmt Exact amount of input tokens to use
    @param _outputTokenAmtMin Minimum amount of output tokens desired
    @param _deadline Deadline (unix secs) for this transaction to execute
     */
    struct SwapExactInputForOutputParams {
        ISwapRouter _swapRouter;
        address _inputTokenContractAddr;
        address _outputTokenContractAddr;
        uint24 _poolFee;
        uint256 _inputTokenAmt;
        uint256 _outputTokenAmtMin;
        uint256 _deadline;
    }

    /**
    @param _swapRouter Swap router
    @param _inputTokenContractAddr Input token contract's address 
    @param _outputTokenContractAddr Output token contract's address
    @param _poolFee Pool fees
    @param _outputTokenAmt Exact amount of output tokens desired
    @param _inputTokenAmtMax Maximum amount of input tokens to swap
    @param _deadline Deadline (unix secs) for this transaction to execute
     */
    struct SwapInputForExactOutputParams {
        ISwapRouter _swapRouter;
        address _inputTokenContractAddr;
        address _outputTokenContractAddr;
        uint24 _poolFee;
        uint256 _outputTokenAmt;
        uint256 _inputTokenAmtMax;
        uint256 _deadline;
    }

    ////////////////////////
    // FUNCTIONS
    ////////////////////////

    /**
    @notice This is to be called by buyer when purchasing.
    @notice Buyer must approve this contract to operate the appropriate amount of input tokens
    @dev This swaps input tokens for exact output (CZP) tokens, and burns the CZP tokens, to mimic FIAT transfer to seller
    @dev To get amount of other token, use `calculateOtherTokenFromCzp()`
     */
    function buyWithOtherToken(BuyWithOtherTokenParams memory _params)
        public
        returns (uint256 otherTokenAmtUsedForTransaction)
    {
        // Transfer input tokens to this contract, and approve SwapRouter to operate them
        TransferHelper.safeTransferFrom(
            _params._otherTokenContractAddr,
            msg.sender,
            address(this),
            _params._otherTokenMaxAmtToPay
        );
        TransferHelper.safeApprove(
            _params._otherTokenContractAddr,
            address(_params._swapRouter),
            _params._otherTokenMaxAmtToPay
        );

        // Swap other tokens for CZP to this contract
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: _params._otherTokenContractAddr,
                tokenOut: _params._czpContractAddr,
                fee: _params._poolFee,
                recipient: address(this),
                deadline: _params._deadline,
                amountOut: _params._fiatToPay,
                amountInMaximum: _params._otherTokenMaxAmtToPay,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        otherTokenAmtUsedForTransaction = _params._swapRouter.exactOutputSingle(
                params
            );

        // Burn CZP, to mimic FIAT transfer
        CazzPayToken(_params._czpContractAddr).burn(_params._fiatToPay);

        // Refund remaining other tokens
        if (_params._otherTokenMaxAmtToPay > otherTokenAmtUsedForTransaction) {
            uint256 otherTokenRefundAmt = _params._otherTokenMaxAmtToPay -
                otherTokenAmtUsedForTransaction;
            TransferHelper.safeApprove(
                _params._otherTokenContractAddr,
                address(_params._swapRouter),
                0
            );
            TransferHelper.safeTransfer(
                _params._otherTokenContractAddr,
                msg.sender,
                otherTokenRefundAmt
            );
        }
    }

    /**
    @notice Swaps an exact amount of input tokens for max output tokens
    @notice Caller should approve contract to transfer input tokens BEFORE calling this
    @return amountOut Amount of output tokens received
     */
    function swapExactInputForOutput(
        SwapExactInputForOutputParams memory _params
    ) public returns (uint256 amountOut) {
        // Transfer the specified amount of DAI to this contract, and approve Router
        TransferHelper.safeTransferFrom(
            _params._inputTokenContractAddr,
            msg.sender,
            address(this),
            _params._inputTokenAmt
        );

        TransferHelper.safeApprove(
            _params._inputTokenContractAddr,
            address(_params._swapRouter),
            _params._inputTokenAmt
        );

        // Perform swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _params._inputTokenContractAddr,
                tokenOut: _params._outputTokenContractAddr,
                fee: _params._poolFee,
                recipient: msg.sender,
                deadline: _params._deadline,
                amountIn: _params._inputTokenAmt,
                amountOutMinimum: _params._outputTokenAmtMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = _params._swapRouter.exactInputSingle(params);
    }

    /**
    @notice Swaps max amount of input tokens for exact amount of output tokens
    @notice Caller should approve contract to transfer input tokens BEFORE calling this
    @notice Caller would be refunded any unused input tokens
    @return amountIn Amount of input tokens used
     */
    function swapInputForExactOutput(
        SwapInputForExactOutputParams memory _params
    ) public returns (uint256 amountIn) {
        // Transfer the specified amount of DAI to this contract, and approve Router
        TransferHelper.safeTransferFrom(
            _params._inputTokenContractAddr,
            msg.sender,
            address(this),
            _params._inputTokenAmtMax
        );

        TransferHelper.safeApprove(
            _params._inputTokenContractAddr,
            address(_params._swapRouter),
            _params._inputTokenAmtMax
        );

        // Perform swap
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: _params._inputTokenContractAddr,
                tokenOut: _params._outputTokenContractAddr,
                fee: _params._poolFee,
                recipient: msg.sender,
                deadline: _params._deadline,
                amountOut: _params._outputTokenAmt,
                amountInMaximum: _params._inputTokenAmtMax,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = _params._swapRouter.exactOutputSingle(params);

        // Refunds remaining input tokens
        if (amountIn < _params._inputTokenAmtMax) {
            uint256 refund = _params._inputTokenAmtMax - amountIn;
            TransferHelper.safeApprove(
                _params._inputTokenContractAddr,
                address(_params._swapRouter),
                0
            );
            TransferHelper.safeTransfer(
                _params._inputTokenContractAddr,
                msg.sender,
                refund
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) =
            IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta =
            secondsPerLiquidityCumulativeX128s[1] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) =
            IUniswapV3Pool(pool).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        secondsAgo = uint32(block.timestamp) - observationTimestamp;
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (uint32 observationTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, ) =
            IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - prevTickCumulative) / delta);
        uint128 liquidity =
            uint128(
                (uint192(delta) * type(uint160).max) /
                    (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
            );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(weightedTickData[i].weight);
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, 'DL');
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i] ? syntheticTick += ticks[i - 1] : syntheticTick -= ticks[i - 1];
        }
    }
}

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.7.6;

// a library for performing various math operations

// Taken from https://github.com/Uniswap/v2-core/blob/v1.0.1/contracts/libraries/Math.sol

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
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
pragma solidity >=0.5.0;

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
    function protocolFees() external view returns (uint128 token0, uint128 token1);

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
    function ticks(int24 tick)
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
    function positions(bytes32 key)
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
    function observations(uint256 index)
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
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
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
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

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
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

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
        uint256 twos = -denominator & denominator;
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

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

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
        require(absTick <= uint256(MAX_TICK), 'T');

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
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
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
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../Ownable/MultiOwnable.sol";

contract CazzPayToken is MultiOwnable, ERC20Burnable {
    // @title Constructor
    // @param _initialAmtToMint Initial amount of tokens to mint
    constructor(uint256 _initialAmtToMint) ERC20("CazzPayToken", "CZP") {
        _mint(msg.sender, _initialAmtToMint);
    }

    // @notice Mints specified amount of $CZP to an address
    // @notice Only callable by an owner
    // @dev MAKE SURE TO CALL THIS ALONG WITH FIAT TRANSFER
    // @param _mintTo Address to mint to
    // @param _amtToMint Amount of tokens to mint
    function mintTokens(address _mintTo, uint256 _amtToMint) public onlyOwner {
        _mint(_mintTo, _amtToMint);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract MultiOwnable {
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    // Stores array of owners
    EnumerableSet.AddressSet private _owners;

    // Modifier
    modifier onlyOwner() {
        require(_owners.contains(msg.sender), "NOT OWNER");
        _;
    }

    // Constructor
    constructor() {
        _owners.add(msg.sender);
    }

    // @notice Adds an owner
    // @notice Only callable by an existing owner
    // @param _newOwner Address of the new owner
    function addOwner(address _newOwner) external onlyOwner {
        _addOwner(_newOwner);
    }

    // @notice Removes an owner
    // @notice Only callable by an existing owner
    // @param _ownerToRemove Address of the new owner
    function removeOwner(address _ownerToRemove) external onlyOwner {
        _removeOwner(_ownerToRemove);
    }

    // @notice Checks to see if an address is an owner
    // @param _ownerToVerify Address of the owner to verify
    // @returns True, if the address is an owner, else false
    function isOwner(address _ownerToVerify) public view returns (bool) {
        return _owners.contains(_ownerToVerify);
    }

    /////////////////////////////
    // Internal mirror functions
    /////////////////////////////

    function _addOwner(address _newOwner) internal {
        _owners.add(_newOwner);
    }

    function _removeOwner(address _ownerToRemove) internal {
        _owners.remove(_ownerToRemove);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}