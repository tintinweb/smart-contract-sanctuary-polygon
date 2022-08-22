// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Base64.sol';
import './TheStorage.sol';
import './ITokenMaker.sol';

contract TokenMaker {
    string[] private bodyList = [
        "White",
        "Creamwhite",
        "Gray",
        "Black",       
        "Lightgreen",
        "Green",
        "Blue",
        "Lightblue",
        "Lightpurple",
        "Purple",
        "Orange",
        "Red",
        "Pink",
        "Lightbrown",
        "Calico White Black Brown",
        "Calico White Yellow Orange",
        "Calico White Lightgreen Green",
        "Calico White Lightblue Blue",
        "Calico White Pink Red",
        "Calico White Lightpurple Purple",
        "Calico White Gray Black",
        "Striped White Gray",
        "Striped White Purple",
        "Striped White Pink",
        "Striped Lightgreene Green",
        "Striped Lightblue Blue",
        "Striped Cream Orange",
        "Striped Pink White",
        "Striped Black White"
    ];
    string[] private faceList = [
        "Wink Purple",
        "Badsmile Greengray",
        "Badsmile2 Purplegreen",
        "Cool Yellow",
        "Proud Red",
        "Normal Bluegreen",
        "Normal Closedeyes"
    ];
    // // 
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    function randomFaceNumber(uint tokenId) external view returns (uint8) {
        return uint8(pluckId(tokenId, "face", faceList));
    }
    function randomBodyNumber(uint tokenId) external view returns (uint8) {
        return uint8(pluckId(tokenId, "body", bodyList));
    }

    // not 0 to max; 
    function pluckId(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) 
        internal pure returns (uint16) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        return uint16((uint256(rand) % uint256(sourceArray.length))) ;
        // string memory output = sourceArray[rand % sourceArray.length];
    }


    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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


    function addressToString(address account) public pure returns(string memory) {
        return byteToString(abi.encodePacked(account));
    }
    function byteToString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function uint256ToString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
    
    function getAttributeString(string memory _name, string memory _value, bool withComma) public pure  returns (string memory) {
      string memory l = '"';
      if (withComma) {
        l = '",';
      }
      return string(abi.encodePacked('"',_name,'":', '"', _value , l ));
    }

    function getStringTraitJsonString(string memory _name, string memory _value, string memory _display,  bool withComma) public pure returns(string memory) {
      string memory l = '';
      if (withComma) {
        l = ',';
      }
      if (keccak256(abi.encodePacked((_display)))==keccak256(abi.encodePacked(("")))) {
          return string(abi.encodePacked('{"trait_type":"',_name,'","value":"', _value, '"}' , l ));
      }
      return string(abi.encodePacked('{"display_type":"',_display,'","trait_type":"',_name,'","value":"', _value, '"}' , l ));
    }

    function getNumberTraitJsonString(string memory _name, uint256 _value, string memory _display,  bool withComma) public pure returns(string memory) {
      string memory l = '';
      if (withComma) {
        l = ',';
      }
      if (keccak256(abi.encodePacked((_display)))==keccak256(abi.encodePacked(("")))) {
          return string(abi.encodePacked('{"trait_type":"',_name,'","value":', uint256ToString(_value), '}' , l ));
      }
      return string(abi.encodePacked('{"display_type":"',_display,'","trait_type":"',_name,'","value":', uint256ToString(_value), '}' , l ));
    }

    function getAttributesJson(
        TheStorage memory _item
    ) public view returns(string memory) {

        return  
          string(abi.encodePacked(
            '"attributes": {',
              getStringTraitJsonString('Body', bodyList[_item.trait_body], "",true ),
              getStringTraitJsonString('Face', faceList[_item.trait_face], "",true ),
              //
              getStringTraitJsonString('Wings', uint256ToString(_item.equip_wings), "",true ),
              getStringTraitJsonString('Neck', uint256ToString(_item.equip_neck), "",true ),
              getStringTraitJsonString('Ear', uint256ToString(_item.equip_ear), "",true ),
              getStringTraitJsonString('Hat', uint256ToString(_item.equip_hat), "",true ),
              getStringTraitJsonString('Legs', uint256ToString(_item.equip_legs), "",true ),
            //   //
            //   getStringTraitJsonString('Background', uint256ToString(_item.bg), "",true ),
            //   getStringTraitJsonString('Effect', uint256ToString(_item.effect), "",true ),
              getStringTraitJsonString('Level', uint256ToString(_item.level), "",false ),

            '}'
          ));
    }

    function getImageURL(
        TheStorage memory _item
    ) public pure returns(string memory) {

        
        string[26] memory parts;
        parts[0] = 'https://imgapi.twinkle.cat/v0/img/cat/jpg/';
        parts[1] = 'body-';
        parts[2] =  uint256ToString(_item.trait_body);
        parts[3] = '.face-' ;
        parts[4] =  uint256ToString(_item.trait_face);
        parts[5] = '.wing-' ;
        parts[6] =  uint256ToString(_item.equip_wings);
        parts[7] = '.neck-' ;
        parts[8] =  uint256ToString(_item.equip_neck);
        parts[9] = '.ear-' ;
        parts[10] =  uint256ToString(_item.equip_ear);
        parts[11] = '.hat-' ;
        parts[12] =  uint256ToString(_item.equip_hat);
        parts[13] = '.legs-' ;
        parts[14] =  uint256ToString(_item.equip_legs);
        parts[15] = '.bg-' ;
        parts[16] =  uint256ToString(_item.bg);
        parts[17] = '.effect-' ;
        parts[18] =  uint256ToString(_item.effect);
        parts[19] = '.level-' ;
        parts[20] =  uint256ToString(_item.level);
        string memory url1 = 
          string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        string memory url2 = 
          string(abi.encodePacked(parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        string memory url3 = 
          string(abi.encodePacked(parts[17], parts[18], parts[19], parts[20]));
        string memory url = 
          string(abi.encodePacked(url1, url2, url3));
        return url;
    }
    function createJson(uint256 _tokenId, TheStorage memory _item) public view returns(string memory) {
        string memory json = string(abi.encodePacked(
                '{"name": "TheNFT #', uint256ToString(_tokenId), '", ',
                // '"description": "TESTDESCRIPTION",',
                '"external_url":"https://twinkle.cat/",',
                '"image": "',getImageURL(_item),'",',
                getAttributesJson(_item),
                '}' // end of json
                ));
        return json;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// [MIT License]
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct TheStorage {
    uint8 level;

    uint8 equip_wings;
    uint8 equip_neck;
    uint8 equip_ear;
    uint8 equip_hat;
    uint8 equip_legs;
    
    uint8 bg;
    uint8 effect;

    uint8 trait_body;
    uint8 trait_face;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import './TheStorage.sol';

interface ITokenMaker {
    function createJson(uint256 _tokenId, TheStorage memory _item) external pure returns(string memory);

    function randomFaceNumber(uint tokenId) external view returns (uint8) ;
    function randomBodyNumber(uint tokenId) external view returns (uint8) ;

}