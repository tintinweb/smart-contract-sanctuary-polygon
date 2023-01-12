/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// ERC20 standarization interface
interface IERC20 {
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function approve(address spender, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


// AAVE flashloan interface
interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}


// UniSwap V2 interface
interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function getAmountsOut(
        uint256 amountIn, 
        address[] memory path
    ) external view returns (
        uint256[] memory amounts
    );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        uint256 amount0Out,	
        uint256 amount1Out,	
        address to,	
        bytes calldata data
    ) external;

    function getReserves() external view returns (
        uint112 reserve0, 
        uint112 reserve1, 
        uint32 blockTimestampLast
    );
}


// UniSwap V3 interface
interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

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
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}



// KyberSwap V1 interface (classic)
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface IDMMRouter01{
    function factory() external pure returns (address);
    function weth() external pure returns (IWETH);
}

interface KyberswapV1 is IDMMRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


// KyberSwap V2 interface
interface KyberswapV2SwapCallback {
    function swapCallback(
        int256 deltaQty0,
        int256 deltaQty1,
        bytes calldata data
    ) external;
}

interface KyberswapV2 is KyberswapV2SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
        uint160 limitSqrtP;
    }
    function swapExactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}


contract arbitrageSwap is Ownable {
    using SafeMath for uint256;
    address pool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address buyToken;
    IUniswapV2Router02 sellDexRouter;
    IUniswapV2Router02 buyDexRouter;
    ISwapRouter uniswapRouter;
    KyberswapV2 kyberSwapRouterV2;
    KyberswapV1 kyberSwapRouterV1;
    uint256 sellAmount;
    bool sellUniV3;
    bool buyUniV3;
    bool sellKyberV2;
    bool buyKyberV2;
    bool sellKyberV1;
    bool buyKyberV1;
    uint24 uniswapV3Fee; 
    uint24 kyberFee;
    address kyberPool;
    address uniV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address kyberV1 = 0x546C79662E028B661dFB4767664d0273184E4dD1;
    address kyberV2 = 0xC1e7dFE73E1598E3910EF4C7845B68A9Ab6F4c83;
    uint256 originalBalance;

    function setParams(
        uint256 _flashAmount,
        address _buyToken,
        address _sellDexRouter,
        address _buyDexRouter,
        uint24 _uniswapV3Fee,
        uint24 _kyberFee,
        address _kyberPool
    ) internal {
        buyToken = _buyToken;
        sellAmount = _flashAmount;

        sellUniV3 = _sellDexRouter == uniV3 ? true : false;
        buyUniV3 = _buyDexRouter == uniV3 ? true : false;

        sellKyberV2 = _sellDexRouter == kyberV2 ? true : false;
        buyKyberV2 = _buyDexRouter == kyberV2 ? true : false;

        sellKyberV1 = _sellDexRouter == kyberV1 ? true : false;
        buyKyberV1 = _buyDexRouter == kyberV1 ? true : false;

        originalBalance = IERC20(_buyToken).balanceOf(address(this));

        if(sellUniV3){
            uniswapV3Fee = _uniswapV3Fee;
            uniswapRouter = ISwapRouter(_sellDexRouter);
        } else if(sellKyberV2){
            kyberFee = _kyberFee;
            kyberSwapRouterV2 = KyberswapV2(_sellDexRouter);
        } else if(sellKyberV1){
            kyberPool = _kyberPool;
            kyberSwapRouterV1 = KyberswapV1(_sellDexRouter);
        } else {
            sellDexRouter = IUniswapV2Router02(_sellDexRouter);
        }

        if(buyUniV3){
            uniswapV3Fee = _uniswapV3Fee;
            uniswapRouter = ISwapRouter(_buyDexRouter);
        } else if(buyKyberV2){
            kyberFee = _kyberFee;
            kyberSwapRouterV2 = KyberswapV2(_buyDexRouter);
        } else if(buyKyberV1){
            kyberPool = _kyberPool;
            kyberSwapRouterV1 = KyberswapV1(_buyDexRouter);
        } else {
            buyDexRouter = IUniswapV2Router02(_buyDexRouter);
        }
    }

    function dualDexSwap(
        address _flashAsset, 
        uint256 _flashAmount,
        address _buyToken,
        address _sellDexRouter,
        address _buyDexRouter,
        uint24 _uniswapV3Fee,
        uint24 _kyberFee,
        address _kyberPool
    ) external onlyOwner {
        require(_sellDexRouter != _buyDexRouter, "Invalid swap, same router buy/sell");

        setParams(_flashAmount, _buyToken, _sellDexRouter, _buyDexRouter, _uniswapV3Fee, _kyberFee, _kyberPool);

        _sellAsset(_flashAsset);
        _buyAsset(_flashAsset);
    }

    function flashloan (
        address _flashAsset, 
        uint256 _flashAmount,
        address _buyToken,
        address _sellDexRouter,
        address _buyDexRouter,
        uint24 _uniswapV3Fee,
        uint24 _kyberFee,
        address _kyberPool
    ) external onlyOwner{

        require(_sellDexRouter != _buyDexRouter, "Invalid swap, same router buy/sell");
        
        setParams(_flashAmount, _buyToken, _sellDexRouter, _buyDexRouter, _uniswapV3Fee, _kyberFee, _kyberPool);

        IPool(pool).flashLoanSimple(address(this), _flashAsset, _flashAmount, "0x", 0);
    }

    event ExecuteFlashloan(address indexed initiator, bytes params);

    // callback flashlaon
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool){
        IERC20(asset).approve(msg.sender, amount+premium);

        emit ExecuteFlashloan(initiator, params);

        _sellAsset(asset);
        _buyAsset(asset);

        return true;
    }


    function _sellAsset(address asset_) internal {
        if(sellUniV3){
            return _uniswapV3(asset_, true);
        } else if(sellKyberV2){
            return _kyberV2(asset_, true);
        } else if(sellKyberV1){
            return _kyberV1(asset_, true);
        } else {
            return _uniswapV2(asset_, true);
        }
    }


    function _buyAsset(address asset_) internal {
        if(buyUniV3){
            return _uniswapV3(asset_, false);
        } else if(buyKyberV2){
            return _kyberV2(asset_, false);
        } else if(buyKyberV1){
            return _kyberV1(asset_, false);
        } else {
            return _uniswapV2(asset_, false);
        }
    }


    // kyberswap V1 contract
    function _kyberV1(address asset_, bool sell) internal {
        IERC20 sellAsset = IERC20(sell ? asset_ : buyToken);
        sellAsset.approve(address(kyberSwapRouterV1), sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance));
        address[] memory path;
        address[] memory poolsPath;
        poolsPath = new address[](1);
        poolsPath[0] = kyberPool;

        path = new address[](2);
        path[0] = sell ? asset_ : buyToken;
        path[1] = sell ? buyToken : asset_;

        kyberSwapRouterV1.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance),
            0,
            poolsPath,
            path,
            address(this),
            block.timestamp
        );
    }


    // uniswap V2 contract
    function _uniswapV2(address asset_, bool sell) internal {
        IERC20 sellAsset = IERC20(sell ? asset_ : buyToken);
        sellAsset.approve(address(sell ? sellDexRouter : buyDexRouter), sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance));
        address[] memory path;

        path = new address[](2);
        path[0] = sell ? asset_ : buyToken;
        path[1] = sell ? buyToken : asset_;

        if(sell){
            sellDexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance),
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            buyDexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance),
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }


    // uniswap V3 contract
    function _uniswapV3(address asset_, bool sell) internal {
        IERC20 sellAsset = IERC20(sell ? asset_ : buyToken);
        sellAsset.approve(address(uniswapRouter), sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance));
        uniswapRouter.exactInputSingle{value: 0}(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: sell ? asset_ : buyToken,
                tokenOut: sell ? buyToken : asset_,
                fee: uniswapV3Fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }

    // kyberswap V2 contract
    function _kyberV2(address asset_, bool sell) internal {
        IERC20 sellAsset = IERC20(sell ? asset_ : buyToken);
        sellAsset.approve(address(kyberSwapRouterV2), sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance));
        kyberSwapRouterV2.swapExactInputSingle{value: 0}(
            KyberswapV2.ExactInputSingleParams({
                tokenIn: sell ? asset_ : buyToken,
                tokenOut: sell ? buyToken : asset_,
                fee: kyberFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: sell ? sellAmount : sellAsset.balanceOf(address(this)).sub(originalBalance),
                minAmountOut: 0,
                limitSqrtP: 0
            })
        );
    }

    function changeLoanPool(address _pool) external onlyOwner {
		pool = _pool;
	}

    function getBalance (address _tokenContractAddress) external view returns (uint256) {
		uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}

	function recoverEth(bool _all, uint256 _amount) external onlyOwner {
		payable(msg.sender).transfer(_all ? address(this).balance : _amount);
	}

	function recoverTokens(address tokenAddress, bool _all, uint256 _amount) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, _all ? token.balanceOf(address(this)) : _amount);
	}

	receive() external payable{}
}