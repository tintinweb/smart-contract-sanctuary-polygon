// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/ZkAddress.sol";
import "../interfaces/IOperatorManager.sol";
import "../interfaces/IZkBobDirectDeposits.sol";
import "../interfaces/IZkBobDirectDepositQueue.sol";
import "../interfaces/IZkBobPool.sol";
import "../utils/Ownable.sol";
import "../proxy/EIP1967Admin.sol";

/**
 * @title ZkBobDirectDepositQueue
 * Queue for zkBob direct deposits.
 */
contract ZkBobDirectDepositQueue is IZkBobDirectDeposits, IZkBobDirectDepositQueue, EIP1967Admin, Ownable {
    using SafeERC20 for IERC20;

    uint256 internal constant R = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant MAX_NUMBER_OF_DIRECT_DEPOSITS = 16;
    bytes4 internal constant MESSAGE_PREFIX_DIRECT_DEPOSIT_V1 = 0x00000001;

    uint256 internal immutable TOKEN_DENOMINATOR;
    uint256 internal constant TOKEN_NUMERATOR = 1;

    address public immutable token;
    uint256 public immutable pool_id;
    address public immutable pool;

    IOperatorManager public operatorManager;

    mapping(uint256 => IZkBobDirectDeposits.DirectDeposit) internal directDeposits;
    uint32 public directDepositNonce;
    uint64 public directDepositFee;
    uint40 public directDepositTimeout;

    event UpdateOperatorManager(address manager);
    event UpdateDirectDepositFee(uint64 fee);
    event UpdateDirectDepositTimeout(uint40 timeout);

    event SubmitDirectDeposit(
        address indexed sender,
        uint256 indexed nonce,
        address fallbackUser,
        ZkAddress.ZkAddress zkAddress,
        uint64 deposit
    );
    event RefundDirectDeposit(uint256 indexed nonce, address receiver, uint256 amount);
    event CompleteDirectDepositBatch(uint256[] indices);

    constructor(address _pool, address _token, uint256 _denominator) {
        require(Address.isContract(_token), "ZkBobDirectDepositQueue: not a contract");
        require(TOKEN_NUMERATOR == 1 || _denominator == 1, "ZkBobDirectDepositQueue: incorrect denominator");
        pool = _pool;
        token = _token;
        TOKEN_DENOMINATOR = _denominator;
        pool_id = uint24(IZkBobPool(_pool).pool_id());
    }

    /**
     * @dev Updates used operator manager contract.
     * Operator manager in this contract is only responsible for fast-track processing of refunds.
     * Usage of fully permissionless operator managers is not recommended, due to existence of front-running DoS attacks.
     * Callable only by the contract owner / proxy admin.
     * @param _operatorManager new operator manager implementation.
     */
    function setOperatorManager(IOperatorManager _operatorManager) external onlyOwner {
        require(address(_operatorManager) != address(0), "ZkBobDirectDepositQueue: manager is zero address");
        operatorManager = _operatorManager;
        emit UpdateOperatorManager(address(_operatorManager));
    }

    /**
     * @dev Updates direct deposit fee.
     * Callable only by the contract owner / proxy admin.
     * @param _fee new absolute fee value for making a direct deposit, in zkBOB units.
     */
    function setDirectDepositFee(uint64 _fee) external onlyOwner {
        directDepositFee = _fee;
        emit UpdateDirectDepositFee(_fee);
    }

    /**
     * @dev Updates direct deposit timeout.
     * Callable only by the contract owner / proxy admin.
     * @param _timeout new timeout value for refunding non-fulfilled/rejected direct deposits.
     */
    function setDirectDepositTimeout(uint40 _timeout) external onlyOwner {
        require(_timeout <= 7 days, "ZkBobDirectDepositQueue: timeout too large");
        directDepositTimeout = _timeout;
        emit UpdateDirectDepositTimeout(_timeout);
    }

    /// @inheritdoc IZkBobDirectDeposits
    function getDirectDeposit(uint256 _index) external view returns (IZkBobDirectDeposits.DirectDeposit memory) {
        return directDeposits[_index];
    }

    /// @inheritdoc IZkBobDirectDepositQueue
    function collect(
        uint256[] calldata _indices,
        uint256 _out_commit
    )
        external
        returns (uint256 total, uint256 totalFee, uint256 hashsum, bytes memory message)
    {
        require(msg.sender == pool, "ZkBobDirectDepositQueue: invalid caller");

        uint256 count = _indices.length;
        require(count > 0, "ZkBobDirectDepositQueue: empty deposit list");
        require(count <= MAX_NUMBER_OF_DIRECT_DEPOSITS, "ZkBobDirectDepositQueue: too many deposits");

        bytes memory input = new bytes(32 + (10 + 32 + 8) * MAX_NUMBER_OF_DIRECT_DEPOSITS);
        message = new bytes(4 + count * (8 + 10 + 32 + 8));
        assembly {
            mstore(add(input, 32), _out_commit)
            mstore(add(message, 32), or(shl(248, count), MESSAGE_PREFIX_DIRECT_DEPOSIT_V1))
        }
        total = 0;
        totalFee = 0;
        for (uint256 i = 0; i < count; ++i) {
            uint256 index = _indices[i];
            DirectDeposit storage dd = directDeposits[index];
            (bytes32 pk, bytes10 diversifier, uint64 deposit, uint64 fee, DirectDepositStatus status) =
                (dd.pk, dd.diversifier, dd.deposit, dd.fee, dd.status);
            require(status == DirectDepositStatus.Pending, "ZkBobDirectDepositQueue: direct deposit not pending");

            assembly {
                // bytes10(dd.diversifier) ++ bytes32(dd.pk) ++ bytes8(dd.deposit)
                let offset := mul(i, 50)
                mstore(add(input, add(64, offset)), diversifier)
                mstore(add(input, add(82, offset)), deposit)
                mstore(add(input, add(74, offset)), pk)
            }
            assembly {
                // bytes8(dd.index) ++ bytes10(dd.diversifier) ++ bytes32(dd.pk) ++ bytes8(dd.deposit)
                let offset := mul(i, 58)
                mstore(add(message, add(36, offset)), shl(192, index))
                mstore(add(message, add(44, offset)), diversifier)
                mstore(add(message, add(62, offset)), deposit)
                mstore(add(message, add(54, offset)), pk)
            }

            dd.status = DirectDepositStatus.Completed;

            total += deposit;
            totalFee += fee;
        }

        hashsum = uint256(keccak256(input)) % R;

        IERC20(token).safeTransfer(msg.sender, (total + totalFee) * TOKEN_DENOMINATOR / TOKEN_NUMERATOR);

        emit CompleteDirectDepositBatch(_indices);
    }

    /// @inheritdoc IZkBobDirectDeposits
    function directDeposit(
        address _fallbackUser,
        uint256 _amount,
        string calldata _zkAddress
    )
        external
        returns (uint256)
    {
        return directDeposit(_fallbackUser, _amount, bytes(_zkAddress));
    }

    /// @inheritdoc IZkBobDirectDeposits
    function directDeposit(
        address _fallbackUser,
        uint256 _amount,
        bytes memory _rawZkAddress
    )
        public
        returns (uint256)
    {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        return _recordDirectDeposit(msg.sender, _fallbackUser, _amount, _rawZkAddress);
    }

    /// @inheritdoc IZkBobDirectDeposits
    function onTokenTransfer(address _from, uint256 _value, bytes calldata _data) external returns (bool) {
        require(msg.sender == token, "ZkBobDirectDepositQueue: not a token caller");

        (address fallbackUser, bytes memory rawZkAddress) = abi.decode(_data, (address, bytes));

        _recordDirectDeposit(_from, fallbackUser, _value, rawZkAddress);

        return true;
    }

    /// @inheritdoc IZkBobDirectDeposits
    function refundDirectDeposit(uint256 _index) external {
        bool isOperator = operatorManager.isOperator(msg.sender);
        DirectDeposit storage dd = directDeposits[_index];
        require(dd.status == DirectDepositStatus.Pending, "ZkBobDirectDepositQueue: direct deposit not pending");
        require(
            isOperator || dd.timestamp + directDepositTimeout < block.timestamp,
            "ZkBobDirectDepositQueue: direct deposit timeout not passed"
        );
        _refundDirectDeposit(_index, dd);
    }

    /// @inheritdoc IZkBobDirectDeposits
    function refundDirectDeposit(uint256[] calldata _indices) external {
        bool isOperator = operatorManager.isOperator(msg.sender);

        uint256 timeout = directDepositTimeout;
        for (uint256 i = 0; i < _indices.length; ++i) {
            DirectDeposit storage dd = directDeposits[_indices[i]];

            if (dd.status == DirectDepositStatus.Pending) {
                require(
                    isOperator || dd.timestamp + timeout < block.timestamp,
                    "ZkBobDirectDepositQueue: direct deposit timeout not passed"
                );
                _refundDirectDeposit(_indices[i], dd);
            }
        }
    }

    function _refundDirectDeposit(uint256 _index, IZkBobDirectDeposits.DirectDeposit storage _dd) internal {
        _dd.status = IZkBobDirectDeposits.DirectDepositStatus.Refunded;

        (address fallbackReceiver, uint96 amount) = (_dd.fallbackReceiver, _dd.sent);

        IERC20(token).safeTransfer(fallbackReceiver, amount);

        emit RefundDirectDeposit(_index, fallbackReceiver, amount);
    }

    function _recordDirectDeposit(
        address _sender,
        address _fallbackReceiver,
        uint256 _amount,
        bytes memory _rawZkAddress
    )
        internal
        returns (uint256 nonce)
    {
        require(_fallbackReceiver != address(0), "ZkBobDirectDepositQueue: fallback user is zero");

        uint64 fee = directDepositFee;
        // small amount of wei might get lost during division, this amount will stay in the contract indefinitely
        uint64 depositAmount = uint64(_amount / TOKEN_DENOMINATOR * TOKEN_NUMERATOR);
        require(depositAmount > fee, "ZkBobDirectDepositQueue: direct deposit amount is too low");
        unchecked {
            depositAmount -= fee;
        }

        ZkAddress.ZkAddress memory zkAddress = ZkAddress.parseZkAddress(_rawZkAddress, uint24(pool_id));

        IZkBobDirectDeposits.DirectDeposit memory dd = IZkBobDirectDeposits.DirectDeposit({
            fallbackReceiver: _fallbackReceiver,
            sent: uint96(_amount),
            deposit: depositAmount,
            fee: fee,
            timestamp: uint40(block.timestamp),
            status: DirectDepositStatus.Pending,
            diversifier: zkAddress.diversifier,
            pk: zkAddress.pk
        });

        nonce = directDepositNonce++;
        directDeposits[nonce] = dd;

        IZkBobPool(pool).recordDirectDeposit(_sender, depositAmount);

        emit SubmitDirectDeposit(_sender, nonce, _fallbackReceiver, zkAddress, depositAmount);
    }

    /**
     * @dev Tells if caller is the contract owner.
     * Gives ownership rights to the proxy admin as well.
     * @return true, if caller is the contract owner or proxy admin.
     */
    function _isOwner() internal view override returns (bool) {
        return super._isOwner() || _admin() == _msgSender();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
                require(isContract(target), "Address: call to non-contract");
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

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@base58-solidity/Base58.sol";

/**
 * @title ZkAddress
 * Library for parsing zkBob addresses.
 */
library ZkAddress {
    uint256 internal constant R = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    error InvalidZkAddress();
    error InvalidZkAddressLength();
    error InvalidZkAddressChecksum();

    struct ZkAddress {
        bytes10 diversifier;
        bytes32 pk;
    }

    /**
     * @notice Parses zkBob address from the zkBob UI representation.
     * Note that on-chain base58 decoding is quite gas intensive (610k gas),
     * consider to use other gas efficient formats from the below.
     * @param _rawZkAddress zk address base58 string representation in the zkBob UI format.
     * @param _poolId id of the pool to verify checksum for.
     */
    function parseZkAddress(
        string calldata _rawZkAddress,
        uint24 _poolId
    )
        external
        pure
        returns (ZkAddress memory res)
    {
        bytes memory _rawZkAddressBytes = bytes(_rawZkAddress);
        uint256 len = _len(_rawZkAddressBytes);

        if (len > 63 || len < 47) {
            revert InvalidZkAddressLength();
        }

        // _zkAddress == Base58.encode(abi.encodePacked(bytes10(diversifier_le), bytes32(pk_le), bytes4(checksum)))
        bytes memory dec = Base58.decode(_rawZkAddressBytes);
        if (_len(dec) != 46) {
            revert InvalidZkAddressLength();
        }
        res = _parseZkAddressLE46(dec, _poolId);
        if (uint256(res.pk) >= R) {
            revert InvalidZkAddress();
        }
    }

    /**
     * @notice Parses zkBob address from the gas-efficient hex formats.
     * Note difference in endianness among checksummed and non-checksummed formats.
     * @param _rawZkAddress zk address hex representation in one of 3 formats.
     * @param _poolId id of the pool to verify checksum for.
     */
    function parseZkAddress(bytes memory _rawZkAddress, uint24 _poolId) external pure returns (ZkAddress memory res) {
        uint256 len = _len(_rawZkAddress);

        if (len == 42) {
            // _zkAddress == abi.encodePacked(bytes10(diversifier_be), bytes32(pk_be))
            res = ZkAddress(bytes10(_load(_rawZkAddress, 32)), _load(_rawZkAddress, 42));
        } else if (len == 64) {
            // _zkAddress == abi.encode(bytes10(diversifier_be), bytes32(pk_be)) == abi.encode(ZkAddress(zkAddress))
            res = abi.decode(_rawZkAddress, (ZkAddress));
        } else if (len == 46) {
            // _zkAddress == abi.encodePacked(bytes10(diversifier_le), bytes32(pk_le), bytes4(checksum))
            res = _parseZkAddressLE46(_rawZkAddress, _poolId);
        } else if (len < 64 && len > 46) {
            // _zkAddress == Base58.encode(abi.encodePacked(bytes10(diversifier_le), bytes32(pk_le), bytes4(checksum)))
            bytes memory dec = Base58.decode(_rawZkAddress);
            if (_len(dec) != 46) {
                revert InvalidZkAddressLength();
            }
            res = _parseZkAddressLE46(dec, _poolId);
        } else {
            revert InvalidZkAddressLength();
        }
        if (uint256(res.pk) >= R) {
            revert InvalidZkAddress();
        }
    }

    function _parseZkAddressLE46(bytes memory _rawZkAddress, uint24 _poolId) internal pure returns (ZkAddress memory) {
        _verifyChecksum(_poolId, _rawZkAddress);
        bytes32 diversifier = _toLE(_load(_rawZkAddress, 32)) << 176;
        bytes32 pk = _toLE(_load(_rawZkAddress, 42));
        return ZkAddress(bytes10(diversifier), pk);
    }

    function _verifyChecksum(uint24 _poolId, bytes memory _rawZkAddress) internal pure {
        bytes4 checksum = bytes4(_load(_rawZkAddress, 74));
        bytes32 zkAddressHash;
        assembly {
            zkAddressHash := keccak256(add(_rawZkAddress, 32), 42)
        }
        bytes4 zkAddressChecksum1 = bytes4(zkAddressHash);
        bytes4 zkAddressChecksum2 = bytes4(keccak256(abi.encodePacked(_poolId, zkAddressHash)));
        if (checksum != zkAddressChecksum1 && checksum != zkAddressChecksum2) {
            revert InvalidZkAddressChecksum();
        }
    }

    function _len(bytes memory _b) internal pure returns (uint256 len) {
        assembly {
            len := mload(_b)
        }
    }

    function _load(bytes memory _b, uint256 _offset) internal pure returns (bytes32 word) {
        assembly {
            word := mload(add(_b, _offset))
        }
    }

    function _toLE(bytes32 _value) internal pure returns (bytes32 res) {
        assembly {
            res := byte(0, _value)
            res := add(res, shl(8, byte(1, _value)))
            res := add(res, shl(16, byte(2, _value)))
            res := add(res, shl(24, byte(3, _value)))
            res := add(res, shl(32, byte(4, _value)))
            res := add(res, shl(40, byte(5, _value)))
            res := add(res, shl(48, byte(6, _value)))
            res := add(res, shl(56, byte(7, _value)))
            res := add(res, shl(64, byte(8, _value)))
            res := add(res, shl(72, byte(9, _value)))
            res := add(res, shl(80, byte(10, _value)))
            res := add(res, shl(88, byte(11, _value)))
            res := add(res, shl(96, byte(12, _value)))
            res := add(res, shl(104, byte(13, _value)))
            res := add(res, shl(112, byte(14, _value)))
            res := add(res, shl(120, byte(15, _value)))
            res := add(res, shl(128, byte(16, _value)))
            res := add(res, shl(136, byte(17, _value)))
            res := add(res, shl(144, byte(18, _value)))
            res := add(res, shl(152, byte(19, _value)))
            res := add(res, shl(160, byte(20, _value)))
            res := add(res, shl(168, byte(21, _value)))
            res := add(res, shl(176, byte(22, _value)))
            res := add(res, shl(184, byte(23, _value)))
            res := add(res, shl(192, byte(24, _value)))
            res := add(res, shl(200, byte(25, _value)))
            res := add(res, shl(208, byte(26, _value)))
            res := add(res, shl(216, byte(27, _value)))
            res := add(res, shl(224, byte(28, _value)))
            res := add(res, shl(232, byte(29, _value)))
            res := add(res, shl(240, byte(30, _value)))
            res := add(res, shl(248, byte(31, _value)))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IOperatorManager {
    function isOperator(address _addr) external view returns (bool);

    function isOperatorFeeReceiver(address _operator, address _addr) external view returns (bool);

    function operatorURI() external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IZkBobDirectDeposits {
    enum DirectDepositStatus {
        Missing, // requested deposit does not exist
        Pending, // requested deposit was submitted and is pending in the queue
        Completed, // requested deposit was successfully processed
        Refunded // requested deposit was refunded to the fallback receiver
    }

    struct DirectDeposit {
        address fallbackReceiver; // refund receiver for deposits that cannot be processed
        uint96 sent; // sent amount in BOB tokens (18 decimals)
        uint64 deposit; // deposit amount, after subtracting all fees (9 decimals)
        uint64 fee; // deposit fee (9 decimals)
        uint40 timestamp; // deposit submission timestamp
        DirectDepositStatus status; // deposit status
        bytes10 diversifier; // receiver zk address, part 1/2
        bytes32 pk; // receiver zk address, part 2/2
    }

    /**
     * @notice Retrieves the direct deposits from the queue by its id.
     * @param depositId id of the submitted deposit.
     * @return deposit recorded deposit struct
     */
    function getDirectDeposit(uint256 depositId) external view returns (DirectDeposit memory deposit);

    /**
     * @notice Performs a direct deposit to the specified zk address.
     * In case the deposit cannot be processed, it can be refunded later to the fallbackReceiver address.
     * @param fallbackReceiver receiver of deposit refund.
     * @param amount direct deposit amount.
     * @param zkAddress receiver zk address.
     * @return depositId id of the submitted deposit to query status for.
     */
    function directDeposit(
        address fallbackReceiver,
        uint256 amount,
        bytes memory zkAddress
    )
        external
        returns (uint256 depositId);

    /**
     * @notice Performs a direct deposit to the specified zk address.
     * In case the deposit cannot be processed, it can be refunded later to the fallbackReceiver address.
     * @param fallbackReceiver receiver of deposit refund.
     * @param amount direct deposit amount.
     * @param zkAddress receiver zk address.
     * @return depositId id of the submitted deposit to query status for.
     */
    function directDeposit(
        address fallbackReceiver,
        uint256 amount,
        string memory zkAddress
    )
        external
        returns (uint256 depositId);

    /**
     * @notice ERC677 callback for performing a direct deposit.
     * Do not call this function directly, it's only intended to be called by the token contract.
     * @param from original tokens sender.
     * @param amount direct deposit amount.
     * @param data encoded address pair - abi.encode(address(fallbackReceiver), bytes(zkAddress))
     * @return ok true, if deposit of submitted successfully.
     */
    function onTokenTransfer(address from, uint256 amount, bytes memory data) external returns (bool ok);

    /**
     * @notice Tells the direct deposit fee, in zkBOB units (9 decimals).
     * @return fee direct deposit submission fee.
     */
    function directDepositFee() external view returns (uint64 fee);

    /**
     * @notice Tells the timeout after which unprocessed direct deposits can be refunded.
     * @return timeout duration in seconds.
     */
    function directDepositTimeout() external view returns (uint40 timeout);

    /**
     * @notice Tells the nonce of next direct deposit.
     * @return nonce direct deposit nonce.
     */
    function directDepositNonce() external view returns (uint32 nonce);

    /**
     * @notice Refunds specified direct deposit.
     * Can be called by anyone, but only after the configured timeout has passed.
     * Function will revert for deposit that is not pending.
     * @param index deposit id to issue a refund for.
     */
    function refundDirectDeposit(uint256 index) external;

    /**
     * @notice Refunds multiple direct deposits.
     * Can be called by anyone, but only after the configured timeout has passed.
     * Function will do nothing for non-pending deposits and will not revert.
     * @param indices deposit ids to issue a refund for.
     */
    function refundDirectDeposit(uint256[] memory indices) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IZkBobDirectDepositQueue {
    /**
     * @dev Collects aggregated info about submitted direct deposits and marks them as completed.
     * Callable only by the zkBOB pool contract.
     * @param _indices list of direct deposit indices to process, max of 16 indices are allowed.
     * @param _out_commit pre-calculated out commitment associated with the given deposits.
     * @return total sum of deposit amounts, not counting fees.
     * @return totalFee sum of deposit fees.
     * @return hashsum hashsum over all retrieved direct deposits.
     * @return message memo message to record into the tree.
     */
    function collect(
        uint256[] calldata _indices,
        uint256 _out_commit
    )
        external
        returns (uint256 total, uint256 totalFee, uint256 hashsum, bytes memory message);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IZkBobPool {
    function pool_id() external view returns (uint256);

    function recordDirectDeposit(address _sender, uint256 _amount) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol" as OZOwnable;

/**
 * @title Ownable
 */
contract Ownable is OZOwnable.Ownable {
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view override {
        require(_isOwner(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Tells if caller is the contract owner.
     * @return true, if caller is the contract owner.
     */
    function _isOwner() internal view virtual returns (bool) {
        return owner() == _msgSender();
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

/**
 * @title EIP1967Admin
 * @dev Upgradeable proxy pattern implementation according to minimalistic EIP1967.
 */
contract EIP1967Admin {
    // EIP 1967
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    uint256 internal constant EIP1967_ADMIN_STORAGE = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    modifier onlyAdmin() {
        require(msg.sender == _admin(), "EIP1967Admin: not an admin");
        _;
    }

    function _admin() internal view returns (address res) {
        assembly {
            res := sload(EIP1967_ADMIN_STORAGE)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title Base58
 * @author [email protected]
 * @notice This algorithm was migrated from github.com/mr-tron/base58 to solidity.
 * Note that it is not yet optimized for gas, so it is recommended to use it only in the view/pure function.
 */
library Base58 {
    bytes constant ALPHABET =
        "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /**
     * @notice encode is used to encode the given bytes in base58 standard.
     * @param data_ raw data, passed in as bytes.
     * @return base58 encoded data_, returned as bytes.
     */
    function encode(bytes memory data_) public pure returns (bytes memory) {
        unchecked {
            uint256 size = data_.length;
            uint256 zeroCount;
            while (zeroCount < size && data_[zeroCount] == 0) {
                zeroCount++;
            }
            size = zeroCount + ((size - zeroCount) * 8351) / 6115 + 1;
            bytes memory slot = new bytes(size);
            uint32 carry;
            int256 m;
            int256 high = int256(size) - 1;
            for (uint256 i = 0; i < data_.length; i++) {
                m = int256(size - 1);
                for (carry = uint8(data_[i]); m > high || carry != 0; m--) {
                    carry = carry + 256 * uint8(slot[uint256(m)]);
                    slot[uint256(m)] = bytes1(uint8(carry % 58));
                    carry /= 58;
                }
                high = m;
            }
            uint256 n;
            for (n = zeroCount; n < size && slot[n] == 0; n++) {}
            size = slot.length - (n - zeroCount);
            bytes memory out = new bytes(size);
            for (uint256 i = 0; i < size; i++) {
                uint256 j = i + n - zeroCount;
                out[i] = ALPHABET[uint8(slot[j])];
            }
            return out;
        }
    }

    /**
     * @notice decode is used to decode the given string in base58 standard.
     * @param data_ data encoded with base58, passed in as bytes.
     * @return raw data, returned as bytes.
     */
    function decode(bytes memory data_) public pure returns (bytes memory) {
        unchecked {
            uint256 zero = 49;
            uint256 b58sz = data_.length;
            uint256 zcount = 0;
            for (uint256 i = 0; i < b58sz && uint8(data_[i]) == zero; i++) {
                zcount++;
            }
            uint256 t;
            uint256 c;
            bool f;
            bytes memory binu = new bytes(2 * (((b58sz * 8351) / 6115) + 1));
            uint32[] memory outi = new uint32[]((b58sz + 3) / 4);
            for (uint256 i = 0; i < data_.length; i++) {
                bytes1 r = data_[i];
                (c, f) = indexOf(ALPHABET, r);
                require(f, "invalid base58 digit");
                for (int256 k = int256(outi.length) - 1; k >= 0; k--) {
                    t = uint64(outi[uint256(k)]) * 58 + c;
                    c = t >> 32;
                    outi[uint256(k)] = uint32(t & 0xffffffff);
                }
            }
            uint64 mask = uint64(b58sz % 4) * 8;
            if (mask == 0) {
                mask = 32;
            }
            mask -= 8;
            uint256 outLen = 0;
            for (uint256 j = 0; j < outi.length; j++) {
                while (mask < 32) {
                    binu[outLen] = bytes1(uint8(outi[j] >> mask));
                    outLen++;
                    if (mask < 8) {
                        break;
                    }
                    mask -= 8;
                }
                mask = 24;
            }
            for (uint256 msb = zcount; msb < binu.length; msb++) {
                if (binu[msb] > 0) {
                    return slice(binu, msb - zcount, outLen);
                }
            }
            return slice(binu, 0, outLen);
        }
    }

    /**
     * @notice encodeToString is used to encode the given byte in base58 standard.
     * @param data_ raw data, passed in as bytes.
     * @return base58 encoded data_, returned as a string.
     */
    function encodeToString(bytes memory data_) public pure returns (string memory) {
        return string(encode(data_));
    }

    /**
     * @notice encodeFromString is used to encode the given string in base58 standard.
     * @param data_ raw data, passed in as a string.
     * @return base58 encoded data_, returned as bytes.
     */
    function encodeFromString(string memory data_)
        public
        pure
        returns (bytes memory)
    {
        return encode(bytes(data_));
    }

    /**
     * @notice decode is used to decode the given string in base58 standard.
     * @param data_ data encoded with base58, passed in as string.
     * @return raw data, returned as bytes.
     */
    function decodeFromString(string memory data_)
        public
        pure
        returns (bytes memory)
    {
        return decode(bytes(data_));
    }

    /**
     * @notice slice is used to slice the given byte, returns the bytes in the range of [start_, end_)
     * @param data_ raw data, passed in as bytes.
     * @param start_ start index.
     * @param end_ end index.
     * @return slice data
     */
    function slice(
        bytes memory data_,
        uint256 start_,
        uint256 end_
    ) public pure returns (bytes memory) {
        unchecked {
            bytes memory ret = new bytes(end_ - start_);
            for (uint256 i = 0; i < end_ - start_; i++) {
                ret[i] = data_[i + start_];
            }
            return ret;
        }
    }

    /**
     * @notice indexOf is used to find where char_ appears in data_.
     * @param data_ raw data, passed in as bytes.
     * @param char_ target byte.
     * @return index, and whether the search was successful.
     */
    function indexOf(bytes memory data_, bytes1 char_)
        public
        pure
        returns (uint256, bool)
    {
        unchecked {
            for (uint256 i = 0; i < data_.length; i++) {
                if (data_[i] == char_) {
                    return (i, true);
                }
            }
            return (0, false);
        }
    }
}

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