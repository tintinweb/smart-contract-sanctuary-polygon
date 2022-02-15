// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PirateItem.sol";
import "../traits/TokenTrait.sol";

interface IPirateItemMetadata {
    
    function pirateItemExists(uint256 tokenId) external view returns (bool);

    function allTokenIds() external view returns (uint256[] memory);

    function addPirateItem(uint256 tokenId, PirateItem memory pirateItem, TokenTrait[] memory tokenTraits) external;

    function updatePirateItem(uint256 tokenId, PirateItem calldata pirateItem, TokenTrait[] calldata traits) external;
    
    function getPirateItem(uint256 tokenId) external view returns (PirateItem memory);

    function getPirateItemCost(uint256 tokenId) external view returns (uint256);
    
    function getTotalCost(uint256[] memory tokenIds, uint256[] memory amounts) external view returns (uint256);

    function getTokenTraits(uint256 tokenId) external view returns (TokenTrait[] memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct PirateItem {
    string name; // required
    string description;
    string imageUri;
    uint256 cost;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IPirateItemMetadata.sol";
import "./PirateItem.sol";
import "../traits/TokenTrait.sol";

contract PirateItemMetadata 
    is IPirateItemMetadata 
{
    using Strings for uint256;

    address private _owner;

    mapping(uint256 => PirateItem) private tokenIdToPirateItem;
    mapping(uint256 => TokenTrait[]) private tokenIdToTokenTraits;

     // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Not Owner");
        _;
    }

    modifier itemExists(uint256 tokenId) {
        require(pirateItemExists(tokenId), "Item not found");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function pirateItemExists(uint256 tokenId) override public view returns (bool) {
        return bytes(tokenIdToPirateItem[tokenId].name).length != 0;
    }

    function allTokenIds() override public view returns (uint256[] memory) {
        return _allTokens;
    }

    function addPirateItem(uint256 tokenId, PirateItem calldata pirateItem, TokenTrait[] calldata traits) 
        override 
        external 
        onlyOwner 
    {
        if (!pirateItemExists(tokenId)) {
            require(bytes(pirateItem.name).length != 0, "Invalid item");

            tokenIdToPirateItem[tokenId] = PirateItem(pirateItem.name, pirateItem.description, pirateItem.imageUri, pirateItem.cost);

            for (uint8 i = 0; i < traits.length; i++) {
                tokenIdToTokenTraits[tokenId].push(
                    TokenTrait(traits[i].traitType, traits[i].traitValue, traits[i].displayType)
                );
            }

            _allTokensIndex[tokenId] = _allTokens.length;
            _allTokens.push(tokenId);
        }
    }

    function updatePirateItem(uint256 tokenId, PirateItem calldata pirateItem, TokenTrait[] calldata traits) 
        override 
        external 
        onlyOwner 
        itemExists(tokenId) 
    {
        require(bytes(pirateItem.name).length != 0, "Invalid item");

        tokenIdToPirateItem[tokenId] = PirateItem(pirateItem.name, pirateItem.description, pirateItem.imageUri, pirateItem.cost);

        delete tokenIdToTokenTraits[tokenId];

        for (uint8 i = 0; i < traits.length; i++) {
            tokenIdToTokenTraits[tokenId].push(
                TokenTrait(traits[i].traitType, traits[i].traitValue, traits[i].displayType)
            );
        }
    }

    function removePirateItem(uint256 tokenId) public onlyOwner itemExists(tokenId) {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();

        PirateItem memory pirateItem;
        tokenIdToPirateItem[tokenId] = pirateItem;

        delete tokenIdToTokenTraits[tokenId];
    }

    function getPirateItem(uint256 tokenId) override public view itemExists(tokenId) returns (PirateItem memory) {
        return tokenIdToPirateItem[tokenId];
    }

    function getTokenTraits(uint256 tokenId) override public view itemExists(tokenId) returns (TokenTrait[] memory) {
        return tokenIdToTokenTraits[tokenId];
    }

    function getPirateItemCost(uint256 tokenId) override public view returns (uint256) {
        return tokenIdToPirateItem[tokenId].cost;
    }

    function getTotalCost(uint256[] memory tokenIds, uint256[] memory amounts) override public view returns (uint256 cost) {
        require(tokenIds.length == amounts.length, "Invalid args");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            cost += getPirateItemCost(tokenIds[i]) * amounts[i];
        }
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return buildPirateItemTokenUri(tokenId);
    }

    function buildPirateItemTokenUri(uint256 tokenId) private view returns (string memory) {

        PirateItem memory pirateItem = getPirateItem(tokenId);
        TokenTrait[] memory tokenTraits = getTokenTraits(tokenId);

        // string(abi.encodePacked("Avatar for MVPS Pirate #", pirateTokenId.toString())),
        string memory metadata = 
            string(
                abi.encodePacked('{"name":"', pirateItem.name, 
                    '", "description":"', pirateItem.description, 
                    '", "image":"', pirateItem.imageUri, '", "attributes":[', compileAttributes(tokenTraits), ']}'
                )
            );

        return metadata;
    }

    function compileAttributes(TokenTrait[] memory tokenTraits) private pure returns (string memory) {
        
        string memory attributes;

        for (uint256 i = 0; i < tokenTraits.length; i++) {
            
            attributes = string(
                abi.encodePacked(attributes, 
                    string(
                        abi.encodePacked(
                            '{"value":"',
                            tokenTraits[i].traitValue,
                            
                            uint8(tokenTraits[i].displayType) != 0 ?
                                string(abi.encodePacked('","display_type":"',
                                getDisplayTypeName(tokenTraits[i].displayType))) : '',

                            '","trait_type":"',
                            tokenTraits[i].traitType,
                            '"}',

                            i < tokenTraits.length -1 ? "," : ''
                        )
                    )
                )
            );
        }

        return attributes;
    }

    function getDisplayTypeName(TraitDisplayType traitDisplayType) private pure returns (string memory)
    {
        if (traitDisplayType == TraitDisplayType.Number)
        {
            return "number";
        }
        return "string";
    } 

    function st2num(string memory numString) public pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TraitDisplayType.sol";

string constant NOTORIETY_POINTS_TRAIT_NAME = "Notoriety Points";
string constant PIRATE_TYPE_NAME = "Pirate Type";
string constant STATUS_TYPE_NAME = "Status";
string constant PROFICIENCY_TRAIT_NAME = "Proficiency";
string constant SHIP_TYPE_NAME = "Ship Type";

string constant PROFICIENCY_BONUS_TRAIT_NAME = "Proficiency Bonus";
string constant VALUE_TRAIT_NAME = "Value";

struct TokenTrait {
    string traitType; // required
    string traitValue;
    TraitDisplayType displayType;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum TraitDisplayType {
    String,
    Number
}