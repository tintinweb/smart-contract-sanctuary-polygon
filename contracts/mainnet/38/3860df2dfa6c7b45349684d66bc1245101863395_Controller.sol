/**
 *Submitted for verification at polygonscan.com on 2022-03-15
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
    uint256 private constant MAX_INT = 2**256 - 1;
    uint256 public MULT;

    address private constant SWAP_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant TOKEN = 0xf857b6BddEd567804248Bc919A7373f3f52508DE;
    address private constant POOL = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;

    mapping(address => uint256) public pendBalance;
    mapping(address => uint256) public pendTime;
    mapping(address => uint256) public STACKED;

    // token data
    address private constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address private constant aDAI = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;
    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private constant aUSDT = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant aUSDC = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;

    function initApprovals() external {
        IERC20(DAI).approve(POOL, MAX_INT);
        IERC20(DAI).approve(SWAP_ROUTER, MAX_INT);
        IERC20(USDT).approve(POOL, MAX_INT);
        IERC20(USDT).approve(SWAP_ROUTER, MAX_INT);
        IERC20(USDC).approve(POOL, MAX_INT);
        IERC20(USDC).approve(SWAP_ROUTER, MAX_INT);
    }

    function checkAaveInterest(address _usddollar, address _aave)
        internal
        view
        returns (uint256)
    {
        return IERC20(_aave).balanceOf(address(this)) - STACKED[_usddollar];
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

    function uniswapBuyback(address _usddollar) internal {
        //uniswap buyback

        uint256 amount = IERC20(_usddollar).balanceOf(address(this));
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

        ISwapRouter(SWAP_ROUTER).exactInputSingle(params);
    }

    // deposit to aave and give user token
    function deposit(
        address _usddollar,
        uint256 _amount,
        address _refer
    ) internal {
        // change MULT
        randstep();

        IERC20(_usddollar).transferFrom(msg.sender, address(this), _amount);

        uint256 amount_mult = _amount + delta(_amount);
        uint256 amount_nult = _amount - delta(_amount);

        AAVE(POOL).deposit(_usddollar, amount_nult, address(this), 0);

        STACKED[_usddollar] = STACKED[_usddollar] + amount_nult;

        pendTime[msg.sender] = block.timestamp + (120000 * MULT);

        pendBalance[msg.sender] = pendBalance[msg.sender] + amount_mult;

        //refer reward
        pendBalance[_refer] = pendBalance[_refer] + delta(_amount);
    }

    // only withdraws the interest
    function withdraw(address _usddollar, address _aave) internal {
        // Int Cashout
        require(
            checkAaveInterest(_usddollar, _aave) > 0,
            "No Interest To Collect"
        );

        AAVE(POOL).withdraw(
            _usddollar,
            checkAaveInterest(_usddollar, _aave),
            address(this)
        );

        //uniswap buyback
        uniswapBuyback(_usddollar);

        // Burn token
        IERC20(TOKEN).burn(IERC20(TOKEN).balanceOf(address(this)));
    }

    // claim funtion
    function claim() external {
        require(pendBalance[msg.sender] > 0, "No Balance to claim");

        require(block.timestamp > pendTime[msg.sender], "Wait for cooldown");

        IERC20(TOKEN).mint(msg.sender, pendBalance[msg.sender]);

        pendBalance[msg.sender] = 0;
    }

    // Deposit and Withdraws
    function depositDAI(uint256 _amount, address _refer) external {
        deposit(DAI, _amount, _refer);
    }

    function withdrawDAI() external {
        withdraw(DAI, aDAI);
    }

    function depositUSDT(uint256 _amount, address _refer) external {
        deposit(USDT, _amount, _refer);
    }

    function withdrawUSDT() external {
        withdraw(USDT, aUSDT);
    }

    function depositUSDC(uint256 _amount, address _refer) external {
        deposit(USDC, _amount, _refer);
    }

    function withdrawUSDC() external {
        withdraw(USDC, aUSDC);
    }
}