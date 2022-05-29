/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IMasterchef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
}

contract Ripae_Genpool_Autocompounder {
    
    address public owner;
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IERC20 public pMATIC = IERC20(0xA0dF47432d9d88bcc040E9ee66dDC7E17A882715);
    IERC20 public QLP = IERC20(0x05eFa0Ed56DDdB4E950E3F5a54e349A137d4edC9);

    IRouter public Router = IRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); // Quickswap
    IMasterchef public GenesisPool = IMasterchef(0xb45EDC1242E116a9E29898540d718d2391C52d41);
    IMasterchef public SharePool = IMasterchef(0xa4dC4c7624acE1b415e6D937E694047b517F2D99);

    constructor() {
        owner = msg.sender;
        USDC.approve(address(GenesisPool), 2 ** 256 - 1);
        QLP.approve(address(SharePool), 2 ** 256 - 1);
        WMATIC.approve(address(Router), 2 ** 256 - 1);
        pMATIC.approve(address(Router), 2 ** 256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Compounder: Caller is not the owner");
        _;
    }

    function depositGenesis() public onlyOwner {
        // Deposit USDC only
        // pid = 2
        GenesisPool.deposit(2, USDC.balanceOf(address(this)));
    }
    
    function depositShare() public onlyOwner {
        SharePool.deposit(0, QLP.balanceOf(address(this)));
    }

    function withdrawGenesis() external onlyOwner {
        // Include emergency
        GenesisPool.deposit(2, 0);
        GenesisPool.emergencyWithdraw(2);
    }

    function withdrawShare() external onlyOwner {
        // pid = 0
        SharePool.deposit(0, 0);
        SharePool.emergencyWithdraw(0);
    }

    function compound() public onlyOwner {
        GenesisPool.deposit(2, 0);
        require(pMATIC.balanceOf(address(this)) > 0, "Compounder: Not enough pMATIC to compound");
        
        address[] memory path = new address[](2);
        path[0] = address(pMATIC);
        path[1] = address(WMATIC);

        uint256[] memory amountsOut = Router.getAmountsOut(pMATIC.balanceOf(address(this)), path);
        // amountsOut[1] is the amount out

        Router.swapExactTokensForTokens(
            pMATIC.balanceOf(address(this)),
            (amountsOut[1] * 8) / 10, // 20% slippage??
            path,
            address(this),
            (block.timestamp + 1200)
        );

        require(WMATIC.balanceOf(address(this)) > 0, "Compounder: Not enough WMATIC to compound");
        Router.addLiquidity(
            address(pMATIC),
            address(WMATIC),
            pMATIC.balanceOf(address(this)),
            WMATIC.balanceOf(address(this)),
            0,
            0,
            address(this),
            (block.timestamp + 1200)
        );

        require(QLP.balanceOf(address(this)) > 0, "Compounder: Not enough LP tokens to deposit");
        depositShare();
    }

    function withdrawToken(address _contract) external onlyOwner {
        IERC20 Token = IERC20(_contract);
        Token.transfer(owner, Token.balanceOf(address(this)));
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "IronVault: external call failed");
        return result;
    }
}