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

pragma solidity 0.8.17;

import "../wallet/Utils.sol";

/**
 * @title Singleton Factory (EIP-2470)
 * @dev Extended version from EIP-2470 for testing purposes
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract SingletonFactory {
    address public owner;

    /* solhint-disable */
    error InvalidSignature();
    error InitializeFailed();
    /* solhint-enable */

    event Deployed(address createdContract, bytes32 salt);

    constructor(address factoryOwner) {
        owner = factoryOwner;
    }

    function deploy(bytes memory initCode) public returns (address payable createdContract) {
        (
            bytes32 salt,
            bytes memory deployCode,
            address entryPoint,
            address walletOwner,
            address guardian,
            bytes memory signature
        ) = abi.decode(initCode, (bytes32, bytes, address, address, address, bytes));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            createdContract := create2(0, add(deployCode, 0x20), mload(deployCode), salt)
            if iszero(extcodesize(createdContract)) {
                revert(0, 0)
            }
        }

        bytes32 initCodeHash = keccak256(abi.encode(block.chainid, createdContract, entryPoint, walletOwner, guardian));
        bytes32 signedHash = Utils.toEthSignedMessageHash(initCodeHash);
        if (owner != Utils.recoverSigner(signedHash, signature, 0)) revert InvalidSignature();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = createdContract.call(
            abi.encodeWithSignature("initialize(address,address,address)", entryPoint, walletOwner, guardian)
        );

        if (!success) revert InitializeFailed();

        emit Deployed(createdContract, salt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Utils
 * @notice Common utility methods used by modules.
 */
library Utils {
    /* solhint-disable */

    error BadValueSignature();
    error EcrecoverReturnedZero();
    error InvalidFunctionPrefix();
    /* solhint-enable */

    bytes4 private constant OWNER_SIG = 0x8da5cb5b;

    /**
     * @notice Helper method to recover the signer at a given position from a list of concatenated signatures.
     * @param signedHash The signed hash
     * @param signatures The concatenated signatures.
     * @param index The index of the signature to recover.
     */
    function recoverSigner(
        bytes32 signedHash,
        bytes memory signatures,
        uint256 index
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signatures, add(0x20, mul(0x41, index))))
            s := mload(add(signatures, add(0x40, mul(0x41, index))))
            v := and(mload(add(signatures, add(0x41, mul(0x41, index)))), 0xff)
        }
        if (v != 27 && v != 28) {
            revert BadValueSignature();
        }

        address recoveredAddress = ecrecover(signedHash, v, r, s);
        if (recoveredAddress == address(0)) {
            revert EcrecoverReturnedZero();
        }
        return recoveredAddress;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @notice Helper method to parse data and extract the method signature.
     */
    function functionPrefix(bytes memory data) internal pure returns (bytes4 prefix) {
        if (data.length < 4) revert InvalidFunctionPrefix();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            prefix := mload(add(data, 0x20))
        }
    }

    /**
     * @notice Returns ceil(a / b).
     */
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if (a % b == 0) {
            return c;
        } else {
            return c + 1;
        }
    }

    /**
     * @notice Checks if an address is a guardian or an account authorised to sign on behalf of a smart-contract guardian
     * given a list of guardians.
     * @param guardians the list of guardians
     * @param signer the address to test
     * @return true and the list of guardians minus the found guardian upon success, false and the original list of guardians if not found.
     */
    function isGuardianOrGuardianSigner(address[] memory guardians, address signer)
        internal
        view
        returns (bool, address[] memory)
    {
        if (guardians.length == 0 || signer == address(0)) {
            return (false, guardians);
        }
        bool isFound = false;
        address[] memory updatedGuardians = new address[](guardians.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < guardians.length; i++) {
            if (!isFound) {
                // check if signer is an account guardian
                if (signer == guardians[i]) {
                    isFound = true;
                    continue;
                }
                // check if signer is the owner of a smart contract guardian
                if (Address.isContract(guardians[i]) && isGuardianOwner(guardians[i], signer)) {
                    isFound = true;
                    continue;
                }
            }
            if (index < updatedGuardians.length) {
                updatedGuardians[index] = guardians[i];
                index++;
            }
        }
        return isFound ? (true, updatedGuardians) : (false, guardians);
    }

    /**
     * @notice Checks if an address is the owner of a guardian contract.
     * The method does not revert if the call to the owner() method consumes more then 25000 gas.
     * @param guardian The guardian contract
     * @param guardianOwner_ The owner to verify.
     */
    function isGuardianOwner(address guardian, address guardianOwner_) internal view returns (bool) {
        address guardianOwner = address(0);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, OWNER_SIG)
            let result := staticcall(25000, guardian, ptr, 0x20, ptr, 0x20)
            if eq(result, 1) {
                guardianOwner := mload(ptr)
            }
        }
        return guardianOwner == guardianOwner_;
    }
}