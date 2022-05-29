/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

// File: contracts/libraries/XSCUtility.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

abstract contract XSCUtility {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // some useful function
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function stringEqual(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function recover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), _v, _r, _s);
        return signer;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // some math functions
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

// File: contracts/libraries/XSCOwnable.sol


pragma solidity =0.8.2;

abstract contract XSCOwnable {
    address private  _owner;

    address private  _admin;

    address private  _funder;

    bool    private  _switch;

    // Emit an event when the admin is changed
    event AdminChangeSwitch(bool indexed previousSwitch, bool indexed newSwitch);

    // Emit an event when the admin is changed
    event OwnerChangeAdmin(address indexed previousAdmin, address indexed newAdmin);

    // Emit an event when the funder is changed
    event OwnerChangeFunder(address indexed previousFunder, address indexed newFunder);

    // Emit an event when the owner is changed
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function initOwnable() internal {
        _switch= true;
        _owner = msg.sender;
        _admin = msg.sender;
        _funder= msg.sender;

        emit AdminChangeSwitch(false, true);
        emit OwnerChangeAdmin(address(0), _admin);
        emit OwnerChangeFunder(address(0), _funder);
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable/Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Ownable/Not admin");
        _;
    }

    modifier onlyFunder() {
        require(msg.sender == _funder, "Ownable/Not funder");
        _;
    }

    modifier switchOn() {
        require(_switch, "Ownable/switched-off");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function funder() public view returns (address) {
        return _funder;
    }

    function isOwner() public view returns(bool) {
        return (msg.sender == _owner);
    }

    function isAdmin() public view returns(bool) {
        return (msg.sender == _admin);
    }

    function isFunder() public view returns(bool) {
        return (msg.sender == _funder);
    }

    function isSwitch() public view returns(bool) {
        return _switch;
    }

    function changeAdmin(address newAdmin) onlyOwner external {
        require(newAdmin != address(0), "Ownable/Zero-address");

        emit OwnerChangeAdmin(_admin, newAdmin);
        _admin = newAdmin;
    }

    function changeFunder(address newFunder) onlyOwner external {
        require(newFunder != address(0), "Ownable/Zero-address");

        emit OwnerChangeFunder(_funder, newFunder);
        _funder = newFunder;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable/Zero-address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function changeSwitch(bool newSwitch) onlyAdmin external {
        if (_switch != newSwitch) {
            emit AdminChangeSwitch(_switch, newSwitch);
            _switch = newSwitch;
        }
    }
}

// File: contracts/MultiSignCore.sol


pragma solidity =0.8.2;


/**
 * @title Used for multiple signatures of witnesses
 */
contract MultiSignCore is XSCOwnable, XSCUtility {
    // Witness addresses
    mapping(address => bool) public witnessMap;
    address[]                public witnessAll;
    uint256                  public requiredSigners;

    event RequiredChanged(uint256 indexed _old, uint256 indexed _new);
    event WitnessAdded(address indexed _addrs, uint256 indexed _required, address[] all);
    event WitnessDropped(address indexed _addrs, uint256 indexed _required, address[] all);

    function initMultiSignCore() internal {
        XSCOwnable.initOwnable();
    }

    modifier onlyWitness() {
        require(witnessMap[msg.sender], "MultiSignCore/Not-Witness");
        _;
    }

    function isWitness() public view returns (bool) {
        return witnessMap[msg.sender];
    }

    function isWitness(address witness) public view returns (bool) {
        return witnessMap[witness];
    }

    function checkWitnessSignature(bytes32 _hash, uint8[] calldata _v, bytes32[] calldata _r, bytes32[] calldata _s) view public returns (bool) {
        if ((_v.length != _r.length) || (_r.length != _s.length) || (_v.length < requiredSigners)) {
            return false;
        }

        uint validCount = 0;
        address[] memory signers = new address[](_v.length);
        for (uint i = 0; i < _v.length; i++) {
            address signer = recover(_hash, _v[i], _r[i], _s[i]);
            require(isWitness(signer), "MultiSignCore/invalid-signer");

            for (uint j = 0; j < i; j++) {
                if (signers[j] == signer) {
                    return false;
                }
            }

            validCount++;
            signers[i] = signer;
            if (validCount >= requiredSigners) {
                return true;
            }
        }

        return false;
    }

    function addWitness(address[] calldata adds) public onlyOwner {
        require(adds.length > 0, "MultiSignCore/null-address" );

        for (uint i = 0; i < adds.length; i++) {
            require(adds[i] != address(0), "MultiSignCore/address-0");
            require(witnessMap[adds[i]] == false, "MultiSignCore/witness-exists");

            witnessMap[adds[i]] = true;
            witnessAll.push(adds[i]);
        }

        uint256 least = witnessAll.length/2 + 1;
        if (requiredSigners < least) {
            requiredSigners = least;
        }

        emit WitnessAdded(adds[0], requiredSigners, adds);
    }

    function dropWitness(address[] calldata adds) external onlyOwner {
        require(adds.length > 0, "MultiSignCore/null-address");

        for (uint i = 0; i < adds.length; i++) {
            require(witnessMap[adds[i]] == true, "MultiSignCore/witness-not-exists");

            delete(witnessMap[adds[i]]);
            _removeWitness(adds[i]);
        }

        if ( requiredSigners > witnessAll.length ) {
            requiredSigners = witnessAll.length;
        }

        emit WitnessDropped(adds[0], requiredSigners, adds);
    }

    function setRequired(uint8 _new) public onlyOwner {
        require(_new > (witnessAll.length/2) && _new <= witnessAll.length, "MultiSignCore/required-invalid");

        emit RequiredChanged(requiredSigners, _new);
        requiredSigners = _new;
    }

    function _removeWitness(address addr) internal {
        (uint index, bool isHas) = _addressIndex(addr);
        if (isHas) {
            _removeAtIndex(index);
        }
    }

    function _addressIndex(address addr) view internal returns (uint index, bool isHas) {
        for (uint i = 0; i< witnessAll.length; i++) {
            if (addr == witnessAll[i]) {
                index = i;
                isHas = true;
                break;
            }
        }
    }

    function _removeAtIndex(uint index) internal {
        require (0 < witnessAll.length);
        require (index < witnessAll.length);

        uint lastIndex = witnessAll.length - 1;
        if (index < lastIndex) {
            witnessAll[index] = witnessAll[lastIndex];
        }

        witnessAll.pop();
    }
}

// File: contracts/CCBase.sol


pragma solidity =0.8.2;

/**
 * @dev Contract module which provides a base to CCSource and CCTarget, major part is taken from Ownable which is
 * initializable. Since upgradable contract can't link external library, move several functions from Util.sol to here.
 */
abstract contract CCBase is MultiSignCore {
    // No. of lock event emitted by the contract
    uint256 internal _eventNonce;

    // Only initialize once
    function initCCBase() internal {
        MultiSignCore.initMultiSignCore();
        _eventNonce = 0;
    }

    /**
     * @dev revert when fallback called.
     */
    receive () payable external {
        revert("CCBase/call-lockAsset");
    }

    fallback () payable external {
        revert("CCBase/call-lockAsset");
    }

    /**
     * @dev Returns current event nonce.
     */
    function eventNonce() public view returns (uint256) {
        return _eventNonce;
    }
}

// File: contracts/libraries/openzeppelin-v4.6.0/contracts/token/ERC20/IERC20.sol


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

// File: contracts/libraries/XSCERC20Safe.sol


pragma solidity =0.8.2;

abstract contract XSCERC20Safe {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // some ERC20 functions
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = _functionCall(address(token), data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function _functionCall(address target, bytes memory data, string memory errorMessage) private returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) private returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(_isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// File: contracts/libraries/openzeppelin-v4.6.0/contracts/utils/Address.sol


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

// File: contracts/libraries/openzeppelin-v4.6.0/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// File: contracts/CCSource.sol


pragma solidity =0.8.2;
pragma experimental ABIEncoderV2;



interface IERC20Like {
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
}

    struct ReleaseAssetInfo {
        uint256     eventSeq;
        address     localAddress;
        address     remoteAddress;
        string      symbol;
        uint256     amount;
    }

/**
 * @title Contract used to lock assets
 */

contract XscBridgeSource is CCBase, XSCERC20Safe, Initializable {
    // The default decimals of all ERC20* symbol
    uint8 constant TARGET_DECIMALS = 18;

    // Mapping of already handled nonce of CCTarget: nonce => bool
    mapping(uint256 => bool) public handledNonces;

    // Native asset symbol
    string public nativeSymbol;

    // All registered token symbols
    string[] public allSymbols;

    // Addresses of registered token contracts
    mapping(string => address) public tokenContracts;
    mapping(string => uint8)   public tokenDecimals;

    // Emit an event when token contract register
    event TokenRegistered(string indexed symbol, address indexed contractAddress, uint256 indexed symbolDecimals);

    // Emit an event when assets get locked
    event AssetLocked(uint256 nonce, address indexed localAddress, address indexed remoteAddress, string symbol, uint256 amount);

    // Emit an event when assets get released
    event AssetReleased(uint256 nonce, address indexed localAddress, address indexed remoteAddress, string symbol, uint256 amount);

    // Only initialize once
    function initialize(string calldata _nativeSymbol) virtual public initializer {
        CCBase.initCCBase();
        nativeSymbol = _nativeSymbol;
        tokenDecimals[nativeSymbol] = 18;
    }

    function regTokenContract(string calldata _symbol, address _contract) onlyAdmin external {
        // check input parameters
        require(!stringEqual(nativeSymbol, _symbol), "regToken/native-symbol-reserved");
        require(isContract(_contract), "regToken/invalid-address");
        IERC20Like erc20Token = IERC20Like(_contract);

        // check decimal of contract
        uint8 _decimals = erc20Token.decimals();
        require(_decimals <= TARGET_DECIMALS, "regToken/invalid-decimals");

        // check symbol of contract
        require(stringEqual(_symbol, erc20Token.symbol()), "regToken/invalid-symbol");
        require(tokenContracts[_symbol] == address(0), "regToken/token-registered");

        tokenContracts[_symbol] = _contract;
        tokenDecimals[_symbol]  = _decimals;
        allSymbols.push(_symbol);

        emit TokenRegistered(_symbol, _contract, _decimals);
    }

    function lockAsset(address _remoteAddress, string calldata _symbol, uint256 _amount) switchOn external payable {
        require(_amount > 0, "lockAsset/amount-is-zero");

        if (stringEqual(nativeSymbol,_symbol)) {
            // Make sure there is some native asset to lock
            uint256 amount = msg.value;
            require(amount == _amount, "lockAsset/native-amount-invalid");
        } else {
            // get token contract address by symbol
            IERC20 erc20Token = IERC20(tokenContracts[_symbol]);
            require(erc20Token != IERC20(address(0)), "lockAsset/symbol-invalid");

            require(msg.value == 0, "lockAsset/no-need-msg-value");
            require(erc20Token.balanceOf(msg.sender)>=_amount, "lockAsset/insufficient-balance");
            require(erc20Token.allowance(msg.sender, address(this)) >= _amount, "lockAsset/insufficient-allowance");

            // transfer asset from user's wallet to this contract
            safeTransferFrom(erc20Token, msg.sender, address(this), _amount);
        }

        _amount = _toTargetAmount(tokenDecimals[_symbol], _amount);
        _eventNonce++;

        emit AssetLocked(_eventNonce, msg.sender, _remoteAddress, _symbol, _amount);
    }

    function releaseAsset(ReleaseAssetInfo calldata _assetInfo, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) switchOn external {
        require(!handledNonces[_assetInfo.eventSeq], "releaseAsset/duplicated");
        bytes32 _hash = keccak256(abi.encodePacked(_assetInfo.eventSeq, _assetInfo.remoteAddress, _assetInfo.localAddress,
            _assetInfo.symbol, _assetInfo.amount, block.chainid));
        require(checkWitnessSignature(_hash, v, r, s), "releaseAsset/signature-error");

        handledNonces[_assetInfo.eventSeq] = true;
        _releaseAsset(payable(_assetInfo.localAddress), _assetInfo.symbol, _assetInfo.amount);

        emit AssetReleased(_assetInfo.eventSeq, _assetInfo.localAddress, _assetInfo.remoteAddress, _assetInfo.symbol, _assetInfo.amount);
    }

    function _releaseAsset(address payable _receiveAddress, string calldata _symbol, uint256 _amount) internal {
        _amount = _toSourceAmount(tokenDecimals[_symbol], _amount);

        if (stringEqual(nativeSymbol, _symbol)) {
            // check if enough asset to release
            require(address(this).balance >= _amount, "release/insufficient-balance");

            // transfer native asset
            _receiveAddress.transfer(_amount);
        } else {
            // get token contract address by symbol
            IERC20 erc20Token = IERC20(tokenContracts[_symbol]);
            require(erc20Token != IERC20(address(0)), "release/symbol-not-registered");

            // transfer asset from this contract to user's wallet
            require(erc20Token.balanceOf(address(this)) >= _amount, "release/insufficient-balance");
            safeTransfer(erc20Token, _receiveAddress, _amount);
        }
    }

    // source decimals to target decimals(18 decimals)
    function _toTargetAmount(uint8 _decimals, uint256 _amount) pure internal returns(uint256 target) {
        if (TARGET_DECIMALS == _decimals) {
            target = _amount;
        } else {
            target = safeDiv(safeMul(_amount, 10 ** TARGET_DECIMALS), (10 ** _decimals));
        }
    }

    // target decimals(18 decimals) to source decimals
    function _toSourceAmount(uint8 _decimals, uint256 _amount) pure internal returns(uint256 source) {
        if (TARGET_DECIMALS == _decimals) {
            source = _amount;
        } else {
            source = safeDiv(safeMul(_amount, 10 ** _decimals), (10 ** TARGET_DECIMALS));
        }
    }

    function getTokenBalance(string calldata _symbol) view external returns(uint256 balance) {
        if (stringEqual(nativeSymbol, _symbol)) {
            balance = address(this).balance;
        } else {
            IERC20 erc20Token = IERC20(tokenContracts[_symbol]);
            if(erc20Token != IERC20(address(0))){
                balance = erc20Token.balanceOf(address(this));
            }
        }
    }
}