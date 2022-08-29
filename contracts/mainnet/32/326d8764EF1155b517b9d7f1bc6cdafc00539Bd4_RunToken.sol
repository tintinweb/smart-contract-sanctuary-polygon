// SPDX-License-Identifier: MIT
pragma solidity  ^0.6.0;
import './SafeMath.sol';
import './IERC20.sol';
import './ERC20.sol';
import './Context.sol';
import './Ownable.sol';

interface IidoRun {
    function  idoback(uint256 token0Amt , address wal) external   returns (uint256);



}
interface IPancakeSwapRouter{
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

interface IPancakeSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract RunToken is ERC20("RunToken", "Run6"), Ownable{
    using SafeMath for uint256;
    uint256 public constant maxSupply =  10**18 *50000000;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public startSellingTime;
    uint256 public sellburnRate =  200;

    uint256 public constant burnRateMax = 10000;
     uint256 public constant burnRateUL = 2000;

    mapping(address => bool) public MarketMakerPairs;

    address public pair;
    address BACKADDR = 0x000000000000000000000000000000000000eFef;
    address public IDOBACK;
    IPancakeSwapRouter public router;
   // address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public    WBNB = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address gov = 0x6810553Ee8542033acEbcdDc47716B7CC8378E55;

    constructor(address _IDOBACK,address _router) public  {

        router = IPancakeSwapRouter( _router);
         pair = IPancakeSwapFactory(router.factory()).createPair(
            WBNB,
            address(this)
        );
        MarketMakerPairs[pair] = true;
        IDOBACK = _IDOBACK;
    }

    function mint(address _to, uint256 _amount) external  onlyOwner returns (bool) {

        if (_amount.add(totalSupply()) > maxSupply) {
            return false;
        }
        _mint(_to, _amount);
        return true;

    }
    function setStartSellingTime(uint256 _time) public onlyOwner{
        require(msg.sender == gov, "!gov");
        startSellingTime = _time;

    }
    function setGov(address _address) external {
       require(msg.sender == gov, "!gov");
       gov = _address;

    }
    function setBurnRate(uint256 _sellburnRate)  external {
        require(msg.sender == gov, "!gov");

        require(_sellburnRate <= burnRateUL, "too high");

        sellburnRate = _sellburnRate;

    }

     function _transfer(address sender, address recipient, uint256 amount) internal virtual override {



        uint256 burnRate = 0;
        if(recipient ==  BACKADDR)//ido back
        {

            super._transfer(sender, IDOBACK, amount);
            IidoRun(IDOBACK).idoback(amount,sender);



            return;
        }



        if(MarketMakerPairs[recipient])//sell
        {
             burnRate = sellburnRate;
             require(startSellingTime>0&&block.timestamp>=startSellingTime,"can not sell now!");
        }


        uint256  burnAmt = amount.mul(burnRate).div(10000);
        amount = amount.sub(burnAmt);
        super._transfer(sender, recipient, amount);
        if(burnAmt>0)
        {
            super._transfer(sender, burnAddress, burnAmt);
        }

    }




}