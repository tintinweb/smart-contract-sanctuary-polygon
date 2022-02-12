/**
 *Submitted for verification at polygonscan.com on 2022-02-12
*/

// File: contracts/uniswapv2/interfaces/IEurekaV2Pair.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IEurekaV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

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

// File: contracts/uniswapv2/libraries/SafeMath.sol


pragma solidity 0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathEureka {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// File: contracts/uniswapv2/libraries/EurekaV2Library.sol


pragma solidity 0.6.12;



library EurekaV2Library {
    using SafeMathEureka for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'EurekaV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'EurekaV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'424b537f41c5fd97af8cd2ff784befd73d77ac7167c8db6730794d4f6b8aa213' // init code hash
                
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IEurekaV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'EurekaV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'EurekaV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'EurekaV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'EurekaV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'EurekaV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'EurekaV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'EurekaV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'EurekaV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/uniswapv2/libraries/TransferHelper.sol


pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/uniswapv2/interfaces/IEurekaV2Router01.sol


pragma solidity 0.6.12;

interface IEurekaV2Router01 {
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

// File: contracts/uniswapv2/interfaces/IEurekaV2Router02.sol


pragma solidity 0.6.12;


interface IEurekaV2Router02 is IEurekaV2Router01 {
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

// File: contracts/uniswapv2/interfaces/IEurekaV2Factory.sol


pragma solidity 0.6.12;

interface IEurekaV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeToSetter(address) external;

    function PERCENT100() external view returns (uint256);

    // function swapFee() external view returns (uint256);
    // function swapAdminFee() external view returns (uint256);
    function SwaptotalFee() external view returns (uint256);
    
    // function adminFee() external view returns (uint256);
    // function farm1Fee() external view returns (uint256);
    // function farm2Fee() external view returns (uint256);
    // function farm3Fee() external view returns (uint256);
    function InOutTotalFee() external view returns (uint256);
  
    // function admin() external view returns (address);
    // function farm1() external view returns (address);
    // function farm2() external view returns (address);
    // function farm3() external view returns (address);
    // function router() external view returns(address);
    function pause() external view returns(bool);

    function maker() external view returns (address);
    function pauseFee(bool status)external;

    
}

// File: contracts/uniswapv2/interfaces/IERC20.sol


pragma solidity 0.6.12;

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

// File: contracts/uniswapv2/interfaces/IWETH.sol


pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/uniswapv2/interfaces/IFarm.sol

pragma solidity 0.6.12;


interface IFarm{
    
     function addLPInfo(
        IERC20 _lpToken
    ) external;

    function addReward(address _lp,uint256 amount) external;

}

interface IMelt{
    function addReward(uint256 amount1) external;
}


interface IBank{
    function addReward(uint256 amount1) external;
}

// File: contracts/uniswapv2/Maker.sol

pragma solidity 0.6.12;








contract Maker {
    using SafeMathEureka for uint256;
    address public factory;
    address public ERK;
    address public router;
    address public feeToSetter;

    // In and out tax. up to 2 decimal
    uint256 public lpFarmFee = 300;
    uint256 public meltPotFee = 100;
    uint256 public bankFee = 100;
    uint256 public adminFee = 100;

    address public admin; // admin recevier address
    mapping(address => address) public lpFarm; // lp stakers
    address public meltPot; // tokenE staking
    address public bank; // tokenL staking

    // swap fee
    uint256 public swapAdminFee = 10; //0.25
    uint256 public swapFee = 15; //0.15
    
    modifier onlyFeeSetter(){
        require(msg.sender == feeToSetter, "FORBIDDEN");   
        _;
    }

    constructor(
        address _factory,
        address _erk,
        address _feeToSetter
    ) public {
        factory = _factory;
        ERK = _erk;
        feeToSetter = _feeToSetter;
    }
    
    event AddLpReceiver(address[] _lp, address[] _feeReceivers);

    function addLpReceiver(address[] calldata lp, address[] calldata feeReceivers) external {
        require(lp.length == feeReceivers.length, "invalid length");
        for(uint i=0; i<lp.length; i++){
            lpFarm[lp[i]] = feeReceivers[i];
        }
        emit AddLpReceiver(lp, feeReceivers);
    }

    function takeLiquidityFee(
        address _lp,
        address _token0,
        address _token1
    ) public returns (bool) {
        if (IEurekaV2Factory(factory).pause()) {
            return (true);
        }
        uint256 fee0 = IERC20(_token0).balanceOf(address(this));
        uint256 fee1 = IERC20(_token1).balanceOf(address(this));

        takeFee(_lp, fee0, _token0);
        takeFee(_lp, fee1, _token1);
     
        return (true);
    }

    function takeFee(address lp, uint256 fee, address token) public {
        uint256 PERCENT = IEurekaV2Factory(factory).InOutTotalFee();

        TransferHelper.safeTransfer(
            token,
            admin,
            fee.mul(adminFee).div(PERCENT)
            );
        if(lpFarm[lp] != address(0x00)){
            TransferHelper.safeTransfer(
            token,
            lpFarm[lp],
            fee.mul(lpFarmFee).div(PERCENT)
            );
        }else{
            TransferHelper.safeTransfer(
            token,
            admin,
            fee.mul(lpFarmFee).div(PERCENT)
            );
        }
        
        TransferHelper.safeTransfer(
            token,
            meltPot,
            fee.mul(meltPotFee).div(PERCENT)
        );
        TransferHelper.safeTransfer(
            token,
            bank,
            fee.mul(meltPotFee).div(PERCENT)
        );
    }
   
    function swapFeeConvert(
        address lp,
        address token,
        uint256 fee
    ) public returns (bool) {
        if (IEurekaV2Factory(factory).pause()) {
            return true;
        }
  
        uint256 adminfee;
        uint256 farmfee;

        adminfee = fee.mul(swapAdminFee).div(swapFee + swapAdminFee);
        farmfee = fee.sub(adminfee);

        TransferHelper.safeTransfer(token, admin, adminfee);
        if(lpFarm[lp] != address(0x000)){
            TransferHelper.safeTransfer(token, lpFarm[lp], farmfee);
        }else{
            TransferHelper.safeTransfer(token, admin, farmfee);
        }
        return true;
    }

    function setRouter(address _router) external onlyFeeSetter {
        router = _router;
    }

    function setInfo(address[2] memory _farm, address _admin) external onlyFeeSetter {
        meltPot = _farm[0]; 
        bank = _farm[1];
        admin = _admin;
    }

    function setSwapFee(uint256 _swapFee, uint256 _swapAdminFee) external onlyFeeSetter {
        swapFee = _swapFee;
        swapAdminFee = _swapAdminFee;
    }

    function setInOutTax(
        uint256 _lpFarmFee,
        uint256 _meltPotFee,
        uint256 _bankFee,
        uint256 _adminFee
    ) external onlyFeeSetter {
        lpFarmFee = _lpFarmFee;
        meltPotFee = _meltPotFee;
        bankFee = _bankFee;
        adminFee = _adminFee;
    }
}

// File: contracts/uniswapv2/EurekaV2Router02.sol


pragma solidity 0.6.12;










contract EurekaV2Router02 is IEurekaV2Router02 {
    using SafeMathEureka for uint;

    address public immutable override factory;
    address public immutable override WETH;
    
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EurekaV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IEurekaV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IEurekaV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = EurekaV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = EurekaV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'EurekaV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = EurekaV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'EurekaV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        address pair = EurekaV2Library.pairFor(factory, tokenA, tokenB);
        (amountA, amountB) = takeAddLiquidityFee(pair, tokenA, tokenB, amountA, amountB, false);
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IEurekaV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        address pair = EurekaV2Library.pairFor(factory, token, WETH);
        (amountToken, amountETH) = takeAddLiquidityFee(pair, token, WETH, amountToken, amountETH, true);
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        IWETH(WETH).deposit{value: amountETH}();
        
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
       
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IEurekaV2Pair(pair).mint(to);      
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = EurekaV2Library.pairFor(factory, tokenA, tokenB);
        IEurekaV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IEurekaV2Pair(pair).burn(to);
        (address token0,) = EurekaV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0); 
        if(amountAMin > 0){
            amountAMin = amountAMin.sub(amountAMin.mul(IEurekaV2Factory(factory).InOutTotalFee()).div(IEurekaV2Factory(factory).PERCENT100()));
        }
        if(amountBMin > 0){
            amountBMin = amountBMin.sub(amountBMin.mul(IEurekaV2Factory(factory).InOutTotalFee()).div(IEurekaV2Factory(factory).PERCENT100()));
        }
        require(amountA >= amountAMin, 'EurekaV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'EurekaV2Router: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = EurekaV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IEurekaV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = EurekaV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IEurekaV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = EurekaV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IEurekaV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = EurekaV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? EurekaV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IEurekaV2Pair(EurekaV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amountIn  = takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]), path[0], amountIn, false);
        amounts = EurekaV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'EurekaV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EurekaV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]), path[0], amountInMax, false);
        amounts = EurekaV2Library.getAmountsIn(factory, amountOut, path);   
        require(amounts[0] <= amountInMax, 'EurekaV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EurekaV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'EurekaV2Router: INVALID_PATH');
        uint256 msgvalue = msg.value;
        IWETH(WETH).deposit{value: msgvalue}();
        msgvalue = takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]) ,path[0], msgvalue, true);
        amounts = EurekaV2Library.getAmountsOut(factory, msgvalue, path);        
        require(amounts[amounts.length - 1] >= amountOutMin, 'EurekaV2Router: INSUFFICIENT_OUTPUT_AMOUNT');      
        assert(IWETH(WETH).transfer(EurekaV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'EurekaV2Router: INVALID_PATH');
        takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]), path[0], amountInMax, false);
        amounts = EurekaV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'EurekaV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EurekaV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'EurekaV2Router: INVALID_PATH');
        amountIn = takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]), path[0], amountIn, false);
        amounts = EurekaV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'EurekaV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EurekaV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'EurekaV2Router: INVALID_PATH');
        uint256 msgValue = msg.value;
        IWETH(WETH).deposit{value: msgValue}();
        msgValue = takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]), path[0], msgValue, true);
        amounts = EurekaV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'EurekaV2Router: EXCESSIVE_INPUT_AMOUNT');
        assert(IWETH(WETH).transfer(EurekaV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        uint256 sfee = msg.value.sub(msgValue);
        if (msg.value > amounts[0].add(sfee)) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0].add(sfee));
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = EurekaV2Library.sortTokens(input, output);
            IEurekaV2Pair pair = IEurekaV2Pair(EurekaV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = EurekaV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? EurekaV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) {
        amountIn = takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]), path[0], amountIn, false);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EurekaV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'EurekaV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'EurekaV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        amountIn = takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]), path[0], amountIn, true);
        assert(IWETH(WETH).transfer(EurekaV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'EurekaV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'EurekaV2Router: INVALID_PATH');
        amountIn = takeSwapFee(IEurekaV2Factory(factory).getPair(path[0], path[1]), path[0], amountIn, false);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EurekaV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'EurekaV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return EurekaV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return EurekaV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return EurekaV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return EurekaV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return EurekaV2Library.getAmountsIn(factory, amountOut, path);
    }

   function takeAddLiquidityFee(address _lp,address _token0, address _token1, uint256 _amount0, uint256 _amount1, bool isEth) internal returns(uint256, uint256){
        if(IEurekaV2Factory(factory).pause()){
            return(_amount0,_amount1);
        }
        address maker = IEurekaV2Factory(factory).maker();
        uint256 fee0; uint256 fee1;
        uint256 PERCENT = IEurekaV2Factory(factory).PERCENT100(); 
        fee0 = _amount0.mul(IEurekaV2Factory(factory).InOutTotalFee()).div(PERCENT);
        fee1 = _amount1.mul(IEurekaV2Factory(factory).InOutTotalFee()).div(PERCENT);

        TransferHelper.safeTransferFrom(_token0, msg.sender,maker, fee0);
        if(!isEth){
            TransferHelper.safeTransferFrom(_token1, msg.sender,maker, fee1);
        }else{
            TransferHelper.safeTransfer(_token1, maker, fee1);
        }

        Maker(maker).takeLiquidityFee(_lp, _token0, _token1);
        _amount0 = _amount0.sub(fee0);
        _amount1 = _amount1.sub(fee1);
        return(_amount0, _amount1);
    
    }
  
    function takeSwapFee(address lp, address token, uint256 amount, bool isEth) internal returns(uint256){
        if(IEurekaV2Factory(factory).pause()){
            return amount;
        }
        uint256 swapTotalFee = amount.mul(IEurekaV2Factory(factory).SwaptotalFee()).div(IEurekaV2Factory(factory).PERCENT100());
        address maker = IEurekaV2Factory(factory).maker();
        if(!isEth){
            TransferHelper.safeTransferFrom(token, msg.sender, maker, swapTotalFee);
        }else{
            TransferHelper.safeTransfer(token, maker, swapTotalFee);
        }
       
        Maker(maker).swapFeeConvert(lp, token, swapTotalFee);
        amount = amount.sub(swapTotalFee);
        return amount;
    }
  

}