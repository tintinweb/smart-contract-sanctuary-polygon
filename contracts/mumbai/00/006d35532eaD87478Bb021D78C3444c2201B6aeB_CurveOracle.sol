// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/oracle/IOracle.sol";
import "../interfaces/curve/ICurvePriceGetter.sol";

contract CurveOracle is IOracle {
    /// Oracle to retrieve the price of the Curve LP Tokens

    /// @notice Calculates the exchange rate
    /// @param _pool address of the pool
    function _get(address _pool) public view returns (uint256 rate) {
        require(_pool != address(0), "3064");
        return ICurvePriceGetter(_pool).get_virtual_price();
    }

    /// @notice Converts the address of the pool into bytes
    /// @param _pool address of the pool
    function getDataParameter(address _pool)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_pool);
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the pool encoded in bytes
    function get(bytes calldata _data)
        external
        view
        override
        returns (bool, uint256)
    {
        address pool = abi.decode(_data, (address));
        return (true, _get(pool));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the pool encoded in bytes
    function peek(bytes calldata _data)
        public
        view
        override
        returns (bool, uint256)
    {
        address pool = abi.decode(_data, (address));
        return (true, _get(pool));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the pool encoded in bytes
    function peekSpot(bytes calldata _data)
        external
        view
        override
        returns (uint256)
    {
        (, uint256 rate) = peek(_data);
        return rate;
    }

    /// @notice Name of the oracle
    function name(bytes calldata)
        external
        pure
        override
        returns (string memory)
    {
        return "Curve-fi";
    }

    /// @notice Symbol of the oracle
    function symbol(bytes calldata)
        external
        pure
        override
        returns (string memory)
    {
        return "CRV";
    }
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

interface ICurvePriceGetter {
    // solhint-disable-next-line func-name-mixedcase
    function get_virtual_price() external view returns (uint256);
}