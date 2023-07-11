// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ITest1 {
    function getBaseProvider(address token) external view returns (address);

    function getRandomProvider(address token, uint256 randomWord) external returns (address);

    function getUserBalance(address account, address token) external view returns (uint256);

    function getTotalFunds(address token) external view returns (uint256);

    function getUserTips(address account, address token) external view returns (uint256);

    function getTotalUserTips(address token) external view returns (uint256);

    function getUserStaked(address account, address token) external view returns (uint256);

    function getTotalStakes(address token) external view returns (uint256);

    function getDepositerHLBalance(address depositer, address token) external view returns (uint256);

    function getTotalHL(address token) external view returns (uint256);

    function getProviderPayout(address account, address token) external view returns (uint256);

    function getTotalPayout(address token) external view returns (uint256);

    function getBalancedStatus(address token) external view returns (bool);

    function setCoreOwnership(address newOwner) external;

    function disableCoreOwnership(address owwner) external;

    function setTrustedForwarder(address trustedForwarder) external;

    function addTokens(address token) external;

    function disableToken(address token) external;

    function setBaseProvider(address account, address token) external;

    function handleBalance(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleUserTips(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleStakes(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleHL(address bettor, address token, uint256 amount, uint256 operator) external;

    function handlePayout(address bettor, address token, uint256 amount, uint256 operator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ITest1.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PoolOperations is ReentrancyGuard {
    // Type Declarations
    enum PoolStatus {
        Active,
        Full,
        Settled
    }
    struct Pool {
        bytes32 matchId;
        bytes32 poolId;
        uint totalPoolAmt;
        uint totalSpots;
        uint spotsLeft;
        uint entryAmt;
        bytes32 poolType;
        PoolStatus status;
        uint8 teamLimit;
    }

    mapping(bytes32 => mapping(address => bytes32[])) poolToPlayerToTeams;
    mapping(bytes32 => mapping(address => uint)) poolToPlayerToStakes;
    mapping(bytes32 => mapping(address => bool)) settledPlayers;

    // Pool Contract Variables
    address private poolsOwner;
    ITest1 private immutable Core;

    mapping(bytes32 => Pool) public pools;

    event PoolCreated(Pool indexed _pool);
    event UserParticipated(Pool indexed _pool, address indexed _participant, address indexed _token);
    event PoolUserSettled(Pool indexed _pool, address indexed _user, uint8 indexed _result, address _token, uint _stake, uint _winAmount);
    event PoolStatusChanged(Pool indexed _pool);

    constructor(address owner, address payable core) {
        poolsOwner = owner;
        Core = ITest1(core);
    }

    modifier onlyPoolsOwner() {
        if (msg.sender != poolsOwner) {
            revert("Pools__OnlyOwnerMethod");
        }
        _;
    }

    function transferPoolsOwnership(address _newOwner) public onlyPoolsOwner {
        if (_newOwner == address(0)) {
            revert("Incorrect address");
        }
        //require(_newOwner != address(0), "Incorect address");
        poolsOwner = _newOwner;
    }

    function setCoreOwnershipInPools(address newOwner) public onlyPoolsOwner {
        Core.setCoreOwnership(newOwner);
    }

    function disableCoreOwnershipInPools(address owner) public onlyPoolsOwner {
        Core.disableCoreOwnership(owner);
    }

    function createPool(bytes32 _poolKey, bytes32 _matchId, uint _totalPoolAmt, uint _totalSpots, uint _entryAmt, bytes32 _poolType, uint8 _maxParticipation) public onlyPoolsOwner {
        pools[_poolKey] = Pool(_matchId, _poolKey, _totalPoolAmt, _totalSpots, _totalSpots, _entryAmt, _poolType, PoolStatus.Active, _maxParticipation);
        emit PoolCreated(pools[_poolKey]);
    }

    function participate(bytes32 _poolId, address _token, bytes32 _teamId) public nonReentrant {
        if (pools[_poolId].status != PoolStatus.Active) revert("Pool is not currently Active.");
        if (pools[_poolId].entryAmt > Core.getUserBalance(msg.sender, _token)) revert("Insufficient Funds.");
        if (pools[_poolId].spotsLeft == 0) revert("No spots left in the pool.");
        if (poolToPlayerToTeams[_poolId][msg.sender].length == pools[_poolId].teamLimit) revert("Already participated with max teams.");

        pools[_poolId].spotsLeft--;
        poolToPlayerToTeams[_poolId][msg.sender].push(_teamId);
        poolToPlayerToStakes[_poolId][msg.sender] += pools[_poolId].entryAmt;

        if (pools[_poolId].spotsLeft == 0) {
            pools[_poolId].status = PoolStatus.Full;
            emit PoolStatusChanged(pools[_poolId]);
        }

        Core.handleStakes(msg.sender, _token, pools[_poolId].entryAmt, 1);
        Core.handleBalance(msg.sender, _token, pools[_poolId].entryAmt, 0);

        if (!Core.getBalancedStatus(_token)) revert("Pools__ContractIsNotBalanced");

        emit UserParticipated(pools[_poolId], msg.sender, _token);
    }

    function settlePoolUser(bytes32 _poolId, address _user, uint8 _result, address _token, uint _stake, uint _winAmount) public onlyPoolsOwner {
        if (poolToPlayerToTeams[_poolId][_user].length > 0) revert("No a participant.");
        if (settledPlayers[_poolId][_user]) revert("Already Settled.");

        if (Core.getUserStaked(_user, _token) < _stake) revert("Less stake balance.");
        Core.handleStakes(_user, _token, _stake, 0);
        Core.handleHL(Core.getBaseProvider(_token), _token, _stake, 1);

        //win
        if (_result == 1) {
            if (Core.getTotalHL(_token) < _winAmount) revert("Less hl balance.");
            Core.handleBalance(_user, _token, _winAmount, 1);
            Core.handleHL(Core.getBaseProvider(_token), _token, _winAmount, 0);
        }

        if (!Core.getBalancedStatus(_token)) revert("Pools__ContractIsNotBalanced");
        settledPlayers[_poolId][_user] == true;

        if (pools[_poolId].status != PoolStatus.Settled) {
            pools[_poolId].status = PoolStatus.Settled;
            emit PoolStatusChanged(pools[_poolId]);
        }

        emit PoolUserSettled(pools[_poolId], _user, _result, _token, _stake, _winAmount);
    }

    function settleEmptyPool(bytes32 _poolId) public onlyPoolsOwner {
        if (pools[_poolId].totalSpots != pools[_poolId].spotsLeft) revert("Pools has players.");
        pools[_poolId].status = PoolStatus.Settled;
        emit PoolStatusChanged(pools[_poolId]);
    }
}