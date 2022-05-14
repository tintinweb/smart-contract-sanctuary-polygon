/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/InventoryManager.sol

//contratto che fa da controller, e prende i dati in base al contratto che gli passo

pragma solidity 0.8.1;

contract InventoryManager {

    address public manager;

    address public sourceAddress;

    string public ipfs;

    constructor() { manager = msg.sender;}

    function setAddress(address add) public {

        sourceAddress = add;

    }

    function get(uint256 numberCard) internal view returns (string memory data_) {
        address source = sourceAddress;

        //string memory numberData = string(abi.encodePacked("_", uint2str(numberCard)));

        data_ = wrapTag(call(source, getData("_", numberCard)));

    }

     function getData(string memory c, uint256 id) internal pure returns (bytes memory data) {
        string memory s = string(abi.encodePacked(
            c,
            toString(id),
            "()"
        ));
        
        return abi.encodeWithSignature(s, "");
    }

    function getImageURI(uint256 cardNumber) public view returns (string memory){

        return get(cardNumber);

    }

    //FUNZIONE COPIATA E INCOLLATA, DA MODIFICARE OVVIAMENTE IN BASE A QUELLO CHE POI CI SERVE ANCHE A NOI
    function getTokenURI(string memory character, uint256 numberCard, string memory weapon, uint8 speed,  uint8 attack, uint8 defence) public view returns (string memory) {

        string memory image = Base64.encode(bytes(getImageURI(numberCard)));

        return string(
            abi.encodePacked(
                    "data:application/json;base64,",
                        Base64.encode(
                                abi.encodePacked(
                                    '{"name": "', character, '","description": "Ninja Turtles of collection",' , '"n of card": "' ,uint2str(numberCard), '","image": "', image, '","animation_url": "', image, '","attributes": [{"trait_type": "Card number", "value": ', uint2str(numberCard), '},{"trait_type": "Speed", "value": ', uint2str(speed), '},{"trait_type": "Attack", "value": ', uint2str(attack), '},{"trait_type": "Defence", "value": ', uint2str(defence), '},{"trait_type": "Weapon", "value": "', weapon, '"}]}'
                                )
                        )
            )           
        );
    }



    //dovrebbe essere la funzione che richiama il contratto
    function call(address source, bytes memory sig) internal view returns (string memory img) {
            (bool succ, bytes memory ret)  = source.staticcall(sig);
            require(succ, "failed to get data");
            img = abi.decode(ret, (string));
    }
    
    function wrapTag(string memory data) internal pure returns (string memory) {
        return string(abi.encodePacked(data));
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