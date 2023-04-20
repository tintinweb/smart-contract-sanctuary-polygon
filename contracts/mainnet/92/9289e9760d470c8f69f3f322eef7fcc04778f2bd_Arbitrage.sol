/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }
    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }
    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
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
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    constructor() {
        _paused = false;
    }
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
    modifier whenPaused() {
        _requirePaused();
        _;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface IRouter {
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

contract Arbitrage is Ownable, ReentrancyGuard{


    
    function executeArbitrage(uint256 amount, IERC20 token0, IERC20 token1, address[] calldata Routers )
    external nonReentrant onlyOwner payable
    {
    require(msg.sender == tx.origin," InValid Caller ");
    require(msg.value == amount, "Amount not equal to sent MATIC");
    
    // Set up token path for first swap (ETH -> token0)
address[] memory path1 = new address[](2);
path1[0] = IRouter(Routers[0]).WETH();
path1[1] = address(token0);

// Execute first swap on first router
uint256 amountOutMin1 = 0; // set the minimum output amount to 0 for simplicity
uint256 amountIn1 = msg.value; // set the input amount of ETH to swap
IRouter(Routers[0]).swapExactETHForTokens{value: amountIn1}(
    amountOutMin1,
    path1,
    address(this),
    block.timestamp
);

// Set up token path for second swap (token0 -> token1)
address[] memory path2 = new address[](2);
path2[0] = address(token0);
path2[1] = address(token1);

// Execute second swap on second router
uint256 amountOutMin2 = 0; // set the minimum output amount to 0 for simplicity
uint256 amountIn2 = token0.balanceOf(address(this)); // set the input amount of token0 to swap
token0.approve(Routers[1], amountIn2); // approve the input token for the router
IRouter(Routers[1]).swapExactTokensForTokens(
    amountIn2,
    amountOutMin2,
    path2,
    address(this),
    block.timestamp
);
    
    // Get the output amount of token1
    // uint256 sellAmount = token1.balanceOf(address(this));

    // // Approve router to spend token1
    // token1.approve(address(Routers[1]), sellAmount);

    // // Define path for reverse swap
    // address[] memory path1 = new address[](3);
    // path1[0] = address(token1);
    // path1[1] = address(token0);
    // path1[2] = IRouter(Routers[1]).WETH();

    // // Execute swap on second router
    // IRouter(Routers[1]).swapExactTokensForETH(
    // sellAmount,
    // 0, 
    // path1,
    // address(this), 
    // block.timestamp
    // );
}

    function withdrawBNB(uint256 amount) public onlyOwner{
        payable(owner()).transfer(amount);
    }

    function withdrawToken(IERC20 token, uint256 amount) public onlyOwner{
        IERC20(token).transfer(msg.sender, amount);
    }

   receive() external payable {}

}