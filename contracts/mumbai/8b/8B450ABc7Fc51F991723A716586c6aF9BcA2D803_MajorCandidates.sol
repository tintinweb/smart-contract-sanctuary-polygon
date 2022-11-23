// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../interfaces/IMajorCandidates.sol';

/// @dev MajorCandidates contract
/// @author Alexandas
contract MajorCandidates is IMajorCandidates, Initializable {
	struct Candidate {
		address prev;
		address next;
		uint256 amount;
	}

	/// @dev return `Stake` contract address
	IStake public override stake;

	/// @dev return `Election` contract address
	IElection public override election;

	/// @dev return head candidate address
	address public headCandidate;

	/// @dev return tail candidate address
	address public tailCandidate;

	/// @dev return total candidates
	uint256 public totalCandidates;

	/// @dev return candidate inforamtion
	mapping(address => Candidate) public candidates;

	/// @dev return max major candidates
	uint256 public override MAX_MAJOR_CANDIDATES;

	modifier onlyStake() {
		require(msg.sender == address(stake), 'MajorCandidates: caller must be Stake contract');
		_;
	}

	modifier onlyElection() {
		require(msg.sender == address(election), 'MajorCandidates: caller must be Election contract');
		_;
	}

	modifier validateGrades() {
		address[] memory olds = majorCandidateList();
		_;
		address[] memory news = majorCandidateList();
		address downgrade = _differOne(olds, news);
		address upgrade = _differOne(news, olds);
		if (downgrade != address(0)) {
			stake.downgrade(downgrade);
		}
		if (upgrade != address(0)) {
			stake.upgrade(upgrade);
		}
	}

	/// @dev proxy initialize function
	/// @param _stake `Stake` contract
	/// @param _election `Election` contract
	function initialize(IStake _stake, IElection _election) external initializer {
		_setStake(_stake);
		_setElection(_election);
		_setMaxMajorLength(9);
	}

	/// @dev return whether a candidate is a major candidate
	/// @param candidate candidate address
	/// @return existed the candidate is a major candidate
	function isMajor(address candidate) public view override returns (bool existed) {
		if (headCandidate != address(0)) {
			address from = headCandidate;
			for (uint256 i = 0; i < MAX_MAJOR_CANDIDATES; i++) {
				if (from == candidate) {
					existed = true;
					break;
				}
				from = candidates[from].next;
				if (from == address(0)) {
					break;
				}
			}
		}
	}

	/// @dev return all major candidates
	/// @return majors all major candidates
	function majorCandidateList() public view override returns (address[] memory majors) {
		uint256 limit = totalCandidates > MAX_MAJOR_CANDIDATES ? MAX_MAJOR_CANDIDATES : totalCandidates;
		if (headCandidate != address(0)) {
			majors = new address[](limit);
			address candidate = headCandidate;
			for (uint256 i = 0; i < limit; i++) {
				majors[i] = candidate;
				candidate = candidates[candidate].next;
				if (candidate == address(0)) {
					break;
				}
			}
		}
	}

	function _differOne(address[] memory inner, address[] memory outer) internal pure returns (address one) {
		for (uint256 i = 0; i < inner.length; i++) {
			bool _exists = false;
			for (uint256 j = 0; j < outer.length; j++) {
				if (inner[i] == outer[j]) {
					_exists = true;
					break;
				}
			}
			if (!_exists) {
				one = inner[i];
				break;
			}
		}
	}

	/// @dev insert or update a candidate in the sorted list
	/// @param candidate candidate address
	/// @param amount candidate votes
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function upsetCandidateWithAnchor(
		address candidate,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external override onlyElection validateGrades {
		require(candidate != address(0), 'MajorCandidates: invalid candidate');
		if (totalCandidates == 0) {
			// insert the first candidate into the list
			require(amount > 0, 'MajorCandidates: zero amount');
			totalCandidates++;
			headCandidate = candidate;
			tailCandidate = candidate;
		} else {
			if (amount == 0) {
				if (!exists(candidate)) {
					return;
				}
				return _removeCandidate(candidate);
			}
			if (!exists(anchor)) {
				if (exists(candidate)) {
					anchor = candidate;
				} else {
					anchor = tailCandidate;
				}
			}
			if (!exists(candidate)) {
				totalCandidates++;
			}
			address start = anchor;
			if (amount > candidates[start].amount) {
				for (uint256 i = 0; i < maxSlippage; i++) {
					if (start == headCandidate) {
						if (start != candidate) {
							_resetCandidate(candidate);
							candidates[candidate].prev = address(0);
							headCandidate = candidate;
							candidates[start].prev = candidate;
							candidates[candidate].next = start;
						}
						break;
					}
					address startPrev = candidates[start].prev;
					uint256 startPrevAmount = candidates[startPrev].amount;
					if (startPrevAmount > amount) {
						if (start != candidate && startPrev != candidate) {
							_resetCandidate(candidate);
							candidates[start].prev = candidate;
							candidates[startPrev].next = candidate;
							candidates[candidate].prev = startPrev;
							candidates[candidate].next = start;
						}
						break;
					}
					start = startPrev;
				}
			} else if (amount < candidates[start].amount) {
				for (uint256 i = 0; i < maxSlippage; i++) {
					if (start == tailCandidate) {
						if (start != candidate) {
							_resetCandidate(candidate);
							candidates[candidate].next = address(0);
							tailCandidate = candidate;
							candidates[start].next = candidate;
							candidates[candidate].prev = start;
						}
						break;
					}
					address startNext = candidates[start].next;
					uint256 startNextAmount = candidates[startNext].amount;
					if (startNextAmount < amount) {
						if (start != candidate && startNext != candidate) {
							_resetCandidate(candidate);
							candidates[start].next = candidate;
							candidates[startNext].prev = candidate;
							candidates[candidate].prev = start;
							candidates[candidate].next = startNext;
						}
						break;
					}
					start = startNext;
				}
			}
		}
		candidates[candidate].amount = amount;
		address prev = candidates[candidate].prev;
		address next = candidates[candidate].next;
		if (prev == address(0)) {
			require(candidate == headCandidate, 'MajorCandidates: invalid order 1');
		} else {
			require(candidates[prev].amount > amount, 'MajorCandidates: invalid order 2');
		}
		if (next == address(0)) {
			require(candidate == tailCandidate, 'MajorCandidates: invalid order 3');
		} else {
			require(candidates[next].amount < amount, 'MajorCandidates: invalid order 4');
		}
		emit UpsetCandidate(candidate, amount);
	}

	/// @dev emit removed a candidate from the sorted list
	/// @param candidate candidate address
	function remove(address candidate) external override onlyStake validateGrades {
		_removeCandidate(candidate);
	}

	function _resetCandidate(address candidate) internal {
		if (!exists(candidate)) {
			return;
		}
		if (headCandidate == candidate) {
			address candidateNext = candidates[candidate].next;
			if (candidateNext != address(0)) {
				candidates[candidateNext].prev = address(0);
				headCandidate = candidateNext;
			}
		} else if (tailCandidate == candidate) {
			address candidatePrev = candidates[candidate].prev;
			if (candidatePrev != address(0)) {
				candidates[candidatePrev].next = address(0);
			}
			tailCandidate = candidatePrev;
		} else {
			address candidatePrev = candidates[candidate].prev;
			address candidateNext = candidates[candidate].next;
			candidates[candidateNext].prev = candidatePrev;
			candidates[candidatePrev].next = candidateNext;
		}
	}

	function _removeCandidate(address candidate) internal {
		require(exists(candidate), 'MajorCandidates: nonexistent candidate');
		address curPrev = candidates[candidate].prev;
		address curNext = candidates[candidate].next;
		if (curPrev == address(0)) {
			// remove head
			if (curNext == address(0)) {
				headCandidate = address(0);
			} else {
				candidates[curNext].prev = address(0);
				headCandidate = curNext;
			}
		} else if (curNext == address(0)) {
			// remove tail
			candidates[curPrev].next = address(0);
			tailCandidate = curPrev;
		} else {
			// remove body
			candidates[curPrev].next = curNext;
			candidates[curNext].prev = curPrev;
		}
		delete candidates[candidate];
		totalCandidates--;
		if (totalCandidates == 0) {
			headCandidate = address(0);
			tailCandidate = address(0);
		}
		emit RemoveCandidate(candidate);
	}

	/// @dev return whether a candidate is existed in the sorted list
	/// @param candidate candidate address
	/// @return whether the candidate is existed in the sorted list
	function exists(address candidate) public view override returns (bool) {
		return candidates[candidate].amount > 0;
	}

	function _setStake(IStake _stake) internal {
		stake = _stake;
		emit StakeUpdated(_stake);
	}

	function _setElection(IElection _election) internal {
		election = _election;
		emit ElectionUpdated(_election);
	}

	function _setMaxMajorLength(uint256 max) internal {
		MAX_MAJOR_CANDIDATES = max;
		emit MaxMajorCandidateUpdated(max);
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IElection.sol';
import './IStake.sol';

/// @dev MajorCandidates interface
/// @author Alexandas
interface IMajorCandidates {

	/// @dev emit when max major candidates changed
	/// @param max max major candidates
	event MaxMajorCandidateUpdated(uint256 max);

	/// @dev emit when `Election` contract changed
	/// @param election `Election` contract address
	event ElectionUpdated(IElection election);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when a candidate insert or update in the sorted list
	/// @param candidate candidate address
	/// @param amount candidate votes
	event UpsetCandidate(address candidate, uint256 amount);

	/// @dev emit when a candidate removed from the sorted list
	/// @param candidate candidate address
	event RemoveCandidate(address candidate);

	/// @dev insert or update a candidate in the sorted list
	/// @param candidate candidate address
	/// @param amount candidate votes
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function upsetCandidateWithAnchor(
		address candidate,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev emit removed a candidate from the sorted list
	/// @param candidate candidate address
	function remove(address candidate) external;

	/// @dev return max major candidates
	function MAX_MAJOR_CANDIDATES() external view returns(uint256);

	/// @dev return `Election` contract address
	function election() external view returns(IElection);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return whether a candidate is existed in the sorted list
	/// @param candidate candidate address
	/// @return whether the candidate is existed in the sorted list
	function exists(address candidate) external view returns (bool);

	/// @dev return whether a candidate is a major candidate
	/// @param candidate candidate address
	/// @return existed the candidate is a major candidate
	function isMajor(address candidate) external view returns(bool existed);

	/// @dev return all major candidates
	/// @return majors all major candidates
	function majorCandidateList() external view returns(address[] memory majors);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IElection.sol';
import './IMajorCandidates.sol';
import './ISlasher.sol';
import './IPools.sol';
import './ICandidateRegistry.sol';

/// @dev Stake interface
/// @author Alexandas
interface IStake is IPools, ICandidateRegistry {

	/// @dev emit when `Election` contract changed
	/// @param election `Election` contract address
	event ElectionUpdated(IElection election);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event IMajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when `Slasher` contract updated
	/// @param slasher `Slasher` contract 
	event SlasherUpdated(ISlasher slasher);

	/// @dev emit when minimum stake updated
	/// @param amount minimum stake
	event MinStakeUpdated(uint256 amount);

	/// @dev emit when stake frozen period updated
	/// @param period stake frozen period
	event StakeFrozenPeriodUpdated(uint256 period);

	/// @dev emit when a candidate upgraded
	/// @param candidate candidate address
	/// @param fromGrade from grade
	/// @param toGrade to grade
	event Upgrade(address candidate, Types.Grade fromGrade, Types.Grade toGrade);

	/// @dev emit when a candidate downgraded
	/// @param candidate candidate address
	/// @param fromGrade from grade
	/// @param toGrade to grade
	event Downgrade(address candidate, Types.Grade fromGrade, Types.Grade toGrade);

	/// @dev emit when a candidate staked tokens
	/// @param from token consumer
	/// @param candidate candidate address
	/// @param amount token amount
	event Stake(address from, address candidate, uint256 amount);

	event ApplyWithdrawn(address candidate, uint256 amount);

	event ApplyQuit(address candidate);

	/// @dev emit when a candidate withdraw tokens
	/// @param candidate candidate address
	/// @param to token receiver
	/// @param amount token amount
	event Withdrawn(address candidate, address to, uint256 amount);

	/// @dev emit when a candidate claimed reward
	/// @param candidate candidate address
	/// @param to token receiver
	/// @param amount token amount
	event Claimed(address candidate, address to, uint256 amount);

	/// @dev emit when a candidate allocate reward for the voters
	/// @param candidate candidate address
	/// @param amount token amount
	event VoterAllocated(address candidate, uint256 amount);

	/// @dev emit when the reward for a candidate
	/// @param candidate candidate address
	/// @param amount token amount
	event CandidateAllocated(address candidate, uint256 amount);

	/// @dev emit when the vote reward coefficient updated
	/// @param coef vote reward coefficient
	event VoteRewardCoefUpdated(uint256 coef);

	/// @dev emit when drafted a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	event DraftSlash(address candidate, uint256 pendingSlash);

	/// @dev emit when rejected a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	event RejectSlash(address candidate, uint256 pendingSlash);

	/// @dev emit when executed a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	/// @param beneficiaries slash reward beneficiaries
	/// @param amounts slash reward amounts
	/// @param burned burned amount
	event ExcuteSlash(address candidate, uint256 pendingSlash, address[] beneficiaries, uint256[] amounts, uint256 burned);

	/// @dev return `Election` contract
	function election() external view returns(IElection);

	/// @dev return `MajorCandidates` contract
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return `Slasher` contract
	function slasher() external returns(ISlasher);

	/// @dev candidate stake tokens
	/// @param amount token amount
	function stake(uint256 amount) external;

	/// @dev candidate apply to quit
	function applyQuit() external;

	/// @dev register a candidate and stake tokens
	/// @param amount token amount
	/// @param manifest node manifest
	function registerAndStake(uint256 amount, string memory manifest) external;

	/// @dev candidate quit from the protocol
	/// @param to token receiver
	function quit(address to) external;

	/// @dev candidate claim reward from the protocol
	/// @param to token receiver
	function claim(address to) external;

	/// @dev candidate withdraw the tokens and claim reward from the protocol
	/// @param amount token amount
	/// @param to token receiver
	// function withdrawAndClaim(uint256 amount, address to) external;

	/// @dev return pending reward for a specific candidate
	/// @param candidate candidate address
	/// @return pending reward for the candidate
	function pendingReward(address candidate) external view returns (uint256 pending);

	/// @dev set voter slash reward coefficient
	/// @param coef voter reward coefficient
	function setVoteRewardCoef(uint256 coef) external;

	/// @dev set allocate the reward to voters from the candidate
	/// @param candidate candidate address
	function voterAllocate(address candidate) external;

	/// @dev return voter reward coefficient for a specific candidate
	/// @param candidate candidate address
	/// @return coef voter reward coefficient
	function voteRewardCoef(address candidate) external view returns (uint256 coef);

	/// @dev return pending voters allocation for a specific candidate
	/// @param candidate candidate address
	/// @return pending pending voters allocation
	function pendingVoterAllocation(address candidate) external view returns (uint256 pending);

	/// @dev return pending candidate allocation
	/// @param candidate candidate address
	/// @return pending pending candidate allocation
	function pendingCandidateAllocation(address candidate) external view returns (uint256 pending);

	/// @dev upgrade a candidate
	/// @param candidate candidate address
	function upgrade(address candidate) external;

	/// @dev downgrade a candidate
	/// @param candidate candidate address
	function downgrade(address candidate) external;

	/// @dev draft a slash for a candidate
	/// @param candidate candidate address
	/// @param amount slash amount
	function draftSlash(address candidate, uint256 amount) external;

	/// @dev reject a slash for a candidate
	/// @param candidate candidate address
	/// @param pendingSlash real slash amount
	function rejectSlash(address candidate, uint256 pendingSlash) external;

	/// @dev executed a slash for a candiate
	/// @param candidate candidate address
	/// @param slash slash amount
	/// @param beneficiaries slash reward beneficiaries
	/// @param amounts slash reward amounts
	/// @param burned burned amount
	function executeSlash(
		address candidate, 
		uint256 slash,
		address[] memory beneficiaries, 
		uint256[] memory amounts,
		uint256 burned
	) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IRewarder.sol';
import './IStake.sol';
import './IMajorCandidates.sol';
import './IERC20.sol';

/// @dev Election contract interface
/// @author Alexandas
interface IElection {

	/// @dev emit when ERC20 token address updated
	/// @param token ERC20 token address
	event TokenUpdated(IERC20 token);

	/// @dev emit when `Rewarder` contract updated
	/// @param rewarder `Rewarder` contract 
	event RewarderUpdated(IRewarder rewarder);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event MajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when vote frozen period updated
	/// @param period vote frozen period
	event VoteFrozenPeriodUpdated(uint256 period);

	/// @dev emit when shares updated for a specific candidate
	/// @param candidate candidate address
	event ShareUpdated(address candidate);

	/// @dev emit when voter voted for a candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param amount token amount
	event Vote(address candidate, address voter, uint256 amount);

	/// @dev emit when voter claimed the reward
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param to receiver address
	/// @param amount reward amount
	event Claimed(address candidate, address voter, address to, uint256 amount);

	/// @dev emit when voter apply withdrawn the votes
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param nonce withdraw nonce
	/// @param amount reward amount
	event ApplyWithdrawn(uint256 nonce, address candidate, address voter, uint256 amount);

	/// @dev emit when voter withdrawn the votes
	/// @param nonce withdraw nonce
	/// @param voter voter address
	/// @param to receiver address
	/// @param amount reward amount
	event Withdrawn( uint256 nonce, address voter, address to, uint256 amount);

	/// @dev voter vote a specific candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param amount reward amount
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function vote(
		address candidate,
		address voter,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev voter claim reward for a specific candidate
	/// @param candidate candidate address
	/// @param to receiver address
	function claim(address candidate, address to) external;

	/// @dev voter apply withdraw reward for a specific candidate
	/// @param candidate candidate address
	/// @param amount reward amount
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function applyWithdraw(
		address candidate,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev voter withdraw votes and reward
	/// @param nonce withdraw nonce
	/// @param to receiver address
	/// @param amount reward amount
	function withdraw(uint256 nonce, address to, uint256 amount) external;

	/// @dev candidate allocate reward for the voters
	/// @param candidate candidate address
	/// @param amount reward amount
	function onAllocate(address candidate, uint256 amount) external;

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev return `Rewarder` contract address
	function rewarder() external view returns(IRewarder);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return `MajorCandidates` contract address
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return precision for shares
	function ACC_PRECISION() external view returns(uint256);

	/// @dev return votes for a specific candidate
	/// @param candidate candidate address
	/// @return votes for a specific candidate
	function voteSupply(address candidate) external view returns(uint256);

	/// @dev pending reward for a voter given a candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @return pending pending reward
	function pendingReward(address candidate, address voter) external view returns (uint256 pending);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';

/// @dev Candidate registry interface
/// @author Alexandas
interface ICandidateRegistry {

	/// @dev emit when candidate registered
	/// @param candidate candidate address
	event Register(address candidate);

	/// @dev register a candidate with node manifest
	/// @param manifest node manifest
	function register(string memory manifest) external;

	/// @dev return a candidate
	/// @param candidate candidate address
	/// @return candidate information
	function candidateInfo(address candidate) external view returns(Types.CandidateInfo memory);

	/// @dev return a candidate address for a specific node manifest
	/// @param manifest node manifest
	/// @return candidate address
	function manifestMap(string memory manifest) external view returns(address);

	/// @dev return whether a candidate is registered
	/// @param candidate candidate address
	/// @return whether the candidate is registered
	function isCandidateRegistered(address candidate) external view returns (bool);

	/// @dev return grade of a candidate
	/// @param candidate candidate address
	/// @return candidate grade
	function gradeOf(address candidate) external view returns (Types.Grade);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IERC20.sol';
import './IRewarder.sol';
import '../libraries/Types.sol';

/// @dev Pools interface
/// @author Alexandas
interface IPools {

	/// @dev emit when ERC20 Token contract updated
	/// @param token ERC20 Token contract
	event TokenUpdated(IERC20 token);

	/// @dev emit when `Rewarder` contract updated
	/// @param rewarder `Rewarder` contract 
	event RewarderUpdated(IRewarder rewarder);

	/// @dev emit when `rewardPerSecond` updated
	/// @param rewardPerSecond reward generated for per second
	event RewardPerSecondUpdated(uint256 rewardPerSecond);

	/// @dev emit when shares precision updated
	/// @param precision shares precision
	event PrecisionUpdated(uint256 precision);

	/// @dev emit when max coefficient updated
	/// @param maxCoef max coefficient
	event MaxCoefUpdated(uint256 maxCoef);

	/// @dev emit when add a pool
	/// @param grade pool grade
	event AddPool(Types.Grade grade);

	/// @dev emit when pool updated
	/// @param grade pool grade
	event PoolUpdated(Types.Grade grade);

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev return `Rewarder` contract address
	function rewarder() external view returns(IRewarder);

	/// @dev return precision for shares
	function ACC_PRECISION() external view returns(uint256);

	/// @dev return max coefficient
	function MAXCOEF() external view returns(uint256);

	/// @dev return total pools allocation points
	function totalAllocPoint() external view returns(uint256);

	/// @dev return reward generated for per second
	function rewardPerSecond() external view returns(uint256);

	/// @dev update a specific pool
	/// @param grade pool grade
	/// @return pool pool info
	function updatePool(Types.Grade grade) external returns (Types.PoolInfo memory pool);

	/// @dev return a specific pool
	/// @param grade pool grade
	/// @return pool pool info
	function poolInfo(Types.Grade grade) external view returns(Types.PoolInfo memory);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';
import './IMajorCandidates.sol';
import './IStake.sol';

/// @dev Slasher interface
/// @author Alexandas
interface ISlasher {

	/// @dev emit when governance address updated
	/// @param governance governance address
	event GovernanceUpdated(address governance);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event MajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when default slash amount updated
	/// @param amount slash amount
	event DefaultSlashAmountUpdated(uint256 amount);

	/// @dev emit when public notice period updated
	/// @param period public notice period
	event PublicNoticePeriodUpdated(uint256 period);

	/// @dev emit when max coefficient updated
	/// @param maxCoef max coefficient
	event MaxCoefUpdated(uint256 maxCoef);

	/// @dev emit when drafter slash reward coefficient updated
	/// @param drafterCoef drafter slash reward coefficient
	event DrafterCoefUpdated(uint64 drafterCoef);

	/// @dev emit when validator slash reward coefficient updated
	/// @param validatorCoef validator slash reward coefficient
	event ValidatorCoefUpdated(uint256 validatorCoef);

	/// @dev emit when executor slash reward coefficient updated
	/// @param executorCoef executor slash reward coefficient
	event ExecutorCoefUpdated(uint256 executorCoef);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	/// @param candidate candidate address
	/// @param slashBlock slashed block in posc
	/// @param manifest node manifest
	/// @param accuracy posc accuracy
	event DraftSlash(uint256 nonce, address candidate, uint64 slashBlock, string manifest, uint64 accuracy);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	event RejectSlash(uint256 nonce);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	event ExecuteSlash(uint256 nonce, address executor);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return `MajorCandidates` contract address
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return default slash amount
	function defaultSlashAmount() external view returns(uint256);

	/// @dev return public notice period
	function publicNoticePeriod() external view returns(uint256);

	/// @dev return current slash nonce
	function nonce() external view returns(uint256);

	/// @dev return max coefficient
	function MAXCOEF() external view returns(uint64);

	/// @dev return drafter slash reward coefficient
	function drafterCoef() external view returns(uint64);

	/// @dev return validator slash reward coefficient
	function validatorCoef() external view returns(uint64);

	/// @dev return executor slash reward coefficient
	function executorCoef() external view returns(uint64);

	/// @dev return slash information at a specific nonce
	/// @param _nonce nonce number
	/// @return slash information
	function getSlashAt(uint256 _nonce) external view returns(Types.SlashInfo memory);

	/// @dev return nonce given a candidate if the candidate is in slashing
	/// @param candidate candidate address
	/// @return nonce number
	function nonceOf(address candidate) external view returns(uint256);

	/// @dev set drafter slash reward coefficient
	/// @param _drafterCoef drafter slash reward coefficient
	function setDrafterCoef(uint64 _drafterCoef) external;

	/// @dev set validator slash reward coefficient
	/// @param _validatorCoef validator slash reward coefficient
	function setValidatorCoef(uint64 _validatorCoef) external;

	/// @dev set executor slash reward coefficient
	/// @param _executorCoef executor slash reward coefficient
	function setExecutorCoef(uint64 _executorCoef) external;

	/// @dev draft a slash
	/// @param slashBlock slashed block in posc
	/// @param manifest node manifest
	/// @param accuracy posc accuracy
	/// @param signatures major candidates signatures
	function draft(uint64 slashBlock, string memory manifest, uint64 accuracy, bytes[] memory signatures) external;

	/// @dev reject a slash
	/// @param manifest node manifest
	function reject(string memory manifest) external;

	/// @dev execute a slash
	/// @param manifest node manifest
	function execute(string memory manifest) external;

	/// @dev return whether candidate is in slashing
	/// @param candidate candidate address
	/// @return whether candidate is in slashing
	function slashExists(address candidate) external view returns(bool);

	/// @dev check whether signatures is valid
	/// @param hash message hash
	/// @param signatures signatures for major candidates
	/// @param signers major candidate signers
	function checkNSignatures(bytes32 hash, bytes[] memory signatures) external view returns(address[] memory signers);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

/// @dev Burnable ERC20 Token interface
/// @author Alexandas
interface IERC20 is IERC20Upgradeable {

	/// @dev burn tokens
	/// @param amount token amount
	function burn(uint256 amount) external;

	/// @dev burn tokens
	/// @param account user address
	/// @param amount token amount
	function burnFrom(address account, uint256 amount) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './IERC20.sol';

/// @dev Rewarder interface
/// @author Alexandas
interface IRewarder {

	/// @dev emit when ERC20 token address updated
	/// @param token ERC20 token address
	event TokenUpdated(IERC20 token);

	/// @dev emit when auth address updated
	/// @param auth authorized address
	event AuthUpdated(address auth);

	/// @dev emit when reward minted
	/// @param from authorized address
	/// @param to receiver address
	/// @param amount token amount
	event Minted(address from, address to, uint256 amount);

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev mint reward to receiver
	/// @param to receiver address
	/// @param amount token amount
	function mint(address to, uint256 amount) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

library Types {

	enum Grade {
		Null,
		Major,
		Secondary
	}

	struct CandidateApplyInfo {
		bool waitQuit;
		uint256 amount;
		uint256 endTime;
	}

	struct CandidateInfo {
		Grade grade;
		uint256 amount;
		int256 rewardDebt;
		uint256 allocation;
		uint256 locked;
		uint256 slash;
		string manifest;
	}

	struct PoolInfo {
		uint256 accPerShare;
		uint256 lastRewardTime;
		uint256 allocPoint;
	}

	enum SlashStatus {
		Drafted,
		Rejected,
		Executed
	}

	struct SlashInfo {
		address candidate;
		address drafter;
		address[] validators;
		uint256 amount;
		uint256 timestamp;
		SlashStatus status;
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}