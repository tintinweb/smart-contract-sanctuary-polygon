// Based on https://eips.ethereum.org/EIPS/eip-4337

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IEntryPoint, IEntryPointStakeController} from "./interface/IEntryPoint.sol";
import {Stake} from "./library/Stake.sol";
import {UserOperation} from "./library/UserOperation.sol";
import {EntryPointUserOperation} from "./library/EntryPointUserOperation.sol";

contract EntryPoint is IEntryPoint, IEntryPointStakeController {
  using EntryPointUserOperation for UserOperation;

  address public immutable create2Factory;
  mapping(address => Stake) internal _paymasterStakes;

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  constructor(address _create2Factory) {
    create2Factory = _create2Factory;
  }

  function handleOps(UserOperation[] calldata ops, address payable redeemer)
    external
  {
    uint256 totalGasCost;
    uint256[] memory verificationGas = new uint256[](ops.length);
    bytes[] memory contexts = new bytes[](ops.length);

    // Verification loop
    for (uint256 i = 0; i < ops.length; i++) {
      verificationGas[i] = gasleft();

      if (ops[i].shouldCreateWallet()) {
        ops[i].deployWallet(create2Factory);
      }

      if (ops[i].hasPaymaster()) {
        _paymasterStakes[ops[i].paymaster].value = ops[i].verifyPaymasterStake(
          _paymasterStakes[ops[i].paymaster]
        );
        contexts[i] = ops[i].validatePaymasterUserOp();
      }

      ops[i].validateUserOp();

      verificationGas[i] = verificationGas[i] - gasleft();
    }

    // Execution loop
    for (uint256 i = 0; i < ops.length; i++) {
      uint256 preExecutionGas = gasleft();

      ops[i].execute();

      uint256 actualGas = verificationGas[i] + (preExecutionGas - gasleft());
      totalGasCost += ops[i].gasCost(actualGas);

      if (ops[i].hasPaymaster()) {
        ops[i].paymasterPostOp(contexts[i], ops[i].gasCost(actualGas));
        _paymasterStakes[ops[i].paymaster].value = ops[i]
          .finalizePaymasterStake(
            _paymasterStakes[ops[i].paymaster],
            ops[i].gasCost(actualGas)
          );
      } else {
        ops[i].refundUnusedGas(ops[i].gasCost(actualGas));
      }
    }

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = redeemer.call{value: totalGasCost}("");
    require(success, "EntryPoint: Failed to redeem");
  }

  function addStake() external payable {
    _paymasterStakes[msg.sender].value += msg.value;
  }

  function lockStake() external {
    // solhint-disable-next-line not-rely-on-time
    _paymasterStakes[msg.sender].lockExpiryTime = block.timestamp + 2 days;
    _paymasterStakes[msg.sender].isLocked = true;
  }

  function unlockStake() external {
    require(
      // solhint-disable-next-line not-rely-on-time
      _paymasterStakes[msg.sender].lockExpiryTime <= block.timestamp,
      "EntryPoint: Lock not expired"
    );

    _paymasterStakes[msg.sender].lockExpiryTime = 0;
    _paymasterStakes[msg.sender].isLocked = false;
  }

  function withdrawStake(address payable withdrawAddress) external {
    require(
      !_paymasterStakes[msg.sender].isLocked,
      "EntryPoint: Stake is locked"
    );

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = withdrawAddress.call{
      value: _paymasterStakes[msg.sender].value
    }("");

    if (success) {
      _paymasterStakes[msg.sender].value = 0;
    }
  }

  function getStake(address paymaster)
    external
    view
    returns (
      uint256 value,
      uint256 lockExpiryTime,
      bool isLocked
    )
  {
    return (
      _paymasterStakes[paymaster].value,
      _paymasterStakes[paymaster].lockExpiryTime,
      _paymasterStakes[paymaster].isLocked
    );
  }
}

// Based on https://eips.ethereum.org/EIPS/eip-4337

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {UserOperation} from "../library/UserOperation.sol";

interface IEntryPoint {
  function handleOps(UserOperation[] calldata ops, address payable redeemer)
    external;

  // function simulateWalletValidation(UserOperation calldata userOp)
  //   external
  //   returns (uint256 gasUsedByPayForSelfOp);

  // function simulatePaymasterValidation(
  //   UserOperation calldata userOp,
  //   uint256 gasUsedByPayForSelfOp
  // ) external view returns (bytes memory context, uint256 gasUsedByPayForOp);
}

interface IEntryPointStakeController {
  function addStake() external payable;

  function lockStake() external;

  function unlockStake() external;

  function withdrawStake(address payable withdrawAddress) external;
}

// Based on https://eips.ethereum.org/EIPS/eip-4337

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

struct Stake {
  uint256 value;
  uint256 lockExpiryTime;
  bool isLocked;
}

// Based on https://eips.ethereum.org/EIPS/eip-4337

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

struct UserOperation {
  address sender;
  uint256 nonce;
  bytes initCode;
  bytes callData;
  uint256 callGas;
  uint256 verificationGas;
  uint256 preVerificationGas;
  uint256 maxFeePerGas;
  uint256 maxPriorityFeePerGas;
  address paymaster;
  bytes paymasterData;
  bytes signature;
}

// Based on https://eips.ethereum.org/EIPS/eip-4337

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../ERC2470/ISingletonFactory.sol";
import {IWallet} from "../interface/IWallet.sol";
import {IPaymaster, PostOpMode} from "../interface/IPaymaster.sol";
import {UserOperation} from "./UserOperation.sol";
import {Stake} from "./Stake.sol";

library EntryPointUserOperation {
  function _gasPrice(UserOperation calldata op)
    internal
    view
    returns (uint256)
  {
    // For blockchains that don't support EIP-1559 transactions.
    // Avoids calling the BASEFEE opcode.
    return
      op.maxFeePerGas == op.maxPriorityFeePerGas
        ? op.maxFeePerGas
        : Math.min(op.maxFeePerGas, op.maxPriorityFeePerGas + block.basefee);
  }

  function _requiredPrefund(UserOperation calldata op)
    internal
    view
    returns (uint256)
  {
    uint256 totalGas = op.callGas + op.verificationGas + op.preVerificationGas;

    return totalGas * _gasPrice(op);
  }

  function _hash(UserOperation calldata op) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          op.sender,
          op.nonce,
          keccak256(op.initCode),
          keccak256(op.callData),
          op.callGas,
          op.verificationGas,
          op.preVerificationGas,
          op.maxFeePerGas,
          op.maxPriorityFeePerGas,
          op.paymaster,
          keccak256(op.paymasterData)
        )
      );
  }

  function _getRequestId(UserOperation calldata op)
    internal
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(_hash(op), address(this), block.chainid));
  }

  function gasCost(UserOperation calldata op, uint256 gas)
    internal
    view
    returns (uint256)
  {
    return gas * _gasPrice(op);
  }

  function shouldCreateWallet(UserOperation calldata op)
    internal
    view
    returns (bool)
  {
    if (!Address.isContract(op.sender) && op.initCode.length == 0) {
      revert("EntryPoint: No wallet & initCode");
    }

    return !Address.isContract(op.sender) && op.initCode.length != 0;
  }

  function hasPaymaster(UserOperation calldata op)
    internal
    pure
    returns (bool)
  {
    return op.paymaster != address(0);
  }

  function verifyPaymasterStake(UserOperation calldata op, Stake memory stake)
    internal
    view
    returns (uint256)
  {
    require(stake.isLocked, "EntryPoint: Stake not locked");
    require(
      stake.value >= _requiredPrefund(op),
      "EntryPoint: Insufficient stake"
    );

    return stake.value - _requiredPrefund(op);
  }

  function finalizePaymasterStake(
    UserOperation calldata op,
    Stake memory stake,
    uint256 actualGasCost
  ) internal view returns (uint256) {
    return stake.value + _requiredPrefund(op) - actualGasCost;
  }

  function validatePaymasterUserOp(UserOperation calldata op)
    internal
    view
    returns (bytes memory)
  {
    return
      IPaymaster(op.paymaster).validatePaymasterUserOp(
        op,
        _requiredPrefund(op)
      );
  }

  function paymasterPostOp(
    UserOperation calldata op,
    bytes memory context,
    uint256 actualGasCost
  ) internal {
    IPaymaster(op.paymaster).postOp(
      PostOpMode.opSucceeded,
      context,
      actualGasCost
    );
  }

  function deployWallet(UserOperation calldata op, address create2Factory)
    internal
  {
    ISingletonFactory(create2Factory).deploy(op.initCode, bytes32(op.nonce));
  }

  function validateUserOp(UserOperation calldata op) internal {
    uint256 requiredPrefund = hasPaymaster(op) ? 0 : _requiredPrefund(op);
    uint256 initBalance = address(this).balance;
    IWallet(op.sender).validateUserOp{gas: op.verificationGas}(
      op,
      _getRequestId(op),
      requiredPrefund
    );

    uint256 actualPrefund = address(this).balance - initBalance;
    if (actualPrefund < requiredPrefund) {
      revert("EntryPoint: incorrect prefund");
    }
  }

  function execute(UserOperation calldata op) internal {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory result) = op.sender.call{gas: op.callGas}(
      op.callData
    );

    if (!success) {
      // solhint-disable-next-line reason-string
      if (result.length < 68) revert();
      // solhint-disable-next-line no-inline-assembly
      assembly {
        result := add(result, 0x04)
      }
      revert(abi.decode(result, (string)));
    }
  }

  function refundUnusedGas(UserOperation calldata op, uint256 actualGasCost)
    internal
  {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = op.sender.call{
      value: _requiredPrefund(op) - actualGasCost
    }("");
    require(success, "EntryPoint: Failed to refund");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// Based on https://eips.ethereum.org/EIPS/eip-2470

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title Singleton Factory (EIP-2470)
 * @notice Exposes CREATE2 (EIP-1014) to deploy bytecode on deterministic addresses based on initialization code and salt.
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
interface ISingletonFactory {
  /**
   * @notice Deploys `_initCode` using `_salt` for defining the deterministic address.
   * @param _initCode Initialization code.
   * @param _salt Arbitrary value to modify resulting address.
   * @return createdContract Created contract address.
   */
  function deploy(bytes memory _initCode, bytes32 _salt)
    external
    returns (address payable createdContract);
}

// Based on https://eips.ethereum.org/EIPS/eip-4337

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {UserOperation} from "../library/UserOperation.sol";

interface IWallet {
  function validateUserOp(
    UserOperation calldata userOp,
    bytes32 requestId,
    uint256 requiredPrefund
  ) external;
}

// Based on https://eips.ethereum.org/EIPS/eip-4337

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {UserOperation} from "../library/UserOperation.sol";

enum PostOpMode {
  opSucceeded, // user op succeeded
  opReverted, // user op reverted. still has to pay for gas.
  postOpReverted // user op succeeded, but caused postOp to revert
}

interface IPaymaster {
  function validatePaymasterUserOp(
    UserOperation calldata userOp,
    uint256 maxcost
  ) external view returns (bytes memory context);

  function postOp(
    PostOpMode mode,
    bytes calldata context,
    uint256 actualGasCost
  ) external;
}