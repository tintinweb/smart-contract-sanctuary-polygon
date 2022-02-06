// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../utils/StringUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IGoldhunterDecoding {
    function isPirate(string calldata _metadata) external pure returns (bool);
    function isCrossedTheOcean(string calldata _metadata) external pure returns (bool);

    function getSkin(string calldata _metadata) external view returns (string memory);
    function getLegs(string calldata _metadata) external view returns (string memory);
    function getFeet(string calldata _metadata) external view returns (string memory);
    function getTshirt(string calldata _metadata) external view returns (string memory);
    function getHeadwear(string calldata _metadata) external view returns (string memory);
    function getMouth(string calldata _metadata) external view returns (string memory);
    function getNeck(string calldata _metadata) external view returns (string memory);
    function getSunglasses(string calldata _metadata) external view returns (string memory);
    function getTool(string calldata _metadata) external view returns (string memory);
    function getPegleg(string calldata _metadata) external view returns (string memory);
    function getHook(string calldata _metadata) external view returns (string memory);
    function getDress(string calldata _metadata) external view returns (string memory);
    function getFace(string calldata _metadata) external view returns (string memory);
    function getPatch(string calldata _metadata) external view returns (string memory);
    function getEars(string calldata _metadata) external view returns (string memory);
    function getHead(string calldata _metadata) external view returns (string memory);
    function getArm(string calldata _metadata) external view returns (string memory);
}

contract GoldhunterDecoding is Ownable {
    
    using StringUtils for string;

    mapping(string => string) public skins;
    mapping(string => string) public legs;
    mapping(string => string) public feet;
    mapping(string => string) public tshirts;
    mapping(string => string) public headwears;
    mapping(string => string) public mouths;
    mapping(string => string) public necks;
    mapping(string => string) public sunglasses;
    mapping(string => string) public tools;
    mapping(string => string) public peglegs;
    mapping(string => string) public hooks;
    mapping(string => string) public dresses;
    mapping(string => string) public faces;
    mapping(string => string) public patches;
    mapping(string => string) public ears;
    mapping(string => string) public heads;
    mapping(string => string) public arms;


    constructor() {
        skins["0"] = "null";
        skins["1"] = "human";
        skins["2"] = "skeleton";
        skins["3"] = "gold";
        skins["4"] = "zombie";
        skins["5"] = "cyborg";

        legs["00"] = "null";
        legs["01"] = "violet_shorts";
        legs["02"] = "white_shorts";
        legs["03"] = "orange_trousers";
        legs["04"] = "black_shorts";
        legs["05"] = "yellow_trousers";
        legs["06"] = "red_trousers";
        legs["07"] = "blue_shorts";
        legs["08"] = "green_shorts";
        legs["09"] = "brown_trousers";
        legs["10"] = "zombie_trousers";

        feet["00"] = "null";
        feet["01"] = "high_boots_red";
        feet["02"] = "white_sneakers";
        feet["03"] = "white_shoes";
        feet["04"] = "violet_sneakers";
        feet["05"] = "grey_shoes";
        feet["06"] = "red_sneakers";
        feet["07"] = "black_shoes";
        feet["08"] = "blue_sneakers";
        feet["09"] = "yellow_sneakers";
        feet["10"] = "high_boots_black";
        feet["11"] = "green_sneakers";
        feet["12"] = "work_shoes";
        feet["13"] = "sandals";

        tshirts["0"] = "null";
        tshirts["1"] = "black";
        tshirts["2"] = "blue";
        tshirts["3"] = "green";
        tshirts["4"] = "brown";
        tshirts["5"] = "orange";
        tshirts["6"] = "red";
        tshirts["7"] = "violet";
        tshirts["8"] = "yellow";
        tshirts["9"] = "white";

        headwears["00"] = "null";
        headwears["01"] = "jester_hat";
        headwears["02"] = "headband";
        headwears["03"] = "brains";
        headwears["04"] = "red_cap";
        headwears["05"] = "rice_hat";
        headwears["06"] = "turban";
        headwears["07"] = "chef";
        headwears["08"] = "white_cap";
        headwears["09"] = "red_bandana";
        headwears["10"] = "cowboy";
        headwears["11"] = "fedora";
        headwears["12"] = "mailman";
        headwears["13"] = "blue_cap";
        headwears["14"] = "visor";
        headwears["15"] = "beanie";
        headwears["16"] = "blue_hat";
        headwears["17"] = "capone";
        headwears["18"] = "santa";
        headwears["19"] = "sun_hat";
        headwears["20"] = "viking";
        headwears["21"] = "devil_horns";
        headwears["22"] = "gold_halo";
        headwears["23"] = "sombrero";
        headwears["24"] = "rainbow_afro";
        headwears["25"] = "crown";

        mouths["00"] = "null";
        mouths["01"] = "frown";
        mouths["02"] = "missing_tooth";
        mouths["03"] = "bloody_fangs";
        mouths["04"] = "smirk";
        mouths["05"] = "neutral";
        mouths["06"] = "wide_smile";
        mouths["07"] = "howling";
        mouths["08"] = "black_mask";
        mouths["09"] = "mustache";
        mouths["10"] = "kiss";
        mouths["11"] = "pipe";
        mouths["12"] = "beard";
        mouths["13"] = "cigarette";
        mouths["14"] = "gold_grills";
        mouths["15"] = "cheese";

        necks["00"] = "null";
        necks["01"] = "scarf";
        necks["02"] = "silver";
        necks["03"] = "gold";
        necks["04"] = "bowtie";
        necks["05"] = "pearls";
        necks["06"] = "mask";
        necks["07"] = "bandana";
        necks["08"] = "dress_tie";
        necks["09"] = "fang_beads";
        necks["10"] = "heart";
        necks["11"] = "diamond";

        sunglasses["00"] = "null";
        sunglasses["01"] = "xray";
        sunglasses["02"] = "3d_glasses";
        sunglasses["03"] = "red_glasses";
        sunglasses["04"] = "the_intellectual";
        sunglasses["05"] = "hipster";
        sunglasses["06"] = "blue_glasses";
        sunglasses["07"] = "rainbow";
        sunglasses["08"] = "basic_sun_protection";
        sunglasses["09"] = "dork";
        sunglasses["10"] = "nouns";
        sunglasses["11"] = "nightvision";

        tools["00"] = "null";
        tools["01"] = "chicken_leg";
        tools["02"] = "compas";
        tools["03"] = "pan";
        tools["04"] = "shovel";
        tools["05"] = "gold_ingot";
        tools["06"] = "lasso";
        tools["07"] = "torch";
        tools["08"] = "slingshot";
        tools["09"] = "hourglass";
        tools["10"] = "lamp";
        tools["11"] = "key";
        tools["12"] = "bo";
        tools["13"] = "map";
        tools["14"] = "pickaxe";
        tools["15"] = "umbrella";

        peglegs["0"] = "null";
        peglegs["1"] = "wooden";
        peglegs["2"] = "none";
        peglegs["3"] = "black";
        peglegs["4"] = "golden";

        hooks["0"] = "null";
        hooks["1"] = "silver";
        hooks["2"] = "none";
        hooks["3"] = "black";
        hooks["4"] = "golden";

        dresses["00"] = "null";
        dresses["01"] = "red_suit";
        dresses["02"] = "green_jacket";
        dresses["03"] = "shirt_striped";
        dresses["04"] = "yellow_jacket";
        dresses["05"] = "white_suit";
        dresses["06"] = "red_jacket";
        dresses["07"] = "violet_suit";
        dresses["08"] = "brown_suit";
        dresses["09"] = "blue_suit";
        dresses["10"] = "black_suite";

        faces["0"] = "null";
        faces["1"] = "big_mustache";
        faces["2"] = "double_braids";
        faces["3"] = "blonde_beard";
        faces["4"] = "imperial_mustache";
        faces["5"] = "skeleton";
        faces["6"] = "pipe";
        faces["7"] = "black_beard";
        faces["8"] = "wizard_beard";

        patches["0"] = "null";
        patches["1"] = "blue";
        patches["2"] = "black";
        patches["3"] = "love";
        patches["4"] = "red";
        patches["5"] = "gold";
        patches["6"] = "double";

        ears["0"] = "null";
        ears["1"] = "silver_hoop";
        ears["2"] = "gold_hoop";
        ears["3"] = "two_gold_piercings";
        ears["4"] = "diamond";

        heads["0"] = "null";
        heads["1"] = "yellow_bandana";
        heads["2"] = "wild_hair_dark";
        heads["3"] = "red_bandana";
        heads["4"] = "buzz_cut";
        heads["5"] = "black_bandana";
        heads["6"] = "pirate_hat_circle";
        heads["7"] = "pirate_hat";
        heads["8"] = "pirate_cap";
        
        arms["0"] = "null";
        arms["1"] = "bottle_of_rum";
        arms["2"] = "treasure_map";
        arms["3"] = "sword";
        arms["4"] = "gun";
        arms["5"] = "trident";
        arms["6"] = "bottle_of_whiskey";
        arms["7"] = "dagger";
        arms["8"] = "pirate_flag";
        arms["9"] = "bottle_of_wine";
        
    }

    ///// BOOLEAN METADATA DECODE /////

    function isCrossedTheOcean(string calldata _metadata) external pure returns (bool) {
        return _metadata.substring(0,0).compareStrings("2");
    }

    function isPirate(string calldata _metadata) external pure returns (bool) {
        return _metadata.substring(1,1).compareStrings("2");
    }

    ///// STRING METADATA CODE /////

    function getSkin(string calldata _metadata) external view returns (string memory) {
        return skins[_metadata.substring(2, 2)];
    }

    function getLegs(string calldata _metadata) external view returns (string memory) {
        return legs[_metadata.substring(3, 4)];
    }

    function getFeet(string calldata _metadata) external view returns (string memory) {
        return feet[_metadata.substring(5, 6)];
    }

    function getTshirt(string calldata _metadata) external view returns (string memory) {
        return tshirts[_metadata.substring(7, 7)];
    }

    function getHeadwear(string calldata _metadata) external view returns (string memory) {
        return headwears[_metadata.substring(8, 9)];
    }

    function getMouth(string calldata _metadata) external view returns (string memory) {
        return mouths[_metadata.substring(10, 11)];
    }

    function getNeck(string calldata _metadata) external view returns (string memory) {
        return necks[_metadata.substring(12, 13)];
    }

    function getSunglasses(string calldata _metadata) external view returns (string memory) {
        return sunglasses[_metadata.substring(14, 15)];
    }

    function getTool(string calldata _metadata) external view returns (string memory) {
        return tools[_metadata.substring(16, 17)];
    }

    // Generation 0 is Index 18

    function getPegleg(string calldata _metadata) external view returns (string memory) {
        return peglegs[_metadata.substring(19, 19)];
    }

    function getHook(string calldata _metadata) external view returns (string memory) {
        return hooks[_metadata.substring(20, 20)];
    }

    function getDress(string calldata _metadata) external view returns (string memory) {
        return dresses[_metadata.substring(21, 22)];
    }

    function getFace(string calldata _metadata) external view returns (string memory) {
        return faces[_metadata.substring(23, 23)];
    }

    function getPatch(string calldata _metadata) external view returns (string memory) {
        return patches[_metadata.substring(24, 24)];
    }

    function getEars(string calldata _metadata) external view returns (string memory) {
        return ears[_metadata.substring(25, 25)];
    }

    function getHead(string calldata _metadata) external view returns (string memory) {
        return heads[_metadata.substring(26, 26)];
    }
    
    function getArm(string calldata _metadata) external view returns (string memory) {
        return arms[_metadata.substring(27, 27)];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library StringUtils {

    function compareStrings(string memory a, string memory b) external pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Substring indexing is done from left -> right
    // Example. str = 0003050040002061101
    // str[0]  = 0
    // str[5]  = 5
    // str[18] = 1
    function substring(string memory str, uint inclStartIndex, uint inclEndIndex) external pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(inclEndIndex-inclStartIndex+1);
        for(uint i = inclStartIndex; i <= inclEndIndex; i++) {
            result[i-inclStartIndex] = strBytes[i];
        }
        return string(result);
    }

    function append(string calldata a, string calldata b) external pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function strToUint(string memory _str) external pure returns(uint256 res, bool err) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return (0, false);
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        return (res, true);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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