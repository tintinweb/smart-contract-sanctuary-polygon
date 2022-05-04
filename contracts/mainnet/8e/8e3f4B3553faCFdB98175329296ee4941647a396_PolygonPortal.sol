// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract ERC721Receiver is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return ERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IFxMessageProcessor.sol";

/// @title Base contract which directly receives state sync updates from FX_CHILD
abstract contract FxMessageProcessor is IFxMessageProcessor {
    /// @notice Contract that actually gets state sync messages via `onStateReceive`
    /// @dev see https://github.com/maticnetwork/pos-portal
    /// @dev verify at https://static.matic.network/network/mainnet/v1/index.json
    /// @return fxChild The address of fxChild on Polygon
    address public fxChild;

    /// @return address of the sending contract on ethereum
    address public ethereumPortal;

    /// @inheritdoc IFxMessageProcessor
    uint256 public lastStateId;

    /// @inheritdoc IFxMessageProcessor
    function processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes calldata data
    ) external override {
        // @dev ensure that only fxChild is allowed to execute this function (i.e. only FX_CHILD
        // is allowed to sync state messages from ethereum). This is because only the stateReceiver
        // is allowed to execute fxChild
        require(msg.sender == fxChild, "FxBaseChildTunnel: msg.sender != FX_CHILD");

        /// @dev since anyone can theoretically call FX_ROOT on ethereum and send arbitrary state sync messages
        /// to arbitrary receipients on polygon, we must ensure that the sender who initiated the state sync
        /// call to FX_ROOT is only who we allow - in this case, that is our counterpart contract on ethereum
        require(sender == ethereumPortal, "FxBaseChildTunnel: sender != ethereumPortal");
        lastStateId = stateId;
        _processRequest(data);
    }

    /// @dev see PolygonPortal.sol for implementation details
    function _processRequest(bytes calldata data) internal virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev see https://github.com/fx-portal/contracts
/// @title IFxMessageProcessor represents interface to process messages sent from Ethereum
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes calldata data
    ) external;

    /// @notice Returns the stateId of the last round of state sync that was executed on this contract
    /// @return stateId of the last state sync round for this contract
    function lastStateId() external returns (uint256 stateId);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @title Main contract which serves as the entry point on Polygon
interface IPolygonPortal {
    struct Call {
        address target;
        bytes callData;
    }

    function swapERC20AndCall(
        address tokenIn,
        uint256 amountIn,
        address user,
        address router,
        bytes memory routerArguments,
        bytes memory callBytes
    ) external;

    function swapNativeAndCall(
        address router,
        bytes calldata routerArguments,
        bytes memory callBytes
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPolygonPortal.sol";
import "./FxMessageProcessor.sol";
import "./ERC721Receiver.sol";

// solhint-disable avoid-low-level-calls
contract PolygonPortal is IPolygonPortal, Initializable, ERC721Receiver, FxMessageProcessor {
    uint256 public fee;
    address public beneficiary;

    function initialize(
        address _ethereumPortal,
        address _beneficiary,
        address _fxChild,
        uint256 _fee
    ) external initializer {
        ethereumPortal = _ethereumPortal;
        beneficiary = _beneficiary;
        fxChild = _fxChild;
        fee = _fee;
    }

    receive() external payable {}

    function _processRequest(bytes calldata rawRequestData) internal override {
        (
            address tokenIn, // input token
            uint256 amountIn, // input token amount
            address user,
            address router, // swap contract address
            bytes memory routerArguments, // swap contract arguments
            bytes memory callBytes // call list
        ) = abi.decode(rawRequestData, (address, uint256, address, address, bytes, bytes));
        try
            this.swapERC20AndCall(tokenIn, amountIn, user, router, routerArguments, callBytes)
        {} catch {
            require(IERC20(tokenIn).transfer(user, amountIn), "refund failed");
        }
    }

    function swapNativeAndCall(
        address router,
        bytes calldata args,
        bytes memory callBytes
    ) external payable {
        uint256 initialBalance = address(this).balance;

        if (router != address(0)) {

        (uint256 brydgeFee, uint256 postFeeAmountIn) = _calculateFee(msg.value);
        (bool successfulFeePayment, ) = beneficiary.call{value: brydgeFee}("");
        require(successfulFeePayment, "Brydge fee payment failed");

        (bool successfulSwap, ) = router.call{value: postFeeAmountIn}(args);
        require(successfulSwap, "swap failed");

        uint256 swapCost = initialBalance - address(this).balance;
        uint256 overpayment = msg.value - swapCost;

        (bool successfulReimbursement, ) = msg.sender.call{value: overpayment}("");
        require(successfulReimbursement, "reimbursement failed");
        }

        _handleCalls(callBytes);
    }

    function swapERC20AndCall(
        address tokenIn,
        uint256 amountIn,
        address user,
        address router,
        bytes memory args,
        bytes memory callBytes
    ) external {
        if (msg.sender == user) {
            require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "funds transfer failed");
        } else if (msg.sender != address(this)) {
            revert("invalid user address");
        }
        if (router != address(0)) {
            _swapERC20(tokenIn, amountIn, user, router, args);
        }
        _handleCalls(callBytes);
    }

    function _handleCalls(bytes memory callBytes) internal {
        Call[] memory calls = abi.decode(callBytes, (Call[]));
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = calls[i].target.call(calls[i].callData);
            require(success, "NFT transfer failed");
        }
    }

    function _swapERC20(
        address tokenIn,
        uint256 amountIn,
        address user,
        address router,
        bytes memory args
    ) internal {
        IERC20 token = IERC20(tokenIn);
        uint256 initialBalance = token.balanceOf(address(this));

        (uint256 brydgeFee, uint256 postFeeAmountIn) = _calculateFee(amountIn);
        require(token.transfer(beneficiary, brydgeFee), "Brydge fee payment failed");

        _handleERC20Approval(tokenIn, router, postFeeAmountIn);
        (bool successfulSwap, ) = router.call(args);
        require(successfulSwap, "swap failed");

        uint256 swapCost = initialBalance - token.balanceOf(address(this));
        uint256 overPayment = amountIn - swapCost;
        require(token.transfer(user, overPayment), "reimbursement failed");
    }

    function _handleERC20Approval(
        address token,
        address operator,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), operator) < amount) {
            IERC20(token).approve(
                operator,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        }
    }

    function _calculateFee(uint256 amountIn) internal view returns (uint256, uint256) {
        uint256 brydgeFee = mulDiv(amountIn, fee, 1000);
        uint256 postFeeAmountIn = amountIn - brydgeFee;
        return (brydgeFee, postFeeAmountIn);
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        uint256 a = x / z;
        uint256 b = x % z; // x = a * z + b
        uint256 c = y / z;
        uint256 d = y % z; // y = c * z + d
        return a * c * z + a * d + b * c + (b * d) / z;
    }
}