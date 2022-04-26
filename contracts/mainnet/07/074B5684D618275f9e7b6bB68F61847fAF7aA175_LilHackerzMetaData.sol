// SPDX-License-Identifier: MIT
/**
>>>   Made with tears and confusion by LFBarreto   <<<
>> https://github.com/LFBarreto/mamie-fait-des-nft  <<
>>>           inspired by nouns.wtf                <<<
*/
pragma solidity 0.8.13;

import "base64-sol/base64.sol";

import "./ILilHackerzMetadata.sol";

contract LilHackerzMetaData is ILilHackerzMetadata {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    uint16[6][][] public _heads;
    uint16[6][][] public _hairs;
    uint16[6][][] public _hats;
    uint16[6][][] public _accessories;
    uint16[6][][] public _eyes;
    uint16[6][][] public _mouths;

    string[] public _heads_traits;
    string[] public _hairs_traits;
    string[] public _hats_traits;
    string[] public _accessories_traits;
    string[] public _eyes_traits;
    string[] public _mouths_traits;

    string public _p0 = "";
    string public _p1 = "";

    string public _description = "";
    string public _web_link = "";

    function _getP0() public view returns (string memory) {
        return _p0;
    }

    function _getP1() public view returns (string memory) {
        return _p1;
    }

    function _setSvgParts(string memory p0, string memory p1) public {
        require(msg.sender == _owner, "Only owner");
        _p0 = p0;
        _p1 = p1;
    }

    function _getDescription() public view returns (string memory) {
        return _description;
    }

    function _setDescription(string memory description) public {
        require(msg.sender == _owner, "Only owner");
        _description = description;
    }

    function _getWebBaseLink() public view returns (string memory) {
        return _web_link;
    }

    function _setWebBaseLink(string memory web_link) public {
        require(msg.sender == _owner, "Only owner");
        _web_link = web_link;
    }

    function _getHeads() public view returns (uint16[6][][] memory) {
        return _heads;
    }

    function _getHeadsTraits() public view returns (string[] memory) {
        return _heads_traits;
    }

    function _addHeads(
        uint16[6][][] calldata heads,
        string[] memory head_traits
    ) public {
        require(msg.sender == _owner, "Only owner");
        for (uint16 i = 0; i < heads.length; i++) {
            _heads.push(heads[i]);
            _heads_traits.push(head_traits[i]);
        }
    }

    function _setHead(
        uint16[6][] calldata head,
        string memory head_trait,
        uint256 index
    ) public {
        require(msg.sender == _owner, "Only owner");
        _heads[index] = head;
        _heads_traits[index] = head_trait;
    }

    function _getHairs() public view returns (uint16[6][][] memory) {
        return _hairs;
    }

    function _getHairsTraits() public view returns (string[] memory) {
        return _hairs_traits;
    }

    function _addHairs(
        uint16[6][][] calldata hairs,
        string[] memory hair_traits
    ) public {
        require(msg.sender == _owner, "Only owner");
        for (uint16 i = 0; i < hairs.length; i++) {
            _hairs.push(hairs[i]);
            _hairs_traits.push(hair_traits[i]);
        }
    }

    function _setHair(
        uint16[6][] calldata hair,
        string memory hair_trait,
        uint256 index
    ) public {
        require(msg.sender == _owner, "Only owner");
        _hairs[index] = hair;
        _hairs_traits[index] = hair_trait;
    }

    function _getHats() public view returns (uint16[6][][] memory) {
        return _hats;
    }

    function _getHatsTraits() public view returns (string[] memory) {
        return _hats_traits;
    }

    function _addHats(uint16[6][][] calldata hats, string[] memory hats_traits)
        public
    {
        require(msg.sender == _owner, "Only owner");
        for (uint16 i = 0; i < hats.length; i++) {
            _hats.push(hats[i]);
            _hats_traits.push(hats_traits[i]);
        }
    }

    function _setHats(
        uint16[6][] calldata hat,
        string memory hat_traits,
        uint256 index
    ) public {
        require(msg.sender == _owner, "Only owner");
        _hats[index] = hat;
        _hats_traits[index] = hat_traits;
    }

    function _getAccessories() public view returns (uint16[6][][] memory) {
        return _accessories;
    }

    function _getAccessoriesTraits() public view returns (string[] memory) {
        return _accessories_traits;
    }

    function _addAccessories(
        uint16[6][][] calldata accessories,
        string[] memory accessories_traits
    ) public {
        require(msg.sender == _owner, "Only owner");
        for (uint16 i = 0; i < accessories.length; i++) {
            _accessories.push(accessories[i]);
            _accessories_traits.push(accessories_traits[i]);
        }
    }

    function _setAccessory(
        uint16[6][] calldata accesory,
        string memory accessory_trait,
        uint256 index
    ) public {
        require(msg.sender == _owner, "Only owner");
        _accessories[index] = accesory;
        _accessories_traits[index] = accessory_trait;
    }

    function _getEyes() public view returns (uint16[6][][] memory) {
        return _eyes;
    }

    function _getEyesTraits() public view returns (string[] memory) {
        return _eyes_traits;
    }

    function _addEyes(uint16[6][][] calldata eyes, string[] memory eyes_traits)
        public
    {
        require(msg.sender == _owner, "Only owner");
        for (uint16 i = 0; i < eyes.length; i++) {
            _eyes.push(eyes[i]);
            _eyes_traits.push(eyes_traits[i]);
        }
    }

    function _setEyes(
        uint16[6][] calldata eye,
        string memory eye_trait,
        uint256 index
    ) public {
        require(msg.sender == _owner, "Only owner");
        _eyes[index] = eye;
        _eyes_traits[index] = eye_trait;
    }

    function _getMouths() public view returns (uint16[6][][] memory) {
        return _mouths;
    }

    function _getMouthsTraits() public view returns (string[] memory) {
        return _mouths_traits;
    }

    function _addMouths(
        uint16[6][][] calldata mouths,
        string[] memory mouths_traits
    ) public {
        require(msg.sender == _owner, "Only owner");
        for (uint16 i = 0; i < mouths.length; i++) {
            _mouths.push(mouths[i]);
            _mouths_traits.push(mouths_traits[i]);
        }
    }

    function _setMouth(
        uint16[6][] calldata mouth,
        string memory mouth_trait,
        uint256 index
    ) public {
        require(msg.sender == _owner, "Only owner");
        _mouths[index] = mouth;
        _mouths_traits[index] = mouth_trait;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface ILilHackerzMetadata {
    function _getP0() external view returns (string memory);

    function _getP1() external view returns (string memory);

    function _setSvgParts(string memory p0, string memory p1) external;

    function _getDescription() external view returns (string memory);

    function _setDescription(string memory description) external;

    function _getWebBaseLink() external view returns (string memory);

    function _setWebBaseLink(string memory web_link) external;

    function _getHeads() external view returns (uint16[6][][] memory);

    function _getHeadsTraits() external view returns (string[] memory);

    function _addHeads(
        uint16[6][][] calldata heads,
        string[] memory head_traits
    ) external;

    function _setHead(
        uint16[6][] calldata head,
        string memory head_trait,
        uint256 index
    ) external;

    function _getHairs() external view returns (uint16[6][][] memory);

    function _getHairsTraits() external view returns (string[] memory);

    function _addHairs(
        uint16[6][][] calldata hairs,
        string[] memory hair_traits
    ) external;

    function _setHair(
        uint16[6][] calldata hair,
        string memory hair_trait,
        uint256 index
    ) external;

    function _getHats() external view returns (uint16[6][][] memory);

    function _getHatsTraits() external view returns (string[] memory);

    function _addHats(uint16[6][][] calldata hats, string[] memory hats_traits)
        external;

    function _setHats(
        uint16[6][] calldata hat,
        string memory hat_traits,
        uint256 index
    ) external;

    function _getAccessories() external view returns (uint16[6][][] memory);

    function _getAccessoriesTraits() external view returns (string[] memory);

    function _addAccessories(
        uint16[6][][] calldata accessories,
        string[] memory accessories_traits
    ) external;

    function _setAccessory(
        uint16[6][] calldata accesory,
        string memory accessory_trait,
        uint256 index
    ) external;

    function _getEyes() external view returns (uint16[6][][] memory);

    function _getEyesTraits() external view returns (string[] memory);

    function _addEyes(uint16[6][][] calldata eyes, string[] memory eyes_traits)
        external;

    function _setEyes(
        uint16[6][] calldata eye,
        string memory eye_trait,
        uint256 index
    ) external;

    function _getMouths() external view returns (uint16[6][][] memory);

    function _getMouthsTraits() external view returns (string[] memory);

    function _addMouths(
        uint16[6][][] calldata mouths,
        string[] memory mouths_traits
    ) external;

    function _setMouth(
        uint16[6][] calldata mouth,
        string memory mouth_trait,
        uint256 index
    ) external;
}