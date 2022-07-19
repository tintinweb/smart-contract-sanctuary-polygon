/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ILandToken {
    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external;

    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;
}


// File src/solc_0.8/common/interfaces/IPolygonLand.sol

interface IPolygonLand is ILandToken {
    function mintQuad(
        address user,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) external;

    function exists(
        uint256 size,
        uint256 x,
        uint256 y
    ) external view returns (bool);
}


// File src/solc_0.8/common/Libraries/TileLib.sol


/// @title An optimized bitset of 24x24 bits (used to represent maps)
/// @notice see: http://
/// @dev We store 8 lines of 24 bits in each uint256 and leave some free space.
library TileLib {
    uint256 public constant PIXEL_MASK = 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant PIXEL_MASK_INV = 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000;

    struct Tile {
        uint256[3] data;
    }

    /// @notice init the tile with the internal data directly
    /// @return A Tile that has the bit data set
    function init(
        Tile memory self,
        uint256 pixelData1,
        uint256 pixelData2,
        uint256 pixelData3
    ) internal pure returns (Tile memory) {
        self.data[0] = pixelData1 & PIXEL_MASK;
        self.data[1] = pixelData2 & PIXEL_MASK;
        self.data[2] = pixelData3 & PIXEL_MASK;
        return self;
    }

    /// @notice Set the bits inside a square that has size x size in the x,y coordinates
    /// @dev can be optimized for the specific case of a 24x24 square
    /// @param self the Tile in which the bits are set
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return self with the corresponding bits set
    function set(
        Tile memory self,
        uint256 x,
        uint256 y,
        uint256 size
    ) internal pure returns (Tile memory) {
        require(x < 24 && y < 24, "Invalid tile coordinates");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        uint256 mask = _quadMask(size);
        require(mask != 0, "invalid size");
        uint256 i;
        for (; i < size; i++) {
            uint256 idx = (y + i) / 8;
            self.data[idx] |= mask << (x + 24 * ((y + i) % 8));
        }
        return self;
    }

    /// @notice Clear the bits inside a square that has size x size in the x,y coordinates
    /// @dev can be optimized for the specific case of a 24x24 square
    /// @param self the Tile in which the bits will be cleared
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return self with the corresponding cleared bits
    function clear(
        Tile memory self,
        uint256 x,
        uint256 y,
        uint256 size
    ) internal pure returns (Tile memory) {
        require(x < 24 && y < 24, "Invalid tile coordinates");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        uint256 mask = _quadMask(size);
        require(mask != 0, "invalid size");
        uint256 i;
        for (; i < size; i++) {
            uint256 idx = (y + i) / 8;
            self.data[idx] &= ~(mask << (x + 24 * ((y + i) % 8)));
        }
        return self;
    }

    /// @notice Check if the bit in certain coordinate inside the Tile is set or not, if not set it.
    /// @dev this routine is a combination of contains and set, used to save some gas
    /// @param self the Tile where the check is done
    /// @param x the x coordinate
    /// @param y the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function addIfNotContain(
        Tile memory self,
        uint256 x,
        uint256 y
    ) internal pure returns (bool, Tile memory) {
        require(x < 24 && y < 24, "Invalid coordinates");
        uint256 idx = y / 8;
        uint256 bitMask = 1 << (x + 24 * (y % 8));
        if (self.data[idx] & bitMask == bitMask) {
            return (false, self);
        }
        self.data[idx] |= bitMask;
        return (true, self);
    }

    /// @notice Check if the bit in certain coordinate inside the Tile is set or not
    /// @param self the Tile where the check is done
    /// @param x the x coordinate
    /// @param y the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function contain(
        Tile memory self,
        uint256 x,
        uint256 y
    ) internal pure returns (bool) {
        require(x < 24 && y < 24, "Invalid coordinates");
        uint256 idx = y / 8;
        uint256 bitMask = 1 << (x + 24 * (y % 8));
        return (self.data[idx] & bitMask == bitMask);
    }

    /// @notice Check if the all the bits of a square inside the Tile are set or not
    /// @param self the Tile where the check is done
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if al the bits are set or false if at least one bit is cleared
    function contain(
        Tile memory self,
        uint256 x,
        uint256 y,
        uint256 size
    ) internal pure returns (bool) {
        require(x < 24 && y < 24, "Invalid tile coordinates");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        uint256 mask = _quadMask(size);
        require(mask != 0, "invalid size");
        uint256 i;
        for (; i < size; i++) {
            uint256 idx = (y + i) / 8;
            uint256 bitMask = mask << (x + 24 * ((y + i) % 8));
            if (self.data[idx] & bitMask != bitMask) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if a Tile includes all the bits that are set in another Tile
    /// @param self the bigger Tile that is checked for inclusion
    /// @param contained the Tile that must be included
    /// @return true if self contain contained Tile
    function contain(Tile memory self, Tile memory contained) internal pure returns (bool) {
        uint256 d0 = contained.data[0] & PIXEL_MASK;
        uint256 d1 = contained.data[1] & PIXEL_MASK;
        uint256 d2 = contained.data[2] & PIXEL_MASK;
        return (self.data[0] & d0 == d0) && (self.data[1] & d1 == d1) && (self.data[2] & d2 == d2);
    }

    /// @notice Check if the Tile has any bit in common with a square
    /// @param self the Tile where the check is done
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if there is at least one bit set in both Tiles
    function intersect(
        Tile memory self,
        uint256 x,
        uint256 y,
        uint256 size
    ) internal pure returns (bool) {
        require(x < 24 && y < 24, "Invalid tile coordinates");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        uint256 mask = _quadMask(size);
        require(mask != 0, "invalid size");
        uint256 i;
        for (; i < size; i++) {
            uint256 idx = (y + i) / 8;
            uint256 bitMask = mask << (x + 24 * ((y + i) % 8));
            if (self.data[idx] & bitMask != 0) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if two Tiles has any bit in common
    /// @param self first Tile to compare
    /// @param other second tile to compare
    /// @return true if there is at least one bit set in both Tiles
    function intersect(Tile memory self, Tile memory other) internal pure returns (bool) {
        return
            ((self.data[0] & other.data[0]) | (self.data[1] & other.data[1]) | (self.data[2] & other.data[2])) &
                PIXEL_MASK !=
            0;
    }

    /// @notice Check if two Tiles has exactly the same bits set
    /// @param self first Tile to compare
    /// @param other second Tile to compare
    /// @return true if the two Tiles has the same bits set
    function isEqual(Tile memory self, Tile memory other) internal pure returns (bool) {
        return
            ((self.data[0] ^ other.data[0]) | (self.data[1] ^ other.data[1]) | (self.data[2] ^ other.data[2])) &
                PIXEL_MASK ==
            0;
    }

    /// @notice return a Tile that is the union of two Tiles
    /// @dev this function destroys data outside the pixel data (we want to save some gas)
    /// @param self first Tile to compare
    /// @param other second Tile to compare
    /// @return a Tile that is the union of self and other
    function or(Tile memory self, Tile memory other) internal pure returns (Tile memory) {
        self.data[0] |= other.data[0] & PIXEL_MASK;
        self.data[1] |= other.data[1] & PIXEL_MASK;
        self.data[2] |= other.data[2] & PIXEL_MASK;
        return self;
    }

    /// @notice return a Tile that is the intersection of two Tiles
    /// @dev this function destroys data outside the pixel data (we want to save some gas)
    /// @param self first Tile to compare
    /// @param other second Tile to compare
    /// @return a Tile that is the intersection of self and other
    function and(Tile memory self, Tile memory other) internal pure returns (Tile memory) {
        self.data[0] &= other.data[0] | PIXEL_MASK_INV;
        self.data[1] &= other.data[1] | PIXEL_MASK_INV;
        self.data[2] &= other.data[2] | PIXEL_MASK_INV;
        return self;
    }

    /// @notice Calculates the subtraction of two Tile
    /// @param self the Tile to subtract from
    /// @param value the Tile subtracted
    /// @return the self with all the bits set in value cleared
    function subtract(Tile memory self, Tile memory value) internal pure returns (Tile memory) {
        self.data[0] &= ~(value.data[0] & PIXEL_MASK);
        self.data[1] &= ~(value.data[1] & PIXEL_MASK);
        self.data[2] &= ~(value.data[2] & PIXEL_MASK);
        return self;
    }

    /// @notice check if a Tile is empty, doesn't have any bit set
    /// @param self first Tile to compare
    /// @return true if the Tile is empty
    function isEmpty(Tile memory self) internal pure returns (bool) {
        return (self.data[0] | self.data[1] | self.data[2]) & PIXEL_MASK == 0;
    }

    /// @notice return a Tile that has only one of the pixels from the original Tile set
    /// @param self Tile in which one pixel is searched
    /// @return ret a Tile that has only one pixel set
    function findAPixel(Tile memory self) internal pure returns (Tile memory ret) {
        uint256 target;
        uint256 shift;

        target = self.data[2] & PIXEL_MASK;
        if (target != 0) {
            shift = _findAPixel(target);
            ret.data[2] = (1 << shift);
            return ret;
        }

        target = self.data[1] & PIXEL_MASK;
        if (target != 0) {
            shift = _findAPixel(target);
            ret.data[1] = (1 << shift);
            return ret;
        }

        target = self.data[0] & PIXEL_MASK;
        if (target != 0) {
            shift = _findAPixel(target);
            ret.data[0] = (1 << shift);
        }
        return ret;
    }

    /// @notice given a tile, translate all the bits in the x and y direction
    /// @param self the initial Tile to translate
    /// @param x the x distance to translate
    /// @param y the y distance to translate
    /// @return col1 first column that represents the four tiles that are the result of the translation
    /// @return col2 second column that represents the four tiles that are the result of the translation
    function translate(
        Tile memory self,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256[6] memory col1, uint256[6] memory col2) {
        // Move right
        uint256 mask = _getTranslateXMask(x);
        col1[0] = (self.data[0] & mask) << x;
        col1[1] = (self.data[1] & mask) << x;
        col1[2] = (self.data[2] & mask) << x;
        if (x > 0) {
            mask = PIXEL_MASK - mask;
            col2[0] = (self.data[0] & mask) >> (24 - x);
            col2[1] = (self.data[1] & mask) >> (24 - x);
            col2[2] = (self.data[2] & mask) >> (24 - x);
        }
        // Move down
        uint256 rem = 24 * (y % 8);
        uint256 div = y / 8;
        mask = PIXEL_MASK - (2**(24 * 8 - rem) - 1);
        // TODO: optimization, remove the loop, check gas consumption
        for (uint256 i = 5; i > div; i--) {
            col1[i] = (col1[i - div] << rem) | ((col1[i - div - 1] & mask) >> (24 * 8 - rem));
            col2[i] = (col2[i - div] << rem) | ((col2[i - div - 1] & mask) >> (24 * 8 - rem));
        }
        col1[div] = col1[0] << rem;
        col2[div] = col2[0] << rem;
        if (div > 0) {
            col1[0] = 0;
            col2[0] = 0;
            if (div > 1) {
                col1[1] = 0;
                col2[1] = 0;
            }
        }
        return (col1, col2);
    }

    uint256 private constant QUAD_MASK_1 = 1;
    uint256 private constant QUAD_MASK_3 = 2**3 - 1;
    uint256 private constant QUAD_MASK_6 = 2**6 - 1;
    uint256 private constant QUAD_MASK_12 = 2**12 - 1;
    uint256 private constant QUAD_MASK_24 = 2**24 - 1;

    /// @notice return a bit mask used to set or clear a square of certain size in the Tile
    /// @param size the size of the square
    /// @return the bit mask or zero if the size is not supported
    function _quadMask(uint256 size) private pure returns (uint256) {
        if (size == 1) return 1;
        if (size == 3) return QUAD_MASK_3;
        if (size == 6) return QUAD_MASK_6;
        if (size == 12) return QUAD_MASK_12;
        if (size == 24) return QUAD_MASK_24;
        return 0;
    }

    /// @notice count the amount of bits set inside the Tile
    /// @param self the Tile in which the bits are counted
    /// @return the count of bits that are set
    function countBits(Tile memory self) internal pure returns (uint256) {
        return _countBits(self.data[0]) + _countBits(self.data[1]) + _countBits(self.data[2]);
    }

    /// @notice count the amount of bits set inside a word
    /// @dev see: https://stackoverflow.com/questions/109023/how-to-count-the-number-of-set-bits-in-a-32-bit-integer
    /// @param x the word in which the bits are counted
    /// @return the count of bits that are set
    function _countBits(uint256 x) private pure returns (uint256) {
        x = x - ((x >> 1) & 0x0000000000000000555555555555555555555555555555555555555555555555);
        x =
            (x & 0x0000000000000000333333333333333333333333333333333333333333333333) +
            ((x >> 2) & 0x0000000000000000333333333333333333333333333333333333333333333333);
        x = (x + (x >> 4)) & 0x00000000000000000F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
        return
            ((((x >> 96) * 0x010101010101010101010101) +
                ((x & 0x0F0F0F0F0F0F0F0F0F0F0F0F) * 0x010101010101010101010101)) >> (11 * 8)) & 0xFF;
    }

    /// @notice giving 8 lines of a Tile, find any bit that is set
    /// @dev we must search in 8 * 24 bits that correspond to 8 lines, so 2^6 * 3, we split in three and then do a binary search
    /// @param target the uint256 that has the 8 lines
    /// @return shift the amount of bits shift left so the choose bit is set in the resulting Tile
    function _findAPixel(uint256 target) private pure returns (uint256 shift) {
        uint256 mask = (2**64 - 1);
        // divide in 3 parts, then do a binary search
        if ((target & mask) == 0) {
            target = target >> 64;
            shift = 64;
            if ((target & mask) == 0) {
                target = target >> 64;
                shift = 128;
            }
        }
        for (uint256 i = 32; i > 0; i = i / 2) {
            mask = mask >> i;
            if ((target & mask) == 0) {
                target = target >> i;
                shift += i;
            }
        }
        return shift;
    }

    /// @notice return a bit mask used translate a Tile data in the x direction
    /// @param x the x value to translate
    /// @return the bit mask
    function _getTranslateXMask(uint256 x) private pure returns (uint256) {
        uint256 mask = (2**24 - 1) >> x;
        mask |= mask << 24;
        mask |= mask << (24 * 2);
        mask |= mask << (24 * 4);
        return mask;
    }
}


// File src/solc_0.8/common/Libraries/TileWithCoordLib.sol


/// @title A Tile (24x24 map piece) that also stores x,y coordinates and a combination of the two called key
/// @dev Using a sparse array of TileWithCoords we build a bigger map covered with Tiles
library TileWithCoordLib {
    using TileLib for TileLib.Tile;

    struct TileWithCoord {
        TileLib.Tile tile;
    }

    /// @notice initialize the TileWithCoord structure
    /// @return An empty Tile that has the x,y and corresponding key value set
    function init(uint256 x, uint256 y) internal pure returns (TileWithCoord memory) {
        TileWithCoord memory ret;
        ret.tile.data[0] = (getKey(x, y)) << 224;
        ret.tile.data[1] = (x / 24) << 224;
        ret.tile.data[2] = (y / 24) << 224;
        return ret;
    }

    /// @notice initialize the TileWithCoord structure
    /// @return An TileWithCoord that has the x,y, key and the Tile bit data set
    function init(
        uint256 x,
        uint256 y,
        uint256 pixelData1,
        uint256 pixelData2,
        uint256 pixelData3
    ) internal pure returns (TileWithCoord memory) {
        TileWithCoord memory ret;
        ret.tile = ret.tile.init(pixelData1, pixelData2, pixelData3);
        ret.tile.data[0] |= (getKey(x, y)) << 224;
        ret.tile.data[1] |= (x / 24) << 224;
        ret.tile.data[2] |= (y / 24) << 224;
        return ret;
    }

    /// @notice Set the bits inside a square that has size x size in the x,y coordinates
    /// @param self the TileWithCoord in which the bits are set
    /// @param xi the x coordinate of the square
    /// @param yi the y coordinate of the square
    /// @param size the size of the square
    /// @return self with the corresponding bits set
    function set(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi,
        uint256 size
    ) internal pure returns (TileWithCoord memory) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid tile coordinates");
        self.tile = self.tile.set(xi % 24, yi % 24, size);
        return self;
    }

    /// @notice Calculates the union/addition of two TileWithCoord
    /// @dev to be able to merge the two TileWithCoord must have the same coordinates
    /// @param self one of the TileWithCoord to merge
    /// @param value the second TileWithCoord to merge
    /// @return the merge of the two TileWithCoord
    function merge(TileWithCoord memory self, TileWithCoord memory value) internal pure returns (TileWithCoord memory) {
        require(getX(self) == getX(value) && getY(self) == getY(value), "Invalid tile coordinates");
        self.tile = self.tile.or(value.tile);
        return self;
    }

    /// @notice Clear the bits inside a square that has size x size in the x,y coordinates
    /// @param self the TileWithCoord, in which the bits will be cleared
    /// @param xi the x coordinate of the square
    /// @param yi the y coordinate of the square
    /// @param size the size of the square
    /// @return self with the corresponding cleared bits
    function clear(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi,
        uint256 size
    ) internal pure returns (TileWithCoord memory) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid tile coordinates");
        self.tile = self.tile.clear(xi % 24, yi % 24, size);
        return self;
    }

    /// @notice Calculates the subtraction of two TileWithCoord
    /// @dev to be able to subtract them the two TileWithCoord must have the same coordinates
    /// @param self the TileWithCoord to subtract from
    /// @param value the TileWithCoord subtracted
    /// @return the self with all the bits set in value cleared
    function clear(TileWithCoord memory self, TileWithCoord memory value) internal pure returns (TileWithCoord memory) {
        require(getX(self) == getX(value) && getY(self) == getY(value), "Invalid tile coordinates");
        self.tile = self.tile.subtract(value.tile);
        return self;
    }

    /// @notice Check if the bit in certain coordinate are set or not in the TileWithCoord
    /// @param self the TileWithCoord where the check is done
    /// @param xi the x coordinate
    /// @param yi the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function contain(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi
    ) internal pure returns (bool) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid coordinates");
        return self.tile.contain(xi % 24, yi % 24);
    }

    /// @notice Check if the all the bits of a square inside the TileWithCoord are set or not
    /// @param self the TileWithCoord where the check is done
    /// @param xi the x coordinate of the square
    /// @param yi the y coordinate of the square
    /// @param size the size of the square
    /// @return true if al the bits are set or false if at least one bit is cleared
    function contain(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi,
        uint256 size
    ) internal pure returns (bool) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid tile coordinates");
        return self.tile.contain(xi % 24, yi % 24, size);
    }

    /// @notice Check if the TileWithCoord has any bit in common with a square
    /// @param self the TileWithCoord where the check is done
    /// @param xi the x coordinate of the square
    /// @param yi the y coordinate of the square
    /// @param size the size of the square
    /// @return true if there is at least one bit set in the TileWithCoords and the square
    function intersect(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi,
        uint256 size
    ) internal pure returns (bool) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid tile coordinates");
        return self.tile.intersect(xi % 24, yi % 24, size);
    }

    /// @notice return the key value stored in the TileWithCoord
    /// @param self the TileWithCoord to get the key from
    /// @return the key value
    function getKey(TileWithCoord memory self) internal pure returns (uint256) {
        return self.tile.data[0] >> 224;
    }

    /// @notice return the x coordinate value stored in the TileWithCoord
    /// @param self the TileWithCoord to get the x coordinate from
    /// @return the x value
    function getX(TileWithCoord memory self) internal pure returns (uint256) {
        return self.tile.data[1] >> 224;
    }

    /// @notice return the y coordinate value stored in the TileWithCoord
    /// @param self the TileWithCoord to get the y coordinate from
    /// @return the y value
    function getY(TileWithCoord memory self) internal pure returns (uint256) {
        return self.tile.data[2] >> 224;
    }

    /// @notice helper to calculate the key value given the x,y coordinates
    /// @param x the x coordinate
    /// @param y the y coordinate
    /// @return the key value
    function getKey(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x / 24) | ((y / 24) << 16);
    }

    /// @notice count the amount of bits set inside the TileWithCoord
    /// @param self the TileWithCoord in which the bits are counted
    /// @return the count of bits that are set
    function countBits(TileWithCoord memory self) internal pure returns (uint256) {
        return self.tile.countBits();
    }

    /// @notice check if a TileWithCoord is empty, none of the bits are set
    /// @param self the TileWithCoord to check
    /// @return true if none of the bits are set
    function isEmpty(TileWithCoord memory self) internal pure returns (bool) {
        return self.tile.isEmpty();
    }

    /// @notice Check if two TileWithCoord has exactly the same coordinates and bits set
    /// @param self first TileWithCoord to compare
    /// @param other second TileWithCoord to compare
    /// @return true if the two TileWithCoord has the same coordinates and bits set
    function isEqual(TileWithCoord memory self, TileWithCoord memory other) internal pure returns (bool) {
        return
            self.tile.data[0] == other.tile.data[0] &&
            self.tile.data[1] == other.tile.data[1] &&
            self.tile.data[2] == other.tile.data[2];
    }
}


// File src/solc_0.8/common/interfaces/IEstateExperienceRegistry.sol


interface IEstateExperienceRegistry {
    function link(
        uint256 estateId, // estateId == 0 => single land experience
        uint256 expId,
        uint256 x,
        uint256 y
    ) external;

    function unLink(uint256 expId) external;

    // Called only by the estate contract
    function batchUnLinkFrom(address from, uint256[] calldata expIdsToUnlink) external;

    function isLinked(uint256 expId) external view returns (bool);

    function isLinked(uint256[][3] calldata quads) external view returns (bool);

    function isLinked(TileWithCoordLib.TileWithCoord[] calldata) external view returns (bool);
}


// File src/solc_0.8/common/Libraries/MapLib.sol

pragma solidity 0.8.2;


/// @title An iterable mapping of Tiles (24x24 bit set).
/// @notice Used to represent a the presence or absence of certain x,y coordinate in a map of lands
/// @dev The key of the mapping is a combination of x and y.
/// @dev This library try to reduce the gas consumption and to do that it accesses the internal structure of the Tiles
library MapLib {
    using TileWithCoordLib for TileWithCoordLib.TileWithCoord;
    using TileLib for TileLib.Tile;

    uint256 private constant LEFT_MASK = 0x000001000001000001000001000001000001000001000001;
    uint256 private constant LEFT_MASK_NEG = ~LEFT_MASK;
    uint256 private constant RIGHT_MASK = 0x800000800000800000800000800000800000800000800000;
    uint256 private constant RIGHT_MASK_NEG = ~RIGHT_MASK;
    uint256 private constant UP_MASK = 0x000000000000000000000000000000000000000000FFFFFF;
    uint256 private constant DOWN_MASK = 0xFFFFFF000000000000000000000000000000000000000000;

    struct TranslateResult {
        TileWithCoordLib.TileWithCoord topLeft;
        TileWithCoordLib.TileWithCoord topRight;
        TileWithCoordLib.TileWithCoord bottomLeft;
        TileWithCoordLib.TileWithCoord bottomRight;
    }

    // An iterable mapping of tiles (24x24 bit set).
    struct Map {
        TileWithCoordLib.TileWithCoord[] values;
        // Position of the value in the `values` array, plus 1 because index 0 means that the key is not found.
        mapping(uint256 => uint256) indexes;
    }

    /// @notice Set the bits inside a square that has size x size in the x,y coordinates in the map
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the Map in which the bits are set
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    function set(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            // Add a new tile
            TileWithCoordLib.TileWithCoord memory t = TileWithCoordLib.init(x, y);
            self.values.push(t.set(x, y, size));
            self.indexes[key] = self.values.length;
        } else {
            // contains
            self.values[idx - 1] = self.values[idx - 1].set(x, y, size);
        }
    }

    /// @notice Given a translation of a tile the corresponding bits are set in the current map
    /// @param self the Map in which the bits are set
    /// @param s translation result, the result of a translation of a tile are four tiles.
    function set(Map storage self, TranslateResult memory s) public {
        set(self, s.topLeft);
        set(self, s.topRight);
        set(self, s.bottomLeft);
        set(self, s.bottomRight);
    }

    /// @notice Given a TileWithCoord (a tile that includes coordinates inside it) set the corresponding bits in the map
    /// @param self the Map in which the bits are set
    /// @param tile the tile that is used to set the bits inside the map
    function set(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public {
        if (tile.isEmpty()) {
            return;
        }
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            // Add a new tile
            self.values.push(tile);
            self.indexes[key] = self.values.length;
        } else {
            self.values[idx - 1] = self.values[idx - 1].merge(tile);
        }
    }

    /// @notice Merge the bits of a list of TileWithCoord in the current one
    /// @param self the Map in which the bits are set
    /// @param tiles the list of TileWithCoord
    function set(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            set(self, tiles[i]);
        }
    }

    /// @notice Merge the bits of another map in the current one
    /// @param self the Map in which the bits are set
    /// @param other the map that is used as source to set the bits in the current one
    function set(Map storage self, Map storage other) public {
        uint256 len = other.values.length;
        for (uint256 i; i < len; i++) {
            set(self, other.values[i]);
        }
    }

    /// @notice Clear the bits inside a square that has size x size in the x,y coordinates in the map
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the Map, in which the bits will be cleared
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return false if the the coordinates are not found so the bits are already cleared
    function clear(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public returns (bool) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains, nothing to clear
            return false;
        }
        TileWithCoordLib.TileWithCoord memory t = self.values[idx - 1].clear(x, y, size);
        if (t.isEmpty()) {
            _remove(self, idx, key);
        } else {
            self.values[idx - 1] = t;
        }
        return true;
    }

    /// @notice Given a TileWithCoord (a tile that includes coordinates inside it) clear the corresponding bits in the map
    /// @param self the Map, in which the bits will be cleared
    /// @param tile the tile that is used to clear the bits inside the map
    /// @return false if the the coordinates are not found so the bits are already cleared
    function clear(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public returns (bool) {
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        TileWithCoordLib.TileWithCoord memory t = self.values[idx - 1].clear(tile);
        if (t.isEmpty()) {
            _remove(self, idx, key);
        } else {
            self.values[idx - 1] = t;
        }
        return true;
    }

    /// @notice Clear the bits of a list of TileWithCoord
    /// @param self the Map in which the bits are cleared
    /// @param tiles the list of TileWithCoord
    function clear(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            clear(self, tiles[i]);
        }
    }

    /// @notice Clear the bits of another map in the current one
    /// @param self the Map in which the bits are cleared
    /// @param other the map that is used as source to clear the bits in the current one
    function clear(Map storage self, Map storage other) public {
        uint256 len = other.values.length;
        for (uint256 i; i < len; i++) {
            clear(self, other.values[i]);
        }
    }

    /// @notice Clear the all the bits in the map
    /// @param self the Map in which the bits are cleared
    function clear(Map storage self) public {
        for (uint256 i; i < self.values.length; i++) {
            delete self.indexes[self.values[i].getKey()];
        }
        delete self.values;
    }

    /// @notice given a tile, translate all the bits in the x and y direction
    /// @dev the result of the translation are four tiles
    /// @param deltaX the x distance to translate
    /// @param deltaY the y distance to translate
    /// @return four tiles with coords that are the result of the translation
    function translate(
        TileLib.Tile memory tile,
        uint256 deltaX,
        uint256 deltaY
    ) internal pure returns (TranslateResult memory) {
        (uint256[6] memory col1, uint256[6] memory col2) = tile.translate(deltaX % 24, deltaY % 24);
        return
            TranslateResult({
                topLeft: TileWithCoordLib.init(deltaX, deltaY, col1[0], col1[1], col1[2]),
                bottomLeft: TileWithCoordLib.init(deltaX, deltaY + 24, col1[3], col1[4], col1[5]),
                topRight: TileWithCoordLib.init(deltaX + 24, deltaY, col2[0], col2[1], col2[2]),
                bottomRight: TileWithCoordLib.init(deltaX + 24, deltaY + 24, col2[3], col2[4], col2[5])
            });
    }

    /// @notice Check if the bit in certain coordinate are set or not inside the map
    /// @param self the Map where the check is done
    /// @param x the x coordinate
    /// @param y the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function contain(
        Map storage self,
        uint256 x,
        uint256 y
    ) public view returns (bool) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        return self.values[idx - 1].contain(x, y);
    }

    /// @notice Check if the all the bits of a square inside the Map are set or not
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the Map where the check is done
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if al the bits are set or false if at least one bit is cleared
    function contain(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public view returns (bool) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        return self.values[idx - 1].contain(x, y, size);
    }

    /// @notice Check if a Map includes all the bits that are set in a TileWithCoord
    /// @param self the Map that is checked for inclusion
    /// @param tile the TileWithCoord that must be included
    /// @return true if self contain tile TileWithCoord
    function contain(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public view returns (bool) {
        if (tile.isEmpty()) {
            return true;
        }
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        return self.values[idx - 1].tile.contain(tile.tile);
    }

    /// @notice Check if a Map includes all the bits that are set in a TileWithCoord[]
    /// @param self the Map that is checked for inclusion
    /// @param tiles the TileWithCoord that must be included
    /// @return true if self contain tiles TileWithCoord[]
    function contain(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public view returns (bool) {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            if (!contain(self, tiles[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if a Map includes all the bits that are set in translation result
    /// @dev this routine is used to match an experience template after translation
    /// @param self the bigger Tile that is checked for inclusion
    /// @param s the translation result that must be included
    /// @return true if self contain all the bits in the translation result
    function contain(Map storage self, TranslateResult memory s) public view returns (bool) {
        return
            contain(self, s.topLeft) &&
            contain(self, s.topRight) &&
            contain(self, s.bottomLeft) &&
            contain(self, s.bottomRight);
    }

    /// @notice Check if a Map includes all the bits that are set in another Map
    /// @dev self can be huge, but other must be small, we iterate over other values.
    /// @param self the Map that is checked for inclusion
    /// @param other the Map that must be included
    /// @return true if self contain other Map
    function contain(Map storage self, Map storage other) public view returns (bool) {
        uint256 len = other.values.length;
        for (uint256 i; i < len; i++) {
            if (!contain(self, other.values[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if a map has at least one bit in common with a square (x,y,size)
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the Map where the check is done
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if there is at least one bit set in both the Map and the square
    function intersect(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public view returns (bool) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !intersect
            return false;
        }
        return self.values[idx - 1].intersect(x, y, size);
    }

    /// @notice Check if a map has at least one bit in common with some TileWithCoord
    /// @param self the Map to compare
    /// @param tile the TileWithCoord to compare
    /// @return true if there is at least one bit set in both the Map and the TileWithCoord
    function intersect(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public view returns (bool) {
        if (tile.isEmpty()) {
            return false;
        }
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        return self.values[idx - 1].tile.intersect(tile.tile);
    }

    /// @notice Check if a Map has at least one of the bits that are set in a TileWithCoord[]
    /// @param self the Map that is checked for inclusion
    /// @param tiles the TileWithCoord that must be included
    /// @return true if there is at least one bit set in both the Map and the TileWithCoord[]
    function intersect(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public view returns (bool) {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            if (intersect(self, tiles[i])) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if a map has at least one bit in common with some translation result
    /// @param self the Map to compare
    /// @param s the four tiles that are the result of a translation
    /// @return true if there is at least one bit set in both the Map and the TranslationResult
    function intersect(Map storage self, TranslateResult memory s) public view returns (bool) {
        return
            intersect(self, s.topLeft) ||
            intersect(self, s.topRight) ||
            intersect(self, s.bottomLeft) ||
            intersect(self, s.bottomRight);
    }

    /// @notice Check if a Map includes any of the bits that are set in another Map
    /// @dev self can be huge, but other must be small, we iterate over other values.
    /// @param self the Map that is checked for inclusion
    /// @param other the Map that must be included
    /// @return true if there is at least one bit set in both Maps
    function intersect(Map storage self, Map storage other) public view returns (bool) {
        uint256 len = other.values.length;
        for (uint256 i; i < len; i++) {
            if (intersect(self, other.values[i])) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if a map is empty (no bits are set)
    /// @param self the Map to check
    /// @return true if the map is empty
    function isEmpty(Map storage self) public view returns (bool) {
        // We remove the tiles when they are empty
        return self.values.length == 0;
    }

    /// @notice Check if two maps are equal
    /// @param self the first Map to check
    /// @param other the second Map to check
    /// @return true if the two maps are equal
    function isEqual(Map storage self, Map storage other) public view returns (bool) {
        return isEqual(self, other.values);
    }

    /// @notice Check if a map is equal to an array of TileWithCoord
    /// @param self the Map to check
    /// @param other the list of TileWithCoord to check
    /// @return true if the two are equal
    function isEqual(Map storage self, TileWithCoordLib.TileWithCoord[] memory other) public view returns (bool) {
        if (other.length != self.values.length) {
            return false;
        }
        uint256 cant = other.length;
        // Check that self contains the same set of tiles than other and they are equal
        for (uint256 i; i < cant; i++) {
            uint256 key = other[i].getKey();
            uint256 idx = self.indexes[key];
            if (idx == 0 || !self.values[idx - 1].isEqual(other[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice return the length of the internal list of tiles
    /// @dev used to iterate off-chain over the tiles.
    /// @param self the Map
    /// @return the length of the list
    function length(Map storage self) public view returns (uint256) {
        return self.values.length;
    }

    /// @notice get the tile that is in certain position in the internal list of tiles
    /// @dev used to iterate off-chain over the tiles.
    /// @param self the Map
    /// @param index the index of the tile
    /// @return the tile that is in the position index in the list
    function at(Map storage self, uint256 index) public view returns (TileWithCoordLib.TileWithCoord memory) {
        return self.values[index];
    }

    /// @notice get the internal list of tiles with pagination
    /// @dev used to iterate off-chain over the tiles.
    /// @param self the Map
    /// @param offset initial offset used to paginate
    /// @param limit amount of tiles to get
    /// @return the partial list of tiles
    function at(
        Map storage self,
        uint256 offset,
        uint256 limit
    ) public view returns (TileWithCoordLib.TileWithCoord[] memory) {
        TileWithCoordLib.TileWithCoord[] memory ret = new TileWithCoordLib.TileWithCoord[](limit);
        for (uint256 i; i < limit; i++) {
            ret[i] = self.values[offset + i];
        }
        return ret;
    }

    /// @notice return the internal list of tiles
    /// @dev Use only for testing. This can be problematic if it grows too much !!!
    /// @param self the map
    /// @return the list of internal tiles
    function getMap(Map storage self) public view returns (TileWithCoordLib.TileWithCoord[] memory) {
        return self.values;
    }

    /// @notice count the amount of bits (lands) set inside a Map
    /// @param self the map
    /// @return the quantity of lands
    function getLandCount(Map storage self) public view returns (uint256) {
        uint256 ret;
        uint256 len = self.values.length;
        for (uint256 i; i < len; i++) {
            ret += self.values[i].countBits();
        }
        return ret;
    }

    /// @notice check if a square is adjacent (4-connected component) to the current map.
    /// @dev used to add a quad to a map, it is cheaper than isAdjacent(map)
    /// @param self the map
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if the square is 4-connected to the map
    function isAdjacent(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public view returns (bool) {
        if (isEmpty(self)) {
            return true;
        }

        uint256 idx;
        TileLib.Tile memory spot;
        spot = spot.set(x % 24, y % 24, size);
        // left
        if (x >= 24) {
            idx = _getIdx(self, x - 24, y);
            if (idx != 0 && !self.values[idx - 1].tile.and(_growLeft(spot)).isEmpty()) {
                return true;
            }
        }
        // up
        if (y >= 24) {
            idx = _getIdx(self, x, y - 24);
            if (idx != 0 && (self.values[idx - 1].tile.data[0] & ((spot.data[0] & UP_MASK) << (24 * 7))) != 0) {
                return true;
            }
        }
        // middle
        idx = _getIdx(self, x, y);
        if (idx != 0 && !self.values[idx - 1].tile.and(_growMiddle(spot)).isEmpty()) {
            return true;
        }
        // down
        idx = _getIdx(self, x, y + 24);
        if (idx != 0 && (self.values[idx - 1].tile.data[2] & ((spot.data[2] & DOWN_MASK) >> (24 * 7))) != 0) {
            return true;
        }
        // right
        idx = _getIdx(self, x + 24, y);
        if (idx != 0 && !self.values[idx - 1].tile.and(_growRight(spot)).isEmpty()) {
            return true;
        }
        return false;
    }

    /// @notice check that the map has only one 4-connected component, aka everything is adjacent
    /// @dev Checks the full map to see if all the pixels are adjacent
    /// @param self the map
    /// @return ret true if all the bits (lands) are adjacent
    function isAdjacent(Map storage self) public view returns (bool ret) {
        if (isEmpty(self)) {
            // everything is adjacent to an empty map
            return true;
        }

        TileLib.Tile[] memory spot = new TileLib.Tile[](self.values.length);
        // We assume that all self.values[] are non empty (we remove them if they are empty).
        spot[0] = self.values[0].tile.findAPixel();
        bool done;
        while (!done) {
            (spot, done) = floodStep(self, spot);
        }
        uint256 len = self.values.length;
        uint256 i;
        for (; i < len; i++) {
            // Check the tile ignoring coordinates
            if (!self.values[i].tile.isEqual(spot[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice used to check adjacency. See: https://en.wikipedia.org/wiki/Flood_fill and isAdjacent.
    /// @param self the map
    /// @param current the current image
    /// @return next return the image with the extra pixels that correspond to the flooding process
    /// @return done true if the current image is the same as the next one so the algorithm is ready to stop flooding.
    function floodStep(Map storage self, TileLib.Tile[] memory current)
        public
        view
        returns (TileLib.Tile[] memory next, bool done)
    {
        uint256 len = self.values.length;
        uint256 i;
        uint256 x;
        uint256 y;
        uint256 idx;
        TileLib.Tile memory ci;
        next = new TileLib.Tile[](len);
        // grow
        for (i; i < len; i++) {
            ci = current[i];
            // isEmpty
            if ((ci.data[0] | ci.data[1] | ci.data[2]) == 0) {
                continue;
            }
            x = self.values[i].getX() * 24;
            y = self.values[i].getY() * 24;

            // middle, always included
            next[i].data[0] |= _grow(ci.data[0]) | ((ci.data[1] & UP_MASK) << (24 * 7));
            next[i].data[1] |=
                _grow(ci.data[1]) |
                ((ci.data[2] & UP_MASK) << (24 * 7)) |
                ((ci.data[0] & DOWN_MASK) >> (24 * 7));
            next[i].data[2] |= _grow(ci.data[2]) | ((ci.data[1] & DOWN_MASK) >> (24 * 7));
            // left
            if (x >= 24) {
                idx = _getIdx(self, x - 24, y);
                if (idx != 0) {
                    next[idx - 1].data[0] |= (ci.data[0] & LEFT_MASK) << 23;
                    next[idx - 1].data[1] |= (ci.data[1] & LEFT_MASK) << 23;
                    next[idx - 1].data[2] |= (ci.data[2] & LEFT_MASK) << 23;
                }
            }
            // up
            if (y >= 24) {
                idx = _getIdx(self, x, y - 24);
                if (idx != 0) {
                    next[idx - 1].data[2] |= (ci.data[0] & UP_MASK) << (24 * 7);
                }
            }
            // down
            idx = _getIdx(self, x, y + 24);
            if (idx != 0) {
                next[idx - 1].data[0] |= (ci.data[2] & DOWN_MASK) >> (24 * 7);
            }
            // right
            idx = _getIdx(self, x + 24, y);
            if (idx != 0) {
                next[idx - 1].data[0] |= (ci.data[0] & RIGHT_MASK) >> 23;
                next[idx - 1].data[1] |= (ci.data[1] & RIGHT_MASK) >> 23;
                next[idx - 1].data[2] |= (ci.data[2] & RIGHT_MASK) >> 23;
            }
        }
        // Mask it.
        done = true;
        for (i = 0; i < len; i++) {
            // next[i] = next[i].and(self.values[i].tile);
            // done = done && next[i].isEqual(current[i]);
            next[i].data[0] &= self.values[i].tile.data[0];
            next[i].data[1] &= self.values[i].tile.data[1];
            next[i].data[2] &= self.values[i].tile.data[2];
            done =
                done &&
                next[i].data[0] == current[i].data[0] &&
                next[i].data[1] == current[i].data[1] &&
                next[i].data[2] == current[i].data[2];
        }
        return (next, done);
    }

    /// @notice delete certain tile from the map
    /// @param self the Map where the tile is removed
    /// @param idx the index of the tile in the internal list
    /// @param key the key of the tile (combination of x,y)
    function _remove(
        Map storage self,
        uint256 idx,
        uint256 key
    ) private {
        uint256 toDeleteIndex = idx - 1;
        uint256 lastIndex = self.values.length - 1;
        if (lastIndex != toDeleteIndex) {
            TileWithCoordLib.TileWithCoord memory lastValue = self.values[lastIndex];
            self.values[toDeleteIndex] = lastValue;
            self.indexes[lastValue.getKey()] = idx;
        }
        self.values.pop();
        delete self.indexes[key];
    }

    /// @notice given x and y return the index of the tile inside the internal list of tiles
    /// @param self the Map where the tile is removed
    /// @param x the x coordinate
    /// @param y the y coordinate
    /// @return the index in the list + 1 or zero if not found
    function _getIdx(
        Map storage self,
        uint256 x,
        uint256 y
    ) private view returns (uint256) {
        return self.indexes[TileWithCoordLib.getKey(x, y)];
    }

    /// @notice grow (4-connected) the internal word that represent 8 lines of the tile adding pixels
    /// @param x the value of the internal work
    /// @return the internal work with the extra pixels from growing it
    function _grow(uint256 x) private pure returns (uint256) {
        return (x | ((x & RIGHT_MASK_NEG) << 1) | ((x & LEFT_MASK_NEG) >> 1) | (x << 24) | (x >> 24));
    }

    /// @notice grow (4-connected) a tile adding pixels around those that exists
    /// @param self the tile to grow
    /// @return e the tile that results from adding all the 4-connected pixels
    function _growMiddle(TileLib.Tile memory self) internal pure returns (TileLib.Tile memory e) {
        e.data[0] = _grow(self.data[0]) | ((self.data[1] & UP_MASK) << (24 * 7));
        e.data[1] =
            _grow(self.data[1]) |
            ((self.data[2] & UP_MASK) << (24 * 7)) |
            ((self.data[0] & DOWN_MASK) >> (24 * 7));
        e.data[2] = _grow(self.data[2]) | ((self.data[1] & DOWN_MASK) >> (24 * 7));
        return e;
    }

    /// @notice grow (4-connected) a tile adding pixels around those that exists
    /// @param self the tile to grow
    /// @return e the extra tile to the right that results from adding all the 4-connected pixels
    function _growRight(TileLib.Tile memory self) internal pure returns (TileLib.Tile memory e) {
        // for loop removed to save some gas.
        e.data[0] = (self.data[0] & RIGHT_MASK) >> 23;
        e.data[1] = (self.data[1] & RIGHT_MASK) >> 23;
        e.data[2] = (self.data[2] & RIGHT_MASK) >> 23;
        return e;
    }

    /// @notice grow (4-connected) a tile adding pixels around those that exists
    /// @param self the tile to grow
    /// @return e the extra tile to the left that results from adding all the 4-connected pixels
    function _growLeft(TileLib.Tile memory self) internal pure returns (TileLib.Tile memory e) {
        e.data[0] = (self.data[0] & LEFT_MASK) << 23;
        e.data[1] = (self.data[1] & LEFT_MASK) << 23;
        e.data[2] = (self.data[2] & LEFT_MASK) << 23;
        return e;
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File src/solc_0.8/common/interfaces/IEstateToken.sol



/// @title Interface for the Estate token on L1
interface IEstateToken {
    function mintEstate(address from, TileWithCoordLib.TileWithCoord[] calldata freeLand) external returns (uint256);

    function burnEstate(address from, uint256 estateId)
        external
        returns (TileWithCoordLib.TileWithCoord[] memory tiles);

    function contain(uint256 estateId, MapLib.TranslateResult memory s) external view returns (bool);

    function getStorageId(uint256 tokenId) external pure returns (uint256);

    function getOwnerOfStorage(uint256 estateId) external view returns (address owner);
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


// File src/solc_0.8/common/BaseWithStorage/ERC2771ContextUpgradeable.sol

pragma solidity ^0.8.0;


/**
 * @dev Context variant with ERC2771 support.
 * @dev Taken from OpenZeppelin source code. Remove after upgrading the OZ library!!!
 * @dev we need and internal _trustedForwarder so we can add a setter.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address internal _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal onlyInitializing {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal onlyInitializing {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    uint256[49] private __gap;
}


// File src/solc_0.8/common/Base/BaseERC721Upgradeable.sol




/// @title An ERC721 token that supports meta-tx and access control.
abstract contract BaseERC721Upgradeable is AccessControlUpgradeable, ERC721Upgradeable, ERC2771ContextUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice initialization
    /// @param trustedForwarder address of the meta tx trustedForwarder
    /// @param admin initial admin role that can grant or revoke other roles
    /// @param name_ name of the token
    /// @param symbol_ symbol of the token
    function __EstateBaseERC721_init(
        address trustedForwarder,
        address admin,
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC2771Context_init_unchained(trustedForwarder);
        __ERC721_init_unchained(name_, symbol_);
        __EstateBaseERC721_init_unchained(admin);
    }

    /// @notice initialization unchained
    /// @param admin initial admin role that can grant or revoke other roles
    function __EstateBaseERC721_init_unchained(address admin) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice set the trusted forwarder (used by the admin in case of misconfiguration)
    /// @param trustedForwarder address of the meta tx trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "not admin");
        _trustedForwarder = trustedForwarder;
    }

    /// @notice Returns whether `tokenId` exists.
    /// @dev Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
    /// @dev Tokens start existing when they are minted (`mint`), and stop existing when they are burned (`burn`).
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Check if the contract supports an interface.
    /// @param interfaceId The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /// @notice Implement an ERC20 metadata method so it is easier to import the token into metamask
    /// @dev Returns the decimals places of the token, for ERC721 it is always zero.
    /// @return
    function decimals() external pure returns (uint8) {
        return 0;
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}


// File src/solc_0.8/common/interfaces/IERC721MandatoryTokenReceiver.sol


/// @dev Note: The ERC-165 identifier for this interface is 0x5e8bf644.
interface IERC721MandatoryTokenReceiver {
    function onERC721BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x4b808c46

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x150b7a02
}


// File src/solc_0.8/estate/EstateTokenIdHelperLib.sol

/// @title Helper library to manage the estate token Id
library EstateTokenIdHelperLib {
    uint256 internal constant SUB_ID_MULTIPLIER = uint256(2)**128;
    uint256 internal constant CHAIN_INDEX_MULTIPLIER = uint256(2)**96;

    /// @notice Increment the version field of the tokenId (the storage Id is kept unchanged).
    /// @dev Mappings to token-specific data are preserved via the storageId part that doesn't change.
    /// @param estateId The estateId to increment.
    /// @return new estate id
    function incrementVersion(uint256 estateId) internal pure returns (uint256) {
        (uint128 subId, uint32 chainIndex, uint96 version) = unpackId(estateId);
        // is it ok to roll over the version we assume the it is impossible to send 2^16 txs
        unchecked {version++;}
        return packId(subId, chainIndex, version);
    }

    /// @notice Pack a new tokenId and associate it with an owner.
    /// @param subId The main id of the token, it never changes.
    /// @param chainIndex The index of the chain, 0: mainet, 1:polygon, etc
    /// @param version The version of the token, it changes on each modification.
    /// @return the token id
    function packId(
        uint128 subId,
        uint32 chainIndex,
        uint96 version
    ) internal pure returns (uint256) {
        return subId * SUB_ID_MULTIPLIER + chainIndex * CHAIN_INDEX_MULTIPLIER + version;
    }

    /// @notice Unpack the tokenId returning the separated values.
    /// @param id The token id
    /// @return subId The main id of the token, it never changes.
    /// @return chainIndex The index of the chain, 0: mainet, 1:polygon, etc
    /// @return version The version of the token, it changes on each modification.
    function unpackId(uint256 id)
        internal
        pure
        returns (
            uint128 subId,
            uint32 chainIndex,
            uint96 version
        )
    {
        return (uint64(id / SUB_ID_MULTIPLIER), uint16(id / CHAIN_INDEX_MULTIPLIER), uint16(id));
    }

    /// @notice Return the part of the tokenId that doesn't change on modifications
    /// @param id The token id
    /// @return The storage Id (the part that doesn't change on modifications)
    function storageId(uint256 id) internal pure returns (uint256) {
        return uint256(id / CHAIN_INDEX_MULTIPLIER) * CHAIN_INDEX_MULTIPLIER;
    }
}


// File src/solc_0.8/estate/EstateBaseToken.sol








/// @title Base contract for estate contract on L1 and L2, it used to group lands together.
/// @dev it uses tile maps to save the land
/// @dev each time something is modified the token id (version) is changed (but keeping a common storageId part)
abstract contract EstateBaseToken is BaseERC721Upgradeable, IEstateToken {
    using MapLib for MapLib.Map;
    using EstateTokenIdHelperLib for uint256;

    struct Estate {
        // current estateId, for the same storageId we have only one valid estateId (the last one)
        uint256 id;
        // estate lands tile set.
        MapLib.Map land;
    }

    struct EstateBaseTokenStorage {
        address landToken;
        uint128 nextId; // max uint64 = 18,446,744,073,709,551,615
        uint32 chainIndex;
        string baseUri;
        // storageId -> estateData
        mapping(uint256 => Estate) estate;
    }

    uint256[50] private __preGap;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @dev Emitted when an estate is updated.
    /// @param estateId The id of the newly minted token.
    /// @param user the user to which the estate is created
    /// @param lands the initial lands of the estate
    event EstateTokenCreated(uint256 indexed estateId, address user, TileWithCoordLib.TileWithCoord[] lands);

    /// @dev Emitted when lands are added to the estate.
    /// @param estateId The id of the previous erc721 ESTATE token.
    /// @param newId The id of the newly minted token.
    /// @param user the user that is adding lands
    /// @param lands The lands of the estate.
    event EstateTokenLandsAdded(
        uint256 indexed estateId,
        uint256 indexed newId,
        address user,
        TileWithCoordLib.TileWithCoord[] lands
    );

    /// @dev Emitted when the estate is updated
    /// @param oldId The original id of the erc721 ESTATE token.
    /// @param newId The updated id of the erc721 ESTATE token.
    /// @param user the user that is updating the estate
    /// @param lands the tiles that compose the estate
    event EstateTokenUpdated(
        uint256 indexed oldId,
        uint256 indexed newId,
        address user,
        TileWithCoordLib.TileWithCoord[] lands
    );

    /// @dev Emitted when the user burn an estate (must be empty).
    /// @param estateId The id of the erc721 ESTATE token.
    /// @param from the user from which the estate is taken
    event EstateTokenBurned(uint256 indexed estateId, address from);

    /// @dev Emitted when the bridge mint an estate.
    /// @param estateId The id of the  erc721 ESTATE token.
    /// @param operator The msg sender
    /// @param to the user to which the estate is minted
    /// @param lands the tiles that compose the estate and was sent from the other layer
    event EstateBridgeMinted(
        uint256 indexed estateId,
        address operator,
        address to,
        TileWithCoordLib.TileWithCoord[] lands
    );

    /// @dev Emitted when the bridge (burner role) burn an estate.
    /// @param estateId The id of the erc721 ESTATE token.
    /// @param operator The msg sender
    /// @param from the user from which the estate is taken
    /// @param lands the tiles that compose the estate and will be sent to the other layer
    event EstateBridgeBurned(
        uint256 indexed estateId,
        address operator,
        address from,
        TileWithCoordLib.TileWithCoord[] lands
    );

    /// @dev Emitted when the land contract address is changed
    /// @param operator The msg sender
    /// @param oldAddress of the land contract
    /// @param newAddress of the land contract
    event EstateLandTokenChanged(address indexed operator, address oldAddress, address newAddress);

    /// @dev Emitted when the base uri for the metadata url is changed
    /// @param operator The msg sender
    /// @param oldURI of the metadata url
    /// @param newURI of the metadata url
    event EstateBaseUrlChanged(address indexed operator, string oldURI, string newURI);

    /// @notice initialization
    /// @param trustedForwarder address of the meta tx trustedForwarder
    /// @param admin initial admin role that can grant or revoke other roles
    /// @param landToken_ the address of the land token contract
    /// @param chainIndex_ the chain index for example: 0:mainnet, 1:polygon, etc
    /// @param name_ name of the token
    /// @param symbol_ symbol of the token
    function initV1(
        address trustedForwarder,
        address admin,
        address landToken_,
        uint16 chainIndex_,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        __ERC2771Context_init_unchained(trustedForwarder);
        __ERC721_init_unchained(name_, symbol_);
        __EstateBaseERC721_init_unchained(admin);
        __EstateBaseToken_init_unchained(landToken_, chainIndex_);
    }

    /// @notice initialization unchained
    /// @param landToken_ the address of the land token contract
    /// @param chainIndex_ the chain index for example: 0:mainnet, 1:polygon, etc
    function __EstateBaseToken_init_unchained(address landToken_, uint16 chainIndex_) internal onlyInitializing {
        _s().landToken = landToken_;
        _s().chainIndex = chainIndex_;
    }

    /// @notice Create a new estate token adding the given quads (aka lands).
    /// @param landToAdd The set of quads to add.
    /// @return estateId the estate Id created
    function create(uint256[][3] calldata landToAdd) external virtual returns (uint256 estateId) {
        Estate storage estate = _mintEstate(_msgSender());
        require(landToAdd[0].length > 0, "nothing to add");
        _addLand(estate, _msgSender(), landToAdd);
        require(estate.land.isAdjacent(), "not adjacent");
        emit EstateTokenCreated(estate.id, _msgSender(), estate.land.getMap());
        return estate.id;
    }

    /// @notice Add the given quads (aka lands) to an Estate.
    /// @param oldId the estate id that will be updated
    /// @param landToAdd The set of quads to add.
    /// @return estateId the new estate Id
    function addLand(uint256 oldId, uint256[][3] calldata landToAdd) external virtual returns (uint256) {
        require(_isApprovedOrOwner(_msgSender(), oldId), "caller is not owner nor approved");
        require(landToAdd[0].length > 0, "nothing to add");
        Estate storage estate = _estate(oldId);
        // we can optimize when adding only one quad
        // The risk with this optimizations is that you keep adding lands but then you cannot remove because
        // the removal check is the expensive one.
        if (landToAdd[0].length == 1) {
            // check that the quad is adjacent before adding
            require(estate.land.isAdjacent(landToAdd[1][0], landToAdd[2][0], landToAdd[0][0]), "not adjacent");
            _addLand(estate, _msgSender(), landToAdd);
        } else {
            // add everything then make the heavier check of the result
            _addLand(estate, _msgSender(), landToAdd);
            require(estate.land.isAdjacent(), "not adjacent");
        }
        estate.id = _incrementTokenVersion(estate.id);
        emit EstateTokenLandsAdded(oldId, estate.id, _msgSender(), estate.land.getMap());
        return estate.id;
    }

    /// @notice create a new estate from scratch (Used by the bridge)
    /// @param to user that will get the new minted Estate
    /// @param tiles the list of tiles (aka lands) to add to the estate
    /// @return the estate Id created
    function mintEstate(address to, TileWithCoordLib.TileWithCoord[] calldata tiles)
        external
        virtual
        override
        returns (uint256)
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "not authorized");
        Estate storage estate = _mintEstate(to);
        estate.land.set(tiles);
        emit EstateBridgeMinted(estate.id, _msgSender(), to, tiles);
        return estate.id;
    }

    /// @notice completely burn an estate (Used by the bridge)
    /// @dev must be implemented for every layer, see PolygonEstateTokenV1 and EstateTokenV1
    /// @param from user that is trying to use the bridge
    /// @param estateId the id of the estate token
    /// @return tiles the list of tiles (aka lands) to add to the estate
    function burnEstate(address from, uint256 estateId)
        external
        virtual
        override
        returns (TileWithCoordLib.TileWithCoord[] memory tiles);

    /// @notice change the address of the land contract
    /// @param landToken the new address of the land contract
    function setLandToken(address landToken) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "not admin");
        require(landToken != address(0), "invalid address");
        address oldAddress = _s().landToken;
        _s().landToken = landToken;
        emit EstateLandTokenChanged(_msgSender(), oldAddress, landToken);
    }

    /// @notice change the base uri of the metadata url
    /// @param baseUri the base uri of the metadata url
    function setBaseURI(string calldata baseUri) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "not admin");
        string memory oldUri = _s().baseUri;
        _s().baseUri = baseUri;
        emit EstateBaseUrlChanged(_msgSender(), oldUri, baseUri);
    }

    /// @notice return the id of the next estate token
    /// @return next id
    function getNextId() external view returns (uint256) {
        return _s().nextId;
    }

    /// @notice return the chain index
    /// @return chain index
    function getChainIndex() external view returns (uint256) {
        return _s().chainIndex;
    }

    /// @notice return the address of the land token contract
    /// @return land token contract address
    function getLandToken() external view returns (address) {
        return _s().landToken;
    }

    /// @notice return owner of the estateId ignoring version rotations (used by the registry)
    /// @param storageId the storage id for an estate
    /// @return owner address
    function getOwnerOfStorage(uint256 storageId) external view override returns (address) {
        return ownerOf(_estate(storageId).id);
    }

    /// @notice return the amount of tiles that describe the land map inside a given estate
    /// @param estateId the estate id
    /// @return the length of the tile map
    function getLandLength(uint256 estateId) external view returns (uint256) {
        return _estate(estateId).land.length();
    }

    /// @notice return an array of tiles describing the map of lands for a given estate
    /// @param estateId the estate id
    /// @param offset an amount of entries to skip in the array (pagination)
    /// @param limit amount of entries to get (pagination)
    /// @return an array of tiles describing the map of lands
    function getLandAt(
        uint256 estateId,
        uint256 offset,
        uint256 limit
    ) external view returns (TileWithCoordLib.TileWithCoord[] memory) {
        return _estate(estateId).land.at(offset, limit);
    }

    /// @notice check if the estate contains certain displaced template (used by the registry)
    /// @param estateId the estate id
    /// @param s displaced template
    /// @return true if the estate contain all the lands of the displaced template
    function contain(uint256 estateId, MapLib.TranslateResult memory s) external view override returns (bool) {
        return _estate(estateId).land.contain(s);
    }

    /// @notice return the amount of lands inside the estate
    /// @param estateId the estate id
    /// @return the amount of lands inside the estate
    function getLandCount(uint256 estateId) external view returns (uint256) {
        return _estate(estateId).land.getLandCount();
    }

    /// @notice given and estateId return the part that doesn't change when the version is incremented
    /// @param estateId the estate id
    /// @return the storage Id
    function getStorageId(uint256 estateId) external pure override returns (uint256) {
        return estateId.storageId();
    }

    /// @notice this is necessary to be able to receive land
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        bytes calldata /* data */
    ) external view virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice this is necessary to be able to receive land
    function onERC721BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        bytes calldata /* data */
    ) external view virtual returns (bytes4) {
        return this.onERC721BatchReceived.selector;
    }

    /// @notice Check if the contract supports an interface.
    /// @param interfaceId The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IERC721MandatoryTokenReceiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _addLand(
        Estate storage estate,
        address from,
        uint256[][3] calldata quads
    ) internal {
        uint256 len = quads[0].length;
        require(len == quads[1].length && len == quads[2].length, "invalid data");
        for (uint256 i; i < len; i++) {
            estate.land.set(quads[1][i], quads[2][i], quads[0][i]);
        }
        ILandToken(_s().landToken).batchTransferQuad(from, address(this), quads[0], quads[1], quads[2], "");
    }

    function _mintEstate(address to) internal returns (Estate storage estate) {
        uint256 estateId = EstateTokenIdHelperLib.packId(++(_s().nextId), _s().chainIndex, 1);
        estate = _estate(estateId);
        estate.id = estateId;
        super._mint(to, estateId);
        return estate;
    }

    function _burnEstate(Estate storage estate) internal {
        estate.land.clear();
        delete estate.land;
        uint256 estateId = estate.id;
        delete _s().estate[estateId.storageId()];
        super._burn(estateId);
    }

    /// @dev used to increment the version in a tokenId by burning the original and reminting a new token. Mappings to
    /// @dev token-specific data are preserved via the storageId mechanism.
    /// @param estateId The estateId to increment.
    /// @return new estate id
    function _incrementTokenVersion(uint256 estateId) internal returns (uint256) {
        address owner = ownerOf(estateId);
        super._burn(estateId);
        estateId = estateId.incrementVersion();
        super._mint(owner, estateId);
        return estateId;
    }

    /// @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    /// @dev token will be the concatenation of the `baseURI` and the `tokenId`.
    /// @dev We don't use storageId in the url because we want the centralized backend to extract it if needed.
    function _baseURI() internal view virtual override returns (string memory) {
        return _s().baseUri;
    }

    function _estate(uint256 estateId) internal view returns (Estate storage) {
        return _s().estate[estateId.storageId()];
    }

    function _s() internal pure returns (EstateBaseTokenStorage storage ds) {
        bytes32 storagePosition = keccak256("EstateBaseTokenStorage.EstateBaseTokenStorage");
        assembly {
            ds.slot := storagePosition
        }
    }

    uint256[50] private __posGap;
}


// File src/solc_0.8/polygon/child/estate/PolygonEstateTokenV1.sol





contract PolygonEstateTokenV1 is EstateBaseToken {
    using MapLib for MapLib.Map;

    struct PolygonEstateTokenStorage {
        IEstateExperienceRegistry registryToken;
    }

    /// @dev Emitted when the registry is changed
    /// @param operator The msg sender
    /// @param oldRegistry old address of the registry
    /// @param newRegistry new address of the registry
    event EstateRegistryChanged(
        address indexed operator,
        IEstateExperienceRegistry oldRegistry,
        IEstateExperienceRegistry newRegistry
    );

    /// @notice update an estate adding and removing lands, and unlinking experiences in one step
    /// @dev to be able to remove lands they must be completely unlinked from any experience (in the registry)
    /// @param oldId the estate id that will be updated
    /// @param landToAdd The set of quads to add.
    /// @param expToUnlink experiences to unlink
    /// @param landToRemove The set of quads to remove.
    /// @return estateId the new estate Id
    function update(
        uint256 oldId,
        uint256[][3] calldata landToAdd,
        uint256[] calldata expToUnlink,
        uint256[][3] calldata landToRemove
    ) external returns (uint256) {
        require(_isApprovedOrOwner(_msgSender(), oldId), "caller is not owner nor approved");
        IEstateExperienceRegistry registry = _ps().registryToken;
        if (address(registry) == address(0)) {
            require(expToUnlink.length == 0, "invalid data");
            require(landToAdd[0].length > 0 || landToRemove[0].length > 0, "nothing to update");
        } else {
            require(
                landToAdd[0].length > 0 || landToRemove[0].length > 0 || expToUnlink.length > 0,
                "nothing to update"
            );
        }
        Estate storage estate = _estate(oldId);
        _addLand(estate, _msgSender(), landToAdd);
        _removeLand(estate, registry, _msgSender(), landToRemove, expToUnlink);
        require(!estate.land.isEmpty(), "estate cannot be empty");
        require(estate.land.isAdjacent(), "not adjacent");
        estate.id = _incrementTokenVersion(estate.id);
        emit EstateTokenUpdated(oldId, estate.id, _msgSender(), estate.land.getMap());
        return estate.id;
    }

    /// @notice burn an estate
    /// @dev to be able to remove lands they must be completely unlinked from any experience (in the registry)
    /// @dev to be able to burn an estate it must be empty
    /// @param estateId the estate id that will be updated
    /// @param expToUnlink experiences to unlink
    /// @param landToRemove The set of quads to remove.
    function burn(
        uint256 estateId,
        uint256[] calldata expToUnlink,
        uint256[][3] calldata landToRemove
    ) external {
        require(_isApprovedOrOwner(_msgSender(), estateId), "caller is not owner nor approved");
        Estate storage estate = _estate(estateId);
        IEstateExperienceRegistry registry = _ps().registryToken;
        require(expToUnlink.length == 0 || address(registry) != address(0), "invalid data");
        _removeLand(estate, registry, _msgSender(), landToRemove, expToUnlink);
        require(estate.land.isEmpty(), "map not empty");
        _burnEstate(estate);
        emit EstateTokenBurned(estateId, _msgSender());
    }

    /// @notice completely burn an estate (Used by the bridge)
    /// @dev to be able to bridge an estate all the lands must be unlinked (we don't have a registry on L1)
    /// @param from user that is trying to use the bridge
    /// @param estateId the id of the estate token
    /// @return tiles the list of tiles (aka lands) to add to the estate
    function burnEstate(address from, uint256 estateId)
        external
        override
        returns (TileWithCoordLib.TileWithCoord[] memory tiles)
    {
        require(hasRole(BURNER_ROLE, _msgSender()), "not authorized");
        require(_isApprovedOrOwner(from, estateId), "caller is not owner nor approved");
        Estate storage estate = _estate(estateId);
        tiles = estate.land.getMap();
        IEstateExperienceRegistry r = _ps().registryToken;
        if (address(r) != address(0)) {
            require(!r.isLinked(tiles), "must unlink first");
        }
        _burnEstate(estate);
        emit EstateBridgeBurned(estateId, _msgSender(), from, tiles);
        return (tiles);
    }

    /// @notice set the registry contract address
    /// @param registry the registry contract address
    function setRegistry(IEstateExperienceRegistry registry) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "not admin");
        require(address(registry) != address(0), "invalid address");
        IEstateExperienceRegistry old = _ps().registryToken;
        _ps().registryToken = registry;
        emit EstateRegistryChanged(_msgSender(), old, registry);
    }

    /// @notice get the registry contract address
    /// @return registry the registry contract address
    function getRegistry() external view returns (IEstateExperienceRegistry) {
        return _ps().registryToken;
    }

    /// @dev See https://docs.opensea.io/docs/contract-level-metadata
    /// @return the metadata url for the whole contract
    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "polygon_estate.json")) : "";
    }

    function _removeLand(
        Estate storage estate,
        IEstateExperienceRegistry registry,
        address from,
        uint256[][3] calldata quads,
        uint256[] calldata expToUnlink
    ) internal {
        uint256 len = quads[0].length;
        require(len == quads[1].length && len == quads[2].length, "invalid quad data");
        if (address(registry) != address(0)) {
            if (expToUnlink.length > 0) {
                registry.batchUnLinkFrom(from, expToUnlink);
            }
            require(!registry.isLinked(quads), "must unlink first");
        }
        address landToken = _s().landToken;
        MapLib.Map storage map = estate.land;
        for (uint256 i; i < len; i++) {
            _removeQuad(from, map, landToken, quads[0][i], quads[1][i], quads[2][i]);
        }
    }

    function _removeQuad(
        address to,
        MapLib.Map storage map,
        address landToken,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal {
        require(map.contain(x, y, size), "quad missing");
        map.clear(x, y, size);
        if (!IPolygonLand(landToken).exists(size, x, y)) {
            // The only way this can happen is if the lands passed trough the bridge
            IPolygonLand(landToken).mintQuad(to, size, x, y, "");
        } else {
            IPolygonLand(landToken).transferQuad(address(this), to, size, x, y, "");
        }
    }

    function _ps() internal pure returns (PolygonEstateTokenStorage storage ds) {
        bytes32 storagePosition = keccak256("PolygonEstateToken.PolygonEstateTokenStorage");
        assembly {
            ds.slot := storagePosition
        }
    }
}