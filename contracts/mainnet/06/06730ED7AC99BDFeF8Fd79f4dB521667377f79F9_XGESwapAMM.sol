/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

// File: @openzeppelin/[email protected]/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: xge_swap_amm


pragma solidity ^0.8;


contract XGESwapAMM is Ownable {
    
}


library Math {
    function abs(uint x, uint y) internal pure returns (uint) {
        return x >= y ? x - y : y - x;
    }
}

contract StableSwap {
    // Number of tokens
    uint private constant N = 3;
    // Amplification coefficient multiplied by N^(N - 1)
    // Higher value makes the curve more flat
    // Lower value makes the curve more like constant product AMM
    uint private constant A = 1000 * (N**(N - 1));
    // 0.03%
    uint private constant SWAP_FEE = 300;
    // Liquidity fee is derived from 2 constraints
    // 1. Fee is 0 for adding / removing liquidity that results in a balanced pool
    // 2. Swapping in a balanced pool is like adding and then removing liquidity
    //    from a balanced pool
    // swap fee = add liquidity fee + remove liquidity fee
    uint private constant LIQUIDITY_FEE = (SWAP_FEE * N) / (4 * (N - 1));
    uint private constant FEE_DENOMINATOR = 1e6;

    address[N] public tokens;
    // Normalize each token to 18 decimals
    // Example - DAI (18 decimals), USDC (6 decimals), USDT (6 decimals)
    uint[N] private multipliers = [1, 1e12, 1e12];
    uint[N] public balances;

    // 1 share = 1e18, 18 decimals
    uint private constant DECIMALS = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    // Return precision-adjusted balances, adjusted to 18 decimals
    function _xp() private view returns (uint[N] memory xp) {
        for (uint i; i < N; ++i) {
            xp[i] = balances[i] * multipliers[i];
        }
    }

    /**
     * @notice Calculate D, sum of balances in a perfectly balanced pool
     * If balances of x_0, x_1, ... x_(n-1) then sum(x_i) = D
     * @param xp Precision-adjusted balances
     * @return D
     */
    function _getD(uint[N] memory xp) private pure returns (uint) {
        /*
        Newton's method to compute D
        -----------------------------
        f(D) = ADn^n + D^(n + 1) / (n^n prod(x_i)) - An^n sum(x_i) - D 
        f'(D) = An^n + (n + 1) D^n / (n^n prod(x_i)) - 1

                     (as + np)D_n
        D_(n+1) = -----------------------
                  (a - 1)D_n + (n + 1)p

        a = An^n
        s = sum(x_i)
        p = (D_n)^(n + 1) / (n^n prod(x_i))
        */
        uint a = A * N; // An^n

        uint s; // x_0 + x_1 + ... + x_(n-1)
        for (uint i; i < N; ++i) {
            s += xp[i];
        }

        // Newton's method
        // Initial guess, d <= s
        uint d = s;
        uint d_prev;
        for (uint i; i < 255; ++i) {
            // p = D^(n + 1) / (n^n * x_0 * ... * x_(n-1))
            uint p = d;
            for (uint j; j < N; ++j) {
                p = (p * d) / (N * xp[j]);
            }
            d_prev = d;
            d = ((a * s + N * p) * d) / ((a - 1) * d + (N + 1) * p);

            if (Math.abs(d, d_prev) <= 1) {
                return d;
            }
        }
        revert("D didn't converge");
    }

    /**
     * @notice Calculate the new balance of token j given the new balance of token i
     * @param i Index of token in
     * @param j Index of token out
     * @param x New balance of token i
     * @param xp Current precision-adjusted balances
     */
    function _getY(
        uint i,
        uint j,
        uint x,
        uint[N] memory xp
    ) private pure returns (uint) {
        /*
        Newton's method to compute y
        -----------------------------
        y = x_j

        f(y) = y^2 + y(b - D) - c

                    y_n^2 + c
        y_(n+1) = --------------
                   2y_n + b - D

        where
        s = sum(x_k), k != j
        p = prod(x_k), k != j
        b = s + D / (An^n)
        c = D^(n + 1) / (n^n * p * An^n)
        */
        uint a = A * N;
        uint d = _getD(xp);
        uint s;
        uint c = d;

        uint _x;
        for (uint k; k < N; ++k) {
            if (k == i) {
                _x = x;
            } else if (k == j) {
                continue;
            } else {
                _x = xp[k];
            }

            s += _x;
            c = (c * d) / (N * _x);
        }
        c = (c * d) / (N * a);
        uint b = s + d / a;

        // Newton's method
        uint y_prev;
        // Initial guess, y <= d
        uint y = d;
        for (uint _i; _i < 255; ++_i) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - d);
            if (Math.abs(y, y_prev) <= 1) {
                return y;
            }
        }
        revert("y didn't converge");
    }

    /**
     * @notice Calculate the new balance of token i given precision-adjusted
     * balances xp and liquidity d
     * @dev Equation is calculate y is same as _getY
     * @param i Index of token to calculate the new balance
     * @param xp Precision-adjusted balances
     * @param d Liquidity d
     * @return New balance of token i
     */
    function _getYD(
        uint i,
        uint[N] memory xp,
        uint d
    ) private pure returns (uint) {
        uint a = A * N;
        uint s;
        uint c = d;

        uint _x;
        for (uint k; k < N; ++k) {
            if (k != i) {
                _x = xp[k];
            } else {
                continue;
            }

            s += _x;
            c = (c * d) / (N * _x);
        }
        c = (c * d) / (N * a);
        uint b = s + d / a;

        // Newton's method
        uint y_prev;
        // Initial guess, y <= d
        uint y = d;
        for (uint _i; _i < 255; ++_i) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - d);
            if (Math.abs(y, y_prev) <= 1) {
                return y;
            }
        }
        revert("y didn't converge");
    }

    // Estimate value of 1 share
    // How many tokens is one share worth?
    function getVirtualPrice() external view returns (uint) {
        uint d = _getD(_xp());
        uint _totalSupply = totalSupply;
        if (_totalSupply > 0) {
            return (d * 10**DECIMALS) / _totalSupply;
        }
        return 0;
    }

    /**
     * @notice Swap dx amount of token i for token j
     * @param i Index of token in
     * @param j Index of token out
     * @param dx Token in amount
     * @param minDy Minimum token out
     */
    function swap(
        uint i,
        uint j,
        uint dx,
        uint minDy
    ) external returns (uint dy) {
        require(i != j, "i = j");

        IERC20(tokens[i]).transferFrom(msg.sender, address(this), dx);

        // Calculate dy
        uint[N] memory xp = _xp();
        uint x = xp[i] + dx * multipliers[i];

        uint y0 = xp[j];
        uint y1 = _getY(i, j, x, xp);
        // y0 must be >= y1, since x has increased
        // -1 to round down
        dy = (y0 - y1 - 1) / multipliers[j];

        // Subtract fee from dy
        uint fee = (dy * SWAP_FEE) / FEE_DENOMINATOR;
        dy -= fee;
        require(dy >= minDy, "dy < min");

        balances[i] += dx;
        balances[j] -= dy;

        IERC20(tokens[j]).transfer(msg.sender, dy);
    }

    function addLiquidity(uint[N] calldata amounts, uint minShares)
        external
        returns (uint shares)
    {
        // calculate current liquidity d0
        uint _totalSupply = totalSupply;
        uint d0;
        uint[N] memory old_xs = _xp();
        if (_totalSupply > 0) {
            d0 = _getD(old_xs);
        }

        // Transfer tokens in
        uint[N] memory new_xs;
        for (uint i; i < N; ++i) {
            uint amount = amounts[i];
            if (amount > 0) {
                IERC20(tokens[i]).transferFrom(msg.sender, address(this), amount);
                new_xs[i] = old_xs[i] + amount * multipliers[i];
            } else {
                new_xs[i] = old_xs[i];
            }
        }

        // Calculate new liquidity d1
        uint d1 = _getD(new_xs);
        require(d1 > d0, "liquidity didn't increase");

        // Reccalcuate D accounting for fee on imbalance
        uint d2;
        if (_totalSupply > 0) {
            for (uint i; i < N; ++i) {
                // TODO: why old_xs[i] * d1 / d0? why not d1 / N?
                uint idealBalance = (old_xs[i] * d1) / d0;
                uint diff = Math.abs(new_xs[i], idealBalance);
                new_xs[i] -= (LIQUIDITY_FEE * diff) / FEE_DENOMINATOR;
            }

            d2 = _getD(new_xs);
        } else {
            d2 = d1;
        }

        // Update balances
        for (uint i; i < N; ++i) {
            balances[i] += amounts[i];
        }

        // Shares to mint = (d2 - d0) / d0 * total supply
        // d1 >= d2 >= d0
        if (_totalSupply > 0) {
            shares = ((d2 - d0) * _totalSupply) / d0;
        } else {
            shares = d2;
        }
        require(shares >= minShares, "shares < min");
        _mint(msg.sender, shares);
    }

    function removeLiquidity(uint shares, uint[N] calldata minAmountsOut)
        external
        returns (uint[N] memory amountsOut)
    {
        uint _totalSupply = totalSupply;

        for (uint i; i < N; ++i) {
            uint amountOut = (balances[i] * shares) / _totalSupply;
            require(amountOut >= minAmountsOut[i], "out < min");

            balances[i] -= amountOut;
            amountsOut[i] = amountOut;

            IERC20(tokens[i]).transfer(msg.sender, amountOut);
        }

        _burn(msg.sender, shares);
    }

    /**
     * @notice Calculate amount of token i to receive for shares
     * @param shares Shares to burn
     * @param i Index of token to withdraw
     * @return dy Amount of token i to receive
     *         fee Fee for withdraw. Fee already included in dy
     */
    function _calcWithdrawOneToken(uint shares, uint i)
        private
        view
        returns (uint dy, uint fee)
    {
        uint _totalSupply = totalSupply;
        uint[N] memory xp = _xp();

        // Calculate d0 and d1
        uint d0 = _getD(xp);
        uint d1 = d0 - (d0 * shares) / _totalSupply;

        // Calculate reduction in y if D = d1
        uint y0 = _getYD(i, xp, d1);
        // d1 <= d0 so y must be <= xp[i]
        uint dy0 = (xp[i] - y0) / multipliers[i];

        // Calculate imbalance fee, update xp with fees
        uint dx;
        for (uint j; j < N; ++j) {
            if (j == i) {
                dx = (xp[j] * d1) / d0 - y0;
            } else {
                // d1 / d0 <= 1
                dx = xp[j] - (xp[j] * d1) / d0;
            }
            xp[j] -= (LIQUIDITY_FEE * dx) / FEE_DENOMINATOR;
        }

        // Recalculate y with xp including imbalance fees
        uint y1 = _getYD(i, xp, d1);
        // - 1 to round down
        dy = (xp[i] - y1 - 1) / multipliers[i];
        fee = dy0 - dy;
    }

    function calcWithdrawOneToken(uint shares, uint i)
        external
        view
        returns (uint dy, uint fee)
    {
        return _calcWithdrawOneToken(shares, i);
    }

    /**
     * @notice Withdraw liquidity in token i
     * @param shares Shares to burn
     * @param i Token to withdraw
     * @param minAmountOut Minimum amount of token i that must be withdrawn
     */
    function removeLiquidityOneToken(
        uint shares,
        uint i,
        uint minAmountOut
    ) external returns (uint amountOut) {
        (amountOut, ) = _calcWithdrawOneToken(shares, i);
        require(amountOut >= minAmountOut, "out < min");

        balances[i] -= amountOut;
        _burn(msg.sender, shares);

        IERC20(tokens[i]).transfer(msg.sender, amountOut);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}