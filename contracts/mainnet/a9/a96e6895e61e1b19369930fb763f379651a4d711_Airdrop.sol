/**
 *Submitted for verification at polygonscan.com on 2022-06-04
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

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

// File: airdrop.sol


pragma solidity ^0.8.7;





interface IGEM {
    function totalSupply() external view returns (uint256);

    function setGemURI(uint256 gemId, string memory tokenURI)
        external
        returns (bool);

    function mintGem(address player, string memory tokenURI)
        external
        returns (uint256);

    function burnGem(uint256 gemId) external returns (bool);
}

interface IMID {
    struct User {
        uint256 id;
        uint256 referral;
        uint256 referees;
        uint256 level;
    }

    function totalUser() external view returns (uint256);

    function userId(address _user) external view returns (uint256);

    function userAddress(uint256 _user) external view returns (address);

    function idExist(uint256 _user) external view returns (bool);

    function userReferral(address _user) external view returns (uint256);

    function userReferralById(uint256 _user) external view returns (uint256);

    function userLevel(address _user) external view returns (uint256);

    function userLevelById(uint256 _user) external view returns (uint256);

    function userDetail(address _user) external view returns (User memory);

    function userDetailById(uint256 _user) external view returns (User memory);

    function register(address _user, uint256 _referral)
        external
        returns (uint256 id, uint256 ref);
}

interface IRAND {
    function getRandomNumber(address gameAddress)
        external
        returns (bytes32 requestId);
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
    using Strings for address;
    using Strings for uint256;

    struct User {
        uint256 points;
        uint256 unclaimed;
        uint256 claimed;
    }

    struct Gem {
        address maker;
        uint256 id;
        uint256 birth;
        uint256 level;
        uint256 color;
        bool isColorFixed;
        bool isSettled;
    }

    string internal _name;
    uint256 internal _gemPrice;
    uint256 internal _dirPoints;
    uint256 internal _indirPoints;
    uint256 internal _bestGem;

    bool internal _gameIsLive = false;

    IGEM internal _gem;
    IMID internal _mid;
    IRAND internal _rand;

    mapping(bytes32 => Gem) internal _gems;
    mapping(uint256 => User) internal _users;

    // Events
    event GemClaimed(address indexed user, uint256 gemId);
    event GemSettled(
        address indexed user,
        uint256 gemId,
        uint256 level,
        uint256 color,
        string uri
    );

    // Modifiers
    modifier onlyRand() {
        require(
            address(_rand) == _msgSender(),
            "ERR: caller is not the rand contract"
        );
        _;
    }

    modifier onlyLive() {
        require(_gameIsLive, "ERR: game is not live");
        _;
    }

    // View
    function name() external view returns (string memory) {
        return _name;
    }

    function gemPrice() public view returns (uint256) {
        return _gemPrice;
    }

    function refPoints() public view returns (uint256, uint256) {
        return (_dirPoints, _indirPoints);
    }

    function userDetail(address _user) public view returns (User memory) {
        return _users[_mid.userId(_user)];
    }

    function idDetail(uint256 _id) public view returns (User memory) {
        return _users[_id];
    }

    function idPoints(uint256 _id) public view returns (uint256) {
        return _users[_id].points;
    }

    function idUnclaimed(uint256 _id) public view returns (uint256) {
        return _users[_id].unclaimed;
    }

    function idClaimed(uint256 _id) public view returns (uint256) {
        return _users[_id].claimed;
    }

    // Setter

    function toggleGameIsLive() external onlyOwner {
        _gameIsLive = !_gameIsLive;
    }

    function setGem(address _contract) external onlyOwner {
        _gem = IGEM(_contract);
    }

    function setMemberID(address _contract) external onlyOwner {
        _mid = IMID(_contract);
    }

    function setRand(address _contract) external onlyOwner {
        _rand = IRAND(_contract);
    }

    function setBestGem(uint256 _value) external onlyOwner {
        _bestGem = _value % 16;
    }

    function setGemPrice(uint256 _value) external onlyOwner {
        _gemPrice = _value;
    }

    function setRefPoints(uint256 _dir, uint256 _indir) external onlyOwner {
        _dirPoints = _dir;
        _indirPoints = _indir;
    }

    // Methods
    function register(uint256 _referral)
        external
        onlyLive
        nonReentrant
        returns (uint256)
    {
        uint256 id;
        uint256 ref;
        (id, ref) = _mid.register(_msgSender(), _referral);
        _addPoints(ref, _dirPoints);
        _addPoints(_mid.userReferralById(ref), _indirPoints);
        return id;
    }

    function claim() external onlyLive nonReentrant returns (uint256) {
        _subUnclaimed(_mid.userId(_msgSender()));
        bytes32 requestId = _rand.getRandomNumber(address(this));
        uint256 gemId = _gem.mintGem(_msgSender(), "");

        Gem memory gem = Gem({
            maker: _msgSender(),
            id: gemId,
            birth: block.number,
            level: uint256(0),
            color: uint256(0),
            isColorFixed: false,
            isSettled: false
        });

        _gems[requestId] = gem;

        emit GemClaimed(_msgSender(), gemId);

        return gemId;
    }

    function settleRand(bytes32 requestId, uint256 randomness)
        public
        onlyRand
        nonReentrant
    {
        Gem storage gem = _gems[requestId];
        require(gem.id > 0, "Gem does not exist");
        require(gem.isSettled == false, "Gem is settled already");

        gem.isSettled = true;

        gem.level = _gemLevel(randomness);
        if (!gem.isColorFixed) {
            gem.color = randomness.mod(6);
        }

        string memory uri = string(
            abi.encodePacked(
                "{",
                '"name": "gem"',
                ", ",
                '"maker": "',
                Strings.toHexString(uint256(uint160(gem.maker)), 20),
                '", ',
                '"birth": ',
                gem.birth.toString(),
                ", ",
                '"level": ',
                gem.level.toString(),
                ", ",
                '"color": ',
                gem.color.toString(),
                ", ",
                '"properties": "',
                randomness.toHexString(),
                '"}'
            )
        );

        _gem.setGemURI(gem.id, uri);

        emit GemSettled(gem.maker, gem.id, gem.level, gem.color, uri);
    }

    // Internal
    function _gemLevel(uint256 randomness) internal view returns (uint256) {
        uint256 level = 0;
        for (uint256 i = 0; i <= _bestGem; i++) {
            randomness /= 10;
            if (randomness % 2 == 0) {
                level = i;
                break;
            }
        }
        return level;
    }

    function _addPoints(uint256 _id, uint256 _points) internal {
        if (
            _users[_id].unclaimed == 0 ||
            _users[_id].unclaimed < _mid.userLevelById(_id)
        ) {
            _users[_id].points += _points;
            if (_users[_id].points >= _gemPrice) {
                _users[_id].points = _users[_id].points.mod(_gemPrice);
                _addUnclaim(_id);
            }
        }
    }

    function _addUnclaim(uint256 _id) internal {
        _users[_id].unclaimed += 1;
    }

    function _subUnclaimed(uint256 _id) internal {
        require(_users[_id].unclaimed > 0);
        _users[_id].unclaimed = _users[_id].unclaimed.sub(1);
        _users[_id].claimed += 1;
    }
}

contract Airdrop is GameBase {
    constructor(
        address gem,
        address mid,
        address rand
    ) {
        _name = "Airdrop - crystal.network";
        _gem = IGEM(gem);
        _mid = IMID(mid);
        _rand = IRAND(rand);
        _gemPrice = uint256(6);
        _dirPoints = uint256(2);
        _indirPoints = uint256(1);
        _bestGem = uint256(3);
        _gameIsLive = true;
    }
}