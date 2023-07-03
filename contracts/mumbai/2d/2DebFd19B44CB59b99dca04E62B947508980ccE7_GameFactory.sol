// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

pragma solidity ^0.8.10;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Librarys/FactoryLib.sol";

contract GameFactory is Initializable, OwnableUpgradeable {

    bool public paused;
    uint public games;

    event DeployInstance(address indexed Instance, address indexed sender, uint indexed game );

    function initialize() external initializer{
        __Ownable_init();
        paused = false;
    }

    function deploy(uint game) external payable returns (address addr) { 
        require(!paused, "The contract is paused!");
        require(game > 0 && game <= games, "There Is No More Games");
        bytes memory bytecode = FactoryLib.ChooseGame(game);
        assembly {

            addr := create(callvalue(), add(bytecode, 0x20), mload(bytecode))
        }
        require(addr != address(0), "deploy failed");
        emit DeployInstance(addr , msg.sender, game);
    }

    function setGames(uint num) external onlyOwner{
        games = num;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BalanceChecker {
    bool public correctBalanceChecked = false;

    function checkBalance(address _account, uint256 _amount) public {
        require(_account.balance == _amount, "Incorrect balance");
        correctBalanceChecked = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BlockHash {
    bool public correctBlockHash = false;

    function blockHashCheck(uint blockNumber, bytes32 blockHash) external {
        require(blockNumber < block.number, "Block number should be less than current block number");
        require(block.number - blockNumber <= 256, "Block number should be within the last 256 blocks");
        if(blockhash(blockNumber) == blockHash){
            correctBlockHash = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Bytes2 {
    bytes2 public num = 0;

    function increaseNum(bytes2 _biggerNum) external {
        require(_biggerNum != bytes2(0), "biggerNum cannot be zero");
        num = _biggerNum;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ChangePassword {
    uint256 private password;
    uint256[] public PreviousPassword;

    constructor(uint256 _password) {
        password = _password;
    }
    function changePassword(uint256 _password, uint256 newPassword) external {
        require(password == _password, "Password Cannot Be Changed!");
        require(
            password != newPassword,
            "The Password Must Be Different From The Previous Password!"
        );
        PreviousPassword.push(_password);
        password = newPassword;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract DecodeData{
    bytes public encodeStringAndUint =hex"00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000b4920416d204e756d626572000000000000000000000000000000000000000000";
     
    struct Player{
       string _string;
       uint256 _number;
    }
    Player public player;

    function decode(string memory _str, uint256 _num) external {
        bytes memory encodedData = abi.encode(_str, _num);
        require(keccak256(encodedData) == keccak256(encodeStringAndUint), "The Answer is incorrect");
        player = Player(_str, _num);
    }
    function decodeStringAndUint(bytes memory encodedData) public pure returns (string memory, uint256){
        (string memory decodedStr, uint256 decodedNum) = abi.decode(
            encodedData,
            (string, uint256)
        );
        return (decodedStr, decodedNum);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract EncodeData {
    bytes public _encodeStringAndUint = hex"";

    function encode(bytes memory encodedData) external {
        require(
            keccak256(encodedData) == keccak256(abi.encode("WEB", 3)),
            "The Answer is incorrect"
        );
        _encodeStringAndUint = encodedData;
    }  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract SomeContract {
    /*              ~~~~                                    ~~~~ 
             ~~                                       ~~
                ~~                                       ~~
             ~~                                        ~~
                ~~                                       ~~
            _____                                      _____
           /|   |\                                    /|   |\
          /_|___|_\                                  /_|___|_\
         ||_|___|_||                                ||_|___|_||
       /             \                            /             \
      /               \                          /               \
     /_________________\  ____________________  /_________________\
    |   ____________    ||   ____    ____     ||   ____________    |
    |  |            |   ||  |    |  |    |    ||  |            |   |
    |  |____________|   ||  |____|  |____|    ||  |____________|   |
    |                   ||                    ||                   |
    |   _____________   ||   _____________    ||   _____________   |
    |  |             |  ||  |             |   ||  |             |  |
    |  |   _     _   |  ||  |   _     _   |   ||  |   _     _   |  |
    |  |  | |   | |  |  ||  |  | |   | |  |   ||  |  | |   | |  |  |
    |__|__| |___| |__|__||__|__| |___| |__|___||__|__| |___| |__|__|      
     */
}

contract Factory {
    SomeContract[] public SomeContracts;

    bool public correctPrediction;

    uint256 public _salt = 1;

    bytes public bytecode = type(SomeContract).creationCode;

    function checkAddress(address _addr, uint256 _sal, bytes memory _bytecode)
        external
        pure
        returns (address)
    {
        bytes32 result = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(_addr),
                _sal,
                keccak256(_bytecode)
            )
        );
        return address(uint160(uint256(result)));
    }

    function deploy(address _add) external{
    require(_add != address(0), "Address must not be null");
    
        bytes32 salt = bytes32(_salt);
        SomeContract someContract = (new SomeContract){salt: salt}();
        SomeContracts.push(someContract);
        if (address(SomeContracts[0]) == _add){
        correctPrediction = true;
        }
        require(correctPrediction,"not correct");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Fallback {
    uint8 num = 0;
    
    function fixMe() external view returns (bool) {
        return num == 1;
    }

    fallback() external {
        num = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract GasChecker {
    uint256 public gasUsed = 0; 
    bool public GasChecked = false;

    function complexOperation(uint256 iterations) external {
        uint256 gasStart = gasleft();

        uint256 sum = 0;
        for(uint256 i = 0; i < iterations; i++) {
            sum += i;
        }

        gasUsed = gasStart - gasleft();
        
        if(gasUsed > 3000 && gasUsed < 5000){
         GasChecked = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HashCollision {
    bytes32 public secretHash = keccak256(abi.encodePacked(sha256("secret")));
    bool public collisionFound = false;

    function findCollision(bytes memory guess) public {
        require(keccak256(abi.encodePacked(guess)) == secretHash, "Not a collision!");
        collisionFound = true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract InterfaceId {
    bool public answer;

    function CalcMe(bytes4 id) external {
        require(id == bytes4(keccak256("CalcMe(bytes4)")), "Calc Me Again!");
        answer = true;
    }

    function Calc() public pure returns (bytes4) {
        return bytes4(keccak256("CalcMe(bytes4)"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Overflow {
    uint256 public counter = type(uint256).max - 3;
    bool public overflowOccurred = false;

    function add(uint256 value) external {
        unchecked {
            counter += value;
            if (counter == 3) {
                overflowOccurred = true;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PayableContract {

    receive() external payable {
        require(msg.value == 1 wei, "Incorrect amount received");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Timestamp {
    uint256 private currentBlockTimestamp;
    bool public success;

    constructor() {
        currentBlockTimestamp = block.timestamp;
    }
    function timeReset(uint256 _Timestamp) external {
        require(currentBlockTimestamp == _Timestamp,"This Is Not The Timestamp");
        currentBlockTimestamp = 0;
        success = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../Games/Fallback.sol";
import "../Games/InterfaceId.sol";
import "../Games/ChangePassword.sol";
import "../Games/DecodeData.sol";
import "../Games/EncodeData.sol";
import "../Games/Timestamp.sol";
import "../Games/Bytes2.sol";
import "../Games/BlockHash.sol";
import "../Games/BalanceChecker.sol";
import "../Games/PayableContract.sol";
import "../Games/Overflow.sol";
import "../Games/GasChecker.sol";
import "../Games/HashCollision.sol";
import "../Games/Factory.sol";

library FactoryLib {
    function checkFallbackGame(address _entity) internal view returns (bool) {
        Fallback entity = Fallback(_entity);
        return entity.fixMe();
    }

    function checkInterfaceIdGame(address _entity)
        internal
        view
        returns (bool)
    {
        InterfaceId entity = InterfaceId(_entity);
        return entity.answer();
    }

    function checkChangePasswordGame(address _entity)
        internal
        view
        returns (bool)
    {
        ChangePassword entity = ChangePassword(_entity);
        return entity.PreviousPassword(0) > 0;
    }

    function checkDecodeDataGame(address _entity) internal view returns (bool) {
        DecodeData entity = DecodeData(_entity);
        (, uint256 number) = entity.player();
        return number == 1;
    }

    function checkEncodeDataGame(address _entity) internal view returns (bool) {
        EncodeData entity = EncodeData(_entity);
        return entity._encodeStringAndUint().length != 0;
    }

    function checkTimestampGame(address _entity) internal view returns (bool) {
        Timestamp entity = Timestamp(_entity);
        return entity.success();
    }

    function checkBytes2Game(address _entity) internal view returns (bool) {
        Bytes2 entity = Bytes2(_entity);
        return entity.num() != 0;
    }

    function checkBlockHashGame(address _entity) internal view returns (bool) {
        BlockHash entity = BlockHash(_entity);
        return entity.correctBlockHash();
    }

    function checkBalanceCheckerGame(address _entity)
        internal
        view
        returns (bool)
    {
        BalanceChecker entity = BalanceChecker(_entity);
        return entity.correctBalanceChecked();
    }

    function checkPayableContractGame(address payable _entity)
        internal
        view
        returns (bool)
    {
        PayableContract entity = PayableContract(_entity);
        return address(entity).balance > 0;
    }

    function checkOverflowGame(address payable _entity)
        internal
        view
        returns (bool)
    {
        Overflow entity = (Overflow(_entity));
        return entity.overflowOccurred();
    }

    function checkGasCheckerGame(address payable _entity)
        internal
        view
        returns (bool)
    {
        GasChecker entity = GasChecker(_entity);
        return entity.GasChecked();
    }

    function checkHashCollisionGame(address payable _entity)
        internal
        view
        returns (bool)
    {
        HashCollision entity = HashCollision(_entity);
        return entity.collisionFound();
    }

    function checkFactoryGame(address _entity)
        internal
        view
        returns (bool)
    {
        Factory entity = Factory(_entity);
        return entity.correctPrediction();
    }

    function ChooseGame(uint256 game)
        internal
        pure
        returns (bytes memory bytecode)
    {
        if (game == 1) {
            bytecode = type(Bytes2).creationCode;
        } else if (game == 2) {
            bytecode = type(Fallback).creationCode;
        } else if (game == 3) {
            bytecode = type(BalanceChecker).creationCode;
        } else if (game == 4) {
            bytecode = type(PayableContract).creationCode;
        } else if (game == 5) {
            bytecode = type(Timestamp).creationCode;
        } else if (game == 6) {
            bytecode = type(GasChecker).creationCode;
        } else if (game == 7) {
            bytes memory bytecode_value = type(ChangePassword).creationCode;
            bytecode = abi.encodePacked(
                bytecode_value,
                abi.encode(
                    0x446f6e277420466f72676574205468652050617373776f726421
                )
            );
        } else if (game == 8) {
            bytecode = type(Overflow).creationCode;
        } else if (game == 9) {
            bytecode = type(BlockHash).creationCode;
        } else if (game == 10) {
            bytecode = type(InterfaceId).creationCode;
        } else if (game == 11) {
            bytecode = type(EncodeData).creationCode;
        } else if (game == 12) {
            bytecode = type(HashCollision).creationCode;
        } else if (game == 13) {
            bytecode = type(DecodeData).creationCode;
        } else if (game == 14) {
            bytecode = type(Factory).creationCode;
        }
        return bytecode;
    }
}