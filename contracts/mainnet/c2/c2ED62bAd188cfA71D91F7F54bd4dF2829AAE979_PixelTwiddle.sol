// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}

contract PixelTwiddle is ISnowV1Program {

    function name() external pure returns (string memory) {
        return "PixelTwiddle";
    }

    function run(uint256[64] calldata canvas, uint8 /*lastUpdatedIndex*/) external view returns (uint8 index, uint256 value) {
        //fake source of randomness
        index = uint8(block.timestamp % 64);
        value = canvas[index];

        if (value == 0) {
            value = invert(value);
        } else {
            uint choice = index % 3;
            if( choice == 0) {
                 value = erase(value);
            } 
            
            else if (choice == 1) {
                //if the index is the first pixel of the canvas, we pass in the pixel and the next one after it to the exclude function
                //else, we pass in the pixel and the one before it.
                 value = 
                    index == 0 ? excludeSelection(value, canvas[index+1]) : excludeSelection(value, canvas[index-1]);
            } 
            
            else {
                 value = 
                    index == 0 ? union(value, canvas[index+1]) : union(value, canvas[index-1]);
            }
           
        }
    }

    function erase(uint256 i) public pure returns(uint) {
        uint m1 = 0x5555555555555555555555555555555555555555555555555555555555555555;
        uint m2 = 0x3333333333333333333333333333333333333333333333333333333333333333;
        uint m4 = 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
        uint maxInt = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        uint dupi = i;
        uint c = 0;

        //if all the pixels are painted
        if(i == maxInt) {
            c = 256;
        } else {
            //calculate the amount of painted pixels
            i = (i & m1 ) + ((i >>  1) & m1 );
            i = (i & m2) + ((i >> 2) & m2);
            i = (i + (i >> 4)) & m4;
            i += i >>  8;
            i += i >> 16;
            i += i >> 32;
            i += i >> 64;
            i += i >> 128;
            c = i & 0xff;
        }

        //if there is only one painted pixel
        if (c == 1) {
            dupi = 0;
        } else {
            //erase half of the painted pixels from the least significant bit
            uint elen = c >> 1;
            for(uint j = 0; j < elen;) {
                unchecked{
                  dupi = dupi & (dupi-1);  
                  ++j;
                }
            }
        }

        return dupi;

    }


    function invert(uint256 i) public pure returns(uint) {
        //returns the inverted form of the pixelated image
        return ~i;
    }


    function excludeSelection(uint256 i, uint256 j) public pure returns(uint) {
        uint output = i ^ j;

        //if there is an overlap between to pixels, return the difference of the overlap
        if (output < i || output < j) {
            return output;
        }

        return 0;
    }

    function union(uint256 i, uint256 j) public pure returns(uint) {
        
        if(i == 0){
            invert(i);
        }

        if(j == 0){
            invert(j);
        }

        //returns the union of two pixels
        return (i | j);
    }
    


}