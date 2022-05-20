/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}


// File contracts/InventoryManager.sol

// SPDX-License-Identifier: Unlicense
//contratto che fa da controller, e prende i dati in base al contratto che gli passo
pragma solidity 0.8.1;

contract InventoryManager {

    using Base64 for bytes;

    struct Card {
        string uuid;
        string id;
        uint32 baseId;
        uint32 number;
        string cardType;
        string category;
        string rarity;
    }

    struct CardInfo {
        string name;
        string description; 
        uint32 version;
        string illustrator; 
        string medias; 
    }

    struct CardAttr {
        bool alternative;
        bool foil; 
    }

    struct CardOwner {
        string uuid;
        address owner;
    }

    struct CardExtra {
        string element;
        string origin;
        string faction;
        uint32 basePower;
        uint8 potential;
        uint8 rank;
        bool alternativeCombo;
    }

    struct NormalCard{
        Card base;
        CardInfo info;
        CardOwner owner;
        CardAttr attr;
    }

    struct BattleCard {
        Card base;
        CardInfo info;
        CardOwner owner;
        CardAttr attr;
        CardExtra extra;
    }

    address public manager;

    address public sourceAddress;

    string public ipfs;

    enum Status {NORMALE, SUPER, ULTRA}


    constructor() { manager = msg.sender;}

    function setAddress(address add) public {

        sourceAddress = add;

    }

    

    function _getTokenURI_Normal(NormalCard memory card) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                    "data:application/json;base64,",
                    abi.encodePacked(
                        "{",
                            _card_header(card.info),
                            "\"attributes\": [",
                            _card_base_attribute(card.base),
                            _attribute_trait_type("illustrator", card.info.illustrator),
                            _attribute_trait_type("version", StringUtils.uint2str(card.info.version)),
                            _attribute_trait_type("alternative", StringUtils.boolToString(card.attr.alternative)),
                            _attribute_trait_type("foil", StringUtils.boolToString(card.attr.foil)),
                            _card_owner_attribute(card.owner),
                        "]}"
                    ).encode()
            )           
        );
    }

    function _getTokenURI_Battle(BattleCard memory card) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                abi.encodePacked(
                    "{",
                    _card_header(card.info),
                    "\"attributes\": [",
                    _card_base_attribute(card.base),
                    _attribute_trait_type("illustrator", card.info.illustrator),
                    _attribute_trait_type("version", StringUtils.uint2str(card.info.version)),
                    _attribute_trait_type("alternative", StringUtils.boolToString(card.attr.alternative)),
                    _attribute_trait_type("foil", StringUtils.boolToString(card.attr.foil)),
                    _card_owner_attribute(card.owner),
                    _card_extra_attribute(card.extra),
                    "]}"
                ).encode()
            )
        );
    }

    function _attribute_trait_type(string memory _type, string memory value) private pure returns (string memory) {
        return string(abi.encodePacked("{\"trait_type\":\"",_type,"\",\"value\":",value,"}"));
    }

    function _card_header(CardInfo memory info) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                    "\"name\": \"", info.name, "\",",
                    "\"description\": \"", info.description, "\",",
                    "\"image\": \"", info.medias, "\",",
                    "\"animation_url\": \"", info.medias, "\","
            )
        );
    }
    function _card_extra_attribute(CardExtra memory extra) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                _attribute_trait_type("card Element", extra.element),
                _attribute_trait_type("card Origin", extra.origin),
                _attribute_trait_type("card Faction", extra.faction),
                _attribute_trait_type("base Power", StringUtils.uint2str(extra.basePower)),
                _attribute_trait_type("potential", StringUtils.uint2str(extra.potential)),
                _attribute_trait_type("rank", StringUtils.uint2str(extra.rank)),
                _attribute_trait_type("alternative Combo", StringUtils.boolToString(extra.alternativeCombo))
            )
        );
    }

    function _card_owner_attribute(CardOwner memory owner) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                    _attribute_trait_type("ownerUuid", owner.uuid),
                    _attribute_trait_type("ownerAddress", string(abi.encodePacked(owner.owner)))
            )
        );
    }

    function _card_base_attribute(Card memory base) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                    _attribute_trait_type("number", StringUtils.uint2str(base.number)),
                    _attribute_trait_type("card Type", base.cardType),
                    _attribute_trait_type("card Category", base.category),
                    _attribute_trait_type("card Rarity", base.rarity)
            )
        );
    }

}

library StringUtils {

    function boolToString(bool a) internal pure returns (string memory){

        if(a)
            return "true";
        else
            return "false";

    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintSsString) {

        if(_i == 0){
            return "0";
        }
        uint j = _i;
        uint len;
        while(j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while(_i != 0){
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;

        }
        return string(bstr);

    }
}