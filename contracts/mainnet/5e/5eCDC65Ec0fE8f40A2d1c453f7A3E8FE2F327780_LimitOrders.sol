// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LimitOrderRouter.sol";



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

// interface ISpaceLimitOrders {
//     enum OrderStatus { PENDING, FILLED, CANCELLED }
//     enum OrderType { ETH_TOKEN, TOKEN_TOKEN, TOKEN_ETH }
    
//     function getRouterAddress() external view returns (address);
    
//     function placeETHTokenOrder(address tokenOut, uint256 priceExecute, uint256 minAmountOut, uint256 deadline) external payable;
//     function placeTokenTokenOrder(address tokenIn, uint256 amountIn, address tokenOut, uint256 priceExecute, uint256 minAmountOut, uint256 deadline) external;
//     function placeTokenETHOrder(address tokenIn, uint256 amountIn, uint256 priceExecute, uint256 minAmountOut, uint256 deadline) external;
//     function executeOrder() external returns (bool filled);
// }


contract LimitOrders{

    using SafeMath for uint256;
    
    // enum OrderStatus {PENDING, FILLED, CANCELLED}
    // enum OrderStatus { PENDING, FILLED, CANCELLED }
    // enum OrderType { ETH_TOKEN, TOKEN_TOKEN, TOKEN_ETH }

    // event OrderPlaced(uint256 orderID, address owner, uint256 amountIn, address tokenIn, address tokenOut, uint256 priceExecute, uint256 minAmountOut);
    event OrderCancelled(address owner,
        uint256 status,
        uint256 swapType,
        address pair,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 priceExecute,  
        uint256 minAmountOut,
        uint256 deadline
        );
    event OrderFulfilled(address owner,
        uint256 status,
        uint256 swapType,
        address pair,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 priceExecute,  
        uint256 minAmountOut,
        uint256 deadline);

    struct Order {
        address owner;
        uint256 status;
        uint256 swapType;
        address pair;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 priceExecute;  
        uint256 minAmountOut;
        uint256 deadline;
    }

    address public immutable factory;
    uint256 public constant ORDER_EXPIRY = 7 days;
    address public immutable WMATIC;
    uint256 public ORDER_TIMESTAMP = block.timestamp;
    address public constant WMATIC_USDC = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;
    // address public constant WMATIC_DAI = 0x1c5DEe94a34D795f9EEeF830B68B80e44868d316; //ropsten
    // address public constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D; //ropsten
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;


    // orders
    mapping (uint256 => Order) public orders;

    uint256[] pendingOrders;

    SpaceOrderRouter spaceRouter;

    constructor() {
        // factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        // WMATIC = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        factory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
        WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        spaceRouter = new SpaceOrderRouter();
    }

    bool entered = false;

    modifier reentrancyGuard() {
        require(!entered, "Reentrancy Disallowed");
        entered = true;
        _;
        entered = false;
    }

    receive() external payable {
        assert(msg.sender == WMATIC);
    }

    function getRouterAddress() external view returns (address){
        return address(spaceRouter);
    }

    // function placeETHTokenOrder(address tokenOut, uint256 priceExecute, uint256 minAmountOut, uint256 deadline) external payable {
    //     setOrder(msg.sender, 1, WMATIC, tokenOut, msg.value, priceExecute, minAmountOut, deadline);
    // }
    
    
    // function placeTokenTokenOrder(address tokenIn, uint256 amountIn, address tokenOut, uint256 priceExecute, uint256 minAmountOut, uint256 deadline) external {
    //     require(IERC20(tokenIn).allowance(msg.sender, address(spaceRouter)) >= amountIn, "Not enough allowance for order");
        
    //     setOrder(msg.sender, OrderType.TOKEN_TOKEN, tokenIn, tokenOut, amountIn, priceExecute, minAmountOut, deadline);
    // }
    
    // function placeTokenETHOrder(address tokenIn, uint256 amountIn, uint256 priceExecute, uint256 minAmountOut, uint256 deadline) external {
    //     require(IERC20(tokenIn).allowance(msg.sender, address(spaceRouter)) >= amountIn, "Not enough allowance for order");
        
    //     setOrder(msg.sender, OrderType.TOKEN_ETH, tokenIn, WMATIC, amountIn, priceExecute, minAmountOut, deadline);
    // }
    
    // function setOrder(
    //     address owner,
    //     OrderType swapType,
    //     address tokenIn,
    //     address tokenOut,
    //     uint256 amountIn,
    //     uint256 priceExecute,
    //     uint256 minAmountOut,
    //     uint256 deadline
    //     ) public returns (uint256) {
    //     address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
    //     require(pair != address(0), "Pair does not exist!");
    //     require(minAmountOut <= priceExecute, "Invalid output amounts");
    //     orders[0] = Order(
    //         owner,
    //         0,
    //         swapType,
    //         pair,
    //         tokenIn,
    //         tokenOut,
    //         amountIn,
    //         priceExecute,
    //         minAmountOut,
    //         deadline
    //     );
    //     return 0;
    //     }
    
   

    function shouldFulfilOrder(Order memory ord) public view returns (bool) {
        return ord.status == 0 && getAmountOut(ord.amountIn,ord.pair, ord.tokenIn, ord.tokenOut) >= ord.priceExecute;
    }


    function ExecuteCustomOrder(Order memory ord) public reentrancyGuard payable returns (bool filled){
        require(ord.status == 0, "Can't executed non-pending order");

        if(execute(ord)) {
            // emit
            emit OrderFulfilled(ord.owner,ord.status,ord.swapType,ord.pair,ord.tokenIn,ord.tokenOut,ord.amountIn,ord.priceExecute,ord.minAmountOut,ord.deadline);
            return true;

        } else {
            if(ord.status == 0 && getAmountOut(ord.amountIn,ord.pair, ord.tokenIn, ord.tokenOut) >= ord.minAmountOut ||
             IERC20(ord.tokenIn).balanceOf(ord.owner) < ord.amountIn || IERC20(ord.tokenIn).allowance(ord.owner, address(spaceRouter)) < ord.amountIn
             ){
                if(ord.swapType == 1){
                payable(ord.owner).transfer(ord.amountIn);
                emit OrderCancelled(ord.owner,ord.status,ord.swapType,ord.pair,ord.tokenIn,ord.tokenOut,ord.amountIn,ord.priceExecute,ord.minAmountOut,ord.deadline);
                }
            }
            return false;
            //emit
        }
    }

    function cancelOrder(Order memory ord) external {

        require(msg.sender == ord.owner || ord.deadline >= block.timestamp, "Failed to cancel this order.");
        // require(msg.sender == ord.owner || ord.timestamp + ORDER_EXPIRY  >= block.timestamp, "Failed to cancel this order.");
        require(ord.status == 0, "Order must be a pending order");

        _cancelOrder(ord);
    }

    function _cancelOrder(Order memory ord) internal {

         // refund and close
        if(ord.swapType == 1){
            payable(ord.owner).transfer(ord.amountIn);
        }
    }


    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }


    function getAmountOut(uint amountIn,address pair, address tokenIn, address tokenOut) public view returns (uint amountOut) {

        (uint reserveIn, uint reserveOut) = getReserves(pair, tokenIn, tokenOut);

        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    
    

    function execute(Order memory ord) internal returns (bool filled) {
        // if(OrderType == "ETH_TOKEN"){
        //     try spaceRouter.makeETHTokenSwap{value: amountIn}(Owner, tokenIn, tokenOut, pair, amountIn, minAmountOut, deadline) {return true;} catch {return false;}
        // } else if (OrderType == "TOKEN_TOKEN") {
        //     try spaceRouter.makeTokenTokenSwap(Owner, tokenIn, tokenOut, pair, amountIn, minAmountOut, deadline) { return true; } catch { return false; }
        // } else { //type Token_ETH
        //     try spaceRouter.makeTokenETHSwap(Owner, tokenIn, tokenOut, pair, amountIn, minAmountOut, deadline) { return true; } catch { return false; }
        // }
        if(ord.swapType == 0){
            try spaceRouter.makeETHTokenSwap{value: ord.amountIn}(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut, ord.deadline) {return true;} catch {return false;}
        } else if (ord.swapType == 1) {
            try spaceRouter.makeTokenTokenSwap(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut, ord.deadline) { return true; } catch { return false; }
        } else { //tpye Token_ETH
            try spaceRouter.makeTokenETHSwap(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut, ord.deadline) { return true; } catch { return false; }
        }
    }



  
    

      /**
     * Returns 10^decimals * tokenOut per tokenIn
     */

    function getPair(address tokenIn, address tokenOut) public view returns (address) {
        return IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
    }

 
     /**
     * Returns 10^decimals * quoteToken per baseToken
     */
 

    function symbolFor(address token) external view returns (string memory) {
        return IERC20(token).symbol();
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
// Use second contract for router as allows try catch on external router calls from main contract to make cancelling failing swaps possible in same tx
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
    // function _div(uint256 a, uint256 b) internal pure returns (uint256) {
    //     require(b>0, "Can't div 0!!!");
    //     uint256 c = a/b;
    //     return c;
    // }
    // function div(uint256 a,uint256 b) internal pure returns (uint256) {
    //     return _div(a,b);
    // }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
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
interface IWMATIC {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

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
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // UniswapV2Pair bytecode hash
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


contract SpaceOrderRouter {
    using SafeMath for uint256;

    
    // address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //eth
    address public constant factory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32; //polygon

    struct Order {
        address owner;
        uint256 status;
        uint256 swapType;
        address pair;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 priceExecute;  
        uint256 minAmountOut;
        uint256 deadline;
    }
    
    // address public constant WMATIC = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //eth
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //polygon
    // 0x1c5DEe94a34D795f9EEeF830B68B80e44868d316
    address authorizedCaller;

    constructor () {
        authorizedCaller = msg.sender;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == authorizedCaller); _;
    }


    
    receive() external payable {
        assert(msg.sender == WMATIC);
    }
    

    function makeTokenTokenSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut, uint256 deadline) external onlyAuthorized {
        
        
        TransferHelper.safeTransferFrom(
            tokenIn, owner, pair, amountIn
        );
        
        uint balanceBefore = IERC20(tokenOut).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        require(
            IERC20(tokenOut).balanceOf(owner).sub(balanceBefore) >= minAmountOut,
            'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        require(
            deadline >= block.timestamp,
            'Order Expired!!!!!!!!'
        );
    }
    function makeTokenETHSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut, uint256 deadline) external {
        TransferHelper.safeTransferFrom(
            tokenIn, owner, pair, amountIn
        );
        uint balanceBefore = IERC20(WMATIC).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        uint amountOut = IERC20(WMATIC).balanceOf(owner).sub(balanceBefore);
        
        require(amountOut >= minAmountOut, 'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        
        IWMATIC(WMATIC).withdraw(amountOut);
        
        TransferHelper.safeTransferETH(owner, amountOut);
        require(
            deadline >= block.timestamp,
            'Order Expired!!!!!!!!'
        );
    }
    function makeETHTokenSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut, uint256 deadline) external payable {
        // Swap ETH for WMATIC then transfer to pair
        IWMATIC(WMATIC).deposit{value: amountIn}();
        assert(IWMATIC(WMATIC).transfer(pair, amountIn));
        
        uint balanceBefore = IERC20(tokenOut).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        require(
            IERC20(tokenOut).balanceOf(owner).sub(balanceBefore) >= minAmountOut,
            'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        require(
            deadline >= block.timestamp,
            'Order Expired!!!!!!!!'
        );
    }
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

//     function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
//         for (uint i; i < path.length - 1; i++) {
//             (address input, address output) = (path[i], path[i + 1]);
//             (address token0,) = UniswapV2Library.sortTokens(input, output);
//             uint amountOut = amounts[i + 1];
//             (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
//             address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
//             IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
//                 amount0Out, amount1Out, to, new bytes(0)
//             );      
// }   
//     }
// }