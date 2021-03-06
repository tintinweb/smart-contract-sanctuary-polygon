//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";

contract FlashResolverPolygon is Helper {
    function getRoutes() public view returns (uint16[] memory) {
        return flashloanAggregator.getRoutes();
    }

    function getBestRoutes(address[] memory _tokens, uint256[] memory _amounts)
        public
        returns (
            uint16[] memory,
            uint256,
            bytes[] memory
        )
    {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        bytes[] memory _data;

        uint16[] memory bRoutes_;
        uint256 feeBPS_;
        uint16[] memory routes_ = getRoutes();
        uint16[] memory routesWithAvailability_ = getRoutesWithAvailability(
            routes_,
            _tokens,
            _amounts
        );
        uint16 j = 0;
        bRoutes_ = new uint16[](routes_.length);
        _data = new bytes[](routes_.length);
        feeBPS_ = type(uint256).max;
        for (uint256 i = 0; i < routesWithAvailability_.length; i++) {
            if (routesWithAvailability_[i] == 8) {
                PoolKey memory bestKey = getUniswapBestFee(_tokens, _amounts);
                uint256 uniswapFeeBPS_ = uint256(bestKey.fee / 100);
                uint256 instaFeeBps_ = flashloanAggregator.InstaFeeBPS();
                if (uniswapFeeBPS_ < instaFeeBps_) {
                    uniswapFeeBPS_ = instaFeeBps_;
                }
                if (feeBPS_ > uniswapFeeBPS_) {
                    feeBPS_ = uniswapFeeBPS_;
                    bRoutes_[0] = routesWithAvailability_[i];
                    _data[0] = abi.encode(bestKey);
                    j = 1;
                } else if (feeBPS_ == bestKey.fee) {
                    bRoutes_[j] = routesWithAvailability_[i];
                    _data[j] = abi.encode(bestKey);
                    j++;
                }
            } else if (routesWithAvailability_[i] != 0) {
                uint256 routeFeeBPS_ = flashloanAggregator.calculateFeeBPS(
                    routesWithAvailability_[i]
                );
                if (feeBPS_ > routeFeeBPS_) {
                    feeBPS_ = routeFeeBPS_;
                    bRoutes_[0] = routesWithAvailability_[i];
                    j = 1;
                } else if (feeBPS_ == routeFeeBPS_) {
                    bRoutes_[j] = routesWithAvailability_[i];
                    j++;
                }
            } else {
                break;
            }
        }
        uint16[] memory bestRoutes_ = new uint16[](j);
        bytes[] memory bestData_ = new bytes[](j);
        for (uint256 i = 0; i < j; i++) {
            bestRoutes_[i] = bRoutes_[i];
            bestData_[i] = _data[i];
        }
        return (bestRoutes_, feeBPS_, bestData_);
    }

    function getData(address[] memory _tokens, uint256[] memory _amounts)
        public
        returns (
            uint16[] memory routes_,
            uint16[] memory bestRoutes_,
            uint256 bestFee_,
            bytes[] memory bestData_
        )
    {
        (routes_) = getRoutes();
        (bestRoutes_, bestFee_, bestData_) = getBestRoutes(_tokens, _amounts);
    }
}

contract InstaFlashResolverPolygon is FlashResolverPolygon {
    receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./variables.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helper is Variables {
    function getAaveAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            (, , , , , , , , bool isActive, ) = aaveProtocolDataProvider
                .getReserveConfigurationData(_tokens[i]);
            (address aTokenAddr, , ) = aaveProtocolDataProvider
                .getReserveTokensAddresses(_tokens[i]);
            if (isActive == false) return false;
            if (token_.balanceOf(aTokenAddr) < _amounts[i]) return false;
        }
        return true;
    }

    function getBalancerAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            if (token_.balanceOf(balancerLendingAddr) < _amounts[i]) {
                return false;
            }
        }
        return true;
    }

    function getRoutesWithAvailability(
        uint16[] memory _routes,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (uint16[] memory) {
        uint16[] memory routesWithAvailability_ = new uint16[](_routes.length);
        uint256 j = 0;
        for (uint256 i = 0; i < _routes.length; i++) {
            if (_routes[i] == 1 || _routes[i] == 7) {
                if (getAaveAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 5) {
                if (getBalancerAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 8) {
                if (_tokens.length == 1 || _tokens.length == 2) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else {
                require(false, "invalid-route");
            }
        }
        return routesWithAvailability_;
    }

    function bubbleSort(address[] memory _tokens, uint256[] memory _amounts)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            for (uint256 j = 0; j < _tokens.length - i - 1; j++) {
                if (_tokens[j] > _tokens[j + 1]) {
                    (
                        _tokens[j],
                        _tokens[j + 1],
                        _amounts[j],
                        _amounts[j + 1]
                    ) = (
                        _tokens[j + 1],
                        _tokens[j],
                        _amounts[j + 1],
                        _amounts[j]
                    );
                }
            }
        }
        return (_tokens, _amounts);
    }

    function validateTokens(address[] memory _tokens) internal pure {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            require(_tokens[i] != _tokens[i + 1], "non-unique-tokens");
        }
    }

    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1, "Token not sorted");
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    function getUniswapBestFee(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal returns (PoolKey memory) {
        if (_tokens.length == 1) {
            PoolKey memory bestKey;

            address[] memory checkTokens_ = new address[](3);
            checkTokens_[0] = usdcAddr;
            checkTokens_[1] = wethAddr;
            checkTokens_[2] = wmaticAddr;

            uint24[] memory checkFees_ = new uint24[](3);
            checkFees_[0] = 100;
            checkFees_[1] = 500;
            checkFees_[2] = 3000;

            for (uint256 i = 0; i < checkTokens_.length; i++) {
                for (uint256 j = 0; j < checkFees_.length; j++) {
                    if (_tokens[0] == checkTokens_[i]) {
                        break;
                    }
                    bestKey.fee = checkFees_[j];
                    if (_tokens[0] < checkTokens_[i]) {
                        bestKey.token0 = _tokens[0];
                        bestKey.token1 = checkTokens_[i];
                    } else {
                        bestKey.token0 = checkTokens_[i];
                        bestKey.token1 = _tokens[0];
                    }
                    IUniswapV3Pool pool = IUniswapV3Pool(
                        computeAddress(uniswapFactoryAddr, bestKey)
                    );
                    if (address(pool).code.length > 0) {
                        uint256 balance0 = IERC20(bestKey.token0).balanceOf(
                            address(pool)
                        );
                        uint256 balance1 = IERC20(bestKey.token1).balanceOf(
                            address(pool)
                        );
                        if (_tokens[0] < checkTokens_[i]) {
                            if (balance0 >= _amounts[0]) {
                                return bestKey;
                            }
                        } else {
                            if (balance1 >= _amounts[0]) {
                                return bestKey;
                            }
                        }
                    }
                }
            }
            bestKey.fee = type(uint24).max;
            return bestKey;
        } else {
            PoolKey memory bestKey;
            bestKey.token0 = _tokens[0];
            bestKey.token1 = _tokens[1];

            uint24[] memory checkFees_ = new uint24[](3);
            checkFees_[0] = 100;
            checkFees_[1] = 500;
            checkFees_[2] = 3000;

            for (uint256 i = 0; i < checkFees_.length; i++) {
                bestKey.fee = checkFees_[i];
                IUniswapV3Pool pool = IUniswapV3Pool(
                    computeAddress(uniswapFactoryAddr, bestKey)
                );
                if (address(pool).code.length > 0) {
                    uint256 balance0 = IERC20(bestKey.token0).balanceOf(
                        address(pool)
                    );
                    uint256 balance1 = IERC20(bestKey.token1).balanceOf(
                        address(pool)
                    );
                    if (balance0 >= _amounts[0] && balance1 >= _amounts[1]) {
                        return bestKey;
                    }
                }
            }
            bestKey.fee = type(uint24).max;
            return bestKey;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {InstaFlashloanAggregatorInterface, IAaveProtocolDataProvider, IUniswapV3Pool} from "./interfaces.sol";

contract Variables {
    address public constant aaveLendingAddr =
        0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address public constant aaveProtocolDataProviderAddr =
        0x7551b5D2763519d4e37e8B81929D336De671d46d;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(aaveProtocolDataProviderAddr);

    address public constant balancerLendingAddr =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    address private flashloanAggregatorAddr =
        0xB2A7F20D10A006B0bEA86Ce42F2524Fde5D6a0F4;
    InstaFlashloanAggregatorInterface internal flashloanAggregator =
        InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);

    address public constant wethAddr = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant usdcAddr = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant wmaticAddr = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
    address public constant uniswapFactoryAddr =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface InstaFlashloanAggregatorInterface {
    function getRoutes() external pure returns (uint16[] memory);

    function calculateFeeBPS(uint256 _route) external view returns (uint256);

    function tokenToCToken(address) external view returns (address);

    function InstaFeeBPS() external view returns (uint256);
}

interface IAaveProtocolDataProvider {
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            bool,
            bool,
            bool
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address,
            address,
            address
        );
}

interface IUniswapV3Pool {
    function balance0() external returns (uint256);

    function balance1() external returns (uint256);
}