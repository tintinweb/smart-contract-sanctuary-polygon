// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17 <0.9.0;

/** 
Optimal MEV router contract for layer 2s (IUniswapV2Router compatible)

For the User it aims to offer:
  1. Better order routing for minimal slippage
  2. At source MEV
  3. Lower gas costs for swaps and liquidity changes

For the Liquidity providers:
  1. Inclusive rewards
  2. Reduced impermanent loss

For the Exchange providers:
  1. Inclusive rewards
  2. Increased adoption

For the Ethereum environment:
  1. Reduced MEV attacks and fee spikes
  2. Healthy growth in MEV space with inclusive incentives

Version 1 MEV Strategies
  - cross-dex backruns for swaps
  - reduced slippage fallback router 

The contract leverages and depends on 2 external protocols:
  1. Uniswap V2 (or equivalent on another network) for backrun completion and fallback swaps
  2. Aave V3 for flashloan backruns that require more liquidity

Business logic
  - Profits from backruns are retained on the contract to improve efficiency (gas cost and profit) of future backruns
  - Contract should therefore be deployed or ownership transfered to a multisig address
  - Harvest function can be called from the multisig owners to distribute profits by consensus 

Resources
  - IUniswapV2Router: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
  - Contract size reduction techniques: https://ethereum.org/en/developers/tutorials/downsizing-contracts-to-fight-the-contract-size-limit/
  - Contract gas reduction techniques: https://gist.github.com/hrkrshnn/ee8fabd532058307229d65dcd5836ddc

Dev Notes
  - Normal sushiswap router functions. Swaps have 2 material changes:
      1) slippage fallback router (uniswap v2)
      2) backruns after user swap
  - For gas and size efficiency, requires are modified to reverts with custom errors
  - Factory hash is now passed to library functions because we are working with 2 factories
  - Other changes are trade-offs for reducing contract size and / or gas usage and stack too deep errors
*/

/// ============ Internal Imports ============
import { ERC20 } from "solmate/tokens/ERC20.sol";
import "./TwoStepOwnable.sol";
import "../interfaces/IWETH.sol";
import "./libraries/OpenMevLibraryL2.sol";
import { SafeTransferLib } from "./libraries/SafeTransferLib.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IBentoBox.sol";
import "../interfaces/IOpenMevRouter.sol";
import "../interfaces/IFlashLoanSimpleReceiver.sol";
import "../interfaces/IProtocolDataProvider.sol";

/// @title OpenMevRouterL2
/// @author Sandy Bradley <@sandybradley>, Sam Bacha <@sambacha>
/// @notice Optimal MEV router contract for layer 2s (IUniswapV2Router compatible)
contract OpenMevRouterL2 is IFlashLoanSimpleReceiver, TwoStepOwnable {
    using SafeTransferLib for ERC20;

    // Custom errors save gas, encoding to 4 bytes
    error Expired();
    error NoTokens();
    error NotPercent();
    error NoReceivers();
    error InvalidPath();
    error TransferFailed();
    error InsufficientBAmount();
    error InsufficientAAmount();
    error TokenIsFeeOnTransfer();
    error ExcessiveInputAmount();
    error ExecuteNotAuthorized();
    error InsufficientAllowance();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();

    event MEV(address indexed user, address indexed token, uint256 value);
    event LoanError(address indexed token, uint256 amountIn);

    address internal immutable WETH09; // native token e.g. avax, matic ...
    address internal constant LENDING_POOL_ADDRESS = 0x794a61358D6845594F94dc1DB02A252b5b4814aD; // aave v3 lending pool address
    address internal constant AAVE_DATA_PROVIDER = 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654;
    address internal constant SUSHI_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address internal immutable BACKUP_FACTORY; // uniswap v2 fork factory
    address internal immutable BENTO;
    bytes32 internal constant SUSHI_FACTORY_HASH = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    bytes32 internal immutable BACKUP_FACTORY_HASH;
    IBentoBoxV1 internal immutable bento; // BENTO vault contract
    mapping(address => bool) internal IS_AAVE_ASSET; // boolean address mapping for flagging aave assets

    /// @notice constructor arguments for cross-chain deployment
    /// @param weth wrapped native token address (e.g. Eth mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    /// @param bentoAddress BentoBox address
    /// @param backupFactory Uniswap V2 (or equiv.) (e.g. Eth mainnet: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
    /// @param backupFactoryHash Initial code hash of backup (uniV2) factory (e.g. Eth mainnet: 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f)SplitSwapRouter
    constructor(
        address weth,
        address bentoAddress,
        address backupFactory,
        bytes32 backupFactoryHash
    ) {
        WETH09 = weth;
        BENTO = bentoAddress;
        BACKUP_FACTORY = backupFactory;
        BACKUP_FACTORY_HASH = backupFactoryHash;        
        bento = IBentoBoxV1(bentoAddress);
        address[] memory aaveAssets = IPool(LENDING_POOL_ADDRESS).getReservesList();
        uint256 length = aaveAssets.length;
        for (uint256 i; i < length; i = _inc(i)) {
            address asset = aaveAssets[i];
            IS_AAVE_ASSET[asset] = true;
        }
    }

    /// @notice reference sushi factory address (IUniswapV2Router compliance)
    function factory() external pure returns (address) {
        return SUSHI_FACTORY;
    }

    /// @notice reference wrapped native token address (IUniswapV2Router compliance)
    function WETH() external view returns (address) {
        return WETH09;
    }

    /// @notice Ensures deadline is not passed, otherwise revert. (0 = no deadline)
    /// @dev Modifier has been replaced with a function for gas efficiency
    /// @param deadline Unix timestamp in seconds for transaction to execute before
    function ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert Expired();
    }

    /// @notice Checks amounts for token A and token B are balanced for pool. Creates a pair if none exists
    /// @dev Reverts with custom errors replace requires
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param amountADesired Amount of token A desired to add to pool
    /// @param amountBDesired Amount of token B desired to add to pool
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @return amountA exact amount of token A to be added
    /// @return amountB exact amount of token B to be added
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        address factory0 = SUSHI_FACTORY;
        if (IUniswapV2Factory(factory0).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory0).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = OpenMevLibraryL2.getReserves(
            factory0,
            tokenA,
            tokenB,
            SUSHI_FACTORY_HASH
        );
        if (_isZero(reserveA) && _isZero(reserveB)) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = OpenMevLibraryL2.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal > amountBDesired) {
                uint256 amountAOptimal = OpenMevLibraryL2.quote(amountBDesired, reserveB, reserveA);
                if (amountAOptimal > amountADesired) revert InsufficientAAmount();
                if (amountAOptimal < amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            } else {
                if (amountBOptimal < amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            }
        }
    }

    /// @notice Adds liquidity to an ERC-20⇄ERC-20 pool. msg.sender should have already given the router an allowance of at least amountADesired/amountBDesired on tokenA/tokenB
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param amountADesired Amount of token A desired to add to pool
    /// @param amountBDesired Amount of token B desired to add to pool
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive liquidity token
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountA exact amount of token A added to pool
    /// @return amountB exact amount of token B added to pool
    /// @return liquidity amount of liquidity token received
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        ensure(deadline);
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = OpenMevLibraryL2.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH);
        ERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        ERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /// @notice Adds liquidity to an ERC-20⇄WETH pool with ETH. msg.sender should have already given the router an allowance of at least amountTokenDesired on token. msg.value is treated as a amountETHDesired. Leftover ETH, if any, is returned to msg.sender
    /// @param token Token in pool
    /// @param amountTokenDesired Amount of token desired to add to pool
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive liquidity token
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountToken exact amount of token added to pool
    /// @return amountETH exact amount of ETH added to pool
    /// @return liquidity amount of liquidity token received
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        ensure(deadline);
        address weth = WETH09;
        (amountToken, amountETH) = _addLiquidity(
            token,
            weth,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = OpenMevLibraryL2.pairFor(SUSHI_FACTORY, token, weth, SUSHI_FACTORY_HASH);
        ERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
        IWETH(weth).deposit{ value: amountETH }();
        ERC20(weth).safeTransfer(pair, amountETH);
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) SafeTransferLib.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    /// **** REMOVE LIQUIDITY ****
    /// @notice Removes liquidity from an ERC-20⇄ERC-20 pool. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountA, uint256 amountB) {
        ensure(deadline);
        address pair = OpenMevLibraryL2.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH);
        ERC20(pair).safeTransferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = OpenMevLibraryL2.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    /// @notice Removes liquidity from an ERC-20⇄WETH pool and receive ETH. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountToken Amount of token received
    /// @return amountETH Amount of ETH received
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountToken, uint256 amountETH) {
        address weth = WETH09;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        (amountToken, amountETH) = removeLiquidity(
            token,
            weth,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // exploit check from fee-on-transfer tokens
        if (amountToken != ERC20(token).balanceOf(address(this)) - balanceBefore) revert TokenIsFeeOnTransfer();
        ERC20(token).safeTransfer(to, amountToken);
        IWETH(weth).withdraw(amountETH);
        SafeTransferLib.safeTransferETH(to, amountETH);
    }

    /// @notice Removes liquidity from an ERC-20⇄ERC-20 pool without pre-approval, thanks to permit.
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair(OpenMevLibraryL2.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /// @notice Removes liquidity from an ERC-20⇄WETTH pool and receive ETH without pre-approval, thanks to permit
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountToken Amount of token received
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountToken, uint256 amountETH) {
        IUniswapV2Pair(OpenMevLibraryL2.pairFor(SUSHI_FACTORY, token, WETH09, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /// @notice Identical to removeLiquidityETH, but succeeds for tokens that take a fee on transfer. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountETH) {
        address weth = WETH09;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        (, amountETH) = removeLiquidity(token, weth, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        ERC20(token).safeTransfer(to, ERC20(token).balanceOf(address(this)) - balanceBefore);
        IWETH(weth).withdraw(amountETH);
        SafeTransferLib.safeTransferETH(to, amountETH);
    }

    /// @notice Identical to removeLiquidityETHWithPermit, but succeeds for tokens that take a fee on transfer.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountETH) {
        IUniswapV2Pair(OpenMevLibraryL2.pairFor(SUSHI_FACTORY, token, WETH09, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    /// @notice Internal core swap. Requires the initial amount to have already been sent to the first pair.
    /// @param _to Address of receiver
    /// @param swaps Array of user swap data
    function _swap(address _to, OpenMevLibraryL2.Swap[] memory swaps)
        internal
        virtual
        returns (uint256[] memory amounts)
    {
        uint256 length = swaps.length;
        amounts = new uint256[](_inc(length));
        amounts[0] = swaps[0].amountIn;
        for (uint256 i; i < length; i = _inc(i)) {
            uint256 amountOut = swaps[i].amountOut;
            {
                (uint256 amount0Out, uint256 amount1Out) = swaps[i].isReverse
                    ? (amountOut, uint256(0))
                    : (uint256(0), amountOut);
                address to = i < _dec(length) ? swaps[_inc(i)].pair : _to;
                address pair = swaps[i].pair;
                _asmSwap(pair, amount0Out, amount1Out, to);
            }
            amounts[_inc(i)] = amountOut;
        }
    }

    /// @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path. The first element of path is the input token, the last is the output token, and any intermediate elements represent intermediate pairs to trade through. msg.sender should have already given the router an allowance of at least amountIn on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address factory0 = SUSHI_FACTORY;
        OpenMevLibraryL2.Swap[] memory swaps = OpenMevLibraryL2.getSwapsOut(
            factory0,
            SUSHI_FACTORY_HASH,
            amountIn,
            path
        );
        uint256 length = swaps.length;
        if (swaps[_dec(length)].amountOut < amountOutMin) {
            // Change 1 -> fallback for insufficient output amount, check backup router
            factory0 = BACKUP_FACTORY;
            swaps = OpenMevLibraryL2.getSwapsOut(factory0, BACKUP_FACTORY_HASH, amountIn, path);
            if (swaps[_dec(length)].amountOut < amountOutMin) revert InsufficientOutputAmount();
        }
        ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair, amountIn);
        amounts = _swap(to, swaps);
        // Change 2 -> back-run swaps
        _backrunSwaps(factory0, swaps);
    }

    /// @notice Receive an exact amount of output tokens for as few input tokens as possible, along the route determined by the path. msg.sender should have already given the router an allowance of at least amountInMax on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of output tokens to receive
    /// @param amountInMax Maximum amount of input tokens
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address factory0 = SUSHI_FACTORY;
        OpenMevLibraryL2.Swap[] memory swaps = OpenMevLibraryL2.getSwapsIn(
            factory0,
            SUSHI_FACTORY_HASH,
            amountOut,
            path
        );
        if (swaps[0].amountIn > amountInMax) {
            factory0 = BACKUP_FACTORY;
            // Change 1 -> fallback for insufficient output amount, check backup router
            swaps = OpenMevLibraryL2.getSwapsIn(factory0, BACKUP_FACTORY_HASH, amountOut, path);
            if (swaps[0].amountIn > amountInMax) revert ExcessiveInputAmount();
        }

        ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair, swaps[0].amountIn);
        amounts = _swap(to, swaps);
        // Change 2 -> back-run swaps
        _backrunSwaps(factory0, swaps);
    }

    /// @notice Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the path. The first element of path must be WETH, the last is the output token. amountIn = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        address factory0 = SUSHI_FACTORY;
        OpenMevLibraryL2.Swap[] memory swaps = OpenMevLibraryL2.getSwapsOut(
            factory0,
            SUSHI_FACTORY_HASH,
            msg.value,
            path
        );
        uint256 length = swaps.length;
        if (swaps[_dec(length)].amountOut < amountOutMin) {
            factory0 = BACKUP_FACTORY;
            // Change 1 -> fallback for insufficient output amount, check backup router
            swaps = OpenMevLibraryL2.getSwapsOut(factory0, BACKUP_FACTORY_HASH, msg.value, path);
            if (swaps[_dec(length)].amountOut < amountOutMin) revert InsufficientOutputAmount();
        }

        IWETH(weth).deposit{ value: msg.value }();
        ERC20(weth).safeTransfer(swaps[0].pair, swaps[0].amountIn);
        amounts = _swap(to, swaps);

        // Change 2 -> back-run swaps
        _backrunSwaps(factory0, swaps);
    }

    /// @notice Receive an exact amount of ETH for as few input tokens as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH. msg.sender should have already given the router an allowance of at least amountInMax on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of ETH to receive
    /// @param amountInMax Maximum amount of input tokens
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        address factory0 = SUSHI_FACTORY;
        OpenMevLibraryL2.Swap[] memory swaps = OpenMevLibraryL2.getSwapsIn(
            factory0,
            SUSHI_FACTORY_HASH,
            amountOut,
            path
        );
        if (swaps[0].amountIn > amountInMax) {
            factory0 = BACKUP_FACTORY;
            // Change 1 -> fallback for insufficient output amount, check backup router
            swaps = OpenMevLibraryL2.getSwapsIn(factory0, BACKUP_FACTORY_HASH, amountOut, path);
            if (swaps[0].amountIn > amountInMax) revert ExcessiveInputAmount();
        }

        ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair, swaps[0].amountIn);
        amounts = _swap(address(this), swaps);
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);

        // Change 2 -> back-run swaps
        _backrunSwaps(factory0, swaps);
    }

    /// @notice Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of ETH that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        address factory0 = SUSHI_FACTORY;
        OpenMevLibraryL2.Swap[] memory swaps = OpenMevLibraryL2.getSwapsOut(
            factory0,
            SUSHI_FACTORY_HASH,
            amountIn,
            path
        );
        uint256 length = swaps.length;
        if (swaps[_dec(length)].amountOut < amountOutMin) {
            factory0 = BACKUP_FACTORY;
            // Change 1 -> fallback for insufficient output amount, check backup router
            swaps = OpenMevLibraryL2.getSwapsOut(factory0, BACKUP_FACTORY_HASH, amountIn, path);
            if (swaps[_dec(length)].amountOut < amountOutMin) revert InsufficientOutputAmount();
        }

        ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair, amountIn);
        amounts = _swap(address(this), swaps);
        uint256 amountOut = swaps[_dec(length)].amountOut;
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);
        // Change 2 -> back-run swaps
        _backrunSwaps(factory0, swaps);
    }

    /// @notice Receive an exact amount of tokens for as little ETH as possible, along the route determined by the path. The first element of path must be WETH. Leftover ETH, if any, is returned to msg.sender. amountInMax = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        address factory0 = SUSHI_FACTORY;
        OpenMevLibraryL2.Swap[] memory swaps = OpenMevLibraryL2.getSwapsIn(
            factory0,
            SUSHI_FACTORY_HASH,
            amountOut,
            path
        );
        if (swaps[0].amountIn > msg.value) {
            factory0 = BACKUP_FACTORY;
            // Change 1 -> fallback for insufficient output amount, check backup router
            swaps = OpenMevLibraryL2.getSwapsIn(factory0, BACKUP_FACTORY_HASH, amountOut, path);
            if (swaps[0].amountIn > msg.value) revert ExcessiveInputAmount();
        }

        IWETH(weth).deposit{ value: swaps[0].amountIn }();
        ERC20(weth).safeTransfer(swaps[0].pair, swaps[0].amountIn);
        amounts = _swap(to, swaps);
        // refund dust eth, if any
        if (msg.value > swaps[0].amountIn) SafeTransferLib.safeTransferETH(msg.sender, msg.value - swaps[0].amountIn);

        // Change 2 -> back-run swaps
        _backrunSwaps(factory0, swaps);
    }

    //requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokensExecute(
        address pair,
        uint256 amountOutput,
        bool isReverse,
        address to
    ) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) = isReverse ? (amountOutput, uint256(0)) : (uint256(0), amountOutput);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        uint256 length = path.length;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (address tokenIn, address tokenOut) = (path[i], path[_inc(i)]);
            bool isReverse;
            address pair;
            {
                (address token0, address token1) = OpenMevLibraryL2.sortTokens(tokenIn, tokenOut);
                isReverse = tokenOut == token0;
                pair = OpenMevLibraryL2._asmPairFor(SUSHI_FACTORY, token0, token1, SUSHI_FACTORY_HASH);
            }
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                uint256 amountInput;
                (uint112 reserve0, uint112 reserve1) = IUniswapV2Pair(pair).getReserves();
                (uint112 reserveInput, uint112 reserveOutput) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
                amountInput = ERC20(tokenIn).balanceOf(pair) - reserveInput;
                amountOutput = OpenMevLibraryL2.getAmountOut(amountInput, reserveInput, reserveOutput);
            }

            address to = i < length - 2
                ? OpenMevLibraryL2.pairFor(SUSHI_FACTORY, tokenOut, path[i + 2], SUSHI_FACTORY_HASH)
                : _to;
            _swapSupportingFeeOnTransferTokensExecute(pair, amountOutput, isReverse, to);
        }
    }

    /// @notice Identical to swapExactTokensForTokens, but succeeds for tokens that take a fee on transfer. msg.sender should have already given the router an allowance of at least amountIn on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual {
        ensure(deadline);
        ERC20(path[0]).safeTransferFrom(
            msg.sender,
            OpenMevLibraryL2.pairFor(SUSHI_FACTORY, path[0], path[1], SUSHI_FACTORY_HASH),
            amountIn
        );
        uint256 balanceBefore = ERC20(path[_dec(path.length)]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (ERC20(path[_dec(path.length)]).balanceOf(to) - balanceBefore < amountOutMin)
            revert InsufficientOutputAmount();
    }

    /// @notice Identical to swapExactETHForTokens, but succeeds for tokens that take a fee on transfer. amountIn = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        uint256 amountIn = msg.value;
        IWETH(weth).deposit{ value: amountIn }();
        ERC20(weth).safeTransfer(
            OpenMevLibraryL2.pairFor(SUSHI_FACTORY, path[0], path[1], SUSHI_FACTORY_HASH),
            amountIn
        );
        uint256 balanceBefore = ERC20(path[_dec(path.length)]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (ERC20(path[_dec(path.length)]).balanceOf(to) - balanceBefore < amountOutMin)
            revert InsufficientOutputAmount();
    }

    /// @notice Identical to swapExactTokensForETH, but succeeds for tokens that take a fee on transfer.
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of ETH that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        ERC20(path[0]).safeTransferFrom(
            msg.sender,
            OpenMevLibraryL2.pairFor(SUSHI_FACTORY, path[0], path[1], SUSHI_FACTORY_HASH),
            amountIn
        );
        uint256 balanceBefore = ERC20(weth).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = ERC20(weth).balanceOf(address(this)) - balanceBefore;
        if (amountOut < amountOutMin) revert InsufficientOutputAmount();
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);
    }

    /// @notice This function is used to calculate the amount of token B that can be exchanged for a given amount of token A.
    /// @param amountA input amount of TokenA to exchange
    /// @param reserveA reserve liquidity for TokenA in the pool
    /// @param reserveB reserve liquidity for TokenB in the pool
    /// @return amountB amount of TokenB returned after swap
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure virtual returns (uint256 amountB) {
        return OpenMevLibraryL2.quote(amountA, reserveA, reserveB);
    }

    /// @notice This function is used to calculate the amount of output given an amount of input, a reserve in, and a reserve out.
    /// @param amountIn input amount of TokenIn to exchange
    /// @param reserveIn reserve liquidity for TokenIn in the pool
    /// @param reserveOut reserve liquidity for TokenOut in the pool
    /// @return amountOut amount of TokenOut returned after swap
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure virtual returns (uint256 amountOut) {
        return OpenMevLibraryL2.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /// @notice This function is used to calculate the amount of input given an amount of output, a reserve in, and a reserve out.
    /// @param amountOut output amount of TokenOut to exchange
    /// @param reserveIn reserve liquidity for TokenIn in the pool
    /// @param reserveOut reserve liquidity for TokenOut in the pool
    /// @return amountIn amount of TokenIn required for swap
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure virtual returns (uint256 amountIn) {
        return OpenMevLibraryL2.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /// @notice Returns an array of uint256 amounts expected for given swap path and amount in
    /// @param amountIn input amount of TokenIn to exchange
    /// @param path array token path for swap
    /// @return amounts amounts array for each token in swap path
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return OpenMevLibraryL2.getAmountsOut(SUSHI_FACTORY, SUSHI_FACTORY_HASH, amountIn, path);
    }

    /// @dev This function is used to get the amounts in for a given path and amount out.
    /// @param amountOut The amount out in wei.
    /// @param path The path of addresses to get the amounts in for.
    /// @return amounts in for the given path and amount out.
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return OpenMevLibraryL2.getAmountsIn(SUSHI_FACTORY, SUSHI_FACTORY_HASH, amountOut, path);
    }

    /// @notice Internal call to back-run swaps i.e. extract natural MEV at source.
    /// @dev Executes after user swaps.
    /// @param factory0 Factory address of dex
    /// @param swaps Array of user swap data
    function _backrunSwaps(address factory0, OpenMevLibraryL2.Swap[] memory swaps) internal {
        uint256 length = swaps.length;
        for (uint256 i; i < length; i = _inc(i)) {
            if (!swaps[i].isBackrunnable) continue;
            (address input, address output) = (swaps[i].tokenIn, swaps[i].tokenOut);
            bool isAaveAsset = IS_AAVE_ASSET[output];
            uint256 contractAssetBalance = ERC20(output).balanceOf(address(this));
            uint256 bentoBalance = ERC20(output).balanceOf(BENTO);
            if (_isZero(contractAssetBalance) && !isAaveAsset && _isZero(bentoBalance)) continue;
            address factory1 = factory0 == SUSHI_FACTORY ? BACKUP_FACTORY : SUSHI_FACTORY;
            uint256 optimalAmount;
            uint256 optimalReturns;
            {
                address pair1 = address(IUniswapV2Factory(factory1).getPair(input, output));
                if (pair1 == address(0)) continue;
                (optimalAmount, optimalReturns) = OpenMevLibraryL2.getOptimalAmounts(
                    swaps[i].pair,
                    pair1,
                    swaps[i].isReverse,
                    isAaveAsset,
                    contractAssetBalance,
                    bentoBalance
                );
            }

            if (_isZero(optimalReturns)) continue;
            if (contractAssetBalance >= optimalAmount) {
                {
                    uint256 amountOut = _arb(factory0, factory1, input, output, address(this), optimalAmount);
                    if (amountOut < optimalAmount) revert InsufficientOutputAmount();
                }
                emit MEV(msg.sender, output, optimalReturns);
            } else if (optimalReturns > ((optimalAmount * 5) / 10000) && bentoBalance >= optimalAmount) {
                // kashi flashloan requires extra hurdle of interest @ 0.05% of loan value and sufficient balance
                _flashSwapKashi(factory0, factory1, input, output, optimalAmount, optimalReturns);
            } else if (
                optimalReturns > ((optimalAmount * 9) / 10000) &&
                ERC20(output).balanceOf(IProtocolDataProvider(AAVE_DATA_PROVIDER).getReserveTokensAddresses(output)) >
                optimalAmount
            ) {
                // aave flashloan requires extra hurdle of interest @ 0.09% of loan value (https://docs.aave.com/developers/guides/flash-loans)
                // check available liquidity for aave asset
                _flashSwap(factory0, factory1, input, output, optimalAmount, optimalReturns);
            }
        }
    }

    /// @notice Internal call to perform multiple swaps across multiple dexes with a BentoBox flashloan.
    /// @param factory0 Factory address for user swap
    /// @param factory1 Factory alternate address
    /// @param input Input address of token for user swap
    /// @param output Output address of token for user swap
    /// @param amountIn Optimal amount in for arbitrage
    /// @param optimalReturns Expected return
    function _flashSwapKashi(
        address factory0,
        address factory1,
        address input,
        address output,
        uint256 amountIn,
        uint256 optimalReturns
    ) internal {
        bytes memory params = _encode(factory0, factory1, input);
        // try / catch flashloan arb. In case arb reverts, user swap will still succeed.
        try bento.flashLoan(IFlashBorrower(address(this)), address(this), output, amountIn, params) {
            // success
            emit MEV(msg.sender, output, optimalReturns - ((amountIn * 5) / 10000));
        } catch {
            // fail flashloan
            emit LoanError(output, amountIn);
        }
    }

    /// @notice Called from BentoBox Lending pool after contract has received the flash loaned amount
    /// @dev Reverts if not profitable.
    /// @param sender Address of flashloan initiator
    /// @param token Token to loan
    /// @param amount Amount to loan
    /// @param fee Fee to repay on loan amount
    /// @param data Encoded factories and tokens
    function onFlashLoan(
        address sender,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external {
        if (msg.sender != BENTO) revert ExecuteNotAuthorized();
        uint256 amountOver;
        {
            (address factory0, address factory1, address input) = _decode(data);
            amountOver = _arb(factory0, factory1, input, token, sender, amount);
        }
        uint256 amountOwing = amount + fee;
        if (amountOver <= amountOwing) revert InsufficientOutputAmount();
        ERC20(token).safeTransfer(BENTO, amountOwing);
    }

    /// @notice Internal call to perform multiple swaps across multiple dexes with an Aave flashloan.
    /// @param factory0 Factory address for user swap
    /// @param factory1 Factory alternate address
    /// @param input Input address of token for user swap
    /// @param output Output address of token for user swap
    /// @param amountIn Optimal amount in for arbitrage
    /// @param optimalReturns Expected return
    function _flashSwap(
        address factory0,
        address factory1,
        address input,
        address output,
        uint256 amountIn,
        uint256 optimalReturns
    ) internal {
        // address of the contract receiving the funds
        address receiverAddress = address(this);
        // compress our 3 addresses
        bytes memory params = _encode(factory0, factory1, input);
        // try / catch flashloan arb. In case arb reverts, user swap will still succeed.
        try IPool(LENDING_POOL_ADDRESS).flashLoanSimple(receiverAddress, output, amountIn, params, uint16(0)) {
            // success
            emit MEV(msg.sender, output, optimalReturns - ((amountIn * 9) / 10000));
        } catch {
            // fail
            emit LoanError(output, amountIn);
        }
    }

    /// @notice Called from Aave Lending pool after contract has received the flash loaned amount (https://docs.aave.com/developers/v/2.0/guides/flash-loans)
    /// @dev Reverts if not profitable.
    /// @param asset Array of tokens to loan
    /// @param amount Array of amounts to loan
    /// @param premium Array of premiums to repay on loan amounts
    /// @param initiator Address of flashloan initiator
    /// @param params Encoded factories and tokens
    /// @return success indicating success
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        if (msg.sender != LENDING_POOL_ADDRESS) revert ExecuteNotAuthorized();
        uint256 amountOver;
        {
            (address factory0, address factory1, address input) = _decode(params);
            amountOver = _arb(factory0, factory1, input, asset, initiator, amount);
        }
        uint256 amountOwing = amount + premium;
        if (amountOver <= amountOwing) revert InsufficientOutputAmount();
        ERC20(asset).safeApprove(LENDING_POOL_ADDRESS, amountOwing);
        return true;
    }

    /// @notice Internal call to perform single swap
    /// @param pair Address of pair to swap in
    /// @param amount0Out AmountOut for token0 of pair
    /// @param amount1Out AmountOut for token1 of pair
    /// @param to Address of receiver
    function _asmSwap(
        address pair,
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal {
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, 0x022c0d9f00000000000000000000000000000000000000000000000000000000) // append 4 byte swap selector
            mstore(add(ptr, 0x04), amount0Out) // append amount0Out
            mstore(add(ptr, 0x24), amount1Out) // append amount1Out
            mstore(add(ptr, 0x44), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // append to
            mstore(add(ptr, 0x64), 0x80) // append location of byte list
            mstore(add(ptr, 0x84), 0) // append 0 bytes data
            let success := call(
                gas(), // gas remaining
                and(pair, 0xffffffffffffffffffffffffffffffffffffffff), // destination address
                0, // 0 value
                ptr, // input buffer
                0xA4, // input length
                0, // output buffer
                0 // output length
            )
        }
    }

    /// @notice Retreive factoryCodeHash from factory address
    /// @param factory0 Dex factory
    /// @return initCodeHash factory code hash for pair address calculation
    function _factoryHash(address factory0) internal view returns (bytes32 initCodeHash) {
        if (factory0 == SUSHI_FACTORY) {
            initCodeHash = SUSHI_FACTORY_HASH;
        } else {
            initCodeHash = BACKUP_FACTORY_HASH;
        }
    }

    /// @notice Internal call to perform single cross-dex state arbitrage
    /// @param factory0 Factory address for user swap
    /// @param factory1 Factory alternate address
    /// @param input Input address of token for user swap
    /// @param output Output address of token for user swap
    /// @param amountIn Optimal amount in for arbitrage
    /// @param to Address of receiver
    /// @return amountOut Amount of output token received
    function _arb(
        address factory0,
        address factory1,
        address input,
        address output,
        address to,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        // first swap output -> input (factory)
        address pair;
        bool isReverse;
        {
            (address token0, address token1) = OpenMevLibraryL2.sortTokens(output, input);
            pair = OpenMevLibraryL2._asmPairFor(factory0, token0, token1, _factoryHash(factory0));
            isReverse = output == token0;
        }

        {
            (uint112 reserveIn, uint112 reserveOut) = IUniswapV2Pair(pair).getReserves();
            (reserveIn, reserveOut) = isReverse ? (reserveIn, reserveOut) : (reserveOut, reserveIn);
            amountOut = OpenMevLibraryL2.getAmountOut(amountIn, reserveIn, reserveOut);
        }
        ERC20(output).safeTransfer(pair, amountIn);
        (uint256 amount0Out, uint256 amount1Out) = isReverse ? (uint256(0), amountOut) : (amountOut, uint256(0));
        _asmSwap(pair, amount0Out, amount1Out, to);

        // next swap input -> ouput (factory1)
        amountIn = amountOut;
        pair = OpenMevLibraryL2._asmPairFor(
            factory1,
            isReverse ? output : input,
            isReverse ? input : output,
            _factoryHash(factory1)
        );
        {
            (uint112 reserveIn, uint112 reserveOut) = IUniswapV2Pair(pair).getReserves();
            (reserveIn, reserveOut) = isReverse ? (reserveOut, reserveIn) : (reserveIn, reserveOut);
            amountOut = OpenMevLibraryL2.getAmountOut(amountIn, reserveIn, reserveOut);
        }

        ERC20(input).safeTransfer(pair, amountIn);
        (amount0Out, amount1Out) = isReverse ? (amountOut, uint256(0)) : (uint256(0), amountOut);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    /// @notice Multi-sig consensus call to distribute a given percentage of specified tokens to specified receivers.
    /// @param percentage Percentage of balance to distribute
    /// @param tokens Array of token addresses to distribute
    /// @param receivers Array of addresses for receiving distribution
    function harvest(
        uint256 percentage,
        address[] calldata tokens,
        address[] calldata receivers
    ) external payable onlyOwner {
        if (percentage > 100 || _isZero(percentage)) revert NotPercent();
        uint256 numReceivers = receivers.length;
        if (_isZero(numReceivers)) revert NoReceivers();
        uint256 numTokens = tokens.length;
        if (_isZero(numTokens)) revert NoTokens();
        uint256 balanceToDistribute;
        for (uint256 i; i < numTokens; i = _inc(i)) {
            address token = tokens[i];
            balanceToDistribute = (ERC20(token).balanceOf(address(this)) * percentage) / (100 * numReceivers);
            if (_isNonZero(balanceToDistribute)) {
                for (uint256 j; j < numReceivers; j = _inc(j)) {
                    ERC20(token).safeTransfer(receivers[j], balanceToDistribute);
                }
            }
        }
    }

    /// @notice Update internal Aave asset flag
    /// @param isActive Boolean flagging whether to use the asset for Aave flashloans
    /// @param asset Address of asset
    function updateAaveAsset(bool isActive, address asset) external payable onlyOwner {
        IS_AAVE_ASSET[asset] = isActive;
    }

    /// @notice Update all internal Aave assets
    function updateAllAaveAssets() external payable onlyOwner {
        address[] memory aaveAssets = IPool(LENDING_POOL_ADDRESS).getReservesList();
        uint256 length = aaveAssets.length;
        for (uint256 i; i < length; i = _inc(i)) {
            address asset = aaveAssets[i];
            IS_AAVE_ASSET[asset] = true;
        }
    }

    /// @notice Compresses 3 addresses into byte stream (len = 60)
    /// @param a Address of first param
    /// @param b Address of second param
    /// @param c Address of third param
    /// @return data Compressed byte stream
    function _encode(
        address a,
        address b,
        address c
    ) internal pure returns (bytes memory) {
        bytes memory data = new bytes(60);
        assembly ("memory-safe") {
            mstore(add(data, 32), shl(96, a))
            mstore(add(data, 52), shl(96, b))
            mstore(add(data, 72), shl(96, c))
        }
        return data;
    }

    /// @notice De-compresses 3 addresses from byte stream (len = 60)
    /// @param data Compressed byte stream
    /// @return a Address of first param
    /// @return b Address of second param
    /// @return c Address of third param
    function _decode(bytes memory data)
        internal
        pure
        returns (
            address a,
            address b,
            address c
        )
    {
        assembly ("memory-safe") {
            a := mload(add(data, 20))
            b := mload(add(data, 40))
            c := mload(add(data, 60))
        }
    }

    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @notice Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @notice Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17 <0.9.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */

abstract contract TwoStepOwnable {
    error Unauthorized();
    error ZeroAddress();

    address private _owner;

    address private _newPotentialOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor() {
        _owner = tx.origin;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    function _onlyOwner() private view {
        if (!isOwner()) revert Unauthorized();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        // require(isOwner(), "TwoStepOwnable: caller is not the owner.");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows a new account (`newOwner`) to accept ownership.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external payable onlyOwner {
        // require(
        //   newOwner != address(0),
        //   "TwoStepOwnable: new potential owner is the zero address."
        // );
        if (newOwner == address(0)) revert ZeroAddress();

        _newPotentialOwner = newOwner;
    }

    /**
     * @dev Cancel a transfer of ownership to a new account.
     * Can only be called by the current owner.
     */
    function cancelOwnershipTransfer() external payable onlyOwner {
        delete _newPotentialOwner;
    }

    /**
     * @dev Transfers ownership of the contract to the caller.
     * Can only be called by a new potential owner set by the current owner.
     */
    function acceptOwnership() external {
        // require(
        //   msg.sender == _newPotentialOwner,
        //   "TwoStepOwnable: current owner must set caller as new potential owner."
        // );
        if (msg.sender != _newPotentialOwner) revert Unauthorized();

        delete _newPotentialOwner;

        emit OwnershipTransferred(_owner, msg.sender);

        _owner = msg.sender;
    }
}

/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/** 
Optimal MEV library to support OpenMevRouter 
Based on UniswapV2Library: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
*/

import "../../interfaces/IUniswapV2Pair.sol";
import "./Uint512.sol";

/// @title OpenMevLibrary
/// @author Sandy Bradley <@sandybradley>, Sam Bacha <@sambacha>
/// @notice Optimal MEV library to support OpenMevRouter
library OpenMevLibraryL2 {
    error Overflow();
    error ZeroAmount();
    error InvalidPath();
    error ZeroAddress();
    error IdenticalAddresses();
    error InsufficientLiquidity();

    struct Swap {
        bool isReverse;
        bool isBackrunnable;
        address tokenIn;
        address tokenOut;
        address pair;
        uint256 amountIn;
        uint256 amountOut;
    }

    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @dev Require replaced with revert custom error
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return token0 First token in pool pair
    /// @return token1 Second token in pool pair
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        bool isZeroAddress;
        assembly ("memory-safe") {
            switch lt(shl(96, tokenA), shl(96, tokenB)) // sort tokens
            case 0 {
                token0 := tokenB
                token1 := tokenA
            }
            default {
                token0 := tokenA
                token1 := tokenB
            }
            isZeroAddress := iszero(token0)
        }
        if (isZeroAddress) revert ZeroAddress();
    }

    /// @notice Calculates the CREATE2 address for a pair without making any external calls
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @param factoryHash Init code hash for factory
    /// @return pair Pair pool address
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 factoryHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = _asmPairFor(factory, token0, token1, factoryHash);
    }

    /// @notice Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param token0 Pool token
    /// @param token1 Pool token
    /// @param factoryHash Init code hash for factory
    /// @return pair Pair pool address
    function _asmPairFor(
        address factory,
        address token0,
        address token1,
        bytes32 factoryHash
    ) internal pure returns (address pair) {
        // There is one contract for every combination of tokens,
        // which is deployed using CREATE2.
        // The derivation of this address is given by:
        //   address(keccak256(abi.encodePacked(
        //       bytes(0xFF),
        //       address(UNISWAP_FACTORY_ADDRESS),
        //       keccak256(abi.encodePacked(token0, token1)),
        //       bytes32(UNISWAP_PAIR_INIT_CODE_HASH),
        //   )));
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, shl(96, token0))
            mstore(add(ptr, 0x14), shl(96, token1))
            let salt := keccak256(ptr, 0x28) // keccak256(token0, token1)
            mstore(ptr, 0xFF00000000000000000000000000000000000000000000000000000000000000) // buffered 0xFF prefix
            mstore(add(ptr, 0x01), shl(96, factory)) // factory address prefixed
            mstore(add(ptr, 0x15), salt)
            mstore(add(ptr, 0x35), factoryHash) // factory init code hash
            pair := and(keccak256(ptr, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    /// @notice Fetches and sorts the reserves for a pair
    /// @param factory Factory address for dex
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @param factoryHash Init code hash for factory
    /// @return reserveA Reserves for tokenA
    /// @return reserveB Reserves for tokenB
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 factoryHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = IUniswapV2Pair(_asmPairFor(factory, token0, token1, factoryHash))
            .getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @notice Given some asset amount and reserves, returns an amount of the other asset representing equivalent value
    /// @dev Require replaced with revert custom error
    /// @param amountA Amount of token A
    /// @param reserveA Reserves for tokenA
    /// @param reserveB Reserves for tokenB
    /// @return amountB Amount of token B returned
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (_isZero(amountA)) revert ZeroAmount();
        if (_isZero(reserveA) || _isZero(reserveB)) revert InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @notice Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountIn Amount of token in
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountOut Amount of token out returned
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (_isZero(amountIn)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 amountInWithFee = amountIn * uint256(997);
            uint256 numerator = amountInWithFee * reserveOut;
            if (reserveOut != numerator / amountInWithFee) revert Overflow();
            uint256 denominator = (reserveIn * uint256(1000)) + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /// @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountOut Amount of token out wanted
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountIn Amount of token in required
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        if (_isZero(amountOut)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY || reserveOut <= amountOut)
            revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 numerator = reserveIn * amountOut * uint256(1000);
            if ((reserveIn * uint256(1000)) != numerator / amountOut) revert Overflow();
            uint256 denominator = (reserveOut - amountOut) * uint256(997);
            amountIn = (numerator / denominator) + 1;
        }
    }

    /// @notice Given an input asset amount and an array of token addresses, calculates all subsequent maximum output token amounts by calling getReserves for each pair of token addresses in the path in turn, and using these to call getAmountOut
    /// @dev Require replaced with revert custom error
    /// @param factory Factory address of dex
    /// @param factoryHash Init code hash for factory
    /// @param amountIn Amount of token in
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function getAmountsOut(
        address factory,
        bytes32 factoryHash,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint256[](length);
        amounts[0] = amountIn;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[_inc(i)], factoryHash);
            amounts[_inc(i)] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory Factory address for dex
    /// @param factoryHash Init code hash for factory
    /// @param amountIn Amount in for first token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsOut(
        address factory,
        bytes32 factoryHash,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        swaps[0].amountIn = amountIn;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (address tokenIn, address tokenOut) = (path[i], path[_inc(i)]);
            (address token0, address token1) = sortTokens(tokenIn, tokenOut);
            bool isReverse = tokenOut == token0;
            address pair = _asmPairFor(factory, token0, token1, factoryHash);
            swaps[i].isReverse = isReverse;
            swaps[i].tokenIn = tokenIn;
            swaps[i].tokenOut = tokenOut;
            swaps[i].pair = pair;
            uint112 reserveIn;
            uint112 reserveOut;
            {
                (uint112 reserve0, uint112 reserve1) = IUniswapV2Pair(pair).getReserves();
                (reserveIn, reserveOut) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
            }
            swaps[i].amountOut = getAmountOut(swaps[i].amountIn, reserveIn, reserveOut);
            unchecked {
                swaps[i].isBackrunnable = _isNonZero((1000 * swaps[i].amountIn) / reserveIn);
            }
            // assign next amount in as last amount out
            if (i < _dec(_dec(length))) swaps[_inc(i)].amountIn = swaps[i].amountOut;
        }
    }

    /// @notice Given an output asset amount and an array of token addresses, calculates all preceding minimum input token amounts by calling getReserves for each pair of token addresses in the path in turn, and using these to call getAmountIn
    /// @dev Require replaced with revert custom error
    /// @param factory Factory address of dex
    /// @param factoryHash Init code hash for factory
    /// @param amountOut Amount of token out wanted
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function getAmountsIn(
        address factory,
        bytes32 factoryHash,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint256[](length);
        amounts[_dec(length)] = amountOut;
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[_dec(i)], path[i], factoryHash);
            amounts[_dec(i)] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory Factory address for dex
    /// @param factoryHash Init code hash for factory
    /// @param amountOut Amount out for last token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsIn(
        address factory,
        bytes32 factoryHash,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        swaps[_dec(_dec(length))].amountOut = amountOut;
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            (address tokenIn, address tokenOut) = (path[_dec(i)], path[i]);
            (address token0, address token1) = sortTokens(tokenIn, tokenOut);
            address pair = _asmPairFor(factory, token0, token1, factoryHash);
            bool isReverse = tokenOut == token0;
            swaps[_dec(i)].isReverse = isReverse;
            swaps[_dec(i)].tokenIn = tokenIn;
            swaps[_dec(i)].tokenOut = tokenOut;
            swaps[_dec(i)].pair = pair;
            uint112 reserveIn;
            uint112 reserveOut;
            {
                (uint112 reserve0, uint112 reserve1) = IUniswapV2Pair(pair).getReserves();
                (reserveIn, reserveOut) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
            }
            swaps[_dec(i)].amountIn = getAmountIn(swaps[_dec(i)].amountOut, reserveIn, reserveOut);
            unchecked {
                swaps[_dec(i)].isBackrunnable = _isNonZero((1000 * swaps[_dec(i)].amountOut) / reserveOut);
            }
            // assign next amount out as last amount in
            if (i > 1) swaps[i - 2].amountOut = swaps[_dec(i)].amountIn;
        }
    }

    /// **** BACKRUNS ****
    /// @notice Internal call for optimal coefficients
    /// @dev Unchecked used to save gas with internal checks for overflows
    /// @param reserve0Token0 Reserve for first pool for first token
    /// @param reserve0Token1 Reserve for first pool for second token
    /// @param reserve1Token0 Reserve for second pool for first token
    /// @param reserve1Token1 Reserve for second pool for second token
    /// @return Cb Coefficient for Cb
    /// @return Cf Coefficient for Cf
    /// @return Cg Coefficient for Cg
    function calcCoeffs(
        uint112 reserve0Token0,
        uint112 reserve0Token1,
        uint112 reserve1Token0,
        uint112 reserve1Token1
    )
        internal
        pure
        returns (
            uint256 Cb,
            uint256 Cf,
            uint256 Cg
        )
    {
        // save gas with unchecked ... perform internal overflow checks
        unchecked {
            Cb = uint256(reserve1Token1) * uint256(reserve0Token0) * 1000000;
            if ((uint256(reserve0Token0) * 1000000) == Cb / uint256(reserve1Token1)) {
                uint256 Ca = uint256(reserve1Token0) * uint256(reserve0Token1) * 994009;
                if ((uint256(reserve0Token1) * 994009) == Ca / uint256(reserve1Token0)) {
                    if (Ca > Cb) {
                        Cf = Ca - Cb;
                        Cg = (uint256(reserve1Token1) * 997000) + (uint256(reserve0Token1) * 994009);
                    }
                }
            }
        }
    }

    /// @notice Internal call for optimal returns
    /// @dev Unchecked used to save gas. Values already checked.
    /// @param Cb Coefficient for Cb
    /// @param Cf Coefficient for Cf
    /// @param Cg Coefficient for Cg
    /// @param amountIn Optimal amount in
    /// @return optimalReturns Optimal return amount
    function calcReturns(
        uint256 Cb,
        uint256 Cf,
        uint256 Cg,
        uint256 amountIn
    ) internal pure returns (uint256) {
        unchecked {
            return (amountIn * (Cf - (Cg * amountIn))) / (Cb + amountIn * Cg);
        }
    }

    /// @notice Optimal amount in and return for back-run
    /// @param pair0 Pair for first back-run swap
    /// @param pair1 Pair for second back-run swap
    /// @param isReverse True if sorted tokens are opposite to input, output order
    /// @param isAaveAsset True if first token is an Aave asset, otherwise false
    /// @param contractAssetBalance Contract balance for first token
    /// @return optimalAmount Optimal amount for back-run
    /// @return optimalReturns Optimal return for back-run
    function getOptimalAmounts(
        address pair0,
        address pair1,
        bool isReverse,
        bool isAaveAsset,
        uint256 contractAssetBalance,
        uint256 bentoBalance
    ) internal view returns (uint256 optimalAmount, uint256 optimalReturns) {
        uint256 Cb;
        uint256 Cf;
        uint256 Cg;
        {
            (uint112 pair0Reserve0, uint112 pair0Reserve1) = IUniswapV2Pair(pair0).getReserves();
            (uint112 pair1Reserve0, uint112 pair1Reserve1) = IUniswapV2Pair(pair1).getReserves();
            (Cb, Cf, Cg) = isReverse
                ? calcCoeffs(pair0Reserve0, pair0Reserve1, pair1Reserve0, pair1Reserve1)
                : calcCoeffs(pair0Reserve1, pair0Reserve0, pair1Reserve1, pair1Reserve0);
        }
        if (_isNonZero(Cf) && _isNonZero(Cg)) {
            uint256 numerator0;
            {
                (uint256 _bSquare0, uint256 _bSquare1) = Uint512.mul256x256(Cb, Cb);
                (uint256 _4ac0, uint256 _4ac1) = Uint512.mul256x256(Cb, Cf);
                (uint256 _bsq4ac0, uint256 _bsq4ac1) = Uint512.add512x512(_bSquare0, _bSquare1, _4ac0, _4ac1);
                numerator0 = Uint512.sqrt512(_bsq4ac0, _bsq4ac1);
            }
            if (numerator0 > Cb) {
                // save gas with unchecked. We already know amount is +ve and finite
                unchecked {
                    optimalAmount = (numerator0 - Cb) / Cg;
                }
                // adjust optimal amount for available liquidity if needed
                if (contractAssetBalance < optimalAmount && !isAaveAsset && bentoBalance < optimalAmount) {
                    if (contractAssetBalance > bentoBalance) {
                        optimalAmount = contractAssetBalance;
                    } else {
                        optimalAmount = bentoBalance;
                    }
                }
                optimalReturns = calcReturns(Cb, Cf, Cg, optimalAmount);
            }
        }
    }

    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @notice Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @notice Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.17;

import { ERC20 } from "solmate/tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    error TransferFailed();
    error ApproveFailed();

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;
        assembly ("memory-safe") {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        // require(success, "ETH_TRANSFER_FAILED");
        if (!success) revert TransferFailed();
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        // require(success, "TRANSFER_FROM_FAILED");
        if (!success) revert TransferFailed();
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        // require(success, "TRANSFER_FAILED");
        if (!success) revert TransferFailed();
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        // require(success, "APPROVE_FAILED");
        if (!success) revert ApproveFailed();
    }
}

/// SPDX-License-Identifier: GPLv3
pragma solidity >=0.8.16 <0.9.0;

library Uint512 {
    /// @notice Calculates the product of two uint256
    /// @dev Used the chinese remainder theoreme
    /// @param a A uint256 representing the first factor.
    /// @param b A uint256 representing the second factor.
    /// @return r0 The result as an uint512. r0 contains the lower bits.
    /// @return r1 The higher bits of the result.
    function mul256x256(uint256 a, uint256 b) internal pure returns (uint256 r0, uint256 r1) {
        assembly ("memory-safe") {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// @notice Calculates the sum of two uint512
    /// @param a0 A uint256 representing the lower bits of the first addend.
    /// @param a1 A uint256 representing the higher bits of the first addend.
    /// @param b0 A uint256 representing the lower bits of the seccond addend.
    /// @param b1 A uint256 representing the higher bits of the seccond addend.
    /// @return r0 The result as an uint512. r0 contains the lower bits.
    /// @return r1 The higher bits of the result.
    function add512x512(
        uint256 a0,
        uint256 a1,
        uint256 b0,
        uint256 b1
    ) internal pure returns (uint256 r0, uint256 r1) {
        assembly ("memory-safe") {
            r0 := add(a0, b0)
            r1 := add(add(a1, b1), lt(r0, a0))
        }
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    /// @param x The uint256 number for which to calculate the square root.
    /// @return s The square root as an uint256.
    function sqrt256(uint256 x) internal pure returns (uint256 s) {
        if (x == 0) return 0;
        assembly ("memory-safe") {
            s := 1

            let xAux := x

            let cmp := or(gt(xAux, 0x100000000000000000000000000000000), eq(xAux, 0x100000000000000000000000000000000))
            xAux := sar(mul(cmp, 128), xAux)
            s := shl(mul(cmp, 64), s)

            cmp := or(gt(xAux, 0x10000000000000000), eq(xAux, 0x10000000000000000))
            xAux := sar(mul(cmp, 64), xAux)
            s := shl(mul(cmp, 32), s)

            cmp := or(gt(xAux, 0x100000000), eq(xAux, 0x100000000))
            xAux := sar(mul(cmp, 32), xAux)
            s := shl(mul(cmp, 16), s)

            cmp := or(gt(xAux, 0x10000), eq(xAux, 0x10000))
            xAux := sar(mul(cmp, 16), xAux)
            s := shl(mul(cmp, 8), s)

            cmp := or(gt(xAux, 0x100), eq(xAux, 0x100))
            xAux := sar(mul(cmp, 8), xAux)
            s := shl(mul(cmp, 4), s)

            cmp := or(gt(xAux, 0x10), eq(xAux, 0x10))
            xAux := sar(mul(cmp, 4), xAux)
            s := shl(mul(cmp, 2), s)

            s := shl(mul(or(gt(xAux, 0x8), eq(xAux, 0x8)), 2), s)
        }

        unchecked {
            s = (s + x / s) >> 1;
            s = (s + x / s) >> 1;
            s = (s + x / s) >> 1;
            s = (s + x / s) >> 1;
            s = (s + x / s) >> 1;
            s = (s + x / s) >> 1;
            s = (s + x / s) >> 1;
            uint256 roundedDownResult = x / s;
            return s >= roundedDownResult ? roundedDownResult : s;
        }
    }

    /// @notice Calculates the square root of a 512 bit unsigned integer, rounding down.
    /// @dev Uses the Karatsuba Square Root method. See https://hal.inria.fr/inria-00072854/document for details.
    /// @param a0 A uint256 representing the low bits of the input.
    /// @param a1 A uint256 representing the high bits of the input.
    /// @return s The square root as an uint256. Result has at most 256 bit.
    function sqrt512(uint256 a0, uint256 a1) internal pure returns (uint256 s) {
        // A simple 256 bit square root is sufficient
        if (a1 == 0) return sqrt256(a0);

        // The used algorithm has the pre-condition a1 >= 2**254
        uint256 shift;
        assembly ("memory-safe") {
            let digits := mul(lt(a1, 0x100000000000000000000000000000000), 128)
            a1 := shl(digits, a1)
            shift := add(shift, digits)

            digits := mul(lt(a1, 0x1000000000000000000000000000000000000000000000000), 64)
            a1 := shl(digits, a1)
            shift := add(shift, digits)

            digits := mul(lt(a1, 0x100000000000000000000000000000000000000000000000000000000), 32)
            a1 := shl(digits, a1)
            shift := add(shift, digits)

            digits := mul(lt(a1, 0x1000000000000000000000000000000000000000000000000000000000000), 16)
            a1 := shl(digits, a1)
            shift := add(shift, digits)

            digits := mul(lt(a1, 0x100000000000000000000000000000000000000000000000000000000000000), 8)
            a1 := shl(digits, a1)
            shift := add(shift, digits)

            digits := mul(lt(a1, 0x1000000000000000000000000000000000000000000000000000000000000000), 4)
            a1 := shl(digits, a1)
            shift := add(shift, digits)

            digits := mul(lt(a1, 0x4000000000000000000000000000000000000000000000000000000000000000), 2)
            a1 := shl(digits, a1)
            shift := add(shift, digits)

            a1 := or(a1, shr(sub(256, shift), a0))
            a0 := shl(shift, a0)
        }

        uint256 sp = sqrt256(a1);
        uint256 rp = a1 - (sp * sp);

        uint256 nom;
        uint256 denom;
        uint256 u;
        uint256 q;

        assembly ("memory-safe") {
            nom := or(shl(128, rp), shr(128, a0))
            denom := shl(1, sp)
            q := div(nom, denom)
            u := mod(nom, denom)

            // The nominator can be bigger than 2**256. We know that rp < (sp+1) * (sp+1). As sp can be
            // at most floor(sqrt(2**256 - 1)) we can conclude that the nominator has at most 513 bits
            // set. An expensive 512x256 bit division can be avoided by treating the bit at position 513 manually
            let carry := shr(128, rp)
            let x := mul(carry, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            q := add(q, div(x, denom))
            u := add(u, add(carry, mod(x, denom)))
            q := add(q, div(u, denom))
            u := mod(u, denom)
        }

        unchecked {
            s = (sp << 128) + q;

            uint256 rl = ((u << 128) | (a0 & 0xffffffffffffffffffffffffffffffff));
            uint256 rr = q * q;

            if ((q >> 128) > (u >> 128) || (((q >> 128) == (u >> 128)) && rl < rr)) {
                s = s - 1;
            }

            return s >> (shift >> 1);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17 <0.9.0;

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

/// @notice Minimal interface for BentoBox token vault (V1) interactions
interface IBentoBoxV1 {
    /**
     * @notice flashLoan is a function that allows a borrower to borrow a token for a short period of time.
     * @dev The borrower must provide an IFlashBorrower interface, the address of the receiver, the address of the token, the amount of the token to borrow, and any additional data.
     */
    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice This function is used to calculate the total amount of elastic and base tokens held by a given address.
     * @dev The function takes an address as an argument and returns the total amount of elastic and base tokens held by that address. The function is marked as external, meaning it can be called from outside the contract.
     */
    function totals(address token) external returns (uint128 elastic, uint128 base);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.17 <0.9.0;

/**
 * @title IFlashLoanSimpleReceiver
 * @author Aave
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanSimpleReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17 <0.9.0;

interface IOpenMevRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint112 reserveA,
        uint112 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint112 reserveIn,
        uint112 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint112 amountOut,
        uint112 reserveIn,
        uint112 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function harvest(
        uint256 percentage,
        address[] calldata tokens,
        address[] calldata receivers
    ) external payable;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.17 <0.9.0;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     **/
    function getReservesList() external view returns (address[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.17 <0.9.0;

interface IProtocolDataProvider {
    /**
     * @notice getReserveData() allows users to get the available liquidity of a given asset.
     * @dev getReserveData() takes an address of an asset as an argument and returns the available liquidity of that asset.
     */
    function getReserveData(address asset) external view returns (uint256 availableLiquidity);

    /**
     * @notice Returns the token addresses of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return aTokenAddress The AToken address of the reserve
     */
    function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17 <0.9.0;

interface IUniswapV2Factory {
    /**
     * @notice Returns the address of the pair for tokenA and tokenB, if it has been created, else address(0) (0x0000000000000000000000000000000000000000)
     * @dev tokenA and tokenB are interchangeable
     * @param tokenA address of the first token
     * @param tokenB address of the second token
     * @return pair address of the pair token
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Returns the address of the nth pair (0-indexed) created through the factory, or address(0) (0x0000000000000000000000000000000000000000) if not enough pairs have been created yet
     */
    function allPairs(uint256) external view returns (address pair);

    /**
     * @notice Returns the total number of pairs created through the factory so far.
     */
    function allPairsLength() external view returns (uint256);

    /**
     * @notice Creates a pair for tokenA and tokenB if one doesn't exist already
     * @dev tokenA and tokenB are interchangeable. Emits PairCreated event.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function pairCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17 <0.9.0;

interface IUniswapV2Pair {
    /// @notice This function permits an address to transfer tokens from the owner's account.
    /// @dev The function takes in the owner's address, the spender's address, the amount of tokens to be transferred, the deadline for the transfer, and the signature of the owner.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Returns the address of the pair token with the lower sort order.
    function token0() external view returns (address);

    /// @notice Returns the address of the pair token with the higher sort order.
    function token1() external view returns (address);

    /// @notice Returns the reserves of token0 and token1
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    /// @notice Creates pool tokens.
    function mint(address to) external returns (uint256 liquidity);

    /// @notice Destroys pool tokens
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swaps tokens. For regular swaps, data.length must be 0
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function approve(address spender, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17 <0.9.0;

interface IWETH {
    /**
     * @dev Allows users to deposit funds into the contract.
     * @notice Funds sent to the contract are stored in the contract's balance.
     */
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice This function allows a user to withdraw their funds from the contract.
     * @dev The withdraw function takes in a uint256 value and allows the user to withdraw their funds from the contract.
     */
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}