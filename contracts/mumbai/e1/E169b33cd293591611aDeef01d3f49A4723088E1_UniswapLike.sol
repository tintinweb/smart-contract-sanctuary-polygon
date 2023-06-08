/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: myuniswap.sol



pragma solidity ^0.8.0;


contract UniswapLike {
    address public tokenAddress;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;
    mapping(address => uint256) public balances;

    event AddLiquidity(address indexed sender, uint256 amount);
    event RemoveLiquidity(address indexed sender, uint256 amount);
    event Swap(address indexed sender, uint256 inputAmount, uint256 outputAmount);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function addLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        uint256 tokenAmount = IERC20(tokenAddress).balanceOf(msg.sender);
        require(tokenAmount >= amount, "Insufficient token balance");

        uint256 liquidityMinted;
        if (totalLiquidity == 0) {
            liquidityMinted = amount;
        } else {
            liquidityMinted = (amount * totalLiquidity) / IERC20(tokenAddress).totalSupply();
        }

        totalLiquidity += liquidityMinted;
        liquidity[msg.sender] += liquidityMinted;
        balances[msg.sender] += amount;

        emit AddLiquidity(msg.sender, amount);
    }

    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(liquidity[msg.sender] >= amount, "Insufficient liquidity");

        uint256 tokenAmount = (amount * IERC20(tokenAddress).totalSupply()) / totalLiquidity;
        require(balances[msg.sender] >= tokenAmount, "Insufficient token balance");

        totalLiquidity -= amount;
        liquidity[msg.sender] -= amount;
        balances[msg.sender] -= tokenAmount;

        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        emit RemoveLiquidity(msg.sender, amount);
    }

    function swap(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient token balance");

        uint256 tokenAmountOut = (amount * IERC20(tokenAddress).balanceOf(address(this))) / balances[msg.sender];
        require(tokenAmountOut > 0, "Invalid swap amount");

        balances[msg.sender] -= amount;
        balances[address(this)] += amount;

        IERC20(tokenAddress).transfer(msg.sender, tokenAmountOut);

        emit Swap(msg.sender, amount, tokenAmountOut);
    }
}