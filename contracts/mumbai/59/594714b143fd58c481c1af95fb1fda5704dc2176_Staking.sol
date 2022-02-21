/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol


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

// File: @openzeppelin\contracts\security\Pausable.sol

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

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

// File: @openzeppelin\contracts\utils\Counters.sol

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts\stakingHelpers\StakingStructs.sol

pragma solidity ^0.8.0;

library StakingStructs {

	struct Reward {
	    address tokenAddress;
	    uint256 amount;
	}

	struct RandomBonus {
	    address tokenAddress;
	    uint256 min;
		uint256 max;
	}

	struct StakeInfo {
		bool active; 			// user in Staking or not
		uint256 cellId; 		// cellID of last staking
		uint256 endTimestamp;	// when staking ends
		uint256 bonusChance;	//percent
		Reward[] rewards;		// rewards to pay
		RandomBonus[] bonuses;
		string regionName;
		string monsterName;
		string monsterImageUrl;
	}

	struct CellInfo {
		bool active;
		uint256 stakeDuration;
		uint256 stakePrice;
		uint256 bonusChance;	//percent
		Reward[] rewards;
		RandomBonus[] bonuses;
		string regionName;
		string monsterName;
		string monsterImageUrl;
	}

}

// File: contracts\stakingHelpers\Cells.sol

pragma solidity ^0.8.0;




contract Cells is Ownable {

	using Counters for Counters.Counter;
	Counters.Counter private _cellIds;

	mapping (uint256 => StakingStructs.CellInfo) internal cellInfo;
	uint256 public activeCellsCount;


	function getMaxCellId() public view returns(uint256){
		return _cellIds.current();
	}


	function getCellInfo(uint256 _cellId) public view returns(StakingStructs.CellInfo memory){
		return cellInfo[_cellId];
	}


	function saveCellPrice(uint256 _cellId, uint256 _stakePrice) public onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].stakePrice = _stakePrice;
	}


	function saveCellBonusChance(uint256 _cellId, uint256 _bonusChance) public onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		require(_bonusChance<=100, 'Bonus chance should be <= 100%');
		cellInfo[_cellId].bonusChance = _bonusChance;
	}


	function saveCellDuration(uint256 _cellId, uint256 _duration) public onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].stakeDuration = _duration;
	}


	function saveCellRewards(uint256 _cellId, StakingStructs.Reward[] memory _rewards) public onlyOwner() {
		delete cellInfo[_cellId].rewards;
		uint256 rewardsLength = _rewards.length;
		StakingStructs.Reward memory oneReward;
		for (uint256 rewardIndex=0; rewardIndex<rewardsLength; rewardIndex++){
			oneReward.tokenAddress = _rewards[rewardIndex].tokenAddress;
			oneReward.amount = _rewards[rewardIndex].amount;
			cellInfo[_cellId].rewards.push(oneReward);
		}
	}


	function saveCellRandomBonuses(uint256 _cellId, StakingStructs.RandomBonus[] memory _bonuses) public onlyOwner() {
		delete cellInfo[_cellId].bonuses;
		StakingStructs.RandomBonus memory oneBonus;
		for (uint256 bonusIndex=0; bonusIndex<_bonuses.length; bonusIndex++){
			oneBonus.tokenAddress = _bonuses[bonusIndex].tokenAddress;
			oneBonus.min = _bonuses[bonusIndex].min;
			oneBonus.max = _bonuses[bonusIndex].max;
			cellInfo[_cellId].bonuses.push(oneBonus);
		}
	}


	function saveMonsterImageUrl(uint256 _cellId, string memory _monsterImageUrl) public onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].monsterImageUrl = _monsterImageUrl;
	}


	function saveMonsterName(uint256 _cellId, string memory _monsterName) public onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].monsterName = _monsterName;
	}


	function saveRegionName(uint256 _cellId, string memory _regionName) public onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].regionName = _regionName;
	}


	function addCell(uint256 _duration, uint256 _stakePrice, uint256 _bonusChance, StakingStructs.Reward[] memory _rewards, StakingStructs.RandomBonus[] memory _bonuses, string memory _regionName, string memory _monsterName, string memory _monsterImageUrl) public onlyOwner() {
		_cellIds.increment();
		uint256 id = _cellIds.current();
		cellInfo[id].active = true;
		cellInfo[id].stakeDuration = _duration;
		cellInfo[id].stakePrice = _stakePrice;
		cellInfo[id].bonusChance = _bonusChance;
		cellInfo[id].regionName = _regionName;
		cellInfo[id].monsterName = _monsterName;
		cellInfo[id].monsterImageUrl = _monsterImageUrl;

		StakingStructs.Reward memory oneReward;
		for (uint256 rewardIndex=0; rewardIndex<_rewards.length; rewardIndex++){
			oneReward.tokenAddress = _rewards[rewardIndex].tokenAddress;
			oneReward.amount = _rewards[rewardIndex].amount;
			cellInfo[id].rewards.push(oneReward);
		}

		StakingStructs.RandomBonus memory oneBonus;
		for (uint256 bonusIndex=0; bonusIndex<_bonuses.length; bonusIndex++){
			oneBonus.tokenAddress = _bonuses[bonusIndex].tokenAddress;
			oneBonus.min = _bonuses[bonusIndex].min;
			oneBonus.max = _bonuses[bonusIndex].max;
			cellInfo[id].bonuses.push(oneBonus);
		}
		activeCellsCount++;
	}


	function enableCell(uint256 _cellId) public onlyOwner() {
		require(!cellInfo[_cellId].active, 'already active');
		cellInfo[_cellId].active = true;
		activeCellsCount++;
	}


	function disableCell(uint256 _cellId) public onlyOwner() {
		require(cellInfo[_cellId].active, 'already disabled');
		cellInfo[_cellId].active = false;
		activeCellsCount--;
	}
}

// File: contracts\Staking.sol

pragma solidity ^0.8.0;






contract Staking is Ownable, Cells, Pausable {

	mapping(address => StakingStructs.StakeInfo) public stakeInfo;
	address[] private usersList;
	mapping(address => bool) internal usersExist;
	address public stakeTokenAdminAddress;	// owner of resource's contracts
	IERC20 public stakeToken;
	uint256 public activeStakesCount;
	mapping(address=>uint256) public statRewards;

	event Stake(address indexed user, uint256 cellId, uint256 returnTimestamp);
	event Reward(address indexed user, address indexed tokenAddress, uint256 tokenAmount);

	constructor (address _stakeTokenAddress, address _stakeTokenAdminAddress){
		stakeToken = IERC20(_stakeTokenAddress);
		stakeTokenAdminAddress = _stakeTokenAdminAddress;
	}

	function myStakeInfo() public view returns(StakingStructs.StakeInfo memory){
		return stakeInfo[msg.sender];
	}

	function pause() public onlyOwner() {
		_pause();
	}

	function unpause() public onlyOwner() {
		_unpause();
	}

	function stake(uint256 _cellId) public whenNotPaused {
		StakingStructs.CellInfo memory cellInfo = getCellInfo(_cellId);
		require(stakeInfo[msg.sender].active == false, 'You are already in staking');
		require(cellInfo.active == true, 'You cannot stake to disabled cell');
		stakeToken.transferFrom(msg.sender, stakeTokenAdminAddress, cellInfo.stakePrice);
		stakeInfo[msg.sender].active = true;
		stakeInfo[msg.sender].cellId = _cellId;
		stakeInfo[msg.sender].bonusChance = cellInfo.bonusChance;
		stakeInfo[msg.sender].endTimestamp = block.timestamp + cellInfo.stakeDuration;
		stakeInfo[msg.sender].regionName = cellInfo.regionName;
		stakeInfo[msg.sender].monsterName = cellInfo.monsterName;
		stakeInfo[msg.sender].monsterImageUrl = cellInfo.monsterImageUrl;

		delete stakeInfo[msg.sender].rewards;
		StakingStructs.Reward memory oneReward;
		for (uint256 rewardInd=0; rewardInd<cellInfo.rewards.length; rewardInd++){
			oneReward.tokenAddress = cellInfo.rewards[rewardInd].tokenAddress;
			oneReward.amount = cellInfo.rewards[rewardInd].amount;
			stakeInfo[msg.sender].rewards.push(oneReward);
		}

		delete stakeInfo[msg.sender].bonuses;
		StakingStructs.RandomBonus memory oneBonus;
		for (uint256 bonusInd=0; bonusInd<cellInfo.bonuses.length; bonusInd++){
			oneBonus.tokenAddress = cellInfo.bonuses[bonusInd].tokenAddress;
			oneBonus.min = cellInfo.bonuses[bonusInd].min;
			oneBonus.max = cellInfo.bonuses[bonusInd].max;
			stakeInfo[msg.sender].bonuses.push(oneBonus);
		}

		if (!usersExist[msg.sender]){
			usersList.push(msg.sender);
		}
		usersExist[msg.sender] = true;
		activeStakesCount++;
		emit Stake(msg.sender, _cellId, stakeInfo[msg.sender].endTimestamp);
	}

	function withdraw() public whenNotPaused {
		require(stakeInfo[msg.sender].active == true, 'You haven`t staked anything');
		require(stakeInfo[msg.sender].endTimestamp < block.timestamp, 'Staking time not ended');

		for (uint256 rewardInd=0; rewardInd<stakeInfo[msg.sender].rewards.length; rewardInd++){
			address rewardAddress = stakeInfo[msg.sender].rewards[rewardInd].tokenAddress;
			uint256 rewardAmount = stakeInfo[msg.sender].rewards[rewardInd].amount;
			IERC20 rewardInstance = IERC20(rewardAddress);
			rewardInstance.transferFrom(stakeTokenAdminAddress, msg.sender, rewardAmount);
			statRewards[rewardAddress] += rewardAmount;
			emit Reward(msg.sender, rewardAddress, rewardAmount);
		}

		(bool hasBonus, uint256 num) = checkFortune(stakeInfo[msg.sender].bonusChance);

		for (uint256 bonusInd=0; bonusInd<stakeInfo[msg.sender].bonuses.length; bonusInd++){
			uint256 minAmount = stakeInfo[msg.sender].bonuses[bonusInd].min;
			uint256 maxAmount = stakeInfo[msg.sender].bonuses[bonusInd].max;
			uint256 bonusAmount = random(minAmount, maxAmount);
			stakeInfo[msg.sender].bonuses[bonusInd].max = bonusAmount;
			if (hasBonus){
				address bonusAddress = stakeInfo[msg.sender].bonuses[bonusInd].tokenAddress;
				IERC20 bonusInstance = IERC20(bonusAddress);
				bonusInstance.transferFrom(stakeTokenAdminAddress, msg.sender, bonusAmount);
				statRewards[bonusAddress] += bonusAmount;
				emit Reward(msg.sender, bonusAddress, bonusAmount);
			}
		}

		stakeInfo[msg.sender].active = false;
		activeStakesCount--;
	}

	function editStakeToken(address _newStakeTokenAddress) public onlyOwner() {
		stakeToken = IERC20(_newStakeTokenAddress);
	}

	function editStakeTokenAdmin(address _newStakeTokenAdminAddress) public onlyOwner() {
		stakeTokenAdminAddress =_newStakeTokenAdminAddress;
	}

	function random(uint256 _min, uint256 _max)	public view	returns(uint256) {
		uint256 diff = _max - _min;
		uint256 seed = uint256(keccak256(abi.encodePacked(
			block.timestamp + block.difficulty +
			((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
			block.gaslimit +
			((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
			block.number
		))) % diff;
		return seed + _min;
	}

	function checkFortune(uint256 chancePercent) public view returns(bool, uint256){
		uint256 num = random(0,100);
		if (num <= chancePercent){
			return (true, num);
		}
		return (false, num);
	}

	function getUsers() public view returns (address[] memory){
		return usersList;
	}

}