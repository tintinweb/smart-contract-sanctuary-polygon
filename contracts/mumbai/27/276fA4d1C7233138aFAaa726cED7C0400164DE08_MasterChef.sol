// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// pragma solidity 0.8.0;

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
    constructor() internal{
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

// pragma solidity 0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// pragma solidity 0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       
            if (b > a) return (false, 0);
            return (true, a - b);
        
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);

    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        
            if (b == 0) return (false, 0);
            return (true, a / b);
        
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            if (b == 0) return (false, 0);
            return (true, a % b);
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
            return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
            return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
            require(b > 0, errorMessage);
            return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interface/BEP20.sol";

contract CONEshakeSwapToken is BEP20('CONEshakeSwap Token', 'CONE') {

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public  {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CONEshakeSwap::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CONEshakeSwap::delegateBySig: invalid nonce");
        require(now <= expiry, "CONEshakeSwap::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "CONEshakeSwap::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CONEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "CONE::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function getOwner() external override view returns (address) {
        return owner();
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero'));
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function _transfer (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }
}

// SPDX-License-Identifier: GPL-3.0

// pragma solidity 0.8.0;

interface IBEP20 {
   
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "./IBEP20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/SafeBEP20.sol";
import "./Bitcone.sol";
import "./interface/IUniswapV2Router01.sol";

//
// MasterChef is the master of CONE. He can make CONE and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CONE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct AffInfo {
        bool isregistered;
        uint affRewards;
        address affFrom;
        uint256 aff1sum; //8 level
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
        uint256 aff8sum;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CONEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that CONEs distribution occurs.
        uint256 accCONEPerShare; // Accumulated CONEs per share, times 1e12. See below.
    }

    // The CONE TOKEN!
    CONEshakeSwapToken public CONE;
    // Bonus muliplier for early CONE makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // Withdraw Fee
    uint256 private fee;
    // deposit can be made
    bool canDeposit = true; 
    // withdrawal can be made
    bool canWithdraw = true;

    IUniswapV2Router01 uniswaprouter1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // aff info mapping
    mapping(address => AffInfo) public affinfo;

    // mapping(uint256 => uint) public poolSupply;
    mapping(uint256 => uint) public totalSupplied;
    mapping(uint256 => uint) public rewardPerBlock;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CONE mining starts.
    uint256 public startBlock;
    uint256 public farmPid;
    uint256 public poolPid;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        CONEshakeSwapToken _CONE,
        address _feeAddress,
        address payable _uniswaprouter1,
        uint256 _farmPid,
        uint256 _poolPid
    ) public {
        CONE = _CONE;
        feeAddress = _feeAddress;
        uniswaprouter1 = IUniswapV2Router01(_uniswaprouter1);
        affinfo[msg.sender].affFrom = address(0);
        affinfo[msg.sender].isregistered = true;
        farmPid = _farmPid;
        poolPid = _poolPid;
    }

    function changeFarmPid(uint _farmPid) external onlyOwner {
        farmPid = _farmPid;
    }

    function changePoolPid(uint _poolPid) external onlyOwner {
        poolPid = _poolPid;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setRewardperBlock(uint256 _pid, uint amount) public onlyOwner {
        rewardPerBlock[_pid] = amount;
    }

    // function setTotalSupplyfor(uint256 _pid, uint amount) public onlyOwner{
    //     poolSupply[_pid] = amount;
    // }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accCONEPerShare: 0
            })
        );
    }

    // function updates the pool information for a specific pool. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        // If _withUpdate is true, the function calls the massUpdatePools function
        // which updates all pools in the poolInfo mapping
        if (_withUpdate) {
            massUpdatePools();
        }
        // The function updates the total allocation point by subtracting the current allocation point
        // of the pool from the totalAllocPoint and adding the new allocation point.
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        // The function updates the allocation point for the specific pool in the poolInfo mapping
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending CONEs on frontend.
    // This function calculates and returns
    // the pending CONE rewards for a specific user in a specific pool.
    function pendingCONE(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        // The variable accCONEPerShare is initialized with
        // the accumulated CONE per share value from the poolInfo mapping.
        uint256 accCONEPerShare = pool.accCONEPerShare;
        // The variable lpSupply is initialized with the balance of the LP token for the pool.
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // The function then checks if the current block number is
        // greater than the last reward block for the pool and if the LP supply is not zero.
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // If these conditions are met, the function calculates the multiplier value using
            // the getMultiplier function and the last reward block and current block number.
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            // It then calculates the CONE reward for the pool using the multiplier,
            // rewardPerBlock, and allocPoint values, and divides by the totalAllocPoint.
            uint256 CONEReward = multiplier
                .mul(rewardPerBlock[_pid])
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            // The accCONEPerShare variable is updated with the accumulated CONE rewards per share.
            accCONEPerShare = accCONEPerShare.add(
                CONEReward.mul(1e12).div(lpSupply)
            );
        }
        //calculates and returns the pending CONE rewards for the user by multiplying
        // the user's share amount by the accCONEPerShare value and dividing by 1e12.
        // The rewardDebt value is subtracted from the final calculation.
        return user.amount.mul(accCONEPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    // NOTE : This function calls the updatePool function for every pool in the poolInfo mapping.
    // This allows for all pools to be updated in one function call instead of having to call the updatePool function for each pool individually.
    function massUpdatePools() public {
        // The function first gets the length of the poolInfo
        uint256 length = poolInfo.length;
        // The function then iterates through each pool in the mapping using a for loop
        for (uint256 pid = 0; pid < length; ++pid) {
            // For each pool, the function calls the updatePool function passing in the current pool ID
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    // This function updates the rewards for a pool
    // The function takes in a single parameter, _pid, which represents the pool ID.
    function updatePool(uint256 _pid) public {
        // The function first retrieves the pool information from the poolInfo mapping and assigns it to the variable "pool" with the storage keyword.
        PoolInfo storage pool = poolInfo[_pid];
        // The function then checks if the current block number is less than or equal to the last block number
        // that the pool received a reward. If it is, the function exits and does not continue with the rest of the logic.
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        // The function calculates the liquidity pool token's supply that is held by the contract by calling the balanceOf function on the pool's lpToken.
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        // If the supply is 0 or the pool's allocation point is 0,
        // the function sets the lastRewardBlock to the current block number and exits.
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // The function calculates the reward multiplier by calling the getMultiplier function
        // passing in the last block number the pool received a reward and the current block number.
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        // The function calculates the Cone token reward for the pool by multiplying the multiplier,
        // rewardPerBlock, and the pool's allocation point by pool.allocPoint,
        // then dividing by the totalAllocPoint.
        uint256 CONEReward = multiplier
            .mul(rewardPerBlock[_pid])
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        // The function adds the Cone token reward to the pool's existing Cone token reward per share
        // by calling the add function on pool.accCONEPerShare and passing in the result of multiplying the Cone token reward by 1e12
        // and dividing by the liquidity pool token's supply.
        pool.accCONEPerShare = pool.accCONEPerShare.add(
            CONEReward.mul(1e12).div(lpSupply)
        );

        // The function updates the lastRewardBlock to the current block number.
        pool.lastRewardBlock = block.number;
    }

    //// Function to register a user for the affiliate program to Deposit LP tokens to MasterChef for CONE allocation.
    function register(address _affaddress) public {
        // Check if the user is already registered
        require(!affinfo[msg.sender].isregistered, "you are already registerd");
        // Verify that the affiliate address is registered
        require(
            affinfo[_affaddress].isregistered,
            " your affiliate is not registered"
        );
        // Get the user's affiliate information
        AffInfo storage affuser = affinfo[msg.sender];
        // Mark the user as registered
        affuser.isregistered = true;
        // Set the user's affiliate address
        affuser.affFrom = _affaddress;

        // Get the addresses of the user's affiliates
        address _affAddr1 = _affaddress;
        address _affAddr2 = affinfo[_affAddr1].affFrom;
        address _affAddr3 = affinfo[_affAddr2].affFrom;
        address _affAddr4 = affinfo[_affAddr3].affFrom;
        address _affAddr5 = affinfo[_affAddr4].affFrom;
        address _affAddr6 = affinfo[_affAddr5].affFrom;
        address _affAddr7 = affinfo[_affAddr6].affFrom;
        address _affAddr8 = affinfo[_affAddr7].affFrom;

        affinfo[_affAddr1].aff1sum = affinfo[_affAddr1].aff1sum.add(1);
        affinfo[_affAddr2].aff2sum = affinfo[_affAddr2].aff2sum.add(1);
        affinfo[_affAddr3].aff3sum = affinfo[_affAddr3].aff3sum.add(1);
        affinfo[_affAddr4].aff4sum = affinfo[_affAddr4].aff4sum.add(1);
        affinfo[_affAddr5].aff5sum = affinfo[_affAddr5].aff5sum.add(1);
        affinfo[_affAddr6].aff6sum = affinfo[_affAddr6].aff6sum.add(1);
        affinfo[_affAddr7].aff7sum = affinfo[_affAddr7].aff7sum.add(1);
        affinfo[_affAddr8].aff8sum = affinfo[_affAddr8].aff8sum.add(1);
    }

    // Function to open deposit
    function openDeposit() public onlyOwner {
        // Set the canDeposit variable to true
        canDeposit = true;
    }

    // Function to close deposit
    function closeDeposit() public onlyOwner {
        // Set the canDeposit variable to false
        canDeposit = false;
    }

    // Function to close withdraw
    function openWithdraw() public onlyOwner {
        // Set the canWithdraw variable to true
        canWithdraw = true;
    }

    // Function to close withdraw
    function closeWithdraw() public onlyOwner {
        // Set the canWithdraw variable to false
        canWithdraw = false;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        // The function first checks if the deposit functionality is open
        // If not it will revert the transaction and return an error message.
        require(canDeposit == true, "Deposite is closed.");
        // The function checks if the user is registered
        // If not it will revert the transaction and return an error message.
        require(affinfo[msg.sender].isregistered, "you are not registerd");
        // The function retrieves the pool information from the poolInfo mapping and
        // assigns it to the variable "pool" with the storage keyword.
        PoolInfo storage pool = poolInfo[_pid];
        // The function also retrieves the user information from the userInfo mapping and
        // assigns it to the variable "user" with the storage keyword.
        UserInfo storage user = userInfo[_pid][msg.sender];
        // The function calls updatePool function passing in the current pool ID
        updatePool(_pid);
        // If the user has an existing balance in the pool
        if (user.amount > 0) {
            //The function calculates pending rewards
            uint256 pending = user
                .amount
                .mul(pool.accCONEPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            // If there are pending rewards, it transfers the rewards to the user
            if (pending > 0) {
                safeCONETransfer(msg.sender, pending);
            }
        }
        // If the deposit amount is greater than 0
        if (_amount > 0) {
            // The function performs a safe transfer of the deposit amount from
            // the user's address to the contract's address
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
                // the function updates
                // the user's balance in the pool by adding the deposit amount
                user.amount = user.amount.add(_amount);
            // }
        }
        // The function updates the user's reward debt to
        // the user's current balance in the pool multiplied by the pool's accCON
        user.rewardDebt = user.amount.mul(pool.accCONEPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    //Set fee Function
    function setFee(uint256 _fee) public virtual onlyOwner returns (uint256) {
        fee = _fee;
        return fee;
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        // Check if withdrawals are allowed
        require(canWithdraw == true, "Withdraw is closed.");
        // Get the pool and user information
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // Verify that the user has enough funds to withdraw
        require(user.amount >= _amount, "withdraw: not good");
        // require(
        //     poolSupply[_pid] > (_amount + totalSupplied[_pid]),
        //     "Withdraw: INSUFFFICIENT SUPPLY"
        // );
        // Update the pool information
        updatePool(_pid);
        // Calculate the pending rewards
        uint256 pending = user.amount.mul(pool.accCONEPerShare).div(1e12).sub(
            user.rewardDebt
        );
        // Check if there are pending rewards
        if (pending > 0) {
            // Calculate the withdraw fee
            uint withdrawfee = pending.mul(fee).div(100);
            // Calculate the amount to be withdrawn
            uint withdrawAmount = pending - withdrawfee;
            // Transfer the rewards to the user
            safeCONETransfer(msg.sender, withdrawAmount);
            // Transfer the withdraw fee to the fee address
            safeCONETransfer(feeAddress, withdrawfee);
            // Increase the total supply of the pool
            totalSupplied[_pid] += pending;
        }
        // Check if the user is withdrawing LP tokens
        if (_amount > 0) {
            // Decrease the user's LP token balance
            user.amount = user.amount.sub(_amount);
            // Transfer the LP tokens to the user
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        // Update the user's reward debt
        user.rewardDebt = user.amount.mul(pool.accCONEPerShare).div(1e12);
        // Emit the Withdraw event
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // This function retrieves and returns the AffInfo struct for a specific user.
    function AffinfoFunction(
        address _user
    ) external view returns (AffInfo memory) {
        return affinfo[_user];
    }

    // This function allows a user to emergency withdraw their LP tokens from a specific pool.
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // The variable amount is initialized with the user's LP token amount in the pool.
        uint256 amount = user.amount;
        // The function then sets the user's amount and
        // reward debt values in the userInfo mapping to 0.
        user.amount = 0;
        user.rewardDebt = 0;
        // It then uses the safeTransfer function to
        // transfer the user's LP token amount from the pool to the user's address.
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        // Finally, the function emits an EmergencyWithdraw event, with the user's
        // address, the pool ID, and the amount withdrawn as the parameters.
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function changeCONEShakeSwapAddress(
        address payable _uniswaprouter1
    ) external onlyOwner {
        uniswaprouter1 = IUniswapV2Router01(_uniswaprouter1);
    }

    address[] private arr = [
        0xe6aDBa24c130A89A1779c9fcDd75709008A2b791, // WBNB
        0x7c14cE10E0011B6738473C72336088db1Fa7CE69 // CONE
    ];

    // This function retrieves and returns the current exchange rate of CONE token.

    // Note: This function assumes that the uniswaprouter1 contract has been
    // correctly set up and the swap pair for the CONE token has been added to it. Also the
    // arr variable should be an array of token address and it should contain the address of CONE Token.
    function getCONERate() public view returns (uint256) {
        // The function first calls the getAmountsOut() function on the uniswaprouter1 contract,
        // passing in 1e18 as the first parameter, and the arr variable as the second parameter.
        // This function call returns an array of uint256 values, representing
        // the output amounts of the tokens in the swap.
        uint256[] memory amounts = uniswaprouter1.getAmountsOut(1e18, arr);
        // The function then returns the second element of
        // the array (index 1) which should be the amount of CONE token.
        return amounts[1];
    }

    // Safe CONE transfer function, just in case if rounding error causes pool to not have enough CONEs.
    function safeCONETransfer(address _to, uint256 _amount) internal {
        // The function first gets the current balance of CONE tokens held by the contract
        uint256 CONEBal = CONE.balanceOf(address(this));
        // uint256 min = (minimumDollarAmount.div(100)).mul(getCONERate());
        // The function defines total percentage as 100
        uint256 totalpercentage = 100;
        // The function defines user transfer as total percentage divided by 100
        uint256 usertransfer = totalpercentage.div(100);
        // The function checks if the amount of CONE tokens being transferred is greater than the current balance of the contract.
        // if it is, it transfers the entire contract balance multiplied by the user transfer percentage divided by 100 to the specified address.
        if (_amount > CONEBal) {
            CONE.transfer(_to, (CONEBal.mul(usertransfer)).div(100));
        }
        // If the amount of CONE tokens being transferred is less than or equal to the contract balance,
        // it transfers the specified amount multiplied by the user transfer percentage divided by 100 to the specified address.
        else {
            CONE.transfer(_to, (_amount.mul(usertransfer)).div(100));
        }
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }
}