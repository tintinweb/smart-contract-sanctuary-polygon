/**
 *Submitted for verification at polygonscan.com on 2023-05-10
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


// File contracts/MultiSigWallet.sol

// License-Identifier: UNLICENSED
pragma solidity ^0.8.17;



contract MultiSigWallet is Initializable {

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        
        return this.onERC721Received.selector;
    }

    
    event Deposit(address indexed sender, uint amount, uint balance);
   
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value
    );

    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    uint public numTreshold;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
        
        
    }
    //index per owner
    event ProposeNewOwner( address indexed owner, uint indexed ownerIndex, address indexed newOwner);
    event ConfirmNewOwner(address indexed owner, uint indexed ownerIndex);
    event ExecuteAddOwner(address indexed owner, uint indexed ownerIndex, address indexed newOwner);

    struct Ownership {
        address newOwner;
        bool addExecuted;
        uint numConfirmations;
    }

    event ProposeRemoveOwner(address indexed owner, uint indexed removeIndex, address indexed addressRemove);
    event ConfirmeRemoveOwner(address indexed owner, uint indexed removeIndex);
    event ExcuteRemoveOwner(address indexed owner, uint indexed removeIndex, address indexed addressRemove);


    struct Deleting {
        address addressRemove;
        bool removeExecuted;
        uint numConfirmations;

    }
    
    event ProposeNewTreshold(address indexed owner, uint indexed tresholdIndex, uint newNumTreshold);
    event ConfirmNewTreshold(address indexed owner, uint indexed tresholdIndex);
    event ExecuteNewTreshold(address indexed owner, uint indexed tresholdIndex);


    struct Treshold {
        uint newNumTreshold;
        bool tresholdExecuted;
        uint numConfirmations;
    }

    event ProposeChangeOwner(address indexed owner, uint indexed rescueIndex, address oldOwner, address indexed newOwner);
    event ConfirmeChangeOwner(address indexed owner, uint indexed rescueIndex);
    event ImAmHere(address indexed owner, uint indexed rescueIndex );
    event ExcuteChangeOwner(address indexed owner, uint indexed rescueIndex, address oldOWner, address indexed newOwner);
    

    struct Rescue {
        address oldOwner;
        address newOwner;
        bool rescueExecuted;
        uint numConfirmations;
        bool imHere;
        uint256 timeToUnLock;
        bool lock;
    }
    
    event ProposeTokenTransaction(
        address indexed owner,
        uint indexed tokenIndex,
        address tokenAddress,
        address to,
        uint value
    );

    event ConfirmTokenTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTokenConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTokenTransaction(address indexed owner, uint indexed txIndex);

     struct TokenTransaction {
        address tokenAddress;
        address to;
        uint value;
        bool tokenExecuted;
        uint numConfirmations;   
    }

     event ProposeNFTTransaction(
        address indexed owner,
        uint indexed NFTIndex,
        address NFTAddress,
        address to,
        uint value
    );

    event ConfirmNFTTransaction(address indexed owner, uint indexed txIndex);
    event RevokeNFTConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteNFTTransaction(address indexed owner, uint indexed txIndex);

     struct NFTTransaction {
        address NFTAddress;
        address to;
        uint NFTid;
        bool NFTExecuted;
        uint numConfirmations;   
    }


    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    mapping(uint => mapping(address => bool)) public IsAddNewOwner;
    mapping(uint => mapping(address => bool)) public isRemoveOwner;
    mapping(uint => mapping(address => bool)) public isTreshold;
    mapping(uint => mapping(address => bool)) public isRescue;
    mapping(uint => mapping(address => bool)) public isToken;
    mapping(uint => mapping(address => bool)) public isNFT;

    Transaction[] public transactions;
    Ownership[] public ownerships;
    Deleting[] public delet;
    Treshold[] public tresholds;
    Rescue[] public resc;
    TokenTransaction[] public tokens;
    NFTTransaction[] public nfts;
    


    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
  
    modifier NFTTransactionExists(uint _NFTIndex) {
        require(_NFTIndex < nfts.length, "NFT transaction does not exist" );
        _;
    }
    modifier tokenTransactionExists(uint _tokenIndex) {
        require(_tokenIndex < tokens.length, "token transaction does not exist" );
        _;
    }
       modifier rescueExists(uint _rescueIndex) {
        require(_rescueIndex < resc.length, "rescue does not exist" );
        _;
    }
     modifier tresholdExists(uint _tresholdIndex) {
        require(_tresholdIndex < tresholds.length, "treshold does not exist" );
        _;
    }
    modifier ownerExists(uint _ownerIndex) {
        require(_ownerIndex < ownerships.length, "owner does not exist" );
        _;
    }
    modifier ownerRemoverExists(uint _removeIndex) {
        require(_removeIndex < delet.length, "removeOwner does not exist" );
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
modifier notExecutedNFTTransaction(uint _NFTIndex) {
        require(!nfts[_NFTIndex].NFTExecuted, "nft transaction already executed");
        _;
    } 

    modifier notExecutedTokenTransaction(uint _tokenIndex) {
        require(!tokens[_tokenIndex].tokenExecuted, "token transaction already executed");
        _;
    } 
   
    modifier notExecutedRescue(uint _rescueIndex) {
        require(!resc[_rescueIndex].rescueExecuted, "rescue already executed");
        _;
    }   

    modifier notExecutedTreshold(uint _tresholdIndex) {
        require(!tresholds[_tresholdIndex].tresholdExecuted, "treshold already executed");
        _;
    }    
    modifier notExecutedAddOwner(uint _ownerIndex) {
        require(!ownerships[_ownerIndex].addExecuted, "add owner already executed");
        _;
    }

    modifier notExecutedRemoveOwner(uint _removeIndex) {
        require(!delet[_removeIndex].removeExecuted, "remove alrady executed");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    modifier notConfirmedNFTTransaction(uint _NFTIndex) {
        require(!isNFT[_NFTIndex][msg.sender], "nft transaction already confirmed by this owner");
        _;
    }
     modifier notConfirmeTokenTransaction(uint _tokenIndex) {
        require(!isToken[_tokenIndex][msg.sender], "token transaction already confirmed by this owner");
        _;
    }

      modifier notConfirmedRescue(uint _rescueIndex) {
        require(!isRescue[_rescueIndex][msg.sender], "rescue already confirmed by this owner");
        _;
    }

      modifier notConfirmedTreshold(uint _tresholdIndex) {
        require(!isTreshold[_tresholdIndex][msg.sender], "treshold already confirmed by this owner");
        _;
    }

    modifier notConfirmedAddOwner(uint _ownerIndex) {
        require(!IsAddNewOwner[_ownerIndex][msg.sender], "add owner already confirmed by this owner");
        _;
    }

     modifier notConfirmedRemoveOwner(uint _removeIndex) {
        require(!isRemoveOwner[_removeIndex][msg.sender], "Remove owner already confirmed by this owner");
        _;
    }


    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed by this owner");
        _;
    }

    function initialize(address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) initializer external {
        
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations number"
        );
        require(
            _numTreshold > 0 &&
                _numTreshold < _owners.length,
            "invalid number of required treshold confirmations number"
        );
        
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            
            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        numTreshold = _numTreshold;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value
        //data??
    ) public onlyOwner {
        uint _txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, _txIndex, _to, _value);
    }

    function confirmTransaction(
        uint _txIndex
    )
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "number confirmations too low"
        );

        transaction.executed = true;


        (bool success, ) = transaction.to.call{value: transaction.value}(
            ""
        );
    
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

         
     function proposeNewOwner(address _newOwner) public onlyOwner {
            uint ownerIndex = ownerships.length;

            require(!isOwner[_newOwner] && _newOwner != address(0), "already owner or address 0");
          
        ownerships.push(
            Ownership({
                newOwner: _newOwner,
                addExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeNewOwner(msg.sender, ownerIndex, _newOwner);
    }

       function confirmNewOwner(
        uint _ownerIndex
    )
        public
        onlyOwner
        ownerExists(_ownerIndex)
        notExecutedAddOwner(_ownerIndex)
        notConfirmedAddOwner(_ownerIndex)
    {
        Ownership storage ownership = ownerships[_ownerIndex];
        ownership.numConfirmations += 1;
        IsAddNewOwner[_ownerIndex][msg.sender] = true;

        emit ConfirmNewOwner(msg.sender, _ownerIndex);
    }
    
        function executeAddOwner(
        uint _ownerIndex
       
    ) public onlyOwner ownerExists(_ownerIndex) notExecutedAddOwner(_ownerIndex) {
        Ownership storage ownership = ownerships[_ownerIndex];

        require(
            ownership.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        ownership.addExecuted = true;
        isOwner[ownership.newOwner] = true;
        owners.push(ownership.newOwner);


        emit ExecuteAddOwner(msg.sender, _ownerIndex, ownership.newOwner);
    }

 function proposeRemoveOwner(address _addressRemove) public onlyOwner {
        uint _removeIndex = delet.length;
        delet.push(
            Deleting({
                addressRemove: _addressRemove,
                removeExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeRemoveOwner(msg.sender, _removeIndex, _addressRemove);

    }
      function confirmeRemoveOwner(
        uint _removeIndex
    )
         public
        onlyOwner
        ownerRemoverExists(_removeIndex)
        notExecutedRemoveOwner(_removeIndex)
        notConfirmedRemoveOwner(_removeIndex)
    {
        Deleting storage deleting = delet[_removeIndex];
        deleting.numConfirmations += 1;
        isRemoveOwner[_removeIndex][msg.sender] = true;

        emit ConfirmeRemoveOwner(msg.sender, _removeIndex);
    }
 
function excuteRemoveOwner(
    uint _removeIndex
   ) public 
    onlyOwner 
    ownerRemoverExists(_removeIndex) 
    notExecutedRemoveOwner(_removeIndex) {
        Deleting storage deleting = delet[_removeIndex];
    
    require(isOwner[deleting.addressRemove], "owner not found");
    require(owners.length > 1, "cannot remove last owner");
    require(
            deleting.numConfirmations >= numTreshold,
            "number of confirmations too low"
        );

        deleting.removeExecuted = true;

           for (uint256 i = 0; i < owners.length; i++) {
        if (owners[i] == deleting.addressRemove) {
            // Rimuove il proprietario dall'array spostando tutti gli elementi successivi a sinistra
            for (uint256 j = i; j < owners.length - 1; j++) {
                owners[j] = owners[j+1];
            }
            owners.pop();
            break;
        }
       

    isOwner[deleting.addressRemove] = false;
    }

        emit ExcuteRemoveOwner(msg.sender, _removeIndex, deleting.addressRemove);
    }


     function proposeNewTreshold(uint _newNumTreshold) public onlyOwner {
            uint _tresholdIndex = tresholds.length;

            require(_newNumTreshold > 0 , "cannot be 0");
            require(_newNumTreshold < owners.length, "treshold minore degli owner ");

        tresholds.push(
            Treshold({
                newNumTreshold: _newNumTreshold,
                tresholdExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeNewTreshold(msg.sender, _tresholdIndex, _newNumTreshold);
    }

       function confirmNewTreshold(
        uint _tresholdIndex
    )
        public
        onlyOwner
        tresholdExists(_tresholdIndex)
        notExecutedTreshold(_tresholdIndex)
        notConfirmedTreshold(_tresholdIndex)
    {
        Treshold storage treshold = tresholds[_tresholdIndex];
        treshold.numConfirmations += 1;
        isTreshold[_tresholdIndex][msg.sender] = true;

        emit ConfirmNewTreshold(msg.sender, _tresholdIndex);
    }
    
        function executeNewTreshold(
        uint _tresholdIndex
        // uint newNumTreshold
    ) public onlyOwner tresholdExists(_tresholdIndex) notExecutedTreshold(_tresholdIndex) {
        Treshold storage treshold = tresholds[_tresholdIndex];

        require(
            treshold.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        
        treshold.tresholdExecuted = true;
        numTreshold = treshold.newNumTreshold;

        
        emit ExecuteNewTreshold(msg.sender, _tresholdIndex);
    }


    function proposeChangeOwner(address _oldOwner, address _newOwner) public onlyOwner {
            uint _rescueIndex = resc.length;

           require(!isOwner[_newOwner] && _newOwner != address(0), "already owner or address 0");
           require(isOwner[_oldOwner], "the old owner is not  actually an owner");

        resc.push(
            Rescue({
                oldOwner: _oldOwner,
                newOwner: _newOwner,
                rescueExecuted: false,
                numConfirmations: 0,
                imHere: false,
                lock: true,
                timeToUnLock: block.timestamp + 2 minutes

            })
            
            
        );

        emit ProposeChangeOwner(msg.sender, _rescueIndex ,_oldOwner, _newOwner);
    }


       function confirmeChangeOwner(
        uint _rescueIndex
    )
        public
        onlyOwner
        rescueExists(_rescueIndex)
        notExecutedRescue(_rescueIndex)
        notConfirmedRescue(_rescueIndex)
    {
        Rescue storage rescue = resc[_rescueIndex];
        rescue.numConfirmations += 1;
        isRescue[_rescueIndex][msg.sender] = true;

        emit ConfirmeChangeOwner(msg.sender, _rescueIndex);
    }

       function imAmHere(uint _rescueIndex) public 
        onlyOwner
        rescueExists(_rescueIndex)
        notExecutedRescue(_rescueIndex)
        {
        Rescue storage rescue = resc[_rescueIndex];
        require(rescue.timeToUnLock - block.timestamp >0, "Time to block execution has expired");
        rescue.imHere = true;
        isRescue[_rescueIndex][msg.sender] = true;
        emit ImAmHere(msg.sender, _rescueIndex);
        }
    
        function executeChangeOwner(
        uint _rescueIndex
        
    ) public onlyOwner rescueExists(_rescueIndex) notExecutedRescue(_rescueIndex) {
        Rescue storage rescue = resc[_rescueIndex];

        require(
            rescue.numConfirmations >= numConfirmationsRequired,
            "number confirmations too low"
        );
        require (rescue.imHere == false, "called ImHere function");
        
        if(block.timestamp >= rescue.timeToUnLock && rescue.lock) {
            rescue.lock = false;
        }

        require(rescue.lock == false, "tempo non ancora passato");
        

        

        rescue.rescueExecuted = true;

        for (uint256 i = 0; i < owners.length; i++) {
        if (owners[i] == rescue.oldOwner) {
            // Rimuove il proprietario dall'array spostando tutti gli elementi successivi a sinistra
            for (uint256 j = i; j < owners.length - 1; j++) {
                owners[j] = owners[j+1];
            }
            owners.pop();
            owners.push(rescue.newOwner);
            break;
        }
        isOwner[rescue.newOwner]= true;
        isOwner[rescue.oldOwner]=false;
        
        emit ExcuteChangeOwner(msg.sender, _rescueIndex, rescue.oldOwner, rescue.newOwner);
    }
}

     function proposeTokenTransaction(
        address _to,
         address _tokenAddress,
        uint _value
    ) public onlyOwner {
        uint _tokenindex = tokens.length;
        

        tokens.push(
            TokenTransaction({
                to: _to,
                tokenAddress: _tokenAddress,
                value: _value,
                tokenExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeTokenTransaction(msg.sender, _tokenindex, _to,_tokenAddress, _value);
    }

    function confirmTokenTransaction(
        uint _tokenIndex
    )
        public
        onlyOwner
        tokenTransactionExists(_tokenIndex)
        notExecutedTokenTransaction(_tokenIndex)
        notConfirmeTokenTransaction(_tokenIndex)
    {
        TokenTransaction storage tokenTransaction = tokens[_tokenIndex];
        tokenTransaction.numConfirmations += 1;
        isToken[_tokenIndex][msg.sender] = true;

        emit ConfirmTokenTransaction(msg.sender, _tokenIndex);
    }

    function executeTokenTransaction(
        uint _tokenIndex
    ) public onlyOwner tokenTransactionExists(_tokenIndex) notExecutedTokenTransaction(_tokenIndex) {
        TokenTransaction storage tokenTransaction = tokens[_tokenIndex];

        require(
            tokenTransaction.numConfirmations >= numConfirmationsRequired,
            "number confirmations too low"
        );

        tokenTransaction.tokenExecuted = true;

        
        IERC20(tokenTransaction.tokenAddress).transfer(tokenTransaction.to, tokenTransaction.value);


        emit ExecuteTokenTransaction(msg.sender, _tokenIndex);
    }

    function revokeTokenConfirmation(
        uint _tokenIndex
    ) public onlyOwner tokenTransactionExists(_tokenIndex) notExecutedTokenTransaction(_tokenIndex) {
        TokenTransaction storage tokenTransaction = tokens[_tokenIndex];

        require(isToken[_tokenIndex][msg.sender], "token transaction not confirmed");

        tokenTransaction.numConfirmations -= 1;
        isToken[_tokenIndex][msg.sender] = false;

        emit RevokeTokenConfirmation(msg.sender, _tokenIndex);
    }

    function proposeNFTTransaction(
        address _to,
         address _NFTAddress,
        uint _NFTid
    ) public onlyOwner {
        uint _NFTindex = nfts.length;
        

        nfts.push(
            NFTTransaction({
                to: _to,
                NFTAddress: _NFTAddress,
                NFTid: _NFTid,
                NFTExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeNFTTransaction(msg.sender, _NFTindex,_NFTAddress, _to,  _NFTid);
    }

    function confirmNFTTransaction(
        uint _NFTIndex
    )
        public
        onlyOwner
        NFTTransactionExists(_NFTIndex)
        notExecutedNFTTransaction(_NFTIndex)
        notConfirmedNFTTransaction(_NFTIndex)
    {
        NFTTransaction storage NFTtransaction = nfts[_NFTIndex];
        NFTtransaction.numConfirmations += 1;
        isNFT[_NFTIndex][msg.sender] = true;

        emit ConfirmTokenTransaction(msg.sender, _NFTIndex);
    }

    function executeNFTTransaction(
        uint _NFTIndex
    ) public onlyOwner NFTTransactionExists(_NFTIndex) notExecutedNFTTransaction(_NFTIndex) {
        NFTTransaction storage NFTtransaction = nfts[_NFTIndex];

        require(
            NFTtransaction.numConfirmations >= numConfirmationsRequired,
            "number confirmations too low"
        );

        NFTtransaction.NFTExecuted = true;

        
        IERC721(NFTtransaction.NFTAddress).safeTransferFrom(address(this), NFTtransaction.to, NFTtransaction.NFTid);


        emit ExecuteNFTTransaction(msg.sender, _NFTIndex);
    }

    function revokeNFTConfirmation(
        uint _NFTIndex
    ) public onlyOwner NFTTransactionExists(_NFTIndex) notExecutedTokenTransaction(_NFTIndex) {
        NFTTransaction storage NFTtransaction = nfts[_NFTIndex];

        require(isNFT[_NFTIndex][msg.sender], "NFT transaction not confirmed");

        NFTtransaction.numConfirmations -= 1;
        isNFT[_NFTIndex][msg.sender] = false;

        emit RevokeNFTConfirmation(msg.sender, _NFTIndex);
    }
    

    function getTimeToUnlock(uint _rescueIndex) public view returns (uint) {
        Rescue storage rescue = resc[_rescueIndex];
        uint _timeToUnlock = rescue.timeToUnLock - block.timestamp;
        return _timeToUnlock > 0 ? _timeToUnlock : 0;
    }
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

        function getOwnershipsCount() public view returns (uint) {
        return ownerships.length;
    }
    function getDeletCount() public view returns (uint) {
        return delet.length;
    }
    function getTresholdsCount() public view returns (uint) {
        return tresholds.length;
    }
    function getRescCount() public view returns (uint) {
        return resc.length;
    }
    function getTokenTxCount() public view returns (uint) {
        return tokens.length;
    }
    function getNFTTxCount() public view returns (uint) {
        return nfts.length;
    }
    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,

            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            
            transaction.executed,
            transaction.numConfirmations
        );
    }
    function getOwnerships(
        uint _ownerIndex
    )
        public
        view
        returns (
            address newOwner,
        bool addExecuted,
        uint numConfirmations
        )
    {
        Ownership storage ownership = ownerships[_ownerIndex];

        return (
            ownership.newOwner,
            ownership.addExecuted,
            ownership.numConfirmations
        );
    }
    function getDelet(
        uint _removeIndex
    )
        public
        view
        returns (
            address addressRemove,
        bool removeExecuted,
        uint numConfirmations
        )
    {
        Deleting storage deleting = delet[_removeIndex];

        return (
            deleting.addressRemove,
            deleting.removeExecuted,
            deleting.numConfirmations
        );
    }
    function getTreshold(
        uint _tresholdIndex
    )
        public
        view
        returns (
           uint newNumTreshold,
        bool tresholdExecuted,
        uint numConfirmations
        )
    {
        Treshold storage treshold = tresholds[_tresholdIndex];

        return (
            treshold.newNumTreshold,
            treshold.tresholdExecuted,
            treshold.numConfirmations
        );
    }
    function getResc(
        uint _rescueIndex
    )
        public
        view
        returns (
        address oldOwner,
        address newOwner,
        bool rescueExecuted,
        uint numConfirmations,
        bool imHere,
        uint256 timeToUnLock,
        bool lock
        )
    {
        Rescue storage rescue = resc[_rescueIndex];

        return (
            rescue.oldOwner,
            rescue.newOwner,
            rescue.rescueExecuted,
            rescue.numConfirmations,
            rescue.imHere,
            rescue.timeToUnLock,
            rescue.lock
        );
    }
    function getTokenTx(
        uint _tokenTransactionIndex
    )
        public
        view
        returns (
         address tokenAddress,
        address to,
        uint value,
        bool tokenExecuted,
        uint numConfirmations
        )
    {
        TokenTransaction storage tokenTransaction = tokens[_tokenTransactionIndex];

        return (
         tokenTransaction.tokenAddress,
         tokenTransaction.to,
         tokenTransaction.value,
         tokenTransaction.tokenExecuted,
         tokenTransaction.numConfirmations 
        );
    }
        function getNFTTx(
        uint _NFTIndex
    )
        public
        view
        returns (
         address NFTAddress,
        address to,
        uint NFTid,
        bool NFTExecuted,
        uint numConfirmations  
        )
    {
        NFTTransaction storage NFTtransaction = nfts[_NFTIndex];

        return (
           NFTtransaction.NFTAddress,
         NFTtransaction.to,
         NFTtransaction.NFTid,
         NFTtransaction.NFTExecuted,
         NFTtransaction.numConfirmations 
        );
    }
}