/**
 *Submitted for verification at polygonscan.com on 2022-06-21
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

// File: newCombine.sol


pragma solidity ^0.8.7;






interface IGEM {
    function totalSupply() external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function setGemURI(uint256 gemId, string memory tokenURI)
        external
        returns (bool);

    function mintGem(address player, string memory tokenURI)
        external
        returns (uint256);

    function burnGem(uint256 gemId) external returns (bool);
}

interface IRAND {
    function getRandomNumber(address gameAddress)
        external
        returns (bytes32 requestId);
}

abstract contract GameRole is Context {
    address private _owner;
    uint256 private _games;

    mapping(address => bool) private _isGame;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event GameAdded(address indexed newGame);
    event GameRemoved(address indexed removedGame);

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
    function isGame(address who) public view returns (bool) {
        return _isGame[who];
    }

    /**
     * @dev Return total number of games.
     */
    function games() public view returns (uint256) {
        return _games;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "GameRole: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the game.
     */
    modifier onlyGame() {
        require(_isGame[_msgSender()], "GameRole: caller is not a game");
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
     * @dev Add a new account (`newGame`) as a game.
     * Can only be called by the current owner.
     */
    function addGame(address newGame) public onlyOwner {
        require(
            newGame != address(0),
            "GameRole: new game is the zero address"
        );
        require(!_isGame[newGame], "GameRole: this address is game");
        emit GameAdded(newGame);
        _isGame[newGame] = true;
        _games += 1;
    }

    /**
     * @dev Remove a game (`game`).
     * Can only be called by the current owner.
     */
    function removeGame(address game) public onlyOwner {
        require(_isGame[game], "GameRole: this address is not game");
        emit GameRemoved(game);
        _isGame[game] = false;
        _games -= 1;
    }
}

abstract contract StringUtil {
    constructor() {}

    function subString(
        uint256 startIndex,
        uint256 endIndex,
        string memory str
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function whereIs(string memory son, string memory father)
        internal
        pure
        returns (uint256)
    {
        bytes memory sonBytes = bytes(son);
        bytes memory fatherBytes = bytes(father);

        require(fatherBytes.length >= sonBytes.length);

        for (uint256 i = 0; i <= fatherBytes.length - sonBytes.length; i++) {
            bool flag = true;
            for (uint256 j = 0; j < sonBytes.length; j++) {
                if (fatherBytes[i + j] != sonBytes[j]) {
                    flag = false;
                    break;
                }
            }

            if (flag) {
                return i;
            }
        }

        return 0;
    }

    function stringsEquals(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if (l1 != b2.length) return false;
        for (uint256 i = 0; i < l1; i++) {
            if (b1[i] != b2[i]) return false;
        }
        return true;
    }

    function hexStringSum(string memory str)
        internal
        pure
        returns (uint256 sum)
    {
        bytes memory strBytes = bytes(str);
        bytes memory numBytes = bytes("0123456789abcdef");
        for (uint256 c = 0; c < strBytes.length; c++) {
            for (uint256 n = 0; n < numBytes.length; n++) {
                if (strBytes[c] == numBytes[n]) {
                    sum += n;
                }
            }
        }
    }
}

abstract contract GameBase is GameRole, ReentrancyGuard, StringUtil {
    using SafeMath for uint256;
    using Strings for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _userIds;

    struct Gem {
        address maker;
        uint256 id;
        uint256 birth;
        uint256 level;
        uint256 color;
        uint256 fromOne;
        uint256 fromTwo;
        uint256 success;
        bool isSettled;
    }

    string internal _name;
    string[] internal _keys = [
        "name",
        "maker",
        "birth",
        "level",
        "color",
        "properties"
    ];
    bool internal _gameIsLive = false;

    IGEM internal _gem;
    IRAND internal _rand;

    mapping(uint256 => Gem) internal _gems;
    mapping(bytes32 => uint256) internal _randMap;

    // Events
    event GemCombine(
        address indexed user,
        uint256 color,
        uint256 from1,
        uint256 from2,
        uint256 fromLevel,
        uint256 rate,
        uint256 gemId
    );
    event GemSettled(
        address indexed user,
        uint256 color,
        uint256 from1,
        uint256 from2,
        bool success,
        uint256 gemId,
        uint256 toLevel,
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

    function isGemsOwner(uint256 gem1, uint256 gem2)
        internal
        view
        returns (bool)
    {
        require(_gem.ownerOf(gem1) == _msgSender(), "Not your gem");
        require(_gem.ownerOf(gem2) == _msgSender(), "Not your gem");
        return true;
    }

    function getGemProperty(uint256 index, string memory uri)
        internal
        view
        returns (string memory)
    {
        require(index < _keys.length, "Invalid index");

        uint256 from = whereIs(_keys[index], uri) +
            bytes(_keys[index]).length +
            3;
        uint256 to;

        if (index == _keys.length - 1) {
            to = whereIs("}", uri);
        } else {
            to = whereIs(_keys[index + 1], uri) - 3;
        }

        return subString(from, to, uri);
    }

    function getGemPropertyNum(uint256 index, string memory uri)
        internal
        view
        returns (uint256 result)
    {
        require(index == 3 || index == 4, "Invalid index");
        string memory s = getGemProperty(index, uri);
        for (uint256 i = 0; i < 16; i++) {
            string memory si = i.toString();
            if (stringsEquals(s, si)) {
                result = i;
            }
        }
    }

    function gemQuality(string memory uri) internal view returns (uint256) {
        string memory properties = getGemProperty(5, uri);
        string memory quality = subString(3, 9, properties);
        uint256 sum = hexStringSum(quality);
        return sum;
    }

    function gemLevel(string memory uri) internal view returns (uint256) {
        return getGemPropertyNum(3, uri);
    }

    function gemColor(string memory uri) internal view returns (uint256) {
        return getGemPropertyNum(4, uri);
    }

    // Setter

    function toggleGameIsLive() external onlyOwner {
        _gameIsLive = !_gameIsLive;
    }

    function setGem(address _contract) external onlyOwner {
        _gem = IGEM(_contract);
    }

    // Methods
    function combineGem(uint256 gem1, uint256 gem2)
        external
        onlyLive
        nonReentrant
        returns (uint256)
    {   
        string memory uri1 = _gem.tokenURI(gem1);
        string memory uri2 = _gem.tokenURI(gem2);

        uint256 level1 = gemLevel(uri1);
        uint256 level2 = gemLevel(uri2);
        uint256 color1 = gemColor(uri1);
        uint256 color2 = gemColor(uri2);

        require(isGemsOwner(gem1, gem2));
        require(level1 < 15, "Need lower level gems");
        require(level1 == level2, "Need same level gems");
        require(color1 == color2, "Need same color gems");

        _burnGem(gem1);
        _burnGem(gem2);

        bytes32 requestId = _rand.getRandomNumber(address(this));
        uint256 gemId = _gem.mintGem(_msgSender(), "");

        Gem memory gem = Gem({
            maker: _msgSender(),
            id: gemId,
            birth: block.number,
            level: level1.add(1),
            color: color1,
            fromOne: gem1,
            fromTwo: gem2,
            success: (gemQuality(uri1) + gemQuality(uri2) + 320) / 5,
            isSettled: false
        });
        
        _randMap[requestId] = gemId;
        _gems[gemId] = gem;

        emit GemCombine(_msgSender(), color1, gem1, gem2, level1, gem.success, gemId);

        return gemId;
    }

    // Internal
    function _burnGem(uint256 id) internal {
        _gem.burnGem(id);
    }

    function settleRand(bytes32 requestId, uint256 randomness)
        public
        onlyRand
        nonReentrant
    {
        Gem storage gem = _gems[_randMap[requestId]];
        require(gem.id > 0, "Gem does not exist");
        require(gem.isSettled == false, "Gem is settled already");

        gem.isSettled = true;

        bool success = true;

        if (randomness % 100 <= gem.success) {
            success = false;
            gem.level = gem.level.sub(1);
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

        emit GemSettled(gem.maker, gem.color, gem.fromOne, gem.fromTwo, success, gem.id, gem.level, uri);
    }
}

contract Combination is GameBase {
    constructor(address gem, address rand) {
        _name = "Gem Combination - crystal.network";
        _gem = IGEM(gem);
        _rand = IRAND(rand);
        _gameIsLive = true;
    }
}