// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IGHGMetadata, ICard} from "../../../interfaces/Interfaces.sol";
import {StringUtils}  from "../../../utils/StringUtils.sol";

contract SpeedCalculator {
    using StringUtils for *;

    IGHGMetadata metadata;
    ICard cards;

    mapping(string => uint) public minerBoosts;
    mapping(string => uint) public piratesBoosts;
    mapping(string => uint) public shipBoosts;
    mapping(string => uint) public cardBoosts;

    constructor(address _metadata, address _cards) {
        metadata = IGHGMetadata(_metadata);
        cards = ICard(_cards);

        minerBoosts["feet_high_boots_black"] = 2;
        minerBoosts["feet_work_shoes"] = 6;
        minerBoosts["headwear_crown"] = 6;
        minerBoosts["headwear_gold_halo"] = 6;
        minerBoosts["legs_red_trousers"] = 1;
        minerBoosts["legs_orange_trousers"] = 1;
        minerBoosts["legs_brown_trousers"] = 1;
        minerBoosts["legs_yellow_trousers"] = 1;
        minerBoosts["legs_zombie_trousers"] = 2;
        minerBoosts["mouth_gold_grills"] = 4;
        minerBoosts["neck_diamond"] = 2;
        minerBoosts["neck_heart"] = 4;
        minerBoosts["skin_gold"] = 4;
        minerBoosts["skin_skeleton"] = 4;
        minerBoosts["skin_zombie"] = 4;
        minerBoosts["skin_cyborg"] = 4;
        minerBoosts["sunglasses_nightvision"] = 8;
        minerBoosts["tool_pickaxe"] = 1;
        minerBoosts["tool_map"] = 1;
        minerBoosts["tool_shovel"] = 1;
        minerBoosts["tool_bo"] = 1;
        minerBoosts["tool_compass"] = 1;
        minerBoosts["tool_hourglass"] = 1;
        minerBoosts["tool_key"] = 6;

        piratesBoosts["arm_pirate_flag"] = 12;
        piratesBoosts["arm_treasure_map"] = 12;
        piratesBoosts["arm_trident"] = 24;
        piratesBoosts["dress_violet_suit"] = 4;
        piratesBoosts["dress_blue_suit"] = 4;
        piratesBoosts["dress_shirt_striped"] = 12;
        piratesBoosts["ears_diamond"] = 4;
        piratesBoosts["face_double_braids"] = 8;
        piratesBoosts["face_pipe"] = 8;
        piratesBoosts["face_skeleton"] = 12;
        piratesBoosts["head_pirate_hat"] = 8;
        piratesBoosts["head_pirate_hat_circle"] = 8;
        piratesBoosts["head_pirate_cap"] = 16;
        piratesBoosts["hook_golden"] = 12;
        piratesBoosts["patch_gold"] = 8;
        piratesBoosts["patch_love"] = 8;
        piratesBoosts["patch_double"] = 12;
        piratesBoosts["pegleg_none"] = 8;

        /* shipBoosts["anchor_gold"] = 15;
        shipBoosts["anchor_bone"] = 15;
        shipBoosts["ships_diamond"] = 8;
        shipBoosts["ships_gold"] = 15;
        shipBoosts["ships_bone"] = 15;
        shipBoosts["ships_royal"] = 15;
        shipBoosts["mast_bone"] = 15;
        shipBoosts["flag_yellow"] = 15;
        shipBoosts["background_harbour"] = 15;
        shipBoosts["sail_pirate_black"] = 30;
        shipBoosts["sail_pirate_white"] = 30;
        shipBoosts["sail_white_stripes"] = 15;
        shipBoosts["sail_pennant_chain"] = 15;
        shipBoosts["sail_bulb_chain"] = 15;
        shipBoosts["sail_colored"] = 30;
        shipBoosts["sail_gold"] = 30;
        shipBoosts["sail_pirate_red"] = 45;
        shipBoosts["waves_red"] = 8; */

        cardBoosts["EVENT_DAO_ESTABLISHMENT_ARTIST_PROOF"] = 8;
        cardBoosts["EVENT_DAO_ESTABLISHMENT_LEGENDARY"] = 12;
        cardBoosts["EVENT_DAO_ESTABLISHMENT_ULTRA_RARE"] = 8;
        cardBoosts["EVENT_DAO_ESTABLISHMENT_DAO_EXCLUSIVE"] = 3;
        cardBoosts["EVENT_DAO_ESTABLISHMENT_COMMON"] = 2;
        cardBoosts["EVENT_POLYGON_PIONEER_ARTIST_PROOF"] = 8;
        cardBoosts["EVENT_POLYGON_PIONEER_LEGENDARY"] = 12;
        cardBoosts["EVENT_POLYGON_PIONEER_ULTRA_RARE"] = 8;
        cardBoosts["EVENT_POLYGON_PIONEER_DAO_EXCLUSIVE"] = 3;
        cardBoosts["EVENT_POLYGON_PIONEER_COMMON"] = 2;
        cardBoosts["CHARACTER_GOVERNOR_ARTIST_PROOF"] = 8;
        cardBoosts["CHARACTER_GOVERNOR_LEGENDARY"] = 12;
        cardBoosts["CHARACTER_GOVERNOR_ULTRA_RARE"] = 8;
        cardBoosts["CHARACTER_GOVERNOR_DAO_EXCLUSIVE"] = 3;
        cardBoosts["CHARACTER_GOVERNOR_RARE"] = 6;
        cardBoosts["CHARACTER_GOVERNOR_COMMON"] = 3;
        cardBoosts["CHARACTER_ERNESTO_ARTIST_PROOF"] = 8;
        cardBoosts["CHARACTER_ERNESTO_LEGENDARY"] = 12;
        cardBoosts["CHARACTER_ERNESTO_ULTRA_RARE"] = 8;
        cardBoosts["CHARACTER_ERNESTO_DAO_EXCLUSIVE"] = 3;
        cardBoosts["CHARACTER_ERNESTO_RARE"] = 6;
        cardBoosts["CHARACTER_ERNESTO_COMMON"] = 3;
    }

    function getCrewSpeed(
        uint16[] calldata _goldhunterIds, 
        /* uint16[] calldata _shipIds, */
        uint[] calldata _cardIds
    ) public view returns (uint speed) {

        for (uint i = 0; i < _goldhunterIds.length; i++) {
            speed += getGoldhunterSpeed(_goldhunterIds[i]);
        }

        /* for (uint i = 0; i < _shipIds.length; i++) {
            speed += getShipSpeed(_shipIds[i]);
        } */

        for (uint i = 0; i < _cardIds.length; i++) {
            speed += getCardSpeed(_cardIds[i]);
        }

    }

    function getGoldhunterSpeed(uint16 _tokenId) public view returns (uint speed) {        
        if (!metadata.goldhunterIsPirate(_tokenId)) {
            return getMinerSpeed(_tokenId);
        } else {
            return getPirateSpeed(_tokenId);
        }
    }

    function getMinerSpeed(uint16 _tokenId) public view returns (uint speed) {
        speed += 4;

        if (metadata.getGoldhunterIsGen0(_tokenId)) {
            speed += 4;
        }

        if (metadata.goldhunterIsCrossedTheOcean(_tokenId)) {
            speed += 4;
        }

        speed += minerBoosts["feet_".append(metadata.getGoldhunterFeet(_tokenId))];
        speed += minerBoosts["headwear_".append(metadata.getGoldhunterHeadwear(_tokenId))];
        speed += minerBoosts["legs_".append(metadata.getGoldhunterLegs(_tokenId))];
        speed += minerBoosts["mouth_".append(metadata.getGoldhunterMouth(_tokenId))];
        speed += minerBoosts["neck_".append(metadata.getGoldhunterNeck(_tokenId))];
        speed += minerBoosts["skin_".append(metadata.getGoldhunterSkin(_tokenId))];
        speed += minerBoosts["sunglasses_".append(metadata.getGoldhunterSunglasses(_tokenId))];
        speed += minerBoosts["tool_".append(metadata.getGoldhunterTool(_tokenId))];
    }

    function getPirateSpeed(uint16 _tokenId) public view returns (uint speed) {
        speed += 8;

        if (metadata.getGoldhunterIsGen0(_tokenId)) {
            speed += 8;
        }

        if (metadata.goldhunterIsCrossedTheOcean(_tokenId)) {
            speed += 8;
        }

        speed += piratesBoosts["arm_".append(metadata.getGoldhunterArm(_tokenId))];
        speed += piratesBoosts["dress_".append(metadata.getGoldhunterDress(_tokenId))];
        speed += piratesBoosts["ears_".append(metadata.getGoldhunterEars(_tokenId))];
        speed += piratesBoosts["face_".append(metadata.getGoldhunterFace(_tokenId))];
        speed += piratesBoosts["head_".append(metadata.getGoldhunterHead(_tokenId))];
        speed += piratesBoosts["golden_".append(metadata.getGoldhunterHook(_tokenId))];
        speed += piratesBoosts["patch_".append(metadata.getGoldhunterPatch(_tokenId))];
        speed += piratesBoosts["pegleg_".append(metadata.getGoldhunterPegleg(_tokenId))];
    }

    /* function getShipSpeed(uint16 _tokenId) public view returns (uint speed) {        
        if (!metadata.shipIsPirate(_tokenId)) {
            speed += 30; 
        } else {
            speed += 45;
        }

        if (metadata.shipIsPirate(_tokenId)) {
            speed += 30;
        }

        speed += shipBoosts["anchor_".append(metadata.getShipAnchor(_tokenId))];
        speed += shipBoosts["ships_".append(metadata.getShipShip(_tokenId))];
        speed += shipBoosts["mast_".append(metadata.getShipMast(_tokenId))];
        speed += shipBoosts["flag_".append(metadata.getShipFlag(_tokenId))];
        speed += shipBoosts["background_".append(metadata.getShipBackground(_tokenId))];
        speed += shipBoosts["sail_".append(metadata.getShipSail(_tokenId))];
        speed += shipBoosts["waves_".append(metadata.getShipWaves(_tokenId))];
    } */

    function getCardSpeed(uint _tokenId) public view returns (uint speed) {
        return cardBoosts[cards.getSeriesName(_tokenId)];
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface ICoin {
    function mint(address account, uint amount) external;
    function burn(address _from, uint _amount) external;
    function balanceOf(address account) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IToken {
    function ownerOf(uint id) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function isApprovedForAll(address owner, address operator) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
}

interface ICard {
    function getSeriesName(uint _id) external view returns (string memory _name);
    function safeTransferFrom(address from, address to, uint tokenId, uint amount, bytes memory data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function mint(address _to, uint _id, uint _amount) external;
}

interface IGHGMetadata {
    ///// GENERIC GETTERS /////
    function getGoldhunterMetadata(uint16 _tokenId) external view returns (string memory);
    function getShipMetadata(uint16 _tokenId) external view returns (string memory);
    function getHouseMetadata(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - SHIPS /////
    function shipIsPirate(uint16 _tokenId) external view returns (bool);
    function shipIsCrossedTheOcean(uint16 _tokenId) external view returns (bool);
    function getShipBackground(uint16 _tokenId) external view returns (string memory);
    function getShipShip(uint16 _tokenId) external view returns (string memory);
    function getShipFlag(uint16 _tokenId) external view returns (string memory);
    function getShipMast(uint16 _tokenId) external view returns (string memory);
    function getShipAnchor(uint16 _tokenId) external view returns (string memory);
    function getShipSail(uint16 _tokenId) external view returns (string memory);
    function getShipWaves(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - HOUSES /////
    function getHouseBackground(uint16 _tokenId) external view returns (string memory);
    function getHouseType(uint16 _tokenId) external view returns (string memory);
    function getHouseWindow(uint16 _tokenId) external view returns (string memory);
    function getHouseDoor(uint16 _tokenId) external view returns (string memory);
    function getHouseRoof(uint16 _tokenId) external view returns (string memory);
    function getHouseForeground(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - GOLDHUNTERS /////
    function goldhunterIsCrossedTheOcean(uint16 _tokenId) external view returns (bool);
    function goldhunterIsPirate(uint16 _tokenId) external view returns (bool);
    function getGoldhunterIsGen0(uint16 _tokenId) external pure returns (bool);
    function getGoldhunterSkin(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterLegs(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterFeet(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterTshirt(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHeadwear(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterMouth(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterNeck(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterSunglasses(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterTool(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterPegleg(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHook(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterDress(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterFace(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterPatch(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterEars(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHead(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterArm(uint16 _tokenId) external view returns (string memory);
}

interface SpeedCalculator {
    function getCrewSpeed(uint16[] calldata _goldhunterIds, uint16[] calldata _shipIds, uint[] calldata _cardIds) external view returns (uint speed);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library StringUtils {

    function equals(string memory a, string memory b) external pure returns (bool) {
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