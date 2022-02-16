/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// File: contracts/uniswapv2/libraries/SafeMath.sol

// SPDX-License-Identifier: GPL-3.0


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
    function pauseFee(bool status)external;

    function PERCENT100() external view returns (uint256);
    function SwaptotalFee() external view returns (uint256);   
    function InOutTotalFee() external view returns (uint256);  
    function pause() external view returns(bool);
    function maker() external view returns (address);
    function whiteList(address token) external view returns(bool);
    function feeReceiver() external view returns(address);
    function tfee() external view returns(uint256);

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