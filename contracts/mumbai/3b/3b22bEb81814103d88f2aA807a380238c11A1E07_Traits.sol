/**
 *Submitted for verification at polygonscan.com on 2022-05-11
*/

// SPDX-License-Identifier: MIT
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        returns (uint8);
}

interface IWarrior {
    // struct to store each token's traits
    struct AvtHtr {
        bool isMerry;
        //2
        uint8 brutalityLevel;
        //3
        uint8 hench_num;
        //4
        uint8 hair;
        //5
        uint8 face;
        //6
        uint8 mask;
        //7
        uint8 weapon;
        //8
        uint8 hat;
        //9
        uint8 top;
        //10
        uint8 pants;
        //11
        uint8 accesorie;
        //12
        uint8 bling;
        //13
        uint8 alphaIndex;
    }

    function getPaidTokens() external view returns (uint256);
    function getMaxTokens() external view returns (uint256);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (AvtHtr memory);
}

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


contract Traits is Ownable, ITraits {
    using Strings for uint256;

    uint256 private alphaTypeIndex = 7;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    string merryBody;
    string henchBody1;
    string henchBody2;
    string henchBody3;

    // mapping from trait type (index) to its name
    string[19] _traitTypes = [
        //for merrymen
        "Hair",
        "Top",
        "Mask",
        "Weapon",
        //for henchmen 1
        "Hat",
        "Top",
        "Weapon",
        "Accesorie",
        "Bling",
        //for henchmen 2
        "Hair",
        "Face",
        "Top",
        "Pants",
        "Weapon",
        //for henchmen 3
        "Hair",
        "Face",
        "Top",
        "Pants",
        "Weapon"
    ];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    mapping(uint8 => uint8) public traitCountForType;
    // mapping from alphaIndex to its score
    string[3] _alphas = ["1", "2", "3"];

    IWarrior public warrior;

    function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        override
        returns (uint8)
    {
        // if (traitType == alphaTypeIndex) {
        //     uint256 m = seed % 100;
        //     if (m > 95) {
        //         return 0;
        //     } else if (m > 80) {
        //         return 1;
        //     } else if (m > 50) {
        //         return 2;
        //     } else {
        //         return 3;
        //     }
        // }

        uint8 modOf = traitCountForType[traitType];

        return uint8(seed % modOf);
    }

    /***ADMIN */

    function setGame(address _warrior) external onlyOwner {
        warrior = IWarrior(_warrior);
    }

    function uploadBodies(
        string calldata _merry,
        string calldata _hench1,
        string calldata _hench2,
        string calldata _hench3
    ) external onlyOwner {
        merryBody = _merry;
        henchBody1 = _hench1;
        henchBody2 = _hench2;
        henchBody3 = _hench3;
    }

    function uploadMerryBody(
        string calldata _merry
    ) external onlyOwner {
        merryBody = _merry;
    }

    function uploadHench1Body(
        string calldata _hench1
    ) external onlyOwner {
        henchBody1 = _hench1;
    }

    function uploadHench2Body(
        string calldata _hench2
    ) external onlyOwner {
        henchBody1 = _hench2;
    }

    function uploadHench3Body(
        string calldata _hench3
    ) external onlyOwner {
        henchBody1 = _hench3;
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     */

    function uploadTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        Trait[] calldata traits
    ) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");

        for (uint256 i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    function setTraitCountForType(uint8[] memory _tType, uint8[] memory _len)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tType.length; i++) {
            traitCountForType[_tType[i]] = _len[i];
        }
    }

    /***RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
     * @return the <image> element
     */
    function drawTrait(Trait memory trait)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.png,
                    '"/>'
                )
            );
    }

    function draw(string memory png) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    png,
                    '"/>'
                )
            );
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
     * @return a valid SVG of the Henchmen / Merrymen
     */

    function drawSVG(uint256 tokenId) public view returns (string memory) {
        IWarrior.AvtHtr memory s = warrior.getTokenTraits(tokenId);
        string memory svgString = "";
        if (s.isMerry) {
            svgString = string(
                abi.encodePacked(
                    draw(merryBody),
                    drawTrait(traitData[2][s.mask]),
                    drawTrait(traitData[0][s.hair]),
                    drawTrait(traitData[1][s.top]),
                    drawTrait(traitData[3][s.weapon])
                )
            );
        } else if (s.hench_num == 1) {
            svgString = string(
                abi.encodePacked(
                    draw(henchBody1),
                    drawTrait(traitData[5][s.top]),
                    drawTrait(traitData[4][s.hat]),
                    drawTrait(traitData[6][s.weapon]),
                    drawTrait(traitData[7][s.accesorie]),
                    drawTrait(traitData[8][s.bling])
                )
            );
        } else if (s.hench_num == 2) {
            svgString = string(
                abi.encodePacked(
                    draw(henchBody2),
                    drawTrait(traitData[12][s.pants]),
                    drawTrait(traitData[11][s.top]),
                    drawTrait(traitData[10][s.face]),
                    drawTrait(traitData[9][s.hair]),
                    drawTrait(traitData[13][s.weapon])
                )
            );
        } else if (s.hench_num == 3) {
            svgString = string(
                abi.encodePacked(
                    draw(henchBody3),
                    drawTrait(traitData[17][s.pants]),
                    drawTrait(traitData[16][s.top]),
                    drawTrait(traitData[15][s.face]),
                    drawTrait(traitData[14][s.hair]),
                    drawTrait(traitData[18][s.weapon])
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '<svg id="warrior" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );            
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
     * @param value the token's trait associated with the key
     * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
     * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        IWarrior.AvtHtr memory s = warrior.getTokenTraits(tokenId);
        string memory traits;
        if (s.isMerry) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[2][s.mask % traitCountForType[2]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][s.hair % traitCountForType[0]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][s.top % traitCountForType[1]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[3][s.weapon % traitCountForType[3]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Alpha Score",
                        _alphas[s.alphaIndex]
                    ),
                    ","
                )
            );
        } else if (s.hench_num == 1) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[5][s.top % traitCountForType[5]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[4],
                        traitData[4][s.hat % traitCountForType[4]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[6],
                        traitData[6][s.weapon % traitCountForType[6]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[7],
                        traitData[7][s.accesorie % traitCountForType[7]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[8],
                        traitData[8][s.bling % traitCountForType[8]].name
                    ),
                    ","
                )
            );
        } else if (s.hench_num == 2) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[12],
                        traitData[12][s.pants % traitCountForType[12]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[11],
                        traitData[11][s.top % traitCountForType[11]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[10],
                        traitData[10][s.face % traitCountForType[10]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[9],
                        traitData[9][s.hair % traitCountForType[9]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[13],
                        traitData[13][s.weapon % traitCountForType[13]].name
                    ),
                    ","
                )
            );
        } else if (s.hench_num == 3) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[17],
                        traitData[17][s.pants % traitCountForType[17]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[16],
                        traitData[16][s.top % traitCountForType[16]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[15],
                        traitData[15][s.face % traitCountForType[15]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[14],
                        traitData[14][s.hair % traitCountForType[14]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[18],
                        traitData[18][s.weapon % traitCountForType[18]].name
                    ),
                    ","
                )
            );
        }
        string memory gen_num = "";
        if (tokenId <= warrior.getPaidTokens()) {
            gen_num = '"Gen 0"';
        } else if (tokenId <= (warrior.getMaxTokens() * 4) / 6) {            
            gen_num = '"Gen 1"';
        } else if (tokenId <= (warrior.getMaxTokens() * 5) / 6) {
            gen_num = '"Gen 2"';
        } else {
            gen_num = '"Gen 3"';
        }
        return
            string(
                abi.encodePacked(
                    "[",
                    traits,
                    '{"trait_type":"Generation","value":',
                    gen_num,
                    '},{"trait_type":"Type","value":',
                    s.isMerry ? '"Merryman"' : '"Henchman"',
                    "}]"
                )
            );
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        IWarrior.AvtHtr memory s = warrior.getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                s.isMerry ? "Merryman #" : "Henchman #",
                tokenId.toString(),
                '", "description": "Thousands of Merrymen and Henchmen compete on a forest in the metaverse. A tempting prize of $GROAT awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the POLYGON blockchain.", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(tokenId))),
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    /***BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
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