// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../src/iSaddleStablePool.sol";
import "../src/iCurvePool.sol";
import "../src/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Arbitrageur's interface for arbitrage.
/// @author Coindex Capital
/// @dev Check readme for more details.
contract SwapArb {

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
    //                        ENUMS AND STRUCTS
    //////////////////////////////////////////////////////////////*/

    enum SwapPoolInterface {SADDLE, CURVE, UNISWAP}

    /// @dev Struct to hold params for Multihop arb function (mainly because of `too deep stack` issues).
    /// @param _initial_deposit: First trade amount.
    /// @param _amounts: Amounts of each token to be received.
    /// @param _pool_addresses: Array of the pools' addresses.
    /// @param _pool_interfaces: Array of the pools' interfaces.
    /// @param _tokens: Array of the tokens being traded.
    /// @param _token_idxs: Array of the tokens indexes in the pools.
    /// @param _max_block_limit: The maximum block number to be executed
    /// @param _min_amount_expected: The minimum amount of tokens expected to be received. This serves to prevent bad execution.
    struct MultiHopArb {
        uint256 _initial_deposit;
        uint256[] _amounts;
        address[] _pool_addresses;
        SwapPoolInterface[] _pool_interfaces;
        address[] _tokens;
        uint8[] _token_idxs;
        uint256 _max_block_limit;
        uint256 _min_amount_expected;
    }

    /*//////////////////////////////////////////////////////////////
    //                         STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public operator;
    mapping(address => bool) public isApproved;
    uint32 public numContractsApproved;

    /*//////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, address _operator) payable{
        if (_owner == address(0) || _operator == address(0)) {
            revert INVALID_ADDRESS(address(0));
        }
        owner = _owner;
        operator = _operator;
    }

    /*//////////////////////////////////////////////////////////////
    //                         EVENTS
    //////////////////////////////////////////////////////////////*/

    event ExecutedArbitrage(address poolAddress);
    event ExecutedMHArbitrage(address poolAddress, uint256 amount_init, uint256 amount_final);
    event BalanceWithdraw(address ercAddr, uint256 amount);

    /*//////////////////////////////////////////////////////////////
    //                         ERRORS
    //////////////////////////////////////////////////////////////*/

    error INVALID_ADDRESS(address addr);
    error NOT_AUTHORIZED(address _addr);
    error NOT_APPROVED_ADDRESS(address _addr);
    error TIMED_OUT(uint initialBlock, uint finalBlock);
    error MIN_LP_EXPECTED(uint256 expectedLPTokens, uint256 tokensReceived);
    error NOT_IMPLEMENTED();
    error INVALID_SIZES();
    error NOT_PROFITABLE();
    error FAIL_WITHDRAW(address ercAddr, uint256 amount);
    error MIN_AMOUNT_EXPECTED(uint256 expectedAmount, uint256 amountReceived);
    error CONTRACT_NOT_EMPTY(address ercAddr);

    /*//////////////////////////////////////////////////////////////
    //                         MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert NOT_AUTHORIZED(msg.sender);
        _;
    }

    modifier onlyOwnerOrOperator() {
        if (msg.sender != owner && msg.sender != operator) revert NOT_AUTHORIZED(msg.sender);
        _;
    }

    modifier onlyApprovedAddresses(address[] memory _addrs) {
        for (uint i = 0; i < _addrs.length; i++) {
            if (!isApproved[_addrs[i]]) {
                revert NOT_APPROVED_ADDRESS(_addrs[i]);
            }
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
    //                         VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getOwner() public view returns (address) {
        return owner;
    }

    /*//////////////////////////////////////////////////////////////
    //                         MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Approve addresses.
    /// @param _addresses: The addresses to be approved
    function approveAddresses(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            isApproved[_addresses[i]] = true;
            numContractsApproved++;
        }
    }

    /// @notice Blacklist addresses.
    /// @param _addresses: The addresses to be blacklisted
    function blacklistAddresses(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            isApproved[_addresses[i]] = false;
        }
    }

    /// @notice Executes the arbitrage trade
    /// @param _amounts: Amounts of each token to be deposited.
    /// @param _pool_address: The pool's address.
    /// @param _pool_interface: The pool's interface.
    /// @param _lp_token_address: The pool's LP token address (should be ERC20 compliant).
    /// @param _max_block_limit: The minimum block number to be executed
    /// @param _min_lp_token_expected: The minimum amount of LP tokens expected to be received. This serves to prevent bad/late execution.
    function executeArbitrage(
        uint256[] memory _amounts,
        address _pool_address,
        SwapPoolInterface _pool_interface,
        address _lp_token_address,
        address[] memory _tokens,
        uint256 _max_block_limit,
        uint256 _min_lp_token_expected) external onlyOwnerOrOperator
    {
        // Check if pool and lp_token is valid
        if (_pool_address == address(0)) revert INVALID_ADDRESS(_pool_address);
        if (_lp_token_address == address(0)) revert INVALID_ADDRESS(_lp_token_address);
        if (_tokens.length != _amounts.length) revert INVALID_SIZES();

        // Check if current block is less than _max_block_limit
        if (block.number > _max_block_limit) revert TIMED_OUT(_max_block_limit, block.number);

        // Approve tokens to pool
        for (uint i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            if (_amounts[i] > 0) {
                token.safeApprove(_pool_address, _amounts[i]);
            }
        }

        if (_pool_interface == SwapPoolInterface.SADDLE) {
            iSaddleStablePool poolContract = iSaddleStablePool(_pool_address);

            uint256 new_lp = poolContract.addLiquidity(_amounts, 0, block.timestamp + 5);

            // Check if _min_lp_token_expected is greater or equal than the amount of LP tokens received
            if (new_lp < _min_lp_token_expected) revert MIN_LP_EXPECTED(_min_lp_token_expected, new_lp);

            // Execute Arbitrage
            IERC20 lp_token = IERC20(_lp_token_address);
            lp_token.safeApprove(_pool_address, new_lp);
            uint256[] memory min_amounts = new uint256[](_tokens.length);
            poolContract.removeLiquidity(new_lp, min_amounts, block.timestamp + 5);

        } else if (_pool_interface == SwapPoolInterface.CURVE) {
            iCurvePool poolContract = iCurvePool(_pool_address);

            uint256 new_lp = poolContract.add_liquidity(_amounts, 0);

            // Check if _min_lp_token_expected is greater or equal than the amount of LP tokens received
            if (new_lp < _min_lp_token_expected) revert MIN_LP_EXPECTED(_min_lp_token_expected, new_lp);

            // Execute Arbitrage
            IERC20 lp_token = IERC20(_lp_token_address);
            lp_token.safeApprove(_pool_address, new_lp);
            uint256[] memory min_amounts = new uint256[](_tokens.length);
            poolContract.remove_liquidity(new_lp, min_amounts);
        } else {
            revert NOT_IMPLEMENTED();
        }

        // Emit event
        emit ExecutedArbitrage(_pool_address);
    }

    /// @notice Executes the multi-hop arbitrage trade.
    /// @notice Important that the trade must end in the same token that it started! (i.e. if you start with USDC, you must end with USDC)
    /// @param _arb: Multihop Arb Params
    function executeMultiHopArb(MultiHopArb calldata _arb) external
    onlyOwnerOrOperator
    onlyApprovedAddresses(_arb._tokens)
    onlyApprovedAddresses(_arb._pool_addresses)
    {
        // Sanity checks
        if (_arb._pool_addresses.length < 2) revert INVALID_SIZES();
        if (_arb._pool_addresses.length != _arb._pool_interfaces.length) revert INVALID_SIZES();
        if (_arb._pool_addresses.length != _arb._amounts.length) revert INVALID_SIZES();
        if (_arb._pool_addresses.length != _arb._tokens.length) revert INVALID_SIZES();
        if (_arb._pool_addresses.length != _arb._token_idxs.length) revert INVALID_SIZES();

        // Check if current block is less than _max_block_limit
        if (block.number > _arb._max_block_limit) revert TIMED_OUT(_arb._max_block_limit, block.number);

        address contract_address = address(this);
        uint256 initial_amount = IERC20(_arb._tokens[0]).balanceOf(contract_address);

        // Loop through all pools trading designated tokens
        for (uint i = 0; i < _arb._pool_addresses.length; i++) {
            // Swap initial amount
            if (_arb._pool_interfaces[i] == SwapPoolInterface.UNISWAP) {
                address p_address = _arb._pool_addresses[i];
                IUniswapV2Pair pool = IUniswapV2Pair(p_address);

                if (i == 0) {
                    // if first, send _initial_deposit
                    IERC20(_arb._tokens[i]).safeTransfer(p_address, _arb._initial_deposit);
                } else {
                    // for others hops, send the amount received from the previous pool swap
                    IERC20(_arb._tokens[i]).safeTransfer(p_address, _arb._amounts[i - 1]);
                }

                // Swap
                // TODO: Possible to implement flash swap in the future
                if (_arb._token_idxs[i] == 0) {
                    pool.swap(0, _arb._amounts[i], contract_address, new bytes(0));
                } else {
                    pool.swap(_arb._amounts[i], 0, contract_address, new bytes(0));
                }
            } else {
                // TODO: Implement other pools
                revert NOT_IMPLEMENTED();
            }
        }

        uint256 final_amount = IERC20(_arb._tokens[0]).balanceOf(address(this));

        // Trade correctness checks
        if (final_amount < _arb._min_amount_expected) revert MIN_AMOUNT_EXPECTED(_arb._min_amount_expected, final_amount);
        if (final_amount < initial_amount) revert NOT_PROFITABLE();

        emit ExecutedMHArbitrage(_arb._pool_addresses[0], initial_amount, final_amount);
    }


    /// @notice Destroy current contract and return resources to owner.
    /// @dev [WARNING] We do not include a check for erc20 balances here, this check should be done by the owner before calling this function.
    function self_destroy() external onlyOwner
    {
        selfdestruct(payable(owner));
    }

    /// @notice Withdraws ERC20 token from the contract to owner.
    /// @param _token_address: The token's address.
    function withdrawToken(address _token_address) public onlyOwner
    {
        IERC20 token = IERC20(_token_address);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(owner, balance);
        emit BalanceWithdraw(_token_address, balance);
    }

    /// @notice Withdraws ERC20 tokens from the contract to owner in a single transaction.
    /// @param _token_addresses: The token's addresses.
    function withdrawBatch(address[] calldata _token_addresses) external onlyOwner {
        for (uint i = 0; i < _token_addresses.length; i++) {
            withdrawToken(_token_addresses[i]);
        }
    }

    /// @notice Payable function to receive native blockchain tokens (e.g. ETH, MATIC, etc).
    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: BSD-2-Clause
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface iCurvePool {
    event TokenExchange(
        address indexed buyer,
        uint256 sold_id,
        uint256 tokens_sold,
        uint256 bought_id,
        uint256 tokens_bought
    );
    event AddLiquidity(
        address indexed provider,
        uint256[3] token_amounts,
        uint256 fee,
        uint256 token_supply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[3] token_amounts,
        uint256 token_supply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 token_amount,
        uint256 coin_index,
        uint256 coin_amount
    );
    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);
    event NewAdmin(address indexed admin);
    event CommitNewParameters(
        uint256 indexed deadline,
        uint256 admin_fee,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 fee_gamma,
        uint256 allowed_extra_profit,
        uint256 adjustment_step,
        uint256 ma_half_time
    );
    event NewParameters(
        uint256 admin_fee,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 fee_gamma,
        uint256 allowed_extra_profit,
        uint256 adjustment_step,
        uint256 ma_half_time
    );
    event RampAgamma(
        uint256 initial_A,
        uint256 future_A,
        uint256 initial_gamma,
        uint256 future_gamma,
        uint256 initial_time,
        uint256 future_time
    );
    event StopRampA(uint256 current_A, uint256 current_gamma, uint256 time);
    event ClaimAdminFee(address indexed admin, uint256 tokens);


    function balanceOf(address i) external view returns (uint256);

    function price_oracle(uint256 k) external view returns (uint256);

    function price_scale(uint256 k) external view returns (uint256);

    function last_prices(uint256 k) external view returns (uint256);

    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function A() external view returns (uint256);

    function gamma() external view returns (uint256);

    function fee() external view returns (uint256);

    function fee_calc(uint256[3] memory xp) external view returns (uint256);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_fee(uint256[3] memory amounts, uint256[3] memory xp)
    external
    view
    returns (uint256);

    function add_liquidity(uint256[] memory amounts, uint256 min_mint_amount)
    external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[] memory min_amounts)
    external returns (uint256[] memory);

    function calc_token_amount(uint256[] memory amounts, bool deposit)
    external
    view
    returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i)
    external
    view
    returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function claim_admin_fees() external;

    function ramp_A_gamma(
        uint256 future_A,
        uint256 future_gamma,
        uint256 future_time
    ) external;

    function stop_ramp_A_gamma() external;

    function commit_new_parameters(
        uint256 _new_mid_fee,
        uint256 _new_out_fee,
        uint256 _new_admin_fee,
        uint256 _new_fee_gamma,
        uint256 _new_allowed_extra_profit,
        uint256 _new_adjustment_step,
        uint256 _new_ma_half_time
    ) external;

    function apply_new_parameters() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function kill_me() external;

    function unkill_me() external;

    function set_reward_receiver(address _reward_receiver) external;

    function set_admin_fee_receiver(address _admin_fee_receiver) external;

    function last_prices_timestamp() external view returns (uint256);

    function initial_A_gamma() external view returns (uint256);

    function future_A_gamma() external view returns (uint256);

    function initial_A_gamma_time() external view returns (uint256);

    function future_A_gamma_time() external view returns (uint256);

    function allowed_extra_profit() external view returns (uint256);

    function future_allowed_extra_profit() external view returns (uint256);

    function fee_gamma() external view returns (uint256);

    function future_fee_gamma() external view returns (uint256);

    function adjustment_step() external view returns (uint256);

    function future_adjustment_step() external view returns (uint256);

    function ma_half_time() external view returns (uint256);

    function future_ma_half_time() external view returns (uint256);

    function mid_fee() external view returns (uint256);

    function out_fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function future_mid_fee() external view returns (uint256);

    function future_out_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function D() external view returns (uint256);

    function owner() external view returns (address);

    function future_owner() external view returns (address);

    function xcp_profit() external view returns (uint256);

    function xcp_profit_a() external view returns (uint256);

    function virtual_price() external view returns (uint256);

    function is_killed() external view returns (bool);

    function kill_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function reward_receiver() external view returns (address);

    function admin_fee_receiver() external view returns (address);

    function lp_token() external view returns (address);

    function totalSupply() external view returns (uint);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"name":"TokenExchange","inputs":[{"name":"buyer","type":"address","indexed":true},{"name":"sold_id","type":"uint256","indexed":false},{"name":"tokens_sold","type":"uint256","indexed":false},{"name":"bought_id","type":"uint256","indexed":false},{"name":"tokens_bought","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"AddLiquidity","inputs":[{"name":"provider","type":"address","indexed":true},{"name":"token_amounts","type":"uint256[3]","indexed":false},{"name":"fee","type":"uint256","indexed":false},{"name":"token_supply","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"RemoveLiquidity","inputs":[{"name":"provider","type":"address","indexed":true},{"name":"token_amounts","type":"uint256[3]","indexed":false},{"name":"token_supply","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"RemoveLiquidityOne","inputs":[{"name":"provider","type":"address","indexed":true},{"name":"token_amount","type":"uint256","indexed":false},{"name":"coin_index","type":"uint256","indexed":false},{"name":"coin_amount","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"CommitNewAdmin","inputs":[{"name":"deadline","type":"uint256","indexed":true},{"name":"admin","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"NewAdmin","inputs":[{"name":"admin","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"CommitNewParameters","inputs":[{"name":"deadline","type":"uint256","indexed":true},{"name":"admin_fee","type":"uint256","indexed":false},{"name":"mid_fee","type":"uint256","indexed":false},{"name":"out_fee","type":"uint256","indexed":false},{"name":"fee_gamma","type":"uint256","indexed":false},{"name":"allowed_extra_profit","type":"uint256","indexed":false},{"name":"adjustment_step","type":"uint256","indexed":false},{"name":"ma_half_time","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"NewParameters","inputs":[{"name":"admin_fee","type":"uint256","indexed":false},{"name":"mid_fee","type":"uint256","indexed":false},{"name":"out_fee","type":"uint256","indexed":false},{"name":"fee_gamma","type":"uint256","indexed":false},{"name":"allowed_extra_profit","type":"uint256","indexed":false},{"name":"adjustment_step","type":"uint256","indexed":false},{"name":"ma_half_time","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"RampAgamma","inputs":[{"name":"initial_A","type":"uint256","indexed":false},{"name":"future_A","type":"uint256","indexed":false},{"name":"initial_gamma","type":"uint256","indexed":false},{"name":"future_gamma","type":"uint256","indexed":false},{"name":"initial_time","type":"uint256","indexed":false},{"name":"future_time","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StopRampA","inputs":[{"name":"current_A","type":"uint256","indexed":false},{"name":"current_gamma","type":"uint256","indexed":false},{"name":"time","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"ClaimAdminFee","inputs":[{"name":"admin","type":"address","indexed":true},{"name":"tokens","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"stateMutability":"view","type":"function","name":"price_oracle","inputs":[{"name":"k","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"price_scale","inputs":[{"name":"k","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"last_prices","inputs":[{"name":"k","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"token","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"coins","inputs":[{"name":"i","type":"uint256"}],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"A","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"gamma","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"fee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"fee_calc","inputs":[{"name":"xp","type":"uint256[3]"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"get_virtual_price","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"exchange","inputs":[{"name":"i","type":"uint256"},{"name":"j","type":"uint256"},{"name":"dx","type":"uint256"},{"name":"min_dy","type":"uint256"}],"outputs":[]},{"stateMutability":"view","type":"function","name":"get_dy","inputs":[{"name":"i","type":"uint256"},{"name":"j","type":"uint256"},{"name":"dx","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"calc_token_fee","inputs":[{"name":"amounts","type":"uint256[3]"},{"name":"xp","type":"uint256[3]"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"add_liquidity","inputs":[{"name":"amounts","type":"uint256[3]"},{"name":"min_mint_amount","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"remove_liquidity","inputs":[{"name":"_amount","type":"uint256"},{"name":"min_amounts","type":"uint256[3]"}],"outputs":[]},{"stateMutability":"view","type":"function","name":"calc_token_amount","inputs":[{"name":"amounts","type":"uint256[3]"},{"name":"deposit","type":"bool"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"calc_withdraw_one_coin","inputs":[{"name":"token_amount","type":"uint256"},{"name":"i","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"remove_liquidity_one_coin","inputs":[{"name":"token_amount","type":"uint256"},{"name":"i","type":"uint256"},{"name":"min_amount","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"claim_admin_fees","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"ramp_A_gamma","inputs":[{"name":"future_A","type":"uint256"},{"name":"future_gamma","type":"uint256"},{"name":"future_time","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"stop_ramp_A_gamma","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"commit_new_parameters","inputs":[{"name":"_new_mid_fee","type":"uint256"},{"name":"_new_out_fee","type":"uint256"},{"name":"_new_admin_fee","type":"uint256"},{"name":"_new_fee_gamma","type":"uint256"},{"name":"_new_allowed_extra_profit","type":"uint256"},{"name":"_new_adjustment_step","type":"uint256"},{"name":"_new_ma_half_time","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"apply_new_parameters","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"revert_new_parameters","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"commit_transfer_ownership","inputs":[{"name":"_owner","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"apply_transfer_ownership","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"revert_transfer_ownership","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"kill_me","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"unkill_me","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"set_reward_receiver","inputs":[{"name":"_reward_receiver","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"set_admin_fee_receiver","inputs":[{"name":"_admin_fee_receiver","type":"address"}],"outputs":[]},{"stateMutability":"view","type":"function","name":"last_prices_timestamp","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"initial_A_gamma","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_A_gamma","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"initial_A_gamma_time","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_A_gamma_time","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"allowed_extra_profit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_allowed_extra_profit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"fee_gamma","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_fee_gamma","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"adjustment_step","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_adjustment_step","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"ma_half_time","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_ma_half_time","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"mid_fee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"out_fee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"admin_fee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_mid_fee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_out_fee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"future_admin_fee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"balances","inputs":[{"name":"arg0","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"D","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"owner","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"future_owner","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"xcp_profit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"xcp_profit_a","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"virtual_price","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"is_killed","inputs":[],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"view","type":"function","name":"kill_deadline","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"transfer_ownership_deadline","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"admin_actions_deadline","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"reward_receiver","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"admin_fee_receiver","inputs":[],"outputs":[{"name":"","type":"address"}]}]
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "solmate/tokens/ERC20.sol";
//import "./IAllowlist.sol";

interface iSaddleStablePool {
    // pool data view functions
    function getA() external view returns (uint256);

//    function getAllowlist() external view returns (IAllowlist);

    function getToken(uint8 index) external view returns (ERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function isGuarded() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
    external
    view
    returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
    external
    view
    returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initialize(
        ERC20[] memory pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 a,
        uint256 fee,
        uint256 adminFee,
        address lpTokenTargetAddress
    ) external;

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);
    event NewWithdrawFee(uint256 newWithdrawFee);
}