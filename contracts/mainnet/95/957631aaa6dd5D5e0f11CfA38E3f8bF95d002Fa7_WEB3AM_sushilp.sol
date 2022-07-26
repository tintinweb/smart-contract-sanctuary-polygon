// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

// @web3assetmanager:security-contact [email protected]

// Link for sushiswap dev docs- https://dev.sushi.com/sushiswap/contracts 
// Factory consist of all read operations for sushiswap (i.e getPair, reserves)
// Router consist of all write operations for sushiswap (i.e addliquidity)


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WEB3AM_sushilp is Ownable {

    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Router02 public immutable uniswapV2Router;
    //token add of WETH
    address public WETH ;

    constructor(address _routerSushi) {
        // the router address is the sushiv2Router address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerSushi);
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        // NOTE :  same contract can be used for uniswap just need to change the above mentioned Router address 

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
         WETH=_uniswapV2Router.WETH();
    }

    event liquidityadded(address user, address token1, address address2, uint tokenAamount, uint tokenBamount);
    event liquidityremove(address user, address pairAddress, uint lptoken);
    event liquidityaddedETH(address user, address token, uint amountToken, uint amountETH);
    event liquidityremoveETH(address user, address pairAddress, uint lptoken);

     // @dev Add Liquidity Function ,if user has both the tokens 
    function addLiquidity(address _tokenA, address _tokenB, uint _amountA, uint _amountB,uint _amountAmin,uint _amountBmin,uint _timestamp) public {
        require(_amountA > 0, "Less TokenA Supply");
        require(_amountB > 0, "Less TokenB Supply");
        require(_tokenA != address(0), "DeAd address not allowed");
        require(_tokenB != address(0), "DeAd address not allowed");
        require(_tokenA != _tokenB, "Same Token not allowed");
        IERC20 tokenA = IERC20(_tokenA);
        IERC20 tokenB = IERC20(_tokenB);
        require(CheckAllowance(tokenA) >= _amountA ,"Less Supply");
        require(CheckAllowance(tokenB) >= _amountB ,"Less Supply");
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);
        // @dev : Approving Router Contract by TokenA and TokenB 
        tokenA.approve(address(uniswapV2Router), _amountA);
        tokenB.approve(address(uniswapV2Router), _amountB);
        uniswapV2Router.addLiquidity(
            _tokenA,//A pool token.
            _tokenB,//A pool token.
            _amountA,//The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
            _amountB,//The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
            _amountAmin,//Bounds the extent to which the B/A price can go up before the transaction reverts. Must be <= amountADesired.
            _amountBmin,//Bounds the extent to which the A/B price can go up before the transaction reverts. Must be <= amountBDesired.
            msg.sender,//Recipient of the liquidity tokens.
            _timestamp//Unix timestamp after which the transaction will revert.
        );
        emit liquidityadded(msg.sender, _tokenA, _tokenB, _amountA, _amountB);
    }
    
    // @dev Add Liquidity with ETH 
    function addLiquidityETH(address _tokenA,uint _amountA,uint _amountAmin,uint _amountBmin,uint _timestamp) public payable {
        require(_amountA > 0, "Less TokenA Supply");
        require(msg.value > 0, "Less TokenA Supply");
        IERC20 tokenA = IERC20(_tokenA);
        require(CheckAllowance(tokenA) >= _amountA ,"Less Supply");
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenA.approve(address(uniswapV2Router), _amountA);
        uniswapV2Router.addLiquidityETH{value : msg.value}(
            _tokenA,//A pool token.
            _amountA,//The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
            //The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
            _amountAmin,//Bounds the extent to which the B/A price can go up before the transaction reverts. Must be <= amountADesired.
            _amountBmin,//Bounds the extent to which the A/B price can go up before the transaction reverts. Must be <= amountBDesired.
            msg.sender,//Recipient of the liquidity tokens.
            _timestamp//Unix timestamp after which the transaction will revert.
        ); 
        emit liquidityaddedETH(msg.sender, _tokenA, _amountA, msg.value);
      
    }

    // @dev Checking Allowance
    function CheckAllowance(IERC20 _Token) internal view returns(uint) {
        return IERC20(_Token).allowance(msg.sender, address(this));
    }

    // @dev Get Pair Address 
    function pairAddress(address _tokenA, address _tokenB) public view returns(IERC20) {
        return IERC20(uniswapV2Factory.getPair(_tokenA, _tokenB));
    }   

    // @dev Removing Liquidity ERC20 Tokens
    function removingLiquidity(address _tokenA, address _tokenB,uint lpamount,uint tokenAmin,uint tokenBmin,uint timestamp) public {
        require(_tokenA != address(0), "DeAd address not allowed");
        require(_tokenB != address(0), "DeAd address not allowed");
        IERC20 pair = pairAddress(_tokenA, _tokenB);
        pair.transferFrom(msg.sender, address(this), lpamount); 
        pair.approve(address(uniswapV2Router), lpamount);
        uniswapV2Router.removeLiquidity(_tokenA,_tokenB,lpamount,tokenAmin,tokenBmin,msg.sender,timestamp);
        emit liquidityremove(msg.sender, address(pair),lpamount);
    }

    // @dev Removing Liquidity Eth Token
    function removingLiquidityETH(address _tokenA,uint lpamount,uint tokenAmin,uint tokenBmin,uint timestamp) public payable {
        require(_tokenA != address(0), "DeAd address not allowed");
        IERC20 pair = pairAddress(_tokenA,WETH);
        pair.transferFrom(msg.sender, address(this), lpamount); 
        pair.approve(address(uniswapV2Router), lpamount);
        uniswapV2Router.removeLiquidityETH(_tokenA,lpamount,tokenAmin,tokenBmin,msg.sender,timestamp);
        emit liquidityremoveETH(msg.sender, address(pair), lpamount);
    }
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}