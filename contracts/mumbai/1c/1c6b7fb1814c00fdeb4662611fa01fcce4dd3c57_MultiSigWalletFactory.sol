/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/proxy/utils/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
        if (_initialized < type(uint8).max) {
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// License-Identifier: MIT
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


// File contracts/multisig.sol

// License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
contract MultiSigWallet is Initializable {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    enum ProposalType {
        Transaction,
        NewOwner,
        RemoveOwner,
        ChangeThreshold,
        ChangeOwner,
        TokenTransaction,
        NFTTransaction
    }

    struct Proposal {
        uint index;
        bool executed;
        uint numConfirmations;
        ProposalType proposalType;
        bytes proposalData;
    }

    Proposal[] public  proposals;
    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired; // TODO non dobbiamo far modificare anche questo?
    uint public numThreshold;

    /*
     **********
     * EVENTS
     **********
     */

    // GENERIC EVENTS
    event Deposit(address indexed sender, uint amount, uint balance);
    event ConfirmProposal(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);

    // TRANSACTION EVENTS
    event ProposeTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed to,
        uint value
    );
    event ExecuteTransaction(address indexed owner, uint indexed proposalIndex);

    // NEW OWNER EVENTS
    event ProposeNewOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed newOwner
    );
    event ExecuteNewOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed newOwner
    );

    // REMOVE OWNER EVENTS
    event ProposeRemoveOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed addressToRemove
    );
    event ExecuteRemoveOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed addressToRemove
    );

    // CHANGE Threshold EVENTS
    event ProposeChangeThreshold(
        address indexed owner,
        uint indexed proposalIndex,
        uint newNumThreshold
    );
    event ExecuteChangeThreshold(
        address indexed owner,
        uint indexed proposalIndex,
        uint newNumThreshold
    );

    // CHANGE OWNER EVENTS
    event ProposeChangeOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address oldOwner,
        address indexed newOwner
    );
    event ImAmHere(address indexed owner, uint indexed proposalIndex);
    event ExecuteChangeOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address oldOwner,
        address indexed newOwner
    );

    // TOKEN TRANSACTION EVENTS
    event ProposeTokenTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address tokenAddress,
        address to,
        uint value
    );
    event ExecuteTokenTransaction(
        address indexed owner,
        uint indexed proposalIndex
    );

    // NFT TRANSACTION EVENTS
    event ProposeNFTTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address NFTAddress,
        address to,
        uint value
    );
    event ExecuteNFTTransaction(
        address indexed owner,
        uint indexed proposalIndex
    );

    /*
     **********
     * MODIFIER
     **********
     */

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Must be an owner");
        _;
    }

    modifier proposalExists(uint _proposalIndex) {
        require(_proposalIndex < proposals.length, "Proposal does not exist");
        _;
    }

    modifier proposalNotExecuted(uint _proposalIndex) {
        require(
            !proposals[_proposalIndex].executed,
            "Proposal already executed"
        );
        _;
    }

    modifier proposalNotConfirmed(uint _proposalIndex) {
        require(
            !isConfirmed[_proposalIndex][msg.sender],
            "Proposal already confirmed by this owner"
        );
        _;
    }

    function initialize(
        address[] memory _owners,
        uint _numConfirmationsRequired,
        uint _numThreshold
    ) external initializer {
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations number"
        );
        require(
            _numThreshold > 0 && _numThreshold < _owners.length,
            "invalid number of required threshold confirmations number"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        numThreshold = _numThreshold;
    }

    /*
     **********
     * GENERIC FUNCTIONS
     **********
     */

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function confirmProposal(
        uint _txIndex
    )
        public
        onlyOwner
        proposalExists(_txIndex)
        proposalNotExecuted(_txIndex)
        proposalNotConfirmed(_txIndex)
    {
        Proposal storage proposal = proposals[_txIndex];
        proposal.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmProposal(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner proposalExists(_txIndex) proposalNotExecuted(_txIndex) {
        Proposal storage proposal = proposals[_txIndex];

        require(
            isConfirmed[_txIndex][msg.sender],
            "Proposal not confirmed by this owner"
        );

        proposal.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function executeProposal(
        uint _txIndex
    ) public onlyOwner proposalExists(_txIndex) proposalNotExecuted(_txIndex) {
        Proposal storage proposal = proposals[_txIndex];

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.Transaction) {
            _executeTransaction(proposal);
        } else if (proposal.proposalType == ProposalType.NewOwner) {
            _executeNewOwner(proposal);
        } else if (proposal.proposalType == ProposalType.RemoveOwner) {
            _executeRemoveOwner(proposal);
        } else if (proposal.proposalType == ProposalType.ChangeThreshold) {
            _executeChangeThreshold(proposal);
        } else if (proposal.proposalType == ProposalType.ChangeOwner) {
            _executeChangeOwner(proposal);
        } else if (proposal.proposalType == ProposalType.TokenTransaction) {
            _executeTokenTransaction(proposal);
        } else if (proposal.proposalType == ProposalType.NFTTransaction) {
            _executeNFTTransaction(proposal);
        }
    }

    /*
     **********
     * SPECIFIC FUNCTIONS
     **********
     */

    /**
     * Transactions
     */
    function proposeTransaction(
        address _to,
        uint _value
    )
        public
        //data??
        onlyOwner
    {
        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.Transaction,
                proposalData: abi.encode(_to, _value)
            })
        );

        emit ProposeTransaction(msg.sender, _proposalIndex, _to, _value);
    }

    function _executeTransaction(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        (address _to, uint _value) = abi.decode(
            proposal.proposalData,
            (address, uint)
        );

        (bool success, ) = _to.call{value: _value}("");
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, proposal.index);
    }

    /**
     * Add Owner
     */
    function proposeNewOwner(address _newOwner) public onlyOwner {
        require(!isOwner[_newOwner], "User is already an owner");
        require(_newOwner != address(0), "New owner can't be zero address");

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.NewOwner,
                proposalData: abi.encode(_newOwner)
            })
        );

        emit ProposeNewOwner(msg.sender, _proposalIndex, _newOwner);
    }

    function _executeNewOwner(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        address _newOwner = abi.decode(proposal.proposalData, (address));

        isOwner[_newOwner] = true;
        owners.push(_newOwner);

        emit ExecuteNewOwner(msg.sender, proposal.index, _newOwner);
    }

    /**
     * Remove Owner
     */
    function proposeRemoveOwner(address _addressToRemove) public onlyOwner {
        require(isOwner[_addressToRemove], "User is not an owner");

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.RemoveOwner,
                proposalData: abi.encode(_addressToRemove)
            })
        );

        emit ProposeRemoveOwner(msg.sender, _proposalIndex, _addressToRemove);
    }

    function _executeRemoveOwner(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );
        require(owners.length > 1, "At least one owner must remain");

        address _addressToRemove = abi.decode(proposal.proposalData, (address));

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _addressToRemove) {
                // Rimuove il proprietario dall'array spostando tutti gli elementi successivi a sinistra
                for (uint256 j = i; j < owners.length - 1; j++) {
                    owners[j] = owners[j + 1];
                }
                owners.pop();
                break;
            }
        }

        isOwner[_addressToRemove] = false;

        emit ExecuteRemoveOwner(msg.sender, proposal.index, _addressToRemove);
    }

    /**
     * Change Threshold
     */
    function proposeChangeThreshold(uint _newThreshold) public onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        require(
            _newThreshold < owners.length,
            "Threshold must be lower than number of owners"
        );

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.ChangeThreshold,
                proposalData: abi.encode(_newThreshold)
            })
        );

        emit ProposeChangeThreshold(msg.sender, _proposalIndex, _newThreshold);
    }

    function _executeChangeThreshold(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        uint _newThreshold = abi.decode(proposal.proposalData, (uint));
        numThreshold = _newThreshold;

        emit ExecuteChangeThreshold(msg.sender, proposal.index, _newThreshold);
    }

    /**
     * Token Transaction
     */
    function proposeTokenTransaction(
        address _to,
        address _tokenAddress,
        uint _value
    ) public onlyOwner {
        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.TokenTransaction,
                proposalData: abi.encode(_to, _tokenAddress, _value)
            })
        );

        emit ProposeTokenTransaction(
            msg.sender,
            _proposalIndex,
            _to,
            _tokenAddress,
            _value
        );
    }

    function _executeTokenTransaction(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        (address _to, address _tokenAddress, uint _value) = abi.decode(
            proposal.proposalData,
            (address, address, uint)
        );

        IERC20(_tokenAddress).transfer(_to, _value);

        emit ExecuteTokenTransaction(msg.sender, proposal.index);
    }

    /**
     * NFT Transfer
     */
    function proposeNFTTransaction(
        address _to,
        address _NFTAddress,
        uint _NFTid
    ) public onlyOwner {
        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.NFTTransaction,
                proposalData: abi.encode(_to, _NFTAddress, _NFTid)
            })
        );

        emit ProposeNFTTransaction(
            msg.sender,
            _proposalIndex,
            _NFTAddress,
            _to,
            _NFTid
        );
    }

    function _executeNFTTransaction(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        (address _to, address _NFTAddress, uint _NFTid) = abi.decode(
            proposal.proposalData,
            (address, address, uint)
        );

        IERC721(_NFTAddress).safeTransferFrom(address(this), _to, _NFTid);

        emit ExecuteNFTTransaction(msg.sender, proposal.index);
    }

    /**
     * Change Owner
     */
    function proposeChangeOwner(
        address _oldOwner,
        address _newOwner
    ) public onlyOwner {
        require(!isOwner[_newOwner], "User is already an owner");
        require(_newOwner != address(0), "New owner can't be zero address");

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.ChangeOwner,
                proposalData: abi.encode(
                    _oldOwner,
                    _newOwner,
                    false,
                    true,
                    block.timestamp + 2 minutes
                )
            })
        );

        emit ProposeChangeOwner(
            msg.sender,
            _proposalIndex,
            _oldOwner,
            _newOwner
        );
    }

    function _executeChangeOwner(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numThreshold,
            "Number of confirmations too low"
        );

        (
            address _oldOwner,
            address _newOwner,
            bool _imHere,
            bool _lock,
            uint _timeToUnLock
        ) = abi.decode(
                proposal.proposalData,
                (address, address, bool, bool, uint)
            );

        require(!_imHere, "called ImHere function");

        if (block.timestamp >= _timeToUnLock && _lock) {
            _lock = false;
        }

        require(_lock == false, "tempo non ancora passato");

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _oldOwner) {
                owners[i] = _newOwner;
                break;
            }
        }

        isOwner[_oldOwner] = false;
        isOwner[_newOwner] = true;

        emit ExecuteChangeOwner(
            msg.sender,
            proposal.index,
            _oldOwner,
            _newOwner
        );
    }

    // TODO verificare
    function imAmHere(
        uint _proposalIndex
    )
        public
        onlyOwner
        proposalExists(_proposalIndex)
        proposalNotExecuted(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];
        require(
            proposal.proposalType == ProposalType.ChangeOwner,
            "Can't call this function for this proposal"
        );
       

        (
            address _oldOwner,
            address _newOwner,
            bool _imHere,
            bool _lock,
            uint _timeToUnLock
        ) = abi.decode(
                proposal.proposalData,
                (address, address, bool, bool, uint)
            );

        require(!_imHere, "You have already called this function");

        require(_oldOwner == msg.sender, "You are not the old owner"); // Aggiunto, vedere con gli altri
        require(
            _timeToUnLock - block.timestamp > 0,
            "Time to block execution has expired"
        );

        _imHere = true;
        proposal.proposalData = abi.encode(
            _oldOwner,
            _newOwner,
            _imHere,
            _lock,
            _timeToUnLock
        );

        emit ImAmHere(msg.sender, _proposalIndex);
    }

    function getTimeToUnlock(uint _proposalIndex) public view returns (uint) {
        Proposal storage proposal = proposals[_proposalIndex];
        (
            address _oldOwner,
            address _newOwner,
            bool _imHere,
            bool _lock,
            uint _timeToUnLock
        ) = abi.decode(
                proposal.proposalData,
                (address, address, bool, bool, uint)
            );

        uint timeToUnlock = _timeToUnLock - block.timestamp;
        return timeToUnlock > 0 ? timeToUnlock : 0;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getProposalsCount() public view returns (uint) {
        return proposals.length;
    }

    // PROPOSALS E' PUBLIC. ALTRIMENTI METTIAMO PRIVATE E FUNZIONE GETPROPOSAL ONLYOWNER

        function decodeProposalData (uint _proposalIndex) public view  {

             Proposal storage proposal = proposals[_proposalIndex];

             if (proposal.proposalType == ProposalType.Transaction){

                _decodetransactionData(proposal.proposalData);
             }
             else if (proposal.proposalType == ProposalType.NewOwner){
                    
                    _decodeNewOwnerData(proposal.proposalData);
                }
                else if (proposal.proposalType == ProposalType.RemoveOwner){
    
                    _decodeRemoveOwnerData(proposal.proposalData);
                }
                else if (proposal.proposalType == ProposalType.ChangeThreshold){
    
                    _decodeChangeThresholdData(proposal.proposalData);
                }
                else if (proposal.proposalType == ProposalType.ChangeOwner){
    
                    _decodeChangeOwnerData(proposal.proposalData);
                }
                else if (proposal.proposalType == ProposalType.TokenTransaction){
    
                    _decodeTokenTransactionData(proposal.proposalData);
                
             }
             else if (proposal.proposalType == ProposalType.NFTTransaction){
    
                _decodeNFTTransactionData(proposal.proposalData);    }

            
        }

        function _decodetransactionData (bytes memory proposalData) internal pure returns (address to, uint value){
            return abi.decode(proposalData, (address, uint));
        }

        function _decodeNewOwnerData (bytes memory proposalData) internal pure returns (address newOwner){
            return abi.decode(proposalData, (address));
        }
        function _decodeRemoveOwnerData (bytes memory proposalData) internal pure returns (address addressToRemove){
            return abi.decode(proposalData, (address));
        }
        function _decodeChangeThresholdData (bytes memory proposalData) internal pure returns (uint newNumThreshold){
            return abi.decode(proposalData, (uint));
        }
        function _decodeChangeOwnerData (bytes memory proposalData) internal pure returns (address oldOwner, address newOwner, bool imHere, bool lock, uint timeToUnLock){
            return abi.decode(proposalData, (address, address, bool, bool, uint));
        }
        function _decodeTokenTransactionData (bytes memory proposalData) internal pure returns (address tokenAddress, address to, uint value){
            return abi.decode(proposalData, (address, address, uint));
        }
        function _decodeNFTTransactionData (bytes memory proposalData) internal pure returns (address NFTAddress, address to, uint NFTid){
            return abi.decode(proposalData, (address, address, uint));
        }
}


// File contracts/proxyFactory.sol

// License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMultiSig{

 function initialize(address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) external;

}

contract MultiSigWalletFactory  {
   address public implementationContract;

  constructor(address _implementationContract) {
    implementationContract = _implementationContract;
  }
    event ProxyCreated(address proxy);
   


function clone(address implementation, address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
       
       IMultiSig(instance).initialize(_owners, _numConfirmationsRequired, _numTreshold);
       
       emit ProxyCreated(address(instance));
       return instance;
            
    }
    
    function createWallet(address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) public returns (address){
    address proxy = clone(implementationContract, _owners, _numConfirmationsRequired, _numTreshold);
    return proxy;
  }
}