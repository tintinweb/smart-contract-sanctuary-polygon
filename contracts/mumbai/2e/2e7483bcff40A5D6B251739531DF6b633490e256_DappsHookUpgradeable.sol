/// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import './access/OwnableUpgradeable.sol';
import './proxy/Initializable.sol';

/// @author ramverma-oro
/// @author vipin-dapps

contract DappsHookUpgradeable is OwnableUpgradeable {
    enum USER_REGISTER_STATUS {
        REGISTERED,
        QUEUE
    }

    struct UserInfo {
        // user code
        bytes3 userCode;
        // total score
        uint256 totalScore;
        // user register status Queue/Registered
        USER_REGISTER_STATUS registerStatus;
        // affiliate code
        bytes3 affiliateCode;
        // completed tasks
        bytes3[] completedTask;
    }

    struct TaskInfo {
        // task name
        string taskName;
        // task score
        uint256 taskScore;
    }

    address[] private userAddresses;

    event TaskAdded(bytes3 indexed taskId, string taskName, uint256 taskScore);
    event UserRegistered(address userAddress, USER_REGISTER_STATUS registerStatus, bytes3 userCode, bytes3 affiliateCode);
    event AddedToPanel(address existedUserAddress, address newUserAddress, bytes3 newUserCode);
    event SubmitedTask(address userAddress, bytes3 taskId, uint256 taskScore);

    mapping(address => UserInfo) public userInfo;
    mapping(bytes3 => address) public userAddress;
    mapping(address => bytes3[]) public userPanel;
    mapping(bytes3 => TaskInfo) public taskInfo;

    /**
     * @notice initialize Dapps Hook contract
     * @param trustedForwarder trusted forwarder address
     */

    function __DappsHookUpgradeable_init(address trustedForwarder) external initializer {
        __Ownable_init(trustedForwarder);
    }

    /**
     * @notice generateUserCode returns bytes code for user
     * @param _userAddress - user wallet address
     * @return code of bytes3
     */

    function generateUserCode(address _userAddress) internal view returns (bytes3) {
        uint256 timestamp = uint256(block.timestamp);
        bytes32 hash = keccak256(abi.encodePacked(_userAddress, timestamp));
        return bytes3(hash);
    }

    /**
     * @notice this function accept user code and return user address
     * @param _userCode - bytes3 user code
     */

    function getUserAddress(bytes3 _userCode) public view returns (address) {
        return userAddress[_userCode];
    }

    /**
     * @notice this function register user to the dapps hook
     * @param _affiliateCode - user code of affiliate
     */
    function registerNewUser(bytes3 _affiliateCode) external {
        // check if user already registered
        require(checkIfUserAlreadyRegistered(), 'UAR');
        // generated user code
        bytes3 userCode_ = generateUserCode(_msgSender());
        // get affiliateAddress
        address affiliateAddress_ = getUserAddress(_affiliateCode);
        // check if affiliate is valid
        if (userInfo[affiliateAddress_].affiliateCode == _affiliateCode && userInfo[affiliateAddress_].affiliateCode == bytes3(0)) {
            // update affiliate totalScore
            userInfo[affiliateAddress_].totalScore += 1;

            // set user data
            userInfo[_msgSender()].registerStatus = USER_REGISTER_STATUS.QUEUE;
            userInfo[_msgSender()].userCode = userCode_;
            userInfo[_msgSender()].affiliateCode = _affiliateCode;
            emit UserRegistered(_msgSender(), USER_REGISTER_STATUS.QUEUE, userCode_, _affiliateCode);
        } else {
            userInfo[_msgSender()].registerStatus = USER_REGISTER_STATUS.QUEUE;
            userInfo[_msgSender()].userCode = userCode_;
            userInfo[_msgSender()].affiliateCode = bytes3(0);
            emit UserRegistered(_msgSender(), USER_REGISTER_STATUS.QUEUE, userCode_, bytes3(0));
        }
    }

    /**
     * @notice Any registered user can add non registered user to his panel
     * @param _userCode - user 6 digit code
     */
    function addUserToPanel(bytes3 _userCode) external {
        require(userInfo[_msgSender()].registerStatus == USER_REGISTER_STATUS.REGISTERED, 'IU');
        require(_userCode == bytes3(0), 'IUC');
        bytes3[] storage userPanelAddresses_ = userPanel[_msgSender()];
        userPanelAddresses_.push(_userCode);
        userPanel[_msgSender()] = userPanelAddresses_;
        address userAddress_ = getUserAddress(_userCode);
        userInfo[userAddress_].registerStatus = USER_REGISTER_STATUS.REGISTERED;
        emit AddedToPanel(_msgSender(), userAddress_, _userCode);
    }

    /**
     * @notice add task to the task list
     * @param _taskId - task id
     * @param _taskname - task name
     * @param _taskScore - task score
     */
    function addTask(bytes3 _taskId, string memory _taskname, uint256 _taskScore) external onlyOwner {
        require(taskInfo[_taskId].taskScore == 0, 'TAE');
        taskInfo[_taskId].taskName = _taskname;
        taskInfo[_taskId].taskScore = _taskScore;
        emit TaskAdded(_taskId, _taskname, _taskScore);
    }

    /**
     * @notice check if task already completed
     * @param account - user wallet address
     * @param _taskId - new task Id
     */
    function checkIfTaskCompleted(address account, bytes3 _taskId) public view returns (bool) {
        bytes3[] storage completedTasks_ = userInfo[account].completedTask;
        for (uint i = 0; i < completedTasks_.length; i++) {
            if (completedTasks_[i] == _taskId) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice check if user already registered
     */
    function checkIfUserAlreadyRegistered() public view returns (bool) {
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _msgSender()) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice submit the completed task
     * @param _taskId task id
     */
    function submitTask(bytes3 _taskId) external {
        require(!checkIfTaskCompleted(_msgSender(), _taskId), 'TAC');
        uint256 taskScore_ = taskInfo[_taskId].taskScore;
        userInfo[_msgSender()].completedTask.push(_taskId);
        userInfo[_msgSender()].totalScore += taskScore_;
        emit SubmitedTask(_msgSender(), _taskId, taskScore_);
    }

    /**
     * @notice get all user data
     */
    function getAllUser() internal view returns (UserInfo[] memory) {
        uint256 totalUsers_ = userAddresses.length;
        UserInfo[] memory allUserInfo_ = new UserInfo[](totalUsers_);
        for (uint8 i = 0; i < userAddresses.length; i++) {
            allUserInfo_[i] = userInfo[userAddresses[i]];
        }
        return allUserInfo_;
    }

    /**
     * @notice - getUserRank returns user rank
     * @param _userAddress - user wallet address
     * @return rank of a user if user not present it will return ran as 0
     */
    function getUserRank(address _userAddress) public view returns (uint256) {
        bytes3 userCode_ = userInfo[_userAddress].userCode;
        UserInfo[] memory allUserInfo_ = getAllUser();
        for (uint i = 1; i < allUserInfo_.length; i++) {
            for (uint j = 0; j < i; j++) {
                if (allUserInfo_[i].totalScore > allUserInfo_[j].totalScore) {
                    UserInfo memory x = allUserInfo_[i];
                    allUserInfo_[i] = allUserInfo_[j];
                    allUserInfo_[j] = x;
                }
            }
        }

        for (uint256 i = 0; i < allUserInfo_.length; i++) {
            if (userCode_ == allUserInfo_[i].userCode) {
                return i + 1;
            }
        }

        return 0;
    }
}

// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity =0.8.9;

import {ERC2771ContextUpgradeable} from '../metatx/ERC2771ContextUpgradeable.sol';
import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner
 */

abstract contract OwnableUpgradeable is Initializable, ERC2771ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     */
    function __Ownable_init(address trustedForwarder) internal initializer {
        __ERC2771ContextUpgradeable_init(trustedForwarder);
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner
     * @return _owner - _owner address
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'ONA');
        _;
    }

    /**
     *
     * NOTE: Renouncing ownership will transfer the contract ownership to ZERO Address
     */

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Can only be called by the current owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'INA');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Internal function without access restriction
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Context variant with ERC2771 support
 */

// solhint-disable
abstract contract ERC2771ContextUpgradeable is Initializable {
    /**
     * @dev holds the trust forwarder
     */

    address public trustedForwarder;

    /**
     * @dev context upgradeable initializer
     * @param tForwarder trust forwarder
     */

    function __ERC2771ContextUpgradeable_init(address tForwarder) internal initializer {
        __ERC2771ContextUpgradeable_init_unchained(tForwarder);
    }

    /**
     * @dev called by initializer to set trust forwarder
     * @param tForwarder trust forwarder
     */

    function __ERC2771ContextUpgradeable_init_unchained(address tForwarder) internal {
        trustedForwarder = tForwarder;
    }

    /**
     * @dev check if the given address is trust forwarder
     * @param forwarder forwarder address
     * @return isForwarder true/false
     */

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * @dev if caller is trusted forwarder will return exact sender.
     * @return sender wallet address
     */

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * @dev returns msg data for called function
     * @return function call data
     */

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity =0.8.9;

import '../utils/AddressUpgradeable.sol';

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered
        require(_initializing ? _isConstructor() : !_initialized, 'CIAI');

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly
     */
    modifier onlyInitializing() {
        require(_initializing, 'CINI');
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity =0.8.9;

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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

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
        return functionStaticCall(target, data, 'Address: low-level static call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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