// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface InventoryLike {
    function getSvg() external pure returns (string memory);
}

contract InventoryManagerItems {

    address impl_;
    address public manager;

    mapping (uint256 => address) public svgs;

    function setSvg(uint256 id, address dest) external {
        require(msg.sender == manager);
        svgs[id] = dest;
    }

    function getTokenURI(uint256 id) external view returns (string memory) {
        string memory svg = Base64.encode(bytes(InventoryLike(svgs[id]).getSvg()));
        if (id == 1)   return getURI(svg, "Potion");
        if (id == 2)   return getURI(svg, "Training Dummy");
        if (id == 3)   return getURI(svg, "Luck Rune");
        if (id == 99)  return getURI(svg, "Lava Rock");
        if (id == 100) return getURI(svg, "Fire Crystal");
        if (id == 101) return getURI(svg, "Ice Crystal");
    }

    function getURI(string memory svg, string memory name) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',name,'", "description":"EtherOrcs Items is a collection of various consumables that aid Orcs and their Allies within the greater EtherOrcs ecosystem.", "image": "data:image/svg+xml;base64,',
                                svg,
                                '","attributes": []}'
                            )
                        )
                    )
                )
            );
    }
}



// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
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