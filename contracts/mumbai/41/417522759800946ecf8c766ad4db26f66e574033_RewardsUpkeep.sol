/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/RewardsUpkeep.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.4;

interface ILiquidityOps {
    function getReward() external returns (uint256[] memory data);

    function harvestRewards() external;
}

interface IRewardsManager {
    function distribute(address _token) external;
}

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

contract RewardsUpkeep is KeeperCompatibleInterface, Ownable {
    // Rewards manager contract address
    address public rewardsManager;

    // Liquidity ops contract address
    address public liquidityOps;

    // Time interval between distributions
    uint256 public interval;

    // Timestamp of last getReward() and harvestRewards() calls
    uint256 public lastHarvest;

    // Last distribution time
    mapping(address => uint256) public lastTimeStamp;

    constructor(
        uint256 _updateInterval,
        address _rewardsManager,
        address _liquidityOps,
        address _fxs,
        address _temple
    ) {
        interval = _updateInterval;
        rewardsManager = _rewardsManager;
        liquidityOps = _liquidityOps;
        lastTimeStamp[_fxs] = block.timestamp;
        lastTimeStamp[_temple] = block.timestamp;
    }

    function addRewardToken(address _token) external onlyOwner {
        require(lastTimeStamp[_token] == 0, "Already exists");
        lastTimeStamp[_token] = block.timestamp;
    }

    function deleteRewardToken(address _token) external onlyOwner {
        require(lastTimeStamp[_token] > 0, "Doesn't exist");
        delete lastTimeStamp[_token];
    }

    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
    }

    function setRewardsManager(address _rewardsManager) external onlyOwner {
        rewardsManager = _rewardsManager;
    }

    function setLiquidityOps(address _liquidityOps) external onlyOwner {
        liquidityOps = _liquidityOps;
    }

    // Called by Chainlink Keepers to check if upkeep should be executed
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address token = abi.decode(checkData, (address));
        require(lastTimeStamp[token] > 0, "Doesn't exist");

        upkeepNeeded = (block.timestamp - lastTimeStamp[token]) > interval;
        performData = checkData;
    }

    // Called by Chainlink Keepers to distribute rewards
    function performUpkeep(bytes calldata performData) external override {
        // Check upkeep conditions again
        address token = abi.decode(performData, (address));
        require(lastTimeStamp[token] > 0, "Doesn't exist");
        require(
            (block.timestamp - lastTimeStamp[token]) > interval,
            "Too early"
        );

        // If last harvest was more than 10 minutes ago, get rewards
        if ((block.timestamp - lastHarvest) > 600) {
            ILiquidityOps(liquidityOps).getReward();
            ILiquidityOps(liquidityOps).harvestRewards();
            lastHarvest = block.timestamp;
        }

        IRewardsManager(rewardsManager).distribute(token);
        lastTimeStamp[token] = block.timestamp;
    }
}