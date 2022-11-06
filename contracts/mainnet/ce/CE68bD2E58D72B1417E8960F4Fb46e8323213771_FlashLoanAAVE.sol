/**
 *Submitted for verification at polygonscan.com on 2022-11-06
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


interface IERC20 {
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function approve(address spender, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}


interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
}


// UniSwap V2 interface
interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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


// KyberSwap V1 interface

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IDMMLiquidityRouter {

}

interface IDMMExchangeRouter {

}

interface IDMMRouter01 is IDMMExchangeRouter, IDMMLiquidityRouter {
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


contract FlashLoanAAVE is Ownable {

    address pool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address buyToken; //token to buy with asset
    IUniswapV2Router02 public sellDexRouter; // sell the loan token
    IUniswapV2Router02 public buyDexRouter; // buy the loan token
    ISwapRouter public uniswapRouter;
    KyberswapV2 public kyberSwapRouterV2;
    KyberswapV1 public kyberSwapRouterV1;
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


    // constructor(address _aaveLendingPool)  {
    //     require(_aaveLendingPool != address(0), "Invalid Pool Address");
    //     pool = _aaveLendingPool;
    // }


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
        buyToken = _buyToken;
        sellAmount = _flashAmount;
        uniswapV3Fee = _uniswapV3Fee; 
        kyberFee = _kyberFee;
        kyberPool = _kyberPool;
        sellUniV3 = _sellDexRouter == uniV3 ? true : false;
        buyUniV3 = _buyDexRouter == uniV3 ? true : false;
        sellKyberV2 = _sellDexRouter == kyberV2 ? true : false;
        buyKyberV2 = _buyDexRouter == kyberV2 ? true : false;
        sellKyberV1 = _sellDexRouter == kyberV1 ? true : false;
        buyKyberV1 = _buyDexRouter == kyberV1 ? true : false;

        if(sellUniV3){
            uniswapV3Fee = _uniswapV3Fee;
            uniswapRouter = ISwapRouter(_sellDexRouter);
        } else if(sellKyberV2){
            kyberFee = _kyberFee;
            kyberSwapRouterV2 = KyberswapV2(_sellDexRouter);
        } else if(sellKyberV1){
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
            kyberSwapRouterV1 = KyberswapV1(_buyDexRouter);
        } else {
            buyDexRouter = IUniswapV2Router02(_buyDexRouter);
        }

        IPool(pool).flashLoanSimple(address(this), _flashAsset, _flashAmount, "0x", 0);
    }


    // callback flashlaon
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool){
        IERC20(asset).approve(msg.sender, amount+premium);

        _sellAsset(asset);
        _buyAsset(asset);
        return true;
    }

    function _sellAsset(address asset_) internal {
        if(sellUniV3){
            _uniswapV3(asset_, true);
        } else if(sellKyberV2){
            _kyberV2(asset_, true);
        } else if(sellKyberV1){
            _kyberV1(asset_, true);
        } else {
            _uniswapV2(asset_, true);
        }
    }


    function _buyAsset(address asset_) internal {
        if(buyUniV3){
            _uniswapV3(asset_, false);
        } else if(buyKyberV2){
            _kyberV2(asset_, false);
        } else if(buyKyberV1){
            _kyberV1(asset_, false);
        } else {
            _uniswapV2(asset_, false);
        }
    }

    // kyberswap V1 contract
    function _kyberV1(address asset_, bool sell) internal {
        IERC20 sellAsset = IERC20(sell ? asset_ : buyToken);
        sellAsset.approve(address(kyberSwapRouterV1), sell ? sellAmount : sellAsset.balanceOf(address(this)));
        address[] memory path;
        address[] memory poolsPath;
        poolsPath = new address[](1);
        poolsPath[0] = kyberPool;
        if(asset_ == sellDexRouter.WETH()) {
            path = new address[](2);
            path[0] = sell ? asset_ : buyToken;
            path[1] = sell ? buyToken : asset_;
        } else {
            path = new address[](3);
            path[0] = sell ? asset_ : buyToken;
            path[1] = sellDexRouter.WETH();
            path[2] = sell ? buyToken : asset_;
        }

        kyberSwapRouterV1.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            sell ? sellAmount : sellAsset.balanceOf(address(this)),
            0,
            poolsPath,
            path,
            address(this),
            block.timestamp
        );
    }


    // kyberswap V2 contract
    function _kyberV2(address asset_, bool sell) internal {
        IERC20 sellAsset = IERC20(sell ? asset_ : buyToken);
        sellAsset.approve(address(kyberSwapRouterV2), sell ? sellAmount : sellAsset.balanceOf(address(this)));
        kyberSwapRouterV2.swapExactInputSingle{value: 0}(
            KyberswapV2.ExactInputSingleParams({
                tokenIn: sell ? asset_ : buyToken,
                tokenOut: sell ? buyToken : asset_,
                fee: kyberFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: sell ? sellAmount : sellAsset.balanceOf(address(this)),
                minAmountOut: 0,
                limitSqrtP: 0
            })
        );
    }


    // uniswap V3 contract
    function _uniswapV3(address asset_, bool sell) internal {
        IERC20 sellAsset = IERC20(sell ? asset_ : buyToken);
        sellAsset.approve(address(uniswapRouter), sell ? sellAmount : sellAsset.balanceOf(address(this)));
        uniswapRouter.exactInputSingle{value: 0}(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: sell ? asset_ : buyToken,
                tokenOut: sell ? buyToken : asset_,
                fee: uniswapV3Fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: sell ? sellAmount : sellAsset.balanceOf(address(this)),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }


    // uniswap V2 contract
    function _uniswapV2(address asset_, bool sell) internal {
        IERC20 sellAsset = IERC20(sell ? asset_ : buyToken);
        sellAsset.approve(address(sellDexRouter), sell ? sellAmount : sellAsset.balanceOf(address(this)));
        address[] memory path;
        if(asset_ == sellDexRouter.WETH()) {
            path = new address[](2);
            path[0] = sell ? asset_ : buyToken;
            path[1] = sell ? buyToken : asset_;
        } else {
            path = new address[](3);
            path[0] = sell ? asset_ : buyToken;
            path[1] = sellDexRouter.WETH();
            path[2] = sell ? buyToken : asset_;
        }

        sellDexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            sell ? sellAmount : sellAsset.balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
    }


	function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function recoverTokens(address tokenAddress) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}
    
	receive() external payable{}
}