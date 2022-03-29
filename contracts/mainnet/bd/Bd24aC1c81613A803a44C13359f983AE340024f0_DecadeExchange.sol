// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/IFeedRegistry.sol";
import "./interface/ISwapRouter.sol";
import "./interface/IQuoter.sol";
import "./interface/IUniswapV2Router01.sol";
import "./library/LibTrade.sol";
import "./library/LibTransfer.sol";

contract DecadeExchange is OwnableUpgradeable {
    using LibTrade for LibTrade.Execution;
    using LibTrade for LibTrade.Order;
    using LibTransfer for IERC20;
    address private constant MATIC_ETH_FEED = 0x327e23A4855b6F663a28c5161541d69Af8973302;
    address private constant UNISWAP_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    bytes32 private constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;
    bytes32 private constant _DOMAIN_NAME = 0x741d9e87d8eeda4919e9c7d0972fa15141434ceb16208542e90992b4697fa12a;

    uint private constant GAS_ENTRANCE = 33000;
    uint private constant GAS_EXECUTION = 76850;
    uint private constant GAS_EXPECTATION = 272000;

    uint private constant RESERVE_MAX = 3000;
    uint private constant RESERVE_DENOM = 1000000;
    uint private constant PRICE_DENOM = 1000000;

    bytes32 private _domainSeparator;

    mapping(address => bool) private _whitelist;
    mapping(address => address) private _oracles;
    mapping(uint => uint) private _fills;

    event Executed(uint indexed askId, uint indexed bidId, uint baseOut, uint quoteOut);
    event Swapped(uint indexed orderId, uint amountOut, uint cost);

    modifier onlyWhitelisted {
        require(_whitelist[msg.sender] || msg.sender == owner(), "!whitelist");
        _;
    }

    /** Initialize **/

    function initialize() external initializer {
        __Ownable_init();

        require(_domainSeparator == 0);
        _domainSeparator = keccak256(abi.encode(_DOMAIN_TYPEHASH, _DOMAIN_NAME, _DOMAIN_VERSION, block.chainid, address(this)));

        _oracles[0x9b47AaD59A49d702708E570D804a1d25F9C867CC] = 0xA338e0492B2F944E9F8C0653D3AD1484f2657a37; // wbtc-eth
        _oracles[0xa2b762986783Dba0fe4464cc1d86A4975Fb1DeB5] = 0xefb7e6be8356cCc6827799B6A7348eE674A80EaE; // usdc-eth
    }

    /** Views **/

    function acceptance(LibTrade.Execution[] memory chunk, uint gasprice) public view returns (LibTrade.Acceptance[] memory) {
        LibTrade.Acceptance[] memory accepts = new LibTrade.Acceptance[](chunk.length);
        (,int _priceMatic,,,) = IFeedRegistry(MATIC_ETH_FEED).latestRoundData();

        for (uint i = 0; i < chunk.length; i++) {
            LibTrade.Execution memory exec = chunk[i];

            require(_min(exec.ask.deadline, exec.bid.deadline) >= block.timestamp, "!deadline");
            require(exec.price >= exec.ask.lprice && exec.price <= exec.bid.lprice, "!price");
            require(exec.recover(_domainSeparator), "!signature");

            require(exec.ask.amount >= _fills[exec.askId] + exec.amount, "!ask.amount");
            require(exec.bid.amount >= _fills[exec.bidId] + exec.amount, "!bid.amount");

            (uint reserveAsk, uint reserveBid) = _reservesOf(exec.ask.account, exec.bid.account, exec.amount, exec.reserve);
            (,int _priceBase,,,) = IFeedRegistry(_oracles[exec.base]).latestRoundData();

            uint txCost = gasprice * GAS_EXPECTATION * uint(_priceMatic) / uint(_priceBase) / (10 ** (18 - IERC20Metadata(exec.base).decimals())) / 2;

            require(reserveAsk + txCost <= exec.amount && reserveBid + txCost <= exec.amount, "!txCost");

            uint[2] memory askTransfers = [exec.amount, _amountQ(exec.base, exec.quote, exec.amount - reserveAsk - txCost, exec.price)];
            uint[2] memory bidTransfers = [_amountQ(exec.base, exec.quote, exec.amount, exec.price), exec.amount - reserveBid - txCost];

            require(IERC20(exec.base).available(exec.ask.account, address(this)) >= askTransfers[0], "!ask.available");
            require(IERC20(exec.quote).available(exec.bid.account, address(this)) >= bidTransfers[0], "!bid.available");

            accepts[i].result = true;
            accepts[i].askTransfers = askTransfers;
            accepts[i].bidTransfers = bidTransfers;
        }
        return accepts;
    }

    /** Restricts **/

    function resetFills(uint offset, uint length) external onlyOwner {
        for (uint i = offset; i < offset + length; i++) {
            if(_fills[i] != 0) delete _fills[i];
        }
    }

    function setWhitelist(address account, bool on) external onlyOwner {
        require(account != address(0), "!account");
        _whitelist[account] = on;
    }

    function setOracles(address[] calldata assets, address[] calldata feeds) external onlyOwner {
        require(assets.length == feeds.length, "!params");
        for (uint i = 0; i < assets.length; i++) {
            _oracles[assets[i]] = feeds[i];
        }
    }

    function approve(address token, address spender) external onlyOwner {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, type(uint).max);
        }
    }

    function execute(LibTrade.Execution[] memory chunk) external onlyWhitelisted {
        uint gasShared = GAS_ENTRANCE / chunk.length + GAS_EXECUTION;
        for (uint i = 0; i < chunk.length; i++) {
            uint gasUsed = gasShared + gasleft();
            LibTrade.Execution memory exec = chunk[i];

            require(_min(exec.ask.deadline, exec.bid.deadline) >= block.timestamp, "!deadline");
            require(exec.price >= exec.ask.lprice && exec.price <= exec.bid.lprice, "!price");
            require(exec.recover(_domainSeparator), "!signature");

            (uint filledAsk, uint filledBid) = (_fills[exec.askId], _fills[exec.bidId]);
            require(exec.ask.amount >= filledAsk + exec.amount, "!filled");
            require(exec.bid.amount >= filledBid + exec.amount, "!filled");
            _fills[exec.askId] = filledAsk + exec.amount;
            _fills[exec.bidId] = filledBid + exec.amount;

            IERC20(exec.base).safeTransferFrom(exec.ask.account, address(this), exec.amount);
            IERC20(exec.quote).safeTransferFrom(exec.bid.account, address(this), _amountQ(exec.base, exec.quote, exec.amount, exec.price));

            (uint reserveAsk, uint reserveBid) = _reservesOf(exec.ask.account, exec.bid.account, exec.amount, exec.reserve);
            uint txCost = _txCostOf(exec.base, (gasUsed - gasleft()) / 2);

            IERC20(exec.quote).safeTransfer(exec.ask.account, _amountQ(exec.base, exec.quote, exec.amount - reserveAsk - txCost, exec.price));
            IERC20(exec.base).safeTransfer(exec.bid.account, exec.amount - reserveBid - txCost);
            emit Executed(exec.askId, exec.bidId, exec.amount - reserveBid - txCost, _amountQ(exec.base, exec.quote, exec.amount - reserveAsk - txCost, exec.price));
        }
    }

    function swap(LibTrade.SwapOrder[] memory chunk) external onlyWhitelisted {
        for (uint i = 0; i < chunk.length; i++) {
            uint gasUsed = gasleft();
            LibTrade.SwapOrder memory swapOrder = chunk[i];

            if (swapOrder.order.amount > _fills[swapOrder.orderId] + swapOrder.remain) continue;
            if(!swapOrder.order.recoverOrder(_domainSeparator, swapOrder.signature)) continue;

            (address tokenIn, address tokenOut) = (swapOrder.order.tokenIn, swapOrder.order.tokenOut);

            bool askSide = tokenIn == swapOrder.base;
            uint expected = swapOrder.order.lprice * swapOrder.remain / 10 ** IERC20Metadata(swapOrder.base).decimals();
            uint amountIn = askSide ? swapOrder.remain : expected;

            if (IERC20(tokenIn).balanceOf(swapOrder.order.account) < amountIn) continue;

            uint amountOut = swapOrder.pathBytes.length == 0 ? _swapV2(swapOrder, expected, askSide) : _swapV3(swapOrder, expected, askSide);
            if (amountOut == 0) continue;

            uint _reserve = _whitelist[swapOrder.order.account] ? 0 : _reserves(amountOut, swapOrder.reserve);
            uint txCost = _txCostOf(swapOrder.base, gasUsed - gasleft());
            if (askSide) {
                txCost = _amountQ(swapOrder.base, swapOrder.quote, swapOrder.remain - txCost, swapOrder.order.lprice);
            }

            _fills[swapOrder.orderId] += swapOrder.remain;

            IERC20(tokenOut).safeTransfer(swapOrder.order.account, amountOut - _reserve - txCost);
            emit Swapped(swapOrder.orderId, amountOut, _reserve + txCost);
        }
    }

    /** Privates **/

    function _amountQ(address base, address quote, uint amount, uint price) private view returns (uint) {
        return (amount * price * (10 ** IERC20Metadata(quote).decimals())) / (PRICE_DENOM * (10 ** IERC20Metadata(base).decimals()));
    }

    function _reservesOf(address accountAsk, address accountBid, uint amount, uint reserve) private view returns (uint reserveAsk, uint reserveBid) {
        uint _reserve = _reserves(amount, reserve);
        return (_whitelist[accountAsk] ? 0 : _reserve, _whitelist[accountBid] ? 0 : _reserve);
    }

    function _reserves(uint amount, uint reserve) private pure returns (uint) {
        return amount * _min(reserve, RESERVE_MAX) / RESERVE_DENOM;
    }

    function _txCostOf(address base, uint gasUsed) private view returns (uint) {
        (,int _priceBase,,,) = IFeedRegistry(_oracles[base]).latestRoundData();
        (,int _priceMatic,,,) = IFeedRegistry(MATIC_ETH_FEED).latestRoundData();
        return tx.gasprice * gasUsed * uint(_priceMatic) / uint(_priceBase) / (10 ** (18 - IERC20Metadata(base).decimals()));
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

    function _max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }

    function _transferFrom(address token, address from, uint amount) private {
        IERC20(token).safeTransferFrom(from, address(this), amount);
    }

    function _swapV2(LibTrade.SwapOrder memory swapOrder, uint expected, bool ask) private returns (uint amountOut) {
        if (ask) {
            uint amountOutMin = IUniswapV2Router01(swapOrder.router).getAmountsOut(swapOrder.remain, swapOrder.path)[swapOrder.path.length - 1];
            if (amountOutMin < expected) return 0;

            _transferFrom(swapOrder.order.tokenIn, swapOrder.order.account, swapOrder.remain);
            amountOut = IUniswapV2Router01(swapOrder.router).swapExactTokensForTokens(swapOrder.remain, expected, swapOrder.path, address(this), block.timestamp + 100)[swapOrder.path.length - 1];
        } else {
            uint amountInMax = IUniswapV2Router01(swapOrder.router).getAmountsIn(swapOrder.remain, swapOrder.path)[0];
            if (amountInMax > expected) return 0;

            _transferFrom(swapOrder.order.tokenIn, swapOrder.order.account, amountInMax);
            amountOut = IUniswapV2Router01(swapOrder.router).swapTokensForExactTokens(swapOrder.remain, amountInMax, swapOrder.path, address(this), block.timestamp + 100)[swapOrder.path.length - 1];
        }
    }

    function _swapV3(LibTrade.SwapOrder memory swapOrder, uint expected, bool ask) private returns (uint amountOut) {
        if (ask) {
            uint amountOutMin = IQuoter(UNISWAP_QUOTER).quoteExactInput(swapOrder.pathBytes, swapOrder.remain);
            if (amountOutMin < expected) return 0;

            _transferFrom(swapOrder.order.tokenIn, swapOrder.order.account, swapOrder.remain);
            amountOut = ISwapRouter(swapOrder.router).exactInput(ISwapRouter.ExactInputParams(swapOrder.pathBytes, address(this), swapOrder.remain, expected));
        } else {
            uint amountInMax = IQuoter(UNISWAP_QUOTER).quoteExactOutput(swapOrder.pathBytes, swapOrder.remain);
            if (amountInMax > expected) return 0;

            _transferFrom(swapOrder.order.tokenIn, swapOrder.order.account, amountInMax);
            ISwapRouter(swapOrder.router).exactOutput(ISwapRouter.ExactOutputParams(swapOrder.pathBytes, address(this), swapOrder.remain, amountInMax));
            amountOut = swapOrder.remain;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity 0.8.9;


interface IFeedRegistry {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);

}

// SPDX-License-Identifier: MIT
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
pragma solidity 0.8.9;


library LibTrade {
    // keccak256("Order(address account,address tokenIn,address tokenOut,uint256 amount,uint256 lprice,uint256 deadline)");
    bytes32 constant _ORDER_TYPEHASH = 0x94b76532850ea0de9b697b00c10f4f5639904158f970c28b2baf02fde94b3bce;

    struct Order {
        address account;
        address tokenIn;
        address tokenOut;
        uint amount;
        uint lprice;
        uint deadline;
    }

    struct OrderPacked {
        address account;
        uint amount;
        uint lprice;
        uint deadline;
    }

    struct Execution {
        address base;
        address quote;
        OrderPacked ask;
        OrderPacked bid;
        bytes askSig;
        bytes bidSig;
        uint askId;
        uint bidId;
        uint amount;
        uint price;
        uint reserve;
    }

    struct SwapOrder {
        address router;
        address base;
        address quote;
        address[] path;     // v3 bytes
        Order order;
        bytes signature;
        bytes pathBytes;
        uint orderId;
        uint remain;
        uint reserve;
    }

    struct Acceptance {
        bool result;
        uint[2] askTransfers;
        uint[2] bidTransfers;
    }

    function recover(Execution memory exec, bytes32 domainSeparator) internal pure returns (bool) {
        Order memory ask = Order(exec.ask.account, exec.base, exec.quote, exec.ask.amount, exec.ask.lprice, exec.ask.deadline);
        Order memory bid = Order(exec.bid.account, exec.quote, exec.base, exec.bid.amount, exec.bid.lprice, exec.bid.deadline);
        return recoverOrder(ask, domainSeparator, exec.askSig) && recoverOrder(bid, domainSeparator, exec.bidSig);
    }

    function recoverOrder(Order memory order, bytes32 domainSeparator, bytes memory signature) internal pure returns (bool) {
        require(signature.length == 65, "invalid signature length");

        bytes32 structHash;
        bytes32 orderDigest;

        assembly {
            let dataStart := sub(order, 32)
            let temp := mload(dataStart)
            mstore(dataStart, _ORDER_TYPEHASH)
            structHash := keccak256(dataStart, 224)
            mstore(dataStart, temp)
        }

        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "invalid signature 's' value");

        address signer;

        if (v > 30) {
            require(v - 4 == 27 || v - 4 == 28, "invalid signature 'v' value");
            signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderDigest)), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "invalid signature 'v' value");
            signer = ecrecover(orderDigest, v, r, s);
        }
        return signer != address(0) && signer == order.account;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibTransfer {
    function available(IERC20 token, address owner, address spender) internal view returns (uint) {
        uint _allowance = token.allowance(owner, spender);
        uint _balance = token.balanceOf(owner);
        return _allowance < _balance ? _allowance : _balance;
    }

    function safeTransfer(IERC20 token, address to, uint value) internal {
        bytes4 selector_ = token.transfer.selector;
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        require(_getLastTransferResult(token), "!safeTransfer");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        bytes4 selector_ = token.transferFrom.selector;
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        require(_getLastTransferResult(token), "!safeTransferFrom");
    }

    function _getLastTransferResult(IERC20 token) private view returns (bool success) {
        assembly {
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            case 0 {
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "!contract")
                }
                success := 1
            }
            case 32 {
                returndatacopy(0, 0, returndatasize())
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "!transferResult")
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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