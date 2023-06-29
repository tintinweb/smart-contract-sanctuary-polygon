// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDexwinCore {
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

import "./IDexwinCore.sol";

contract PoolOperations {
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
    IDexwinCore private immutable Core;

    mapping(bytes32 => Pool) public pools;

    event PoolCreated(Pool indexed _pool);
    event UserParticipated(Pool indexed _pool, address indexed _participant, address indexed _token);
    event PoolUserSettled(Pool indexed _pool, address indexed _user, uint8 indexed _result, address _token, uint _stake, uint _winAmount);
    event PoolStatusChanged(Pool indexed _pool);

    constructor(address owner, address payable core) {
        poolsOwner = owner;
        Core = IDexwinCore(core);
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

    function participate(bytes32 _poolId, address _token, bytes32 _teamId) public {
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
        Core.handleHL(_user, _token, _stake, 1);

        //win
        if (_result == 1) {
            if (Core.getTotalHL(_token) < _winAmount) revert("Less hl balance.");
            Core.handleBalance(_user, _token, _winAmount, 1);
            Core.handleHL(_user, _token, _winAmount, 0);
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