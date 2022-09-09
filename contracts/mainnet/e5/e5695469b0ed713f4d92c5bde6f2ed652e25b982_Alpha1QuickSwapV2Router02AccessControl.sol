/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;



contract Alpha1QuickSwapV2Router02AccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // WETH on polygon
        _tokenWhitelist[0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619] = true;
        // USDC on polygon
        _tokenWhitelist[0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = true;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    function check(bytes32 _role, uint256 _value, bytes calldata data) external onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    fallback() external {
        revert("Unauthorized access");
    }

    // ACL methods

    
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[tokenA], "Token is not allowed");
        require(_tokenWhitelist[tokenB], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }
            
    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[tokenA], "Token is not allowed");
        require(_tokenWhitelist[tokenB], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }
            
}