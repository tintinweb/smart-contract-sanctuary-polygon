//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Swapient Subatomic Swaps on native and ERC20 tokens.
 *
 * This contract provides a way to:
 *  - Deposit tokens (create a sell order, or an unadressed deposit)
 *  - Add a receiver to a portion of your deposit (add a counterparty, creating an addressed deposit)
 *  - Claim an addressed deposit
 *  - Refund an unaddressed deposit
 *  - Refund an addressed deposit after
 *
 *
 * Protocol:
 *
 *  1) newValueDeposit() - a sender call to this with value creates a new unaddressed value deposit, returning a deposit ID.
 *      This represents an order on native tokens.
 *
 *  2) newERC20Deposit(token, value) - a sender call to this creates a new unaddressed ERC20 token deposit, returning a deposit ID.
 *      This represents an order on ER20 tokens.
 *
 *  3) addReceiver(depositId, value, receiver, hashlock, validityTime, options) - adds a receiver (counterparty) to a portion of your deposit, creating an addressedDeposit. Returns an ID.
 *      This has two idiomatic uses:
 *      - the counterparty adds the initiator as the receiver to their deposit, this creates a buy order
 *      - the initiator then adds the counterparty as the receiver to their deposit using the same preimage hash. This adds a counterparty to a sell order
 *
 *  5) claim(addressedDepositId, preimage) - is used to claim an addressed deposit.
 *      This has two idiomatic uses:
 *      - the counterparty claims the initiator's addressed deposit, revealing the hashlock preimage in the process
 *      - the initiator uses the revealed preimage, to claim the counterparty's addressed deposit
 *
 *  6) refundAddressedDeposit(addresssedDepositId) - used to refund addressed deposit back to the depositor address after timeout.
 *
 *  7) refundDeposit(depositId) - used to refund deposit back to the depositor address. This has no timeout.
 *
 *  8) cancelAddressedDeposit(addresssedDepositId) - used to cancel addressed deposit, and send value back to the original unaddressed deposit.
 *      This works only after a timeout.
 */
contract Swapient {
    using SafeERC20 for IERC20;

    enum DepositType {
        NATIVE,
        ERC20
    }

    event DepositCreated(uint256 indexed depositId);
    event DepositRefunded(uint256 indexed depositId);
    event AddressedDepositCreated(uint256 indexed addressedDepositId);
    event AddressedDepositClaimed(uint256 indexed addressedDepositId);
    event AddressedDepositRefunded(uint256 indexed depositId);
    event AddressedDepositCancelled(uint256 indexed depositId);

    // by default deposits are unaddressed
    struct Deposit {
        address depositor;
        DepositType depositType;
        uint256 amount;
        IERC20 erc20token;
        uint256 addressedDepositCount;
    }

    struct AddressedDeposit {
        uint256 parentDepositId;
        uint256 amount;
        address receiver;
        bytes32 hashlock;
        bytes32 preimage;
        uint256 expiryTime;
        bool active;
    }

    Deposit[] public deposits;
    AddressedDeposit[] public addressedDeposits;

    modifier correctDepositor(uint256 _depositId) {
        require(
            deposits[_depositId].depositor == msg.sender,
            "ERR__DEPOSITOR_MISMATCH"
        );
        _;
    }

    modifier notExpired(uint256 _addressedDepositId) {
        require(
            addressedDeposits[_addressedDepositId].expiryTime > block.timestamp,
            "ERR__EXPIRED"
        );
        _;
    }

    modifier isExpired(uint256 _addressedDepositId) {
        require(
            addressedDeposits[_addressedDepositId].expiryTime < block.timestamp,
            "ERR__NOT_EXPIRED"
        );
        _;
    }

    modifier notInactive(uint256 _addressedDepositId) {
        require(
            addressedDeposits[_addressedDepositId].active == true,
            "ERR__INACTIVE"
        );
        _;
    }

    modifier correctPreimage(uint256 _addressedDepositId, bytes32 _preimage) {
        require(
            addressedDeposits[_addressedDepositId].hashlock ==
                keccak256(abi.encodePacked(_preimage)),
            "ERR__INCORRECT_PREIMAGE"
        );
        _;
    }

    modifier correctReceiver(uint256 _addressedDepositId) {
        require(
            addressedDeposits[_addressedDepositId].receiver == msg.sender,
            "ERR__RECEIVER_MISMATCH"
        );
        _;
    }

    modifier isERC20Deposit(uint256 _depositId) {
        require(
            deposits[_depositId].depositType == DepositType.ERC20,
            "ERR__NOT_ERC20_DEPOSIT"
        );
        _;
    }

    modifier isNativeDeposit(uint256 _depositId) {
        require(
            deposits[_depositId].depositType == DepositType.NATIVE,
            "ERR__NOT_NATIVE_DEPOSIT"
        );
        _;
    }

    function addReceiver(
        uint256 _depositId,
        uint256 _amount,
        address _receiver,
        bytes32 _preimageHash,
        uint256 _validityTime
    ) external correctDepositor(_depositId) returns (uint256) {
        Deposit storage deposit = deposits[_depositId];

        require(deposit.amount >= _amount, "ERR__INSUFFICIENT_AMOUNT");

        deposit.amount -= _amount;
        deposit.addressedDepositCount++;

        AddressedDeposit memory newAddressedDeposit = AddressedDeposit(
            _depositId,
            _amount,
            _receiver,
            _preimageHash,
            0x0,
            block.timestamp + _validityTime * 1 seconds,
            true
        );

        addressedDeposits.push(newAddressedDeposit);

        uint256 addressedDepositId = addressedDeposits.length - 1;

        emit AddressedDepositCreated(addressedDepositId);
        return addressedDepositId;
    }

    function newNativeDeposit() external payable returns (uint256) {
        require(msg.value > 0, "ERR__NO_VALUE_SUPPLIED");
        Deposit memory deposit = Deposit(
            msg.sender,
            DepositType.NATIVE,
            msg.value,
            IERC20(address(0)),
            0
        );

        deposits.push(deposit);

        uint256 depositId = deposits.length - 1;

        emit DepositCreated(depositId);
        return depositId;
    }

    function newNativeDepositAndAddReceiver(
        address _receiver,
        bytes32 _hashlock,
        uint256 _expiryTime
    ) external payable returns (uint256, uint256) {
        require(msg.value > 0, "ERR__NO_VALUE_SUPPLIED");

        Deposit memory deposit = Deposit(
            msg.sender,
            DepositType.NATIVE,
            0,
            IERC20(address(0)),
            0
        );

        deposits.push(deposit);

        uint256 depositId = deposits.length - 1;

        AddressedDeposit memory newAddressedDeposit = AddressedDeposit(
            depositId,
            msg.value,
            _receiver,
            _hashlock,
            bytes32(0),
            _expiryTime,
            true
        );

        addressedDeposits.push(newAddressedDeposit);

        uint256 addressedDepositId = addressedDeposits.length - 1;

        deposits[depositId].addressedDepositCount++;

        emit DepositCreated(depositId);
        emit AddressedDepositCreated(addressedDepositId);

        emit DepositCreated(depositId);
        return (depositId, addressedDepositId);
    }

    function newERC20Deposit(
        address _tokenAddress,
        uint256 _amount
    ) external payable returns (uint256) {
        IERC20 token = IERC20(address(_tokenAddress));

        token.safeTransferFrom(msg.sender, address(this), _amount);

        Deposit memory newTokenDeposit = Deposit(
            msg.sender,
            DepositType.ERC20,
            _amount,
            token,
            0
        );

        deposits.push(newTokenDeposit);

        uint256 depositId = deposits.length - 1;

        emit DepositCreated(depositId);
        return depositId;
    }

    function newERC20DepositAndAddReceiver(
        address _tokenAddress,
        uint256 _amount,
        address _receiver,
        bytes32 _hashlock,
        uint256 _expiryTime
    ) external payable returns (uint256, uint256) {
        IERC20 token = IERC20(address(_tokenAddress));

        token.safeTransferFrom(msg.sender, address(this), _amount);

        Deposit memory newTokenDeposit = Deposit(
            msg.sender,
            DepositType.ERC20,
            _amount,
            token,
            0
        );

        deposits.push(newTokenDeposit);

        uint256 depositId = deposits.length - 1;

        AddressedDeposit memory newAddressedDeposit = AddressedDeposit(
            depositId,
            _amount,
            _receiver,
            _hashlock,
            bytes32(0),
            _expiryTime,
            true
        );

        addressedDeposits.push(newAddressedDeposit);

        uint256 addressedDepositId = addressedDeposits.length - 1;

        deposits[depositId].addressedDepositCount++;

        emit DepositCreated(depositId);
        emit AddressedDepositCreated(addressedDepositId);
        return (depositId, addressedDepositId);
    }

    function refundNativeDeposit(
        uint256 _depositId
    ) external isNativeDeposit(_depositId) {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.amount > 0, "ERR__ZERO_AMOUNT");

        address payable depositor = payable(deposit.depositor);
        uint256 amount = deposit.amount;

        deposit.amount = 0;
        depositor.transfer(amount);

        emit DepositRefunded(_depositId);
    }

    function refundERC20Deposit(
        uint256 _depositId
    ) external isERC20Deposit(_depositId) {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.amount > 0, "ERR__ZERO_AMOUNT");

        uint256 amount = deposit.amount;

        deposit.amount = 0;
        deposit.erc20token.safeTransfer(deposit.depositor, amount);

        emit DepositRefunded(_depositId);
    }

    function refundAddressedNativeDeposit(
        uint256 _addressedDepositId
    )
        external
        notInactive(_addressedDepositId)
        isExpired(_addressedDepositId)
        isNativeDeposit(_addressedDepositId)
    {
        AddressedDeposit storage addressedDeposit = addressedDeposits[
            _addressedDepositId
        ];

        Deposit memory deposit = deposits[addressedDeposit.parentDepositId];

        address payable depositor = payable(deposit.depositor);

        addressedDeposit.active = false;
        depositor.transfer(addressedDeposit.amount);

        emit AddressedDepositRefunded(_addressedDepositId);
    }

    function refundAddressedERC20Deposit(
        uint256 _addressedDepositId
    )
        external
        notInactive(_addressedDepositId)
        isExpired(_addressedDepositId)
        isERC20Deposit(_addressedDepositId)
    {
        AddressedDeposit storage addressedDeposit = addressedDeposits[
            _addressedDepositId
        ];

        Deposit memory parentDeposit = deposits[
            addressedDeposit.parentDepositId
        ];

        addressedDeposit.active = false;

        parentDeposit.erc20token.safeTransfer(
            parentDeposit.depositor,
            addressedDeposit.amount
        );

        emit AddressedDepositRefunded(_addressedDepositId);
    }

    function cancelAddressedDeposit(
        uint256 _addressedDepositId
    ) external notInactive(_addressedDepositId) isExpired(_addressedDepositId) {
        AddressedDeposit storage addressedDeposit = addressedDeposits[
            _addressedDepositId
        ];

        Deposit storage deposit = deposits[addressedDeposit.parentDepositId];

        deposit.amount += addressedDeposit.amount;
        addressedDeposit.active = false;

        emit AddressedDepositCancelled(_addressedDepositId);
    }

    function claimNative(
        uint256 _addressedDepositId,
        bytes32 _preimage
    )
        external
        notInactive(_addressedDepositId)
        notExpired(_addressedDepositId)
        correctPreimage(_addressedDepositId, _preimage)
        // correctReceiver(_addressedDepositId)
        isNativeDeposit(_addressedDepositId)
    {
        AddressedDeposit storage addressedDeposit = addressedDeposits[
            _addressedDepositId
        ];

        addressedDeposit.active = false;
        addressedDeposit.preimage = _preimage;

        address payable receiver = payable(addressedDeposit.receiver);
        receiver.transfer(addressedDeposit.amount);

        emit AddressedDepositClaimed(_addressedDepositId);
    }

    function claimERC20(
        uint256 _addressedDepositId,
        bytes32 _preimage
    )
        external
        notInactive(_addressedDepositId)
        notExpired(_addressedDepositId)
        correctPreimage(_addressedDepositId, _preimage)
        // correctReceiver(_addressedDepositId)
        isERC20Deposit(_addressedDepositId)
    {
        AddressedDeposit storage addressedDeposit = addressedDeposits[
            _addressedDepositId
        ];

        addressedDeposit.active = false;
        addressedDeposit.preimage = _preimage;

        Deposit memory parentDeposit = deposits[
            addressedDeposit.parentDepositId
        ];

        parentDeposit.erc20token.safeTransfer(
            addressedDeposit.receiver,
            addressedDeposit.amount
        );

        emit AddressedDepositClaimed(_addressedDepositId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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