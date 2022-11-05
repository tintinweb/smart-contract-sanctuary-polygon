/**
 *Submitted for verification at polygonscan.com on 2022-11-05
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

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// ERC20 standard
interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


// AAVE Flashloan
interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}


// UniSwap V3
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


// KyberSwap V2
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


// FlashLoan contract
contract FlashLoanAAVE is Ownable {

    address pool;
    address public buyToken; //token to buy with asset
    // IUniswapV2Router02 public sellDexRouter; // sell the loan token
    // IUniswapV2Router02 public buyDexRouter; // buy the loan token
    ISwapRouter public uniswapRouter;
    KyberswapV2 public kyberSwapRouter;
    uint256 sellAmount;
    bool public sellV3;
    bool public buyV3;
    uint24 public uniswapV3Fee;
    bool public sellKyberV2;
    bool public buyKyberV2;
    uint24 public kyberFee;


    constructor(address _aaveLendingPool) {
        require(_aaveLendingPool != address(0), "Invalid Pool Address");
        pool = _aaveLendingPool;
    }
    
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


    // sell the flash loan asset to buyTokenUsingAsset from sellDexRouter
    function _sellAsset(address asset_) internal {
        IERC20 sellAsset = IERC20(asset_);

        if(sellV3){
            sellAsset.approve(address(uniswapRouter), sellAmount);
            uniswapRouter.exactInputSingle{value: 0}(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: asset_,
                    tokenOut: buyToken,
                    fee: uniswapV3Fee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: sellAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            
        } else if(sellKyberV2){
            sellAsset.approve(address(kyberSwapRouter), sellAmount);
            kyberSwapRouter.swapExactInputSingle{value: 0}(
                KyberswapV2.ExactInputSingleParams({
                    tokenIn: asset_,
                    tokenOut: buyToken,
                    fee: kyberFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: sellAmount,
                    minAmountOut: 0,
                    limitSqrtP: 0
                })
            );

        }
    }

    // buy asset using buyTokenUsingAsset from buyDexRouter
    function _buyAsset(address asset_) internal {
        IERC20 buyAsset = IERC20(buyToken);
        if(buyV3){
            buyAsset.approve(address(uniswapRouter), buyAsset.balanceOf(address(this)));
            uniswapRouter.exactInputSingle{value: 0}(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: buyToken,
                    tokenOut: asset_,
                    fee: uniswapV3Fee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: buyAsset.balanceOf(address(this)),
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        } else if(buyKyberV2){
            buyAsset.approve(address(kyberSwapRouter), buyAsset.balanceOf(address(this)));
            kyberSwapRouter.swapExactInputSingle{value: 0}(
                KyberswapV2.ExactInputSingleParams({
                    tokenIn: buyToken,
                    tokenOut: asset_,
                    fee: kyberFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: buyAsset.balanceOf(address(this)),
                    minAmountOut: 0,
                    limitSqrtP: 0
                })
            );
        }

    }


    function flashloan (
        address _flashAsset, 
        uint256 _flashAmount,
        address _buyToken,
        address _sellDexRouter,
        address _buyDexRouter,
        bool _sellUniswapV3,
        bool _buyUniswapV3,
        uint24 _uniswapV3Fee,
        bool _sellKyberV2,
        bool _buyKyberV2,
        uint24 _kyberFee
    ) external onlyOwner{
        buyToken = _buyToken;
        // sellDexRouter = IUniswapV2Router02(_sellDexRouter);
        // buyDexRouter = IUniswapV2Router02(_buyDexRouter);
        sellV3 = _sellUniswapV3;
        buyV3 = _buyUniswapV3;
        uniswapV3Fee = _uniswapV3Fee;
        sellAmount = _flashAmount;
        sellKyberV2 = _sellKyberV2;
        buyKyberV2 = _buyKyberV2;
        kyberFee = _kyberFee;


        if(sellV3){
            uniswapRouter = ISwapRouter(_sellDexRouter);
        }
        if(buyV3){
            uniswapRouter = ISwapRouter(_buyDexRouter);
        }
        if(sellKyberV2){
            kyberSwapRouter = KyberswapV2(_sellDexRouter);
        }
        if(buyKyberV2){
            kyberSwapRouter = KyberswapV2(_buyDexRouter);
        }

        IPool(pool).flashLoanSimple(address(this), _flashAsset, _flashAmount, "0x", 0);
    }

	function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, amount);
	}
    
	receive() external payable{}
}