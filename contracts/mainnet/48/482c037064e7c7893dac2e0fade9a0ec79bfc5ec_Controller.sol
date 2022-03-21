/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 _amount) external;

    function mint(address _address, uint256 _amount) external;
}

interface AAVE {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract Controller {
    event Deposit(
        address indexed _token,
        address indexed _from,
        uint256 _value
    );

    event Claim(address indexed _from, uint256 _value);

    uint256 private constant MAX_INT = 2**256 - 1;
    uint256 public MULT;

    address private constant TOKEN = 0x7075f7B8D36998c4429Fc43d20ce41f2a3C7EF9a;
    address private constant UNISWAP =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant AAVE_POOL =
        0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private constant aUSDT = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant aUSDC = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;

    mapping(address => uint256) public pendingBal;
    mapping(address => uint256) public pendingTime;
    mapping(address => uint256) public LOCKED;
    mapping(address => uint256) public STABLEFACT;

    function initApprovals() external {
        if (STABLEFACT[USDT] < 1) {
            STABLEFACT[USDT] = 1000000000000000000;
        }

        if (STABLEFACT[USDC] < 1) {
            STABLEFACT[USDC] = 1000000000000000000;
        }

        IERC20(USDT).approve(AAVE_POOL, MAX_INT);
        IERC20(USDT).approve(UNISWAP, MAX_INT);
        IERC20(USDC).approve(AAVE_POOL, MAX_INT);
        IERC20(USDC).approve(UNISWAP, MAX_INT);
    }

    function checkAaveInterest(address _usddollar, address _aave)
        internal
        view
        returns (uint256)
    {
        return IERC20(_aave).balanceOf(address(this)) - LOCKED[_usddollar];
    }

    function delta(uint256 _amount) internal view returns (uint256) {
        return ((_amount / 100) * MULT);
    }

    function randstep() internal {
        MULT = MULT + 1;

        if (MULT > 9) {
            MULT = 1;
        }
    }

    function uniswapBuyback(address _usddollar, uint256 _in) internal {
        uint256 amount = _in;
        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;
        uint24 fee = 10000;
        uint256 deadline = block.timestamp + 30;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                _usddollar,
                TOKEN,
                fee,
                address(this),
                deadline,
                amount,
                amountOutMinimum,
                sqrtPriceLimitX96
            );

        ISwapRouter(UNISWAP).exactInputSingle(params);
    }

    function deposit(address _usddollar, uint256 _amount) internal {
        require(_amount >= 2000000, "Amount should be greater than 1");

        randstep();

        IERC20(_usddollar).transferFrom(msg.sender, address(this), _amount);

        IERC20(TOKEN).burn(IERC20(TOKEN).balanceOf(address(this)));

        uniswapBuyback(_usddollar, 1000000);

        STABLEFACT[_usddollar] = IERC20(TOKEN).balanceOf(address(this));

        uint256 amount_nult = IERC20(_usddollar).balanceOf(address(this));

        AAVE(AAVE_POOL).deposit(_usddollar, amount_nult, address(this), 0);

        LOCKED[_usddollar] =
            LOCKED[_usddollar] +
            amount_nult -
            (delta(amount_nult) * 2);

        if (block.timestamp + (100000 * MULT) > pendingTime[msg.sender]) {
            pendingTime[msg.sender] = block.timestamp + (100000 * MULT);
        } else {
            pendingTime[msg.sender] = block.timestamp + (100000 * 10);
        }

        uint256 _tokenamount = ((_amount * 1000000000000) *
            STABLEFACT[_usddollar]) / 1e18;

        pendingBal[msg.sender] =
            pendingBal[msg.sender] +
            _tokenamount +
            delta(_tokenamount);

        emit Deposit(_usddollar, msg.sender, _tokenamount);
    }

    function withdraw(address _usddollar, address _aave) internal {
        if (checkAaveInterest(_usddollar, _aave) > 1000000) {
            AAVE(AAVE_POOL).withdraw(
                _usddollar,
                checkAaveInterest(_usddollar, _aave),
                address(this)
            );

            uniswapBuyback(
                _usddollar,
                IERC20(_usddollar).balanceOf(address(this))
            );
        }
    }

    function claim() external {
        require(pendingBal[msg.sender] > 0, "No Balance to claim");

        require(block.timestamp > pendingTime[msg.sender], "Wait for cooldown");

        IERC20(TOKEN).mint(msg.sender, pendingBal[msg.sender]);

        emit Claim(msg.sender, pendingBal[msg.sender]);

        pendingBal[msg.sender] = 0;

        uint256 rand = MULT % 3;

        if (rand == 1) {
            withdraw(USDC, aUSDC);
        }

        if (rand == 2) {
            withdraw(USDT, aUSDT);
        }
    }

    function runUSDT(uint256 _amount) external {
        deposit(USDT, _amount);
    }

    function runUSDC(uint256 _amount) external {
        deposit(USDC, _amount);
    }
}