// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./utils/Random.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract ApeironPlanetGenerator is Random {
    enum CoreType {
        Elemental,
        Mythic,
        Arcane,
        Divine,
        Primal
    }
    // enum Bloodline {
    //     Pure,    //0
    //     Duo,     //1
    //     Tri,     //2
    //     Mix      //3
    // }
    mapping(CoreType => mapping(uint256 => uint256))
        public bloodlineRatioPerCoreType;
    mapping(CoreType => uint256) haveTagRatioPerCoreType;

    struct PlanetTag {
        uint256 id;
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
    }
    mapping(uint256 => PlanetTag[]) public planetTagsPerBloodline;

    // enum ElementType {
    //     Fire,   //0
    //     Water,  //1
    //     Air,    //2
    //     Earth   //3
    // }

    event GenerateGeneId(
        uint256 bloodline,
        uint256[] elementOrders,
        uint256[] attributes,
        uint256 geneId
    );

    constructor() {
        bloodlineRatioPerCoreType[CoreType.Primal][
            0 /*Bloodline.Pure*/
        ] = 100;

        bloodlineRatioPerCoreType[CoreType.Divine][
            0 /*Bloodline.Duo*/
        ] = 10;
        bloodlineRatioPerCoreType[CoreType.Divine][
            1 /*Bloodline.Duo*/
        ] = 90;

        bloodlineRatioPerCoreType[CoreType.Arcane][
            0 /*Bloodline.Pure*/
        ] = 2;
        bloodlineRatioPerCoreType[CoreType.Arcane][
            1 /*Bloodline.Duo*/
        ] = 30;
        bloodlineRatioPerCoreType[CoreType.Arcane][
            2 /*Bloodline.Tri*/
        ] = 68;

        bloodlineRatioPerCoreType[CoreType.Mythic][
            0 /*Bloodline.Pure*/
        ] = 1;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            1 /*Bloodline.Duo*/
        ] = 9;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            2 /*Bloodline.Tri*/
        ] = 72;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            3 /*Bloodline.Mix*/
        ] = 18;

        bloodlineRatioPerCoreType[CoreType.Elemental][
            2 /*Bloodline.Tri*/
        ] = 70;
        bloodlineRatioPerCoreType[CoreType.Elemental][
            3 /*Bloodline.Mix*/
        ] = 30;

        haveTagRatioPerCoreType[CoreType.Primal] = 0;
        haveTagRatioPerCoreType[CoreType.Divine] = 20;
        haveTagRatioPerCoreType[CoreType.Arcane] = 10;
        haveTagRatioPerCoreType[CoreType.Mythic] = 10;
        haveTagRatioPerCoreType[CoreType.Elemental] = 10;

        //18 tags for Duo
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(1, 0, 55, 0, 55)); //Archipelago
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(2, 0, 0, 0, 75)); //Tallmountain Falls
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(3, 0, 75, 0, 0)); //Deep Sea
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(4, 55, 0, 0, 55)); //Redrock Mesas
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(5, 0, 0, 0, 65)); //Mega Volcanoes
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(6, 75, 0, 0, 0)); //Pillars of Flame
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(7, 0, 0, 55, 55)); //Karsts
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(8, 0, 0, 0, 60)); //Hidden Caves
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(9, 0, 0, 75, 0)); //Floating Lands
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(10, 55, 55, 0, 0)); //Ghostlight Swamp
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(11, 0, 65, 0, 0)); //Boiling Seas
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(12, 65, 0, 0, 0)); //Flametouched Oasis
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(13, 0, 55, 55, 0)); //White Frost
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(14, 0, 50, 0, 0)); //Monsoon
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(15, 0, 0, 65, 0)); //Frozen Gale
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(16, 55, 0, 55, 0)); //Anticyclonic Storm
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(17, 60, 0, 0, 0)); //Conflagration
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(18, 0, 0, 60, 0)); //Hurricane

        //28 tags for Tri
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(19, 35, 35, 0, 35)); //Rainforest
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(20, 0, 0, 0, 55)); //Jungle Mountains
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(21, 0, 55, 0, 0)); //Tallest Trees
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(22, 55, 0, 0, 0)); //Steamwoods
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(23, 0, 40, 0, 40)); //Alpine
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(24, 40, 0, 0, 40)); //Sandy Jungle
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(25, 40, 40, 0, 0)); //Mangrove
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(26, 0, 35, 35, 35)); //Tundra
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(27, 0, 0, 0, 40)); //Snow-capped Peaks
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(28, 0, 40, 0, 0)); //Frozen Lakes
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(29, 0, 0, 55, 0)); //Taiga
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(30, 0, 35, 0, 35)); //Hibernia
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(31, 0, 0, 40, 40)); //Prairie
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(32, 0, 40, 40, 0)); //Hailstorm
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(33, 35, 0, 35, 35)); //Wasteland
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(34, 0, 0, 0, 40)); //Sheerstone Spires
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(35, 40, 0, 0, 0)); //Lava Fields
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(36, 0, 0, 40, 0)); //Howling Gales
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(37, 35, 0, 0, 35)); //Dunes
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(38, 0, 0, 35, 35)); //Barren Valleys
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(39, 40, 0, 40, 0)); //Thunder Plains
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(40, 35, 35, 35, 0)); //Salt Marsh
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(41, 0, 40, 0, 0)); //Coral Reef
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(42, 40, 0, 0, 0)); //Fire Swamp
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(43, 0, 0, 40, 0)); //Windswept Heath
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(44, 35, 35, 0, 0)); //Beachside Mire
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(45, 0, 35, 35, 0)); //Gentlesnow Bog
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(46, 35, 0, 35, 0)); //Stormy Night Swamp

        //16 tags for Mix
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(47, 30, 30, 30, 30)); //Utopia
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(48, 25, 25, 25, 25)); //Garden
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(49, 0, 0, 0, 35)); //Mountain
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(50, 0, 35, 0, 0)); //Ocean
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(51, 35, 0, 0, 0)); //Wildfire
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(52, 0, 0, 35, 0)); //Cloud
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(53, 0, 25, 0, 25)); //Forest
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(54, 25, 0, 0, 25)); //Desert
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(55, 0, 0, 25, 25)); //Hill
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(56, 25, 25, 0, 0)); //Swamp
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(57, 0, 25, 25, 0)); //Snow
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(58, 25, 0, 25, 0)); //Plains
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(59, 0, 0, 0, 30)); //Dryland
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(60, 0, 30, 0, 0)); //Marsh
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(61, 30, 0, 0, 0)); //Drought
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(62, 0, 0, 30, 0)); //Storm
    }

    function _getBloodline(CoreType coreType, uint256 randomBaseValue)
        internal
        view
        returns (uint256)
    {
        uint256 picked = 3; //Bloodline.Mix;

        uint256 baseValue = 0;
        for (
            uint256 idx = 0; /*Bloodline.Pure*/
            idx <= 3; /*Bloodline.Mix*/
            idx++
        ) {
            // from Pure to Mix
            baseValue += bloodlineRatioPerCoreType[coreType][idx];
            if (_randomRangeByBaseValue(randomBaseValue, 1, 100) <= baseValue) {
                picked = idx;
                break;
            }
        }

        return picked;
    }

    function _getPlanetTag(
        CoreType coreType,
        uint256 bloodline,
        uint256[2] memory randomBaseValues
    ) internal view returns (PlanetTag memory) {
        PlanetTag memory planetTag;
        //exclude if it is pure
        if (
            bloodline != 0 && /*Bloodline.Pure*/
            //according to ratio
            haveTagRatioPerCoreType[coreType] >=
            _randomRangeByBaseValue(randomBaseValues[0], 1, 100)
        ) {
            //random pick a tag from pool
            planetTag = planetTagsPerBloodline[bloodline][
                _randomByBaseValue(
                    randomBaseValues[1],
                    planetTagsPerBloodline[bloodline].length
                )
            ];
        }
        return planetTag;
    }

    function _getElementOrders(
        uint256 bloodline,
        PlanetTag memory planetTag,
        uint256[4] memory randomBaseValues
    ) internal pure returns (uint256[] memory) {
        uint256[4] memory orders;
        uint256[] memory results = new uint256[](1 + uint256(bloodline));
        uint256 pickedIndex;

        //have not any tag
        if (planetTag.id == 0) {
            //dominant element index
            pickedIndex = _randomByBaseValue(randomBaseValues[0], 4);
        }
        //have any tag
        else {
            uint256 possibleElementSize;
            if (planetTag.fire > 0) {
                orders[possibleElementSize++] = 0; //ElementType.Fire
            }
            if (planetTag.water > 0) {
                orders[possibleElementSize++] = 1; //ElementType.Water
            }
            if (planetTag.air > 0) {
                orders[possibleElementSize++] = 2; //ElementType.Air
            }
            if (planetTag.earth > 0) {
                orders[possibleElementSize++] = 3; //ElementType.Earth
            }

            //dominant element index (random pick from possibleElements)
            pickedIndex = orders[
                _randomByBaseValue(randomBaseValues[0], possibleElementSize)
            ];
        }

        orders[0] = 0; //ElementType.Fire
        orders[1] = 1; //ElementType.Water
        orders[2] = 2; //ElementType.Air
        orders[3] = 3; //ElementType.Earth

        //move the specified element to 1st place
        (orders[0], orders[pickedIndex]) = (orders[pickedIndex], orders[0]);
        //assign the value as result
        results[0] = orders[0];

        //process the remaining elements
        for (uint256 i = 1; i <= bloodline; i++) {
            //random pick the index from remaining elements
            pickedIndex = i + _randomByBaseValue(randomBaseValues[i], 4 - i);
            //move the specified element to {i}nd place
            (orders[i], orders[pickedIndex]) = (orders[pickedIndex], orders[i]);
            //assign the value as result
            results[i] = orders[i];
        }

        return results;
    }

    function _getMaxBetweenValueAndPlanetTag(
        uint256 value,
        uint256 elementType,
        PlanetTag memory planetTag
    ) internal pure returns (uint256) {
        if (planetTag.id > 0) {
            if (
                elementType == 0 /*ElementType.Fire*/
            ) {
                return Math.max(value, planetTag.fire);
            } else if (
                elementType == 1 /*ElementType.Water*/
            ) {
                return Math.max(value, planetTag.water);
            } else if (
                elementType == 2 /*ElementType.Air*/
            ) {
                return Math.max(value, planetTag.air);
            } else if (
                elementType == 3 /*ElementType.Earth*/
            ) {
                return Math.max(value, planetTag.earth);
            }
        }

        return value;
    }

    function _getElementValues(
        uint256 bloodline,
        PlanetTag memory planetTag,
        uint256[] memory elementOrders,
        uint256[3] memory randomBaseValues
    ) internal pure returns (uint256[4] memory) {
        require(elementOrders.length == bloodline + 1, "invalid elementOrders");

        uint256[4] memory values;

        if (
            bloodline == 0 /*Bloodline.Pure*/
        ) {
            values[uint256(elementOrders[0])] = 100;
        } else if (
            bloodline == 1 /*Bloodline.Duo*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 50, 59),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] =
                100 -
                values[uint256(elementOrders[0])];
        } else if (
            bloodline == 2 /*Bloodline.Tri*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 33, 43),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] = _randomRangeByBaseValue(
                randomBaseValues[1],
                23,
                Math.min(43, 95 - values[uint256(elementOrders[0])])
            );
            values[uint256(elementOrders[2])] =
                100 -
                values[uint256(elementOrders[0])] -
                values[uint256(elementOrders[1])];
        } else if (
            bloodline == 3 /*Bloodline.Mix*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 25, 35),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] = _randomRangeByBaseValue(
                randomBaseValues[1],
                20,
                34
            );
            values[uint256(elementOrders[2])] = _randomRangeByBaseValue(
                randomBaseValues[2],
                20,
                Math.min(
                    34,
                    95 -
                        values[uint256(elementOrders[0])] -
                        values[uint256(elementOrders[1])]
                )
            );
            values[uint256(elementOrders[3])] =
                100 -
                values[uint256(elementOrders[0])] -
                values[uint256(elementOrders[1])] -
                values[uint256(elementOrders[2])];
        }

        return values;
    }

    function _generateGeneId(CoreType coreType) internal returns (uint256) {
        uint256 bloodline = _getBloodline(coreType, _getRandomBaseValue());
        PlanetTag memory planetTag = _getPlanetTag(
            coreType,
            bloodline,
            [_getRandomBaseValue(), _getRandomBaseValue()]
        );
        uint256[] memory elementOrders = _getElementOrders(
            bloodline,
            planetTag,
            [
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue()
            ]
        );
        uint256[4] memory elementValues = _getElementValues(
            bloodline,
            planetTag,
            elementOrders,
            [
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue()
            ]
        );
        uint256[] memory attributes = new uint256[](18);
        attributes[0] = elementValues[0]; //element: fire
        attributes[1] = elementValues[1]; //element: water
        attributes[2] = elementValues[2]; //element: air
        attributes[3] = elementValues[3]; //element: earth
        attributes[4] = planetTag.id; //primeval legacy tag
        attributes[5] = _randomRange(0, 1); //body: sex
        attributes[6] = _randomRange(0, 11); //body: weapon
        attributes[7] = _randomRange(0, 3); //body: body props
        attributes[8] = _randomRange(0, 5); //body: head props
        attributes[9] = _randomRange(0, 23); //skill: cskill1
        attributes[10] = (attributes[9] + _randomRange(1, 23)) % 24; //skill: cskill2
        attributes[11] = (attributes[10] + _randomRange(1, 22)) % 24; //skill: cskill3
        if (attributes[11] == attributes[9]) {
            attributes[11] = (attributes[11] + 1) % 24;
        }
        attributes[12] = _randomRange(0, 31); //skill: pskill1
        attributes[13] = (attributes[12] + _randomRange(1, 31)) % 32; //skill: pskill2
        attributes[14] = _randomRange(0, 2); //class
        attributes[15] = _randomRange(0, 31); //special gene
        // attributes[16] = 0; //generation 1st digit
        // attributes[17] = 0; //generation 2nd digit
        uint256 geneId = _convertToGeneId(attributes);
        emit GenerateGeneId(bloodline, elementOrders, attributes, geneId);
        return geneId;
    }

    function _convertToGeneId(uint256[] memory attributes)
        internal
        pure
        returns (uint256)
    {
        uint256 geneId = 0;
        for (uint256 id = 0; id < attributes.length; id++) {
            geneId += attributes[id] << (8 * id);
        }

        return geneId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Random {
    uint256 randomNonce;

    function __getRandomBaseValue(uint256 _nonce) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            _nonce
        )));
    }

    function _getRandomBaseValue() internal returns (uint256) {
        randomNonce++;
        return __getRandomBaseValue(randomNonce);
    }

    function __random(uint256 _nonce, uint256 _modulus) internal view returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return __getRandomBaseValue(_nonce) % _modulus;
    }

    function _random(uint256 _modulus) internal returns (uint256) {
        randomNonce++;
        return __random(randomNonce, _modulus);
    }

    function _randomByBaseValue(uint256 _baseValue, uint256 _modulus) internal pure returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return _baseValue % _modulus;
    }

    function __randomRange(uint256 _nonce, uint256 _start, uint256 _end) internal view returns (uint256) {
        if (_end > _start) {
            return _start + __random(_nonce, _end + 1 - _start);
        }
        else {
            return _end + __random(_nonce, _start + 1 - _end);
        }
    }

    function _randomRange(uint256 _start, uint256 _end) internal returns (uint256) {
        randomNonce++;
        return __randomRange(randomNonce, _start, _end);
    }

    function _randomRangeByBaseValue(uint256 _baseValue, uint256 _start, uint256 _end) internal pure returns (uint256) {
        if (_end > _start) {
            return _start + _randomByBaseValue(_baseValue, _end + 1 - _start);
        }
        else {
            return _end + _randomByBaseValue(_baseValue, _start + 1 - _end);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}