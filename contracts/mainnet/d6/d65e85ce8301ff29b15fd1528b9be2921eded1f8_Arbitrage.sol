/**
 *Submitted for verification at polygonscan.com on 2023-06-26
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
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IRouter {

    function WETH() external pure returns (address);
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
    external 
    returns (uint[] memory amounts);

}

contract Arbitrage is Ownable, ReentrancyGuard{
    
    
    function executeArbitrage(uint256 amount, IERC20 token1, IERC20 token2, address[] calldata Routers )
    external nonReentrant onlyOwner
    {
        require(msg.sender == tx.origin," InValid Caller ");
        require(token1.balanceOf(msg.sender) >= amount, "Insufficient USDC balance");

        // Transfer USDC from the sender to the contract
        IERC20(token1).transferFrom(msg.sender, address(this), amount);

        // Define path for swap
        address[] memory path = new address[](2);
        path[0] = address(token1);
        path[1] = address(token2);

        // Approve router to spend USDC
        IERC20(token1).approve(address(Routers[0]), amount);

        // Execute swap on first router
        IRouter(Routers[0]).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        // Get the output amount of token1
        uint256 sellAmount = token2.balanceOf(address(this));

        // Approve router to spend token1
        IERC20(token2).approve(address(Routers[1]), sellAmount);

        // Define path for reverse swap
        address[] memory path1 = new address[](2);
        path1[0] = address(token2);
        path1[1] = address(token1);

        // Execute swap on second router
        IRouter(Routers[1]).swapExactTokensForTokens(
            sellAmount,
            0,
            path1,
            address(this),
            block.timestamp
        );
    }

    function executeArbitrageETH(uint256 amount,IERC20 token, address[] calldata Routers )
        external nonReentrant onlyOwner payable
        {
        require(msg.sender == tx.origin," InValid Caller ");
        require(msg.value == amount, "Amount not equal to sent MATIC");
        
        // Define path for swap
        address[] memory path = new address[](2);
        path[0] = IRouter(Routers[0]).WETH();
        path[1] = address(token);

        // Execute swap on first router
        IRouter(Routers[0]).swapExactETHForTokens{value: amount}(
        0, 
        path,
        address(this), 
        block.timestamp
        );
        
        // Get the output amount of token1
        uint256 sellAmount = token.balanceOf(address(this));

        // Approve router to spend token1
        token.approve(address(Routers[1]), sellAmount);

        // Define path for reverse swap
        address[] memory path1 = new address[](2);
        path1[0] = address(token);
        path1[1] = IRouter(Routers[1]).WETH();

        // Execute swap on second router
        IRouter(Routers[1]).swapExactTokensForETH(
        sellAmount,
        0, 
        path1,
        address(this), 
        block.timestamp
        );
    }

    function withdrawBNB(uint256 amount) public onlyOwner{
        payable(owner()).transfer(amount);
    }

    function withdrawToken(IERC20 token, uint256 amount) public onlyOwner{
        IERC20(token).transfer(msg.sender, amount);
    }

   receive() external payable {}

}
//["0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff","0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506"]