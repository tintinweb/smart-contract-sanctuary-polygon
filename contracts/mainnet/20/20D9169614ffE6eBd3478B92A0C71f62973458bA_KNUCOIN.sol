// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
pragma solidity ^0.8.9;

contract Arrangements {
    enum ArrangementStatus { 
        ARRANGEMENT_CREATED,
        ARRANGEMENT_REMOVED
    }
    enum MembershipStatus {
        USER_ADDED,
        USER_REMOVED
    }
    event ArrangementEvent(uint128 indexed arrangementId, uint64 indexed userId, ArrangementStatus indexed arrangementStatus);
    event MembershipEvent(uint128 indexed arrangementId, uint64 indexed memberId, MembershipStatus indexed membershipStatus);

    struct Arrangement {
        bytes32 name;
        uint32 reward;
        uint64 creatorId;
        bool created;
        uint64[] memberList;
        mapping(uint64 => User) members;
    }

    struct User {
        uint64 sequenceNumber;
        bool isMember;
    }

    modifier _isArrangement(uint128 arrangementId) {
        require(isArrangement(arrangementId), "Arrangement doesn't exist!");
        _;
    }
    
    uint128 internal arrangementCount;
    mapping(uint128 => Arrangement) arrangements;

    function createArrangement(uint64 issuer, uint32 reward, bytes32 name) public virtual {
        arrangements[arrangementCount].name = name;
        arrangements[arrangementCount].reward = reward;
        arrangements[arrangementCount].creatorId = issuer;
        arrangements[arrangementCount].created = true;
        emit ArrangementEvent(arrangementCount, issuer, ArrangementStatus.ARRANGEMENT_CREATED);
        unchecked {
            ++arrangementCount;
        }
    }

    function removeArrangement(uint64 issuer, uint128 arrangementId) public virtual 
    _isArrangement(arrangementId) {
        delete arrangements[arrangementId];
        
        emit ArrangementEvent(arrangementId, issuer, ArrangementStatus.ARRANGEMENT_REMOVED);
    }

    function addMember(uint64 issuer, uint64 memberId, uint128 arrangementId) public virtual 
    _isArrangement(arrangementId) {
        require(issuer == memberId || issuer == arrangements[arrangementId].creatorId, "You're not allowed!");
        require(!arrangements[arrangementId].members[memberId].isMember, "The user is a member!");
        arrangements[arrangementId].memberList.push(memberId);
        arrangements[arrangementId].members[memberId].isMember = true;
        arrangements[arrangementId].members[memberId].sequenceNumber = uint64(arrangements[arrangementId].memberList.length - 1);
        
        emit MembershipEvent(arrangementId, memberId, MembershipStatus.USER_ADDED);
    }

    function removeMember(uint64 issuer, uint64 memberId, uint128 arrangementId) public virtual 
    _isArrangement(arrangementId) {
        require(issuer == memberId || issuer == arrangements[arrangementId].creatorId, "You're not allowed!");
        require(arrangements[arrangementId].members[memberId].isMember, "The user is not a member");
        uint256 length = arrangements[arrangementId].memberList.length;  
        uint64 sequenceNumber = arrangements[arrangementId].members[memberId].sequenceNumber;
        uint64 last = arrangements[arrangementId].memberList[length - 1];
        
        delete arrangements[arrangementId].members[memberId];

        arrangements[arrangementId].members[last].sequenceNumber = sequenceNumber;
        arrangements[arrangementId].memberList[last] = last;
        arrangements[arrangementId].memberList.pop();
        
        emit MembershipEvent(arrangementId, memberId, MembershipStatus.USER_REMOVED);
    }

    function getMembers(uint128 arrangementId) public view 
    _isArrangement(arrangementId) returns(uint64[] memory) {
        return arrangements[arrangementId].memberList;
    }

    function getTotalMembers(uint128 arrangementId) public view 
    _isArrangement(arrangementId) returns(uint256) {
        return arrangements[arrangementId].memberList.length;
    }

    function getArrangement(uint128 arrangementId) public view 
    _isArrangement(arrangementId) returns(bytes32 name, uint32 reward, uint64 creatorId) {
        return (
            arrangements[arrangementId].name,
            arrangements[arrangementId].reward,
            arrangements[arrangementId].creatorId
        );
    }

    function isCreator(uint64 memberId, uint128 arrangementId) public view returns(bool) {
        return arrangements[arrangementId].creatorId == memberId;
    }

    function isMember(uint64 memberId, uint128 arrangementId) public view returns(bool) {
        return arrangements[arrangementId].members[memberId].isMember;
    }

    function isArrangement(uint128 arrangementId) public view returns(bool) {
        return arrangements[arrangementId].created;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CTERC20 {
    event Transfer(uint64 indexed from, uint64 indexed to, uint256 amount);
    mapping(uint64 => uint32) private _balances; 
    
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _mint(uint64 userId, uint32 amount) internal {
        _balances[userId] += amount;
        emit Transfer(0, userId, amount);
    }

    function _redeem(uint64 userId, uint32 amount) internal {
        require(_balances[userId] >= amount, "The user doesn't possess this much!");
        _balances[userId] -= amount;
        emit Transfer(userId, 0, amount);
    }

    function balanceOf(uint64 userId) public view returns(uint32) {
        return _balances[userId];
    }

     function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint8) {
        return 3;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Teachers.sol";
import "./CTERC20.sol";
import "./Arrangements.sol";

contract KNUCOIN is Ownable, Teachers, CTERC20 {
    constructor(
        uint64 issuer,
        uint128 teacherArrangementLimit, 
        string memory name_, 
        string memory symbol_
        ) CTERC20(name_, symbol_) Teachers(issuer, teacherArrangementLimit) {}

    function mint(uint64 issuer, uint64 memberId, uint32 amount) external 
    onlyOwner _isTeacher(issuer) {
        _mint(memberId, amount);
    }

    function redeem(uint64 issuer, uint64 memberId, uint32 amount) external 
    onlyOwner _isTeacher(issuer) {
        _redeem(memberId, amount);
    }

    function addTeacher(uint64 issuer, uint64 memberId) public override 
    onlyOwner {
        super.addTeacher(issuer, memberId);
    }

    function removeTeacher(uint64 issuer, uint64 memberId) public override 
    onlyOwner {
        super.removeTeacher(issuer, memberId);
    }

    function createArrangement(uint64 issuer, uint32 reward, bytes32 name) public override 
    onlyOwner {
        super.createArrangement(issuer, reward, name);
    }

    function removeArrangement(uint64 issuer, uint128 arrangementId) public override 
    onlyOwner {
        super.removeArrangement(issuer, arrangementId);
    }

    function finishArrangement(uint64 issuer, uint128 arrangementId) external 
    onlyOwner _isTeacher(issuer) {
        uint64[] memory members = getMembers(arrangementId);
        uint32 reward = arrangements[arrangementId].reward;
        super.removeArrangement(issuer, arrangementId);
        
        for (uint64 i = 0; i < members.length; i++) {
            _mint(members[i], reward);
        }
    }

    function addMember(uint64 issuer, uint64 memberId, uint128 arrangementId) public override 
    onlyOwner {
        super.addMember(issuer, memberId, arrangementId);
    }

    function removeMember(uint64 issuer, uint64 memberId, uint128 arrangementId) public override
    onlyOwner {
        super.removeMember(issuer, memberId, arrangementId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Arrangements.sol";
import "./CTERC20.sol";

library ArrayFunctionality {
    function removeArrangement(uint128[] storage array, uint128 index) public {
        array[index] = array[array.length - 1];
        array.pop();
    }
}

contract Teachers is Arrangements {
    enum TeacherStatus { TEACHER_ADDED, TEACHER_REMOVED }
    event TeacherEvent(uint64 indexed teacherId, uint64 indexed userId, TeacherStatus indexed teacherStatus);

    using ArrayFunctionality for uint128[];
    struct _Arrangement {
        uint128 sequenceNumber;
        bool isArrangement;
    }
    struct Teacher {
        bool bearer;
        uint128[] arrangementList;
        mapping(uint128 => _Arrangement) arrangements;
    }

    modifier _isTeacher(uint64 userId) {
        require(isTeacher(userId), "You're not allowed!");
        _;
    }

    constructor(uint64 issuer, uint128 arrangementLimit) {
        bearers[issuer].bearer = true;
        ARRANGEMENT_LIMIT = arrangementLimit;
        emit TeacherEvent(0, issuer, TeacherStatus.TEACHER_ADDED);
    }

    uint128 public immutable ARRANGEMENT_LIMIT;
    mapping(uint64 => Teacher) bearers;

    function addTeacher(uint64 issuer, uint64 memberId) public virtual 
    _isTeacher(issuer) {
        if (!isTeacher(memberId)) {
            bearers[memberId].bearer = true;
            emit TeacherEvent(issuer, memberId, TeacherStatus.TEACHER_ADDED);
        }
    }

    function removeTeacher(uint64 issuer, uint64 memberId) public virtual 
    _isTeacher(issuer) {
        if (isTeacher(memberId)) {
            bearers[memberId].bearer = false;
            emit TeacherEvent(issuer, memberId, TeacherStatus.TEACHER_REMOVED);
        }
    }

    function createArrangement(uint64 issuer, uint32 reward, bytes32 name) public override virtual _isTeacher(issuer) {
        require(bearers[issuer].arrangementList.length < ARRANGEMENT_LIMIT, "You exceed the arrangement limit");
        bearers[issuer].arrangements[arrangementCount].sequenceNumber = uint128(bearers[issuer].arrangementList.length);
        bearers[issuer].arrangements[arrangementCount].isArrangement = true;
        bearers[issuer].arrangementList.push(arrangementCount);
        super.createArrangement(issuer, reward, name);
    }

    function removeArrangement(uint64 issuer, uint128 arrangementId) public override virtual _isTeacher(issuer) {
        require(bearers[issuer].arrangements[arrangementId].isArrangement, "You're not allowed!");
        
        uint256 length = bearers[issuer].arrangementList.length;  
        uint128 sequenceNumber = bearers[issuer].arrangements[arrangementId].sequenceNumber;
        uint128 last = bearers[issuer].arrangementList[length - 1];
       
        delete bearers[issuer].arrangements[arrangementId];

        bearers[issuer].arrangements[last].sequenceNumber = sequenceNumber;
        bearers[issuer].arrangementList[sequenceNumber] = last;
        bearers[issuer].arrangementList.pop();        

        super.removeArrangement(issuer, arrangementId);
    }

    function getArrangementsOf(uint64 teacherId) public view returns(uint128[] memory) {
        return bearers[teacherId].arrangementList;
    }

    function getTotalArrangements(uint64 teacherId) public view returns(uint256) {
        return bearers[teacherId].arrangementList.length;
    }

    function isTeacher(uint64 memberId) public view returns(bool) {
        return bearers[memberId].bearer;
    }
}