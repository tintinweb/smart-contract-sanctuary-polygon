/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// File: GetLiquid_flat.sol


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: GetLiquid.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface CpieV2Factory {
    function getPair(address token0, address token1)
        external
        view
        returns (address);
}

interface CpieV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountA, uint256 amountB);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

contract GetLiquid {
    address private FACTORY = 0xF502B3d87311863bb0aC3CF3d2729A78438116Cf;
    address private ROUTER = 0x2D466B2b58bc254704E226686CF767820e0F6aB8;
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address owner;

    event Log(string message, uint256 val);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function updateFactory(address _factory)
        public
        onlyOwner
        returns (address)
    {
        return FACTORY = _factory;
    }

    function updateRouter(address _router) public onlyOwner returns (address) {
        return ROUTER = _router;
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) external {
        IERC20(_tokenA).allowance(msg.sender, address(this));
        IERC20(_tokenB).allowance(msg.sender, address(this));

        // Transfer from Human to this smart contract
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        // Allow the V2 Router to use the tokens
        IERC20(_tokenA).approve(ROUTER, _amountA);
        IERC20(_tokenB).approve(ROUTER, _amountB);

        // Now add the liquidity
        (uint256 amountA, uint256 amountB, uint256 liquidity) = CpieV2Router(
            ROUTER
        ).addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                address(this),
                block.timestamp
            );

        emit Log("AmountA", amountA);
        emit Log("AmountB", amountB);
        emit Log("Liquidity", liquidity);
    }

    function removeLiquidity(address _tokenA, address _tokenB) external {
        address pair = CpieV2Factory(FACTORY).getPair(_tokenA, _tokenB);

        uint256 liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(ROUTER, liquidity);

        (uint256 amountA, uint256 amountB) = CpieV2Router(ROUTER)
            .removeLiquidity(
                _tokenA,
                _tokenB,
                liquidity,
                1,
                1,
                address(this),
                block.timestamp
            );

        // Transfer tokens from contract to user
        IERC20(_tokenA).approve(address(this), amountA);
        IERC20(_tokenB).approve(address(this), amountB);

        IERC20(_tokenA).transferFrom(address(this), msg.sender, amountA);
        IERC20(_tokenB).transferFrom(address(this), msg.sender, amountB);

        emit Log("amountA", amountA);
        emit Log("amountB", amountB);
    }

    function removeLiquidityETH(address _token) external payable {
        address pair = CpieV2Factory(FACTORY).getPair(_token, WMATIC);
        uint liquidity = IERC20(pair).balanceOf(address(this));

        IERC20(pair).approve(ROUTER, liquidity);

        (uint256 amount, uint256 eth) = CpieV2Router(ROUTER).removeLiquidityETH(
            _token,
            liquidity,
            1,
            1,
            msg.sender,
            block.timestamp
        );

        emit Log("amount", amount);
        emit Log("Ether", eth);
    }

    function addLiquidityETH(address _token, uint256 _amount) external payable {
        // Transfer from Human to this smart contract
        
        uint256 liquid = IERC20(_token).balanceOf(address(this));
        
        IERC20(_token).approve(ROUTER, liquid);
        IERC20(_token).allowance(msg.sender, address(this));
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    
        (uint256 amount, uint256 eth, uint256 liquidity) = CpieV2Router(ROUTER)
            .addLiquidityETH{value: msg.value}(
            _token,
            liquid,
            1,
            msg.value,
            msg.sender,
            block.timestamp
        );

        emit Log("amount", amount);
        emit Log("Ether", eth);
        emit Log("LP Tokens", liquidity);
    }
}