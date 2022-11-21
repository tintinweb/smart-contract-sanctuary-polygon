/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IAocoRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    // function addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB, uint liquidity);

    // function addLiquidityETH(
    //     address token,
    //     uint amountTokenDesired,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    // function removeLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB);

    // function removeLiquidityETH(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountToken, uint amountETH);

    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountA, uint amountB);

    // function removeLiquidityETHWithPermit(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountToken, uint amountETH);

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

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IAocoRouter02 is IAocoRouter01 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountETH);

    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountETH);

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

// interface IAocoFactory {
//     event PairCreated(address indexed token0, address indexed token1, address pair, uint);

//     function feeTo() external view returns (address);

//     function feeToSetter() external view returns (address);

//     function getPair(address tokenA, address tokenB) external view returns (address pair);

//     function allPairs(uint) external view returns (address pair);

//     function allPairsLength() external view returns (uint);

//     function createPair(address tokenA, address tokenB) external returns (address pair);

//     function setFeeTo(address) external;

//     function setFeeToSetter(address) external;

//     function INIT_CODE_PAIR_HASH() external view returns (bytes32);

//     function feeList(address) external view returns (uint256 _holderFee, uint256 _devFee, uint256 _totalFee);

//     function useCreatePairWhiteList(address) external view returns (bool);

//     function createPairWhiteList(address) external view returns (address);

//     function useRouterWhiteList(address) external view returns (bool);

//     function useRouterWhiteListMode() external view returns (bool);
// }

contract swapHelper is Ownable {
    using SafeMath for uint256;
    address public WETH;
    IAocoRouter02 public routerAddress;
    address[] public swapRouter;
    address[] public swapRouter2;
    uint256 public approveAmount;
    mapping(address => bool) public callerList;
    mapping(address => uint256) public callerAmountList;

    modifier onlyCaller() {
        require(callerList[msg.sender], "e000");
        _;
    }

    event swapCotE(address _tx_origin, address _msg_sender, uint256 _gasUsed, uint256 _spendSwapInToken, uint256 _timestamp);

    constructor (IAocoRouter02 _routerAddress, address[] memory _swapRouter, address[] memory _swapRouter2, uint256 _amount) {
        setSwapInfo(_routerAddress, _swapRouter, _swapRouter2, _amount);
    }

    function setWETH(address _WETH) external onlyOwner {
        WETH = _WETH;
    }

    function setSwapInfo(IAocoRouter02 _routerAddress, address[] memory _swapRouter, address[] memory _swapRouter2, uint256 _amount) public onlyOwner {
        require(_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1]);
        require(_swapRouter2[0] == _swapRouter[_swapRouter2.length - 1]);
        routerAddress = _routerAddress;
        swapRouter = _swapRouter;
        swapRouter2 = _swapRouter2;
        approveAmount = _amount;
        IERC20(_swapRouter[0]).approve(address(_routerAddress), _amount);
        IERC20(_swapRouter2[0]).approve(address(_routerAddress), _amount);
    }

    function setCallerList(address[] memory _userList, uint256[] memory _amountList, bool _status) external onlyOwner {
        require(_userList.length == _amountList.length, "x001");
        for (uint256 i = 0; i < _userList.length; i++) {
            callerList[_userList[i]] = _status;
            if (_status) {
                callerAmountList[_userList[i]] = _amountList[i];
            } else {
                callerAmountList[_userList[i]] = 0;
            }
        }
    }

    function swapCot() external onlyCaller {
        uint256 startGas = gasleft();
        uint256 _swapIn = callerAmountList[msg.sender];
        if (_swapIn == 0) {
            return;
        } else {
            address swapInToken = swapRouter[0];
            address swapOutToken = swapRouter[1];
            if (IERC20(swapInToken).allowance(address(this), address(routerAddress)) < _swapIn) {
                IERC20(swapInToken).approve(address(routerAddress), approveAmount);
            }
            uint256 balanceOfIn0 = IERC20(swapInToken).balanceOf(address(this));
            uint256 balanceOfOut0 = IERC20(swapOutToken).balanceOf(address(this));
            routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(_swapIn, 0, swapRouter, address(this), block.timestamp);
            uint256 balanceOfOut1 = IERC20(swapOutToken).balanceOf(address(this));
            _swapIn = balanceOfOut1.sub(balanceOfOut0);
            if (IERC20(swapOutToken).allowance(address(this), address(routerAddress)) < _swapIn) {
                IERC20(swapOutToken).approve(address(routerAddress), approveAmount);
            }
            routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(_swapIn, 0, swapRouter2, address(this), block.timestamp);
            uint256 balanceOfIn1 = IERC20(swapInToken).balanceOf(address(this));
            uint256 spendSwapInToken = balanceOfIn0.sub(balanceOfIn1);
            uint256 gasUsed = startGas - gasleft();
            emit swapCotE(tx.origin, msg.sender, gasUsed, spendSwapInToken, block.timestamp);
            //return spendSwapInToken;
        }
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    receive() payable external {}
}