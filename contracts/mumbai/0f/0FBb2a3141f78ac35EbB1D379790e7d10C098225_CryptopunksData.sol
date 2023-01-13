/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity 0.7.6;

contract CryptopunksData {

    string internal constant SVG_HEADER = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 32 32" shape-rendering="crispEdges">';
    string internal constant SVG_FOOTER = '</svg>';

    mapping(uint64 => bytes) private punks;


    function addPunks(uint64 index, bytes memory _punks) public {
        punks[index] = _punks;
    }


    function punkImageSvg(uint16 index) external view returns (string memory svg) {
        bytes memory pixels = punks[index];
        svg = string(abi.encodePacked(SVG_HEADER));
        bytes memory buffer = new bytes(6);
        for (uint y = 0; y < 32; y++) {
            for (uint x = 0; x < 32; x++) {
                uint p = (y * 32 + x) * 3;
                if (uint8(pixels[p + 2]) > 0) {
                    for (uint i = 0; i < 3; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    svg = string(abi.encodePacked(svg,
                        '<rect x="', toString(x), '" y="', toString(y),'" width="1" height="1" fill="#', string(buffer),'"/>'));
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

}