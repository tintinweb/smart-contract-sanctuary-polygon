// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.2;

interface IvFlashSwapCallback {
    function vFlashSwapCallback(
        address tokenIn,
        address tokenOut,
        uint256 requiredBackAmount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.2;

import "../types.sol";

interface IvPair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );

    event Swap(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address indexed to
    );

    event SwapReserve(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address ikPool,
        address indexed to
    );

    event AllowListChanged(address[] tokens);

    event Sync(uint256 balance0, uint256 balance1);

    event FactoryChanged(address newFactory);

    event FeeChanged(uint24 fee, uint24 vFee);

    event ReserveThresholdChanged(uint256 newThreshold);

    event AllowListCountChanged(uint24 _maxAllowListCount);

    function fee() external view returns (uint24);

    function vFee() external view returns (uint24);

    function setFee(uint24 _fee, uint24 _vFee) external;

    function swapNative(
        uint256 amountOut,
        address tokenOut,
        address to,
        bytes calldata data
    ) external returns (uint256 _amountIn);

    function swapReserveToNative(
        uint256 amountOut,
        address ikPair,
        address to,
        bytes calldata data
    ) external returns (uint256 _amountIn);

    function swapNativeToReserve(
        uint256 amountOut,
        address ikPair,
        address to,
        bytes calldata data
    ) external returns (uint256 _amountIn);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function setAllowList(address[] memory _allowList) external;

    function setMaxAllowListCount(uint24 _maxAllowListCount) external;

    function calculateReserveRatio() external view returns (uint256 rRatio);

    function setMaxReserveThreshold(uint256 threshold) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function pairBalance0() external view returns (uint256);

    function pairBalance1() external view returns (uint256);

    function maxAllowListCount() external view returns (uint24);

    function getBalances() external view returns (uint256, uint256);

    function getLastBalances()
        external
        view
        returns (
            uint256 _lastBalance0,
            uint256 _lastBalance1,
            uint256 _blockNumber
        );

    function getTokens() external view returns (address, address);

    function reservesBaseValue(address reserveAddress)
        external
        view
        returns (uint256);

    function reserves(address reserveAddress) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.2;

struct VirtualPoolModel {
    uint24 fee;
    address token0;
    address token1;
    uint256 balance0;
    uint256 balance1;
    address commonToken;
}

struct VirtualPoolTokens {
    address jk0;
    address jk1;
    address ik0;
    address ik1;
}

struct ExchangeReserveCallbackParams {
    address jkPair1;
    address jkPair2;
    address ikPair2;
}

struct SwapCallbackData {
    address caller;
    uint256 tokenInMax;
    uint ETHValue;
    address jkPool;
}

struct PoolCreationDefaults {
    address factory;
    address token0;
    address token1;
    uint24 fee;
    uint24 vFee;
    uint24 maxAllowListCount;
    uint256 maxReserveRatio;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "./types.sol";
import "./interfaces/IvPair.sol";
import "./interfaces/IvFlashSwapCallback.sol";

contract vExchangeReserves is IvFlashSwapCallback {
    address immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function vFlashSwapCallback(
        address tokenIn,
        address tokenOut,
        uint256 requiredBackAmount,
        bytes calldata data
    ) external override {
        ExchangeReserveCallbackParams memory decodedData = abi.decode(
            data,
            (ExchangeReserveCallbackParams)
        );

        IvPair(decodedData.jkPair2).swapNativeToReserve(
            requiredBackAmount,
            decodedData.ikPair2,
            decodedData.jkPair1,
            new bytes(0)
        );
    }

    function exchange(
        address jkPair1,
        address ikPair1,
        address jkPair2,
        uint256 flashAmountOut,
        bytes calldata swapCallbackData
    ) external {
        IvPair(jkPair1).swapNativeToReserve(
            flashAmountOut,
            ikPair1,
            jkPair2,
            swapCallbackData
        );
    }
}