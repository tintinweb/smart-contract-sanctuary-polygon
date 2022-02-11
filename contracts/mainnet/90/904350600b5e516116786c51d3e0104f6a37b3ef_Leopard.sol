// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
*________________________Leopard(PARD)___________________________
*____________元宇宙头号MEME军团，金钱豹大军强势来袭。_______________
*____________在全球华人最隆重的节日，农历新年来临期间。______________
*_金钱豹，这个源自中国神话里的重要人物因为谐音“金钱暴富”意外爆红网络。_
*______________全网日均浏览量过亿，MEME情绪持续高涨。_______________
*_________________纵观全球疫情危难，金融风暴肆略。__________________
*______________金钱豹家族带着农历春节一片祥和福瑞之气。______________
*__________向全球人民送出一份美好的祝福：新年快乐，金钱暴富！_________
**/

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Receivable.sol";

contract Leopard is ERC721Enumerable, ReentrancyGuard, Ownable, Receivable {
    
    constructor() ERC721("Leopard", "PARD") Ownable() {}

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    uint256 public constant PRICE = 1.8 ether;// 1.8 MATIC
    
    // The LeopardDAO Community will award airdrop soon.
    function mintWithFees() public payable nonReentrant {
        require(msg.value >= PRICE, "Insufficient funds to mint, at least 1.8 MATIC.");
        uint256 latestId = totalSupply();
        _safeMint(_msgSender(), latestId);

        // Magic number :)
        require(totalSupply() <= 10000, "Max mint amount");
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        string memory output;
        if (tokenId < 100) {
            output = string(
            abi.encodePacked(
                "ipfs://QmUESZAPg6ZJo5NxwjurCAqu1SBrUFzYdwSuSkDRqMziXe/",
                Utils.toString(tokenId),
                ".png"
            )
        );
        } else {
            output = string(
            abi.encodePacked(
                "ipfs://QmUESZAPg6ZJo5NxwjurCAqu1SBrUFzYdwSuSkDRqMziXe/",
                "9999.png"
            )
        );
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Leopard #',
                        Utils.toString(tokenId),
                        '", "description": "LeopardDAO is a global Chinese Community. We share MEME to everyone with: Sincerity, Integrity, Meaning, and Purpose. LeopardDAO to be continued...", "image": "',
                        output,
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
}


library Utils {
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
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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