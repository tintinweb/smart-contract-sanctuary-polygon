// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

struct RevisionInput {
    uint8 revNum;
    bytes32 jti;
    bytes32 merkleRoot;
}

struct StoredRevision {
    uint8 revNum;
    uint32 storedAtBlockNumber;
    bytes32 jti;
    bytes32 merkleRoot;
}

struct Certificate {
    string purpose;
    string issuer;
    string jti;
    string subject;
    string algorithm;
    string pk;
    string parent;
}

contract VerizonContentTracker is Initializable {
    // THIS IS USED TO ALLOW THE FACTORY TO CALL THE INITIALIZER
    address public immutable factory;
    Certificate public vzJWTCert;

    //mapping of operators
    mapping(address => bool) private _operators;
    //Mapping of JTI to linked list
    mapping(bytes32 => StoredRevision[]) private _jtiToRevList;
    // event for new revision
    event NewRevision(
        bytes32 indexed jti,
        bytes32 indexed merkleRoot,
        uint8 indexed revNum,
        uint32 storedAtBlockNumber
    );

    modifier onlyOperator() {
        require(_operators[msg.sender], "only operators can call this function");
        _;
    }
    modifier onlyFactory() {
        require(msg.sender == factory, "only the factory can call this function");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    // initialize the contract with an operator
    function initialize(address operator_) public onlyFactory initializer {
        _addOperator(operator_);
        vzJWTCert = Certificate({
            purpose: "03",
            issuer: "adledger.org",
            jti: "UuAaDS-FbnPCth81sEa7ta3wKXE2niHU30WC0YC_8PA",
            subject: "verizon.com",
            algorithm: "EdDSA-ed25519",
            pk: "9Cj4-EL54Ydi4DXphGYJEVx5WR2hoftywau0e_i36hI",
            parent: "013d6643d8ef9bb9f1ff4585867eeccaff42273916"
        });
    }

    /**
     * @dev adds the jti to the _jtiToRevList mapping
     * @param node_ a node object with where the revision is 0, jti = merkle root, and previous rev num = 0
     */
    function addNewArticle(RevisionInput calldata node_) public onlyOperator returns (bool) {
        // check if the revNum is 0
        if (node_.revNum != 0) {
            return false;
        }
        // if the merkle root does not equal the jti or if either one is undefined return false
        if (node_.jti == 0 || node_.merkleRoot != node_.jti || _jtiToRevList[node_.jti].length != 0) {
            return false;
        }
        StoredRevision memory storedRevision = StoredRevision({
            revNum: node_.revNum,
            storedAtBlockNumber: uint32(block.number),
            jti: node_.jti,
            merkleRoot: node_.merkleRoot
        });
        // add the new jti to the mapping and point it to a new list of revisions
        _jtiToRevList[storedRevision.jti].push(storedRevision);
        emit NewRevision(
            storedRevision.jti,
            storedRevision.merkleRoot,
            storedRevision.revNum,
            storedRevision.storedAtBlockNumber
        );
        return true;
    }

    /**
     * @dev adds a new revision to the linked list
     * @param revision_ a revision object with where the revision is greater than 0, jti != merkle root, and previous rev num = previous head
     */
    function addNewRevision(RevisionInput calldata revision_) public onlyOperator returns (bool) {
        uint256 nextRev = revision_.revNum;
        // previous revision
        uint256 totalRevs = _jtiToRevList[revision_.jti].length;
        if (totalRevs != nextRev || nextRev == 0) {
            return false;
        }
        // make sure merkle root does not equal jti and that both are defined
        if (revision_.jti == 0 || revision_.merkleRoot == 0 || revision_.merkleRoot == revision_.jti) {
            return false;
        }
        StoredRevision memory storedRevision = StoredRevision({
            revNum: revision_.revNum,
            storedAtBlockNumber: uint32(block.number),
            jti: revision_.jti,
            merkleRoot: revision_.merkleRoot
        });
        // add the new revision to list
        _jtiToRevList[revision_.jti].push(storedRevision);

        emit NewRevision(
            storedRevision.jti,
            storedRevision.merkleRoot,
            storedRevision.revNum,
            storedRevision.storedAtBlockNumber
        );
        return true;
    }

    function addContentBatch(RevisionInput[] calldata nodes_) public onlyOperator returns (uint32 succeeded) {
        for (uint256 i = 0; i < nodes_.length; i++) {
            if (nodes_[i].revNum == 0) {
                if (addNewArticle(nodes_[i])) {
                    succeeded++;
                }
            } else {
                if (addNewRevision(nodes_[i])) {
                    succeeded++;
                }
            }
        }
    }

    function revokeOperator(address operator_) public onlyFactory {
        delete _operators[operator_];
    }

    function addOperator(address operator_) public onlyFactory {
        _addOperator(operator_);
    }

    function updateVzJWTCert(Certificate calldata cert_) public onlyOperator {
        vzJWTCert = cert_;
    }

    /**
     * @dev returns the article revision Node object
     * @param jti_ bytes32 jti of the article
     * @param revNum_ revision number of the article
     */
    function getRevision(bytes32 jti_, uint8 revNum_) public view returns (StoredRevision memory) {
        if (_jtiToRevList[jti_].length <= revNum_) {
            return StoredRevision({ revNum: 0, storedAtBlockNumber: 0, jti: 0, merkleRoot: 0 });
        }
        return _jtiToRevList[jti_][revNum_];
    }

    /**
     * @notice returns an array of revisions. If the revision number is greater than the total
     * revisions for the article, it will return an empty revision
     * @param jtis_ array of jti
     * @param revNums_ array of revision numbers
     * @return StoredRevision[] array of revisions. If the revision number is greater than the total
     * revisions for the article, it will return an empty revision.
     */
    function getRevisionInBatch(
        bytes32[] calldata jtis_,
        uint8[] calldata revNums_
    ) public view returns (StoredRevision[] memory) {
        require(jtis_.length == revNums_.length, "jtis and revNums must be same length");
        StoredRevision[] memory revisions = new StoredRevision[](jtis_.length);
        for (uint256 i = 0; i < jtis_.length; i++) {
            revisions[i] = getRevision(jtis_[i], revNums_[i]);
        }
        return revisions;
    }

    /**
     * @dev returns the linked list of revisions for the article
     * @param jti_ bytes32 jti of the article
     */
    function getRevList(bytes32 jti_) public view returns (StoredRevision[] memory) {
        return _jtiToRevList[jti_];
    }

    /**
     * @dev returns the operator status of the address
     * @param operator_ address of the operator
     */
    function isOperator(address operator_) public view returns (bool) {
        return _operators[operator_];
    }

    /**
     * @dev returns the head revision number of the article
     * @param jti_ bytes32 jti of the article
     */
    function getTotalRevisions(bytes32 jti_) public view returns (uint256) {
        return _jtiToRevList[jti_].length;
    }

    /**
     * @dev returns the article revision Node object
     * @param jti_ bytes32 jti of the article
     */
    function getLatestRevision(bytes32 jti_) public view returns (StoredRevision memory) {
        return _jtiToRevList[jti_][_jtiToRevList[jti_].length - 1];
    }

    function _addOperator(address operator_) internal {
        require(operator_ != address(0), "cannot add 0 address");
        _operators[operator_] = true;
    }
}