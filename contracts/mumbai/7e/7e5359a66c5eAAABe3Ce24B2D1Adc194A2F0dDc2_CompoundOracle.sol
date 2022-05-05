// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/oracle/IOracle.sol";
import "../interfaces/compound/ICompoundToken.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract CompoundOracle is IOracle {
    /// Oracle to get the price of the LP tokens of Compound (cTokens)

    /// @notice Calculates the exchange rate
    /// @param _cTokenAddress address of the cToken
    function _get(address _cTokenAddress) private returns (uint256) {
        require(_cTokenAddress != address(0), "3001");
        ICompoundToken cToken = ICompoundToken(_cTokenAddress);
        uint256 rate = cToken.exchangeRateCurrent();
        return _scaleRate(rate, cToken);
    }

    /// @notice Calculates the stored exchange rate
    /// @param _cTokenAddress address of the cToken
    function _peek(address _cTokenAddress) private view returns (uint256) {
        require(_cTokenAddress != address(0), "3001");
        ICompoundToken cToken = ICompoundToken(_cTokenAddress);
        uint256 rate = cToken.exchangeRateStored();
        return _scaleRate(rate, cToken);
    }

    function _scaleRate(uint256 _rate, ICompoundToken _cToken)
        private
        view
        returns (uint256)
    {
        IERC20Metadata underlying = IERC20Metadata(_cToken.underlying());
        uint256 underlyingDecimals = underlying.decimals();

        if (underlyingDecimals <= 8) {
            _rate *= 10**(8 - underlyingDecimals);
        } else {
            _rate /= 10**(underlyingDecimals - 8);
        }
        return _rate;
    }

    /// @notice Converts the address of the cToken into bytes
    /// @param _cTokenAddress address of the cToken
    function getDataParameter(address _cTokenAddress)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_cTokenAddress);
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the cToken encoded in bytes
    function get(bytes calldata _data)
        external
        override
        returns (bool, uint256)
    {
        address cToken = abi.decode(_data, (address));
        return (true, _get(cToken));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the cToken encoded in bytes
    function peek(bytes calldata _data)
        public
        view
        override
        returns (bool, uint256)
    {
        address cToken = abi.decode(_data, (address));
        return (true, _peek(cToken));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the cToken encoded in bytes
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
        return "Compound";
    }

    /// @notice Symbol of the oracle
    function symbol(bytes calldata)
        external
        pure
        override
        returns (string memory)
    {
        return "Compound";
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

/// @title Interface for the CToken
/// @author Cosmin Grigore (@gcosmintech)
interface ICompoundToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint);

    function decimals() external view returns (uint256);

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}