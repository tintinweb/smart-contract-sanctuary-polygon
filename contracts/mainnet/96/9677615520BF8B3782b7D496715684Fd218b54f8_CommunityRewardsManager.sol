/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: gogo-contracts/contracts/gov/CommunityRewardsManager.sol


pragma solidity ^0.8.4;


interface ICommunityRewards {
    function updateReward(address account) external;

    function getRewardFor(address user) external;

    function resetInactiveMultipliers(
        uint256 totalRewardMultiplierSnapshot,
        address[] memory users
    ) external;
}

interface IGovStakingv2 {
    function paused() external returns (bool);
}

contract CommunityRewardsManager is Ownable {
    address private BLOCKER = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    address[] public communityRewardsList;
    mapping(address => uint256) public listIndexes;

    mapping(address => bool) allowed;

    address public store;
    address public govStaking;

    modifier isAllowed() {
        require(allowed[msg.sender], "msg is not allowed");
        _;
    }

    event AllowanceSet(address indexed account, bool allowance);
    event NewGovStaking(address indexed newAddress);
    event NewStore(address indexed newAddress);

    constructor(address _store) {
        store = _store;
        communityRewardsList.push(BLOCKER);
        // to avoid index 0 for other address
    }

    function updateAllRewards(address account) external {
        for (uint256 i = 1; i < communityRewardsList.length; i++) {
            ICommunityRewards(communityRewardsList[i]).updateReward(account);
        }
    }

    function getAllRewards(address account) external isAllowed {
        for (uint256 i = 1; i < communityRewardsList.length; i++) {
            ICommunityRewards(communityRewardsList[i]).getRewardFor(account);
        }
    }

    function resetSingleInactivMultiplier(
        uint256 totalRewardMultiplierSnapshot,
        address user
    ) external isAllowed {
        address[] memory users = new address[](1);
        users[0] = user;
        _resetInactiveMultipliers(totalRewardMultiplierSnapshot, users);
    }

    function resetInactiveMultipliers(
        uint256 totalRewardMultiplierSnapshot,
        address[] memory users
    ) external isAllowed {
        require(
            IGovStakingv2(govStaking).paused(),
            "GovStaking contract must be paused"
        );
        _resetInactiveMultipliers(totalRewardMultiplierSnapshot, users);
    }

    function _resetInactiveMultipliers(
        uint256 totalRewardMultiplierSnapshot,
        address[] memory users
    ) internal {
        for (uint256 i = 1; i < communityRewardsList.length; i++) {
            ICommunityRewards(communityRewardsList[i]).resetInactiveMultipliers(
                totalRewardMultiplierSnapshot,
                users
            );
        }
    }

    function getStoreAddress() external view returns (address) {
        return store;
    }

    // owner functions

    function addRewardContract(address newContract) external onlyOwner {
        require(
            listIndexes[newContract] == 0 && newContract != BLOCKER, // blocker needed for 0 check
            "address already added"
        );
        listIndexes[newContract] = communityRewardsList.length;
        communityRewardsList.push(newContract);
        emit AllowanceSet(newContract, true);
    }

    function removeRewardContract(address oldContract) external onlyOwner {
        require(
            listIndexes[oldContract] > 0 && oldContract != BLOCKER,
            "unknown address"
        );
        if (communityRewardsList.length > 2) {
            // length 1 = blocker address
            uint256 oldIndex = listIndexes[oldContract];
            listIndexes[
                communityRewardsList[communityRewardsList.length - 1]
            ] = oldIndex;
            communityRewardsList[oldIndex] = communityRewardsList[
                communityRewardsList.length - 1
            ];
        }
        communityRewardsList.pop();
        delete listIndexes[oldContract];
        emit AllowanceSet(oldContract, false);
    }

    function setAllowance(address allow, bool flag) external onlyOwner {
        allowed[allow] = flag;
    }

    function setStore(address newStore) external onlyOwner {
        store = newStore;
        emit NewStore(newStore);
    }

    function setGovStaking(address newGov) external onlyOwner {
        govStaking = newGov;
        emit NewGovStaking(newGov);
    }
}