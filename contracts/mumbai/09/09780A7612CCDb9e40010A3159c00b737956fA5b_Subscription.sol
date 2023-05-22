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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.14;

interface IMultiSig {

    // Defining the Transaction struct
    struct Transaction {
        address from;               // Address that submitted the transaction
        address executed;           // Address that executed the transaction
        uint256 numConfirmations;   // Number of confirmations for the transaction
        string functionName;        // Name of the function to be executed in the transaction
        bytes data;                 // Data to be passed to the function
        address[] confirmed;        // Array of addresses that confirmed the transaction
        uint256 createdAt;          // Timestamp when the transaction was created
        uint256 updatedAt;          // Timestamp when the transaction was last updated
    }

    // Defining events for submitting, confirming, and executing transactions
    event SubmitTransaction(address indexed from, uint256 indexed transactionId); 
    event ConfirmTransaction(address indexed from, uint256 indexed transactionId);
    event ExecuteTransaction(address indexed from, uint256 indexed transactionId);

    // Function to get the list of owners
    function getOwners() external view returns (address[] memory);

    // Function to confirm a transaction
    function confirmTransaction(uint256 _transactionId) external;
    
    // Function to execute a transaction
    function executeTransaction(uint256 _transactionId) external  ;

    // Function to get the details of a transaction
    function getTransaction (uint256 _transactionId) external view returns (Transaction memory transactions_);

    // Function to get all transactions with pagination
    function getAllTransactions (uint256 _pageNo, uint256 _perPage) external view returns (Transaction [] memory transactions_, uint256 totalList_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ISubscription {

    /////////////////////// Enum ///////////////////////

    enum PlanType {
        MONTHLY,
        YEARLY
    }

    /////////////////////// Struct ///////////////////////

    struct Plan {
        uint256 id;
        string name;
        uint256 price;
        PlanType planType;
        uint256 spaceSize; // in byte
        bool isActive;
    }

    struct Subscription {
        uint256 id;
        uint256 planId;
        address walletAddress;
        uint256 fromDate;
        uint256 toDate;
    }

    struct Storage {
        address walletAddress;
        uint256 available; // in byte
        uint256 used; // in byte
    }

    /////////////////////// General functions ///////////////////////

    function setFreeSpace(uint256 _freeSpace) external returns (uint256 _transactionId);
    function getFreeSpace() external view returns (uint256 _freeSpace);

    function isThereSubscription (address _user) external view returns (bool isSubscription_, uint256 space_, uint256 lastSubscriptionEndDate_);
    
    /////////////////////// Plan management functions and events ///////////////////////

    /********************** Event **********************/
    event createNewPlanEvent (uint256 id, string name, uint256 price, PlanType planType, uint256 spaceSize, bool isActive);
    event setActivateDeactivatePlanEvent (uint256 id, bool isActive);

    /********************** Functions **********************/
    function createNewPlan (string memory _name, uint256 _price, bool _isMonthly, uint256 _spaceSize, bool _isActive) external returns (uint256 _transactionId);
    function setActivateDeactivatePlan (uint256 _id) external returns (uint256 _transactionId);
    function getAllPlans (uint256 _pageNo, uint256 _perPage) external view returns (Plan[] memory plans_, uint total_);

    /////////////////////// Subscription management functions ///////////////////////
    
    event subscriptionEvent (uint256 id, uint256 planId, address walletAddress, uint256 fromDate, uint256 toDate);
    function subscription (uint256 _planId) external payable;
    function getListOfSubscriptionsForUser () external view returns (Subscription[] memory subscriptions_, uint256 total_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "a must be greater than or equals b");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "must be greater than zero");
        return a / b;
    }

 
  
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMultiSig.sol";
import "./lib/SafeMath.sol";

abstract contract MultiSig is IMultiSig, Initializable {

    using SafeMath for uint256;

    address [] private ownerList;
    mapping(address => bool) private ownerMap;

    uint256 private transactionIncrement;
    mapping(uint256 => Transaction) internal transactionMap;

    mapping(uint256 => mapping(address => bool)) private transactionAddressConfirmedMap;

    uint256 private numConfirmationsRequired;

    /////////////////////////////// Start Modifiers ///////////////////////////////
    
    // Modifier to check if the sender is an owner
    modifier onlyOwner() {
        require(ownerMap[msg.sender], "not owner");
        _;
    }

    // Modifier to check if the transaction exists
    modifier transactionExists(uint256 _transactionId) {
        require(_transactionId > 0 && _transactionId <= transactionIncrement, "Transaction does not exist");
        _;
    }

    // Modifier to check if the transaction has not been executed
    modifier notExecuted(uint256 _transactionId) {
        require(transactionMap[_transactionId].executed == address(0), "Transaction already executed");
        _;
    }

    // Modifier to check if the transaction has not been confirmed by the sender
    modifier notConfirmed(uint256 _transactionId) {
        require(!transactionAddressConfirmedMap[_transactionId][msg.sender], "Transaction already confirmed");
        _;
    }

    /////////////////////////////// End Modifiers ///////////////////////////////

    // Constructor to initialize the contract with owners and the required number of confirmations
    // constructor(address [] memory _owners, uint256 _numConfirmationsRequired) {

    //     require (_numConfirmationsRequired > 1 , "The Number of confirmations required must be greater than one");
    //     require (_owners.length >= _numConfirmationsRequired , "The number of owners must be greater than or equal to the number of confirmations required");

    //     transactionIncrement = 0;
    //     numConfirmationsRequired = _numConfirmationsRequired;
    //     addOwners(_owners);
    // }

    function initialize(address [] memory _owners, uint256 _numConfirmationsRequired) public virtual onlyInitializing {

        require (_numConfirmationsRequired > 1 , "The Number of confirmations required must be greater than one");
        require (_owners.length >= _numConfirmationsRequired , "The number of owners must be greater than or equal to the number of confirmations required");

        transactionIncrement = 0;
        numConfirmationsRequired = _numConfirmationsRequired;
        addOwners(_owners);
    }

    // Internal function to add owners to the contract
    function addOwners(address[] memory _owners) internal {
        
        for (uint256 i = 0 ; i < _owners.length ; i = i.add(1)) {

            require (_owners[i] != address(0) , "Zero address not Allowed");
            require (!ownerMap[_owners[i]] , "The Owner not unique");

            ownerMap[_owners[i]] = true;
            ownerList.push(_owners[i]);
        }

    }
    // Function to get the list of owners
    function getOwners() external view returns (address[] memory) {
        return ownerList;
    }

    // Internal function to submit a transaction
    function submitTransaction(address _sender, string memory _functionName, bytes memory _data) internal returns (uint256 _transactionId) {
    
        require (_sender != address(0) , "Zero address not Allowed");
	    require(bytes(_functionName).length > 0, "The Function name is required");
	    require(_data.length > 0, "The Data is required");

        transactionIncrement = transactionIncrement.add(1);
    
        transactionMap[transactionIncrement].from           = _sender;
        transactionMap[transactionIncrement].executed       = address(0);
        transactionMap[transactionIncrement].functionName   = _functionName;
        transactionMap[transactionIncrement].data           = _data;
        transactionMap[transactionIncrement].createdAt      =  block.timestamp;
        transactionMap[transactionIncrement].updatedAt      =  block.timestamp;

        emit SubmitTransaction (_sender, transactionIncrement);

        return transactionIncrement;
    }

    // Function to confirm a transaction
    function confirmTransaction(uint256 _transactionId) external onlyOwner 
        transactionExists(_transactionId) 
        notExecuted(_transactionId) 
        notConfirmed(_transactionId) {

        transactionMap[_transactionId].confirmed.push(msg.sender);
        transactionMap[_transactionId].numConfirmations = transactionMap[_transactionId].numConfirmations.add(1);
        transactionAddressConfirmedMap[_transactionId][msg.sender] = true;
        transactionMap[_transactionId].updatedAt = block.timestamp;

        emit ConfirmTransaction(msg.sender, _transactionId);
    }

    // Function to execute a transaction
    function executeTransaction(uint256 _transactionId) external  onlyOwner transactionExists(_transactionId) 
        notExecuted(_transactionId) {

        require(transactionMap[_transactionId].numConfirmations >= numConfirmationsRequired, "cannot execute tx");

        transactionMap[_transactionId].executed = msg.sender;
        transactionMap[_transactionId].updatedAt = block.timestamp;

        executeFunction(_transactionId);
        
        emit ExecuteTransaction(msg.sender, _transactionId);
    }

    // Function to get the details of a transaction
    function getTransaction (uint256 _transactionId) external onlyOwner view returns (Transaction memory transactions_) {
        return transactionMap[_transactionId];
    }

    // Function to get all transactions with pagination
    function getAllTransactions (uint256 _pageNo, uint256 _perPage) external onlyOwner view returns (Transaction [] memory transactions_, uint256 totalList_) {
        require((_pageNo.mul(_perPage)) <= transactionIncrement, "Page is Out of Range");
        uint256 no_transaction = (transactionIncrement.sub(_pageNo.mul(_perPage))) < _perPage ?
        (transactionIncrement.sub(_pageNo.mul(_perPage))) : _perPage;
        Transaction[] memory transactions = new Transaction[](no_transaction);
        for (uint256 i = 0; i < transactions.length; i= i.add(1)) {
            transactions[i] = transactionMap[(_pageNo.mul(_perPage)) + (i.add(1))];
        }
        return (transactions, transactionIncrement);
    }

    // Internal function to execute the function specified in the transaction
    function executeFunction (uint256 _transactionId) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISubscription.sol";
import "./MultiSig.sol";
import "./interfaces/IMultiSig.sol";

contract Subscription is ISubscription , MultiSig{

    uint256 private planCounter;
    uint256 private subscriptionCounter;
    mapping(uint256 => Plan) private plansMap;
    mapping(address => Subscription[]) private subscriptionsMap;
    uint256 private freeSpace;
    address multiSigWallet;

    /////////////////////// Modifier ///////////////////////

    modifier nonZeroAddress() {
        require(msg.sender != address(0x0), "Zero address not Allowed");
        _;
    }

    modifier stringIsNotEmpty(string memory _val, string memory _msg) {
        require(bytes(_val).length > 0, _msg);
        _;
    }

    modifier valueIsGreaterThanZero(uint256 _val, string memory _msg) {
        require(_val > 0, _msg);
        _;
    }

    modifier planIsExists(uint256 _val, string memory _msg) {
        require(plansMap[_val].id > 0, _msg);
        _;
    }

    modifier planIsActive(uint256 _val) {
        require(plansMap[_val].id > 0 && plansMap[_val].isActive, "The plan is not active");
        _;
    }

    modifier ifThereActiveSubscription(string memory _msg) {

        for(uint i = 0 ; i < subscriptionsMap[msg.sender].length ; i++){
            require(!(subscriptionsMap[msg.sender][i].fromDate <= block.timestamp && subscriptionsMap[msg.sender][i].toDate >= block.timestamp), _msg);
        }
        _;
    }

    modifier checkSubscriptionAmount(uint256 _val) {
        require(msg.value >= plansMap[_val].price, "Insufficient subscription amount");
        _;
    }

    /////////////////////// Constructor ///////////////////////

    // constructor(address[] memory _owners, uint256 _numConfirmationsRequired) MultiSig (_owners, _numConfirmationsRequired) {
    //    freeSpace = 209715200; // 200MB =>  209715200 / 1024**2
    // }

    function initialize(address[] memory _owners, uint256 _numConfirmationsRequired) public override initializer {
        MultiSig.initialize(_owners, _numConfirmationsRequired);
        freeSpace = 209715200; // 200MB =>  209715200 / 1024**2
    }

    function executeFunction (uint256 _transactionId) internal override{

        if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_setFreeSpace"))))) {
            (uint256 _freeSpace) = abi.decode(transactionMap[_transactionId].data,( uint256 ));
            _setFreeSpace( _freeSpace);
        } else if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_setActivateDeactivatePlan"))))) {
            (uint256 _id) = abi.decode(transactionMap[_transactionId].data, (uint256 ));
            _setActivateDeactivatePlan(_id);
        } else if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_createNewPlan"))))) {
            (string memory _name, uint256 _price, bool _isMonthly, uint256 _spaceSize, bool _isActive) = abi.decode(transactionMap[_transactionId].data, (string,uint256,bool,uint256,bool));
            _createNewPlan(_name,_price,_isMonthly,_spaceSize,_isActive);
        } else if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_setMultiSigWallet"))))) {
            (address _multiSigWallet) = abi.decode(transactionMap[_transactionId].data, (address));
            _setMultiSigWallet(_multiSigWallet);
        } 

    }

    /////////////////////// General functions ///////////////////////

    function setMultiSigWallet(address _multiSigWallet) external onlyOwner returns (uint256 _transactionId) {
        return submitTransaction(msg.sender, "_setMultiSigWallet" , abi.encode(_multiSigWallet));
    }


    function _setMultiSigWallet(address _multiSigWallet) internal {
        multiSigWallet = _multiSigWallet;
    }


    function setFreeSpace(uint256 _freeSpace) external onlyOwner returns (uint256 _transactionId) {
        return submitTransaction(msg.sender, "_setFreeSpace" , abi.encode(_freeSpace));
    }

    function _setFreeSpace(uint256 _freeSpace) internal {
        freeSpace = _freeSpace;
    }
    

    function getFreeSpace() external view returns (uint256 _freeSpace) {
        return freeSpace;
    }

    function isThereSubscription (address _user) external view returns (bool isSubscription_, uint256 space_, uint256 lastSubscriptionEndDate_) {
        
        uint no_subscription = subscriptionsMap[_user].length;
        
        for(uint i = 0 ; i < no_subscription ; i++){
            if (subscriptionsMap[_user][i].fromDate <= block.timestamp && subscriptionsMap[_user][i].toDate >= block.timestamp) {
                return (true, plansMap[subscriptionsMap[_user][i].planId].spaceSize, subscriptionsMap[_user][i].toDate);
            }
        }

        return (false, freeSpace, no_subscription > 0 ? subscriptionsMap[_user][no_subscription - 1].toDate : 0);
    }

    /////////////////////// Plan management functions ///////////////////////

    function createNewPlan (string memory _name, uint256 _price, bool _isMonthly, uint256 _spaceSize, bool _isActive)  external onlyOwner returns (uint256 _transactionId){
        return submitTransaction(msg.sender, "_createNewPlan" , abi.encode(  _name,  _price,  _isMonthly,  _spaceSize, _isActive));
    }

    //multi sig 
    function _createNewPlan (string memory _name, uint256 _price, bool _isMonthly, uint256 _spaceSize, bool _isActive) internal  
        nonZeroAddress 
        stringIsNotEmpty (_name, "The name is Required") 
        valueIsGreaterThanZero (_price, "The price must be greater than zero")
        valueIsGreaterThanZero (_spaceSize, "The space size must be greater than zero")
    {
        planCounter = planCounter + 1;
        plansMap[planCounter] = Plan(planCounter, _name, _price, _isMonthly ? PlanType.MONTHLY : PlanType.YEARLY, _spaceSize, _isActive);

        emit createNewPlanEvent (planCounter, _name, _price, plansMap[planCounter].planType, _spaceSize, _isActive);
    }

    function setActivateDeactivatePlan (uint256 _id)  external onlyOwner returns (uint256 _transactionId){
        return submitTransaction(msg.sender, "_setActivateDeactivatePlan" , abi.encode(_id));

    }

    //multi sig 
    function _setActivateDeactivatePlan (uint256 _id) internal nonZeroAddress  planIsExists(_id, "The plan does not exist") {
        plansMap[_id].isActive = !plansMap[_id].isActive;
        emit setActivateDeactivatePlanEvent (_id, plansMap[_id].isActive);
    }

    function getAllPlans (uint256 _pageNo, uint256 _perPage) external view returns (Plan[] memory plans_, uint total_) {
        require((_pageNo * _perPage) <= planCounter, "Page is Out of Range");

        uint256 no_plans = (planCounter - (_pageNo * _perPage)) < _perPage
            ? (planCounter - (_pageNo * _perPage)) : _perPage;

        plans_ = new Plan[](no_plans);

        uint startIndex = planCounter - (_pageNo * _perPage) ;
        uint256 index = 0;
        for (uint256 i = startIndex; i > startIndex - no_plans; i--) {
            plans_[index++] = plansMap[i];
        }

        return (plans_, planCounter);
    }

    /////////////////////// Subscription management functions ///////////////////////

    /////////////////////// Subscription management functions ///////////////////////

    function subscription (uint256 _planId) external payable nonZeroAddress 
        ifThereActiveSubscription("You are already subscribed") 
        planIsExists(_planId, "The plan does not exist") 
        planIsActive(_planId) 
        checkSubscriptionAmount(_planId)
    {
        subscriptionCounter++;

        uint256 fromDate = block.timestamp;
        uint256 toDate = fromDate + (plansMap[_planId].planType == PlanType.MONTHLY ? 5 minutes : 10 minutes);

        subscriptionsMap[msg.sender].push(Subscription(subscriptionCounter, _planId, msg.sender, fromDate, toDate));
        
        payable(multiSigWallet).transfer(msg.value);
        
        emit subscriptionEvent (subscriptionCounter, _planId, msg.sender, fromDate, toDate);
    }

    function getListOfSubscriptionsForUser () external view returns (Subscription[] memory subscriptions_, uint256 total_) {
        return (subscriptionsMap[msg.sender], subscriptionsMap[msg.sender].length);
    }

}