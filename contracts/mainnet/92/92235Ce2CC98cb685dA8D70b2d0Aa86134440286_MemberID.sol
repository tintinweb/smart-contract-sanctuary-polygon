/**
 *Submitted for verification at polygonscan.com on 2022-06-04
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

    constructor() {
        _status = _NOT_ENTERED;
    }

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

// File: memberId.sol


pragma solidity ^0.8.7;





interface IMEMBER {
    function userNameIndex(address _user) external view returns (uint256);

    function subScore(uint256 score, address account)
        external
        returns (uint256);

    function setName(uint256 nameIndex, address account)
        external
        returns (uint256);
}

abstract contract GameRole is Context {
    address private _owner;
    uint256 private _certifieds;

    mapping(address => bool) private _isCertified;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event CertifiedAdded(address indexed newCertified);
    event CertifiedRemoved(address indexed removedCertified);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Return True if address is a game.
     */
    function isCertified(address who) public view returns (bool) {
        return _isCertified[who];
    }

    /**
     * @dev Return total number of Certifieds.
     */
    function certifieds() public view returns (uint256) {
        return _certifieds;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "GameRole: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the Certified.
     */
    modifier onlyCertified() {
        require(
            _isCertified[_msgSender()],
            "GameRole: caller is not certified"
        );
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "GameRole: new owner is the zero address"
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

    /**
     * @dev Add a new account (`newCertified`) as a game.
     * Can only be called by the current owner.
     */
    function addCertified(address newCertified) public onlyOwner {
        require(
            newCertified != address(0),
            "GameRole: new game is the zero address"
        );
        require(!_isCertified[newCertified], "GameRole: this address is game");
        emit CertifiedAdded(newCertified);
        _isCertified[newCertified] = true;
        _certifieds += 1;
    }

    /**
     * @dev Remove a Certified (`certified`).
     * Can only be called by the current owner.
     */
    function removeCertified(address certified) public onlyOwner {
        require(
            _isCertified[certified],
            "GameRole: this address is not Certified"
        );
        emit CertifiedRemoved(certified);
        _isCertified[certified] = false;
        _certifieds -= 1;
    }
}

abstract contract GameBase is GameRole, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _userIds;

    struct User {
        uint256 id;
        uint256 referral;
        uint256 referees;
        uint256 level;
    }

    string internal _name;
    bool internal _gameIsLive = false;
    uint256 internal _maxLevel;
    uint256 internal _baseLevelPrice;

    IMEMBER internal _member;

    mapping(uint256 => address) internal _ids;
    mapping(address => User) internal _users;

    // Events
    event Registration(
        address indexed user,
        address indexed referral,
        uint256 id
    );

    // Modifiers
    modifier onlyLive() {
        require(_gameIsLive, "ERR: game is not live");
        _;
    }

    // View
    function name() external view returns (string memory) {
        return _name;
    }

    function totalUser() external view returns (uint256) {
        return _userIds.current();
    }

    function levelPrice(uint256 level) public view returns (uint256) {
        return _baseLevelPrice * (2**level);
    }

    function userId(address _user) public view returns (uint256) {
        return _member.userNameIndex(_user);
    }

    function userAddress(uint256 _user) public view returns (address) {
        return _ids[_user];
    }

    function idExist(uint256 _user) public view returns (bool) {
        return userAddress(_user) != address(0);
    }

    function userReferral(address _user) public view returns (uint256) {
        return _users[_user].referral;
    }

    function userReferralById(uint256 _user) public view returns (uint256) {
        return _users[_ids[_user]].referral;
    }

    function userLevel(address _user) public view returns (uint256) {
        return _users[_user].level;
    }

    function userLevelById(uint256 _user) public view returns (uint256) {
        return _users[_ids[_user]].level;
    }

    function userDetail(address _user) public view returns (User memory) {
        return _users[_user];
    }

    function userDetailById(uint256 _user) public view returns (User memory) {
        return _users[_ids[_user]];
    }

    // Setter

    function toggleGameIsLive() public onlyOwner {
        _gameIsLive = !_gameIsLive;
    }

    function setMaxLevel(uint256 _max) public onlyOwner {
        _maxLevel = _max;
    }

    function setUpgradePrice(uint256 _basePrice) public onlyOwner {
        _baseLevelPrice = _basePrice;
    }

    function setMembership(address _contract) external onlyOwner {
        _member = IMEMBER(_contract);
    }

    // Methods
    function initiaize() external onlyOwner returns (uint256) {
        require(_userIds.current() == 0, "ERR: Not New Game");
        uint256 id = _newUser(_msgSender(), uint256(1));
        _users[_msgSender()].level = _maxLevel;
        toggleGameIsLive();
        return id;
    }

    function register(address _user, uint256 _referral)
        external
        onlyLive
        onlyCertified
        nonReentrant
        returns (uint256 id, uint256 ref)
    {
        require(!(userId(_user) > 0), "ERR: Already registered");
        ref = _referral > _userIds.current() ? uint256(1) : _referral;
        id = _newUser(_user, ref);
        return (id, ref);
    }

    function upgrade() external onlyLive nonReentrant returns (uint256 level) {
        require(userId(_msgSender()) > 0, "ERR: Not registered");
        require(userLevel(_msgSender()) < _maxLevel, "ERR: Already Max Level");
        level = _upgrade(_msgSender());
        return level;
    }

    // Internal
    function _newUser(address _user, uint256 _referral)
        internal
        returns (uint256)
    {
        _userIds.increment();

        User memory user = User({
            id: _userIds.current(),
            referral: _referral,
            referees: uint256(0),
            level: uint256(0)
        });

        _ids[_userIds.current()] = _user;
        _users[_user] = user;
        _users[_ids[_referral]].referees++;

        _setName(_userIds.current(), _user);

        return _userIds.current();
    }

    function _upgrade(address _user) internal returns (uint256) {
        _member.subScore(levelPrice(_users[_user].level), _user);
        _users[_user].level += 1;
        return _users[_user].level;
    }

    function _setName(uint256 _value, address _user) internal {
        _member.setName(_value, _user);
    }

    function _subScore(uint256 _value, address _user) internal {
        _member.subScore(_value, _user);
    }
}

contract MemberID is GameBase {
    constructor(address member) {
        _name = "Membership ID - crystal.network";
        _member = IMEMBER(member);
        _maxLevel = uint256(100);
        _baseLevelPrice = uint256(10000);
    }
}