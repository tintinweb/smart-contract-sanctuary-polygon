// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bodies {
    string public constant body1 = "body1";
    string public constant body2 = "body2";
    string public constant body3 = "body3";

    function getBody1() public pure returns (string memory) {
        return body1;
    }

    function getBody2() public pure returns (string memory) {
        return body2;
    }

    function getBody3() public pure returns (string memory) {
        return body3;
    }
}

contract Helms {
    string public constant helms1 = "helms1";
    string public constant helms2 = "helms2";
    string public constant helms3 = "helms3";
    function getHelms1() public pure returns (string memory) {
        return helms1;
    }

    function getHelms2() public pure returns (string memory) {
        return helms2;
    }

    function getHelms3() public pure returns (string memory) {
        return helms3;
    }
}

contract Mainhands {
    string public constant mainhand1 = "mainhand1";
    string public constant mainhand2 = "mainhand2";
    string public constant mainhand3 = "mainhand3";
    function getMainhand1() public pure returns (string memory) {
        return mainhand1;
    }

    function getMainhand2() public pure returns (string memory) {
        return mainhand2;
    }

    function getMainhand3() public pure returns (string memory) {
        return mainhand3;
    }
}

contract Offhands {
    string public constant offhand1 = "offhand1";
    string public constant offhand2 = "offhand2";
    string public constant offhand3 = "offhand3";
    function getOffhand1() public pure returns (string memory) {
        return offhand1;
    }

    function getOffhand2() public pure returns (string memory) {
        return offhand2;
    }

    function getOffhand3() public pure returns (string memory) {
        return offhand3;
    }
}


contract Uniques {
    string public constant unique1 = "unique1";
    string public constant unique2 = "unique2";
    string public constant unigue3 = "unique3";
    function getUnique1() public pure returns (string memory) {
        return unique1;
    }

    function getUnique2() public pure returns (string memory) {
        return unique2;
    }

    function getUnique3() public pure returns (string memory) {
        return unigue3;
    }
}

// SPDX-License-Identifier: Unlicense
import "./Inventory.sol";
pragma solidity 0.8.7;

contract InventoryManager {
    address impl_;
    address public manager;

    enum Part {
        body,
        helm,
        mainhand,
        offhand,
        unique
    }

    mapping(uint8 => address) public bodies;
    mapping(uint8 => address) public helms;
    mapping(uint8 => address) public mainhands;
    mapping(uint8 => address) public offhands;
    mapping(uint8 => address) public uniques;

    string public constant header =
        '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer =
        "<style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";

    function getSVG(
        uint8 body_,
        uint8 helm_,
        uint8 mainhand_,
        uint8 offhand_
    ) public view returns (string memory) {
        // it's a unique!
        if (helm_ > 40)
            return
                string(
                    abi.encodePacked(header, get(Part.unique, body_), footer)
                );

        return
            string(
                abi.encodePacked(
                    header,
                    get(Part.body, body_),
                    get(Part.helm, helm_),
                    get(Part.mainhand, mainhand_),
                    get(Part.offhand, offhand_),
                    footer
                )
            );
    }

    constructor() {
        manager = msg.sender;
    }

    function getTokenURI(
        uint16 id_,
        uint8 body_,
        uint8 helm_,
        uint8 mainhand_,
        uint8 offhand_,
        uint16 level_,
        uint16 zugModifier_
    ) public view returns (string memory) {
        string memory svg = Base64.encode(
            bytes(getSVG(body_, helm_, mainhand_, offhand_))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Orc #',
                                toString(id_),
                                '", "description":"EtherOrcs is a collection of 5050 Orcs ready to pillage the blockchain. With no IPFS or API, these Orcs are the very first role-playing game that takes place 100% on-chain. Spawn new Orcs, battle your Orc to level up, and pillage different loot pools to get new weapons and gear which upgrades your Orc metadata. This Horde of Orcs will stand the test of time and live on the blockchain for eternity.", "image": "',
                                "data:image/svg+xml;base64,",
                                svg,
                                '",',
                                getAttributes(
                                    body_,
                                    helm_,
                                    mainhand_,
                                    offhand_
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                    INVENTORY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setBodies(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            bodies[ids[index]] = source;
        }
    }

    function setHelms(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            helms[ids[index]] = source;
        }
    }

    function setMainhands(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            mainhands[ids[index]] = source;
        }
    }

    function setOffhands(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            offhands[ids[index]] = source;
        }
    }

    function setUniques(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            uniques[ids[index]] = source;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function call(
        address source,
        bytes memory sig
    ) internal view returns (string memory svg) {
        (bool succ, bytes memory ret) = source.staticcall(sig);
        require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }

    function get(Part part, uint8 id) public view returns (string memory svg) {
        address source = bodies[id]; // change this to get the contract address for the given part and id
        string memory sig = getData(part);
        (bool succ, bytes memory data) = source.staticcall(
            abi.encodeWithSignature(sig)
        );
        require(succ, "failed to get data");
        return wrapTag(abi.decode(data, (string)));
    }

    function wrapTag(string memory uri) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="1" y="1" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    uri,
                    '"/>'
                )
            );
    }

    function getData(
        Part part
    ) internal pure returns (string memory sig) {
        if (part == Part.body) {
            return "getBody1()";
        } else if (part == Part.helm) {
            return "getHelms1()";
        } else if (part == Part.mainhand) {
            return "mainhand1()";
        } else if (part == Part.offhand) {
            return "offhand1()";
        } else if (part == Part.unique) {
            return "unique1()";
        }
        revert("invalid part/id");
    }

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

    function getAttributes(
        uint8 body_,
        uint8 helm_,
        uint8 mainhand_,
        uint8 offhand_
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"attributes": [',
                    getBodyAttributes(body_),
                    ",",
                    getHelmAttributes(helm_),
                    ",",
                    getMainhandAttributes(mainhand_),
                    ",",
                    getOffhandAttributes(offhand_),
                    "]"
                )
            );
    }

    function getBodyAttributes(
        uint8 body_
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Body","value":"',
                    getBodyName(body_),
                    '"}'
                )
            );
    }

    function getHelmAttributes(
        uint8 helm_
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Helm","value":"',
                    getHelmName(helm_),
                    '"},{"display_type":"number","trait_type":"HelmTier","value":',
                    toString(getTier(helm_)),
                    "}"
                )
            );
    }

    function getMainhandAttributes(
        uint8 mainhand_
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Mainhand","value":"',
                    getMainhandName(mainhand_),
                    '"},{"display_type":"number","trait_type":"MainhandTier","value":',
                    toString(getTier(mainhand_)),
                    "}"
                )
            );
    }

    function getOffhandAttributes(
        uint8 offhand_
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Offhand","value":"',
                    getOffhandName(offhand_),
                    '"},{"display_type":"number","trait_type":"OffhandTier","value":',
                    toString(getTier(offhand_)),
                    "}"
                )
            );
    }

    function getTier(uint16 id) internal pure returns (uint16) {
        if (id > 40) return 100;
        if (id == 0) return 0;
        return ((id - 1) / 4);
    }

    // Here, we do sort of a Binary Search to find the correct name. Not the pritiest code I've wrote, but hey, it works!

    function getBodyName(uint8 id) public pure returns (string memory) {
        if (id > 40) return getUniqueName(id);
        if (id < 20) {
            if (id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "Green Orc 1" : "Green Orc 2";
                    }
                    return id == 3 ? "Green Orc 3" : "Dark Green Orc 1";
                }
                if (id < 7)
                    return id == 5 ? "Dark Green Orc 2" : "Dark Green Orc 3";
                return
                    id == 7 ? "Red Orc 1" : id == 8 ? "Red Orc 2" : "Red Orc 3";
            }
            if (id <= 15) {
                if (id < 13) {
                    return
                        id == 10 ? "Blood Red Orc 1" : id == 11
                            ? "Blood Red Orc 2"
                            : "Blood Red Orc 3";
                }
                return
                    id == 13 ? "Clay Orc 1" : id == 14
                        ? "Clay Orc 2"
                        : "Clay Orc 3";
            }
            if (id < 18)
                return id == 16 ? "Dark Clay Orc 1" : "Dark Clay Orc 2";
            return id == 18 ? "Dark Clay Orc 3" : "Blue Orc 1";
        }

        if (id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return
                        id == 20 ? "Blue Orc 2" : id == 21
                            ? "Blue Orc 3"
                            : "Midnight Blue Orc 1";
                }
                return id == 23 ? "Midnight Blue Orc 2" : "Midnight Blue Orc 3";
            }

            if (id < 27) return id == 25 ? "Albino Orc 1" : "Albino Orc 2";
            return "Albino Orc 3";
        }
    }

    function getHelmName(uint8 id) public pure returns (string memory) {
        if (id > 40) return getUniqueName(id);
        if (id < 20) {
            if (id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "None" : "None";
                    }
                    return id == 3 ? "None" : "None";
                }
                if (id < 7)
                    return id == 5 ? "Leather Helm +1" : "Orcish Helm +1";
                return
                    id == 7 ? "Leather Cap +1" : id == 8
                        ? "Iron Helm +1"
                        : "Bone Helm +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return
                        id == 10 ? "Full Orc Helm +2" : id == 11
                            ? "Chainmail Cap +2"
                            : "Strange Helm +2";
                }
                return
                    id == 13 ? "Full Plate Helm +3" : id == 14
                        ? "Chainmail Coif +3"
                        : "Boar Head +3";
            }
            if (id < 18)
                return id == 16 ? "Orb of Protection +3" : "Royal Thingy +4";
            return id == 18 ? "Dark Iron Helm +4" : "Cursed Hood +4";
        }

        if (id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return
                        id == 20 ? "Red Bandana +4" : id == 21
                            ? "Thorned Helm +5"
                            : "Demon Skull +5";
                }
                return id == 23 ? "Treasure Chest +5" : "Cursed Hood +5";
            }

            if (id < 27)
                return id == 25 ? "Blue Knight Helm +6" : "Parasite +6";
            return
                id == 27 ? "Dragon Eyes +6" : id == 28
                    ? "Horned Cape +6"
                    : "Nether Blindfold +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return
                    id == 30 ? "Lightning Crown +7" : id == 31
                        ? "Master Warlock Cape +7"
                        : "Red Knight Helm +7";
            }
            return
                id == 33 ? "Beholder Head +8" : id == 34
                    ? "Ice Crown +8"
                    : "Band of the Dark Lord +8";
        }
        if (id < 38) return id == 36 ? "Helm of Evil +8" : "Blazing Horns +9";
        return
            id == 38 ? "Possessed Helm +9" : id == 39
                ? "Molten Crown +9"
                : "Helix Helm +9";
    }

    function getMainhandName(uint8 id) public pure returns (string memory) {
        if (id > 40) return getUniqueName(id);
        if (id < 20) {
            if (id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "Pickaxe" : "Torch";
                    }
                    return id == 3 ? "Club" : "Pleb Staff";
                }
                if (id < 7) return id == 5 ? "Short Sword +1" : "Dagger +1";
                return
                    id == 7 ? "Simple Axe +1" : id == 8
                        ? "Fiery Poker +1"
                        : "Large Axe +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return
                        id == 10 ? "Iron Hammer +2" : id == 11
                            ? "Iron Mace +2"
                            : "Jagged Axe +2";
                }
                return
                    id == 13 ? "Enchanted Poker +3" : id == 14
                        ? "Curved Sword +3"
                        : "Ultra Mallet +3";
            }
            if (id < 18)
                return id == 16 ? "Disciple Staff +3" : "Assassin Blade +4";
            return id == 18 ? "Swamp Staff +4" : "Simple Wand +4";
        }

        if (id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return
                        id == 20 ? "Royal Blade +4" : id == 21
                            ? "Skull Shield +5"
                            : "Skull Crusher Axe +5";
                }
                return id == 23 ? "Flaming Staff +5" : "Flaming Royal Blade +5";
            }

            if (id < 27)
                return id == 25 ? "Berserker Sword +6" : "Necromancer Staff +6";
            return
                id == 27 ? "Flaming Skull Shield +6" : id == 28
                    ? "Frozen Scythe +6"
                    : "Blood Sword +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return
                    id == 30 ? "Dark Lord Staff +7" : id == 31
                        ? "Bow of Artemis +7"
                        : "Ice Sword +7";
            }
            return
                id == 33 ? "Cryptic Staff +8" : id == 34
                    ? "Nether Lance +8"
                    : "Demonic Axe +8";
        }
        if (id < 38)
            return id == 36 ? "Old Moon Sword +8" : "Lightning Lance +9";
        return
            id == 38 ? "Molten Hammer +9" : id == 39
                ? "Possessed Great Staff +9"
                : "Helix Lance +9";
    }

    function getOffhandName(uint8 id) public pure returns (string memory) {
        if (id > 40) return getUniqueName(id);
        if (id < 20) {
            if (id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "None" : "None";
                    }
                    return id == 3 ? "None" : "None";
                }
                if (id < 7)
                    return
                        id == 5 ? "Wooden Shield +1" : "Paper Hands Shield +1";
                return
                    id == 7 ? "Dagger +1" : id == 8
                        ? "Pirate Hook +1"
                        : "Offhand Axe +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return
                        id == 10 ? "Offhand Slasher +2" : id == 11
                            ? "Large Shield +2"
                            : "Bomb +2";
                }
                return
                    id == 13 ? "Offhand Poker +3" : id == 14
                        ? "Reinforced Shield +3"
                        : "War Banner +3";
            }
            if (id < 18)
                return id == 16 ? "Hand Cannon +3" : "Metal Kite Shield +4";
            return id == 18 ? "Crossbow +4" : "Cursed Skull +4";
        }

        if (id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return
                        id == 20 ? "Spiked Shield +4" : id == 21
                            ? "Cursed Totem +5"
                            : "Grimoire +5";
                }
                return id == 23 ? "Offhand Glaive +5" : "Frost Side Sword +5";
            }

            if (id < 27)
                return id == 25 ? "Magic Shield +6" : "Enchanted Glaive +6";
            return
                id == 27 ? "Burning Wand +6" : id == 28
                    ? "Burning Shield +6"
                    : "Burning Blade +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return
                    id == 30 ? "Holy Scepter +7" : id == 31
                        ? "Possessed Skull +7"
                        : "Demonic Grimoire +7";
            }
            return
                id == 33 ? "Scepter of Frost +8" : id == 34
                    ? "Demonic Scythe +8"
                    : "Lightning Armband of Power +8";
        }
        if (id < 38) return id == 36 ? "Ice Staff +8" : "Nether Shield +9";
        return
            id == 38 ? "Molten Scimitar +9" : id == 39
                ? "Staff of the Dark Lord +9"
                : "Helix Scepter +9";
    }

    function getUniqueName(uint8 id) internal pure returns (string memory) {
        if (id < 47) {
            if (id < 44) {
                return
                    id == 41 ? "Cthulhu" : id == 42
                        ? "Vorgak The War Chief"
                        : "Gromlock The Destroyer";
            }
            return
                id == 44 ? "Yuckha The Hero" : id == 45
                    ? "Orgug The Master Warlock"
                    : "Hoknuk The Demon Tamer";
        }
        if (id < 50) {
            return
                id == 47 ? "Lava Man" : id == 48
                    ? "hagra the Zombie"
                    : "Morzul The Ice Warrior";
        }
        return
            id == 50 ? "T4000 The MechaOrc" : id == 51
                ? "Slime Orc The Forgotten"
                : "Mouse God";
    }
}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}