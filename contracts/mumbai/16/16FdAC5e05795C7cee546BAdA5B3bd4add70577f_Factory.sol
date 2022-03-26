// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Exchange.sol";
import "./Oracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Factory {
    address public owner;
    address[] public exchageAddresses;
    event CreateExchange(address indexed creator, address exchangeAddress, address token0, address token1, uint256 indexed timestamp);

    modifier onlyOwner {
        require(msg.sender == owner, 'Factory: NOT_OWNER');
        _;
    }
    function createExchange(address token0, address token1, uint256 token0Amount, uint256 token1Amount, uint256 time) external returns(bool) {
        Oracle oracle = new Oracle();
        uint256 token0Price = oracle.currentPriceOfToken();
        uint256 token1Price = oracle.currentPriceOfToken();
        Exchange exchange = new Exchange(token0, token1, token0Amount, token1Amount, token0Price, token1Price, block.timestamp + time, address(oracle));
        IERC20(token0).transfer(address(exchange), token0Amount);
        IERC20(token1).transfer(address(exchange), token1Amount);
        exchageAddresses.push(address(exchange));
        emit CreateExchange(msg.sender, address(exchange), token0, token1, block.timestamp);
        return true;
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Oracle {
    uint256 nonce = 0;
    function currentPriceOfToken() public returns(uint256) {
        nonce += 1;
        return uint(keccak256(abi.encodePacked(nonce))) % 100;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Oracle.sol";

contract Exchange {
    address public token0;
    address public token1;
    uint256 public endTime;
    mapping(address => uint256) public tokenPrice;
    mapping(address => uint256) public tokenAmount;
    address public oracle;
    uint256 private lock = 0;
    address public immutable owner;
    
    event Swap(address swapper, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 timestamp);

    constructor(address _token0, address _token1, uint256 _token0Amount, uint256 _token1Amount, uint256 _token0Price, uint256 _token1Price, uint256 _endTime, address _oracle) {
        token0 = _token0;
        token1 = _token1;
        tokenPrice[_token0] = _token0Price;
        tokenPrice[_token1] = _token1Price;
        tokenAmount[_token0] = _token0Amount;
        tokenAmount[_token1] = _token1Amount;
        endTime = _endTime;
        oracle = _oracle;
        owner = tx.origin;
    }

    modifier isLock {
        require(lock == 0, 'Exchange: IS_CALLED');
        lock = 1;
        _;
        lock = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'Echange: NOT_OWNER');
        _;
    }

    function _updatePrice(address tokenIn, address tokenOut) internal returns(bool) {
        tokenPrice[tokenIn] = Oracle(oracle).currentPriceOfToken();
        tokenPrice[tokenOut] = Oracle(oracle).currentPriceOfToken();
        return true;
    }

    function _getAmountOut(address tokenIn, uint256 amountIn, address tokenOut) internal view returns(uint256) {
        return amountIn / tokenPrice[tokenIn] * tokenPrice[tokenOut];
    }

    function swap(address tokenIn, uint256 amountIn, address tokenOut, address to) external isLock returns(bool) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        if(block.timestamp > endTime) {
            _updatePrice(tokenIn, tokenOut);
        }
        uint256 amountOut = _getAmountOut(tokenIn, amountIn, tokenOut);
        IERC20(tokenOut).transfer(to, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, block.timestamp);
        return true;
    }

    function getToken() external onlyOwner isLock returns(bool) {
        uint256 token0Total = IERC20(token0).balanceOf(address(this));
        uint256 token1Total = IERC20(token1).balanceOf(address(this));
        IERC20(token0).transfer(msg.sender, token0Total);
        IERC20(token1).transfer(msg.sender, token1Total);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}