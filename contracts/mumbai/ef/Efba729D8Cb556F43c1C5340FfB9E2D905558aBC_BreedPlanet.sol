// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
// pragma abicoder v2;

// import "@openzeppelin/contracts/utils/Address.sol";
// import "./utils/Random.sol";
import "./ApeironPlanetGenerator.sol";
import "./PlanetMeta.sol";
import "./ApeironPlanet.sol";

// contract BreedPlanet is Random {
contract BreedPlanet is ApeironPlanetGenerator {
    ApeironPlanet public immutable planetContract;
    uint256 currentPlanetId = 4585;

    // Mapping from token ID to NextBreeding time
    mapping(uint256 => uint256) private planetNextBreedMap;
    mapping(uint256 => uint256) private planetNextBornMap; // todo

    event BreedSucess(uint256 _tokenId);
    event BornSucess(uint256 _tokenId);

    struct ElementStruct {
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
        uint256 totalWeight;
        uint256 domainValue;
        uint256 domainIndex;
    }

    constructor(address _nftAddress) {
        // require(_nftAddress.isContract(), "_nftAddress must be a contract");
        planetContract = ApeironPlanet(_nftAddress);
    }

    function _getCurrentPlanetId() internal view returns (uint256) {
        return currentPlanetId;
    }

    function getParentID(uint256 planetId)
        public
        view
        returns (uint256, uint256)
    {
        uint256 parentAId = 0;
        uint256 parentBId = 0;
        PlanetMeta.PlanetData memory planetData;
        (planetData, ) = planetContract.getPlanetData(planetId);
        if (planetData.parents.length == 2) {
            parentAId = planetData.parents[0];
            parentBId = planetData.parents[1];
        }
        return (parentAId, parentBId);
    }

    function _hasParent(uint256 planetId) internal view returns (bool) {
        PlanetMeta.PlanetData memory planetData;
        (planetData, ) = planetContract.getPlanetData(planetId);
        if (planetData.parents.length == 2) {
            return true;
        }
        return false;
    }

    function _getParentAndGrandparentIDArray(uint256 planetId)
        internal
        view
        returns (uint256[] memory)
    {
        require(_hasParent(planetId), "planet have no parents");
        uint256 parentAId;
        uint256 parentBId;
        (parentAId, parentBId) = getParentID(planetId);
        uint256[] memory parents = _getParentIDArray(parentAId, parentBId);
        return parents;
    }

    // get A & B parents, A,B Index is 0,1
    function _getParentIDArray(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 parentCount = 2;
        uint256 parentAAId = planetAId;
        uint256 parentABId = planetAId;
        uint256 parentBAId = planetBId;
        uint256 parentBBId = planetBId;
        if (_hasParent(planetAId)) {
            parentCount += 2;
            (parentAAId, parentABId) = getParentID(planetAId);
        }
        if (_hasParent(planetBId)) {
            parentCount += 2;
            (parentBAId, parentBBId) = getParentID(planetBId);
        }

        uint256 index = 2;
        uint256[] memory parents = new uint256[](parentCount);
        parents[0] = planetAId;
        parents[1] = planetBId;
        if (parentAAId != planetAId && parentABId != planetAId) {
            parents[index++] = parentAAId;
            parents[index++] = parentABId;
        }
        if (parentBAId != planetBId && parentBBId != planetBId) {
            parents[index++] = parentBAId;
            parents[index] = parentBBId;
        }
        return parents;
    }

    function _parentIsRepeated(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (bool)
    {
        uint256[] memory parentsArray = _getParentIDArray(planetAId, planetBId);
        for (uint256 id = 0; id < parentsArray.length - 1; id++) {
            for (uint256 id2 = id + 1; id2 < parentsArray.length; id2++) {
                if (
                    parentsArray[id] == parentsArray[id2] &&
                    parentsArray[id] != 0
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    function checkCanBreed(uint256 planetAId, uint256 planetBId)
        public
        view
        returns (bool)
    {
        // planet data
        PlanetMeta.PlanetData memory planetAData;
        PlanetMeta.PlanetData memory planetBData;
        (planetAData, ) = planetContract.getPlanetData(planetAId);
        (planetBData, ) = planetContract.getPlanetData(planetBId);

        // require(
        //     planetAData.lastBreedTime + 14 * oneDayInterval < block.timestamp &&
        //         planetBData.lastBreedTime + 14 * oneDayInterval <
        //         block.timestamp,
        //     "14 days cooldown for each breeding"
        // );
        require(
            planetNextBreedMap[planetAId] < block.timestamp &&
                planetNextBreedMap[planetBId] < block.timestamp,
            "14 days cooldown for each breeding"
        );

        // planet reach max breed count
        require(
            planetAData.breedCount + 1 <= planetAData.breedCountMax &&
                planetBData.breedCount + 1 <= planetBData.breedCountMax,
            "planet reach max breed count"
        );

        // planet can't breed with parent and itself
        require(
            !_parentIsRepeated(planetAId, planetBId),
            "planet can't breed with parent"
        );

        // todo APRS and ANIMA Fees is require

        return true;
    }

    function _checkAndAddBreedCountMax(uint256 planetId) internal {
        PlanetMeta.PlanetData memory planetData;
        (planetData, ) = planetContract.getPlanetData(planetId);
        // speacial handle no parent breedCountMax
        if (!_hasParent(planetId) && planetData.breedCountMax == 0) {
            planetContract.updatePlanetData(
                planetId,
                planetData.gene,
                0,
                0,
                3,
                false
            );
        }
    }

    function breed(uint256 planetAId, uint256 planetBId) external {
        _checkAndAddBreedCountMax(planetAId);
        _checkAndAddBreedCountMax(planetBId);

        if (checkCanBreed(planetAId, planetBId)) {
            uint256[] memory parents = new uint256[](2);
            parents[0] = planetAId;
            parents[1] = planetBId;
            currentPlanetId++;
            planetContract.safeMint(0, parents, msg.sender, currentPlanetId);
            // 14 days cooldown for each breeding
            // 28 days if grandparent are same
            bool isGrandparentRepeat = false;
            uint256[] memory parentAArray;
            uint256[] memory parentBArray;
            if (_hasParent(parents[0])) {
                parentAArray = _getParentAndGrandparentIDArray(parents[0]);
            } else {
                parentAArray = new uint256[](1);
                parentAArray[0] = parents[0];
            }
            if (_hasParent(parents[1])) {
                parentBArray = _getParentAndGrandparentIDArray(parents[1]);
            } else {
                parentBArray = new uint256[](1);
                parentBArray[0] = parents[1];
            }
            for (uint256 i = 0; i < parentAArray.length; i++) {
                for (uint256 j = 0; j < parentBArray.length; j++) {
                    if (parentAArray[i] == parentBArray[j]) {
                        isGrandparentRepeat = true;
                    }
                }
            }
            uint256 breedInterval;
            if (isGrandparentRepeat) {
                breedInterval = 28 * 3600 * 24;
            } else {
                breedInterval = 14 * 3600 * 24;
            }

            planetNextBreedMap[planetAId] = block.timestamp + breedInterval;
            planetNextBreedMap[planetBId] = block.timestamp + breedInterval;

            emit BreedSucess(currentPlanetId);
        }
    }

    // born function
    function born(uint256 planetId) external {
        PlanetMeta.PlanetData memory planetData;
        (planetData, ) = planetContract.getPlanetData(planetId);
        // check can born
        require(planetData.bornTime == 0, "Planet already born");
        require(_hasParent(planetId), "Planet has no parent");
        require(
            (planetData.createTime + (3600 * 24 * 7)) < block.timestamp,
            "Not born for 7 days"
        );

        // todo update planet.gene
        uint256[] memory attributes = _updateAttributesByParentData(planetId);
        uint256 geneId = _convertToGeneId(attributes);

        // update planet as borned
        planetContract.updatePlanetData(planetId, geneId, 0, 0, 3, true);
        emit BornSucess(planetId);
    }

    function _updateRemainValueForElementStruct(
        ElementStruct memory elementStruct
    ) internal returns (ElementStruct memory) {
        uint256 totalValue = elementStruct.fire +
            elementStruct.water +
            elementStruct.air +
            elementStruct.earth;
        uint256 remainValue;
        uint256 baseValue;
        if (totalValue < 100) {
            remainValue = 100 - totalValue;
            if (remainValue > 0) {
                uint256 randomElement = _randomRange(0, 3);
                // do two times
                for (uint256 i = 0; i < 2; i++) {
                    if (randomElement == 0 && elementStruct.fire == 0) {
                        randomElement = 1;
                    }
                    if (randomElement == 1 && elementStruct.water == 0) {
                        randomElement = 2;
                    }
                    if (randomElement == 2 && elementStruct.air == 0) {
                        randomElement = 3;
                    }
                    if (randomElement == 3 && elementStruct.earth == 0) {
                        randomElement = 0;
                    }
                }
                if (randomElement == 0) {
                    elementStruct.fire += remainValue;
                } else if (randomElement == 1) {
                    elementStruct.water += remainValue;
                } else if (randomElement == 2) {
                    elementStruct.air += remainValue;
                } else if (randomElement == 3) {
                    elementStruct.earth += remainValue;
                }
            }
        } else if (totalValue > 100) {
            if (elementStruct.domainIndex == 1) {
                remainValue = 100 - elementStruct.fire;
                baseValue =
                    elementStruct.water +
                    elementStruct.air +
                    elementStruct.earth;
                elementStruct.water = ((elementStruct.water * remainValue) /
                    (baseValue));
                elementStruct.air = ((elementStruct.air * remainValue) /
                    (baseValue));
                elementStruct.earth = ((elementStruct.earth * remainValue) /
                    (baseValue));
            } else if (elementStruct.domainIndex == 2) {
                remainValue = 100 - elementStruct.water;
                baseValue =
                    elementStruct.fire +
                    elementStruct.air +
                    elementStruct.earth;
                elementStruct.fire = ((elementStruct.fire * remainValue) /
                    (baseValue));
                elementStruct.air = ((elementStruct.air * remainValue) /
                    (baseValue));
                elementStruct.earth = ((elementStruct.earth * remainValue) /
                    (baseValue));
            } else if (elementStruct.domainIndex == 3) {
                remainValue = 100 - elementStruct.air;
                baseValue =
                    elementStruct.fire +
                    elementStruct.water +
                    elementStruct.earth;
                elementStruct.fire = ((elementStruct.fire * remainValue) /
                    (baseValue));
                elementStruct.water = ((elementStruct.water * remainValue) /
                    (baseValue));
                elementStruct.earth = ((elementStruct.earth * remainValue) /
                    (baseValue));
            } else if (elementStruct.domainIndex == 4) {
                remainValue = 100 - elementStruct.earth;
                baseValue =
                    elementStruct.fire +
                    elementStruct.water +
                    elementStruct.air;
                elementStruct.fire = ((elementStruct.fire * remainValue) /
                    (baseValue));
                elementStruct.water = ((elementStruct.water * remainValue) /
                    (baseValue));
                elementStruct.air = ((elementStruct.air * remainValue) /
                    (baseValue));
            }
            // after redistribute value, total value may be below 100
            elementStruct = _updateRemainValueForElementStruct(elementStruct);
        }
        return elementStruct;
    }

    function _updateAttributesByParentData(uint256 planetId)
        internal
        returns (uint256[] memory)
    {
        uint256 random;
        uint256 random2;
        uint256 random3;

        uint256[] memory parents = _getParentAndGrandparentIDArray(planetId);
        require(parents.length >= 2, "planet have no parents");

        PlanetMeta.PlanetData memory parentAData;
        PlanetMeta.PlanetData memory parentBData;
        (parentAData, ) = planetContract.getPlanetData(parents[0]);
        (parentBData, ) = planetContract.getPlanetData(parents[1]);

        uint256[] memory parentAAttributes = _convertToAttributes(
            parentAData.gene,
            18
        );
        uint256[] memory parentBAttributes = _convertToAttributes(
            parentBData.gene,
            18
        );

        // element
        ElementStruct memory elementStruct = ElementStruct(0, 0, 0, 0, 0, 0, 0);
        for (uint256 id = 0; id < parents.length; id++) {
            PlanetMeta.PlanetData memory planetData;
            (planetData, ) = planetContract.getPlanetData(parents[id]);
            uint256[] memory planetAttributes = _convertToAttributes(
                planetData.gene,
                18
            );

            uint256 weight = 1;
            if (id == 0 || id == 1) {
                weight = 3;
            }
            elementStruct.fire += planetAttributes[0] * weight;
            elementStruct.water += planetAttributes[1] * weight;
            elementStruct.air += planetAttributes[2] * weight;
            elementStruct.earth += planetAttributes[3] * weight;
            elementStruct.totalWeight += weight;
        }
        elementStruct.fire = elementStruct.fire / elementStruct.totalWeight;
        elementStruct.water = elementStruct.water / elementStruct.totalWeight;
        elementStruct.air = elementStruct.air / elementStruct.totalWeight;
        elementStruct.earth = elementStruct.earth / elementStruct.totalWeight;
        elementStruct = _updateRemainValueForElementStruct(elementStruct);
        // dominant element adjust by parent legacy tag
        if (parentAAttributes[4] != 0 || parentBAttributes[4] != 0) {
            // get planet domain element
            elementStruct.domainValue = Math.max(
                Math.max(elementStruct.fire, elementStruct.water),
                Math.max(elementStruct.air, elementStruct.earth)
            );
            // double check if there are 2 value are the same
            uint256 initRandomIndex = _randomRange(1, 4);
            elementStruct.domainIndex = 0;
            if (elementStruct.domainValue == elementStruct.fire) {
                elementStruct.domainIndex = 1;
            }
            if (elementStruct.domainValue == elementStruct.water) {
                if (elementStruct.domainIndex == 0) {
                    elementStruct.domainIndex = 2;
                }
                if (initRandomIndex >= 2) {
                    elementStruct.domainIndex = 2;
                }
            }
            if (elementStruct.domainValue == elementStruct.air) {
                if (elementStruct.domainIndex == 0) {
                    elementStruct.domainIndex = 3;
                }
                if (initRandomIndex >= 3) {
                    elementStruct.domainIndex = 3;
                }
            }
            if (elementStruct.domainValue == elementStruct.earth) {
                if (elementStruct.domainIndex == 0) {
                    elementStruct.domainIndex = 4;
                }
                if (initRandomIndex >= 4) {
                    elementStruct.domainIndex = 4;
                }
            }

            // get parent planetTag
            PlanetTag memory planetATag = PlanetTag(0, 0, 0, 0, 0);
            PlanetTag memory planetBTag = PlanetTag(0, 0, 0, 0, 0);
            if (parentAAttributes[4] != 0) {
                planetATag = _getPlanetTagById(parentAAttributes[4]);
            }
            if (parentBAttributes[4] != 0) {
                planetBTag = _getPlanetTagById(parentBAttributes[4]);
            }

            // update element value by tag
            if (elementStruct.domainIndex == 1) {
                elementStruct.fire = Math.max(
                    elementStruct.fire,
                    Math.max(planetATag.fire, planetBTag.fire)
                );
                elementStruct.domainValue = elementStruct.fire;
                elementStruct.domainIndex = 1;
            } else if (elementStruct.domainIndex == 2) {
                elementStruct.water = Math.max(
                    elementStruct.water,
                    Math.max(planetATag.water, planetBTag.water)
                );
                elementStruct.domainValue = elementStruct.water;
                elementStruct.domainIndex = 2;
            } else if (elementStruct.domainIndex == 3) {
                elementStruct.air = Math.max(
                    elementStruct.air,
                    Math.max(planetATag.air, planetBTag.air)
                );
                elementStruct.domainValue = elementStruct.air;
                elementStruct.domainIndex = 3;
            } else if (elementStruct.domainIndex == 4) {
                elementStruct.earth = Math.max(
                    elementStruct.earth,
                    Math.max(planetATag.earth, planetBTag.earth)
                );
                elementStruct.domainValue = elementStruct.earth;
                elementStruct.domainIndex = 4;
            }
        }
        // final adjust value to total 100
        elementStruct = _updateRemainValueForElementStruct(elementStruct);

        // attributes
        uint256[] memory attributes = new uint256[](18);
        attributes[0] = elementStruct.fire; // element: fire
        attributes[1] = elementStruct.water; // element: water
        attributes[2] = elementStruct.air; // element: air
        attributes[3] = elementStruct.earth; // element: earth

        // primeval legacy tag
        uint256[] memory parentLegacyArray = _getParentLegacyArray(planetId);
        random = _randomRange(0, 99);
        random = random / 10;
        if (parentLegacyArray.length > random) {
            attributes[4] = parentLegacyArray[random];
        } else {
            attributes[4] = 0;
        }

        random = _randomRange(0, 1);
        attributes[5] = (random == 0)
            ? parentAAttributes[5]
            : parentBAttributes[5]; // body: sex
        random = _randomRange(0, 1);
        attributes[6] = (random == 0)
            ? parentAAttributes[6]
            : parentBAttributes[6]; // body: weapon
        random = _randomRange(0, 1);
        attributes[7] = (random == 0)
            ? parentAAttributes[7]
            : parentBAttributes[7]; // body: body props
        random = _randomRange(0, 1);
        attributes[8] = (random == 0)
            ? parentAAttributes[8]
            : parentBAttributes[8]; // body: head props

        // skill: pskill1, pskill2
        uint256 skillCount = 2;
        uint256[] memory pskillArray = new uint256[](4);
        pskillArray[0] = parentAAttributes[12];
        pskillArray[1] = parentAAttributes[13];
        if (
            parentBAttributes[12] != parentAAttributes[12] &&
            parentBAttributes[12] != parentAAttributes[13]
        ) {
            pskillArray[skillCount++] = parentBAttributes[12];
        }
        if (
            parentBAttributes[13] != parentAAttributes[12] &&
            parentBAttributes[13] != parentAAttributes[13]
        ) {
            pskillArray[skillCount++] = parentBAttributes[13];
        }
        random = _randomRange(0, skillCount - 1); // skill: pskill1 random
        random2 = (random + _randomRange(1, skillCount - 1)) % skillCount; // skill: pskill2 random
        attributes[12] = pskillArray[random]; // skill: pskill1
        attributes[13] = pskillArray[random2]; // skill: pskill2

        random = _randomRange(0, 1);
        attributes[14] = (random == 0)
            ? parentAAttributes[14]
            : parentBAttributes[14]; //class

        // handle cskill after class define
        uint256[] memory cskillArray = new uint256[](6);
        if (parentAAttributes[14] == parentBAttributes[14]) {
            // both class are same
            skillCount = 3;
            cskillArray[0] = parentAAttributes[9];
            cskillArray[1] = parentAAttributes[10];
            cskillArray[2] = parentAAttributes[11];
            if (
                parentBAttributes[9] != parentAAttributes[9] &&
                parentBAttributes[9] != parentAAttributes[10] &&
                parentBAttributes[9] != parentAAttributes[11]
            ) {
                cskillArray[skillCount++] = parentBAttributes[9];
            }
            if (
                parentBAttributes[10] != parentAAttributes[9] &&
                parentBAttributes[10] != parentAAttributes[10] &&
                parentBAttributes[10] != parentAAttributes[11]
            ) {
                cskillArray[skillCount++] = parentBAttributes[10];
            }
            if (
                parentBAttributes[11] != parentAAttributes[9] &&
                parentBAttributes[11] != parentAAttributes[10] &&
                parentBAttributes[11] != parentAAttributes[11]
            ) {
                cskillArray[skillCount++] = parentBAttributes[11];
            }
            // todo cskill mutation
        } else {
            // both class are different
            skillCount = 4;
            if (attributes[14] == parentAAttributes[14]) {
                cskillArray[0] = parentAAttributes[9];
                cskillArray[1] = parentAAttributes[10];
                cskillArray[2] = parentAAttributes[11];
            } else {
                cskillArray[0] = parentBAttributes[9];
                cskillArray[1] = parentBAttributes[10];
                cskillArray[2] = parentBAttributes[11];
            }
            cskillArray[3] = 255; // empty skill
        }
        random = _randomRange(0, skillCount - 1); // skill: cskill1 random
        random2 = (random + _randomRange(1, skillCount - 1)) % skillCount; // skill: cskill2 random
        random3 = (random2 + _randomRange(1, skillCount - 2)) % skillCount; // skill: cskill3 random
        attributes[9] = cskillArray[random]; // skill: cskill1
        attributes[10] = cskillArray[random2]; // skill: cskill2
        attributes[11] = cskillArray[random3]; // skill: cskill3

        random = _randomRange(0, 1);
        attributes[15] = (random == 0)
            ? parentAAttributes[15]
            : parentBAttributes[15]; //special gene
        return attributes;
    }

    function _convertToAttributes(uint256 _geneId, uint256 _numOfAttributes)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory attributes = new uint256[](_numOfAttributes);

        uint256 geneId = _geneId;
        for (uint256 id = 0; id < attributes.length; id++) {
            attributes[id] = geneId % 256;
            geneId /= 256;
        }

        return attributes;
    }

    function _getPlanetTagById(uint256 planetTagId)
        internal
        view
        returns (PlanetTag memory)
    {
        require(planetTagId != 0, "Tag should not be 0 to call this function");

        if (planetTagId <= 18) {
            return planetTagsPerBloodline[1][planetTagId - 1];
        } else if (planetTagId <= 46) {
            return planetTagsPerBloodline[2][planetTagId - 18 - 1];
        } else if (planetTagId <= 62) {
            return planetTagsPerBloodline[2][planetTagId - 46 - 1];
        }
    }

    function _getParentLegacyArray(uint256 planetId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 count = 0;
        uint256[] memory parentArray = _getParentAndGrandparentIDArray(
            planetId
        );
        uint256[] memory legacyTagArray = new uint256[](parentArray.length);
        for (uint256 i = 0; i < parentArray.length; i++) {
            PlanetMeta.PlanetData memory planetData;
            (planetData, ) = planetContract.getPlanetData(parentArray[i]);
            uint256[] memory planetAttributes = _convertToAttributes(
                planetData.gene,
                18
            );
            if (planetAttributes[4] != 0) {
                legacyTagArray[count] = planetAttributes[4];
                count++;
            }
        }

        return legacyTagArray;
    }

    function test(uint256 planetId) public view returns (uint256[] memory) {
        uint256 count = 0;
        uint256[] memory parentArray = _getParentAndGrandparentIDArray(
            planetId
        );
        uint256[] memory legacyTagArray = new uint256[](parentArray.length);
        for (uint256 i = 0; i < parentArray.length; i++) {
            PlanetMeta.PlanetData memory planetData;
            (planetData, ) = planetContract.getPlanetData(parentArray[i]);
            uint256[] memory planetAttributes = _convertToAttributes(
                planetData.gene,
                18
            );
            if (planetAttributes[4] != 0) {
                legacyTagArray[count] = planetAttributes[4];
                count++;
            }
        }

        return legacyTagArray;
    }
}

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
    mapping(CoreType => mapping(uint256 => uint256)) bloodlineRatioPerCoreType;
    mapping(CoreType => uint256) haveTagRatioPerCoreType;

    struct PlanetTag {
        uint256 id;
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
    }
    mapping(uint256 => PlanetTag[]) planetTagsPerBloodline;

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
            pickedIndex = _randomByBaseValue(
                randomBaseValues[0],
                4
            );
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

contract PlanetMeta {
    struct PlanetData {
        uint256 gene;
        uint256 baseAge;
        uint256 evolve;
        uint256 breedCount;
        uint256 breedCountMax;
        uint256 createTime; // before hatch
        uint256 bornTime; // after hatch
        uint256 lastBreedTime;
        uint256[] relicsTokenIDs;
        uint256[] parents; //parent token ids 
        uint256[] children; //children token ids
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";
import "./PlanetMeta.sol";

contract ApeironPlanet is
    PlanetMeta,
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessProtectedUpgradable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable
{
    // Base URI
    string private baseURI;

    // Mapping from token ID to PlanetData
    mapping(uint256 => PlanetData) private planetDataMap;

    // event
    event UpdatePlanet(uint256 _tokenId);
    event UpdateURI(string _baseURI);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    modifier hasTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "tokenId is non existent");
        _;
    }

    function initialize() public initializer {
        __ERC721_init("ApeironPlanet", "APEP");
        __Pausable_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // minting for presale
    function safeMint(
        uint256 gene,
        uint256[] calldata parents,
        address to,
        uint256 tokenId
    ) public onlyAdmin {
        require(
            //bred from zero
            // (parentA == 0 && parentB == 0) ||
            (parents.length == 0) ||
                //bred from existing parents
                (parents.length == 2 &&
                    _exists(parents[0]) &&
                    _exists(parents[1]) &&
                    parents[0] != parents[1] &&
                    planetDataMap[parents[0]].breedCount <
                    planetDataMap[parents[0]].breedCountMax &&
                    planetDataMap[parents[1]].breedCount <
                    planetDataMap[parents[1]].breedCountMax),
            "parents are non existent or cant breed anymore"
        );

        _safeMint(to, tokenId);

        planetDataMap[tokenId].gene = gene;
        planetDataMap[tokenId].baseAge = 1;
        planetDataMap[tokenId].createTime = block.timestamp;

        if (parents.length == 2) {
            planetDataMap[tokenId].parents = parents;

            planetDataMap[parents[0]].children.push(tokenId);
            planetDataMap[parents[0]].breedCount += 1;
            planetDataMap[parents[0]].lastBreedTime = block.timestamp;
            planetDataMap[parents[1]].children.push(tokenId);
            planetDataMap[parents[1]].breedCount += 1;
            planetDataMap[parents[1]].lastBreedTime = block.timestamp;
        }
    }

    function burn(uint256 tokenId)
        public
        override
        hasTokenId(tokenId)
        onlyAdmin
    {
        super.burn(tokenId);

        //keep planetDataMap even it is burnt
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function updatePlanetData(
        uint256 tokenId,
        uint256 gene,
        //  Add planet baseage, by absorb
        uint256 addAge,
        // evolve the planet.
        uint256 addEvolve,
        // add breed count max
        uint256 addBreedCountMax,
        // update born time to now
        bool setBornTime
    ) external hasTokenId(tokenId) whenNotPaused onlyAdmin {
        if (setBornTime) {
            require(
                planetDataMap[tokenId].bornTime == 0,
                "Planet already born"
            );
            planetDataMap[tokenId].bornTime = block.timestamp;
        }

        planetDataMap[tokenId].gene = gene;
        planetDataMap[tokenId].baseAge += addAge;
        planetDataMap[tokenId].evolve += addEvolve;
        planetDataMap[tokenId].breedCountMax += addBreedCountMax;
        
        emit UpdatePlanet(tokenId);
    }

    // set relic of existing planet. More check left for minter
    function setPlanetRelics(uint256 tokenId, uint256[] calldata newRelics)
        external
        hasTokenId(tokenId)
        whenNotPaused
        onlyAdmin
    {
        planetDataMap[tokenId].relicsTokenIDs = newRelics;
        
        emit UpdatePlanet(tokenId);
    }

    function getPlanetData(uint256 tokenId)
        public
        view
        returns (
            PlanetData memory, //planetData
            bool //isAlive
        )
    {
        require(
            planetDataMap[tokenId].createTime != 0,
            "PlanetData is non existent"
        );

        return (planetDataMap[tokenId], _exists(tokenId));
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit UpdateURI(baseURI);
    }

    // override functions for ERC721Upgradeable
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Burnable_init_unchained();
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtectedUpgradable is OwnableUpgradeable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
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