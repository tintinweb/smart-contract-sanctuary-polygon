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

    function getMaximillionContract() external view returns(address);

    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICErc20Delegator {
    function borrow(address borrower, address payable holder, uint borrowAmount) external returns(uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns(uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function mint(address minter, uint mintAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function redeemUnderlying(address payable redeemer, uint redeemAmount) external returns (uint);
        
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICEther {
    function borrow(address borrower, address payable holder, uint borrowAmount) external returns(uint);
    function repayBorrowBehalf(address borrower) external payable;
    function borrowBalanceCurrent(address account) external returns (uint);
    function mint(address minter) external payable ;
    function balanceOfUnderlying(address owner) external returns (uint);
    function redeemUnderlying(address payable redeemer, uint redeemAmount) external returns (uint);
        
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMarginFunds {
    function withdrawFunds(address payable to, uint256 amount) external ;
    function withdrawERC20Tokens(address tokenAddress, address to, uint256 amount) external; 
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMaximillion {
    function repayBehalf(address borrower) external payable;
        
}

import "./utils/MarginStorage.sol";
import "./access/ReentrancyGuard.sol";
import "./access/Ownable.sol";
import "./interface/ICErc20Delegator.sol";
import "./interface/ICEther.sol";
import "./interface/IMarginFunds.sol";
import "./interface/IAdminFunctions.sol";
import "./interface/IMaximillion.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

//Issue in withdraw and deposit function need to update it after implementing the interest fn
contract Margin is ReentrancyGuard, MarginStorage, Ownable {
    //Need to add an initialize function
    receive() external payable {}

    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;
    function initialize() public initializer {
        Ownable.ownable_init();
        ReentrancyGuard.initializeStatus();
        precision = 1000000;
    }

    function updateAdminContract(address _adminContract) external onlyOwner {
        require(
            _adminContract.isContract(),
            "Margin: Address is not a contract"
        );
        adminContract = _adminContract;
    }

    modifier onlyPosition() {
        require(msg.sender == IAdminFunctions(adminContract).getPositionContract(), "Margin: Not admin");
    _;
    }

    event Deposited(
        address userAddress,
        address assetAddress,
        uint256 marginAmount,
        uint256 leverage,
        uint256 depositedTime,
        uint256 loanAmount
    );

    event Withdrawn(
        address userAddress,
        address assetAddress,
        uint256 marginAmount
    );

    function deposit(
        address assetAddress,
        uint256 marginAmount,
        uint256 leverage
    ) external payable {
        uint256 maxLeverage = IAdminFunctions(adminContract).getBaseLtm();
        require(marginAmount > 0 && leverage <= maxLeverage, "Margin: Invalid inputs");
        if (assetAddress == address(0)) {
            require(msg.value > 0, "Margin: Invalid inputs");
            marginAmount = msg.value;
            (bool successTransfer, ) = IAdminFunctions(adminContract).getMarginFundsContract().call{
                    value: marginAmount
                }("");
                require(
                    successTransfer,
                    "Margin:Transfer to margin funds contract failed"
                );
        } else {
            IERC20(assetAddress).transferFrom(
                msg.sender,
                IAdminFunctions(adminContract).getMarginFundsContract(),
                marginAmount
            );
        }
        uint256 marginReservePercent = IAdminFunctions(adminContract).getMarginReservePercent();
        uint256 marginReserve = (marginAmount * marginReservePercent) / 100; //marginPercent should be from admin contract

        Deposit storage depositInfo = depositDetails[msg.sender][assetAddress];

        depositInfo.assetAddress = assetAddress;
        depositInfo.marginAmount += (marginAmount - marginReserve);
        depositInfo.marginReserve += marginReserve;
        depositInfo.leverage += leverage;
        address delegator = IAdminFunctions(adminContract).getDelegatorAddress(assetAddress); //delegatorAddresses[assetAddress];
        require(delegator != address(0), "Margin: Not a delegator address");
        uint256 loanAmount = marginAmount * leverage;
        depositInfo.loanAmount += loanAmount;
        //amount is transferred to the margin contract
        //check it here
        if(loanAmount !=0) {
            uint256 success = ICErc20Delegator(delegator).borrow(
                msg.sender,
                payable(IAdminFunctions(adminContract).getMarginFundsContract()),
                loanAmount
            );
            require(success == 0, "Margin: Insufficient loan amount");
        }
        depositInfo.timestamp = block.number;

        emit Deposited(
            msg.sender,
            assetAddress,
            marginAmount,
            leverage,
            block.timestamp,
            loanAmount
        );
    }

    function withdraw(address assetAddress, uint256 amountToWithdraw)
        external
        payable
        nonReentrant
    {
        Deposit storage depositInfo = depositDetails[msg.sender][assetAddress];
        uint256 maxWithdrawAmount = maxWithdraw(msg.sender, assetAddress);
        require(
            amountToWithdraw <= maxWithdrawAmount,
            "Margin: Withdraw less amount"
        );
        //Reduce withdraw amount from deposit both from the marginReserve and the marginAmount
        uint256 loanAmount = depositInfo.loanAmount + depositInfo.usedLoan;
        if(loanAmount == 0) {
            if(depositInfo.marginAmount >= amountToWithdraw)
            depositInfo.marginAmount -= amountToWithdraw;
            else {
                uint256 amountLeft = amountToWithdraw - depositInfo.marginAmount;
                depositInfo.marginAmount = 0;
                if(depositInfo.marginReserve >= amountLeft)
                    depositInfo.marginReserve -= amountLeft;
                else
                    depositInfo.marginReserve = 0;
            }
            //depositInfo.marginAmount = 0;
        }
        else {
            depositInfo.marginAmount -= amountToWithdraw;
        }
        // Reset deposit after full withdraw
        // if(depositInfo.marginAmount + depositInfo.marginReserve == 0)

        if (assetAddress == address(0)) {
            //internal call to marginFunds
            IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawFunds(payable(address(this)), amountToWithdraw); //send directly to user
            payable(msg.sender).transfer(amountToWithdraw); //.call
        }
        else {
            //internal call to marginFundsContract
            IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawERC20Tokens(assetAddress, address(this), amountToWithdraw);
            IERC20(assetAddress).transfer(msg.sender, amountToWithdraw);
        }
        emit Withdrawn(msg.sender, assetAddress, amountToWithdraw);
    }

    function maxWithdraw(address user, address assetAddress)
        public
        view
        returns (uint256)
    {
        Deposit storage depositInfo = depositDetails[user][assetAddress];
        //if both are zero
        if (depositInfo.marginAmount + depositInfo.marginReserve == 0) return 0;
        uint256 loanAmount = depositInfo.loanAmount + depositInfo.usedLoan;
        uint256 totalMargin;
        if(loanAmount == 0) {
        totalMargin = depositInfo.marginAmount +
            depositInfo.marginReserve;
        }
        else {
         totalMargin = depositInfo.marginAmount;
        }
        uint256 maxLeverage = IAdminFunctions(adminContract).getBaseLtm();
        uint256 maxWithdrawAmount = (maxLeverage * totalMargin - loanAmount) / maxLeverage;
        return maxWithdrawAmount;
    }

    function borrow(address assetAddress, uint256 borrowAmount)
        external payable
        nonReentrant
    {
        Deposit storage depositInfo = depositDetails[msg.sender][assetAddress];
        uint256 maxBorrowAmount = maxBorrow(msg.sender, assetAddress);
        require(borrowAmount > 0, "Margin: Borrow amount must be greater than zero");
        require(
            maxBorrowAmount >= borrowAmount,
            "Margin: Cannot give more loan"
        );
        address delegator = IAdminFunctions(adminContract).getDelegatorAddress(assetAddress); //delegatorAddresses[assetAddress];
        require(delegator != address(0), "Margin: Not a delegator address");
        //here the amount is getting transferred to the margin funds contract address(not to user address),
        uint256 success = ICErc20Delegator(delegator).borrow(
            msg.sender,
            payable(IAdminFunctions(adminContract).getMarginFundsContract()),
            borrowAmount
        );
        require(success == 0, "Margin: Borrow failed");

        depositInfo.loanAmount += borrowAmount;
    }

    //function for returning maxBorrowAmount
    function maxBorrow(address user, address assetAddress)
        public
        view
        returns (uint256)
    {
        Deposit storage depositInfo = depositDetails[user][assetAddress];
        require(depositInfo.marginAmount > 0, "Margin: Insufficient deposit");
        uint256 totalMargin = depositInfo.marginAmount + depositInfo.marginReserve + depositInfo.usedMargin; 
        uint256 loanAmount = depositInfo.loanAmount + depositInfo.usedLoan;
        uint256 maxLeverage = IAdminFunctions(adminContract).getBaseLtm();
        uint256 maxBorrowAmount = maxLeverage * totalMargin - loanAmount;

        return maxBorrowAmount;
    }

    //source = 1 , ltmRatio for wallet
    //source = 2 , ltmRatio for createPosition
    function ltmRatio(address user, address assetAddress, uint256 source)
        public
        view
        returns (uint256)
    {
        Deposit storage depositInfo = depositDetails[user][assetAddress];
        uint256 totalMargin;
        uint256 loanAmount;
        if(source == 1) {
            totalMargin = depositInfo.marginAmount + depositInfo.marginReserve + depositInfo.usedMargin;
            loanAmount = depositInfo.loanAmount + depositInfo.usedLoan;
        }
        else {
            totalMargin = depositInfo.marginAmount;
            loanAmount = depositInfo.loanAmount;

        }
        if (totalMargin == 0) return 0;
        return (loanAmount * precision) / totalMargin;
    }

    // Add extra param -> max (bool)
    // if max is true = 
        // in repayBorrowBehalf pass inputs as uint(-1)
        // make the interest zero. and loan amount zero
    // if max is false
        // continue with same     
    // source = 1, from external wallet
    // source = 2, from margin Account
    function repay(
        address assetAddress,
        uint256 repayAmount,
        uint256 source,
        bool max
    ) external payable {
        Deposit storage depositInfo = depositDetails[msg.sender][assetAddress];
        address delegator = IAdminFunctions(adminContract).getDelegatorAddress(assetAddress);
        require(delegator != address(0), "Margin: Not a delegator address");
        // address maximillionContract = IAdminFunctions(adminContract).getMaximillionContract();
        uint256 maxRepayAmount = maxRepay(msg.sender, assetAddress); 
         (uint256 repayLoanAmount, 
            uint256 repayInterestAmount) = loanToInterest(msg.sender, assetAddress);
            depositInfo.interestAccumulated = repayInterestAmount;
            uint256 loanAmount;
            uint256 interestAmount;
        if(max == false) {
            if(repayInterestAmount !=0) {
                uint256 ltiRatio = (repayLoanAmount * precision)/depositInfo.interestAccumulated;
                (loanAmount, interestAmount) = getAmount(repayAmount, ltiRatio);
            }
            else {
                loanAmount = repayAmount;
            }
            depositInfo.loanAmount -= loanAmount;
            depositInfo.repaidLoan += loanAmount;
            depositInfo.interestAccumulated -= interestAmount;
        }
        else {
            require(depositInfo.usedLoan == 0, "Margin: Excess repay");
            
            // if(repayAmount >= maxRepayAmount ) {
            //         repayAmount = repayAmount - maxRepayAmount;
            //         depositInfo.repaidLoan += repayAmount;
            //         depositInfo.loanAmount = (loanAmount) - repayAmount;
            //         depositInfo.interestAccumulated -= interestAmount;
            // }
            // else {
                depositInfo.repaidLoan += depositInfo.loanAmount ;
                depositInfo.loanAmount = 0;
                depositInfo.interestAccumulated = 0;
            //}
        }
        if (source == 1) {
            if (assetAddress == address(0)) {
                repayAmount = msg.value;
                
                if(max == true) {
                    // repayAmount = type(uint256).max;
                    repayAmount = ICErc20Delegator(delegator).borrowBalanceCurrent(msg.sender);
                }
                ICEther(delegator).repayBorrowBehalf{
                    value: repayAmount
                }(msg.sender);
                // IMaximillion(maximillionContract).repayBehalf{
                //         value: repayAmount
                //     }(msg.sender);
            } else {
                //amount is getting transferred to the contract
                if(max == true) {
                    repayAmount = ICErc20Delegator(delegator).borrowBalanceCurrent(msg.sender);
                }
                IERC20(assetAddress).transferFrom(
                    msg.sender,
                    address(this),
                    repayAmount
                );
                IERC20(assetAddress).approve(delegator, type(uint256).max);
                //repay = loan + interest;
                if(max == true) {
                    repayAmount = type(uint256).max;
                }
                uint256 success = ICErc20Delegator(delegator).repayBorrowBehalf(
                    msg.sender,
                    repayAmount
                );
                require(success == 0, "Margin: Repay failed");
            }
        }
        //using the margin account
        else {
            require(
                depositInfo.marginAmount >= repayAmount,
                "Margin: Insufficient Margin"
            );
            if(maxRepayAmount >= ICErc20Delegator(delegator).borrowBalanceCurrent(msg.sender) && max == true) {
                repayAmount = ICErc20Delegator(delegator).borrowBalanceCurrent(msg.sender);
                if(assetAddress == address(0)) {
                    IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawFunds(payable(address(this)), repayAmount);
                    //uint256 maxValue = type(uint256).max;
                    ICEther(delegator).repayBorrowBehalf{
                        value: repayAmount
                    }(msg.sender);
                    // IMaximillion(maximillionContract).repayBehalf{
                    //     value: maxValue
                    // }(msg.sender);
                }
                else {
                    IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawERC20Tokens(assetAddress, address(this), repayAmount);
                    uint256 maxValue = type(uint256).max;
                    IERC20(assetAddress).approve(delegator, maxValue);
                    
                    uint256 success = ICErc20Delegator(delegator).repayBorrowBehalf(
                        msg.sender,
                        maxValue
                    );
                    require(success == 0, "Margin: Repay failed");
                }
            }
            else {
                // require(
                //     repayAmount <= maxRepayAmount,
                //     "Margin: Insufficient margin balance"
                // );
                if(repayAmount > maxRepayAmount ) {
                    repayAmount = repayAmount - maxRepayAmount;

                }
                if(assetAddress == address(0)) {
                    IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawFunds(payable(address(this)), repayAmount);
                    ICEther(delegator).repayBorrowBehalf{
                        value: repayAmount
                    }(msg.sender);
                    //maximillion contract
                    // IMaximillion(maximillionContract).repayBehalf{
                    //     value: repayAmount
                    // }(msg.sender);

                }
                else {
                    IMarginFunds(IAdminFunctions(adminContract).getMarginFundsContract()).withdrawERC20Tokens(assetAddress, address(this), repayAmount);
                    IERC20(assetAddress).approve(delegator, repayAmount);
                    uint256 success = ICErc20Delegator(delegator).repayBorrowBehalf(
                        msg.sender,
                        repayAmount
                    );
                    require(success == 0, "Margin: Repay failed");
                }

            }
            depositInfo.marginAmount -= repayAmount;
        }
    }

    //marginAmount = 12
    //maxRepay = 15 > borrowBalance
    function maxRepay(address user, address assetAddress)
        public
        returns (uint256)
    {
        Deposit storage depositInfo = depositDetails[user][assetAddress];
        uint256 totalMargin = depositInfo.marginAmount;
        (uint256 loanAmount, 
        uint256 interestAmount) = loanToInterest(user, assetAddress);
        //uint256 loanAmount = depositInfo.loanAmount + depositInfo.usedLoan;
        uint256 maxLeverage = IAdminFunctions(adminContract).getBaseLtm();
        uint256 maxRepayAmount = (maxLeverage * totalMargin - (loanAmount + interestAmount)) / (maxLeverage - 1);
        return maxRepayAmount;
    }

    function getDepositDetails(address user, address assetAddress) public view returns(Deposit memory) {
        return depositDetails[user][assetAddress];
    }
    
    function getDepositAmounts(address user, address assetAddress)
        public
        view
        returns (
            uint256 marginAmount,
            uint256 loanAmount,
            uint256 usedMargin,
            uint256 usedLoan
        )
    {
        Deposit memory depositInfo = depositDetails[user][assetAddress];
        marginAmount = depositInfo.marginAmount;
        loanAmount = depositInfo.loanAmount;
        usedMargin = depositInfo.usedMargin;
        usedLoan = depositInfo.usedLoan;
        return (marginAmount, loanAmount, usedMargin, usedLoan);
    }

    function setPositionAmount(address user, address assetAddress, uint256 marginUsed, uint256 loanUsed, uint256 source) public onlyPosition {
        Deposit storage depositInfo = depositDetails[user][assetAddress];
        if(source == 1) {
            depositInfo.usedMargin += marginUsed;
        }
        else {    
            depositInfo.usedMargin += marginUsed;
            depositInfo.usedLoan += loanUsed;
            depositInfo.marginAmount -= marginUsed;
            depositInfo.loanAmount -= loanUsed;
        }
    }

    function removeMargin(address user, address assetAddress, uint256 marginUsed) public onlyPosition {
        Deposit storage depositInfo = depositDetails[user][assetAddress];
        depositInfo.usedMargin -= marginUsed;
        depositInfo.marginAmount += marginUsed;
    }

    function closePositionAmount(address user, address assetAddress, uint256 marginUsed, uint256 loanUsed, uint256 marginAmount) public onlyPosition {
        Deposit storage depositInfo = depositDetails[user][assetAddress];
        
        depositInfo.usedMargin -= marginUsed;
        depositInfo.usedLoan -= loanUsed;
        depositInfo.marginAmount += marginAmount;
        depositInfo.loanAmount += loanUsed;
    } 

    function loanToInterest(address user, address assetAddress) public returns(uint256, uint256) {
        Deposit storage depositInfo = depositDetails[user][assetAddress];
        address delegator = IAdminFunctions(adminContract).getDelegatorAddress(assetAddress);
        uint256 compoundBorrow = ICErc20Delegator(delegator).borrowBalanceCurrent(user);
        uint256 interestAccumulated = compoundBorrow - depositInfo.loanAmount;
        return (depositInfo.loanAmount, interestAccumulated);
    }

    function getAmount(uint256 repayAmount, uint256 ltiRatio) public view returns(uint256, uint256) {
        uint256 loanAmount = ((ltiRatio * repayAmount) / (ltiRatio + precision));
        uint256 interestAmount = repayAmount - loanAmount;
        return (loanAmount, interestAmount);
    }

    function getAdminContract() public view returns(address) {
        return adminContract;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract MarginStorage {
    
    uint256 internal precision;

    address internal adminContract;
    
    struct Deposit {
        uint256 marginAmount;
        address assetAddress;
        uint256 marginReserve;
        uint256 leverage;
        uint256 loanAmount;
        uint256 repaidLoan;
        uint256 interestAccumulated;
        uint256 timestamp;
        uint256 usedMargin;
        uint256 usedLoan;
        uint256 lossValue;
        uint256 gainValue;
        uint256 exitAmount;
    }

    mapping(address => mapping(address => Deposit)) public depositDetails;

    // mapping (address => address) public delegatorAddresses;
    
    mapping(address => mapping(address => uint256)) internal totalInterest;    
   
}