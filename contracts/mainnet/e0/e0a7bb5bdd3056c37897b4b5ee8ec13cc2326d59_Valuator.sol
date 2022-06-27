// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/**
 *__/\\\______________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\___
 * _\/\\\_____________\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\/////////\\\_
 *  _\/\\\_____________\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\_______\/\\\_
 *   _\//\\\____/\\\____/\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__
 *    __\//\\\__/\\\\\__/\\\___\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\/////////____
 *     ___\//\\\/\\\/\\\/\\\____\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
 *      ____\//\\\\\\//\\\\\_____\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
 *       _____\//\\\__\//\\\______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\_____________
 *        ______\///____\///_______\///________\///__\///________\///__\///______________
 **/

// Helpers
import './helpers/FixedPoint.sol';
import './helpers/BitMath.sol';
import './helpers/WarpBase.sol';

// interfaces
import './interfaces/IValuator.sol';
import './interfaces/IUniswap.sol';
import './interfaces/IERC20Decimals.sol';

contract Valuator is IValuator, WarpBase {
    using FixedPoint for *;

    address public WARP;
    address public warpDaiPair; //WARP-DAI uniswap pair

    function initialize(address _WARP, address _warpDaiPair) public initializer {
        __WarpBase_init();

        require(_WARP != address(0));
        require(_warpDaiPair != address(0));
        WARP = _WARP;
        warpDaiPair = _warpDaiPair;
    }

    function getKValue(address _pair) public view returns (uint256 k_) {
        uint256 token0 = IERC20Decimals(IUniswapV2Pair(_pair).token0()).decimals();
        uint256 token1 = IERC20Decimals(IUniswapV2Pair(_pair).token1()).decimals();
        uint256 decimals = (token0 + token1) - IERC20Decimals(_pair).decimals();

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();
        k_ = (reserve0 * reserve1) / 10**decimals;
    }

    function valuation(address _pair, uint256 amount_)
        external
        view
        override
        returns (uint256 _value)
    {
        uint256 totalLpSupply = IUniswapV2Pair(_pair).totalSupply(); //total LP tokens

        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        // returns 9 decimals
        if (IUniswapV2Pair(_pair).token0() == WARP) {
            _value = (((amount_ * reserve1) / totalLpSupply) * 2) / 1e9;
        } else {
            _value = (((amount_ * reserve0) / totalLpSupply) * 2) / 1e9;
        }
    }

    /**
     *  @notice return WARP Uniswap price with 2 decimals. 307 is 3.07 DAI. DAI is 18 decimals, WARP is 9 decimals.
     *  @return price_ uint
     */

    function getUniswapWarpPrice() external view override returns (uint256 price_) {
        IUniswapV2Pair pair = IUniswapV2Pair(warpDaiPair);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (IUniswapV2Pair(warpDaiPair).token0() == WARP) {
            price_ = (reserve1 * (10**IERC20Decimals(pair.token0()).decimals())) / reserve0 / 1e16;
        } else {
            price_ = (reserve0 * (10**IERC20Decimals(pair.token1()).decimals())) / reserve1 / 1e16;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

library FixedPoint {
    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint256) {
        return uint256(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        unchecked {
            require(denominator > 0, 'FixedPoint::fraction: division by zero');
            if (numerator == 0) return FixedPoint.uq112x112(0);

            if (numerator <= type(uint144).max) {
                uint256 result = (numerator << RESOLUTION) / denominator;
                require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
                return uq112x112(uint224(result));
            } else {
                uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
                require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
                return uq112x112(uint224(result));
            }
        }
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        unchecked {
            uint256 mm = mulmod(x, y, type(uint256).max);
            l = x * y;
            h = mm - l;
            if (mm < l) h -= 1;
        }
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        unchecked {
            uint256 pow2 = d & (~d + 1);
            d /= pow2;
            l /= pow2;
            l += h * (((~pow2 + 1)) / pow2 + 1);
            uint256 r = 1;
            r *= 2 - d * r;
            r *= 2 - d * r;
            r *= 2 - d * r;
            r *= 2 - d * r;
            r *= 2 - d * r;
            r *= 2 - d * r;
            r *= 2 - d * r;
            r *= 2 - d * r;
            return l * r;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        unchecked {
            (uint256 l, uint256 h) = fullMul(x, y);
            uint256 mm = mulmod(x, y, d);
            if (mm > l) h -= 1;
            l -= mm;
            require(h < d, 'FullMath::mulDiv: overflow');
            return fullDiv(l, h, d);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

library BitMath {
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract WarpBase is Initializable {
    bool public paused;
    address public owner;
    mapping(address => bool) public pausers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseChanged(address indexed by, bool indexed paused);

    /** ========  MODIFIERS ========  */

    /** @notice modifier for owner only calls */
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /** @notice pause toggler */
    modifier onlyPauseToggler() {
        require(owner == msg.sender || pausers[msg.sender], 'Ownable: caller is not the owner');
        _;
    }

    /** @notice modifier for pausing contracts */
    modifier whenNotPaused() {
        require(!paused || owner == msg.sender || pausers[msg.sender], 'Feature is paused');
        _;
    }

    /** ========  INITALIZE ========  */
    function __WarpBase_init() internal initializer {
        owner = msg.sender;
        paused = false;
    }

    /** ========  OWNERSHIP FUNCTIONS ========  */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /** ===== PAUSER FUNCTIONS ========== */

    /** @dev allow owner to add or remove pausers */
    function setPauser(address _pauser, bool _allowed) external onlyOwner {
        pausers[_pauser] = _allowed;
    }

    /** @notice toggle pause on and off */
    function setPause(bool _paused) external onlyPauseToggler {
        paused = _paused;

        emit PauseChanged(msg.sender, _paused);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface IValuator {
    function valuation(address _LP, uint256 _amount) external view returns (uint256);

    function getUniswapWarpPrice() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint256);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface IERC20Decimals {
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}