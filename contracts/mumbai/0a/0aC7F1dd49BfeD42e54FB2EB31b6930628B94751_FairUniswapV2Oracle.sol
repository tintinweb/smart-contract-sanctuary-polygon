// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/oracle/IModChainlinkOracle.sol";
import "../interfaces/oracle/IOracle.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../libraries/Babylonian.sol";

contract FairUniswapV2Oracle is IOracle {
    /// Oracle to get the price of UniswapV2 / Sushiswap LP pair tokens
    /// This is different from the SimpleUniswapV2Oracle because the other one
    /// might be susceptible to a flash-loan sandwich attack, so the calculation
    /// method here differs to infer the reserve ratio from the ratio of the
    /// underlying assets' fair prices.
    /// To get the price of each underlying asset we use the ModChainlinkOracle

    /// @notice base oracle used to get the price of each underlying asset of the pair
    IModChainlinkOracle public baseOracle;

    /// @notice creates the contract
    /// @param _baseOracle address of the ModChainlinkOracle used as base oracle
    constructor(address _baseOracle) {
        baseOracle = IModChainlinkOracle(_baseOracle);
    }

    /// @notice Calculates the exchange rate
    /// @param _pair address of the pair contract
    function _get(address _pair) private view returns (uint256 rate) {
        require(_pair != address(0), "3058");
        address token0 = IUniswapV2Pair(_pair).token0();
        address token1 = IUniswapV2Pair(_pair).token1();
        uint256 totalSupply = IUniswapV2Pair(_pair).totalSupply();
        (uint256 r0, uint256 r1, ) = IUniswapV2Pair(_pair).getReserves();
        bytes memory token0OracleData = baseOracle.getDataParameter(token0);
        bytes memory token1OracleData = baseOracle.getDataParameter(token1);
        uint256 token0Price = baseOracle.peekSpot(token0OracleData);
        uint256 token1Price = baseOracle.peekSpot(token1OracleData);
        uint256 sqrtReserves = Babylonian.sqrt(r0 * r1);
        uint256 sqrtPrices = Babylonian.sqrt(token0Price*token1Price);
        rate = 2*(sqrtReserves * sqrtPrices) / totalSupply;
    }

    /// @notice Converts the address of the pair into bytes
    /// @param _pair address of the pair
    function getDataParameter(address _pair) public pure returns (bytes memory) {
        return abi.encode(_pair);
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the pair encoded in bytes
    function get(bytes calldata _data) public view override returns (bool, uint256) {
        address pair = abi.decode(_data, (address));
        return (true, _get(pair));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the pair encoded in bytes
    function peek(bytes calldata _data)
        public
        view
        override
        returns (bool, uint256)
    {
        address pair = abi.decode(_data, (address));
        return (true, _get(pair));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the pair encoded in bytes
    function peekSpot(bytes calldata _data)
        public
        view
        override
        returns (uint256)
    {
        (, uint256 rate) = peek(_data);
        return rate;
    }

    /// @notice Name of the oracle
    function name(bytes calldata) public pure override returns (string memory) {
        return "Fair Uniswap V2";
    }

    /// @notice Symbol of the oracle
    function symbol(bytes calldata)
        public
        pure
        override
        returns (string memory)
    {
        return "F-UNI-V2";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IOracle.sol";

interface IModChainlinkOracle is IOracle{
    event AggregatorAdded(address token, address aggregator);

    function aggregators(address token) external view returns (address);

    function getDataParameter(address token)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @dev MAKE SURE THIS HAS 10^18 decimals
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    // solhint-disable-next-line func-name-mixedcase
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}