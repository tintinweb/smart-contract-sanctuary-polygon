// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

abstract contract RouterMigratable {
    constructor() {}

    event RouterMigrated(address _old, address _net);

    modifier onlyRouter() virtual {
        _;
    }

    function migrateRouter(address _newRouter) external virtual onlyRouter {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

struct Tokens {
    address feeToken;
    address credit;
    address bonus;
}

interface IAuctionFactory {
    function feeToken() external view returns (address);

    function creditToken() external view returns (address);

    function bonusToken() external view returns (address);

    function stakingTreasury() external view returns (address);

    function bidRouter() external view returns (address);

    function pools(uint256 id) external view returns (address);

    function isOperator(address _operator) external view returns (bool);

    function addUserVolume(address _user, uint256 _amount) external;

    function getTokens() external view returns (Tokens memory);

    function isPool(address _pool) external view returns (bool);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IBidRouter {

    function isPool(address _pool) external view returns (bool);

    function teamAddress() external view returns (address);

    function gasReceiver() external view returns (address);

    /// @notice pool function used when refunding a bid for credits
    function poolTransferTo(address _user, uint256 _amount) external;

    function onExpireThresholdReset(address _user) external;

    function gasFee() external view returns (uint256);

    function bid(
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external payable;

    function bidOnBehalf(
        address _user,
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external;

    function factoryDeclarePool(address _pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolInitializable {
    function initFirstRound(uint256 _firstRoundStart, uint256 _pid) external;

    function minValue() external view returns (uint256);

    function faceValue() external view returns (uint256);

    function minBids() external view returns (uint256);

    function bidFee() external view returns (uint256);

    function roundDuration() external view returns (uint256);

    function slotDecimals() external view returns (uint256);

    function maxOffer() external view returns (uint256);

    function coolOffPeriodTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPoolInitializable.sol";
import "../interfaces/IBidRouter.sol";
import "../interfaces/IAuctionFactory.sol";
import "../general-components/RouterMigratable.sol";

contract AuctionFactoryUniversal is Ownable, RouterMigratable, IAuctionFactory {
    /**
     * Events
     */

    /// @notice Event emitted when a new pool is created
    event AuctionPoolCreated(
        address poolAddress,
        uint256 indexed poolId,
        uint256 minValue,
        uint256 faceValue,
        uint256 roundDuration,
        uint256 bidFee,
        uint256 maxOffer,
        uint256 slotDecimals,
        uint256 minBids,
        uint256 firstRoundStartTime,
        uint256 coolOffPeriod,
        string poolType
    );

    /// @notice creation event
    event FactoryInitialized(address _feeToken, address _credit, address _bonus, address _router);

    /// @notice added operator
    event NewOperator(address _op);

    /// @notice added operator
    event RemovedOperator(address _op);

    /// @notice treasury declared
    event NewTreasury(address _treasury);

    /// @notice bonus token replaced
    event NewBonus(address _bonus);

    /// @notice lock factory from adding new pools
    event FactoryLocked();

    /// @notice user's onchain volume variable increase
    event VolumeIncreased(address _user, uint256 _amount);

    /**
     * Variables
     */

    /// @notice The address of feeToken token contract
    address public immutable feeToken;

    /// @notice The address of credit token contract
    address public immutable creditToken;

    /// @notice The address of the bid router
    address public bidRouter;

    /// @notice The address of bonus token contract
    address public bonusToken;

    /// @notice address through which will get feeToken that belongs to stakers
    address public stakingTreasury;

    /// @notice The list of pools
    address[] public pools;

    /// @notice Is pool locked from adding new pool
    bool public locked;

    /**
     * Mappings
     */

    /// @notice Operators can create pools and conduct action on them
    mapping(address => bool) public isOperator;

    /// @notice Mapping user => trading volume
    /// @notice This value is truthful and relevant only if the factory's creditToken is exclusive to fat-pools-only factories.
    mapping(address => uint256) public userVolume;

    /// @notice Mapping of pool address => pool id
    mapping(address => bool) public isPool;

    modifier onlyRouter() override {
        require(msg.sender == bidRouter, "Router only");
        _;
    }

    /**
     * @param _feeToken The address of feeToken which is used to pay the bid fee when placing bid (18 is the Max value of decimals)
     * @param _creditToken The address of the 1:1 feeToken backed credits that can be used to place bids
     * @param _bonusToken The address of the bonus token used to place non-backed bids
     * @param _bidRouter The address of the contract directing the bids to pool and handling the tokens transfers from users
     */
    constructor(address _feeToken, address _creditToken, address _bonusToken, address _bidRouter) {
        require(_feeToken!=address(0), "Fee token can not be address(0)");
        require(_creditToken!=address(0), "Credit can not be address(0)");
        require(_bonusToken!=address(0), "Bonus can not be address(0)");
        require(_bidRouter!=address(0), "Router can not be address(0)");
        //19+ decimal tokens will revert down contracts system flow, the auction system supports up to 18 decimals tokens.
        feeToken = _feeToken;
        creditToken = _creditToken;
        bonusToken = _bonusToken;
        bidRouter = _bidRouter;

        emit FactoryInitialized(_feeToken, _creditToken, _bonusToken, _bidRouter);
    }

    /**
     * @notice A function to add user volume
     *
     * @param _user Address of user receiving volume
     * @param _amount New bid volume in feeToken
     */
    function addUserVolume(address _user, uint256 _amount) external onlyRouter {
        userVolume[_user] += _amount;
        emit VolumeIncreased(_user, _amount);
    }

    /**
     * @notice Add new auction pool
     * @param _firstRoundStartTime The epoch of first round start time.
     * @param _pool The address of the newly added auction pool
     * @param _type The type of the pool used purely for event processing (e.g "cool pool")
     */
    function addPool(uint256 _firstRoundStartTime, IPoolInitializable _pool, string calldata _type) external onlyOwner {
        require(!isPool[address(_pool)], "Already pooled");
        require(!locked, "Factory is locked");

        uint256 _pid = pools.length;

        pools.push(address(_pool));

        // Add pool to the mapping
        isPool[address(_pool)] = true;

        _pool.initFirstRound(_firstRoundStartTime, _pid);

        //Handling no minValue pool
        uint256 _minValue;
        try _pool.minValue() returns (uint256 _realMinValue) {
            _minValue = _realMinValue;
        } catch {}

        emit AuctionPoolCreated(
            address(_pool),
            _pid,
            _minValue,
            _pool.faceValue(),
            _pool.roundDuration(),
            _pool.bidFee(),
            _pool.maxOffer(),
            _pool.slotDecimals(),
            _pool.minBids(),
            _firstRoundStartTime,
            _pool.coolOffPeriodTime(),
            _type
        );

        IBidRouter(bidRouter).factoryDeclarePool(address(_pool));
    }

    /**
     * VIEW FUNCTIONS
     */

    /**
     * @notice Return addresses of feeToken, Credit and Bonus
     *
     * @return _tokens List of token addresses
     */
    function getTokens() external view returns (Tokens memory _tokens) {
        _tokens = Tokens(feeToken, creditToken, bonusToken);
    }

    /**
     * @notice Returns the address of the current pool
     *
     * @return _poolLength The total number of the pool
     */
    function poolLength() public view returns (uint256 _poolLength) {
        _poolLength = pools.length;
    }

    /**
     * ADMIN FUNCTIONS
     */

    /**
     * @notice Add operator
     *
     * @param _operator The address of the operator to add
     */
    function addOperator(address _operator) external onlyOwner {
        isOperator[_operator] = true;
        emit NewOperator(_operator);
    }

    /**
     * @notice Remove operator
     *
     * @param _operator The address of the operator to remove
     */
    function removeOperator(address _operator) external onlyOwner {
        isOperator[_operator] = false;
        emit RemovedOperator(_operator);
    }

    /**
     * @notice Set the staking treasury address
     *
     * @param _treasury The address of the new staker's treasury
     */
    function setStakingTreasury(address _treasury) external onlyOwner {
        require(_treasury!=address(0), "Treasury can not be address(0)");
        stakingTreasury = _treasury;
        emit NewTreasury(_treasury);
    }

    /**
     * @notice Set new BonusToken
     *
     * @param _bonusToken The address of the new bonus token
     */
    /// @notice This causes issue with revoked bonus bids. Can be overcome if pool is fed with new bonus tokens
    function setBonusToken(address _bonusToken) external onlyOwner {
        require(_bonusToken!=address(0), "Bonus can not be address(0)");
        bonusToken = _bonusToken;
        emit NewBonus(_bonusToken);
    }

    function migrateRouter(address _newRouter) external override onlyRouter {
        require(_newRouter!=address(0), "Router can not be address(0)");
        emit RouterMigrated(bidRouter, _newRouter);
        bidRouter = _newRouter;
    }

    /// @notice lock the factory forever, preventing new pools
    function lockFactory(string memory _confirm) external onlyOwner {
        require(keccak256(abi.encodePacked(_confirm)) == keccak256(abi.encodePacked("Lock the factory forever")), "Not confirmed");
        require(!locked, "Already locked");

        locked = true;

        emit FactoryLocked();
    }
}