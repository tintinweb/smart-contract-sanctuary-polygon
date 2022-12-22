pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

import "./IER20.sol";


contract EventWallet {
    
    IERC20 tokenContract;
    
    address owner;
    address parentContract;
    
    
    // constructor method, this will be called when the contract is getting deployed.
    constructor(address _tokenContractAddress,address _owner)  public{
        
        owner = _owner;
        parentContract = msg.sender;
        
        tokenContract = IERC20(_tokenContractAddress);
    }
    
    // To update the owner address of this wallet, this can only be called by current owner.
    function updateOwner(address _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }
    
    //To transfer the funds from event wallet to other addresses, it needs two parameters: address and amount (amount in decimals)
    //amount eg: for 100 tokens... we need to send the amount as 10000 as the token has two decimals.
    function releaseFunds(address _receipent,uint256 amount) public{
        
        require(msg.sender == owner || msg.sender == parentContract);
        tokenContract.transfer(_receipent,amount);
        
    }
    
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    
    /**
     * @dev Moves `amount` tokens from `origin` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function customTransferFrom(address recipient, uint256 amount) external returns (bool);
    
    
    /**
     * @dev Moves `amount` tokens from `origin` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function customTransfer(address recipient, uint256 amount) external returns (bool);
    
    

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
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
contract Ownable is Context {
    address private _owner;
    address private _teachOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _teachOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    function techOwner() public view returns (address) {
        return _teachOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender() || _teachOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./IER20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./event_wallet.sol";

contract University is Ownable {
    mapping(address => bool) facultyList;
    mapping(address => bool) staffList;
    mapping(address => bool) public jrAdminList;
    mapping(address => bool) studentsList;

    mapping(string => mapping(string => bool)) academicRecordcourses;
    mapping(string => mapping(address => bool)) courseStudentsList;
    mapping(string => address) coursefacultys;
    mapping(string => academicRecord) allacademicRecords;

    mapping(address => string[]) studentcourses;
    mapping(address => string[]) facultycourses;

    struct academicRecord {
        string academicRecordCode;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint8 status; // 1-active, 2- closed
    }

    event facultyUpdated(
        address _facultyAddress,
        bool _updateType,
        uint256 timeStamp
    );
    event staffUpdated(
        address _facultyAddress,
        bool _updateType,
        uint256 timeStamp
    );
    event StudentUpdated(
        address _studentAddress,
        address _facultyAddress,
        bool _updateType,
        uint256 timeStamp
    );
    event academicRecordStarted(string _academicRecordID, uint256 timeStamp);
    event academicRecordEnded(string _academicRecordID, uint256 timeStamp);

    event TokensAwarded(
        address _studentAddress,
        address _facultyAddress,
        uint256 timeStamp
    );
    event JRAdminsAdded(address[] list, address _addedBy, uint256 timeStamp);
    event staffAdded(address[] list, address _addedBy, uint256 timeStamp);
    event coursesAndfacultyAdded(
        address[] facultylist,
        string[] courselist,
        address addedBy,
        uint256 timeStamp
    );
    event academicRecordcoursesUpdated(
        string academicRecordID,
        address addedBy,
        uint256 timeStamp
    );
    event academicRecordUpdated(
        string academicRecordID,
        uint256 newStartTime,
        uint256 newEndTime,
        address updatedBy,
        uint256 timeStamp
    );

    event courseStudentListUpdated(
        string,
        address[] students,
        address updatedBy,
        uint256 timeStamp
    );
    event JrAdminUpdated(
        address oldAddress,
        address newAddress,
        uint256 timeStamp
    );
    event staffAddressUpdated(
        address oldAddress,
        address newAddress,
        uint256 timeStamp
    );
    event StudentcoursesUpdated(
        address _studentAddress,
        address updatedBy,
        uint256 timeStamp
    );
    event StudentAddressUpdated(
        address oldAddress,
        address newAddress,
        uint256 timeStamp
    );
    event facultyAddressUpdated(
        address oldAddress,
        address newAddress,
        uint256 timeStamp
    );

    IERC20 tokenContract;

    /** @dev Contract internal method, will be executed automatically when contract gets deployed.
     * the total supply.
     */

    constructor(address _tokenContractAddress) public {
        tokenContract = IERC20(_tokenContractAddress);
    }

    function updateTokenAddress(address _tokenContractAddress)
        public
        onlyOwner
    {
        tokenContract = IERC20(_tokenContractAddress);
    }

    /** @dev This is function modifier which will be executed when a function using modifier is called,
     * modifier are usually used for checking certain Requirements before main logic gets executed
     *
     * This modifier checks whether the transaction sending address is of jr admin level
     */
    modifier jrAdminLevel() {
        require(
            msg.sender == owner() ||
                msg.sender == techOwner() ||
                jrAdminList[msg.sender],
            "only jr admin level or above"
        );
        _;
    }

    /** @dev This is function modifier which will be executed when a function using modifier is called,
     * modifier are usually used for checking certain Requirements before main logic gets executed
     *
     * This modifier checks whether the transaction sending address is of faculty level or higher
     */

    modifier facultyLevel() {
        require(
            msg.sender == owner() ||
                msg.sender == techOwner() ||
                jrAdminList[msg.sender] ||
                facultyList[msg.sender],
            "only faculty level or above"
        );
        _;
    }

    modifier staffLevel() {
        require(
            msg.sender == owner() ||
                msg.sender == techOwner() ||
                jrAdminList[msg.sender] ||
                facultyList[msg.sender] ||
                staffList[msg.sender],
            "only staff level or above"
        );
        _;
    }

    /** @dev Takes a list of jr admin addresses as input and whitelist them
     *
     * Emits a {JRAdminsAdded}
     *
     * Requirements
     *
     * - only owner or techowner can call this method.
     *
     * Please dont send more than 10 addresses at a time.
     */

    function addJrAdmins(address[] memory _list) public onlyOwner {
        for (uint256 i = 0; i < _list.length; i++) {
            jrAdminList[_list[i]] = true;
        }

        emit JRAdminsAdded(_list, msg.sender, now);
    }

    /** @dev Takes a list of faculty address and uints.
     * maps the courses to facultys
     * whitelists the facultys
     * Emits a {coursesAndfacultyAdded}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     * Please make sure the array size is 10 or less.
     */
    function addfacultyAndcourses(
        address[] memory _facultyList,
        string[] memory _coursesList
    ) public jrAdminLevel {
        for (uint256 i = 0; i < _coursesList.length; i++) {
            coursefacultys[_coursesList[i]] = _facultyList[i];
            facultyList[_facultyList[i]] = true;
            facultycourses[_facultyList[i]].push(_coursesList[i]);
        }

        emit coursesAndfacultyAdded(
            _facultyList,
            _coursesList,
            msg.sender,
            now
        );
    }

    function addStaff(address[] memory _stafflist) public jrAdminLevel {
        for (uint256 i = 0; i < _stafflist.length; i++) {
            staffList[_stafflist[i]] = true;
        }

        emit staffAdded(_stafflist, msg.sender, now);
    }

    /** @dev Takes old faculty address and new faculty addrss as input.
     * changes all uint assignments from old faculty address to new one.
     * blocks the old faculty address
     * whitelists the new address
     * Emits a {facultyAddressUpdated}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     */

    function updatefacultyAddress(address _oldAddress, address _newAddress)
        public
        jrAdminLevel
    {
        facultyList[_oldAddress] = false;

        string[] memory uints = facultycourses[_oldAddress];
        for (uint256 i = 0; i < uints.length; i++) {
            coursefacultys[uints[i]] = _newAddress;
            facultycourses[_newAddress].push(uints[i]);
        }
        facultyList[_newAddress] = true;

        emit facultyAddressUpdated(_oldAddress, _newAddress, now);
    }

    /** @dev Takes faculty address and update type as input
     *  block or unblock a particular faculty.
     * Emits a {facultyUpdated}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     */

    function updatefacultyStatus(address _facultyAddress, bool _updateType)
        public
        jrAdminLevel
    {
        facultyList[_facultyAddress] = _updateType;
        emit facultyUpdated(_facultyAddress, _updateType, now);
    }

    /** @dev Takes staff address and update type as input
     *  block or unblock a particular faculty.
     * Emits a {facultyUpdated}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     */

    function updateStaffStatus(address _staffAddress, bool _updateType)
        public
        jrAdminLevel
    {
        staffList[_staffAddress] = _updateType;
        emit staffUpdated(_staffAddress, _updateType, now);
    }

    /** @dev Takes student address and update type as input
     *  block or unblock a particular student.
     * Emits a {StudentUpdated}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     */

    function updateStudentStatus(address _studentAddress, bool _updateType)
        public
        facultyLevel
    {
        studentsList[_studentAddress] = _updateType;
        emit StudentUpdated(_studentAddress, msg.sender, _updateType, now);
    }

    /** @dev Takes academicRecord code and days as input
     *  creates a new academicRecord and stores it.
     * Emits a {academicRecordStarted}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     */

    function startacademicRecord(string memory _academicRecordCode, uint8 _days)
        public
        jrAdminLevel
    {
        academicRecord memory currentacademicRecord;
        currentacademicRecord.academicRecordCode = _academicRecordCode;
        currentacademicRecord.status = 1;
        currentacademicRecord.startTimestamp = now;
        currentacademicRecord.endTimestamp = now + _days * 86400;

        allacademicRecords[_academicRecordCode] = currentacademicRecord;

        emit academicRecordStarted(_academicRecordCode, now);
    }

    /** @dev Takes academicRecord code, start time and end time as input
     *  update an exisitng academicRecord
     * Emits a {academicRecordUpdated}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     * the timestamp need to be in unix timestamp format.
     */

    function updateacademicRecord(
        string memory _academicRecordCode,
        uint256 _startTimeStamp,
        uint256 _endTimeStamp
    ) public jrAdminLevel {
        require(
            allacademicRecords[_academicRecordCode].startTimestamp != 0,
            "Invalid academicRecord"
        );

        allacademicRecords[_academicRecordCode]
            .startTimestamp = _startTimeStamp;
        allacademicRecords[_academicRecordCode].endTimestamp = _endTimeStamp;

        emit academicRecordUpdated(
            _academicRecordCode,
            _startTimeStamp,
            _endTimeStamp,
            msg.sender,
            now
        );
    }

    /** @dev Takes academicRecord code, start type as intput (int)
     *  update an exisitng academicRecord status
     * Emits a {academicRecordEnded}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     */

    function updateacademicRecordStatus(
        string memory _academicRecordID,
        uint8 _status
    ) public jrAdminLevel {
        allacademicRecords[_academicRecordID].status = _status;

        emit academicRecordEnded(_academicRecordID, now);
    }

    /** @dev Takes academicRecord code, course list as input.
     *  assings the uints to the academicRecord.
     * Emits a {academicRecordcoursesUpdated}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     * Please keep array size less than 10
     *
     */

    function updateacademicRecordcourses(
        string[] memory _coursesList,
        string memory _academicRecordCode
    ) public jrAdminLevel {
        for (uint256 i = 0; i < _coursesList.length; i++) {
            academicRecordcourses[_academicRecordCode][_coursesList[i]] = true;
        }

        emit academicRecordcoursesUpdated(_academicRecordCode, msg.sender, now);
    }

    // function updatecourseStudents(string memory _courseId,address [] memory _studentList) public jrAdminLevel {

    //     for(uint i=0;i<_studentList.length;i++){
    //         courseStudentsList[_courseId][_studentList[i]] = true;
    //         studentsList[_studentList[i]] = true;
    //     }

    //     emit courseStudentListUpdated(_courseId,_studentList,msg.sender,now);

    // }

    /** @dev Takes student address, course list as input.
     *  assings the uints to the student.
     * Emits a {StudentcoursesUpdated}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     * Please keep array sizes less than 10.
     *
     */

    function updateStudentcourses(
        address _studentAddress,
        string[] memory _uintsList,
        bool[] memory _updateTypeList
    ) public jrAdminLevel {
        for (uint256 i = 0; i < _uintsList.length; i++) {
            courseStudentsList[_uintsList[i]][
                _studentAddress
            ] = _updateTypeList[i];
            studentcourses[_studentAddress].push(_uintsList[i]);
        }
        studentsList[_studentAddress] = true;

        emit StudentcoursesUpdated(_studentAddress, msg.sender, now);
    }

    /** @dev Takes old student address and new student addrss as input.
     * changes all uint assignments from old student address to new one.
     * blocks the old student address
     * whitelists the new address
     * Emits a {StudentAddressUpdated}
     *
     * Requirements
     *
     * - only owner or techowner or jr admins can call this method.
     *
     */

    function updateStudentAddress(address _oldAddress, address _newAddress)
        public
        jrAdminLevel
    {
        studentsList[_oldAddress] = false;
        string[] memory uints = studentcourses[_oldAddress];
        for (uint256 i = 0; i < uints.length; i++) {
            courseStudentsList[uints[i]][_newAddress] = courseStudentsList[
                uints[i]
            ][_oldAddress];
            studentcourses[_newAddress].push(uints[i]);
        }
        studentsList[_newAddress] = true;

        emit StudentAddressUpdated(_oldAddress, _newAddress, now);
    }

    /** @dev Takes old student address, course code and amount
     * transfer given amount of tokens to the student
     * Emits a {TokensAwarded}
     *
     * Requirements
     * - student need to be added for that course
     *
     */

    function awardStudents(
        address _studentAddress,
        string memory _courseId,
        uint256 _amount
    ) public {
        require(studentsList[_studentAddress], "student is not whitelisted");
        require(
            coursefacultys[_courseId] == msg.sender,
            "Sender address is not matching with faculty addrss"
        );
        require(
            courseStudentsList[_courseId][_studentAddress],
            "Student not whitelisted for this course"
        );
        require(studentsList[_studentAddress], "student blocked");
        require(facultyList[msg.sender], "faculty blocked");
        require(
            tokenContract.transferFrom(owner(), _studentAddress, _amount),
            "Issue with transfer"
        );

        emit TokensAwarded(_studentAddress, msg.sender, _amount);
    }

    /** @dev Takes old jr admin address and new jr admin addrss as input.
     * blocks the old  address
     * whitelists the new address
     * Emits a {JrAdminUpdated}
     *
     * Requirements
     *
     * - only owner or techowner can call this method
     *
     */

    function updateJrAdmin(address _oldAddress, address _newAddress)
        public
        onlyOwner
    {
        jrAdminList[_oldAddress] = false;
        jrAdminList[_newAddress] = true;
        emit JrAdminUpdated(_oldAddress, _newAddress, now);
    }

    function updateStaff(address _oldAddress, address _newAddress)
        public
        onlyOwner
    {
        staffList[_oldAddress] = false;
        staffList[_newAddress] = true;
        emit staffAddressUpdated(_oldAddress, _newAddress, now);
    }

    function getcoursefaculty(string memory _courseId)
        public
        view
        returns (address)
    {
        return coursefacultys[_courseId];
    }

    function getStudentStatus(address _studentAddress)
        public
        view
        returns (bool)
    {
        return studentsList[_studentAddress];
    }

    function getfacultyStatus(address _facultyAddress)
        public
        view
        returns (bool)
    {
        return facultyList[_facultyAddress];
    }

    function getacademicRecordDetails(string memory _academicRecordID)
        public
        view
        returns (
            uint256,
            uint256,
            uint8
        )
    {
        return (
            allacademicRecords[_academicRecordID].startTimestamp,
            allacademicRecords[_academicRecordID].endTimestamp,
            allacademicRecords[_academicRecordID].status
        );
    }
}