/// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Interface of the fighting bots ERC721 compliant contract.
 */
interface IFightingBotsNftContract {
    function mintTrooper(address to, string memory mintHash) external returns (uint256);
}

abstract contract BotParts {
    string[] headParts = ["Bungie", "The Look", "Biter", "Stay Frosty", "Headbutt", "Sat-Attack", "Electric Feel",
    "Punk Buster", "Old Switcharoo", "Nobreather", "Hot Shades", "Spitter", "Loudmouth", "The Xena Pinch",
    "Greetings!", "Ups'a'Daisy", "Sharp Vision", "Chomper", "Chill Out", "The Ram", "Death From Above",
    "CPR", "Punk Buster Buster", "Redirected Assistance", "Mask-Up", "Sharp Looker", "Hurley", "Omegaphone",
    "Weak-Spot Spotter", "The Saboteur", "Rock & Hard Place", "Evil Eye", "Infected Bite", "Frost-Bite",
    "Head-Master", "Air-Strike", "Power-Drain", "Corruptor", "Decoy Self", "Fan-Club", "Critical-Eye",
    "Foulmouth", "A Stunning Voice", "Achille's Hell", "The Trojan", "Beam Me Up Scotty",
    "An Eye for an Eye", "Corrupting Bite", "Freeze Breeze", "Concussion", "Emergency Protocol",
    "Energy Vampire", "Ram-Jam", "Divide and Conquer", "Air Conditioner", "Death-Stare", "Rocket Rapper",
    "The Wailer", "Ace in the Hole", "The Inside Job"];

    string[] torsoParts = ["Warm Inside", "Nipple Twister", "Bear Hug", "Droppin a hot one", "Power Flasher", "Stinger",
    "Adblock Off", "All Tied Up", "Net Value", "Voodoo Magic Man", "I am Death", "Skunk", "The Tarkin", "Melter", "Fly-By",
    "Heartburn", "Heartbreaker", "Shreddy Krueger", "Bombs Away", "Electric Hug", "Stinger Swarm", "Dataleak",
    "That's a Wrap!", "Fisherman", "Head-Banger", "The Little Boy", "Polluter", "The Goldfinger", "Have a Blast",
    "The Birds", "Mr. Lava-Lava", "Turnaround", "The Greater Good", "Die-No-Might", "Light Ripple", "Gun Control",
    "Immunity", "Hog-Tie", "Poacher", "Rorschach", "The Fatman", "Gas-assassination", "Joint Welder", "Armor Breaker",
    "Air Jammers", "Mod Melter", "Shaken not Stirred", "Pulverizer", "Big Bada-Boom", "Blackout", "Not the Bees!",
    "Directive Overwrite", "Family Ties", "Master Trapper", "Clone Attack", "Nuketown", "Toxic Mist", "Ammo Melter",
    "Armor Scrapper", "Air Commander"];


    string[] legsParts = ["Putting The Foot", "Get A Grip", "Foot Locker", "Jumpman", "Floor Scrub", "Muddy Roads",
    "Rollin'", "Kick Back", "Tripwire", "The Muhammad Ali", "Turbo Jump", "Flubber", "Carwars", "Showstopper", "Toe Stepper",
    "Mazel Tov", "Rooted", "The Billie Jean", "Double Jump", "Xenoblood", "Slippery When Wet", "Roll-Out", "Roundhouse",
    "Bootstrapper", "The Bullet-Dodger", "Rocketman", "The Bouncer", "Hot Wheels", "The Wall", "Runover", "Romper-Stomper",
    "Dug-Deep", "Foot-Shocker", "Leg Stretcher", "Sole Melter", "Slime-Time", "Gateway Driver", "The Shuffler",
    "Arrow to the Knee", "Jumpin' Jack", "Jetride", "Anticorrosive", "Bad Karma", "Protected", "The Trampler", "Groundshaker",
    "Foundation", "Power Walker", "High Reacher", "Toxic Quicksand", "Gross Income", "Skate-or-Die", "Kick Off",
    "The Trench Connection", "Acrobatic", "Blast Off", "Lay off the Acid", "Car-nage", "Givin' a Damn", "The Mowdown"];


    string[] laParts = ["Nailed It", "Pay Per Cut", "Fishhook", "Hammer Timer", "Thunder Struck", "Gunslinger",
    "Need a Light?", "Lumberjack", "En Garde!", "What the Fork?", "Search and Destroy", "No, Thanks!", "Poker", "Catch!",
    "My Little Friend", "The Stapler", "Slice 'n' Dice", "The Scorpion", "The Woodpecker", "Electric Avenue", "Quick Draw",
    "Heartwarming", "Reel-Axe a Little", "Half the Bot", "Pokestroke", "El Supremo", "Hold-Up!", "Slasher", "Hot Potato",
    "Long Tall Sally", "Pin-Down", "Halved", "There She Blows!", "The Percussionist", "Large Charge", "Marauder", "Pyromaniac",
    "Rip and Tear", "Deflector", "Fork-et About it", "Kingslayer", "Unflinched", "Now that's a Knife!", "Throwback",
    "Get to the Choppa!", "Rusty Nails", "Chop-Shop", "The Chest Burster", "The Drum Solo", "Circuit Stir-Fry", "Quicksilver",
    "Let It Burn", "Bury the Hatchet", "Flunger", "Forknife", "Herd Culler", "You Shall Not Pass", "Blade Frenzy",
    "Pineapple Express", "Bullet-Hell"];

    string[] raParts = ["Knock-Knock", "Cut The Trap", "Hardened", "Spare Change", "The Sneeze", "Hackerman", "Mi Scuzi",
    "I'll Be Back", "Bullseye!", "Stick Around", "Full Metal Jacket", "Pump it Up", "Light Up!", "Akimboom", "Cueball",
    "Homewrecker", "Chop Suey", "Solid Snake", "Pickpocket", "The Slimer", "Power Glove", "Rat-At-At", "Double Trouble",
    "Cross-Blow", "Stuck in a Moment", "Short Bursts", "Double Barrel", "The Toaster", "Hardboiled", "The Turkey", "The Mash",
    "Saw It First", "Concrete Feet", "Deconstructor", "Molasses", "Jagged Alliance", "The Capone", "The Red-Herrings",
    "Trick-o-Chet", "The Clogger", "Get Some!", "Sawed-Off", "The Firestarter", "Burst Thirst", "Home-Run", "The Ricochet",
    "The Amputator", "Stoned to Death", "Scrapped-Up", "Over Greaser", "Energy Hack", "Spitfire", "Revolving Trio",
    "Bolt-Rain", "Master-Plaster", "Yippee Ki Yay", "Slug-Fest", "Napalm in the morning", "Gun-Fu", "Sonic Boom"];

    string[] rarities = ["common", "rare", "epic", "legendary"];

    function isValidHead(string memory part) internal view returns (bool) {
        return contains(headParts, part) || contains(rarities, part);
    }

    function isValidLa(string memory part) internal view returns (bool) {
        return contains(laParts, part) || contains(rarities, part);
    }

    function isValidRa(string memory part) internal view returns (bool) {
        return contains(raParts, part) || contains(rarities, part);
    }

    function isValidTorso(string memory part) internal view returns (bool) {
        return contains(torsoParts, part) || contains(rarities, part);
    }

    function isValidLegs(string memory part) internal view returns (bool) {
        return contains(legsParts, part) || contains(rarities, part);
    }


    function contains(string[] memory array, string memory value) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (compare(array[i], value)) {
                return true;
            }
        }
        return false;
    }

    function compare(string memory str1, string memory str2) private pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}


contract BotsMinter is BotParts, Ownable, Pausable {

    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;

    EnumerableSet.AddressSet private whitelistedMinters;

    IFightingBotsNftContract public fightingBotsContract;

    string private constant HASH_PREFIX = "mint_hash_prefix_";

    uint private totalMints;

    mapping(uint => BotMintData) mintingData;


    event BotMint(uint idx, uint256 tokenId, address to);

    constructor(address trooperContractAddress) {
        fightingBotsContract = IFightingBotsNftContract(trooperContractAddress);

    }

    struct BotMintData {
        uint256 botId;
        string head;
        string torso;
        string legs;
        string la;
        string ra;
    }

    function getTotalMints() external view returns (uint) {
        return totalMints;
    }

    function getMintDataIdx(uint idx) external view returns (BotMintData memory) {
        return mintingData[idx];
    }


    function mintBot(string memory head, string memory torso, string memory legs, string memory la, string memory ra, address to) external {

        require(to != address(this), "Incorrect address");
        require(isMinter(_msgSender()), "Sender is not allowed to mint");
        validateBotParts(head, torso, legs, la, ra);

        string memory mintHash = string(abi.encodePacked(HASH_PREFIX, totalMints.toString()));
        uint256 botId = fightingBotsContract.mintTrooper(to, mintHash);

        mintingData[totalMints] = BotMintData(botId, head, torso, legs, la, ra);

        totalMints++;
    }

    function validateBotParts(
        string memory head,
        string memory torso,
        string memory legs,
        string memory la,
        string memory ra
    ) private view {
        require(isValidHead(head), "The head is invalid");
        require(isValidTorso(torso), "The torso is invalid");
        require(isValidLa(la), "The left arm is invalid");
        require(isValidRa(ra), "The right arm is invalid");
        require(isValidLegs(legs), "The legs is invalid");
    }

    function addMinter(address minter) external onlyOwner {
        whitelistedMinters.add(minter);
    }

    function removeMinter(address minter) external onlyOwner {
        whitelistedMinters.remove(minter);
    }

    function isMinter(address minter) public view returns (bool) {
        return whitelistedMinters.contains(minter);
    }
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