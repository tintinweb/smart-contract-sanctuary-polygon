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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

struct Goal {
    string name;
    uint256 createdAt;
    uint256 expiredAt;
    bool achieved;
}

/// @title Game contract
/// @author Alexey Pavlov
/// @notice This contract stores goals and contains goals managements methods
contract Game is Ownable {
    event NewGoal(uint256 goalId, string name, uint256 createdAt, uint256 expiredAt, bool achieved);

    uint256 public createGoalFee = 0.000001 ether;
    Goal[] public goals;

    mapping(uint256 => address) public goalsToOwner;
    mapping(address => uint256) ownerGoalsCount;

    constructor() {}

    modifier ownerOf(uint256 _goalId) {
        require(msg.sender == goalsToOwner[_goalId], "Caller is not the owner of the goal");
        _;
    }

    function _createGoal(string memory _name, uint256 _expiredAt) internal {
        goals.push(Goal(_name, block.timestamp, _expiredAt, false));
        uint256 id = goals.length - 1;
        goalsToOwner[id] = msg.sender;
        ownerGoalsCount[msg.sender]++;
        emit NewGoal(id, _name, block.timestamp, _expiredAt, false);
    }

    function createGoal(string memory _name, uint256 _expiredAt) external payable {
        require(msg.value == createGoalFee, "Goal fee not paid");

        _createGoal(_name, _expiredAt);
    }

    /// @notice Returns the quantity of goals for the owner
    /// @param _owner The address of owner to get quantity goals
    /// @return Quantity of owner's goals
    function getGoalsByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](ownerGoalsCount[_owner]);
        uint256 counter = 0;

        for (uint256 i = 0; i < goals.length; i++) {
            if (goalsToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }

        return result;
    }

   /*function _isExpired(Goal storage _goal) internal view returns (bool) {
        return (_goal.expiredAt >= block.timestamp);
    }

    function _isAchieved(Goal storage _goal) internal view returns (bool) {
        return _goal.achieved;
    }

    function _isCompleted(Goal storage _goal) internal view returns (bool) {
        return _isExpired(_goal) || _isAchieved(_goal);
    }

    function changeName(uint256 _goalId, string calldata _newName) external ownerOf(_goalId) {
        goals[_goalId].name = _newName;
    }*/

    function setGoalAchieved(uint256 _goalId) external ownerOf(_goalId) {
        goals[_goalId].achieved = true;
    }

/*    function withdraw() external onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }*/

    function setCreateGoalFee(uint256 _fee) external onlyOwner {
        createGoalFee = _fee;
    }

    function getGoals() public view returns (Goal[] memory) {
        return goals;
    }

    function getCreateGoalFee() public view returns (uint256) {
        return createGoalFee;
    }
}