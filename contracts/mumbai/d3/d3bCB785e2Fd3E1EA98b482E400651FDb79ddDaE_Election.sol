// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../interfaces/IStake.sol';
import '../interfaces/IElection.sol';

contract Election is IElection, Initializable {
	struct VoterInfo {
		uint256 amount;
		uint256 rewardDebt;
	}

	IERC20 public override token;

	IStake public override stake;

	IMajorCandidates public override majorCandidates;

	uint256 public override ACC_PRECISION;

	mapping(address => mapping(address => VoterInfo)) public voters;

	mapping(address => uint256) public override voteSupply;

	mapping(address => uint256) public accPerShares;

	modifier onlyStake() {
		require(msg.sender == address(stake), 'MajorCandidates: caller must be Stake contract');
		_;
	}

	function initialize(
		IERC20 _token,
		IStake _stake,
		IMajorCandidates _majorCandidates
	) external initializer {
		_setToken(_token);
		_setStake(_stake);
		_setMajorCandidates(_majorCandidates);
		ACC_PRECISION = 1e12;
	}

	function slipVote(
		address candidate,
		address voter,
		uint256 amount,
		uint256 slippage
	) external override {
		require(stake.isCandidateRegistered(candidate), 'Election: nonexistent candidate');
		token.transferFrom(msg.sender, address(this), amount);
		stake.voterClaim(candidate);
		voters[candidate][voter].amount = voters[candidate][voter].amount + amount;
		voters[candidate][voter].rewardDebt = voters[candidate][voter].rewardDebt + (amount * accPerShares[candidate] / ACC_PRECISION);
		voteSupply[candidate] = voteSupply[candidate] + amount;
		majorCandidates.slipUpdate(candidate, voteSupply[candidate], slippage);

		emit Vote(candidate, voter, amount);
	}

	function vote(
		address candidate,
		address voter,
		uint256 amount,
		address prev,
		address next
	) external override {
		require(stake.isCandidateRegistered(candidate), 'Election: nonexistent candidate');
		token.transferFrom(msg.sender, address(this), amount);
		stake.voterClaim(candidate);
		voters[candidate][voter].amount = voters[candidate][voter].amount + amount;
		voters[candidate][voter].rewardDebt = voters[candidate][voter].rewardDebt + (amount * accPerShares[candidate] / ACC_PRECISION);
		voteSupply[candidate] = voteSupply[candidate] + amount;
		majorCandidates.upset(candidate, voteSupply[candidate], prev, next);

		emit Vote(candidate, voter, amount);
	}

	function claim(address candidate, address to) external {
		stake.voterClaim(candidate);
		VoterInfo storage voter = voters[candidate][msg.sender];
		uint256 accumulated = voter.amount * accPerShares[candidate] / ACC_PRECISION;
		uint256 pending = accumulated - voter.rewardDebt;
		voter.rewardDebt = accumulated;
		token.transfer(to, pending);
		emit Claimed(candidate, msg.sender, to, pending);
	}

	function withdrawAndClaim(
		address candidate,
		uint256 amount,
		address to,
		address prev,
		address next
	) public override {
		stake.voterClaim(candidate);
		VoterInfo storage voter = voters[candidate][msg.sender];
		uint256 accumulated = voter.amount * accPerShares[candidate] / ACC_PRECISION;
		uint256 pending = accumulated - voter.rewardDebt;
		voter.rewardDebt = accumulated - (amount * accPerShares[candidate] / ACC_PRECISION);
		voter.amount = voter.amount - amount;
		voteSupply[candidate] = voteSupply[candidate] - amount;
		majorCandidates.upset(candidate, voteSupply[candidate], prev, next);
		token.transfer(to,  pending + amount);
		emit Claimed(candidate, msg.sender, to, pending);
		emit Withdrawn(candidate, msg.sender, to, amount);
	}

	function slipWithdrawAndClaim(
		address candidate,
		uint256 amount,
		address to,
		uint256 slippage
	) public override {
		stake.voterClaim(candidate);
		VoterInfo storage voter = voters[candidate][msg.sender];
		uint256 accumulated = voter.amount * accPerShares[candidate] / ACC_PRECISION;
		uint256 pending = accumulated - voter.rewardDebt;
		voter.rewardDebt = accumulated - (amount * accPerShares[candidate] / ACC_PRECISION);
		voter.amount = voter.amount - amount;
		voteSupply[candidate] = voteSupply[candidate] - amount;
		majorCandidates.slipUpdate(candidate, voteSupply[candidate], slippage);
		token.transfer(to,  pending + amount);
		emit Claimed(candidate, msg.sender, to, pending);
		emit Withdrawn(candidate, msg.sender, to, amount);
	}

	function pendingReward(address candidate, address voter) public view returns (uint256 pending) {
		if (voteSupply[candidate] > 0) {
			uint256 pendingAllocation = stake.pendingAllocationReward(candidate);
			uint256 rewardDebt = voters[candidate][voter].rewardDebt;
			uint256 pendingShares = accPerShares[candidate] + (pendingAllocation * ACC_PRECISION / voteSupply[candidate]);
			pending = voters[candidate][voter].amount * pendingShares / ACC_PRECISION - rewardDebt;
		}
	}

	function allocateRewardFor(address candidate, uint256 amount) external override onlyStake {
		if (voteSupply[candidate] > 0) {
			accPerShares[candidate] = accPerShares[candidate] + (amount * ACC_PRECISION / voteSupply[candidate]);
			emit ShareUpdated(candidate);
		}
	}

	function _setStake(IStake _stake) internal {
		stake = _stake;
		emit StakeUpdated(_stake);
	}

	function _setMajorCandidates(IMajorCandidates _majorCandidates) internal {
		majorCandidates = _majorCandidates;
		emit MajorCandidatesUpdated(_majorCandidates);
	}

	function _setToken(IERC20 _token) internal {
		token = _token;
		emit TokenUpdated(_token);
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IStake.sol';
import './IMajorCandidates.sol';
import './IERC20.sol';

interface IElection {

	event TokenUpdated(IERC20 token);

	event StakeUpdated(IStake stake);

	event MajorCandidatesUpdated(IMajorCandidates majorCandidates);

	event ShareUpdated(address candidate);

	event Vote(address candidate, address voter, uint256 amount);

	event Claimed(address candidate, address voter, address to, uint256 amount);

	event Withdrawn(address candidate, address voter, address to, uint256 amount);

	function token() external view returns(IERC20);

	function stake() external view returns(IStake);

	function majorCandidates() external view returns(IMajorCandidates);

	function voteSupply(address candidate) external view returns(uint256);

	function ACC_PRECISION() external view returns(uint256);

	function allocateRewardFor(address candidate, uint256 amount) external;

	function slipVote(
		address candidate,
		address voter,
		uint256 amount,
		uint256 slippage
	) external;

	function vote(address candidate, address voter, uint256 amount, address prev, address next) external;

	function withdrawAndClaim(
		address candidate,
		uint256 amount,
		address to,
		address prev,
		address next
	) external;

	function slipWithdrawAndClaim(
		address candidate,
		uint256 amount,
		address to,
		uint256 slippage
	) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './ICandidateSlash.sol';

interface IStake is ICandidateSlash {
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
import './IStake.sol';

interface IMajorCandidates {

	event MaxNodesLengthUpdated(uint256 _len);

	event ElectionUpdated(IElection election);

	event StakeUpdated(IStake stake);

	event AddCandidate(address candidate, uint256 amount, address prev, address next);

	event UpdateCandidate(address candidate, uint256 amount, address prev, address next);

	event RemoveCandidate(address candidate);

	function MAX_MAJOR_CANDIDATES() external view returns(uint256);

	function election() external view returns(IElection);

	function stake() external view returns(IStake);

	function exists(address candidate) external view returns (bool);

	function existsInMajor(address candidate) external view returns(bool existed);

	function majorCandidateList() external view returns(address[] memory majors);

	function remove(address candidate) external;

	function upset(address candidate, uint256 amount, address prev, address next) external;

	function slipUpdate(address candidate, uint256 amount, uint256 slippage) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IERC20 is IERC20Upgradeable {
	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './ISlasher.sol';
import './ICandidateStake.sol';

interface ICandidateSlash is ICandidateStake {

	event SlasherUpdated(ISlasher slasher);

	event DraftSlash(address _candidate, uint256 pendingSlash);

	event RejectSlash(address _candidate, uint256 pendingSlash);

	event ExcuteSlash(address _candidate, uint256 pendingSlash, address[] beneficiaries, uint256[] amounts, uint256 burned);

	function slasher() external returns(ISlasher);

	function draftSlash(address _candidate, uint256 amount) external returns(uint256 pendingSlash);

	function rejectSlash(address _candidate, uint256 pendingSlash) external;

	function executeSlash(
		address _candidate, 
		uint256 slash,
		address[] memory beneficiaries, 
		uint256[] memory amounts,
		uint256 burned
	) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';
import './IMajorCandidates.sol';
import './IStake.sol';

interface ISlasher {

	event GovernanceUpdated(address governance);

	event StakeUpdated(IStake stake);

	event MajorCandidatesUpdated(IMajorCandidates _majorCandidates);

	event DefaultSlashAmountUpdated(uint256 amount);

	event PublicNoticePeriodUpdated(uint256 period);

	event MaxCoefUpdated(uint256 maxCoef);

	event DrafterCoefUpdated(uint64 drafterCoef);

	event ValidatorCoefUpdated(uint256 validatorCoef);

	event ExecutorCoefUpdated(uint256 executorCoef);

	event DraftSlash(uint256 nonce, address candidate, uint64 slashBlock, string manifest, uint64 accuracy);

	event RejectSlash(uint256 nonce);

	event ExecuteSlash(uint256 nonce, address executor);

	function stake() external view returns(IStake);

	function majorCandidates() external view returns(IMajorCandidates);

	function defaultSlashAmount() external view returns(uint256);

	function publicNoticePeriod() external view returns(uint256);

	function nonce() external view returns(uint256);

	function MAXCOEF() external view returns(uint64);

	function drafterCoef() external view returns(uint64);

	function validatorCoef() external view returns(uint64);

	function executorCoef() external view returns(uint64);

	function getSlashAt(uint256 _nonce) external view returns(Types.SlashInfo memory);

	function nonceOf(address candidate) external view returns(uint256);

	function setDrafterCoef(uint64 _drafterCoef) external;

	function setValidatorCoef(uint64 _validatorCoef) external;

	function setExecutorCoef(uint64 _executorCoef) external;

	function draft(uint64 slashBlock, string memory manifest, uint64 accuracy, bytes[] memory signatures) external;

	function reject(address candidate) external;

	function execute(address candidate) external;

	function slashExists(address candidate) external view returns(bool);

	function checkNSignatures(bytes32 hash, bytes[] memory signatures) external view returns(address[] memory signers);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';
import './ICandidateElection.sol';

interface ICandidateStake is ICandidateElection {

	event MinStakeUpdated(uint256 amount);

	event StakeFrozenPeriodUpdated(uint256 period);

	event Quit(Types.Grade grade, address candidate);

	event Stake(address from, address candidate, uint256 amount);

	event Withdrawn(address candidate, address to, uint256 amount);

	function stake(uint256 amount) external;

	function registerAndStake(uint256 amount, string memory url) external;
	
	function quit(address to) external;

	function claim(address candidate) external returns(Types.PoolInfo memory pool);

	function withdrawAndClaim(uint256 amount, address to) external;

	function candidatePendingReward(address candidate) external view returns (uint256 pending);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

library Types {

	enum Grade {
		Null,
		Major,
		Secondary
	}

	struct CandidateInfo {
		Grade grade;
		uint256 amount;
		uint256 rewardDebt;
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';
import './IMajorCandidates.sol';
import './ICandidateElectionReward.sol';

interface ICandidateElection is ICandidateElectionReward {

	event IMajorCandidatesUpdated(IMajorCandidates majorCandidates);

	event Upgrade(address candidate, Types.Grade fromGrade, Types.Grade toGrade);

	event Downgrade(address candidate, Types.Grade fromGrade, Types.Grade toGrade);

	function majorCandidates() external view returns(IMajorCandidates);

	function upgrade(address candidate) external;

	function downgrade(address candidate) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';
import './IElection.sol';
import './ICandidateRegistry.sol';
import './IPools.sol';

interface ICandidateElectionReward is ICandidateRegistry, IPools {

	event ElectionUpdated(IElection election);

	event Claimed(address candidate, address to, uint256 pending);

	event Allocate(address candidate, uint256 amount);

	event VoteRewardCoefUpdated(uint256 coef);

	function election() external view returns(IElection);

	function setVoteRewardCoef(uint256 coef) external;

	function voterClaim(address candidate) external;

	function voteRewardCoef(address candidate) external view returns (uint256 pending);

	function pendingAllocationReward(address candidate) external view returns (uint256 pending);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';
import './IERC20.sol';
import './IRewarder.sol';

interface IPools {

	event TokenUpdated(IERC20 token);

	event RewarderUpdated(IRewarder rewarder);

	event RewardPerSecondUpdated(uint256 rewardPerSecond);

	event PrecisionUpdated(uint256 precision);

	event MaxCoefUpdated(uint256 maxCoef);

	event AddPool(Types.Grade grade);

	event PoolUpdated(Types.Grade grade);

	function token() external view returns(IERC20);

	function rewarder() external view returns(IRewarder);

	function ACC_PRECISION() external view returns(uint256);

	function MAXCOEF() external view returns(uint256);

	function updatePool(Types.Grade grade) external returns (Types.PoolInfo memory pool);

	function poolInfo(Types.Grade grade) external returns(Types.PoolInfo memory);

	function totalAllocPoint() external view returns(uint256);

	function rewardPerSecond() external view returns(uint256);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';

interface ICandidateRegistry {

	event Register(address candidate);

	function register(string memory manifest) external;

	function candidateInfo(address candidate) external view returns(Types.CandidateInfo memory);

	function manifestMap(string memory manifest) external view returns(address);

	function isCandidateRegistered(address candidate) external view returns (bool);

	function gradeOf(address candidate) external view returns (Types.Grade);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IRewarder {

	event TokenUpdated(IERC20Upgradeable token);

	event StakeUpdated(address stake);

	event SendReward(address to, uint256 amount);

	function token() external view returns(IERC20Upgradeable);

	function sendReward(address to, uint256 amount) external;

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