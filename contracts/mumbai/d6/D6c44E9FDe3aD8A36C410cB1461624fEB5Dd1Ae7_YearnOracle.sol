// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/oracle/IOracle.sol";
import "../interfaces/yearn/IYearnVault.sol";

contract YearnOracle is IOracle {
    /// Oracle to get the price of the LP tokens of Yearn finance vaults

    /// @notice Calculates the exchange rate
    /// @param _vault address of the vault
    function _get(address _vault) private view returns (uint256 rate) {
        require(_vault != address(0), "3048");
        rate = IYearnVault(_vault).pricePerShare();
        uint256 decimals = IYearnVault(_vault).decimals();
        if (decimals <= 18) {
            rate *= 10 ** (18 - decimals);
        } else {
            rate /= 10 ** (decimals - 18);
        }
    }

    /// @notice Converts the address of the vault into bytes
    /// @param _vault address of the vault
    function getDataParameter(address _vault)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_vault);
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the vault encoded in bytes
    function get(bytes calldata _data)
        external
        view
        override
        returns (bool, uint256)
    {
        address vault = abi.decode(_data, (address));
        return (true, _get(vault));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the vault encoded in bytes
    function peek(bytes calldata _data)
        public
        view
        override
        returns (bool, uint256)
    {
        address vault = abi.decode(_data, (address));
        return (true, _get(vault));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the vault encoded in bytes
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
        return "Yearn";
    }

    /// @notice Symbol of the oracle
    function symbol(bytes calldata)
        external
        pure
        override
        returns (string memory)
    {
        return "Yearn";
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

/// @title Interface for Yearn Vault contract
/// @author Cosmin Grigore (@gcosmintech)
interface IYearnVault {
    function token() external view returns (address);

    function decimals() external view returns (uint256);

    function governance() external view returns (address);

    function management() external view returns (address);

    function guardian() external view returns (address);

    function emergencyShutdown() external view returns (bool);

    function depositLimit() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256 _amount, address _recipient)
        external
        returns (uint256);

    function withdraw(
        uint256 _maxShares,
        address _recipient,
        uint256 _maxLoss
    ) external returns (uint256);

    function balanceOf(address _recipient) external view returns (uint256);
}