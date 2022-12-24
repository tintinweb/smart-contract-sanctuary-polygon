// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './interfaces/HMTokenInterface.sol';
import './interfaces/IRewardPool.sol';
import './interfaces/IEscrow.sol';
import './utils/SafeMath.sol';

contract Escrow is IEscrow {
    using SafeMath for uint256;
    event IntermediateStorage(string _url, string _hash);
    event Pending(string manifest, string hash);
    event BulkTransfer(uint256 indexed _txId, uint256 _bulkCount);

    EscrowStatuses public override status;

    address public reputationOracle;
    address public recordingOracle;
    address public launcher;
    address payable public canceler;

    uint256 public reputationOracleStake;
    uint256 public recordingOracleStake;
    uint256 private constant BULK_MAX_VALUE = 1000000000 * (10 ** 18);
    uint32 private constant BULK_MAX_COUNT = 100;

    address public eip20;

    string public manifestUrl;
    string public manifestHash;

    string public finalResultsUrl;
    string public finalResultsHash;

    uint256 public duration;

    uint256[] public finalAmounts;
    bool public bulkPaid;

    mapping(address => bool) public areTrustedHandlers;

    constructor(
        address _eip20,
        address payable _canceler,
        uint256 _duration,
        address[] memory _handlers
    ) {
        eip20 = _eip20;
        status = EscrowStatuses.Launched;
        duration = _duration.add(block.timestamp); // solhint-disable-line not-rely-on-time
        launcher = msg.sender;
        canceler = _canceler;
        areTrustedHandlers[_canceler] = true;
        areTrustedHandlers[msg.sender] = true;
        addTrustedHandlers(_handlers);
    }

    function getBalance() public view returns (uint256) {
        return HMTokenInterface(eip20).balanceOf(address(this));
    }

    function addTrustedHandlers(address[] memory _handlers) public {
        require(
            areTrustedHandlers[msg.sender],
            'Address calling cannot add trusted handlers'
        );
        for (uint256 i = 0; i < _handlers.length; i++) {
            areTrustedHandlers[_handlers[i]] = true;
        }
    }

    // The escrower puts the Token in the contract without an agentless
    // and assigsn a reputation oracle to payout the bounty of size of the
    // amount specified
    function setup(
        address _reputationOracle,
        address _recordingOracle,
        uint256 _reputationOracleStake,
        uint256 _recordingOracleStake,
        string memory _url,
        string memory _hash
    ) public trusted notExpired {
        require(
            _reputationOracle != address(0),
            'Invalid or missing token spender'
        );
        require(
            _recordingOracle != address(0),
            'Invalid or missing token spender'
        );
        uint256 totalStake = _reputationOracleStake.add(_recordingOracleStake);
        require(totalStake >= 0 && totalStake <= 100, 'Stake out of bounds');
        require(
            status == EscrowStatuses.Launched,
            'Escrow not in Launched status state'
        );

        reputationOracle = _reputationOracle;
        recordingOracle = _recordingOracle;
        areTrustedHandlers[reputationOracle] = true;
        areTrustedHandlers[recordingOracle] = true;

        reputationOracleStake = _reputationOracleStake;
        recordingOracleStake = _recordingOracleStake;

        manifestUrl = _url;
        manifestHash = _hash;
        status = EscrowStatuses.Pending;
        emit Pending(manifestUrl, manifestHash);
    }

    function abort() public trusted notComplete notPaid {
        if (getBalance() != 0) {
            cancel();
        }
        selfdestruct(canceler);
    }

    function cancel()
        public
        trusted
        notBroke
        notComplete
        notPaid
        returns (bool)
    {
        bool success = HMTokenInterface(eip20).transfer(canceler, getBalance());
        status = EscrowStatuses.Cancelled;
        return success;
    }

    function complete() public notExpired {
        require(
            msg.sender == reputationOracle || areTrustedHandlers[msg.sender],
            'Address calling is not trusted'
        );
        require(status == EscrowStatuses.Paid, 'Escrow not in Paid state');
        status = EscrowStatuses.Complete;
    }

    function storeResults(
        string memory _url,
        string memory _hash
    ) public trusted notExpired {
        require(
            status == EscrowStatuses.Pending ||
                status == EscrowStatuses.Partial,
            'Escrow not in Pending or Partial status state'
        );
        emit IntermediateStorage(_url, _hash);
    }

    function bulkPayOut(
        address[] memory _recipients,
        uint256[] memory _amounts,
        string memory _url,
        string memory _hash,
        uint256 _txId
    ) public trusted notBroke notLaunched notPaid notExpired returns (bool) {
        require(
            _recipients.length == _amounts.length,
            "Amount of recipients and values don't match"
        );
        require(_recipients.length < BULK_MAX_COUNT, 'Too many recipients');

        uint256 balance = getBalance();
        bulkPaid = false;
        uint256 aggregatedBulkAmount = 0;
        for (uint256 i; i < _amounts.length; i++) {
            aggregatedBulkAmount += _amounts[i];
        }
        require(aggregatedBulkAmount < BULK_MAX_VALUE, 'Bulk value too high');

        if (balance < aggregatedBulkAmount) {
            return bulkPaid;
        }

        bool writeOnchain = bytes(_hash).length != 0 || bytes(_url).length != 0;
        if (writeOnchain) {
            // Be sure they are both zero if one of them is
            finalResultsUrl = _url;
            finalResultsHash = _hash;
        }

        (
            uint256 reputationOracleFee,
            uint256 recordingOracleFee
        ) = finalizePayouts(_amounts);
        HMTokenInterface token = HMTokenInterface(eip20);

        for (uint256 i = 0; i < _recipients.length; ++i) {
            token.transfer(_recipients[i], finalAmounts[i]);
        }

        delete finalAmounts;
        bulkPaid =
            token.transfer(reputationOracle, reputationOracleFee) &&
            token.transfer(recordingOracle, recordingOracleFee);

        balance = getBalance();
        if (bulkPaid) {
            if (status == EscrowStatuses.Pending) {
                status = EscrowStatuses.Partial;
            }
            if (balance == 0 && status == EscrowStatuses.Partial) {
                status = EscrowStatuses.Paid;
            }
        }
        emit BulkTransfer(_txId, _recipients.length);
        return bulkPaid;
    }

    function finalizePayouts(
        uint256[] memory _amounts
    ) internal returns (uint256, uint256) {
        uint256 reputationOracleFee = 0;
        uint256 recordingOracleFee = 0;
        for (uint256 j; j < _amounts.length; j++) {
            uint256 singleReputationOracleFee = reputationOracleStake
                .mul(_amounts[j])
                .div(100);
            uint256 singleRecordingOracleFee = recordingOracleStake
                .mul(_amounts[j])
                .div(100);
            uint256 amount = _amounts[j].sub(singleReputationOracleFee).sub(
                singleRecordingOracleFee
            );
            reputationOracleFee = reputationOracleFee.add(
                singleReputationOracleFee
            );
            recordingOracleFee = recordingOracleFee.add(
                singleRecordingOracleFee
            );
            finalAmounts.push(amount);
        }
        return (reputationOracleFee, recordingOracleFee);
    }

    modifier trusted() {
        require(areTrustedHandlers[msg.sender], 'Address calling not trusted');
        _;
    }

    modifier notBroke() {
        require(getBalance() != 0, 'EIP20 contract out of funds');
        _;
    }

    modifier notComplete() {
        require(
            status != EscrowStatuses.Complete,
            'Escrow in Complete status state'
        );
        _;
    }

    modifier notPaid() {
        require(status != EscrowStatuses.Paid, 'Escrow in Paid status state');
        _;
    }

    modifier notLaunched() {
        require(
            status != EscrowStatuses.Launched,
            'Escrow in Launched status state'
        );
        _;
    }

    modifier notExpired() {
        require(duration > block.timestamp, 'Contract expired'); // solhint-disable-line not-rely-on-time
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './Escrow.sol';
import './interfaces/IStaking.sol';
import './utils/Initializable.sol';

contract EscrowFactory is Initializable {
    // all Escrows will have this duration.
    uint256 constant STANDARD_DURATION = 8640000;
    string constant ERROR_ZERO_ADDRESS = 'EscrowFactory: Zero Address';

    uint256 public counter;
    mapping(address => uint256) public escrowCounters;
    address public lastEscrow;
    address public eip20;
    address public staking;
    event Launched(address eip20, address escrow);

    function initialize(address _eip20, address _staking) public initializer {
        require(_eip20 != address(0), ERROR_ZERO_ADDRESS);
        eip20 = _eip20;
        require(_staking != address(0), ERROR_ZERO_ADDRESS);
        staking = _staking;
    }

    function createEscrow(
        address[] memory trustedHandlers
    ) public returns (address) {
        bool hasAvailableStake = IStaking(staking).hasAvailableStake(
            msg.sender
        );
        require(
            hasAvailableStake == true,
            'Needs to stake HMT tokens to create an escrow.'
        );

        Escrow escrow = new Escrow(
            eip20,
            payable(msg.sender),
            STANDARD_DURATION,
            trustedHandlers
        );
        counter++;
        escrowCounters[address(escrow)] = counter;
        lastEscrow = address(escrow);
        emit Launched(eip20, lastEscrow);
        return lastEscrow;
    }

    function isChild(address _child) public view returns (bool) {
        return escrowCounters[_child] == counter;
    }

    function hasEscrow(address _address) public view returns (bool) {
        return escrowCounters[_address] != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface HMTokenInterface {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferBulk(
        address[] calldata _tos,
        uint256[] calldata _values,
        uint256 _txId
    ) external returns (uint256 _bulkCount);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IEscrow {
    enum EscrowStatuses {
        Launched,
        Pending,
        Partial,
        Paid,
        Complete,
        Cancelled
    }

    function status() external view returns (EscrowStatuses);

    function addTrustedHandlers(address[] memory _handlers) external;

    function setup(
        address _reputationOracle,
        address _recordingOracle,
        uint256 _reputationOracleStake,
        uint256 _recordingOracleStake,
        string memory _url,
        string memory _hash
    ) external;

    function abort() external;

    function cancel() external returns (bool);

    function complete() external;

    function storeResults(string memory _url, string memory _hash) external;

    function bulkPayOut(
        address[] memory _recipients,
        uint256[] memory _amounts,
        string memory _url,
        string memory _hash,
        uint256 _txId
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IRewardPool {
    /**
     * @dev Keep track of slashers how much they slashed per allocations
     */
    struct Reward {
        address escrowAddress;
        address slasher;
        uint256 tokens; // Tokens allocated to a escrowAddress
    }

    function addReward(
        address _escrowAddress,
        address slasher,
        uint256 tokens
    ) external;

    function getRewards(
        address _escrowAddress
    ) external view returns (Reward[] memory);

    function distributeReward(address _escrowAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import '../libs/Stakes.sol';

interface IStaking {
    /**
     * @dev Possible states an allocation can be
     * States:
     * - Null = Staker == address(0)
     * - Pending = not Null && tokens > 0 && escrowAddress status == Pending
     * - Active = Pending && escrowAddress status == Launched
     * - Closed = Active && closedAt != 0
     * - Completed = Closed && closedAt && escrowAddress status == Complete
     */
    enum AllocationState {
        Null,
        Pending,
        Active,
        Closed,
        Completed
    }

    /**
     * @dev Possible sort fields
     * Fields:
     * - None = Do not sort
     * - Stake = Sort by stake amount
     */
    enum SortField {
        None,
        Stake
    }

    /**
     * @dev Allocate HMT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address escrowAddress;
        address staker;
        uint256 tokens; // Tokens allocated to a escrowAddress
        uint256 createdAt; // Time when allocation was created
        uint256 closedAt; // Time when allocation was closed
    }

    function rewardPool() external view returns (address);

    function setMinimumStake(uint256 _minimumStake) external;

    function setLockPeriod(uint32 _lockPeriod) external;

    function setRewardPool(address _rewardPool) external;

    function isAllocation(address _escrowAddress) external view returns (bool);

    function hasStake(address _indexer) external view returns (bool);

    function hasAvailableStake(address _indexer) external view returns (bool);

    function getAllocation(
        address _escrowAddress
    ) external view returns (Allocation memory);

    function getAllocationState(
        address _escrowAddress
    ) external view returns (AllocationState);

    function getStakedTokens(address _staker) external view returns (uint256);

    function getStaker(
        address _staker
    ) external view returns (Stakes.Staker memory);

    function stake(uint256 _tokens) external;

    function unstake(uint256 _tokens) external;

    function withdraw() external;

    function slash(
        address _slasher,
        address _staker,
        address _escrowAddress,
        uint256 _tokens
    ) external;

    function allocate(address escrowAddress, uint256 _tokens) external;

    function closeAllocation(address _escrowAddress) external;

    function getListOfStakers()
        external
        view
        returns (address[] memory, Stakes.Staker[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import '../utils/SafeMath.sol';
import '../utils/Math.sol';

/**
 * @title Structures, methods and data are available to manage the staker state.
 */
library Stakes {
    using SafeMath for uint256;
    using Stakes for Stakes.Staker;

    struct Staker {
        uint256 tokensStaked; // Tokens staked by the Staker
        uint256 tokensAllocated; // Tokens allocated for jobs
        uint256 tokensLocked; // Tokens locked for withdrawal
        uint256 tokensLockedUntil; // Tokens locked until time
    }

    /**
     * @dev Deposit tokens to the staker stake.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to deposit
     */
    function deposit(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.add(_tokens);
    }

    /**
     * @dev Withdraw tokens from the staker stake.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to withdraw
     */
    function withdraw(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.sub(_tokens);
    }

    /**
     * @dev Release tokens from the staker stake.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to release
     */
    function release(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.sub(_tokens);
    }

    /**
     * @dev Add tokens from the main stack to tokensAllocated.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to allocate
     */
    function allocate(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.add(_tokens);
    }

    /**
     * @dev Unallocate tokens from a escrowAddress back to the main stack.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unallocate
     */
    function unallocate(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.sub(_tokens);
    }

    /**
     * @dev Lock tokens until a lock period pass.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unstake
     * @param _period Period in blocks that need to pass before withdrawal
     */
    function lockTokens(
        Stakes.Staker storage stake,
        uint256 _tokens,
        uint256 _period
    ) internal {
        uint256 lockingPeriod = _period;

        if (stake.tokensLocked > 0) {
            lockingPeriod = Math.weightedAverage(
                Math.diffOrZero(stake.tokensLockedUntil, block.number), // Remaining lock period
                stake.tokensLocked,
                _period,
                _tokens
            );
        }

        stake.tokensLocked = stake.tokensLocked.add(_tokens);
        stake.tokensLockedUntil = block.number.add(lockingPeriod);
    }

    /**
     * @dev Unlock tokens.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unkock
     */
    function unlockTokens(
        Stakes.Staker storage stake,
        uint256 _tokens
    ) internal {
        stake.tokensLocked = stake.tokensLocked.sub(_tokens);
        if (stake.tokensLocked == 0) {
            stake.tokensLockedUntil = 0;
        }
    }

    /**
     * @dev Return all tokens available for withdrawal.
     * @param stake Staker struct
     * @return Amount of tokens available for withdrawal
     */
    function withdrawTokens(
        Stakes.Staker storage stake
    ) internal returns (uint256) {
        uint256 tokensToWithdraw = stake.tokensWithdrawable();

        if (tokensToWithdraw > 0) {
            stake.unlockTokens(tokensToWithdraw);
            stake.withdraw(tokensToWithdraw);
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Return all tokens available in stake.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensAvailable(
        Stakes.Staker memory stake
    ) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensUsed());
    }

    /**
     * @dev Return all tokens used in allocations and locked for withdrawal.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensUsed(
        Stakes.Staker memory stake
    ) internal pure returns (uint256) {
        return stake.tokensAllocated.add(stake.tokensLocked);
    }

    /**
     * @dev Return the amount of tokens staked which are not locked.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensSecureStake(
        Stakes.Staker memory stake
    ) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensLocked);
    }

    /**
     * @dev Tokens available for withdrawal after lock period.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensWithdrawable(
        Stakes.Staker memory stake
    ) internal view returns (uint256) {
        if (
            stake.tokensLockedUntil == 0 ||
            block.number < stake.tokensLockedUntil
        ) {
            return 0;
        }
        return stake.tokensLocked;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                'Address: low-level call failed'
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                'Address: low-level call with value failed'
            );
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
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                'Address: low-level static call failed'
            );
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), 'Address: call to non-contract');
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import './AddressUpgradeable.sol';

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
            'Initializable: contract is already initialized'
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            'Initializable: contract is already initialized'
        );
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
        require(_initializing, 'Initializable: contract is not initializing');
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, 'Initializable: contract is initializing');
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './SafeMath.sol';

/**
 * @title Math Library
 * @notice A collection of functions to perform math operations
 */
library Math {
    using SafeMath for uint256;

    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Calculates the weighted average of two values pondering each of these
     * values based on configured weights. The contribution of each value N is
     * weightN/(weightA + weightB).
     * @param valueA The amount for value A
     * @param weightA The weight to use for value A
     * @param valueB The amount for value B
     * @param weightB The weight to use for value B
     */
    function weightedAverage(
        uint256 valueA,
        uint256 weightA,
        uint256 valueB,
        uint256 weightB
    ) internal pure returns (uint256) {
        return
            valueA.mul(weightA).add(valueB.mul(weightB)).div(
                weightA.add(weightB)
            );
    }

    /**
     * @dev Returns the difference between two numbers or zero if negative.
     */
    function diffOrZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x.sub(y) : 0;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}