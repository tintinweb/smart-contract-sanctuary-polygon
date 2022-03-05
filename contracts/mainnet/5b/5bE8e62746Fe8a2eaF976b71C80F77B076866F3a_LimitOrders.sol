// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../libraries/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../libraries/UniswapV2Library.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "./ISpaceLimitOrder.sol";
import "./SpaceOrderRouter.sol";
contract LimitOrders {
    // enum OrderStatus {PENDING, FILLED, CANCELLED}
    enum OrderStatus { PENDING, FILLED, CANCELLED }
    enum OrderType { ETH_TOKEN, TOKEN_TOKEN, TOKEN_ETH }

    event OrderPlaced(uint256 orderID, address owner, uint256 amountIn, address tokenIn, address tokenOut, uint256 priceExecuted, uint256 minAmountOut);
    event OrderCancelled(uint256 orderID);
    event OrderFulfilled(uint256 orderID, address broker);


    struct Order {
        uint256 orderID;
        uint256 pendingIndex;
        address owner;
        OrderStatus status;
        OrderType swapType;
        address pair;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 priceExecuted;  
        uint256 minAmountOut;
        uint256 timestamp;
    }

    address public immutable factory;
    uint256 public constant ORDER_EXPIRY = 7 days;
    address public immutable WETH;
    uint256 public ordersIndex = 1;

    // orders
    mapping (uint256 => Order) public orders;
    mapping (address => uint256[]) public addressOrders;
    mapping (address => uint256[]) public pairOrders;
    uint256[] pendingOrders;

    SpaceOrderRouter spaceRouter;

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
        spaceRouter = new SpaceOrderRouter(_WETH);
    }

    bool entered = false;

    modifier reentrancyGuard() {
        require(!entered, "Reentrancy Disallowed");
        entered = true;
        _;
        entered = false;
    }


    receive() external payable {
        assert(msg.sender == WETH);
    }

    function getRouterAddress() external view  returns (address){
        return address(spaceRouter);
    }

    function placeETHTokenOrder(address tokenOut, uint256 priceExecuted, uint256 minAmountOut) external payable  {
        createOrder(msg.sender, OrderType.ETH_TOKEN, WETH, tokenOut, msg.value, priceExecuted, minAmountOut);
    }
    
    
    function placeTokenTokenOrder(address tokenIn, uint256 amountIn, address tokenOut, uint256 priceExecuted, uint256 minAmountOut) external  {
        require(IERC20(tokenIn).allowance(msg.sender, address(spaceRouter)) >= amountIn, "Not enough allowance for order");
        
        createOrder(msg.sender, OrderType.TOKEN_TOKEN, WETH, tokenOut, amountIn, priceExecuted, minAmountOut);
    }
    
    function placeTokenETHOrder(address tokenIn, uint256 amountIn, uint256 priceExecuted, uint256 minAmountOut) external  {
        require(IERC20(tokenIn).allowance(msg.sender, address(spaceRouter)) >= amountIn, "Not enough allowance for order");
        
        createOrder(msg.sender, OrderType.TOKEN_ETH, tokenIn, WETH, amountIn, priceExecuted, minAmountOut);
    }

    function createOrder(
        address owner,
        OrderType swapType,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 priceExecuted,
        uint256 minAmountOut
    ) internal returns (uint256) {
        address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
        require(pair != address(0), "Pair does not exist!");

        uint256 orderID = ordersIndex++;
        uint256 pendingIndex = pendingOrders.length;
        pendingOrders.push(orderID);

        addressOrders[msg.sender].push(orderID);
        pairOrders[pair].push(orderID);

        orders[orderID] = Order(
            orderID,
            pendingIndex,
            owner,
            OrderStatus.PENDING,
            swapType,
            pair,
            tokenIn,
            tokenOut,
            amountIn,
            priceExecuted,
            minAmountOut,
            block.timestamp
        );

        emit OrderPlaced(orderID, msg.sender, amountIn, tokenIn, tokenOut,priceExecuted, minAmountOut);
        return orderID;
    }

    function cancelOrder(uint256 orderID) external  {
        Order memory ord = orders[orderID];

        require(msg.sender == ord.owner || ord.timestamp + ORDER_EXPIRY  >= block.timestamp, "Failed to cancel this order.");
        require(ord.status == OrderStatus.PENDING, "Order must be a pending order");

        _cancelOrder(orderID);
    }

    function _cancelOrder(uint256 orderID) internal {
        Order memory ord = orders[orderID];


        closeOrder(orderID, OrderStatus.CANCELLED);
        emit OrderCancelled(orderID);
    }

    function closeOrder(uint256 orderID, OrderStatus status) internal {
        //Remove order from pending by swapping in last pending order then pop from array 
        pendingOrders[orders[orderID].pendingIndex] = pendingOrders[pendingOrders.length - 1];

        //update pendingIndex for moved order
        orders[pendingOrders[orders[orderID].pendingIndex]].pendingIndex = orders[orderID].pendingIndex;

        // remove duplicate pending order from end
        pendingOrders.pop();

        // update status
        orders[orderID].status = status;
        orders[orderID].timestamp = block.timestamp;
    }   

    function executeOrder(uint256 orderID) public  reentrancyGuard returns (bool filled){
        Order memory ord = orders[orderID];

        require(ord.status == OrderStatus.PENDING, "Can't executed non-pending order");

        if(execute(ord)) {
            closeOrder(orderID, OrderStatus.FILLED);

            emit OrderFulfilled(orderID, msg.sender);
            return true;
        } else {
            _cancelOrder(orderID);
            emit OrderCancelled(orderID);
        }
        return false;
    }

    function execute(Order memory ord) internal returns (bool filled) {
        if(ord.swapType == OrderType.ETH_TOKEN){
            try spaceRouter.makeETHTokenSwap{value: ord.amountIn}(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut) {return true;} catch {return false;}
        } else if (ord.swapType == OrderType.TOKEN_TOKEN) {
            try spaceRouter.makeTokenTokenSwap(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut) { return true; } catch { return false; }
        } else { //tpye Token_ETH
            try spaceRouter.makeTokenETHSwap(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut) { return true; } catch { return false; }
        }
    }

    function symbolFor(address token) external view returns (string memory) {
        return IERC20(token).symbol();
    }

    function getPendingOrders() external view  returns (uint256[] memory) {
        return pendingOrders;
    }

     function getOrdersForAddress(address adr) external view  returns (uint256[] memory) {
        return addressOrders[adr];
    }
    
    function getOrdersForPair(address pair) external view  returns (uint256[] memory) {
        return pairOrders[pair];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "../interfaces/IUniswapV2Pair.sol";

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            // hex"966a963e3b25b66a576eb88e424b7615304e3e0b136a99fcf39cd343c6baa72f" // UniswapV2Pair bytecode hash
                            hex"9d5ddce9e360e6ed1fb3230c538363b64a1970f93e8539e959a827e0f6aedc68" // UniswapV2Pair bytecode hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997); // 99.7 || 1* 997
        uint256 numerator = amountInWithFee.mul(reserveOut); //99.7 * 100 = 9970 || 997 * 100 = 99700
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee); // 1000+99.7 = 1099.7 || 1000+997 = 1997
        amountOut = numerator / denominator; // 99700 / 1997
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISpaceLimitOrders {
    enum OrderStatus { PENDING, FILLED, CANCELLED }
    enum OrderType { ETH_TOKEN, TOKEN_TOKEN, TOKEN_ETH }
    
    function getRouterAddress() external view returns (address);
    
    function placeETHTokenOrder(address tokenOut, uint256 priceExecuted, uint256 minAmountOut) external payable;
    function placeTokenTokenOrder(address tokenIn, uint256 amountIn, address tokenOut, uint256 priceExecuted, uint256 minAmountOut) external;
    function placeTokenETHOrder(address tokenIn, uint256 amountIn, uint256 priceExecuted, uint256 minAmountOut) external;
    
    function cancelOrder(uint256 orderID) external;
    
    function executeOrder(uint256 orderID) external returns (bool filled);
    
    function getPendingOrders() external view returns (uint256[] memory);
    
    function getOrdersForAddress(address adr) external view returns (uint256[] memory);
    function getOrdersForPair(address pair) external view returns (uint256[] memory);
    
    event OrderPlaced(uint256 orderID, address owner, uint256 amountIn, address tokenIn, address tokenOut, uint256 priceExecuted, uint256 minAmountOut);
    event OrderCancelled(uint256 orderID);
    event OrderFulfilled(uint256 orderID, address broker);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../libraries/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/UniswapV2Library.sol";
import "../interfaces/IUniswapV2Pair.sol";

// Use second contract for router as allows try catch on external router calls from main contract to make cancelling failing swaps possible in same tx

contract SpaceOrderRouter {
    using SafeMath for uint256;
    
    enum OrderStatus { PENDING, FILLED, CANCELLED }
    enum OrderType { ETH_TOKEN, TOKEN_TOKEN, TOKEN_ETH }
    
    struct Order {
        uint256 id;                 // Order ID 
        uint256 pendingIndex;       // Index in pending order array
        address owner;              // Order placer 
        OrderStatus status;         // Order status 
        OrderType swapType;         // Order type
        address tokenIn;            // Token to swap 
        address tokenOut;           // Token to swap for
        uint256 amountIn;           // ETH Amount in 
        uint256 priceExecuted;    // Price to trigger order at 
        uint256 minAmountOut;       // Max price to trigger order at (in case price changed before tx has been mined)
        uint256 timestamp;
    }
    
    address public WETH; 
    
    address authorizedCaller;
    

    constructor (address _WETH) {
        authorizedCaller = msg.sender;
        WETH = _WETH;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == authorizedCaller); _;
    }
    
    receive() external payable {
        assert(msg.sender == WETH);
    }
    

    function makeTokenTokenSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external onlyAuthorized {
        TransferHelper.safeTransferFrom(
            tokenIn, owner, pair, amountIn
        );
        
        uint balanceBefore = IERC20(tokenOut).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        require(
            IERC20(tokenOut).balanceOf(owner).sub(balanceBefore) >= minAmountOut,
            'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    
     function makeTokenETHSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external onlyAuthorized {
        TransferHelper.safeTransferFrom(
            tokenIn, owner, pair, amountIn
        );
        
        uint balanceBefore = IERC20(WETH).balanceOf(address(this));
        _swap(pair, tokenIn, tokenOut, address(this));
        
        uint amountOut = IERC20(WETH).balanceOf(address(this)).sub(balanceBefore);
        
        require(amountOut >= minAmountOut, 'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        
        IWETH(WETH).withdraw(amountOut);
        
        TransferHelper.safeTransferETH(owner, amountOut);
    }
    
    function makeETHTokenSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external payable onlyAuthorized {
        // Swap bnb for WETH then transfer to pair
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pair, amountIn));
        
        uint balanceBefore = IERC20(tokenOut).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        require(
            IERC20(tokenOut).balanceOf(owner).sub(balanceBefore) >= minAmountOut,
            'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
    
    // function _swap(
    //     uint256[] memory amounts,
    //     address[] memory path,
    //     address _to
    // ) internal virtual {
    //     for (uint256 i; i < path.length - 1; i++) {
    //         (address input, address output) = (path[i], path[i + 1]);
    //         (address token0, ) = UniswapV2Library.sortTokens(input, output);
    //         uint256 amountOut = amounts[i + 1];
    //         (uint256 amount0Out, uint256 amount1Out) = input == token0
    //             ? (uint256(0), amountOut)
    //             : (amountOut, uint256(0));
    //         address to = i < path.length - 2
    //             ? UniswapV2Library.pairFor(factory, output, path[i + 2])
    //             : _to;
    //         IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
    //             .swap(amount0Out, amount1Out, to, new bytes(0));
    //     }
    // }
    function _swap(
        address _pair,
        address tokenIn,
        address tokenOut,
        address to
    ) internal virtual {
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        uint amountInput;
        uint amountOutput;
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = tokenIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(tokenIn).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);

        (uint amount0Out, uint amount1Out) = tokenIn == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}