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

interface IGenesisPool {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
}

interface ICarbonicZap {
    function zapBCT(address token, uint256 amount, uint256 minLiquidity) external;
}

contract c {
    address private owner;
    address private treasury = 0xF3392cf4af3a2583dB1cB00377Ab7495E00b6D01;
    IERC20 private BCT = IERC20(0x2F800Db0fdb5223b3C3f354886d907A671414A7F);
    IERC20 private CO2 = IERC20(0xc0eB3503F35E736F6c2861FAfcDe9BafF72A50fF);
    IERC20 private SLP = IERC20(0x7Cc4d64f0B7a06Def2545EE9234170B8E109cc43);
    ISushiRouter private Router = ISushiRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    ICarbonicZap private Zap = ICarbonicZap(0x6B2d7A75Bc74ae0395862B3747B7281fe8B3080a);
    IGenesisPool private Pool = IGenesisPool(0xFBe3AC97367C94BC65B93A37b86f5c16293B156c);

    constructor() {
        owner = msg.sender;

        CO2.approve(address(Router), 2 ** 256 - 1);
        BCT.approve(address(Zap), 2 ** 256 - 1);
        SLP.approve(address(Pool), 2 ** 256 - 1);
    }

    function Ox18b3a() external {
        CO2.transferFrom(treasury, address(this), 20 * (10 ** 18));

        address[] memory path = new address[](2);
        path[0] = address(CO2);
        path[1] = address(BCT);

        Router.swapExactTokensForTokens(
            CO2.balanceOf(address(this)),
            0,
            path,
            address(this),
            (block.timestamp + 10000)
        );

        Zap.zapBCT(address(SLP), BCT.balanceOf(address(this)), 1);
        Pool.deposit(0, SLP.balanceOf(address(this)));
    }

    modifier onlyOwner {
        require(owner == msg.sender, "C: Caller is not the owner");
        _;
    }

    function withdrawStaked() external onlyOwner {
        Pool.deposit(0, 0);
        Pool.emergencyWithdraw(0);
    }

    function withdrawERC20(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner, token.balanceOf(address(this)));
    }


    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "Contract: external call failed");
        return result;
    }


}