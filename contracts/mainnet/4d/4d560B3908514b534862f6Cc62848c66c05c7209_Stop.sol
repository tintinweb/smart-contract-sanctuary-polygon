// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract Stop {

    constructor () public {
        owner = payable(msg.sender);
        enterFees = 100;
        leaveFees = 200;
        deadline = 30000;
    }

    event OrderCalled(address, address, address, uint, address);
    event BuyOrderCalled(address, address, address, uint, address);
    event Approved(address, address, uint);
    event OrderSet(address, address, uint, uint, address);
    event BuyOrderSet(address, address, address, uint, uint, address);
    event MarketBuy(address, address, address, address, uint);

    mapping(address => mapping(address => uint)) orders;
    address USD = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address payable owner;
    uint enterFees;
    uint leaveFees;
    uint deadline;
    address cttAddress = address(this);

    /**
    * @dev modifier to owner access
     */

     modifier onlyOwner{
        require(msg.sender == owner, "Hey hey hey you can't use this function");
        _;
     }

    /**
    * @dev function to pass ownership
    * @param _address address that should be the new owner
     */

    function transferOwnership(address payable _address) external onlyOwner {
        owner = _address;
    }

    /**
    * @dev function to set the enter fees
    * @param _fees value of the fees divided per 100
     */

    function setEnterFees(uint _fees) external onlyOwner returns(bool){
        enterFees = _fees;
        return true;
    }

    /**
    * @dev function to set the leave fees
    * @param _fees value of the fees divided per 100
     */

    function setLeaveFees(uint _fees) external onlyOwner returns(bool){
        leaveFees = _fees;
        return true;
    }

    /**
    * @dev set deadline
    * @param _deadline deadline as uiny;
    */

    function setDeadline(uint _deadline) external onlyOwner returns(bool){
        deadline = _deadline;
        return true;
    }    


    /**
    * @dev set order and pay the fees
    * @param _router address associated
    * @param _token address of the token to be selled
    * @param _amount of the order
    * @param _trigger value to trigger the function
    * @param _feeTo address to split the fees to  
     */

    function setSellOrder(address _router, address _token, uint _amount, uint _trigger, address _feeTo) external {
        address WETH =  IUniswapV2Router02(_router).WETH();
        IERC20 token = IERC20(_token);
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;        
        uint ttl = block.timestamp + deadline;
        uint fees = (_amount / 10000) * enterFees;
        uint chargedAmount = _amount - fees;
        uint splitFee = fees / 2;
        token.transferFrom(msg.sender, cttAddress, fees);
        token.approve(_router, fees);
        IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(fees, 0, path, cttAddress, ttl);
        token.transfer(owner, splitFee);
        token.transfer(_feeTo, splitFee);
        emit OrderSet(_router, _token, chargedAmount, _trigger, _feeTo);
    }

    /**
    * @dev set order and pay the fees
    * @param _router address associated
    * @param _token0 address of the token to be selled
    * @param _token1 address of output token
    * @param _trigger value to trigger the function
    * @param _feeTo address to split the fees to
     */

    function setBuyOrder(address _router, address _token0, address _token1, uint _amount, uint _trigger, address _feeTo) external payable {
        address WETH =  IUniswapV2Router02(_router).WETH();
        require(_token0 == WETH || _token0 == USD, 'Only WMATIC or TETHER avaiable');
        uint ttl = block.timestamp + deadline;        
        IERC20 token0 =  IERC20(_token0);
        address[] memory path = new address[](2);
        path[0] = _token0;
        path[1] = _token1;                
        uint fees = (_amount / 10000) * enterFees;
        uint chargedAmount = _amount - fees;
        uint splitFee = fees / 2;
        token0.transferFrom(msg.sender, cttAddress, fees);
        token0.transfer(owner, splitFee);
        token0.transfer(_feeTo, splitFee);
        IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(chargedAmount ,0, path, msg.sender, ttl);
        emit BuyOrderSet(_router, _token0, _token1, chargedAmount, _trigger, _feeTo);
    }     

    /**
    * @dev function to trigger order to be called externaly from a backend script. Needs to be checked from block to block if the 
      params are fullfilled then should be triggered.
    * @param _router string that represents the router to be called. For each string representing the router there's a address associdated
    * @param _token address of the token to be selled
    * @param _trader address that will receive the ether from the order execution
    * @param _amount of the order
    * @param _feeTo address who splits fees with owner       
     */ 

    function triggerSellOrder(address _router, address _token, address _trader, uint _amount, address _feeTo) external payable onlyOwner {
        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        IERC20 token = IERC20(_token);
        address WETH =  router.WETH();
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;
        uint ttl = block.timestamp + deadline;
        uint[] memory amountOut = router.getAmountsOut(_amount, path);        
        uint fees = (amountOut[1] / 10000) * leaveFees;
        uint splitFees = fees / 2;
        uint chargedAmount = _amount - fees;    
        token.approve(_router, chargedAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, 0, path, cttAddress, ttl);
        payable(_trader).transfer(chargedAmount);
        payable(_feeTo).transfer(splitFees);
        payable(owner).transfer(splitFees);
        emit OrderCalled(_router, _token, _trader, _amount, _feeTo);
    }

        /**
    * @dev function to trigger order to be called externaly from a backend script. Needs to be checked from block to block if the 
      params are fullfilled then should be triggered.
    * @param _router string that represents the router to be called. For each string representing the router there's a address associdated
    * @param _token address of the token to be selled
    * @param _trader address that will receive the ether from the order execution
    * @param _amount of the order 
    * @param _feeTo address who splits fees with owner 
     */ 

    function triggerBuyOrder(address _router, address _token, address _trader, uint _amount, address _feeTo) external payable onlyOwner {
        IERC20 token = IERC20(_token);
        address WETH =  IUniswapV2Router02(_router).WETH();    
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;
        uint ttl = block.timestamp + deadline;          
        uint fees = (_amount / 10000) * leaveFees;
        uint splitFees = fees / 2;
        uint chargedAmount = _amount - fees;
        token.approve(_router, _amount);
        IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(chargedAmount, 0, path, cttAddress, ttl);
        token.transfer(owner, splitFees);
        token.transfer(_feeTo, splitFees);
        token.transfer(_trader, chargedAmount);
        emit BuyOrderCalled(_router, _token, _trader, _amount, _feeTo);
    }

    /**
    * @param _router router of the dex
    * @param _token token address
    * @param _feeTo address of the fee receiver
     */

    function marketBuy(address _router, address _token, address _feeTo) external payable {
        IERC20 token = IERC20(_token);
        address WETH =  IUniswapV2Router02(_router).WETH();               
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;
        uint ttl = block.timestamp + deadline;
        uint _amount = msg.value;          
        uint fees = (_amount / 10000) * enterFees;
        uint chargedAmount = _amount - fees;
        uint splitFees = fees / 2;
        owner.transfer(splitFees);
        payable(_feeTo).transfer(splitFees);
        token.approve(_router, chargedAmount);
        IUniswapV2Router02(_router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: chargedAmount}(0, path, msg.sender, ttl);            
        emit MarketBuy(_router, _token, msg.sender, _feeTo, _amount);
    }   

    /**
    * @param _router router of the dex
    * @param _token token address
    * @param _amount amount of tokens
    * @param _feeTo address of the fee receiver
     */


    function marketSell(address _router, address _token, uint _amount, address _feeTo) external payable { 
        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        address WETH =  router.WETH();     
        IERC20 token = IERC20(_token);        
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;
        uint ttl = block.timestamp + deadline;          
        token.approve(_router, _amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, 0, path, cttAddress, ttl);
        uint[] memory amountOut = router.getAmountsOut(_amount, path);
        uint fees = (amountOut[1] / 10000) * enterFees;
        uint chargedAmount = amountOut[1] - fees;
        uint splitFees = fees / 2;
        payable(msg.sender).transfer(chargedAmount);
        payable(_feeTo).transfer(splitFees);
        owner.transfer(splitFees);
        emit MarketBuy(_router, _token, msg.sender, _feeTo, amountOut[1]);
    }

    function withdrawn() external onlyOwner returns(bool){
        owner.transfer(cttAddress.balance);
        return true;
    }

    function withdrawnAsset(address _token) external onlyOwner returns(bool){
        IERC20 token = IERC20(_token);
        uint amount = token.balanceOf(cttAddress);
        IERC20(_token).transfer(owner, amount);
        return true;
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}