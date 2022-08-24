/**
 *Submitted for verification at polygonscan.com on 2022-08-23
*/

/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.12;

enum PoolTypes {
    FIX_PRICE,
    UNISWAP_V2
}



/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

////import "../token/ERC20/IERC20.sol";




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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
}




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
pragma solidity ^0.8.12;

interface IUniswapV2{
    function addLiquidity(uint256 _dataToken, uint256 _tAmountDesired, uint256 _tAmountMin, uint256 _nAmountDesired, uint256 _nAmountMin ) external returns( uint256, uint256, uint256);
    function swapTokens(uint256 _dataToken, uint256 _amountIn, uint256 _amountOutMin, address _to, uint256 _deadline) external;
    function addDataToken(address _erc20address, address _erc721Address, uint256 _dataTokenId) external;
}




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
pragma solidity ^0.8.12;

interface IFixPrice{
    function buyToken(uint256 _dataToken, uint256 _amount, address _owner, address _buyer) external returns (bool _success);
    function addDataToken(address _erc20address, address _erc721Address, uint256 _tokensPerUnit, uint256 _dataTokenId) external;
}




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

////import "../utils/Utils.sol";
interface INVG8Marketplace {

    function enlistDataToken(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _usagePrice,
        PoolTypes _poolType
    ) external returns (uint256);
}




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
pragma solidity ^0.8.12;

////import "@openzeppelin/contracts/interfaces/IERC20.sol";
interface IERC20Template is IERC20{
    function initialize(string memory name_, string memory symbol_, address _owner, uint256 _totalSupply) external;
    function decimals() external view returns (uint8);
}



/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
pragma solidity ^0.8.12;

////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Template is IERC721{
    function initialize(string memory name_, string memory symbol_, address _owner, string memory _uri) external;
}



/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

////import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}




/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
            
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


/** 
 *  SourceUnit: /home/talha/Navigate Contracts/contracts/NVG8Factory.sol
*/
pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/proxy/Clones.sol";
////import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// ////import "@openzeppelin/contracts/access/Ownable.sol";
// ////import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
////import "./interfaces/IERC721Template.sol";
////import "./interfaces/IERC20Template.sol";
////import "./interfaces/INVG8Marketplace.sol";
////import "./interfaces/pools/IFixPrice.sol";
////import "./interfaces/pools/IUniswapV2.sol";
////import "./utils/Utils.sol";

contract NVG8Factory is Initializable {
    // EVENTS
    event TemplateAdded(TemplateType _type, address _template);
    event TemplateRemoved(TemplateType _type, address _template);
    event TemplateStatusChanged(
        TemplateType _type,
        address _template,
        bool _status
    );
    event DataTokenCreated(
        address _erc721Token,
        address _erc20Token,
        uint256 dataTokenId,
        address _owner,
        string _name,
        string _symbol,
        uint256 _totalSupply
        // string _uri
    );
    event poolAdded(PoolTypes _poolType, address _poolAddress);
    event poolRemoved(PoolTypes _poolType);

    // ENUM
    enum TemplateType {
        ERC721,
        ERC20
    }

    // STRUCTS
    struct Template {
        address templateAddress;
        bool isActive;
        TemplateType templateType;
    }
    struct DataToken {
        address erc721Token;
        address erc20Token;
        address owner;
        string name;
        string symbol;
        uint256 usagePrice;
    }

    // STATE VARIABLES
    mapping(uint256 => Template) public templates;
    address public nvg8Marketplace;
    bool private initialized;
    address public owner;
    mapping(PoolTypes => address) public poolAddresses; // stores the address of the pricing pools like Uniswap and fix price etc

    // MODIFIERS
    //Modifier onlyMarketplaceOrOwner
    modifier onlyMarketplaceOrOwner() {
        require(
            msg.sender == nvg8Marketplace || msg.sender == owner,
            "Only marketplace or factory can do this"
        );
        _;
    }

    //Modifier onlyOwner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this");
        _;
    }

    // INITIALIZER FUNCTIONS
    function initialize() public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        owner = msg.sender;
    }

    constructor() {}

    // TEMPLATE FUNCTIONS
    /**
     * @notice Add a new template to the factory
     * @dev Add a `Template` struct in `templates` mapping with `_index` as key.
     * @param _type The type of the template to be added.
     * @param _template The address of the template to be added.
     * @param _index The index of the template to be added.
     * @dev Emit the `TemplateAdded` event.
     */
    function createTemplate(
        TemplateType _type,
        address _template,
        uint256 _index
    ) public onlyOwner {
        require(
            templates[_index].templateAddress == address(0),
            "Template already exists"
        );

        templates[_index] = Template({
            templateAddress: _template,
            isActive: true,
            templateType: _type
        });

        emit TemplateAdded(_type, _template);
    }

    /**
     * @notice Remove a template from the factory
     * @dev it just delete the template from the `templates` mapping againsts the `_index` key.
     * @param _index The index of the template to be removed.
     * @dev Emit the `TemplateRemoved` event.
     */
    function removeTemplate(uint256 _index) public onlyOwner {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        emit TemplateRemoved(
            templates[_index].templateType,
            templates[_index].templateAddress
        );

        delete templates[_index];
    }

    /**
     * @notice Change the status of a template
     * @dev Set the `isActive` field of the template against the `_index` key to `_status`.
     * @param _index The index of the template to be changed.
     * @param _status The new status of the template.
     * @dev Emit the `TemplateStatusChanged` event.
     */
    function changeTemplateStatus(uint256 _index, bool _status)
        public
        onlyOwner
    {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        templates[_index].isActive = _status;

        emit TemplateStatusChanged(
            templates[_index].templateType,
            templates[_index].templateAddress,
            _status
        );
    }

    /**
     * @notice Add a new pricing pool address to the factory
     * @dev Add a new pricing pool address to the `poolAddresses` mapping againsts the `_poolType` key.
     * @param _poolType The type of the pricing pool to be added.
     * @param _poolAddress The address of the pricing pool to be added.
     * @dev Emit the `PoolAdded` event.
     */
    function addPoolAddress(PoolTypes _poolType, address _poolAddress)
        public
        onlyOwner
    {
        require(_poolAddress != address(0), "Pool address is not valid");
        require(poolAddresses[_poolType] == address(0), "Pool already exists"); // ? Should we allow Owner to update the pool address?

        poolAddresses[_poolType] = _poolAddress;

        emit poolAdded(_poolType, _poolAddress);
    }

    /**
     * @notice Remove a pricing pool address from the factory
     * @dev it just delete the pricing pool address from the `poolAddresses` mapping againsts the `_poolType` key.
     * @param _poolType The type of the pricing pool to be removed.
     * @dev Emit the `PoolRemoved` event.
     */
    function removePoolAddress(PoolTypes _poolType) public onlyOwner {
        require(poolAddresses[_poolType] != address(0), "Pool does not exist");
        delete poolAddresses[_poolType];

        emit poolRemoved(_poolType);
    }

    function getPoolAddress(PoolTypes _poolType)
        external
        view
        returns (address)
    {
        return poolAddresses[_poolType];
    }

    /**
     * @notice Create a new data token
     * @dev Create a new data token with the given parameters, it's an internal function.
     * @param _ERC721TemplateIndex The index of the ERC721 template to be used.
     * @param _ERC20TemplateIndex The index of the ERC20 template to be used.
     * @param _name The name of the data token.
     * @param _symbol The symbol of the data token.
     * @param _uri The URI of the data token.
     * @param _totalSupply The total supply of the data token.
     * @param _poolType The type of the pricing pool to be used.
     * @dev Emit the `DataTokenCreated` event.
     * @return The erc721 address of the new data token.
     * @return The erc20 address of the new data token.
     * @return The data token Id of the new data token.
     */
    function _createDataToken(
        uint256 _ERC721TemplateIndex,
        uint256 _ERC20TemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSupply,
        PoolTypes _poolType
    )
        internal
        returns (
            address,
            address,
            uint256
        )
    {
        require(
            templates[_ERC721TemplateIndex].templateAddress != address(0) &&
                templates[_ERC721TemplateIndex].isActive &&
                templates[_ERC721TemplateIndex].templateType ==
                TemplateType.ERC721,
            "ERC721 template does not exist or is not active"
        );

        require(
            templates[_ERC20TemplateIndex].templateAddress != address(0) &&
                templates[_ERC20TemplateIndex].isActive &&
                templates[_ERC20TemplateIndex].templateType ==
                TemplateType.ERC20,
            "ERC20 template does not exist or is not active"
        );

        require(
            nvg8Marketplace != address(0),
            "NVG8 Marketplace does not exist"
        );

        // clone ERC721Template
        address erc721Token = Clones.clone(
            templates[_ERC721TemplateIndex].templateAddress
        );

        // clone ERC20Template
        address erc20Token = Clones.clone(
            templates[_ERC20TemplateIndex].templateAddress
        );

        // initialize erc721Token
        IERC721Template(erc721Token).initialize(
            _name,
            _symbol,
            msg.sender,
            _uri
        );

        // initialize erc20Token
        IERC20Template(erc20Token).initialize(
            _name,
            _symbol,
            msg.sender,
            _totalSupply
        );

        uint256 dataTokenId = enlistDataTokenOnMarketplace(
            erc721Token,
            erc20Token,
            msg.sender,
            _name,
            _symbol,
            1,
            _poolType
        );

        emit DataTokenCreated(
            erc721Token,
            erc20Token,
            dataTokenId,
            msg.sender,
            _name,
            _symbol,
            _totalSupply
        );

        return (erc721Token, erc20Token, dataTokenId);
    }

    /**
     * @notice Create a new data token with fixed price
     * @dev This funtion will create a Fixed price data token.
     * @param _ERC721TemplateIndex The index of the ERC721 template to be used.
     * @param _ERC20TemplateIndex The index of the ERC20 template to be used.
     * @param _name The name of the data token.
     * @param _symbol The symbol of the data token.
     * @param _uri The URI of the data token.
     * @param _totalSupply The total supply of the data token.
     * @param _tokensPerUnit The nvg8 tokens per unit of the data token.
     */
    function createDataTokenWithFixedPrice(
        uint256 _ERC721TemplateIndex,
        uint256 _ERC20TemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSupply,
        uint256 _tokensPerUnit
    ) public {
        (
            address erc721Token,
            address erc20Token,
            uint256 dataTokenId
        ) = _createDataToken(
                _ERC721TemplateIndex,
                _ERC20TemplateIndex,
                _name,
                _symbol,
                _uri,
                _totalSupply,
                PoolTypes.FIX_PRICE
            );

        require(
            poolAddresses[PoolTypes.FIX_PRICE] != address(0),
            "Fixed Price Pool does not exist"
        );

        IFixPrice(poolAddresses[PoolTypes.FIX_PRICE]).addDataToken(
            erc20Token,
            erc721Token,
            _tokensPerUnit,
            dataTokenId
        );
    }

    /**
     * @notice Create a new data token with dynamic price, using UniswapV2 as the pricing pool.
     * @dev This funtion will create a Dynamic price data token, and will use UniswapV2 as the pricing pool.
     * @param _ERC721TemplateIndex The index of the ERC721 template to be used.
     * @param _ERC20TemplateIndex The index of the ERC20 template to be used.
     * @param _name The name of the data token.
     * @param _symbol The symbol of the data token.
     * @param _uri The URI of the data token.
     * @param _totalSupply The total supply of the data token.
     */
    function createDataTokenWithUniswapV2(
        uint256 _ERC721TemplateIndex,
        uint256 _ERC20TemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSupply
    ) public {
        (
            address erc721Token,
            address erc20Token,
            uint256 dataTokenId
        ) = _createDataToken(
                _ERC721TemplateIndex,
                _ERC20TemplateIndex,
                _name,
                _symbol,
                _uri,
                _totalSupply,
                PoolTypes.UNISWAP_V2
            );
        require(
            poolAddresses[PoolTypes.UNISWAP_V2] != address(0),
            "UniswapV2 pool does not exist"
        );

        IUniswapV2(poolAddresses[PoolTypes.UNISWAP_V2]).addDataToken(
            erc20Token,
            erc721Token,
            dataTokenId
        );
    }

    /**
     * @notice Set the nvg8 marketplace address.
     * @dev This function will set the nvg8 marketplace address.
     * @param _marketplace The nvg8 marketplace address.
     */
    function setMarketplace(address _marketplace) public onlyOwner {
        nvg8Marketplace = _marketplace;
    }

    /**
     * @notice Enlist a data token on the nvg8 marketplace.
     * @dev This function will enlist a data token on the nvg8 marketplace, it's a private function.
     * @param _erc721Token The ERC721 token address.
     * @param _erc20Token The ERC20 token address.
     * @param _owner The owner of the data token.
     * @param _name The name of the data token.
     * @param _symbol The symbol of the data token.
     * @param _usagePrice The usage price of the data token.
     * @param _poolType The pool type of the data token.
     * @return The data token id.
     */
    function enlistDataTokenOnMarketplace(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _usagePrice,
        PoolTypes _poolType
    ) private returns (uint256) {
        require(nvg8Marketplace != address(0), "Nvg8 Marketplace is not set");
        // TODO: is valid ERC721 & ERC20 token
        //! Can only be Validated from the web3.js

        uint256 dataTokenId = INVG8Marketplace(nvg8Marketplace).enlistDataToken(
            _erc721Token,
            _erc20Token,
            _owner,
            _name,
            _symbol,
            _usagePrice,
            _poolType
        );
        // require(dataTokenId > 0, "Failed to enlist data token on marketplace");
        return dataTokenId;
    }
}

// Todo: how to manage who can use the token?
// Todo: add tests
// Todo: add documentation