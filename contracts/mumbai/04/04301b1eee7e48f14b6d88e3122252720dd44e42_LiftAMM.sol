/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/LiftAMM.sol


pragma solidity ^0.8.9;


contract LiftAMM {
    uint256 public totalSupply;
    mapping (address => uint256) public balance;

    // Testar criar eventos para praticar
    
    //endereços dos tokens que são negociados
    address public tokenA;
    address public tokenB;

    //balanço do tokens em variável de estado
    uint256 public balanceTokenA; 
    uint256 public balanceTokenB;
    
    uint256 priceSwap;
    uint256 liquidityProviderFee = 3; //fee (0.3%) para os provedores de liquidez (LP)

    //motante de fee dos tokens em variável de estado
    uint256 public amountFeeTokenA; 
    uint256 public amountFeeTokenB;
    

    constructor (address _tokenA, address _tokenB){
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    modifier ensure(uint deadline){
        require(deadline >= block.timestamp, "TRANSACTION: EXPIRED");
        _;
    }

    // Raiz quadrada: https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
    function squareRoot(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }  

    function addLiquidity(uint256 amountADesired, uint256 amountBDesired) external returns (uint256 liquidity) {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        require (totalSupply * amountADesired / balanceA == totalSupply * amountBDesired / balanceB, "Wrong proportion between assets A and B");

        liquidity = squareRoot(amountADesired * amountBDesired);
        totalSupply += liquidity;
        balance[msg.sender] += liquidity;
        balanceTokenA += balanceA;
        balanceTokenB += balanceB;
        priceSwap = balanceA * balanceB;

    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountADesired, uint256 amountBDesired) {   
        require(balance[msg.sender] >= liquidity, "Not enough liquidity for this, amount too big"); 
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));         

        uint divisor = totalSupply / liquidity;
        amountADesired = balanceA / divisor;
        amountBDesired = balanceB / divisor;

        totalSupply -= liquidity;
        balance[msg.sender] -= liquidity;  

        IERC20(tokenA).transfer(msg.sender, amountADesired);
        IERC20(tokenB).transfer(msg.sender, amountBDesired); 
        balanceTokenA -= balanceA;
        balanceTokenB -= balanceB;
        priceSwap = balanceA * balanceB;
    }

    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut, uint deadline) external ensure(deadline) returns (uint256 amountOut) {
        uint256 newBalance;
        uint256 feeAmount;
        uint256 amountInWithFee;

        require(tokenIn == tokenA || tokenIn == tokenB, "TokenIn is not in pool");        

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this)); // X
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this)); // Y

        uint256 k = balanceA * balanceB; // K = X * Y   

        if (tokenIn == tokenA) {
            feeAmount = (amountIn * liquidityProviderFee / 1000);
            amountInWithFee = amountIn + feeAmount;
            IERC20(tokenA).transferFrom(msg.sender, address(this), amountInWithFee);
            newBalance = k / (balanceA + amountIn);
            amountOut = balanceB - newBalance;
            require(amountOut >= minAmountOut, "Minimum amount exceeded");            
            IERC20(tokenB).transfer(msg.sender, amountOut);
            amountFeeTokenA += amountInWithFee - amountIn;
        }
        else {
            feeAmount = (amountIn * liquidityProviderFee / 1000);
            amountInWithFee = amountIn + feeAmount;
            IERC20(tokenB).transferFrom(msg.sender, address(this), amountInWithFee);
            newBalance = k / (balanceB + amountIn);
            amountOut = balanceA - newBalance;
            require(amountOut >= minAmountOut, "Minimum amount exceeded");            
            IERC20(tokenA).transfer(msg.sender, amountOut);
            amountFeeTokenB += amountInWithFee - amountIn;
        }      
    }
}