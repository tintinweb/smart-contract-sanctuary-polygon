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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ID8XCoin {
    function burn(uint256 _amount) external;

    function votes(address holder) external view returns (uint256);

    function canVoteFor(address delegate, address owner) external view returns (bool);

    function totalVotes() external view returns (uint256);

    function delegateVoteTo(address delegate) external;

    function epochDurationSec() external returns (uint256);

    function isQualified(
        address sender,
        uint16 _percentageBps,
        address[] calldata helpers
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Interface for reward contract
 */

interface IGovernanceRewards {
    function withdraw(address _tokenAddr, address[] calldata _delegators) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ID8XCoin } from "../token/ID8XCoin.sol";
import { IGovernanceRewards } from "../treasury/IGovernanceRewards.sol";

contract Vesting {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event RewardClaimed(
        address rewardContractAddr,
        address rewardTokenAddr,
        uint256 amountReceived
    );
    event WithdrawVestedToken(uint256 amntWithdrawn, uint256 currentVestLeft);
    event VestingEnded(
        uint256 totalAmntOwned,
        uint256 amntLeftToWithdraw,
        uint256 amntLostToTreasury
    );
    event VoteDelegated(address delegate);

    uint64 public immutable startTS; // vesting starts at this timestamp
    uint64 public immutable endTS; // vesting ends at this timestamp
    uint256 public immutable amount; // amount that the contract starts with; can only change when vesting ends
    uint256 public amountWithdrawn; // amount that was already withdrawn
    address public immutable tokenAddr;
    address public immutable ownerAddr;
    address public immutable vestingFactory;

    /**
     * Constructor
     * @notice this is an external function. To avoid that addresses will be blocked,
     * we require that the minimal amount is 10 (0x8ac7230489e80000 in dec18 format)
     * @param _factoryAddr address of the vesting factory
     * @param _ownerAddr address of the owner of the vesting contract
     * @param  _tokenAddr address of the governance token
     * @param _startTS timestamp when vesting starts (regular vesting contract)
     * @param _endTS timestamp, defines end of the linear vesting schedule
     * @param _amount total amount in the vesting contract
     */
    constructor(
        address _factoryAddr,
        address _ownerAddr,
        address _tokenAddr,
        uint64 _startTS,
        uint64 _endTS,
        uint256 _amount
    ) {
        require(_factoryAddr != address(0), "zero addr");
        require(_ownerAddr != address(0), "zero addr");
        require(_amount > 0x8ac7230489e80000, "amt too small");
        vestingFactory = _factoryAddr;
        ownerAddr = _ownerAddr;
        tokenAddr = _tokenAddr;
        startTS = _startTS;
        endTS = _endTS;
        amount = _amount;
    }

    /**
     * Amount of the total that already vested.
     * Previous withdrawals are not factored-in.
     */
    function amountVested() external view returns (uint256) {
        if (block.timestamp < startTS) {
            return 0;
        }
        if (block.timestamp > endTS) {
            return amount;
        }
        return _amountVested();
    }

    /**
     * Internal function amount of the total that already vested.
     * Does not check for block.timestamp < startTS
     * @notice all tokens of type tokenAddr that the contract owns can be withdrawn
     * after vesting ended. Only relevant in case for some reason the contract would
     * have more tokens than originally set
     */
    function _amountVested() internal view returns (uint256) {
        return ((block.timestamp - startTS) * amount) / (endTS - startTS);
    }

    /**
     * Amount owned corresponds to the amount that has vested
     * for regular vesting contracts
     */
    function _amountOwned() internal view virtual returns (uint256) {
        return _amountVested();
    }

    /**
     * owner can withdraw according to vesting schedule:
     * linear vest from t0 to t1 of the amount 'amount'.
     * @notice all tokens of type tokenAddr that the contract owns can be withdrawn
     * after vesting ended. Only relevant in case for some reason the contract would
     * have more tokens than originally set.
     * Therefore after endTS, the owner can withdraw all D8X in the contract
     * @param _amnt   amount the owner wants to withdraw
     */
    function withdraw(uint256 _amnt) external {
        require(block.timestamp > startTS, "t0 not reached");
        require(msg.sender == ownerAddr, "not owner");
        uint256 max;
        if (block.timestamp < endTS) {
            max = _amountVested() - amountWithdrawn;
        } else {
            max = IERC20Upgradeable(tokenAddr).balanceOf(address(this));
        }
        require(_amnt <= max, "amnt too large");
        amountWithdrawn = amountWithdrawn + _amnt;
        IERC20Upgradeable(tokenAddr).safeTransfer(ownerAddr, _amnt);
        emit WithdrawVestedToken(_amnt, max - _amnt);
    }

    /**
     * Delegate the vote for the vesting contract's tokens
     * to another address. Only owners can delegate
     * @param _delegate address the owner wishes to delegate too
     */
    function delegateVoteTo(address _delegate) external {
        require(msg.sender == ownerAddr, "not owner");
        ID8XCoin(tokenAddr).delegateVoteTo(_delegate);
        emit VoteDelegated(_delegate);
    }

    /**
     * Withdraw reward from governance reward contract using voting contract's voting power
     * @param _rewardContractAddr   address of reward contract that implements IReward
     * @param _tokenAddr            address of reward token (ERC20) that can be withdrawn
     */
    function claimGovernanceReward(address _rewardContractAddr, address _tokenAddr) external {
        require(msg.sender == ownerAddr, "not owner");
        IERC20Upgradeable rewardTkn = IERC20Upgradeable(_tokenAddr);
        uint256 amountBefore = rewardTkn.balanceOf(address(this));
        IGovernanceRewards(_rewardContractAddr).withdraw(_tokenAddr, new address[](0));
        uint256 amountReceived = rewardTkn.balanceOf(address(this)) - amountBefore;
        rewardTkn.safeTransfer(ownerAddr, amountReceived);
        emit RewardClaimed(_rewardContractAddr, _tokenAddr, amountReceived);
    }

    /**
     * If the vesting contract holder delegates his vote, the delegate can
     * withdraw the delegator's earnings. With this function the vesting
     * contract holder can withdraw the token.
     * @param _rewardTokenAddr token to be withdrawn
     */
    function withdrawReward(address _rewardTokenAddr) external {
        require(msg.sender == ownerAddr, "not owner");
        require(_rewardTokenAddr != tokenAddr, "use withdraw");
        IERC20Upgradeable rewardTkn = IERC20Upgradeable(_rewardTokenAddr);
        uint256 balance = rewardTkn.balanceOf(address(this));
        require(balance > 0, "no balance");
        rewardTkn.safeTransfer(ownerAddr, balance);
    }

    /**
     * For regular vesting contracts, the amount vested belongs to
     * the owner, the rest is transferred to a recipient.
     * @notice the factory removes the reference to the vesting contract
     * after calling end vesting, so function is only called once
     * @param _recipient receives unvested funds
     */
    function endVesting(address _recipient) external virtual {
        _endVesting(_recipient, startTS);
    }

    /**
     * Internal function to end vesting
     * @param _recipient receiver of tokens not owned
     * @param _startTS timestamp when vesting starts (regular vesting contract), or when ownership
     *  starts (CLevel vesting contract)
     */
    function _endVesting(address _recipient, uint64 _startTS) internal {
        require(msg.sender == vestingFactory, "only vesting factory");
        require(block.timestamp < endTS, "vesting ended");
        // amount vested belongs to the owner of the vesting contract
        uint256 amountOwned = block.timestamp > _startTS ? _amountOwned() : 0;
        uint256 amountNotOwned = amount - amountOwned;
        IERC20Upgradeable(tokenAddr).safeTransfer(_recipient, amountNotOwned);
        uint256 newOwnerAmount = amountOwned - amountWithdrawn;
        emit VestingEnded(amountOwned, newOwnerAmount, amountNotOwned);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Vesting } from "./Vesting.sol";

contract VestingCLvl is Vesting {
    uint64 public immutable genesisTS; // token generation event

    /**
     * Constructor
     * @param _factory address of the vesting factory
     * @param _ownerAddr address of the owner of the vesting contract
     * @param  _tokenAddr address of the governance token
     * @param _genesisTS timestamp when ownership starts
     * @param _startTS timestamp when vesting starts (regular vesting contract)
     * @param _endTS timestamp, defines end of the linear vesting and ownership
     * schedule
     * @param _amount total amount in the vesting contract
     */
    constructor(
        address _factory,
        address _ownerAddr,
        address _tokenAddr,
        uint64 _genesisTS,
        uint64 _startTS,
        uint64 _endTS,
        uint256 _amount
    ) Vesting(_factory, _ownerAddr, _tokenAddr, _startTS, _endTS, _amount) {
        genesisTS = _genesisTS;
    }

    /**
     * Amount of tokens owned by C-Level owner corresponds
     * to linear function since "genesis timestamp".
     * If genesisTs = startTs then this corresponds to a regular
     * vesting contract
     */
    function _amountOwned() internal view override returns (uint256) {
        return ((block.timestamp - genesisTS) * amount) / (endTS - genesisTS);
    }

    /**
     * For c-level vesting contracts, the "amount" linearly
     * accrued since "genesis" counts as owned. This is to reward c-level
     * that have contributed till project launch.
     * @param _recipient receives unvested funds
     */
    function endVesting(address _recipient) external virtual override {
        _endVesting(_recipient, genesisTS);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Vesting } from "./Vesting.sol";
import { VestingCLvl } from "./VestingCLvl.sol";
import { VestingInvestor } from "./VestingInvestor.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract VestingFactory {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event VestingContractCreated(
        address addr,
        address owner,
        uint64 genesis,
        uint64 startTS,
        uint64 endTS,
        uint256 amount,
        string vestingType
    );

    address public immutable tokenAddr; //token
    mapping(address => address) public ownerToVesting;
    address public cLevelMultiSigAddr;

    /**
     * Constructor
     * @param  _tokenAddr address of the governance token
     * @param _cLevelMultiSigAddr address controlling the vesting factory
     */
    constructor(address _tokenAddr, address _cLevelMultiSigAddr) {
        require(_tokenAddr != address(0), "zero addr");
        require(_cLevelMultiSigAddr != address(0), "zero addr");

        tokenAddr = _tokenAddr;
        cLevelMultiSigAddr = _cLevelMultiSigAddr;
    }

    /**
     * Create normal vesting contract
     * @param _vestingOwner address of the owner of the vesting contract
     * @param _startTS timestamp when vesting starts (regular vesting contract)
     * @param _endTS timestamp, defines end of the linear vesting schedule
     * @param _amount total amount in the vesting contract
     */
    function createVestingContract(
        address _vestingOwner,
        uint64 _startTS,
        uint64 _endTS,
        uint256 _amount
    ) external {
        require(ownerToVesting[_vestingOwner] == address(0), "already has vesting");
        Vesting vest = new Vesting(
            address(this),
            _vestingOwner,
            tokenAddr,
            _startTS,
            _endTS,
            _amount
        );
        ownerToVesting[_vestingOwner] = address(vest);
        IERC20Upgradeable(tokenAddr).safeTransferFrom(msg.sender, address(vest), _amount);
        emit VestingContractCreated(
            address(vest),
            _vestingOwner,
            0,
            _startTS,
            _endTS,
            _amount,
            "vesting"
        );
    }

    /**
     * Create Clvl vesting contract
     * @param _vestingOwner address of the owner of the vesting contract
     * @param _genesisTS timestamp when ownership starts
     * @param _startTS timestamp when vesting starts
     * @param _endTS timestamp, defines end of the linear vesting and ownership schedule
     * @param _amount total amount in the vesting contract
     */
    function createCLvlVestingContract(
        address _vestingOwner,
        uint64 _genesisTS,
        uint64 _startTS,
        uint64 _endTS,
        uint256 _amount
    ) external {
        require(ownerToVesting[_vestingOwner] == address(0), "already has vesting");
        Vesting vest = new VestingCLvl(
            address(this),
            _vestingOwner,
            tokenAddr,
            _genesisTS,
            _startTS,
            _endTS,
            _amount
        );
        ownerToVesting[_vestingOwner] = address(vest);
        IERC20Upgradeable(tokenAddr).safeTransferFrom(msg.sender, address(vest), _amount);
        emit VestingContractCreated(
            address(vest),
            _vestingOwner,
            _genesisTS,
            _startTS,
            _endTS,
            _amount,
            "c-vesting"
        );
    }

    /**
     * Create investor vesting contract
     * @param _vestingOwner address of the owner of the vesting contract
     * @param _startTS timestamp when vesting starts
     * @param _endTS timestamp, defines end of the linear vesting and ownership schedule
     * @param _amount total amount in the vesting contract
     */
    function createInvestorVestingContract(
        address _vestingOwner,
        uint64 _startTS,
        uint64 _endTS,
        uint256 _amount
    ) external {
        require(ownerToVesting[_vestingOwner] == address(0), "already has vesting");
        Vesting vest = new VestingInvestor(
            address(this),
            _vestingOwner,
            tokenAddr,
            _startTS,
            _endTS,
            _amount
        );
        ownerToVesting[_vestingOwner] = address(vest);
        IERC20Upgradeable(tokenAddr).safeTransferFrom(msg.sender, address(vest), _amount);
        emit VestingContractCreated(
            address(vest),
            _vestingOwner,
            0,
            _startTS,
            _endTS,
            _amount,
            "investor"
        );
    }

    /**
     * C-Level multisig can replace its address
     * @param _newMultiSig  address of the new multisig-wallet
     */
    function replaceMultiSig(address _newMultiSig) external {
        require(_newMultiSig != address(0), "zero addr");
        require(msg.sender == cLevelMultiSigAddr, "only CLvl");
        cLevelMultiSigAddr = _newMultiSig;
    }

    /**
     * C-Level multisig can end vestings.
     * Remaining funds are sent to multisig.
     * @param _owner address of the vesting contract owner
     */
    function endVesting(address _owner) external {
        require(msg.sender == cLevelMultiSigAddr, "only CLvl");
        address vestingAddr = ownerToVesting[_owner];
        require(vestingAddr != address(0), "vesting not managed");
        // the owner still has access to the vesting contract
        // but not the factory. With this action, we ensure
        // the vesting contract can be ended only once (owner keeps vested funds)
        delete ownerToVesting[_owner];
        // actually end the vesting
        Vesting(vestingAddr).endVesting(cLevelMultiSigAddr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Vesting } from "contracts/vesting/Vesting.sol";

contract VestingInvestor is Vesting {
    /**
     * Constructor
     * @param _factory address of the vesting factory
     * @param _ownerAddr address of the owner of the vesting contract
     * @param  _tokenAddr address of the governance token
     * @param _startTS timestamp when vesting starts
     * @param _endTS timestamp, defines end of the linear vesting and ownership
     * schedule
     * @param _amount total amount in the vesting contract
     */
    constructor(
        address _factory,
        address _ownerAddr,
        address _tokenAddr,
        uint64 _startTS,
        uint64 _endTS,
        uint256 _amount
    ) Vesting(_factory, _ownerAddr, _tokenAddr, _startTS, _endTS, _amount) {}

    /**
     * Investor's vesting contracts cannot be ended
     * So this function overrides the parent to do nothing instead.
     */
    function endVesting(address _recipient) external override {}
}