/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
}/// @notice Chainlink's price oracle interface
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}interface TokenRegistryInterface {
    /// @notice Emitted when a new token is registered with the protocol
    event TokenRegistered(string symbol, uint8 index);

    /// @notice Looks up price of given token index
    function getPrice(uint8 _index)
        external
        view
        returns (uint256 price, uint8 decimal);

    /// @notice Obtain the symbol of a given index
    function getSymbol(uint8 _index) external returns (string calldata symbol);

    /// @notice Given a string, return the associated token index
    function getTokenIndex(string calldata _symbol)
        external
        returns (uint8 index);

    /// @notice Registers a new token for use in Tug
    /// @param _symbol Associated String for human readability
    /// @param _chainlinkOracle Chainlink oracle address to be used to get price
    /// @return index of the new token.
    // function registerToken(string calldata _symbol, address _chainlinkOracle) external returns (uint index);
}
/// @title A registry for tokens and price oracles.
/// @notice Register new tokens and associated Chainlink price oracles in this contract.
contract TokenRegistry is TokenRegistryInterface, Ownable {
    /// @dev Used to determine index. Indices will start from 1 instead of 0.
    uint8 public tokenCount;
    mapping(uint8 => string) public symbols;
    mapping(string => uint8) private indexOfSymbols;
    mapping(uint8 => AggregatorV3Interface) public chainlinkOracles;

    // ------------------------- Errors ------------------------------------ //
    error SymbolAlreadyRegistered(string symbol);
    error UnableToReadOraclePriceDuringRegistry(address chainlinkAddress);
    error InvalidTokenIndex(uint8 invalidIndex);
    error InvalidPrice(uint8 index);

    // ------------------------- View Functions ------------------------------------ //
    /// @inheritdoc TokenRegistryInterface
    function getPrice(uint8 _index)
        external
        view
        override
        returns (uint256 price, uint8 decimal)
    {
        if (bytes(symbols[_index]).length == 0)
            revert InvalidTokenIndex(_index);
        AggregatorV3Interface aggregator = chainlinkOracles[_index];
        (
            ,
            /*uint80 roundID*/
            int256 clPrice, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = aggregator.latestRoundData();
        if (clPrice > 0) {
            price = uint256(clPrice);
            decimal = aggregator.decimals();
        } else {
            revert InvalidPrice(_index);
        }
    }

    /// @inheritdoc TokenRegistryInterface
    function getSymbol(uint8 _index)
        external
        view
        override
        returns (string memory symbol)
    {
        symbol = symbols[_index];
    }

    /// @inheritdoc TokenRegistryInterface
    function getTokenIndex(string calldata _symbol)
        public
        view
        override
        returns (uint8 index)
    {
        index = indexOfSymbols[_symbol];
    }

    // ------------------------- Mutative Functions ------------------------------------ //
    /// @notice Registers a new token for use in Tug
    /// @param _symbol Associated String for human readability
    /// @param _chainlinkOracle Chainlink oracle address to be used to get price
    /// @return index of the new token. Starts from 1.
    function registerToken(string calldata _symbol, address _chainlinkOracle)
        external
        onlyOwner
        returns (uint8 index)
    {
        if (getTokenIndex(_symbol) != 0)
            revert SymbolAlreadyRegistered(_symbol);
        AggregatorV3Interface aggregator = AggregatorV3Interface(
            _chainlinkOracle
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = aggregator.latestRoundData();
        if (price < 1)
            revert UnableToReadOraclePriceDuringRegistry(_chainlinkOracle);

        index = ++tokenCount;
        symbols[index] = _symbol;
        indexOfSymbols[_symbol] = index;
        chainlinkOracles[index] = aggregator;
    }
}