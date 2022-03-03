// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/core/IManager.sol";

import "./libraries/OperationsLib.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract holding configuration for everything contract
/// @author Cosmin Grigore (@gcosmintech)
contract Manager is IManager, Ownable {
    /// @notice returns holding manager address
    address public override holdingManager;

    /// @notice returns stablecoin manager address
    address public override stablesManager;

    /// @notice returns the available strategy manager
    address public override strategyManager;

    /// @notice returns the available dex manager
    address public override dexManager;

    /// @notice returns the protocol token address
    address public override protocolToken;

    /// @notice returns the default performance fee
    uint256 public override performanceFee = 1000; //1%

    /// @notice returns the fee address
    address public override feeAddress;

    /// @notice returns the amount of protocol tokens
    ///         rewarded for pre-minting a holding contract
    uint256 public override mintingTokenReward = 10**8; //TODO Change placeholder value

    /// @notice returns the max amount of available holdings
    uint256 public override maxAvailableHoldings = 100; //TODO Change placeholder value

    /// @notice returns true/false for contracts' whitelist status
    mapping(address => bool) public override isContractWhitelisted;

    /// @notice returns true if token is whitelisted
    mapping(address => bool) public override isTokenWhitelisted;

    /// @notice Sets the global fee address
    /// @param _val The address of the receiver.
    function setFeeAddress(address _val)
        public
        override
        onlyOwner
        validAddress(_val)
    {
        emit FeeAddressUpdated(feeAddress, _val);
        feeAddress = _val;
    }

    /// @notice updates the strategy manager address
    /// @param _strategy strategy manager's address
    function setStrategyManager(address _strategy)
        external
        override
        onlyOwner
        validAddress(_strategy)
    {
        require(_strategy != address(0), "ERR: INVALID ADDRESS");
        require(strategyManager != _strategy, "ERR: ALREADY SET");
        emit StrategyManagerUpdated(strategyManager, _strategy);
        strategyManager = _strategy;
    }

    /// @notice updates the dex manager address
    /// @param _dex dex manager's address
    function setDexManager(address _dex)
        external
        override
        onlyOwner
        validAddress(_dex)
    {
        require(dexManager != _dex, "ERR: ALREADY SET");
        emit DexManagerUpdated(dexManager, _dex);
        dexManager = _dex;
    }

    /// @notice sets the holding manager address
    /// @param _holding strategy's address
    function setHoldingManager(address _holding)
        external
        override
        onlyOwner
        validAddress(_holding)
    {
        require(holdingManager != _holding, "ERR: ALREADY SET");
        emit HoldingManagerUpdated(holdingManager, _holding);
        holdingManager = _holding;
    }

    /// @notice sets the stablecoin manager address
    /// @param _stables strategy's address
    function setStablecoinManager(address _stables)
        external
        override
        onlyOwner
        validAddress(_stables)
    {
        require(stablesManager != _stables, "ERR: ALREADY SET");
        emit StablecoinManagerUpdated(stablesManager, _stables);
        stablesManager = _stables;
    }

    /// @notice sets the protocol token address
    /// @param _protocolToken protocol token address
    function setProtocolToken(address _protocolToken)
        external
        override
        onlyOwner
        validAddress(_protocolToken)
    {
        require(protocolToken != _protocolToken, "ERR: ALREADY SET");
        emit ProtocolTokenUpdated(protocolToken, _protocolToken);
        protocolToken = _protocolToken;
    }

    /// @notice sets the performance fee
    /// @dev should be less than FEE_FACTOR
    /// @param _fee fee amount
    function setPerformanceFee(uint256 _fee)
        external
        override
        onlyOwner
        validAmount(_fee)
    {
        require(_fee < OperationsLib.FEE_FACTOR, "ERR: INVALID FEE");
        emit PerformanceFeeUpdated(performanceFee, _fee);
        performanceFee = _fee;
    }

    /// @notice sets the protocol token reward for pre-minting holdings
    /// @param _amount protocol token amount
    function setMintingTokenReward(uint256 _amount)
        external
        override
        onlyOwner
        validAmount(_amount)
    {
        emit MintingTokenRewardUpdated(mintingTokenReward, _amount);
        mintingTokenReward = _amount;
    }

    /// @notice sets the max amount of available holdings
    /// @param _amount max amount of available holdings
    function setMaxAvailableHoldings(uint256 _amount)
        external
        override
        onlyOwner
        validAmount(_amount)
    {
        emit MaxAvailableHoldingsUpdated(maxAvailableHoldings, _amount);
        maxAvailableHoldings = _amount;
    }

    /// @notice whitelists a contract
    /// @param _contract contract's address
    function whitelistContract(address _contract)
        external
        override
        onlyOwner
        validAddress(_contract)
    {
        require(!isContractWhitelisted[_contract], "ERR: ALREADY WHITELISTED");
        isContractWhitelisted[_contract] = true;
        emit ContractWhitelisted(_contract);
    }

    /// @notice removes a contract from the whitelisted list
    /// @param _contract contract's address
    function blacklistContract(address _contract)
        external
        override
        onlyOwner
        validAddress(_contract)
    {
        require(isContractWhitelisted[_contract], "ERR: NOT AUTHORIZED");
        isContractWhitelisted[_contract] = false;
        emit ContractBlacklisted(_contract);
    }

    /// @notice whitelists a token
    /// @param _token token's address
    function whitelistToken(address _token)
        external
        override
        onlyOwner
        validAddress(_token)
    {
        require(!isTokenWhitelisted[_token], "ERR: ALREADY WHITELISTED");
        isTokenWhitelisted[_token] = true;
        emit TokenWhitelisted(_token);
    }

    /// @notice removes a token from whitelist
    /// @param _token token's address
    function removeToken(address _token)
        external
        override
        onlyOwner
        validAddress(_token)
    {
        require(isTokenWhitelisted[_token], "ERR: NOT AUTHORIZED");
        isTokenWhitelisted[_token] = false;
        emit TokenRemoved(_token);
    }

    // -- modifiers --

    modifier validAddress(address _address) {
        require(_address != address(0), "ERR: INVALID ADDRESS");
        _;
    }
    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "ERR: INVALID AMOUNT");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for a the manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IManager {
    /// @notice emitted when the dex manager is set
    event DexManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the strategy manager is set
    event StrategyManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the holding manager is set
    event HoldingManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the stablecoin manager is set
    event StablecoinManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token address is changed
    event ProtocolTokenUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token reward for minting is updated
    event MintingTokenRewardUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the max amount of available holdings is updated
    event MaxAvailableHoldingsUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the fee address is changed
    event FeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );
    /// @notice emitted when the default fee is updated
    event PerformanceFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);

    /// @notice emitted when a new contract is whitelisted
    event ContractWhitelisted(address indexed contractAddress);

    /// @notice emitted when a contract is removed from the whitelist
    event ContractBlacklisted(address indexed contractAddress);

    /// @notice emitted when a new token is whitelisted
    event TokenWhitelisted(address indexed token);

    /// @notice emitted when a new token is removed from the whitelist
    event TokenRemoved(address indexed token);

    /// @notice returns true/false for contracts' whitelist status
    function isContractWhitelisted(address _contract)
        external
        view
        returns (bool);

    /// @notice returns true/false for token's whitelist status
    function isTokenWhitelisted(address _token) external view returns (bool);

    /// @notice returns holding manager address
    function holdingManager() external view returns (address);

    /// @notice returns stablecoin manager address
    function stablesManager() external view returns (address);

    /// @notice returns the available strategy manager
    function strategyManager() external view returns (address);

    /// @notice returns the available dex manager
    function dexManager() external view returns (address);

    /// @notice returns the protocol token address
    function protocolToken() external view returns (address);

    /// @notice returns the default performance fee
    function performanceFee() external view returns (uint256);

    /// @notice returns the amount of protocol tokens
    ///         rewarded for pre-minting a holding contract
    function mintingTokenReward() external view returns (uint256);

    /// @notice returns the max amount of available holdings
    function maxAvailableHoldings() external view returns (uint256);

    /// @notice returns the fee address
    function feeAddress() external view returns (address);

    /// @notice updates the fee address
    /// @param _fee the new address
    function setFeeAddress(address _fee) external;

    /// @notice updates the strategy manager address
    /// @param _strategy strategy manager's address
    function setStrategyManager(address _strategy) external;

    /// @notice updates the dex manager address
    /// @param _dex dex manager's address
    function setDexManager(address _dex) external;

    /// @notice sets the holding manager address
    /// @param _holding strategy's address
    function setHoldingManager(address _holding) external;

    /// @notice sets the protocol token address
    /// @param _protocolToken protocol token address
    function setProtocolToken(address _protocolToken) external;

    /// @notice sets the stablecoin manager address
    /// @param _stables strategy's address
    function setStablecoinManager(address _stables) external;

    /// @notice sets the performance fee
    /// @param _fee fee amount
    function setPerformanceFee(uint256 _fee) external;

    /// @notice sets the protocol token reward for pre-minting holdings
    /// @param _amount protocol token amount
    function setMintingTokenReward(uint256 _amount) external;

    /// @notice sets the max amount of available holdings
    /// @param _amount max amount of available holdings
    function setMaxAvailableHoldings(uint256 _amount) external;

    /// @notice whitelists a contract
    /// @param _contract contract's address
    function whitelistContract(address _contract) external;

    /// @notice removes a contract from the whitelisted list
    /// @param _contract contract's address
    function blacklistContract(address _contract) external;

    /// @notice whitelists a token
    /// @param _token token's address
    function whitelistToken(address _token) external;

    /// @notice removes a token from whitelist
    /// @param _token token's address
    function removeToken(address _token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OperationsLib {
    uint256 internal constant FEE_FACTOR = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_FACTOR;
    }

    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "OperationsLib::safeApprove: approve failed"
        );
    }
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