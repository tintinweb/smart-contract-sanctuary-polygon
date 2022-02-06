// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IShipDecoding} from "./ShipDecoding.sol";
import {IHouseDecoding} from "./HouseDecoding.sol";
import {IGoldhunterDecoding} from "./GoldhunterDecoding.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GHGMetadata is Ownable {
    
    mapping(uint16 => string) public goldhuntersMetadata;
    mapping(uint16 => string) public shipsMetadata;
    mapping(uint16 => string) public housesMetadata;

    IGoldhunterDecoding public goldhunterDecoding;
    IShipDecoding public shipDecoding;
    IHouseDecoding public houseDecoding;
    
    constructor() {}

    ///// SETTER FUNCTIONS - ONLY OWNER /////

    function setGoldhunterMetadata(uint16[] calldata _tokenIds, string[] calldata _metadata) external onlyOwner {
        for(uint i = 0; i < _tokenIds.length; i++) {
            goldhuntersMetadata[_tokenIds[i]] = _metadata[i];
        }
    }

    function setShipsMetadata(uint16[] calldata _tokenIds, string[] calldata _metadata) external onlyOwner {
        for(uint i = 0; i < _tokenIds.length; i++) {
            shipsMetadata[_tokenIds[i]] = _metadata[i];
        }
    }

    function setHouseMetadata(uint16[] calldata _tokenIds, string[] calldata _metadata) external onlyOwner {
        for(uint i = 0; i < _tokenIds.length; i++) {
            housesMetadata[_tokenIds[i]] = _metadata[i];
        }
    }

    function setGoldhunterDecoding(address _goldhunterDecoding) external onlyOwner {
        goldhunterDecoding = IGoldhunterDecoding(_goldhunterDecoding);
    }

    function setShipDecoding(address _shipDecoding) external onlyOwner {
        shipDecoding = IShipDecoding(_shipDecoding);
    }

    function setHouseDecoding(address _houseDecoding) external onlyOwner {
        houseDecoding = IHouseDecoding(_houseDecoding);
    }

    //// GETTER FUNCTIONS - METADATA /////

    function getGoldhunterMetadata(uint16 _tokenId) external view returns (string memory) {
        return goldhuntersMetadata[_tokenId];
    }

    function getShipMetadata(uint16 _tokenId) external view returns (string memory) {
        return shipsMetadata[_tokenId];
    }

    function getHouseMetadata(uint16 _tokenId) external view returns (string memory) {
        return housesMetadata[_tokenId];
    }

    ///// GETTER FUNCTIONS - SHIP TRAITS /////

    function shipIsPirate(uint16 _tokenId) external view returns (bool) {
        return shipDecoding.isPirate(shipsMetadata[_tokenId]);
    }

    function shipIsCrossedTheOcean(uint16 _tokenId) external view returns (bool) {
        return shipDecoding.isCrossedTheOcean(shipsMetadata[_tokenId]);
    }
    
    function getShipBackground(uint16 _tokenId) external view returns (string memory) {
        return shipDecoding.getBackground(shipsMetadata[_tokenId]);
    }

    function getShipShip(uint16 _tokenId) external view returns (string memory) {
        return shipDecoding.getShip(shipsMetadata[_tokenId]);
    }

    function getShipFlag(uint16 _tokenId) external view returns (string memory) {
        return shipDecoding.getFlag(shipsMetadata[_tokenId]);
    }

    function getShipMast(uint16 _tokenId) external view returns (string memory) {
        return shipDecoding.getMast(shipsMetadata[_tokenId]);
    }

    function getShipAnchor(uint16 _tokenId) external view returns (string memory) {
        return shipDecoding.getAnchor(shipsMetadata[_tokenId]);
    }

    function getShipSail(uint16 _tokenId) external view returns (string memory) {
        return shipDecoding.getSail(shipsMetadata[_tokenId]);
    }

    function getShipWaves(uint16 _tokenId) external view returns (string memory) {
        return shipDecoding.getWaves(shipsMetadata[_tokenId]);
    }

    ///// GETTER FUNCTIONS - HOUSE TRAITS /////

    function getHouseBackground(uint16 _tokenId) external view returns (string memory) {
        return houseDecoding.getBackground(housesMetadata[_tokenId]);
    }

    function getHouseType(uint16 _tokenId) public view returns (string memory) {
        return houseDecoding.getType(housesMetadata[_tokenId]);
    }

    function getHouseWindow(uint16 _tokenId) public view returns (string memory) {
        return houseDecoding.getWindow(housesMetadata[_tokenId]);
    }

    function getHouseDoor(uint16 _tokenId) public view returns (string memory) {
        return houseDecoding.getDoor(housesMetadata[_tokenId]);
    }

    function getHouseRoof(uint16 _tokenId) public view returns (string memory) {
        return houseDecoding.getRoof(housesMetadata[_tokenId]);
    }

    function getHouseForeground(uint16 _tokenId) public view returns (string memory) {
        return houseDecoding.getForeground(housesMetadata[_tokenId]);
    }

    ///// GETTER FUNCTIONS - GOLDHUNTER TRAITS /////

    function goldhunterIsCrossedTheOcean(uint16 _tokenId) public view returns (bool) {
        return goldhunterDecoding.isCrossedTheOcean(goldhuntersMetadata[_tokenId]);
    }

    function goldhunterIsPirate(uint16 _tokenId) public view returns (bool) {
        return goldhunterDecoding.isPirate(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterIsGen0(uint16 _tokenId) public pure returns (bool) {
        return _tokenId < 10000;
    }

    function getGoldhunterSkin(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getSkin(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterLegs(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getLegs(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterFeet(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getFeet(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterTshirt(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getTshirt(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterHeadwear(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getHeadwear(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterMouth(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getMouth(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterNeck(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getNeck(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterSunglasses(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getSunglasses(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterTool(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getTool(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterPegleg(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getPegleg(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterHook(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getHook(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterDress(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getDress(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterFace(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getFace(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterPatch(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getPatch(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterEars(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getEars(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterHead(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getHead(goldhuntersMetadata[_tokenId]);
    }

    function getGoldhunterArm(uint16 _tokenId) public view returns (string memory) {
        return goldhunterDecoding.getArm(goldhuntersMetadata[_tokenId]);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../utils/StringUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IShipDecoding {
    function isPirate(string calldata _metadata) external pure returns (bool);
    function isCrossedTheOcean(string calldata _metadata) external pure returns (bool);

    function getBackground(string calldata _metadata) external view returns (string memory);
    function getShip(string calldata _metadata) external view returns (string memory);
    function getFlag(string calldata _metadata) external view returns (string memory);
    function getMast(string calldata _metadata) external view returns (string memory);
    function getAnchor(string calldata _metadata) external view returns (string memory);
    function getSail(string calldata _metadata) external view returns (string memory);
    function getWaves(string calldata _metadata) external view returns (string memory);
}

contract ShipDecoding is Ownable {
    
    using StringUtils for string;

    mapping(string => string) public backgrounds;
    mapping(string => string) public ships;
    mapping(string => string) public flags;
    mapping(string => string) public masts;
    mapping(string => string) public anchors;
    mapping(string => string) public sails;
    mapping(string => string) public waves;

    constructor() {
        backgrounds["0"] = "null";
        backgrounds["1"] = "day";
        backgrounds["2"] = "bay";
        backgrounds["3"] = "night";
        backgrounds["4"] = "island";
        backgrounds["5"] = "harbour";

        ships["00"] = "null";
        ships["01"] = "cyborg";
        ships["02"] = "ice";
        ships["03"] = "classic";
        ships["04"] = "mahogany";
        ships["05"] = "pink";
        ships["06"] = "diamond";
        ships["07"] = "ocean_green";
        ships["08"] = "bone";
        ships["09"] = "royal";
        ships["10"] = "gold";

        flags["0"] = "null";
        flags["1"] = "blue";
        flags["2"] = "orange";
        flags["3"] = "violet";
        flags["4"] = "red";
        flags["5"] = "brown";
        flags["6"] = "green";
        flags["7"] = "pink";
        flags["8"] = "yellow";

        masts["0"] = "null";
        masts["1"] = "diamond";
        masts["2"] = "gold";
        masts["3"] = "ice";
        masts["4"] = "wood";
        masts["5"] = "bone";

        anchors["0"] = "null";
        anchors["1"] = "classic";
        anchors["2"] = "steel";
        anchors["3"] = "diamond";
        anchors["4"] = "ice";
        anchors["5"] = "gold";
        anchors["6"] = "bone";

        sails["00"] = "null";
        sails["01"] = "orange";
        sails["02"] = "classic";
        sails["03"] = "green";
        sails["04"] = "pennant_chain";
        sails["05"] = "pirate_white";
        sails["06"] = "white_stripes";
        sails["07"] = "white";
        sails["08"] = "violet";
        sails["09"] = "yellow";
        sails["10"] = "blue";
        sails["11"] = "pink";
        sails["12"] = "pirate_black";
        sails["13"] = "bulb_chain";
        sails["14"] = "red";
        sails["15"] = "colored";
        sails["16"] = "gold";
        sails["17"] = "pirate_red";

        waves["0"] = "null";
        waves["1"] = "blue";
        waves["2"] = "red";
        waves["3"] = "yellow";
        waves["4"] = "green";
    }

    ///// BOOLEAN METADATA DECODE /////

    function isPirate(string calldata _metadata) external pure returns (bool) {
        return _metadata.substring(0,0).compareStrings("2");
    } 

    function isCrossedTheOcean(string calldata _metadata) external pure returns (bool) {
        return _metadata.substring(1, 1).compareStrings("2");
    }

    ///// STRING METADATA DECODE /////

    function getBackground(string calldata _metadata) external view returns (string memory) {
        return backgrounds[_metadata.substring(2, 2)];
    }

    function getShip(string calldata _metadata) external view returns (string memory) {
        return ships[_metadata.substring(3, 4)];
    }

    function getFlag(string calldata _metadata) external view returns (string memory) {
        return flags[_metadata.substring(5, 5)];
    }

    function getMast(string calldata _metadata) external view returns (string memory) {
        return masts[_metadata.substring(6, 6)];
    }

    function getAnchor(string calldata _metadata) external view returns (string memory) {
        return anchors[_metadata.substring(7, 7)];
    }

    function getSail(string calldata _metadata) external view returns (string memory) {
        return sails[_metadata.substring(8, 9)];
    }

    function getWaves(string calldata _metadata) external view returns (string memory) {
        return waves[_metadata.substring(10, 10)];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../utils/StringUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IHouseDecoding {
    function getBackground(string calldata _metadata) external view returns (string memory);
    function getType(string calldata _metadata) external view returns (string memory);
    function getWindow(string calldata _metadata) external view returns (string memory);
    function getDoor(string calldata _metadata) external view returns (string memory);
    function getRoof(string calldata _metadata) external view returns (string memory);
    function getForeground(string calldata _metadata) external view returns (string memory);
}

contract HouseDecoding is Ownable {
    
    using StringUtils for string;

    mapping(string => string) public backgrounds;
    mapping(string => string) public types;
    mapping(string => string) public windows;
    mapping(string => string) public doors;
    mapping(string => string) public roofs;
    mapping(string => string) public foregrounds;

    constructor() {
        backgrounds["0"] = "null";
        backgrounds["1"] = "day";
        backgrounds["2"] = "forest";
        backgrounds["3"] = "river";
        backgrounds["4"] = "beach";
        backgrounds["5"] = "field";
        backgrounds["6"] = "cave";
        backgrounds["7"] = "night";

        types["0"] = "null";
        types["1"] = "pink";
        types["2"] = "classic";
        types["3"] = "cyborg";
        types["4"] = "mahogany";
        types["5"] = "brick";
        types["6"] = "diamond";
        types["7"] = "bone";
        types["8"] = "gold";

        windows["0"] = "null";
        windows["1"] = "diamond";
        windows["2"] = "classic";
        windows["3"] = "steel";
        windows["4"] = "gold";
        windows["5"] = "circle";
        windows["6"] = "bone";

        doors["00"] = "null";
        doors["01"] = "purple";
        doors["02"] = "blue";
        doors["03"] = "red";
        doors["04"] = "classic";
        doors["05"] = "green";
        doors["06"] = "white";
        doors["07"] = "brown";
        doors["08"] = "yellow";
        doors["09"] = "white_stripes";
        doors["10"] = "pink";
        doors["11"] = "orange";

        roofs["0"] = "null";
        roofs["1"] = "wood";
        roofs["2"] = "bricks";
        roofs["3"] = "bone";
        roofs["4"] = "thatch";
        roofs["5"] = "diamond";
        roofs["6"] = "gold";

        foregrounds["0"] = "null";
        foregrounds["1"] = "bushes";
        foregrounds["2"] = "grass";
        foregrounds["3"] = "flower_bed";
        foregrounds["4"] = "dirt";
    }

    ///// STRING METADATA DECODE /////

    function getBackground(string calldata _metadata) external view returns (string memory) {
        return backgrounds[_metadata.substring(0, 0)];
    }

    function getType(string calldata _metadata) external view returns (string memory) {
        return types[_metadata.substring(1, 1)];
    }

    function getWindow(string calldata _metadata) external view returns (string memory) {
        return windows[_metadata.substring(2, 2)];
    }

    function getDoor(string calldata _metadata) external view returns (string memory) {
        return doors[_metadata.substring(3, 4)];
    }

    function getRoof(string calldata _metadata) external view returns (string memory) {
        return roofs[_metadata.substring(5, 5)];
    }

    function getForeground(string calldata _metadata) external view returns (string memory) {
        return foregrounds[_metadata.substring(6, 6)];
    }

}

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