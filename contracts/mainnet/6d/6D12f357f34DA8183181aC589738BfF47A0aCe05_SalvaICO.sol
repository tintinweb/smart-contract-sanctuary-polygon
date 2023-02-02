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

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

//An ICO-cum-coin sale contract
// During ICO invest() will be called for ico investors.
// After ico ends, invest() will revert. Buy() fuction will be called by users to by coins.
// The following values can not be changed after deployment: admin, tokenPrice, saleEnd, tokenTradeStart, minInvestment.

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SalvaICO {
    using SafeERC20 for IERC20;
    IERC20 public salvaContract;

    //Enums
    enum State {
        beforeStart,
        running,
        ended,
        halted
    }

    enum ContractState {
        unhalted,
        halted
    }

    // State vars.

    State public state;
    ContractState public contractState;

    // Admin can be changed by the current admin.
    address public admin;

    // Following values are not modifiable after deployment.
    uint256 public tokenPrice = 1 ether; // 1 MATIC = 1 Coin.
    uint256 public raisedAmount; // Value will be in wei
    // uint256 public saleStart = block.timestamp;
    uint256 public saleEnd = block.timestamp + 2678400; //31 days

    uint256 public tokenTradeStart = saleEnd + 604800; //A week after saleEnd. 7 days = 604800
    uint256 public minInvestment = 1 ether;

    // Non modifialble values ends here.

    mapping(address => bool) private blocked;

    // Events
    event Invested(
        address indexed investor,
        uint256 indexed maticReceived,
        uint256 tokensSent
    );
    event CoinSold(address indexed buyer, uint256 indexed amount);
    event AdminChanged(address indexed newAdmin, address indexed oldAdmin);
    event SalvaTokensWithdrawn(
        address indexed withdrawer,
        IERC20 tokenAddress,
        uint256 indexed amount
    );
    event ERC20TokenWithdrawal(
        address withdrawer,
        address ERC20token,
        uint256 amount
    );

    event ERC20Withdrawn(address receiver, uint256 value);

    // Setting salvacontract address and amin in constructor

    constructor(address _salvaContract, address _admin) {
        salvaContract = IERC20(_salvaContract);
        admin = _admin;
        state == State.beforeStart;
    }

    /// @dev function to stop ico.

    function stop() external {
        require(
            contractState == ContractState.unhalted,
            "ICO: contract halted."
        );

        require(msg.sender == admin, "ICO: only admin!");
        require(state != State.halted, "ICO: already stopped!");
        state = State.halted;
    }

    /// @dev function to start ico callable only by the admin

    function start() external {
        require(
            contractState == ContractState.unhalted,
            "ICO: contract halted."
        );

        require(msg.sender == admin, "ICO: only admin!");
        require(state == State.halted || state == State.beforeStart, "ICO: already running!");
        state = State.running;
    }

    /// @dev Public function too get current state of ICO.

    function getICOState() public view returns (State) {
        if (block.timestamp <= saleEnd && state == State.running) {
            return State.running;
        } else if (block.timestamp > saleEnd) {
            return State.ended;
        } else if (state == State.halted) {
            return State.halted;
        } else if (state == State.beforeStart) {
            return State.beforeStart;
        } else {
            return state;
        }
    }

    // function called when sending eth to the contract.
    // this function can not be called and revertes after ico ends. Third line of the below code ensures this.

    function invest() external payable returns (bool) {
        require(
            contractState == ContractState.unhalted,
            "ICO: contract halted."
        );

        require(!blocked[msg.sender], "ICO: user blocked.");

        state = getICOState();
        require(state == State.running, "ICO: must be in running state.");

        // after ico ends. this function reverts here.
        require(block.timestamp < saleEnd, "ICO: ico ended.");
        require(msg.value >= minInvestment, "ICO: amount must be >= 1 MATIC.");

        require(
            salvaContract.balanceOf(address(this)) > 0,
            "ICO: 0 contract fund"
        );

        raisedAmount += msg.value;

        // require(raisedAmount <= hardCap);

        uint256 _valueSent = msg.value;

        uint256 _salvaCoins = (_valueSent * 10**18) / tokenPrice;

        address _to = msg.sender;

        emit Invested(_to, msg.value, _salvaCoins);

        // sending Salvacoin to buyer

        _sendTokens(_to, _salvaCoins);

        return true;
    }


    /// @dev Private function for sending tokens

    function _sendTokens(address _to, uint256 _salvaCoins) private {
        salvaContract.safeTransfer(_to, _salvaCoins);
    }

    /// @dev Admin function to withdraw unsold ERC20 tokens
    /// @dev Total remaining ERC20 token is sent back to the caller(admin)
    /// @dev Can be called only after ico sale ends. 2nd line of this function ensures that.

    function withdrawSalvaTokens() external returns (bool success) {
        require(
            contractState == ContractState.unhalted,
            "ICO: in halted state."
        );

        require(msg.sender == admin, "ICO: only admin!");
        require(block.timestamp > saleEnd); // the token will be transferable only after tokenTradeStart
        address _to = msg.sender;
        uint256 _amount = this.contractTokenBalance();

        if (_amount == 0) {
            revert("ICO: zero coins to withdraw.");
        }

        emit SalvaTokensWithdrawn(_to, salvaContract, _amount);

        _sendTokens(_to, _amount);

        return true;
    }

    /// @dev Admin function to recover other ERC20 tokens than SalvaCoin.

    function recoverOtherTokens(address _tokenAddress, uint256 _tokenAmount)
        public
    {
        require(
            contractState == ContractState.unhalted,
            "ICO: in halted state."
        );

        address _caller = msg.sender;
        require(_caller == admin, "ICO: only admin!");

        require(
            _tokenAddress != address(this),
            "ICO: cannot be this contract address"
        );

        uint256 _tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));

        require(_tokenAmount >= _tokenBalance, "ICO: insufficient balance");

        emit ERC20Withdrawn(msg.sender, _tokenBalance);

        emit ERC20TokenWithdrawal(_caller, _tokenAddress, _tokenBalance);

        IERC20(_tokenAddress).transfer(_caller, _tokenAmount);
    }

    /// @dev Admin function to withdraw total ico sales amount in MATIC to admin wallet.
    /// @dev Total ico amount is sent to the caller(admin).

    function withdrawICOAmount() external {
        require(
            contractState == ContractState.unhalted,
            "ICO: in halted state."
        );

        require(msg.sender == admin, "ICO: only admin!");

        uint256 _amount = address(this).balance;

        require(_amount > 0, "ICO: zero ICO contract balance.");

        address payable _to = payable(msg.sender);

        (bool success, ) = _to.call{value: _amount}("");

        require(success, "ICO: ICO amount withdrawal failed");
    }

    /// @dev View function for fetching salva token balance of this contract.

    function contractTokenBalance() external view returns (uint256 _tokens) {
        require(msg.sender == admin, "ICO: only admin!");
        address _thisContract = address(this);
        return salvaContract.balanceOf(_thisContract);
    }

    /// @dev Only admin can block users.

    function blockUser(address _user) external returns (bool) {
        require(
            contractState == ContractState.unhalted,
            "ICO: in halted state."
        );

        require(msg.sender == admin, "ICO: only admin!");

        if (blocked[_user]) {
            revert("ICO: alreday blocked.");
        } else {
            blocked[_user] = true;
        }
        return true;
    }

    /// @dev Only admin can unblock users.

    function unBlockUser(address _user) external returns (bool) {
        require(
            contractState == ContractState.unhalted,
            "ICO: in halted state."
        );

        require(msg.sender == admin, "ICO: only admin!");

        if (!blocked[_user]) {
            revert("ICO: already unblocked.");
        } else {
            blocked[_user] = false;
        }
        return true;
    }

    /// @dev Admin can change the contract state from halted to unHalted and back to halted.
    /// @dev In in halted mode. All sate modifying function are going to revert.

    function changeContractState() external {
        require(msg.sender == admin, "ICO: only admin!");

        if (contractState == ContractState.unhalted) {
            contractState = ContractState.halted;
        } else {
            contractState = ContractState.unhalted;
        }
    }

    /// @dev Buy function to buy SalvaCoin send to this contract by SalvaContract.
    /// @dev Only callable after ICO ends.

    function buyCoin() external payable returns (bool) {
        require(block.timestamp > saleEnd, "ICO: only after ICO ends.");
        require(msg.value >= tokenPrice, "ICO: send right amount.");
        address _to = msg.sender;
        uint256 _salvaCoins = (msg.value * 10**18) / tokenPrice;

        //emitting event.
        emit CoinSold(_to, _salvaCoins);
        salvaContract.safeTransfer(_to, _salvaCoins);
        return true;
    }

    /// @dev Admin can change the admin of this contract

    function changeAdmin(address _newAdmin) external returns (bool) {
        address _caller = msg.sender;
        require(_caller == admin, "ICO: only admin.");

        admin = _newAdmin;

        // emitting event.
        emit AdminChanged(_newAdmin, admin);

        return true;
    }
}