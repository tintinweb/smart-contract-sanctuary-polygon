/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity 0.8.7;

library mortlib {
    function bytesToUint(bytes memory b) public pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }
    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function intToStr(int v) internal pure returns (bytes memory) {
        uint maxlength = 100; 
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        uint x;
        if(v < 0)
            x = uint(-v);
        else
            x = uint(v);
        while (x != 0) { 
            uint8 remainder = uint8(x % 10); 
            x = x / 10; 
            reversed[i % maxlength] = bytes1(48 + remainder); 
            i++;
        }
        if(v < 0)
            reversed[(i++) % maxlength] = "-";
        bytes memory s = new bytes(i+1); 
        for (uint j = 1; j <= i % maxlength; j++) { 
            s[j - 1] = reversed[i - j];
        } 
        return bytes(s); 
    }
    function _arrayAdd(int128[5] memory first, int128[5] memory second) internal pure returns(int128[5] memory sum){
        sum[0] = first[0] + second[0];
        sum[1] = first[1] + second[1];
        sum[2] = first[2] + second[2];
        sum[3] = first[3] + second[3];
        sum[4] = first[4] + second[4];
    }
    function _arraySub(int128[5] memory first, int128[5] memory second) internal pure returns(int128[5] memory sum){
        sum[0] = first[0] - second[0];
        sum[1] = first[1] - second[1];
        sum[2] = first[2] - second[2];
        sum[3] = first[3] - second[3];
        sum[4] = first[4] - second[4];
    }

    function _arrayMul(int128 first, int128[5] memory second) internal pure returns(int128[5] memory sum){
        sum[0] = first * second[0];
        sum[1] = first * second[1];
        sum[2] = first * second[2];
        sum[3] = first * second[3];
        sum[4] = first * second[4];
    }


    function _genModifier(int128[5] memory first, int128[5] memory second) internal pure returns(int128[5] memory modded){
        modded[0] = first[0] * second[0] / 1000;
        modded[1] = first[1] * second[1] / 1000;
        modded[2] = first[2] * second[2] / 1000;
        modded[3] = first[3] * second[3] / 1000;
        modded[4] = first[4] * second[4] / 1000;
    }
    function _genUnmodifier(int128[5] memory first, int128[5] memory second) internal pure returns(int128[5] memory modded){
        modded[0] = (first[0] * 1000) / second[0];
        modded[1] = (first[1] * 1000) / second[1];
        modded[2] = (first[2] * 1000) / second[2];
        modded[3] = (first[3] * 1000) / second[3];
        modded[4] = (first[4] * 1000) / second[4];
    }
    function ERC1155BatchTest(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256 courLimit,
        uint256 devLimit
    ) internal pure  {
        uint16 allotments = 0;
        uint16 court = 0;
        uint16 allotFake = 0;
        uint16 courtFake = 0;
        for(uint i = 0; i < ids.length; i++){
            require(amounts[i] == 1, "Use the client or you'll burn an NFT, dipshit");
            if(ids[i] < 10000){
                allotments = 0;
                court = 0;
            } else if(ids[i] < 100000){
                allotments++;
                if(ids[i] == 10000)
                    allotFake++;
            } else if(ids[i] < 1000000){
                court++;
                if(ids[i] == 100000)
                    courtFake++;
            }
                
            require(allotments - allotFake < devLimit + 1, "Cannot stake more than 18 structures per castle");
            require(court - courtFake < courLimit + 1, "Cannot stake more than 3 courtiers");
        }

    }
}