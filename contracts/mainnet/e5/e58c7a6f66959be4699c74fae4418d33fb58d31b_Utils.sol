/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

library Utils {

    function getLevel(uint256 exp) public pure returns (uint256) {
        if(exp < 5) {
            return 1;
        } else if(exp < 15){
            return 2;
        } else if(exp < 30){
            return 3;
        } else if(exp < 50){
            return 4;
        } else {
            return 5;
        }
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
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}