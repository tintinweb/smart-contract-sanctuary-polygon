// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonsterPartData is Ownable
{
    uint8[5] public BASE_STATS = [5,10,3,3,20];//attack, hp, defense, speed, accuracy
    uint8[5] public COUNTER_CLASSES = [3,4,5,1,2];
    uint8[5] public GENERATION_CLASSES = [2,3,4,5,1];
    uint8 public constant EVOLVE_LEVEL_REQUIRE = 3;
    using Strings for uint256;
    struct Part {
    uint8 partType;//1:Body 2:Horn 3:back 4:tail 5:eye
    uint8 class;//1: Fire: 2:Ground 3:Metal 4:Water 5:Plant
    uint8 rarity;//1:normal 2:rare 3:superrare
  }

    bool public isMonsterPartData = true;

    mapping(uint256 => Part) public parts;

    function addPartData(uint256 _partIndex, uint8 _type, uint8 _class, uint8 _rarity) external onlyOwner
    {
        parts[_partIndex] = Part(_type, _class, _rarity);
    }

    function getEvolveRequireLevel(uint8[5] memory _decodeGene, uint8 evolve) external view returns(uint8)
    {
        uint8 levelRequire = 0;
        for (uint8 i = 0; i < _decodeGene.length; i++)
        {
            uint8 rarity =parts[_decodeGene[i]].rarity;
            if((rarity > 2 && evolve < 3) || (rarity > 1 && evolve < 2))
            {
                levelRequire += EVOLVE_LEVEL_REQUIRE;
            }
        }
        return levelRequire;
    }

    function getCounterGene(uint8 bodyGene1, uint8 bodyGene2) external view returns(uint8)//0: not counter
    {
        uint8 class1 = parts[bodyGene1].class;
        uint8 class2 = parts[bodyGene2].class;
        if(COUNTER_CLASSES[class1 -1] == class2)
        {
            return bodyGene1;
        }else if(COUNTER_CLASSES[class2 -1] == class1)
        {
            return bodyGene2;
        }

        return 0;
    }

    function getBaseStatPoints(uint8[5] memory _decodeGene) external view returns(uint8[5] memory)
    {
        uint8[5] memory baseStats = BASE_STATS;
        uint8 bodyClass = parts[_decodeGene[0]].class;
        baseStats[bodyClass - 1] += 3;//Body bonus: Fire: +3Attack, Ground: +3hp, Metal: +3defense, Water: +3speed, Plant: +3Accuracy
        //gene order: Body -> Horn -> back -> tail -> eye <=> Attack -> HP -> Defense -> Speed -> Accuracy
        for(uint8 i =0;i<_decodeGene.length;i++)
        {
            uint8 partClass = parts[_decodeGene[i]].class;
            uint supportIndex1 = 4;
            uint supportIndex2 = 3;
            if(i == 1)
            {
                supportIndex1 = 0;
                supportIndex2 = 4;
            }else if(i > 1)
            {
                supportIndex1 = i-1;
                supportIndex2 = i-2;
            }
            uint8 supportPartClass1 = parts[_decodeGene[supportIndex1]].class;
            uint8 supportPartClass2 = parts[_decodeGene[supportIndex2]].class;
            if(GENERATION_CLASSES[partClass - 1] ==  supportPartClass1)
                baseStats[partClass - 1] += 3;
            if(GENERATION_CLASSES[partClass - 1] ==  supportPartClass2)
                baseStats[partClass - 1] += 1; 
        }
        return baseStats;
    }

    function constructTokenURI(uint8[5] memory _decodeGene, uint256 _id) public pure returns (string memory)
    {
        string memory name = string(abi.encodePacked("Monster #", _id.toString()));
        string memory image = string(abi.encodePacked("https://breeddemoapi.herokuapp.com/monsters/", _id.toString()));
        // attributes handle
        string memory attribute ="[";
        attribute = string(abi.encodePacked(attribute,'{"trait_type":"BODY",'));
        attribute = string(abi.encodePacked(attribute,'"value":"body', uint256(_decodeGene[0]).toString(), '"}',","));
        attribute = string(abi.encodePacked(attribute,'{"trait_type":"HORN",'));
        attribute = string(abi.encodePacked(attribute,'"value":"horn', uint256(_decodeGene[1]).toString(), '"}',","));
        attribute = string(abi.encodePacked(attribute,'{"trait_type":"BACK",'));
        attribute = string(abi.encodePacked(attribute,'"value":"back', uint256(_decodeGene[2]).toString(), '"}',","));
        attribute = string(abi.encodePacked(attribute,'{"trait_type":"TAIL",'));
        attribute = string(abi.encodePacked(attribute,'"value":"tail', uint256(_decodeGene[3]).toString(), '"}',","));
        attribute = string(abi.encodePacked(attribute,'{"trait_type":"EYES",'));
        attribute = string(abi.encodePacked(attribute,'"value":"eyes', uint256(_decodeGene[4]).toString(), '"}'));
        attribute = string(abi.encodePacked(attribute,"]"));

    return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    abi.encodePacked('{"name":"', name, '", "description":"', name, '", "image": "', image, '","attributes":',attribute,'}')
                )
            )
        );
    }

   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

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