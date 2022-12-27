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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Import this file to use console.log
//import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiftAMM { 
    uint256 public totalSupply;
    mapping(address => uint256) public balance; 

    address public tokenA;
    address public tokenB;
    constructor(address _tokenA, address _tokenB) { 
        require(_tokenA != address(0), "Token A address could not be 0x!"); 
        require(_tokenB != address(0), "Token B address could not be 0x!"); 
        tokenA = _tokenA;
        tokenB = _tokenB;   
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

    //pode criar um modifier para o deadline

    function addLiquidity(uint256 amountA, uint256 amountB, uint256 deadline) external returns (uint256 liquidity) {       
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        require(deadline < deadline + 5 minutes, "Timeout for this transaction");

        require(totalSupply * amountA / balanceA == totalSupply * amountB / balanceB, "Wrong proportion between asset A and B");

        liquidity = squareRoot(amountA * amountB);
        totalSupply += liquidity;
        balance[msg.sender] += liquidity;        
    }

    function removeLiquidity(uint256 liquidity, uint deadline) external returns (uint256 amountA, uint256 amountB) {   
        require(balance[msg.sender] >= liquidity, "Not enough liquidity for this, amount too big"); 
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        require(deadline < deadline + 5 minutes, "Timeout for this transaction");        

        uint divisor = totalSupply / liquidity;
        amountA = balanceA / divisor;
        amountB = balanceB / divisor;

        totalSupply -= liquidity;
        balance[msg.sender] -= liquidity;

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB); 
    }

    function swap(address tokenIn, uint256 amountIn, uint256 deadline) external returns (uint256 amountOut) {
        uint256 newBalance;
        uint256 newBalanceMax;
        uint256 amountOutStd;
        uint256 minAmountOut;
        require(tokenIn == tokenA || tokenIn == tokenB, "TokenIn not in pool");
        require(amountIn > 0, "Insufficient funds");
        
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this)); // X
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this)); // Y

        require(deadline < deadline + 5 minutes, "Timeout for this transaction");

        uint256 k = balanceA * balanceB; // K = X * Y

        if (tokenIn == tokenA) {
            require(amountIn < balanceA, "Insufficient Liquidity A");
            IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
            /**
            Criou-se a variável newBalanceMax:
            no denominador foi acrescido 5% - essa variável cria um controle
            Para que não haja um swap maior que 5%
            Depois foi comparado  o newBalance com o newBalanceMax; 
            Se o newBalance for MENOR significa que o swap irá ocorrer fora da margem
            de controle de 5% - assim o valor amountOut será igual a minAmountOut
            com o objetivo de proteger o usuário e fazer o swap dentro da tolerancia (slippage protection)
            de 5%
             */
            newBalance = k / (balanceA + amountIn);
            newBalanceMax = k / (105 * (balanceA + amountIn) / 100);

            amountOutStd = balanceB - newBalance;
            minAmountOut = balanceB - newBalanceMax;

            if(newBalance < newBalanceMax) {
                amountOut = minAmountOut;
            } else {
                amountOut = amountOutStd;
            }

            IERC20(tokenB).transfer(msg.sender, amountOut);
        }
        else {
            require(amountIn < balanceB, "Insufficient Liquidity B");
            IERC20(tokenB).transferFrom(msg.sender, address(this), amountIn);
            newBalance = k / (balanceB + amountIn);
            newBalanceMax = k / (105 * (balanceB + amountIn) / 100);
            
            amountOutStd = balanceB - newBalance;
            minAmountOut = balanceB - newBalanceMax;

            if(newBalance < newBalanceMax) {
                amountOut = minAmountOut;
            } else {
                amountOut = amountOutStd;
            }
            
            IERC20(tokenA).transfer(msg.sender, amountOut);
        }      
    }
}