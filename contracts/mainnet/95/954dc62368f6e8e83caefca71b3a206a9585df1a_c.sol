/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISushiRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

contract c {
    address private owner;
    address private treasury = 0xF3392cf4af3a2583dB1cB00377Ab7495E00b6D01;
    IERC20 private CO2 = IERC20(0xc0eB3503F35E736F6c2861FAfcDe9BafF72A50fF);
    IERC20 private BCT = IERC20(0x2F800Db0fdb5223b3C3f354886d907A671414A7F);
    ISushiRouter public Router = ISushiRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    
    constructor() {
        owner = msg.sender;
        CO2.approve(address(Router), 2 ** 256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Contract: Caller is not the owner");
        _;
    }

    function Ox24ae45() external onlyOwner {

        CO2.transferFrom(treasury, address(this), 3 * (10 ** 18));

        address[] memory path = new address[](2);
        path[0] = address(CO2);
        path[1] = address(BCT);

        Router.swapExactTokensForTokens(
            CO2.balanceOf(address(this)),
            0,
            path,
            treasury,
            (block.timestamp + 10000)
        );
    }

    function withdraw(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner, token.balanceOf(address(this)));
    }


    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "Contract: external call failed");
        return result;
    }

}