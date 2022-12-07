// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     function ownable_init() internal initializer {
        _transferOwnership(_msgSender());
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File @openzeppelin/contracts/security/[email protected]
// SPDX-License-Identifier: UNLICENSED

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
     
    // it has to be changedto only initializer
    function initializeStatus() internal {
        _status = _NOT_ENTERED;
    }
    // constructor() {
    //     _status = _NOT_ENTERED;
    // }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAdminFunctions {

   function getBaseLtm() external view returns(uint256);

   function getMarginReservePercent() external view returns(uint256);

   function getLiquidationRatio() external view returns(uint256);

   function getMarginCallRatio() external view returns(uint256);
    
   function getProtocolFees() external view returns(uint256);

   function getLiquidationPenalty() external view returns(uint256);

    function getMarginContract() external view returns(address);

    function getMarginFundsContract() external view returns(address);

    function getPositionContract() external view returns(address);

    function getLiquidationReserves() external view returns(address payable);

    function getProtocolReserves() external view returns(address payable);

    function getDelegatorAddress(address assetAddress) external view returns(address);
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMargin {
    // struct Deposit {
    //     uint256 marginAmount;
    //     address assetAddress;
    //     uint256 marginReserve;
    //     uint256 leverage;
    //     uint256 loanAmount;
    //     uint256 repaidLoan;
    //     uint256 interestAccumulated;
    //     uint256 timestamp;
    //     uint256 usedMargin;
    //     uint256 usedLoan;
    //     uint256 lossValue;
    //     uint256 gainValue;
    //     uint256 exitAmount;
    // }
    //function getDepositDetails(address user, address assetAddress) external view returns(Deposit memory);

    function getDepositAmounts(address user, address assetAddress) external view returns(uint256, uint256, uint256, uint256);

    function ltmRatio(address user, address assetAddress) external view returns (uint256);

    function setPositionAmount(address user, address assetAddress, uint256 marginUsed, uint256 loanUsed) external;

    function closePositionAmount(address user, address assetAddress, uint256 marginUsed, uint256 loanUsed, uint256 marginAmount) external;

    function removeMargin(address user, address assetAddress, uint256 marginUsed) external;
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMarginFunds {
    function withdrawFunds(address payable to, uint256 amount) external ;
    function withdrawERC20Tokens(address tokenAddress, address to, uint256 amount) external; 
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

     function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
}

import "./access/ReentrancyGuard.sol";
import "./access/Ownable.sol";
import "./utils/PositionStorage.sol";
import "./interface/IMargin.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IMarginFunds.sol";
import "./interface/IAdminFunctions.sol";
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Position is ReentrancyGuard, Ownable, PositionStorage {
    
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    
    function initialize() public initializer {
        Ownable.ownable_init();
        ReentrancyGuard.initializeStatus();
        precision = 1000000;
        positionID = 1;
        uniswapV2Router = IUniswapV2Router02(0x8954AfA98594b838bda56FE4C12a09D7739D179b);
        tradeDeadline = 5 minutes;
    }

    function updateAdminContract(address _adminContract) external onlyOwner {
        require(
            _adminContract.isContract(),
            "Position: Address is not a contract"
        );
        adminContract = _adminContract;
    }

    //from the received amount of targetToken protocol fees to be deducted
    function createPositionAndTrade(address tokenAddress, address targetToken, uint256 amount) external {
       (uint256 availableMargin,
        uint256 loanAmount,
        ,
        ) = IMargin(IAdminFunctions(adminContract).getMarginContract()).getDepositAmounts(msg.sender, tokenAddress);
        uint256 ltmRatio = IMargin(IAdminFunctions(adminContract).getMarginContract()).ltmRatio(msg.sender, tokenAddress);
        uint256 marginUsed = (precision * amount)/(ltmRatio + precision);
        uint256 loanUsed = amount - marginUsed;

        require(availableMargin >= marginUsed && loanAmount >= loanUsed, "Position: Insufficient amount");
        // Path for quickswap 
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = targetToken;
        if(tokenAddress == address(0)) path[0] = uniswapV2Router.WETH();
        // pair should exist in quickswap
        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            path[0],
            path[1]
        );
        require(pair != address(0), "Position: Invalid Pair");
        // Store trade result and traded price
        (uint256 result, uint256 tradePriceAfterTrade) = trade(amount, path);
        address user = msg.sender;
        IMargin(IAdminFunctions(adminContract).getMarginContract()).setPositionAmount(user, tokenAddress, marginUsed, loanUsed);
        // Store position related details

        positionIDs[positionID] = Position({
            userAddress: msg.sender,
            asset: tokenAddress,
            assetAmount: amount,
            marginUsed: marginUsed,
            loanUsed: loanUsed,
            reverseAmount:0,
            targetAsset: targetToken,
            targetAmount: result,
            tradedPrice: tradePriceAfterTrade,
            timestamp: block.timestamp,
            closedPrice: 0,
            marginPrice: getMarginPrice(
                amount, 
                marginUsed,
                result,
                path
            ),
            liquidationPrice: getLiquidationPrice(
                amount,
                marginUsed,
                result,
                path
            ),
            status: 0,
            marginAdded: 0,
            marginMoved: 0,
            lossValue: 0,
            gainValue: 0
        });
        usersPosition[msg.sender].push(positionID);
        userPositionByAsset[msg.sender][tokenAddress].push(positionID);
        //marginAdded[positionID] = 0;
        positionID++;

    }

    function trade(uint256 tradeAmount, address[] memory path) internal returns(uint256, uint256) {
        uint256[] memory result = new uint256[](2);
        uint256 deadline = block.timestamp + tradeDeadline;
        uint256 decimals = IERC20Metadata(path[0]).decimals();
        uint256[] memory price = uniswapV2Router.getAmountsOut(
            1 * 10**decimals,
            path
        );
        uint256[] memory expectedUnits = uniswapV2Router.getAmountsOut(tradeAmount, path);
        //0.2% of expected units as protocol fees
        uint256 protocolFeePercent = IAdminFunctions(adminContract).getProtocolFees();
        uint256 protocolFees = (expectedUnits[1] * protocolFeePercent) / 10000;
        //expectedUnits is in expectedUnits[1] 
        if(path[0] == uniswapV2Router.WETH()) {
            // Trade and get asset out
            //internalCall to marginFunds
            IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawFunds(payable(address(this)), tradeAmount);
            result = uniswapV2Router.swapExactETHForTokens{value: tradeAmount } (
                0,
                path,
                address(this),
                deadline
            );
        } 
        else if(path[1] == uniswapV2Router.WETH()) {
            IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawERC20Tokens(path[0], address(this), tradeAmount);
            IERC20(path[0]).approve(address(uniswapV2Router), tradeAmount);
            result = uniswapV2Router.swapExactTokensForETH(
                tradeAmount,
                0,
                path,
                address(this),
                deadline
            );
        }
        else {
            IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawERC20Tokens(path[0], address(this), tradeAmount);
            IERC20(path[0]).approve(address(uniswapV2Router), tradeAmount);
            result = uniswapV2Router.swapExactTokensForTokens(
                tradeAmount,
                0,
                path,
                address(this),
                deadline
            );
        }
        price[1] = (getConvertedAmount(decimals, tradeAmount) * (10**18)) / (
            getConvertedAmount(IERC20Metadata(path[1]).decimals(), result[1])
        );
        // //deducting the protocol fees
        result[1] = result[1] - protocolFees;
        //this protocol fees should be transferred to ProtocolReserves contract
        if(path[0] == address(0))
            IAdminFunctions(adminContract).getProtocolReserves().transfer(protocolFees);
        else    
            IERC20(path[0]).transfer(IAdminFunctions(adminContract).getProtocolReserves(), protocolFees);
        return (result[1], price[1]);

    }
    
    function tradeForClosePosition(uint256 tradeAmount, address[] memory path) internal returns(uint256, uint256) {
        uint256[] memory result = new uint256[](2);
        uint256 deadline = block.timestamp + tradeDeadline;
        uint256 decimals = IERC20Metadata(path[0]).decimals();
        uint256[] memory price = uniswapV2Router.getAmountsOut(
            1 * 10**decimals,
            path
        );
        if(path[0] == uniswapV2Router.WETH()) {
            // Trade and get asset out
            result = uniswapV2Router.swapExactETHForTokens{value: tradeAmount } (
                0,
                path,
                address(this),
                deadline
            );
        }
        else if(path[1] == uniswapV2Router.WETH()) {
            IERC20(path[0]).approve(address(uniswapV2Router), tradeAmount);
            result = uniswapV2Router.swapExactTokensForETH(
                tradeAmount,
                0,
                path,
                address(this),
                deadline
            );
        }
        else {
            IERC20(path[0]).approve(address(uniswapV2Router), tradeAmount);
            result = uniswapV2Router.swapExactTokensForTokens(
                tradeAmount,
                0,
                path,
                address(this),
                deadline
            );
        }
        price[1] = (getConvertedAmount(decimals, tradeAmount) * (10**18)) / (
            getConvertedAmount(IERC20Metadata(path[1]).decimals(), result[1])
        );
        return (result[1], price[1]);
    }

    function closePosition(uint256 positionID) external {
        Position storage positionInfo = positionIDs[positionID];
        require(positionInfo.userAddress == msg.sender, "Position: Not the user");
        require(positionInfo.status == 0, "Position: Position Closed");

        address[] memory path = new address[](2);
        path[1] = positionInfo.asset;
        path[0] = positionInfo.targetAsset;
        if(path[1] == address(0)) path[1] = uniswapV2Router.WETH();
        (uint256 _result, ) = tradeForClosePosition(positionInfo.targetAmount, path);
        
        uint256 decimals = IERC20Metadata(path[1]).decimals();
        address[] memory path_ = new address[](2);
        path_[0] = path[1];
        path_[1] = path[0];
        //Get price
        uint256[] memory price = uniswapV2Router.getAmountsOut(
            1 * 10**decimals, path_
        );
        positionInfo.reverseAmount = _result;
        positionInfo.closedPrice = price[1];
        positionInfo.status = 1;

        uint256 temp;
        uint256 marginAmount;
        if(positionInfo.assetAmount >= _result) {
            //loss
            temp = positionInfo.assetAmount - _result;
            positionInfo.lossValue = temp;
            marginAmount = positionInfo.marginUsed - temp;
            
        }
        else {
            //gain
            temp = _result - positionInfo.assetAmount;
            positionInfo.gainValue = temp;
            marginAmount = positionInfo.marginUsed + temp;
        }
        address user = msg.sender;
        IMargin(IAdminFunctions(adminContract).getMarginContract()).closePositionAmount(user, positionInfo.asset, positionInfo.marginUsed ,positionInfo.loanUsed, marginAmount);
        if(positionInfo.asset != address(0)) {
            require(IERC20(positionInfo.asset).balanceOf(address(this)) >= _result, "Position: No balance");
            IERC20(positionInfo.asset).transfer(IAdminFunctions(adminContract).getMarginFundsContract(), _result);
        }
        else {
            require(address(this).balance >= _result, "Position: Less matic balance");
            payable(IAdminFunctions(adminContract).getMarginFundsContract()).transfer(_result);
        }

    }   

    function getConvertedAmount(uint256 _decimals, uint256 _amount)
        public
        pure
        returns (uint256)
    {
        uint256 maxDecimal = 18;
        if (_decimals < maxDecimal) {
            return _amount * (10**(maxDecimal - (_decimals)));
        }
        // if (_decimals == maxDecimal) {
        //     return _amount;
        // }
        return _amount;
    }

    //in case of addMargin amount is in marginFund contract
    function addMargin(uint256 positionID, uint256 marginAmount) external {
        Position storage positionInfo = positionIDs[positionID];
        require(positionInfo.userAddress == msg.sender, "Position: Not the user");
        require(positionInfo.status == 0, "Position: Position Closed");
        (uint256 availableMargin, , 
        , ) = IMargin(IAdminFunctions(adminContract).getMarginContract()).getDepositAmounts(msg.sender, positionInfo.asset);
        require(marginAmount <= availableMargin, "Position: Insufficient margin");
        address user = msg.sender;
        IMargin(IAdminFunctions(adminContract).getMarginContract()).setPositionAmount(user, positionInfo.asset, marginAmount, 0);
        address[] memory path = new address[](2);
        path[0] = positionInfo.asset;
        path[1] = positionInfo.targetAsset;
        positionInfo.marginUsed += marginAmount;
        //positionInfo.assetAmount += marginAmount;
        positionInfo.marginPrice = getMarginPrice(
            positionInfo.assetAmount + marginAmount,
            positionInfo.marginUsed,
            positionInfo.targetAmount,
            path
        );
        positionInfo.liquidationPrice = getLiquidationPrice(
            positionInfo.assetAmount + marginAmount,
            positionInfo.marginUsed,
            positionInfo.targetAmount,
            path
        );
        //marginAdded[positionID] += marginAmount;
        positionInfo.marginAdded += marginAmount;
    }

    function moveMargin(uint256 positionID, uint256 marginAmount) external {
        Position storage positionInfo = positionIDs[positionID];
        require(positionInfo.userAddress == msg.sender, "Position: Not the user");
        require(positionInfo.status == 0, "Position: Position closed");
        //add condition to only if add margin is done
        require(positionInfo.marginAdded >= marginAmount, "Position: Margin not added");
        // (uint256 availableMargin, , 
        // , ) = IMargin(marginContract).getDepositAmounts(msg.sender, positionInfo.asset);
        //require(marginAmount <= availableMargin, "Position: Insufficient margin");
        //require(marginAmount <= positionInfo.marginUsed, "Position: Insufficient margin");
        //uint256 ltmRatio = (positionInfo.loanUsed*precision)/(positionInfo.marginUsed - marginAmount);
        //require(ltmRatio <= 4 * precision, "Position: Position beyond base ltm");
        address user = msg.sender;
        IMargin(IAdminFunctions(adminContract).getMarginContract()).removeMargin(user, positionInfo.asset, marginAmount);
        //need to maintain the ltm ratio for the position
        address[] memory path = new address[](2);
        path[0] = positionInfo.asset;
        path[1] = positionInfo.targetAsset;
        positionInfo.marginUsed -= marginAmount;
        //positionInfo.assetAmount -= marginAmount;
        positionInfo.marginPrice = getMarginPrice(
            positionInfo.assetAmount - marginAmount,
            positionInfo.marginUsed,
            positionInfo.targetAmount,
            path
        );
        positionInfo.liquidationPrice = getLiquidationPrice(
            positionInfo.assetAmount - marginAmount,
            positionInfo.marginUsed,
            positionInfo.targetAmount,
            path
        );
        //mapping for margin removed
        // marginMoved[positionID] += marginAmount;
        // marginAdded[positionID] -= marginAmount;
        positionInfo.marginMoved += marginAmount;
        positionInfo.marginAdded -= marginAmount;

    }

    function getLiquidationPrice(uint256 tradeAmount, uint256 marginAmount, uint256 targetAmount, address[] memory path) public view returns(uint256 liquidationPrice) {
        uint256 assetDecimals = IERC20Metadata(path[0]).decimals();
        uint256 targetDecimals = IERC20Metadata(path[1]).decimals();
        uint256 value = getConvertedAmount(assetDecimals, tradeAmount);
        uint256 convertedMargin = getConvertedAmount(assetDecimals, marginAmount);
        uint256 units = getConvertedAmount(targetDecimals, targetAmount);
        //liquidation Price = (value - 80% of MarginAmount)/units;
        uint256 liquidationRatio = IAdminFunctions(adminContract).getLiquidationRatio();
        uint256 maxLoss = (convertedMargin * liquidationRatio)/100; 
        if(targetDecimals == 18) {
            liquidationPrice = (value - maxLoss)/units;
        }
        else {
            liquidationPrice = ((value - maxLoss)* 10**18)/units;
        }
        return liquidationPrice;
    }

    function getMarginPrice(uint256 tradeAmount, uint256 marginAmount, uint256 targetAmount, address[] memory path) public view returns(uint256 marginPrice) {
        //Assuming
        //margin = 100,
        //marginCallRatio = 70%,
        //maxMarginLoss = 70
        uint256 assetDecimals = IERC20Metadata(path[0]).decimals();
        uint256 targetDecimals = IERC20Metadata(path[1]).decimals();
        uint256 value = getConvertedAmount(assetDecimals, tradeAmount);
        uint256 convertedMargin = getConvertedAmount(assetDecimals, marginAmount);
        uint256 units = getConvertedAmount(targetDecimals, targetAmount);
        //marginCallPrice = (value - 70% of marginAmount)/Units;
        uint256 marginCallRatio = IAdminFunctions(adminContract).getMarginCallRatio();
        uint256 maxMarginLoss = (convertedMargin * marginCallRatio)/100; 
        if(targetDecimals == 18) {
            marginPrice = (value - maxMarginLoss)/units;

        }
        else {
            marginPrice = ((value - maxMarginLoss) * 10**18)/units;
        }
        return marginPrice;
        
    }

    function liquidate(uint256 positionID) external {
        //uint256 _positionId;
        for(uint256 i=1; i< positionID; i++) {
            //Get each position Info
            Position storage positionInfo = positionIDs[i];
            //Get the current price
            address[] memory path = new address[](2);
            path[1] = positionInfo.asset;
            path[0] = positionInfo.targetAsset;
            if(path[1] == address(0)) path[1] = uniswapV2Router.WETH();
            // Should be open position and current price is lesser than liquidation price (80% of traded price)
            if(positionInfo.status == 0 && getCurrentPrice(i) <  positionInfo.liquidationPrice) {

                //here trade should be done
                (uint256 _result, ) = tradeForClosePosition(positionInfo.targetAmount, path);
                //0.02%
                uint256 liquidationPercent = IAdminFunctions(adminContract).getLiquidationPenalty();
                uint256 liquidationPenalty = (_result * liquidationPercent)/10000;
                _result = _result - liquidationPenalty;
                uint256 decimals = IERC20Metadata(path[1]).decimals();
                address[] memory path_ = new address[](2);
                path_[0] = path[1];
                path_[1] = path[0];
                // Get Price
                uint256[] memory price = uniswapV2Router.getAmountsOut(
                    1 * 10**decimals,
                    path_
                );

                // Use this for get absolute value
                // price[1] = (getConvertedAmount(IERC20(path_[0]).decimals(), 1 * 10**decimals).mul(10**18)).div(
                //     getConvertedAmount(IERC20(path_[1]).decimals(), price[1])
                // );

                // Store Traded values
                positionInfo.reverseAmount = _result;
                positionInfo.closedPrice = price[1];
                positionInfo.status = 2;

                uint256 temp;
                uint256 marginAmount;
                if(positionInfo.assetAmount >= _result) {
                    //loss
                    temp = positionInfo.assetAmount - _result;
                    positionInfo.lossValue = temp;
                    marginAmount = positionInfo.marginUsed - temp;
                }
                else {
                    //gain
                    temp = _result - positionInfo.assetAmount;
                    positionInfo.gainValue = temp;
                    marginAmount = positionInfo.marginUsed + temp;
                }
                address user = msg.sender;
                //update the margin and loan values
                IMargin(IAdminFunctions(adminContract).getMarginContract()).closePositionAmount(user, positionInfo.asset, positionInfo.marginUsed, positionInfo.loanUsed, marginAmount);
                if(positionInfo.asset != address(0)) {
                    require(IERC20(positionInfo.asset).balanceOf(address(this)) >= _result, "Position: No balance");
                    IERC20(positionInfo.asset).transfer(IAdminFunctions(adminContract).getMarginFundsContract(), _result);
                }
                else {
                    require(address(this).balance >= _result, "Less matic balance");
                    payable(IAdminFunctions(adminContract).getMarginFundsContract()).transfer(_result);
                }

                // transferring the liquidation penalty to liquidationReserves
                if(path[1] == address(0))
                   IAdminFunctions(adminContract).getLiquidationReserves().transfer(liquidationPenalty);
                else    
                    IERC20(path[1]).transfer(IAdminFunctions(adminContract).getLiquidationReserves(), liquidationPenalty);

                //position is liquidated

            }

        }
    }

    function getCurrentPrice(uint256 _positionID)
        public
        view
        returns (uint256)
    {
        Position storage positionInfo = positionIDs[_positionID];
        address[] memory path = new address[](2);
        path[0] = positionInfo.asset;
        path[1] = positionInfo.targetAsset;

        // Since price should be in same asset
        // Calculate path again and get price
        uint256 decimals = IERC20Metadata(path[0]).decimals();
        // Get Price
        uint256[] memory price = uniswapV2Router.getAmountsOut(
            1 * 10**decimals,
            path
        );
        if (IERC20Metadata(path[1]).decimals() == 18) {
            return ((1 * 10**18) / price[1]);
        } else {
            return ((1 * 10**18 * 10**(18 - IERC20Metadata(path[1]).decimals())) /
                price[1]);
        }
    }

    function getAdminContract() public view returns(address) {
        return adminContract;
    }

    function getPositionDetails(uint256 positionID) public view returns(Position memory) {
        return positionIDs[positionID];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
contract PositionStorage {
    
    struct Position {
        address userAddress;
        address asset;
        uint256 assetAmount; // traded amount
        uint256 marginUsed;
        uint256 loanUsed;
        uint256 reverseAmount; // amount got after closing the trade
        address targetAsset;
        uint256 targetAmount;
        uint256 timestamp;
        uint256 tradedPrice; //entry price
        uint256 closedPrice; //exit price
        uint256 marginPrice;
        uint256 liquidationPrice;
        uint8 status; // 0 for create, 1 for close, 2 for liquidate
        uint256 marginAdded;
        uint256 marginMoved;
        uint256 lossValue;
        uint256 gainValue;
    }


    uint256 internal precision;

    address internal adminContract;

    // Starting position
    uint256 public positionID;
    
    // Trade deadline
    uint256 public tradeDeadline;

    // handles trade position
    mapping(uint256 => Position) internal positionIDs; 

    // Handles array of position id
    mapping(address => uint256[]) public usersPosition;

    // users positions based on deposit token
    mapping(address => mapping(address => uint256[]))
        public userPositionByAsset;

}