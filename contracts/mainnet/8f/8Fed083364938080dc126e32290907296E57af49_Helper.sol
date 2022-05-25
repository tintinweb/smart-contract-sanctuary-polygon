/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
    function WETH() external view returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IFactory {
    function router() external view returns (address);
    function poolExist(address) external view returns (bool);
    function tokenToPool(address, address) external view returns (address);
}

interface IExchange {
    function estimatePos(address, uint) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getCurrentPool() external view returns (uint, uint);
    function fee() external view returns (uint);
    function addTokenLiquidityWithLimit(uint amount0, uint amount1, uint minAmount0, uint minAmount1, address user) external;
}

interface IGovernance {
    function factory() external view returns (address);
    function feeShareRate() external view returns (uint);
    function poolVoting() external view returns (address);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract Helper {
    using SafeMath for uint256;

    string public constant version = "Helper20220322";
    address public governance;
    address public factory;
    address public router;
    address public poolVoting;
    address payable public withdraw;

    constructor(address _governance, address payable _withdraw) public {
        governance = _governance;
        factory = IGovernance(governance).factory();
        poolVoting = IGovernance(governance).poolVoting();
        router = IFactory(factory).router();

        require(_withdraw != address(0));
        withdraw = _withdraw;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3){
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) /2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getSwapAmt(address lp, address token, uint256 amtA) public view returns (uint maxSwap, uint estimateTarget) {
        IExchange pool = IExchange(lp);

        uint fee = pool.fee();
        require(fee < 10000);

        uint resA = 0;
        bool exist = false;
        if (token == pool.token0()) {
            exist = true;
            (resA, ) = pool.getCurrentPool();
        }
        if (token == pool.token1()) {
            exist = true;
            (, resA) = pool.getCurrentPool();
        }
        require(exist);

        uint addA = (20000 - fee).mul(20000 - fee).mul(resA);
        uint addB = (10000 - fee).mul(40000).mul(amtA);
        uint sqrtRes = sqrt(resA.mul(addA.add(addB)));
        uint subRes = resA.mul(20000 - fee);
        uint divRes = (10000 - fee).mul(2);

        maxSwap = (sqrtRes.sub(subRes)).div(divRes);
        estimateTarget = pool.estimatePos(token, maxSwap);
    }

    function addLiquidityWithETH(address lp, uint inputForLiquidity, uint targetForLiquidity) public payable {
        IFactory Factory = IFactory(factory);
        IRouter Router = IRouter(router);
        IExchange pool = IExchange(lp);
        address WETH = Router.WETH();

        require(Factory.poolExist(lp));
        require(pool.token0() == Router.WETH());

        uint amount = msg.value;

        (uint maxSwap, ) = getSwapAmt(lp, WETH, amount);
        address target = pool.token1();

        uint balanceTarget = balanceOf(target);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = target;

        IWETH(WETH).deposit.value(msg.value)();
        approve(WETH, router, maxSwap);

        Router.swapExactTokensForTokens(maxSwap, 1, path, address(this), block.timestamp + 600);
        balanceTarget = (balanceOf(target)).sub(balanceTarget);

        require(targetForLiquidity <= balanceTarget);
        require(inputForLiquidity <= (amount).sub(maxSwap));

        addLiquidity(lp, (amount).sub(maxSwap), balanceTarget, true);
    }

    function addLiquidityWithToken(address lp, address token, uint amount, uint inputForLiquidity, uint targetForLiquidity) public {
        IFactory Factory = IFactory(factory);
        IRouter Router = IRouter(router);
        IExchange pool = IExchange(lp);

        require(Factory.poolExist(lp));
        require(token != address(0));

        require(IERC20(token).transferFrom(msg.sender, address(this), amount));

        address token0 = pool.token0();
        address token1 = pool.token1();

        (uint maxSwap,) = getSwapAmt(lp, token, amount);
        address target = token == token0 ? token1 : token0;

        approve(token, router, maxSwap);

        uint balanceTarget = balanceOf(target);
            
        {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = target;

            Router.swapExactTokensForTokens(maxSwap, 1, path, address(this), block.timestamp + 600);
        }
        balanceTarget = (balanceOf(target)).sub(balanceTarget);

        require(targetForLiquidity <= balanceTarget);
        require(inputForLiquidity <= (amount).sub(maxSwap));

        if (token == token0) {
            addLiquidity(lp, (amount).sub(maxSwap), balanceTarget, false);
        } else {
            addLiquidity(lp, balanceTarget, (amount).sub(maxSwap), false);
        }
    }

    function addLiquidity(address lp, uint inputA, uint inputB, bool isETH) private {
        IExchange pool = IExchange(lp);
        IRouter Router = IRouter(router);
        address WETH = Router.WETH();

        address token0 = pool.token0();
        address token1 = pool.token1();

        uint diffA = balanceOf(token0);
        uint diffB = balanceOf(token1);
        
        approve(token0, lp, inputA);
        approve(token1, lp, inputB);

        pool.addTokenLiquidityWithLimit(inputA, inputB, 1, 1, address(this));

        diffA = (diffA).sub(balanceOf(token0));
        diffB = (diffB).sub(balanceOf(token1));

        transfer(lp, msg.sender, balanceOf(lp));
        if (inputA > diffA) {
            if (isETH) {
                IWETH(WETH).withdraw(inputA.sub(diffA));
                (bool success, ) = msg.sender.call.value(inputA.sub(diffA))("");
                require(success, 'Helper: ETH transfer failed');
            } else {
                transfer(token0, msg.sender, (inputA).sub(diffA));
            }
        }
            
        if (inputB > diffB)
            transfer(token1, msg.sender, (inputB).sub(diffB));
    }

    function balanceOf(address token) private view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function approve(address token, address spender, uint amount) private {
        require(IERC20(token).approve(spender, amount));
    }

    function transfer(address token, address payable to, uint amount) private {
        if (amount == 0) return;

        if (token == address(0)) {
            (bool success, ) = to.call.value(amount)("");
            require(success, "Transfer failed.");
        }
        else{
            require(IERC20(token).transfer(to, amount));
        }
    }

    function inCaseTokensGetStuck(address token) public {
        require(msg.sender == withdraw);

        transfer(token, withdraw, balanceOf(token));
    }

    function () external payable {}
}