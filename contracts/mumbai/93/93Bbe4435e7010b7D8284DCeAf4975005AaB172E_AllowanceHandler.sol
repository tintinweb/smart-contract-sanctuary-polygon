//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ProxyUtils.sol";
import "./SecurityUtils.sol";
import "./SecuredProcess.sol";

/**
 * @dev Definition of a process that can be secured through allowance mechanism
 */
interface IAllowance is ISecuredProcess {
    /**
     * @dev Bucket definition data structure
     * 'name' Name of the bucket
     * 'allowanceCap' Allowance cap defined on the bucket. If zero, allowance should explicitly be added to user and will
     * be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * 'creditorRole' Role that user should be granted in order to credit allowance on the bucket
     * 'debitorRole' Role that user should be granted in order to debit allowance on the bucket
     */
    struct Bucket {
        bytes32 name;
        uint256 allowanceCap;
        bytes32 creditorRole;
        bytes32 debitorRole;
    }

    /**
     * @dev This method should return the number of allowance buckets defined in this contract.
     * Can be used together with {getBucketAt} to enumerate all allowance buckets defined in this contract.
     */
    function getBucketCount() external view returns (uint256);
    /**
     * @dev This method should return one of the allowance bucket defined in this contract.
     * `index` must be a value between 0 and {getBucketCount}, non-inclusive.
     * Allowance buckets are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getBucketAt} and {getBucketCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getBucketAt(uint256 index) external view returns (Bucket memory);
    /**
     * @dev This method should return the allowance bucket defined in this contract by given name
     * @param name Name of the allowance bucket to be retrieved
     */
    function getBucket(bytes32 name) external view returns (Bucket memory);
    /**
     * @dev This method should create allowance bucket corresponding to given arguments
     * @param name Name of the allowance bucket
     * @param allowanceCap Allowance cap defined on the bucket. If zero, allowance should explicitly be added to user and
     * will be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * @param creditorRole Role that user should be granted in order to credit allowance on the bucket
     * @param debitorRole Role that user should be granted in order to debit allowance on the bucket
     */
    function createBucket(bytes32 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) external;

    /**
     * @dev Getter of the available allowance for a user on a given bucket. Should return the available allowance for a
     * user alongside its applicable bucket definition
     * @param address_ Address of the user for which allowance should be retrieved
     * @param bucketName Bucket name for which allowance should be retrieved
     */
    function getAllowance(address address_, bytes32 bucketName) external view returns (uint256 allowance, Bucket memory bucket);
    /**
     * @dev Should check the available allowance for a user on a given bucket. Should revert if available allowance is lower
     * than requested one or if bucket is not defined. Should return the available allowance for a user alongside its applicable
     * bucket definition
     * @param address_ Address of the user for which allowance should be checked
     * @param bucketName Bucket name for which allowance should be checked
     * @param amount Minimal amount of allowance expected
     */
    function checkAllowance(address address_, bytes32 bucketName, uint256 amount) external view returns (uint256 allowance, Bucket memory bucket);
    /**
     * @dev Should add allowances for users on given buckets. Should revert if added amount exceeds allowance cap or if
     * provided arrays do not have the same sizes or if one of given bucket names is not defined. Caller should be granted
     * every bucket's defined creditor roles for the call to be allowed
     * @param addresses Address of the users for which allowances should be added
     * @param bucketNames Buckets name for which allowances should be added
     * @param amounts Amounts of allowance to be added
     */
    function addAllowances(address[] memory addresses, bytes32[] memory bucketNames, uint256[] memory amounts) external returns (uint256[] memory allowances, Bucket[] memory buckets);
    /**
     * @dev Should add allowance for a user on a given bucket. Should revert if added amount exceeds allowance cap or if
     * given bucket name is not defined. Caller should be granted bucket's defined creditor role for the call to be allowed
     * @param address_ Address of the user for which allowance should be added
     * @param bucketName Bucket name for which allowance should be added
     * @param amount Amount of allowance to be added
     */
    function addAllowance(address address_, bytes32 bucketName, uint256 amount) external returns (uint256 allowance, Bucket memory bucket);
    /**
     * @dev Should use allowance of a user on a given bucket. Should revert if used amount exceeds available allowance
     * or if given bucket name is not defined. Caller should be granted bucket's defined debitor role for the call to be allowed
     * @param address_ Address of the user from which allowance should be used
     * @param bucketName Bucket name from which allowance should be used
     * @param amount Amount of allowance to be used
     */
    function useAllowance(address address_, bytes32 bucketName, uint256 amount) external returns (uint256 allowance, Bucket memory bucket);
}

error AllowanceHandler_AmountExceeded(uint256 requestedAmount, uint256 available);
error AllowanceHandler_WrongParams();
error AllowanceHandler_ForbiddenRole(bytes32 role);
error AllowanceHandler_BucketNotDefined(bytes32 name);
error AllowanceHandler_BucketAlreadyDefined(bytes32 name);

/**
 * @dev Base implementation for secured allowance mechanism
 */
abstract contract BaseAllowanceHandler is IAllowance, PausableImpl {
    /** Role definition necessary to be able to manage buckets */
    bytes32 public constant ALLOWANCE_ADMIN_ROLE = keccak256("ALLOWANCE_ADMIN_ROLE");
    /** IAllowance interface ID definition */
    bytes4 public constant IAllowanceInterfaceId = type(IAllowance).interfaceId;

    /**
     * @dev This method is the entrypoint to create a new bucket definition. User should be granted ALLOWANCE_ADMIN_ROLE
     * role in order to use it. Will revert if a bucket with exact same name is already defined or if chosen roles are
     * DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the bucket to be created
     * @param allowanceCap Allowance cap of the bucket to be created. If zero, allowance should explicitly be defined by
     * user and will be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * @param creditorRole Role that user should be granted in order to credit allowance on the created bucket
     * @param debitorRole Role that user should be granted in order to debit allowance on the created bucket
     */
    function createBucket(bytes32 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) external onlyRole(ALLOWANCE_ADMIN_ROLE) {
        _createBucket(name, allowanceCap, creditorRole, debitorRole);
    }
    /**
     * @dev Internal method to create a new bucket definition. Will revert if a bucket with exact same name is already defined
     * or if chosen roles are DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the bucket to be created
     * @param allowanceCap Allowance cap of the bucket to be created. If zero, allowance should explicitly be defined by
     * user and will be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * @param creditorRole Role that user should be granted in order to credit allowance on the created bucket
     * @param debitorRole Role that user should be granted in order to debit allowance on the created bucket
     */
    function _createBucket(bytes32 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) internal virtual;
    /**
     * @dev Getter of the available allowance for a user on a given bucket.
     * Will return the available allowance for a user alongside its applicable bucket definition or revert with AllowanceHandler_BucketNotDefined
     * if none can be found
     * @param address_ Address of the user for which allowance should be retrieved
     * @param bucketName Bucket name for which allowance should be retrieved
     */
    function getAllowance(address address_, bytes32 bucketName) public virtual view returns (uint256 allowance, Bucket memory bucket);
    /**
     * @dev Check the available allowance for a user on a given bucket. Will revert with AllowanceHandler_AmountExceeded
     * if available allowance is lower than requested one or with AllowanceHandler_BucketNotDefined if bucket is not defined.
     * Will return the available allowance for a user alongside its applicable bucket definition
     * @param address_ Address of the user for which allowance should be checked
     * @param bucketName Bucket name for which allowance should be checked
     * @param amount Minimal amount of allowance expected
     */
    function checkAllowance(address address_, bytes32 bucketName, uint256 amount) public view returns (uint256 allowance, Bucket memory bucket) {
        // Get current allowance
        (uint256 allowance_, Bucket memory bucket_) = getAllowance(address_, bucketName);
        // Revert if user's allowance is not sufficient
        if(allowance_ < amount) revert AllowanceHandler_AmountExceeded(amount, allowance_);
        return (allowance_, bucket_);
    }
    /** @dev Internal method that checks given address against provided bucket definition's creditor/debitor role or default
     * ALLOWANCE_ADMIN_ROLE
     * @param address_ Address to be checked for
     * @param bucket_ Bucket defininition for which to check for creditor/debitor role
     * @param credit Should check for creditor role if true, or debitor role otherwise
     */
    function _checkAllower(address address_, Bucket memory bucket_, bool credit) internal view {
        // If address is not a full allowance admin, check creditor/debitor role
        if(!hasRole(ALLOWANCE_ADMIN_ROLE, address_)) {
            // Check allowance role depending on whether allowance has to be credited or debited
            _checkRole(credit ? bucket_.creditorRole : bucket_.debitorRole, address_);
        }
    }
    /**
     * @dev Add allowances for users on given buckets. Will revert with AllowanceHandler_AmountExceeded if added amount
     * exceeds allowance cap or with AllowanceHandler_WrongParams if provided array does not have the same sizes or with
     * AllowanceHandler_BucketNotDefined if one of given bucket names is not defined. Caller
     * should be granted every bucket's defined creditor roles for the call to be allowed
     * @param addresses Address of the users for which allowances should be added
     * @param bucketNames Buckets name for which allowances should be added
     * @param amounts Amounts of allowance to be added
     */
    function addAllowances(address[] memory addresses, bytes32[] memory bucketNames, uint256[] memory amounts) external
    returns (uint256[] memory allowances, Bucket[] memory buckets) {
        uint256[] memory allowances_ = new uint256[](addresses.length);
        Bucket[] memory buckets_ = new Bucket[](addresses.length);
        if(addresses.length != bucketNames.length || bucketNames.length != amounts.length) revert AllowanceHandler_WrongParams();
        for(uint256 i = 0 ; i < addresses.length ; i++) {
            (allowances_[i], buckets_[i]) = _addOrUseAllowance(addresses[i], bucketNames[i], amounts[i], true/*, true*/);
        }
        return (allowances_, buckets_);
    }
    /**
     * @dev Add allowance for a user on a given bucket. Will revert with AllowanceHandler_AmountExceeded if added amount
     * exceeds allowance cap or with AllowanceHandler_BucketNotDefined if given bucket name is not defined. Caller should
     * be granted bucket's defined creditor role for the call to be allowed
     * @param address_ Address of the user for which allowance should be added
     * @param bucketName Bucket name for which allowance should be added
     * @param amount Amount of allowance to be added
     */
    function addAllowance(address address_, bytes32 bucketName, uint256 amount) external
    returns (uint256 allowance, Bucket memory bucket) {
        return _addOrUseAllowance(address_, bucketName, amount, true/*, true*/);
    }
    /**
     * @dev Use allowance of a user on a given bucket. Will revert with AllowanceHandler_AmountExceeded if used amount
     * exceeds available allowance or with AllowanceHandler_BucketNotDefined if given bucket name is not defined. Caller
     * should be granted bucket's defined debitor role for the call to be allowed
     * @param address_ Address of the user from which allowance should be used
     * @param bucketName Bucket name from which allowance should be used
     * @param amount Amount of allowance to be used
     */
    function useAllowance(address address_, bytes32 bucketName, uint256 amount) public// override
    returns (uint256 allowance, Bucket memory bucket) {
        return _addOrUseAllowance(address_, bucketName, amount, false/*, true*/);
    }
    /**
     * Internal method used to add or use allowance for a user on a given bucket. It insures that no allowance change can
     * be done while contract is paused and will revert with AllowanceHandler_BucketNotDefined if given bucket name is not
     * defined or with AllowanceHandler_AmountExceeded if attempting to add more that possible/use more than available allowance.
     * When checkRole is activated, user should be granted corresponding creditor/debitor (when allowance should be added
     * or removed) role found in given whitelist definition in order to use it
     * @param address_ Address of the user for which allowance should be set
     * @param bucketName Bucket name for which allowance should be set
     * @param amount Amount of allowance to add or use for defined user on a given bucket
     * @param add Should the amount of allowance added or user for defined user on a given bucket
     * @ param checkRole Should the creditor/debitor role be checked
     */
    function _addOrUseAllowance(address address_, bytes32 bucketName, uint256 amount, bool add/*, bool checkRole*/) internal virtual
    returns (uint256 allowance, Bucket memory bucket);

    /**
     * Check process for an allowance secured mechanism consists of checking allowance rigths
     */
    function checkProcess(bytes32 bucketName, address address_, uint256 amount) public virtual view {
        checkAllowance(address_, bucketName, amount);
    }
    /**
     * Execute process for an allowance secured mechanism consists of using allowance rigths
     */
    function doProcess(bytes32 bucketName, address address_, uint256 amount) public virtual {
        useAllowance(address_, bucketName, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
               interfaceId == IAllowanceInterfaceId ||
               interfaceId == type(ISecuredProcess).interfaceId;
    }
}

/**
 * @dev This is the default contract implementation for allowance management.
 */
contract AllowanceHandler is BaseAllowanceHandler {
    /** @dev Allowances defined for users on buckets */
    mapping(address => mapping(bytes32 => uint256)) private _allowances;

    /** @dev Buckets defined on this contract */
    mapping(bytes32 => Bucket) private _buckets;
    /** @dev Enumerable set used to reference every defined buckets name */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private _bucketNames;

    /**
     * @dev Event emitted whenever some allowances are added for a user on a specific bucket
     * 'admin' Address of the administrator that added allowances
     * 'beneficiary' Address of the user for which allowances were added
     * 'bucket' Bucket definition in which allowances were added
     * 'amount' Amount of added allowances
     * 'allowance' Amount of available allowances for the user on the bucket after addition
     */
    event AllowanceAdded(address indexed admin, address indexed beneficiary, bytes32 indexed bucket, uint256 amount, uint256 allowance);
    /**
     * @dev Event emitted whenever some allowances are used for a user on a specific bucket
     * 'consumer' Address of the consumer that used allowances
     * 'beneficiary' Address of the user for which allowances were used
     * 'bucket' Bucket definition in which allowances were used
     * 'amount' Amount of used allowances
     * 'allowance' Amount of available allowances for the user on the bucket after usage
     */
    event AllowanceUsed(address indexed consumer, address indexed beneficiary, bytes32 indexed bucket, uint256 amount, uint256 allowance);

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev This method returns the number of buckets defined in this contract.
     * Can be used together with {getBucketAt} to enumerate all buckets defined in this contract.
     */
    function getBucketCount() external view returns (uint256) {
        return _bucketNames.length();
    }
    /**
     * @dev This method returns one of the buckets defined in this contract.
     * `index` must be a value between 0 and {getBucketCount}, non-inclusive.
     * Buckets are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getBucketAt} and {getBucketCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getBucketAt(uint256 index) external view returns (Bucket memory) {
        return _buckets[_bucketNames.at(index)];
    }
    /**
     * @dev This method returns the bucket defined in this contract by given name and will revert with AllowanceHandler_BucketNotDefined
     * if none can be found
     * @param name Name of the bucket definition to be found
     */
    function getBucket(bytes32 name) public view returns (Bucket memory) {
        if(!_bucketNames.contains(name)) revert AllowanceHandler_BucketNotDefined(name);
        return _buckets[name];
    }
    /**
     * @dev Internal method to create a new bucket definition. Will revert if a bucket with exact same name is already defined
     * or if chosen roles are DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the bucket to be created
     * @param allowanceCap Allowance cap of the bucket to be created. If zero, allowance should explicitly be defined by
     * user and will be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * @param creditorRole Role that user should be granted in order to credit allowance on the created bucket
     * @param debitorRole Role that user should be granted in order to debit allowance on the created bucket
     */
    function _createBucket(bytes32 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) internal override {
        // Check bucket name existence
        if(_bucketNames.contains(name)) revert AllowanceHandler_BucketAlreadyDefined(name);
        // Check for forbidden roles
        if(creditorRole == DEFAULT_ADMIN_ROLE || creditorRole == ALLOWANCE_ADMIN_ROLE) revert AllowanceHandler_ForbiddenRole(creditorRole);
        if(debitorRole == DEFAULT_ADMIN_ROLE || debitorRole == ALLOWANCE_ADMIN_ROLE) revert AllowanceHandler_ForbiddenRole(debitorRole);
        _buckets[name] = Bucket(name, allowanceCap, creditorRole, debitorRole);
        _bucketNames.add(name);
    }

    /**
     * @dev Getter of the available allowance for a user on a given bucket.
     * Will return the available allowance for a user alongside its applicable bucket definition or revert with AllowanceHandler_BucketNotDefined
     * if none can be found
     * @param address_ Address of the user for which allowance should be retrieved
     * @param bucketName Bucket name for which allowance should be retrieved
     */
    function getAllowance(address address_, bytes32 bucketName) public override view returns (uint256 allowance, Bucket memory bucket) {
        Bucket memory bucket_ = getBucket(bucketName);
        // Allowance is specifically defined by user
        if(bucket_.allowanceCap == 0) {
            return (_allowances[address_][bucketName], bucket_);
        }
        // Allowance is capped and fully granted until used
        return (bucket_.allowanceCap - _allowances[address_][bucketName], bucket_);
    }
    /**
     * Internal method used to add or use allowance for a user on a given bucket. It insures that no allowance change can
     * be done while contract is paused and will revert with AllowanceHandler_BucketNotDefined if given bucket name is not
     * defined or with AllowanceHandler_AmountExceeded if attempting to add more that possible/use more than available allowance.
     * When checkRole is activated, user should be granted corresponding creditor/debitor (when allowance should be added
     * or removed) role found in given whitelist definition in order to use it
     * @param address_ Address of the user for which allowance should be set
     * @param bucketName Bucket name for which allowance should be set
     * @param amount Amount of allowance to add or use for defined user on a given bucket
     * @param add Should the amount of allowance added or user for defined user on a given bucket
     * param checkRole Should the creditor/debitor role be checked
     */
    function _addOrUseAllowance(address address_, bytes32 bucketName, uint256 amount, bool add/*, bool checkRole*/) internal override whenNotPaused()
    returns (uint256 allowance, Bucket memory bucket) {
        // Get or check allowance depending on if some have to be added or used
        (uint256 allowance_, Bucket memory bucket_) = add ? getAllowance(address_, bucketName) : checkAllowance(address_, bucketName, amount);
        // Nothing to add/use
        if(amount == 0) return (allowance_, bucket_);
        //if(checkRole) {
            _checkAllower(_msgSender(), bucket_, add);
            // Check allowance role depending on whether if some have to be added or used
            //_checkRole(add ? bucket_.creditorRole : bucket_.debitorRole);
        //}
        // Allowance is specifically defined by user
        if(bucket_.allowanceCap == 0) {
            // Add/use allowance
            _allowances[address_][bucketName] = add ? allowance_ + amount : allowance_ - amount;
        }
        // Allowance is capped and fully granted until used
        else {
            // If allowance should be added, cap should not be exceeded (cannot add more than the number already used
            uint256 usedAllowance = bucket_.allowanceCap - allowance_;
            if(add && amount > usedAllowance) revert AllowanceHandler_AmountExceeded(amount, usedAllowance);
            // Add/use allowance
            _allowances[address_][bucketName] = add ? usedAllowance - amount : usedAllowance + amount;
        }
        (allowance_, ) = getAllowance(address_, bucketName);
        // Emit corresponding event
        if(add) {
            emit AllowanceAdded(msg.sender, address_, bucketName, amount, allowance_);
        }
        else {
            emit AllowanceUsed(msg.sender, address_, bucketName, amount, allowance_);
        }
        return (allowance_, bucket_);
    }
}

/**
 * @dev Base allowance proxy implementation that will externalize behavior into another contract (ie a deployed AllowanceHandler),
 * acting as a proxy
 */
abstract contract AllowanceProxy is ProxyDiamond, BaseAllowanceHandler {
    /** @dev Key used to reference the proxied IAllowance contract */
    bytes32 public constant PROXY_IAllowance = keccak256("IAllowanceProxy");

    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param allowanceProxyAddress_ Address of the contract handling allowance process
     */
    constructor(address allowanceProxyAddress_, bool nullable, bool updatable, bool adminable) {
        _setAllowanceProxy(PROXY_IAllowance, allowanceProxyAddress_, nullable, updatable, adminable);
    }

    function getBucketCount() external view returns (uint256) {
        return getAllowanceProxy().getBucketCount();
    }
    function getBucketAt(uint256 index) external view returns (Bucket memory) {
        return getAllowanceProxy().getBucketAt(index);
    }
    function getBucket(bytes32 name) external view returns (Bucket memory) {
        return getAllowanceProxy().getBucket(name);
    }
    function _createBucket(bytes32 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) internal override {
        return getAllowanceProxy().createBucket(name, allowanceCap, creditorRole, debitorRole);
    }

    function getAllowance(address address_, bytes32 bucketName) public override view returns (uint256 allowance, Bucket memory bucket) {
        return getAllowanceProxy().getAllowance(address_, bucketName);
    }
    function _addOrUseAllowance(address address_, bytes32 bucketName, uint256 amount, bool add/*, bool checkRole*/) internal virtual override whenNotPaused()
    returns (uint256 allowance, Bucket memory bucket) {
        (uint256 allowance_, Bucket memory bucket_) = add ? getAllowanceProxy().addAllowance(address_, bucketName, amount) :
                                                            getAllowanceProxy().useAllowance(address_, bucketName, amount);
        if(amount != 0) {
            _checkAllower(_msgSender(), bucket_, add);
        }
        return (allowance_, bucket_);
    }


    /**
     * Getter of the contract handling allowances process
     */
    function getAllowanceProxy() internal view returns (IAllowance) {
        return IAllowance(getProxy(PROXY_IAllowance));
    }
    function _setAllowanceProxy(bytes32 key, address allowanceProxyAddress_, bool nullable, bool updatable, bool adminable) internal {
        _setProxy(key, allowanceProxyAddress_, IAllowanceInterfaceId, nullable, updatable, adminable);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SecurityUtils.sol";

error ProxyHub_ContractIsNull();
error ProxyHub_ContractIsInvalid(bytes4 interfaceId);
error ProxyHub_KeyNotDefined(address user, bytes32 key);
error ProxyHub_NotUpdatable();
error ProxyHub_NotAdminable();
error ProxyHub_CanOnlyBeRestricted();
error ProxyHub_CanOnlyBeAdminableIfUpdatable();

/**
 * @dev As solidity contracts are size limited, and to ease modularity and potential upgrades, contracts should be divided
 * into smaller contracts in charge of specific functional processes. Links between those contracts and their users can be
 * seen as 'proxies', a way to call and delegate part of a treatment. Instead of having every user contract referencing and
 * managing links to those proxies, this part as been delegated to following ProxyHub. User contract might then declare
 * themself as ProxyDiamond to easily store and access their own proxies
 */
contract ProxyHub is PausableImpl {

    /**
     * @dev Proxy definition data structure
     * 'proxyAddress' Address of the proxied contract
     * 'interfaceId' ID of the interface the proxied contract should comply to (ERC165)
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    struct Proxy {
        address proxyAddress;
        bytes4 interfaceId;
        bool nullable;
        bool updatable;
        bool adminable;
        bytes32 adminRole;
    }
    /** @dev Proxies defined for users on keys */
    mapping(address => mapping(bytes32 => Proxy)) private _proxies;
    /** @dev Enumerable set used to reference every defined users */
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _users;
    /** @dev Enumerable sets used to reference every defined keys by users */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(address => EnumerableSet.Bytes32Set) private _keys;

    /**
     * @dev Event emitted whenever a proxy is defined
     * 'admin' Address of the administrator that defined the proxied contract (will be the user if directly managed)
     * 'user' Address of the of the user for which a proxy was defined
     * 'key' Key by which the proxy was defined and referenced
     * 'proxyAddress' Address of the proxied contract
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    event ProxyDefined(address indexed admin, address indexed user, bytes32 indexed key, address proxyAddress,
                       bytes4 interfaceId, bool nullable, bool updatable, bool adminable, bytes32 adminRole);

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Search for the existing proxy defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function findProxyFor(address user, bytes32 key) public view returns (Proxy memory) {
        return _proxies[user][key];
    }
    /**
     * @dev Search for the existing proxy defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function findProxy(bytes32 key) public view returns (Proxy memory) {
        return findProxyFor(msg.sender, key);
    }
    /**
     * @dev Search for the existing proxy address defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function findProxyAddressFor(address user, bytes32 key) external view returns (address) {
        return findProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Search for the existing proxy address defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function findProxyAddress(bytes32 key) external view returns (address) {
        return findProxy(key).proxyAddress;
    }
    /**
     * @dev Search if proxy has been defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return True if proxy has been defined by given user on provided key, false otherwise
     */
    function isKeyDefinedFor(address user, bytes32 key) public view returns (bool) {
        // A proxy can have only been initialized whether with a null address AND nullablevalue set to true OR a not null
        // address (When a structure has not yet been initialized, all boolean value are false)
        return _proxies[user][key].proxyAddress != address(0) || _proxies[user][key].nullable;
    }
    /**
     * @dev Check if proxy has been defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     */
    function checkKeyIsDefinedFor(address user, bytes32 key) internal view {
        if(!isKeyDefinedFor(user, key)) revert ProxyHub_KeyNotDefined(user, key);
    }
    /**
     * @dev Get the existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function getProxyFor(address user, bytes32 key) public view returns (Proxy memory) {
        checkKeyIsDefinedFor(user, key);
        return _proxies[user][key];
    }
    /**
     * @dev Get the existing proxy defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function getProxy(bytes32 key) public view returns (Proxy memory) {
        return getProxyFor(msg.sender, key);
    }
    /**
     * @dev Get the existing proxy address defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function getProxyAddressFor(address user, bytes32 key) external view returns (address) {
        return getProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Get the existing proxy address defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function getProxyAddress(bytes32 key) external view returns (address) {
        return getProxy(key).proxyAddress;
    }

    /**
     * @dev Set already existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found, with ProxyHub_NotAdminable if not allowed to be modified by administrator, with ProxyHub_CanOnlyBeRestricted
     * if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull when given address is null
     * and null not allowed
     * @param user User that should have defined the proxy being modified
     * @param key Key by which the proxy being modified should have been defined
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function setProxyFor(address user, bytes32 key, address proxyAddress, bytes4 interfaceId,
                         bool nullable, bool updatable, bool adminable) external {
        _setProxy(msg.sender, user, key, proxyAddress, interfaceId, nullable, updatable, adminable, DEFAULT_ADMIN_ROLE);
    }
    /**
     * @dev Define proxy for caller on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function setProxy(bytes32 key, address proxyAddress, bytes4 interfaceId,
                      bool nullable, bool updatable, bool adminable, bytes32 adminRole) external {
        _setProxy(msg.sender, msg.sender, key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }

    function _setProxy(address admin, address user, bytes32 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) private whenNotPaused() {
        if(!updatable && adminable) revert ProxyHub_CanOnlyBeAdminableIfUpdatable();
        // Check if we are in update mode and perform updatability validation
        if(isKeyDefinedFor(user, key)) {
            Proxy memory proxy = _proxies[user][key];
            // Proxy is being updated directly by its user
            if(admin == user) {
                if(!proxy.updatable) revert ProxyHub_NotUpdatable();
            }
            // Proxy is being updated "externally" by an administrator
            else {
                if(!proxy.adminable && admin != user) revert ProxyHub_NotAdminable();
                _checkRole(proxy.adminRole, admin);
                // Admin role is never given in that case, should then be retrieved
                adminRole = _proxies[user][key].adminRole;
            }
            if(proxy.interfaceId != interfaceId || proxy.adminRole != adminRole) revert ProxyHub_CanOnlyBeRestricted();
            // No update to be performed
            if(proxy.proxyAddress == proxyAddress && proxy.nullable == nullable &&
               proxy.updatable == updatable && proxy.adminable == adminable) {
                return;
            }
            if((!_proxies[user][key].nullable && nullable) ||
               (!_proxies[user][key].updatable && updatable) ||
               (!_proxies[user][key].adminable && adminable)) {
                revert ProxyHub_CanOnlyBeRestricted();
            }
        }
        // Proxy cannot be initiated by administration
        else if(admin != user) revert ProxyHub_KeyNotDefined(user, key);
        // Proxy reference is being created
        else {
            _users.add(user);
            _keys[user].add(key);
        }
        // Check Proxy depending on its address
        if(proxyAddress == address(0)) {
            // Proxy address cannot be set to null
            if(!nullable) revert ProxyHub_ContractIsNull();
        }
        // Interface ID is defined
        else if(interfaceId != 0x00) {
            // Proxy should support requested interface
            if(!ERC165(proxyAddress).supportsInterface(interfaceId)) revert ProxyHub_ContractIsInvalid(interfaceId);
        }

        _proxies[user][key] = Proxy(proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
        emit ProxyDefined(admin, user, key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }

    /**
     * @dev This method returns the number of users defined in this contract.
     * Can be used together with {getUserAt} to enumerate all users defined in this contract.
     */
    function getUserCount() public view returns (uint256) {
        return _users.length();
    }
    /**
     * @dev This method returns one of the users defined in this contract.
     * `index` must be a value between 0 and {getUserCount}, non-inclusive.
     * Users are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getUserAt} and {getUserCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param index Index at which to search for the user
     */
    function getUserAt(uint256 index) public view returns (address) {
        return _users.at(index);
    }
    /**
     * @dev This method returns the number of keys defined in this contract for a user.
     * Can be used together with {getKeyAt} to enumerate all keys defined in this contract for a user.
     * @param user User for which to get defined number of keys
     */
    function getKeyCount(address user) public view returns (uint256) {
        return _keys[user].length();
    }
    /**
     * @dev This method returns one of the keys defined in this contract for a user.
     * `index` must be a value between 0 and {getKeyCount}, non-inclusive.
     * Keys are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getKeyAt} and {getKeyCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param user User for which to get key at defined index
     * @param index Index at which to search for the key of defined user
     */
    function getKeyAt(address user, uint256 index) public view returns (bytes32) {
        return _keys[user].at(index);
    }
}

error ProxyDiamond_ContractIsInvalid();

/**
 * @dev This is the contract to extend in order to easily store and access a proxy
 */
contract ProxyDiamond {
    /** @dev Address of the Hub where proxies are stored */
    address public immutable proxyHubAddress;

    /**
     * @dev Default constructor
     * @param proxyHubAddress_ Address of the Hub where proxies are stored
     */
    constructor(address proxyHubAddress_) {
        proxyHubAddress = proxyHubAddress_;
    }

    /**
     * @dev Returns the address of the proxy defined by current proxy diamond on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param key Key on which searched proxied address should be defined by diamond
     * @return Found existing proxy address defined by diamond on provided key
     */
    function getProxy(bytes32 key) public virtual view returns (address) {
        return ProxyHub(proxyHubAddress).getProxyAddress(key);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function _setProxy(bytes32 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal virtual {
        ProxyHub(proxyHubAddress).setProxy(key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed. Adminnistrator role will be the default one returned by getProxyAdminRole()
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function _setProxy(bytes32 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable) internal virtual {
        _setProxy(key, proxyAddress, interfaceId, nullable, updatable, adminable, getProxyAdminRole());
    }
    /**
     * @dev Default proxy hub administrator role
     */
    function getProxyAdminRole() public virtual returns (bytes32) {
        return 0x00;
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

error AccessControl_MissingRole(address account, bytes32 role);

/**
 * @dev Default implementation to use when role based access control is requested. It extends openzeppelin implementation
 * in order to use 'error' instead of 'string message' when checking roles and to be able to attribute admin role for each
 * defined role (and not rely exclusively on the DEFAULT_ADMIN_ROLE)
 */
abstract contract AccessControlImpl is AccessControlEnumerable {

    /**
     * @dev Default constructor
     */
    constructor() {
        // To be done at initialization otherwise it will never be accessible again
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Revert with AccessControl_MissingRole error if `account` is missing `role` instead of a string generated message
     */
    function _checkRole(bytes32 role, address account) internal view virtual override {
        if(!hasRole(role, account)) revert AccessControl_MissingRole(account, role);
    }
    /**
     * @dev Sets `adminRole` as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender is missing
     * current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public {
        address sender = _msgSender();
        if(!hasRole(getRoleAdmin(role), sender) && !hasRole(DEFAULT_ADMIN_ROLE, sender)) {
            revert AccessControl_MissingRole(sender, getRoleAdmin(role));
        }
        _setRoleAdmin(role, adminRole);
    }
    /**
     * @dev Sets `role` as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender is missing
     * current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdminItself(bytes32 role) public {
        setRoleAdmin(role, role);
    }
    /**
     * @dev Sets DEFAULT_ADMIN_ROLE as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender
     * is missing current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdminDefault(bytes32 role) public {
        setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
    }
}

/**
 * @dev Default implementation to use when contract should be pausable (role based access control is then requested in order
 * to grant access to pause/unpause actions). It extends openzeppelin implementation in order to define publicly accessible
 * and role protected pause/unpause methods
 */
abstract contract PausableImpl is AccessControlImpl, Pausable {
    /** Role definition necessary to be able to pause contract */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Pause the contract if message sender has PAUSER_ROLE role. Action protected with whenNotPaused() or with
     * _requireNotPaused() will not be available anymore until contract is unpaused again
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }
    /**
     * @dev Unpause the contract if message sender has PAUSER_ROLE role. Action protected with whenPaused() or with
     * _requirePaused() will not be available anymore until contract is paused again
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ProxyUtils.sol";

interface ISecuredProcess {
    function checkProcess(bytes32 processName, address address2Process, uint256 amount2Process) external view;
    function doProcess(bytes32 processName, address address2Process,uint256 amount2Process) external;
}

abstract contract SecuredProcessProxy is ProxyDiamond, ISecuredProcess, ERC165 {
    /** @dev Key used to reference the proxied SecuredProcess contract */
    bytes32 public constant PROXY_SecuredProcess = keccak256("SecuredProcessProxy");
    /** ISecuredProcess interface ID definition */
    bytes4 public constant ISecuredProcessInterfaceId = type(ISecuredProcess).interfaceId;
    /** @dev Default secured process name */
    //bytes32 public immutable _defaultProcessName;

    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param securedProcessAddress_ Address of the contract handling secured process
     */
    constructor(address securedProcessAddress_, bool nullable, bool updatable, bool adminable/*, bytes32 defaultProcessName_*/) {
        //_defaultProcessName = defaultProcessName_ == 0x00 ? bytes32(uint256(uint160(address(this))) << 96) : defaultProcessName_;//abi.encodePacked(address(this));
        _setSecuredProcessProxy(PROXY_SecuredProcess, securedProcessAddress_, nullable, updatable, adminable);
    }

    /*function canProcess(bytes32 processName, address address2Process, uint256 amount2Process) external virtual returns(bool) {
        return getSecuredProcess().canProcess(processName, address2Process, amount2Process);
    }*/
    function checkProcess(bytes32 processName, address address2Process, uint256 amount2Process) public view virtual {
        address securedProcessAddress = getProxy(PROXY_SecuredProcess);
        if(securedProcessAddress != address(0)) {
            ISecuredProcess(securedProcessAddress).checkProcess(processName /*_defaultProcessName*/, address2Process, amount2Process);
        }
    }
    function doProcess(bytes32 processName, address address2Process, uint256 amount2Process) public virtual {
        address securedProcessAddress = getProxy(PROXY_SecuredProcess);
        if(securedProcessAddress != address(0)) {
            ISecuredProcess(securedProcessAddress).doProcess(processName /*_defaultProcessName*/, address2Process, amount2Process);
        }
    }

    /**
     * Getter of the contract handling secured process
     */
    /*function getSecuredProcess() internal view returns (ISecuredProcess) {
        return ISecuredProcess(getProxy(PROXY_SecuredProcess));
    }*/
    function _setSecuredProcessProxy(bytes32 key, address securedProcessAddress_,
                                     bool nullable, bool updatable, bool adminable) internal {
        _setProxy(key, securedProcessAddress_, ISecuredProcessInterfaceId, nullable, updatable, adminable);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
               interfaceId == type(ISecuredProcess).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
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