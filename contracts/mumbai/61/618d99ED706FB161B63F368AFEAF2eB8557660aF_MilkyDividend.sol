/**
 *Submitted for verification at polygonscan.com on 2022-10-01
*/

// File: base\IERC1155.sol
interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    function totalSupply(uint256 id) external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function allowance(address owner, address spender, uint256 id) external view returns (uint256);
    function approve(address spender, uint256 amount, uint256 id) external returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
    function burn(address account, uint256 id, uint256 amount) external returns(bool success);
    function mint(address account, uint256 id, uint256 amount) external returns(bool success);
}
// File: base\IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(uint256 amount, address walletAddress) external returns(bool success);
    function burn(uint256 amount) external;
    function name() external view returns (string memory);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferFee(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: base\SafeMath.sol
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: base\AddressUpgradable.sol
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
// File: base\Initializable.sol
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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }
    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}
// File: base\ContextUpgradeable.sol
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }
    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
// File: base\OwnableUpgradeable.sol
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }
    function __Ownable_init_unchained() internal onlyInitializing {
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
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
// File: base\PausableUpgradeable.sol
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }
    function __Pausable_init_unchained() internal onlyInitializing {
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
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
// File: base\CountersUpgradeable.sol
library CountersUpgradeable {
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
// File: base\ReentrancyGuardUpgradeable.sol
abstract contract ReentrancyGuardUpgradeable is Initializable {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }
    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}
// File: ..\node_modules\@opengsn\contracts\src\interfaces\IRelayRecipient.sol
pragma solidity >=0.6.0;
/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);
    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);
    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);
    function versionRecipient() external virtual view returns (string memory);
}
// File: @opengsn\contracts\src\BaseRelayRecipient.sol
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;
/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;
    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }
    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }
    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }
    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}
// File: StakingUpgradable.sol
struct StakingSettings {
    // in tokens, max amount of tokens staker can receive in one cycle
    uint256 maxRewardPerStaker;
    // In DAYS, how often the reward is generated
    uint256 rewardCycle;
    // address of the smart contract which is staked
    address stakingToken;
    // in tokens, how many tokens minimum user can stake
    uint256 minimumStakingAmount;
    // address of the smart contract which is minted/burned
    address tmos;
    // id of tmos tokens for this specific staking
    uint256 tokendaId;
}
struct Stake {
    address staker;
    uint256 amount;
    uint256 since;
    address token;
    bool active;
}
contract StakeCalculator {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;
    uint256 private _dedicatedReward;
    uint256 private _stakeholderCount;
    uint256 private _maxReward;
    uint256 private _totalStaked;
    uint256 private _calculationBonus;
    constructor(
        uint256 reward,
        uint256 maxReward,
        uint256 calculationBonus
    ) {
        _dedicatedReward = reward;
        _maxReward = maxReward;
        _calculationBonus = calculationBonus;
    }
    function add(
        address wallet,
        uint256 amount,
        uint256 stakingDays
    ) public {
        if (balances[wallet] == 0 && amount > 0) {
            _stakeholderCount++;
        }
        uint256 dailyBonus = amount.mul(_calculationBonus).div(10**4);
        uint256 amountWithBonus = amount.add(dailyBonus.mul(stakingDays));
        balances[wallet] = balances[wallet].add(amountWithBonus);
        _totalStaked = _totalStaked.add(amountWithBonus);
    }
    function count() public view returns (uint256) {
        return _stakeholderCount;
    }
    function total() public view returns (uint256) {
        return _totalStaked;
    }
    function balanceOf(address wallet) public view returns (uint256) {
        return balances[wallet];
    }
    function estimateReward(address wallet, uint256 totalPool)
        public
        view
        returns (uint256)
    {
        uint256 reward = totalPool.mul(balanceOf(wallet).div(total()));
        reward = reward.add(reward);
        if (reward > _maxReward) {
            return _maxReward;
        }
        return reward;
    }
}
contract StakingUpgradable is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    BaseRelayRecipient
{
    using SafeMath for uint256;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    StakingSettings private _settings;
    //user balance in TMOS
    mapping(address => uint256) private _balances;
    // USER => LIST OF STAKES
    mapping(address => Stake[]) private _userStakes;
    // ALL STAKES
    Stake[] private _tokenStakes;
    // total amount of frozen staking tokens
    uint256 private _totalStaked;
    // total amount of payed rewards
    uint256 private _payedRewards;
    // timestamp of last payment
    uint256 private _lastPayment;
    //Reward Token (USDT, USDC) => USER => AMOUNT
    mapping(address => mapping(address => uint256)) private _claimable;
    uint256 _calculationBonus;
    event Staked(address indexed staker, uint256 amount, uint256 timestamp);
    event Distributed(uint256 amount, uint256 stakeholderCount);
    function initialize(StakingSettings memory settings_) public initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _settings = settings_;
        _calculationBonus = 1 * 10**2;
        _setTrustedForwarder(0xdA78a11FD57aF7be2eDD804840eA7f4c2A38801d);
    }
    function stake(uint256 _amount) external nonReentrant {
        IERC20 token = IERC20(_settings.stakingToken);
        require(
            token.allowance(_msgSender(), address(this)) >= _amount,
            "Staking: Cannot stake more than you own"
        );
        require(
            _amount >= _settings.minimumStakingAmount,
            "Staking: Cannot stake less than the minimum amount"
        );
        token.transferFrom(_msgSender(), address(this), _amount);
        _mintTMOS(_msgSender(), _amount);
        Stake memory userStake = Stake(
            _msgSender(),
            _amount,
            block.timestamp,
            _settings.stakingToken,
            true
        );
        _userStakes[_msgSender()].push(userStake);
        _tokenStakes.push(userStake);
        _totalStaked = _totalStaked.add(_amount);
        _balances[_msgSender()] = _balances[_msgSender()].add(_amount);
        emit Staked(_msgSender(), _amount, block.timestamp);
    }
    function distribute(address rewardTokenAddress, uint256 amount)
        public
        nonReentrant
        returns (uint256)
    {
        require(
            rewardTokenAddress != address(0),
            "Invalid reward token address"
        );
        require(amount >= 0, "Reward cannot be 0");
        require(
            _getDaysSinceLastPayment() >= _settings.rewardCycle,
            "Staking: Reward cycle not finished yet"
        );
        IERC20 rewardToken = IERC20(rewardTokenAddress);
        require(
            rewardToken.allowance(_msgSender(), address(this)) >= amount,
            "Staking: Insufficient funds"
        );
        StakeCalculator calculator = new StakeCalculator(
            amount,
            _settings.maxRewardPerStaker,
            _calculationBonus
        );
        for (uint256 s = 0; s < _tokenStakes.length; s += 1) {
            if (
                _tokenStakes[s].staker != address(0) &&
                _tokenStakes[s].active != false
            ) {
                uint256 stakedDays = _getStakedDays(_tokenStakes[s].since);
                if (stakedDays >= _settings.rewardCycle - 1) {
                    calculator.add(
                        _tokenStakes[s].staker,
                        _tokenStakes[s].amount,
                        stakedDays
                    );
                }
            }
        }
        for (uint256 s = 0; s < _tokenStakes.length; s += 1) {
            if (
                _tokenStakes[s].staker != address(0) &&
                _tokenStakes[s].active != false
            ) {
                uint256 reward = calculator.estimateReward(
                    _tokenStakes[s].staker,
                    amount
                );
                if (reward > 0) {
                    _claimable[rewardTokenAddress][
                        _tokenStakes[s].staker
                    ] = _claimable[rewardTokenAddress][_tokenStakes[s].staker]
                        .add(reward);
                }
            }
        }
        if (calculator.count() > 0) {
            rewardToken.transferFrom(_msgSender(), address(this), amount);
        }
        _payedRewards = _payedRewards.add(amount);
        _lastPayment = block.timestamp;
        emit Distributed(amount, calculator.count());
        return amount;
    }
    function _mintTMOS(address wallet, uint256 _amount) internal {
        IERC1155 tmos = IERC1155(_settings.tmos);
        tmos.mint(wallet, _settings.tokendaId, _amount);
    }
    function _burnTMOS(address wallet, uint256 _amount) internal {
        IERC1155 tmos = IERC1155(_settings.tmos);
        tmos.burn(wallet, _settings.tokendaId, _amount);
    }
    function setMaxReward(uint256 reward) public onlyOwner {
        _settings.maxRewardPerStaker = reward;
    }
    function setRewardCycle(uint256 cycle) public onlyOwner {
        _settings.rewardCycle = cycle;
    }
    function setMinimumStakingAmount(uint256 amount) public onlyOwner {
        _settings.minimumStakingAmount = amount;
    }
    function minimumStakingAmount() public view returns (uint256) {
        return _settings.minimumStakingAmount;
    }
    function rewardCycle() public view returns (uint256) {
        return _settings.rewardCycle;
    }
    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }
    function totalReward() public view returns (uint256) {
        return _payedRewards;
    }
    function balanceOf(address _staker) public view returns (uint256) {
        return _balances[_staker];
    }
    function _getDaysSinceLastPayment() internal view returns (uint256) {
        return (block.timestamp - _lastPayment) / 60 / 60 / 24;
    }
    function _getStakedDays(uint256 stakedAt) internal view returns (uint256) {
        return (block.timestamp - stakedAt) / 60 / 60 / 24;
    }
    // get claimable balance of the token (USDT/USDC) for the given user (wallet)
    function claimableBalanceOf(address token, address wallet)
        public
        view
        returns (uint256)
    {
        return _claimable[token][wallet];
    }
    function claim(address tokenAddress) public nonReentrant returns (uint256) {
        require(tokenAddress != address(0), "Invalid token");
        uint256 withdrawAmount = claimableBalanceOf(tokenAddress, _msgSender());
        require(withdrawAmount > 0, "Nothing to withdraw");
        IERC20 token = IERC20(tokenAddress);
        require(
            token.balanceOf(address(this)) >= withdrawAmount,
            "Insufficient funds on smart contract. Please try again later"
        );
        token.transfer(_msgSender(), withdrawAmount);
        delete _claimable[tokenAddress][_msgSender()];
        return withdrawAmount;
    }
    function withdraw() public nonReentrant {
        IERC20 _stakingToken = IERC20(_settings.stakingToken);
        IERC1155 tmos = IERC1155(_settings.tmos);
        uint256 totalStake = 0;
        for (uint256 s = 0; s < _userStakes[_msgSender()].length; s += 1) {
            totalStake = totalStake.add(_userStakes[_msgSender()][s].amount);
        }
        require(totalStake > 0, "Nothing to withdraw");
        require(
            tmos.allowance(_msgSender(), address(this), _settings.tokendaId) >=
                totalStake,
            "You have to approve TMOS first"
        );
        require(
            _stakingToken.balanceOf(address(this)) >= totalStake,
            "Insufficient funds on smart contract. Please try again later"
        );
        delete _userStakes[_msgSender()];
        _totalStaked = _totalStaked.sub(totalStake);
        for (uint256 s = 0; s < _tokenStakes.length; s += 1) {
            if (_tokenStakes[s].staker == _msgSender()) {
                delete _tokenStakes[s];
            }
        }
        _balances[_msgSender()] = _balances[_msgSender()].sub(totalStake);
        _burnTMOS(_msgSender(), totalStake);
        _stakingToken.transfer(_msgSender(), totalStake);
    }
    function stakes(address wallet) public view returns (Stake[] memory) {
        return _userStakes[wallet];
    }
    function stakingToken() public view returns (address) {
        return _settings.stakingToken;
    }
    function calculationBonus() public view returns (uint256) {
        return _calculationBonus;
    }
    function setCalculationBonus(uint256 bonus) public onlyOwner {
        require(bonus > 0, "Too little bonus");
        _calculationBonus = bonus;
    }
    function _msgSender()
        internal
        view
        override(BaseRelayRecipient, ContextUpgradeable)
        returns (address ret)
    {
        return BaseRelayRecipient._msgSender();
    }
    function _msgData()
        internal
        view
        override(BaseRelayRecipient, ContextUpgradeable)
        returns (bytes calldata ret)
    {
        return BaseRelayRecipient._msgData();
    }
    function versionRecipient() external pure override returns (string memory) {
        return "2.2.6";
    }
    function setTrustedForwarder(address _forwarder) public onlyOwner {
        _setTrustedForwarder(_forwarder);
    }
}
// File: MilkyDividend.sol
// SPDX-License-Identifier: MIT
contract MilkyDividend is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, BaseRelayRecipient  {
    using SafeMath for uint256;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    //user balance in MIC
    mapping(address => uint256) private _balances;
    //user balance in USDC -> USER
    mapping(address => mapping(address => uint256)) private _claimableBalances;
    // total amount of frozen staking tokens
    uint256 private _totalStaked;
    // total amount of payed rewards
    uint256 private _payedRewards;
    address private _rewardTokenAddress;
    // address of the smart contract which is staked
    address private _stakingTokenAddress;
    // in tokens, how many tokens minimum user can stake
    uint256 private _minimumStakingAmount;
    // USER => LIST OF STAKES
    mapping(address => Stake[]) public _userStakes;
    // ALL STAKES
    Stake[] public _allStakes;
    uint256 public lastRewardDate;
    struct Distribution {
        address tokenAddress;
        uint256 amount;
        uint256 timestamp;
        uint256 totalStaked;
    }
    uint256 public lastDistributionId;
    mapping(uint256 => Distribution) public distributions;
    mapping(address => mapping(address => uint256)) public userRewardDistributionLastClaimedId;
    event Staked(address indexed staker, uint256 amount, uint256 timestamp);
    event Distributed(uint256 amount, uint256 stakeholderCount);
    function initialize(address trustedForwarder, address rewardTokenAddress, address stakingTokenAddress) public initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _setTrustedForwarder(trustedForwarder);
        _rewardTokenAddress = rewardTokenAddress;
        _stakingTokenAddress = stakingTokenAddress;
        _minimumStakingAmount = 1;
        lastRewardDate = block.timestamp - 7 days;
    }
    function distribute(address rewardTokenAddress, uint256 amount) public nonReentrant
    {
        require(rewardTokenAddress != address(0), "Invalid reward token address");
        require(amount >= 0, "Reward cannot be 0");
        IERC20 token = IERC20(rewardTokenAddress);
        require(token.allowance(_msgSender(), address(this)) >= amount, "Staking: Insufficient funds");
        uint256 rewardDayDiff = (block.timestamp - lastRewardDate) / 60;
        require(rewardDayDiff >= 1, "MICDIV: You cannot distribute reward at the same day");
        token.transferFrom(_msgSender(), address(this), amount);
        _payedRewards = _payedRewards.add(amount);
        lastDistributionId++;
        distributions[lastDistributionId] = Distribution(rewardTokenAddress, amount, block.timestamp, _totalStaked);
        //_recalculateClaimable(rewardTokenAddress, amount, rewardDayDiff);
        lastRewardDate = block.timestamp;
        emit Distributed(amount, amount);
    }
    function stake(uint256 _amount) external whenNotPaused nonReentrant {
      IERC20 token = IERC20(_stakingTokenAddress);
      require(token.allowance(_msgSender(), address(this)) >= _amount, "Staking: Cannot stake more than you own");
      require(_amount >= _minimumStakingAmount, "Staking: Cannot stake less than the minimum amount");
      token.transferFrom(_msgSender(), address(this), _amount);
      _totalStaked = _totalStaked.add(_amount);
      Stake memory userStake = Stake(_msgSender(), _amount, block.timestamp, _stakingTokenAddress, true);
      _userStakes[_msgSender()].push(userStake);
      _allStakes.push(userStake);
      _balances[_msgSender()] = _balances[_msgSender()].add(_amount);
      emit Staked(_msgSender(), _amount, block.timestamp);
    }
    function totalStaked() public view returns (uint256){
        return _totalStaked;
    }
    function totalReward() public view returns (uint256){
        return _payedRewards;
    }
    function balanceOf(address _staker) public view returns(uint256){
        return _balances[_staker];
    }
    function minimumStakingAmount() public view returns (uint256) {
        return _minimumStakingAmount;
    }
    function stakingToken() public view returns (address){ 
        return _stakingTokenAddress;
    }
    function rewardToken() public view returns (address){ 
        return _rewardTokenAddress;
    }
    function setRewardToken(address rewardTokenAddress_) public onlyOwner {
        require(rewardTokenAddress_ != address(0), "Invalid reward token address");
        _rewardTokenAddress = rewardTokenAddress_;
    }
    // get claimable balance of the token (USDT/USDC) for the given user (wallet)
    function claimableBalanceOf(address token, address wallet) public view returns(uint256) {
        uint256 totalClaimable;
        uint256 lastClaimedId = userRewardDistributionLastClaimedId[_msgSender()][token];
        for(uint i = lastClaimedId + 1; i <= lastDistributionId; i++) {
            Distribution memory distribution = distributions[i];
            if(distribution.tokenAddress != token) continue;
            uint256 rewardDayDiff = 7;
            if(i > 1) {
                rewardDayDiff = (distribution.timestamp - distributions[i - 1].timestamp) / 60;
            }
            for(uint j = 0; j < _userStakes[wallet].length; j++) {
                Stake memory userStake = _userStakes[wallet][j];
                if(userStake.since > distribution.timestamp) continue;
                uint256 daysDiff = (distribution.timestamp - userStake.since) / 60;
                if(daysDiff > rewardDayDiff) {
                    daysDiff = rewardDayDiff;
                }
                uint256 reward = daysDiff.mul(distribution.amount).div(rewardDayDiff).mul(userStake.amount).div(distribution.totalStaked);
                totalClaimable = totalClaimable.add(reward);
            }
        }
        return totalClaimable;
    }
    function updateUserLastClaimedIdForReward(address tokenAddress) private {
        uint256 lastClaimedId = userRewardDistributionLastClaimedId[_msgSender()][tokenAddress];
        for(uint i = lastDistributionId; i > lastClaimedId; i--) {
            Distribution memory distribution = distributions[i];
            if(distribution.tokenAddress == tokenAddress) {
                userRewardDistributionLastClaimedId[_msgSender()][tokenAddress] = i;
                return;
            }
        }
    }
    function claim(address tokenAddress) whenNotPaused public nonReentrant returns(uint256) {
        uint256 withdrawAmount = claimableBalanceOf(tokenAddress, _msgSender());
        require(withdrawAmount > 0, "Nothing to withdraw");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= withdrawAmount, "Insufficient funds on smart contract. Please try again later");
        updateUserLastClaimedIdForReward(tokenAddress);
        token.transfer(_msgSender(), withdrawAmount);
        _claimableBalances[tokenAddress][_msgSender()] = _claimableBalances[tokenAddress][_msgSender()].sub(withdrawAmount);
        return withdrawAmount;
    }
    function withdraw() whenNotPaused public nonReentrant {
        IERC20 stakingToken_ = IERC20(_stakingTokenAddress);
        uint256 balance = _balances[_msgSender()];
        require(balance > 0, "Nothing to withdraw");
        require(stakingToken_.balanceOf(address(this)) >= balance, "Insufficient funds on smart contract. Please try again later");
        for (uint256 i = 0; i < _userStakes[_msgSender()].length; i++){
            _totalStaked = _totalStaked.sub(_userStakes[_msgSender()][i].amount);
        }
        delete _userStakes[_msgSender()];
        stakingToken_.transfer(_msgSender(), balance);
        _balances[_msgSender()] = _balances[_msgSender()].sub(balance);
    }
    function pause() public whenNotPaused onlyOwner {
        _pause();
    }
    function unpause() public whenPaused onlyOwner {
        _unpause();
    }
    function finalize() public onlyOwner {
        IERC20 token = IERC20(_rewardTokenAddress);
        uint256 withdrawAmount = token.balanceOf(address(this));
        require(withdrawAmount > 0, "Nothing to withdraw");
        token.transfer(_msgSender(), withdrawAmount);
    }
    function _msgSender() internal override(BaseRelayRecipient, ContextUpgradeable) view returns (address ret) {
        return BaseRelayRecipient._msgSender();
    }
    function _msgData() internal override(BaseRelayRecipient, ContextUpgradeable) view returns (bytes calldata ret) {
        return BaseRelayRecipient._msgData();
    }
    function versionRecipient() external override pure returns (string memory) {
        return "2.2.6";
    }
    function setTrustedForwarder(address _forwarder) public onlyOwner {
        _setTrustedForwarder(_forwarder);
    }
}