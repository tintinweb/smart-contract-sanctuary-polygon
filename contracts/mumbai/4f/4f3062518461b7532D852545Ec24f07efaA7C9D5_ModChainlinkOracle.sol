// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/oracle/IModChainlinkOracle.sol";
import "../interfaces/oracle/IModAggregator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ModChainlinkOracle is IModChainlinkOracle, Ownable {
    /// Modified version of the basic Chainlink Oracle that returns
    /// all rates escaled to 1e18. Also it already contains a set of
    /// aggregators addesses on mainnet.

    /// @notice Mapping associating the token addresses to their aggregators
    mapping(address => address) public override aggregators;

    constructor() {
        // WETH
        _addAggregator(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );

        // WBTC
        _addAggregator(
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
        );

        // AAVE
        _addAggregator(
            0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
            0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012
        );

        // UNI
        _addAggregator(
            0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
            0x553303d460EE0afB37EdFf9bE42922D8FF63220e
        );

        // SUSHI
        _addAggregator(
            0x6B3595068778DD592e39A122f4f5a5cF09C90fE2,
            0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7
        );

        // CRV
        _addAggregator(
            0xD533a949740bb3306d119CC777fa900bA034cd52,
            0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f
        );

        // CVX
        _addAggregator(
            0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B,
            0xd962fC30A72A84cE50161031391756Bf2876Af5D
        );

        // MATIC
        _addAggregator(
            0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,
            0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676
        );

        // COMP
        _addAggregator(
            0xc00e94Cb662C3520282E6f5717214004A7f26888,
            0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5
        );

        // LINK
        _addAggregator(
            0x514910771AF9Ca656af840dff83E8264EcF986CA,
            0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c
        );
    }

    /// @notice Adds a new token=>aggregator pair
    /// @param _token address of the token
    /// @param _aggregator address of the aggregator
    function addAggregator(address _token, address _aggregator)
        external
        onlyOwner
    {
        require(_token != address(0), "3001");
        require(_aggregator != address(0), "3053");
        _addAggregator(_token, _aggregator);
    }

    function _addAggregator(address _token, address _aggregator) internal {
        aggregators[_token] = _aggregator;
        emit AggregatorAdded(_token, _aggregator);
    }

    /// @notice Calculates the exchange rate
    /// @param _aggregator address of the aggregator
    function _get(address _aggregator) public view returns (uint256 rate) {
        require(_aggregator != address(0), "3053");
        int256 answer = IModAggregator(_aggregator).latestAnswer();
        uint8 decimals = IModAggregator(_aggregator).decimals();
        rate = (1e18 * uint256(answer)) / (10**uint256(decimals));
    }

    /// @notice Encodes the address of the corresponding aggregator into bytes
    /// @param _token address of the token
    function getDataParameter(address _token)
        external
        view
        override
        returns (bytes memory)
    {
        return abi.encode(aggregators[_token]);
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the aggregator encoded in bytes
    function get(bytes calldata _data)
        external
        view
        override
        returns (bool, uint256)
    {
        address aggregator = abi.decode(_data, (address));
        return (true, _get(aggregator));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the aggregator encoded in bytes
    function peek(bytes calldata _data)
        public
        view
        override
        returns (bool, uint256)
    {
        address aggregator = abi.decode(_data, (address));
        return (true, _get(aggregator));
    }

    /// @notice Get the latest exchange rate
    /// @param _data address of the aggregator encoded in bytes
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
        return "ModChainlink";
    }

    /// @notice Symbol of the oracle
    function symbol(bytes calldata)
        external
        pure
        override
        returns (string memory)
    {
        return "MLINK";
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

// Chainlink Aggregator
interface IModAggregator {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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