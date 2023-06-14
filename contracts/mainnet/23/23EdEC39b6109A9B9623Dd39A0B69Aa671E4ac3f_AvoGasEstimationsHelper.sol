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
pragma solidity >=0.8.17;

interface AvoCoreStructs {
    /// @notice a pair of a bytes signature and its signer.
    struct SignatureParams {
        ///
        /// @param signature signature, e.g. ECDSA signature for default flow
        bytes signature;
        ///
        /// @param signer signer of the signature, required for smart contract signatures
        address signer;
    }

    /// @notice an executable action, including operation (call or delegateCall), target, data and value
    struct Action {
        ///
        /// @param target the target to execute the actions on
        address target;
        ///
        /// @param data the data to be passed to the call for each target
        bytes data;
        ///
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        ///
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call)
        uint256 operation;
    }

    /// @notice common params for both `cast()` and `castAuthorized()`
    struct CastParams {
        Action[] actions;
        ///
        /// @param id             Required:
        ///                       id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall),
        ///                                           20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        ///
        /// @param avoSafeNonce   Required:
        ///                       avoSafeNonce to be used for this tx. Must equal the avoSafeNonce value on AvoSafe
        ///                       or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoSafeNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoSafeNonce` is set to -1)
        bytes32 salt;
        ///
        /// @param source         Optional:
        ///                       Source e.g. referral for this tx
        address source;
        ///
        /// @param metadata       Optional:
        ///                       metadata for future flexibility
        bytes metadata;
    }

    /// @notice `cast()` input params related to forwarding validity
    struct CastForwardParams {
        ///
        /// @param gas            Required:
        ///                       As EIP-2770: an amount of gas limit to set for the execution
        ///                       Protects against potential gas griefing attacks & ensures the relayer sends enough gas
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in
        ///                       or 0 if the request is not time-limited to occur after a certain time
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
    }

    /// @notice `castAuthorized()` input params
    struct CastAuthorizedParams {
        ///
        /// @param maxFee         Optional:
        ///                       the maximum fee allowed to be paid for tx execution
        uint256 maxFee;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be executed in
        ///                       or 0 if the request is not time-limited to occur after a certain time
        ///                       Protects against executing a certain transaction at  an earlier moment
        ///                       not intended when signed, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       is valid for, or 0 if request should be valid forever.
        ///                       Protects against executing a certain transaction at a later moment
        ///                       not intended when signed, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig
        uint256 validUntil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IAvoFactory } from "../interfaces/IAvoFactory.sol";
import { IAvoWalletV3 } from "../interfaces/IAvoWalletV3.sol";
import { IAvoMultisigV3 } from "../interfaces/IAvoMultisigV3.sol";

interface IAvoWalletWithCallTargets is IAvoWalletV3 {
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable;
}

interface IAvoMultisigWithCallTargets is IAvoMultisigV3 {
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable;
}

/// @title  AvoGasEstimationsHelper v3.0.0
/// @notice helps estimate gas costs for AvoWallet actions, especially when AvoWallet is not deployed yet.
///         ATTENTION: Only supports AvoWallet version > 2.0.0
contract AvoGasEstimationsHelper {
    using Address for address;

    error AvoGasEstimationsHelper__InvalidParams();

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice  AvoFactory that this contract uses to find or create AvoSafe deployments
    IAvoFactory public immutable avoFactory;

    /// @dev cached AvoSafe Bytecode to optimize gas usage.
    /// If this changes because of a AvoFactory (and AvoSafe change) upgrade,
    /// then this variable must be updated through an upgrade deploying a new AvoGasEstimationsHelper!
    bytes32 public immutable avoSafeBytecode;

    /// @dev cached AvoMultiSafe Bytecode to optimize gas usage.
    /// If this changes because of an AvoFactory (and AvoMultiSafe change) upgrade,
    /// then this variable must be updated through an upgrade deploying a new AvoGasEstimationsHelper!
    bytes32 public immutable avoMultiSafeBytecode;

    /// @notice constructor sets the immutable avoFactory address
    /// @param avoFactory_      address of AvoFactory
    constructor(IAvoFactory avoFactory_) {
        if (address(avoFactory_) == address(0)) {
            revert AvoGasEstimationsHelper__InvalidParams();
        }
        avoFactory = avoFactory_;

        // get AvoSafe & AvoSafeMultsig bytecode from factory.
        // @dev Note if a new AvoFactory is deployed (upgraded), a new AvoForwarder must be deployed
        // to update these bytecodes. See Readme for more info.
        avoSafeBytecode = avoFactory.avoSafeBytecode();
        avoMultiSafeBytecode = avoFactory.avoMultiSafeBytecode();
    }

    /// @notice estimate gas usage of actions_ via ._callTargets() on AvoWallet and deploying AvoSafe if necessary
    /// Can be used for versions > 2.0.0 (2.x.x and 3.x.x)
    /// Note this gas estimation will not include the gas consumed in `.cast()`
    /// @param owner_         AvoSafe owner
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param id_            id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @return totalGasUsed_           total amount of gas used
    /// @return deploymentGasUsed_      amount of gas used for deployment (or for getting the AvoWallet if already deployed)
    /// @return isAvoSafeDeployed_      boolean flag indicating if AvoSafe is already deployed (true) or if it must be deployed (false)
    /// @return success_                boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGas(
        address owner_,
        IAvoWalletV3.Action[] calldata actions_,
        uint256 id_
    )
        external
        payable
        returns (uint256 totalGasUsed_, uint256 deploymentGasUsed_, bool isAvoSafeDeployed_, bool success_)
    {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoWalletWithCallTargets avoWallet_;
        // _getDeployedAvoWallet automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoWallet_, isAvoSafeDeployed_) = _getDeployedAvoWallet(owner_, address(0));

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoWallet_).call{ value: msg.value }(
            abi.encodeCall(avoWallet_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /// @notice estimate gas usage of actions_ via ._callTargets() on AvoWallet and deploying AvoSafe if necessary
    /// Can be used for versions > 2.0.0 (2.x.x and 3.x.x)
    /// Note this gas estimation will not include the gas consumed in `.cast()`
    /// @param owner_               AvoSafe owner
    /// @param actions_             the actions to execute (target, data, value, operation)
    /// @param id_                  id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @param avoWalletVersion_    Version of AvoWallet logic contract to deploy
    /// @return totalGasUsed_       total amount of gas used
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the AvoWallet if already deployed)
    /// @return isAvoSafeDeployed_  boolean flag indicating if AvoSafe is already deployed (true) or if it must be deployed (false)
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGasWithVersion(
        address owner_,
        IAvoWalletV3.Action[] calldata actions_,
        uint256 id_,
        address avoWalletVersion_
    )
        external
        payable
        returns (uint256 totalGasUsed_, uint256 deploymentGasUsed_, bool isAvoSafeDeployed_, bool success_)
    {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoWalletWithCallTargets avoWallet_;
        // _getDeployedAvoWallet automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoWallet_, isAvoSafeDeployed_) = _getDeployedAvoWallet(owner_, avoWalletVersion_);

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoWallet_).call{ value: msg.value }(
            abi.encodeCall(avoWallet_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /// @notice estimate gas usage of actions_ via ._callTargets() on AvoMultisig and deploying AvoMultiSafe if necessary
    /// Note this gas estimation will not include the gas consumed in `.cast()`
    /// @param owner_         AvoMultiSafe owner
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param id_            id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @return totalGasUsed_           total amount of gas used
    /// @return deploymentGasUsed_      amount of gas used for deployment (or for getting the AvoWallet if already deployed)
    /// @return isDeployed_             boolean flag indicating if AvoMultiSafe is already deployed (true) or if it must be deployed (false)
    /// @return success_                boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGasMultisig(
        address owner_,
        IAvoMultisigV3.Action[] calldata actions_,
        uint256 id_
    ) external payable returns (uint256 totalGasUsed_, uint256 deploymentGasUsed_, bool isDeployed_, bool success_) {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoMultisigWithCallTargets avoMultisig_;
        // _getDeployedAvoMultisig automatically checks if AvoMultiSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoMultisig_, isDeployed_) = _getDeployedAvoMultisig(owner_, address(0));

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoMultisig_).call{ value: msg.value }(
            abi.encodeCall(avoMultisig_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /// @notice estimate gas usage of actions_ via ._callTargets() on AvoWallet and deploying AvoSafe if necessary
    /// Note this gas estimation will not include the gas consumed in `.cast()`
    /// @param owner_               AvoMultiSafe owner
    /// @param actions_             the actions to execute (target, data, value, operation)
    /// @param id_                  id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @param avoMultisigVersion_  Version of AvoMultisig logic contract to deploy
    /// @return totalGasUsed_       total amount of gas used
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the AvoWallet if already deployed)
    /// @return isDeployed_  b      oolean flag indicating if AvoMultiSafe is already deployed (true) or if it must be deployed (false)
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGasWithVersionMultisig(
        address owner_,
        IAvoMultisigV3.Action[] calldata actions_,
        uint256 id_,
        address avoMultisigVersion_
    ) external payable returns (uint256 totalGasUsed_, uint256 deploymentGasUsed_, bool isDeployed_, bool success_) {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoMultisigWithCallTargets avoMultisig_;
        // _getDeployedAvoMultisig automatically checks if AvoMultiSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoMultisig_, isDeployed_) = _getDeployedAvoMultisig(owner_, avoMultisigVersion_);

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoMultisig_).call{ value: msg.value }(
            abi.encodeCall(avoMultisig_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev gets or if necessary deploys an AvoSafe for owner `from_` and returns the address
    /// @param from_                AvoSafe Owner
    /// @param avoWalletVersion_    Optional param to define a specific AvoWallet version to deploy
    /// @return                     the AvoSafe for the owner & boolean flag for if it was already deployed or not
    function _getDeployedAvoWallet(
        address from_,
        address avoWalletVersion_
    ) internal returns (IAvoWalletWithCallTargets, bool) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return (IAvoWalletWithCallTargets(computedAvoSafeAddress_), true);
        } else {
            if (avoWalletVersion_ == address(0)) {
                return (IAvoWalletWithCallTargets(avoFactory.deploy(from_)), false);
            } else {
                return (IAvoWalletWithCallTargets(avoFactory.deployWithVersion(from_, avoWalletVersion_)), false);
            }
        }
    }

    /// @dev gets or if necessary deploys an AvoMultiSafe for owner `from_` and returns the address
    /// @param from_                AvoMultiSafe Owner
    /// @param avoMultisigVersion_  Optional param to define a specific AvoMultisig version to deploy
    /// @return                     the AvoMultiSafe for the owner & boolean flag for if it was already deployed or not
    function _getDeployedAvoMultisig(
        address from_,
        address avoMultisigVersion_
    ) internal returns (IAvoMultisigWithCallTargets, bool) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddressMultisig(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return (IAvoMultisigWithCallTargets(computedAvoSafeAddress_), true);
        } else {
            if (avoMultisigVersion_ == address(0)) {
                return (IAvoMultisigWithCallTargets(avoFactory.deployMultisig(from_)), false);
            } else {
                return (
                    IAvoMultisigWithCallTargets(avoFactory.deployMultisigWithVersion(from_, avoMultisigVersion_)),
                    false
                );
            }
        }
    }

    /// @dev computes the deterministic contract address `computedAddress_` for a AvoSafe deployment for `owner_`
    function _computeAvoSafeAddress(address owner_) internal view returns (address computedAddress_) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSalt(owner_), avoSafeBytecode)
        );

        // cast last 20 bytes of hash to address
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev computes the deterministic contract address `computedAddress_` for a AvoSafeMultsig deployment for `owner_`
    function _computeAvoSafeAddressMultisig(address owner_) internal view returns (address computedAddress_) {
        // replicate Create2 address determination logic
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSaltMultisig(owner_), avoMultiSafeBytecode)
        );

        // cast last 20 bytes of hash to address
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev  gets the bytes32 salt used for deterministic deployment for `owner_`
    function _getSalt(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }

    /// @dev  gets the bytes32 salt used for deterministic Multisig deployment for `owner_`
    function _getSaltMultisig(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "./IAvoVersionsRegistry.sol";

interface IAvoFactory {
    /// @notice returns AvoVersionsRegistry (proxy) address
    function avoVersionsRegistry() external view returns (IAvoVersionsRegistry);

    /// @notice returns Avo wallet logic contract address that new AvoSafe deployments point to
    function avoWalletImpl() external view returns (address);

    /// @notice returns AvoMultisig logic contract address that new AvoMultiSafe deployments point to
    function avoMultisigImpl() external view returns (address);

    /// @notice           Checks if a certain address is an AvoSafe instance. only works for already deployed AvoSafes
    /// @param avoSafe_   address to check
    /// @return           true if address is an avoSafe
    function isAvoSafe(address avoSafe_) external view returns (bool);

    /// @notice                    Computes the deterministic address for owner based on Create2
    /// @param owner_              AvoSafe owner
    /// @return computedAddress_   computed address for the contract (AvoSafe)
    function computeAddress(address owner_) external view returns (address computedAddress_);

    /// @notice                      Computes the deterministic Multisig address for owner based on Create2
    /// @param owner_                AvoMultiSafe owner
    /// @return computedAddress_     computed address for the contract (AvoSafe)
    function computeAddressMultisig(address owner_) external view returns (address computedAddress_);

    /// @notice         Deploys an AvoSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoSafe owner
    /// @return         deployed address for the contract (AvoSafe)
    function deploy(address owner_) external returns (address);

    /// @notice                    Deploys an AvoSafe with non-default version for an owner deterministcally using Create2.
    ///                            ATTENTION: Only supports AvoWallet version > 2.0.0
    ///                            Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_              AvoSafe owner
    /// @param avoWalletVersion_   Version of AvoWallet logic contract to deploy
    /// @return                    deployed address for the contract (AvoSafe)
    function deployWithVersion(address owner_, address avoWalletVersion_) external returns (address);

    /// @notice         Deploys an AvoMultiSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoMultiSafe owner
    /// @return         deployed address for the contract (AvoMultiSafe)
    function deployMultisig(address owner_) external returns (address);

    /// @notice                      Deploys an AvoMultiSafe with non-default version for an owner
    ///                              deterministcally using Create2.
    ///                              Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_                AvoMultiSafe owner
    /// @param avoMultisigVersion_   Version of AvoMultisig logic contract to deploy
    /// @return                      deployed address for the contract (AvoMultiSafe)
    function deployMultisigWithVersion(address owner_, address avoMultisigVersion_) external returns (address);

    /// @notice                     registry can update the current AvoWallet implementation contract set as default
    ///                             `_ avoWalletImpl` logic contract address for new AvoSafe (proxy) deployments
    /// @param avoWalletImpl_       the new avoWalletImpl address
    function setAvoWalletImpl(address avoWalletImpl_) external;

    /// @notice                     registry can update the current AvoMultisig implementation contract set as default
    ///                             `_ avoMultisigImpl` logic contract address for new AvoMultiSafe (proxy) deployments
    /// @param avoMultisigImpl_     the new avoWalletImpl address
    function setAvoMultisigImpl(address avoMultisigImpl_) external;

    /// @notice      returns the byteCode for the AvoSafe contract used for Create2 address computation
    function avoSafeBytecode() external view returns (bytes32);

    /// @notice      returns  the byteCode for the AvoSafe contract used for Create2 address computation
    function avoMultiSafeBytecode() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

/// @notice base interface without getters for storage variables
interface IAvoMultisigV3Base is AvoCoreStructs {
    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoMultisig version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoMultisig logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature for `cast()`
    /// @dev                  This is also the non-sequential nonce that will be marked as used when the request
    ///                       with the matching `params_` and `forwardParams_` is executed via `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castAuthorized()`
    /// @dev                      This is also the non-sequential nonce that will be marked as used when the request
    ///                           with the matching `params_` and `authorizedParams_` is executed via `castAuthorized()`
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 digest to verify signature
    function getSigDigestAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice                   Verify the transaction signature for a `cast()' request is valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Verify the transaction signature for a `castAuthorized()' request is valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   executes arbitrary `actions_` with a valid signature executable by AvoForwarder
    ///                           if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                      validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   executes arbitrary `actions_` through authorized tx sent with valid signatures.
    ///                           Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                           if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                      executes a .call or .delegateCall for every action (depending on params)
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice  checks if an address `signer_` is an allowed signer (returns true if allowed)
    function isSigner(address signer_) external view returns (bool);

    /// @notice  returns allowed signers on AvoMultisig wich can trigger actions
    ///          if reaching quorum of `requiredSigners` (include owner)
    function signers() external view returns (address[] memory signers);
}

/// @notice full interface with some getters for storage variables
interface IAvoMultisigV3 is IAvoMultisigV3Base {
    /// @notice             AvoMultisig Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);

    /// @notice             returns the number of allowed signers
    function signersCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoFeeCollector {
    /// @notice FeeConfig params used to determine the fee
    struct FeeConfig {
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        /// @param fee current fee amount:
        // for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%);
        // for static mode: absolute amount in native gas token to charge (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the fee for an AvoSafe (msg.sender) transaction `gasUsed_` based on fee configuration
    /// @param gasUsed_ amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoVersionsRegistry is IAvoFeeCollector {
    /// @notice                   checks if an address is listed as allowed AvoWallet version and reverts if not
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version
    ///                              and reverts if it is not
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed AvoMultisig version and reverts if not
    /// @param avoMultisigVersion_  address of the AvoMultisig logic contract to check
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

/// @notice base interface without getters for storage variables
interface IAvoWalletV3Base is AvoCoreStructs {
    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoWallet version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoWallet logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               returns non-sequential nonce that will be marked as used when the request with the matching
    ///                       `params_` and `authorizedParams_` is executed via `castAuthorized()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_   Cast params related to execution through owner such as maxFee
    /// @return               bytes32 non sequential nonce
    function nonSequentialNonceAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature
    /// @dev                  This is also the non-sequential nonce that will be marked as used when the request
    ///                       with the matching `params_` and `forwardParams_` is executed via `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                 Verify the transaction signature is valid and can be executed.
    ///                         This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                         Does not revert and returns successfully if the input is valid.
    ///                         Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                         For smart contract signatures it must fulfill the requirements for the relevant
    ///                         smart contract `.isValidSignature()` EIP1271 logic
    ///                         -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                         If defined, it must match the actual signature signer or refer to the smart contract
    ///                         that must be an allowed authority and validates signature via EIP1271
    /// @return                 returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external view returns (bool);

    /// @notice                 executes arbitrary `actions_` with a valid signature
    ///                         if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                         in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                    validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                         For smart contract signatures it must fulfill the requirements for the relevant
    ///                         smart contract `.isValidSignature()` EIP1271 logic
    ///                         -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                         If defined, it must match the actual signature signer or refer to the smart contract
    ///                         that must be an allowed authority and validates signature via EIP1271
    /// @return success         true if all actions were executed succesfully, false otherwise.
    /// @return revertReason    revert reason if one of the actions fails
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                 executes arbitrary `actions_` through authorized tx sent by owner.
    ///                         Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                         if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                         in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                    executes a .call or .delegateCall for every action (depending on params)
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_     Cast params related to execution through owner such as maxFee
    /// @return success         true if all actions were executed succesfully, false otherwise.
    /// @return revertReason    revert reason if one of the actions fails
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice             checks if an address `authority` is an allowed authority (returns true if allowed)
    function isAuthority(address authority_) external view returns (bool);
}

/// @notice full interface with some getters for storage variables
interface IAvoWalletV3 is IAvoWalletV3Base {
    /// @notice             AvoWallet Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);
}