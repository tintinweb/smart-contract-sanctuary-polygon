/**
 *            _   __________  ____  __            __  _______ _   ____
 *           / | / /_  __/ / / / / / /           / / / / ___// | / / /
 *          /  |/ / / / / /_/ / / / /  ______   / /_/ /\__ \/  |/ / /
 *         / /|  / / / / __  / /_/ /  /_____/  / __  /___/ / /|  / /___
 *        /_/ |_/ /_/ /_/ /_/\____/           /_/ /_//____/_/ |_/_____/
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/**
 * Generate UUID strings from `block.difficulty`, i.e., `block.prevrandao`
 * 
 * UUID follows RFC4122 Version-4 Variant-1 (DCE 1.1, ISO/IEC 11578:1996)
 * 
 * See more at https://datatracker.ietf.org/doc/html/rfc4122.html
 */

contract UUIDGenerator {
    /******************************** Constant ********************************/
    bytes16 private constant symbols      = "0123456789abcdef";
    uint256 private constant maxLoopCount = 3;
    
    /***************************** State veriable *****************************/
    mapping(bytes16 => bool) public usedUUIDs;
    
    /************************* Public write function **************************/
    function generateUUID4() public returns (string memory) {
        bytes16 result;
        uint256 i;
        
        // Try at most 3 times to generate non-repeating UUID4, otherwise revert
        for (;i < maxLoopCount;) {
            result = randomUUID4();
            
            if (!usedUUIDs[result]) {
                break;
            }
            
            unchecked {i++;}
        }
        if (i == maxLoopCount) {
            revert('Failed to generate "non-repeating" UUID4 for now');
        }
        else {
            usedUUIDs[result] = true;
        }
        
        return toUUIDLayout(result);
    }
    
    /**************************** Private function ****************************/
    function randomUUID4() private view returns (bytes16) {
        bytes16 randomSource = bytes16(uint128(block.difficulty));
        
        bytes1 byte_9 = bytes1(randomSource << (6*8));
        bytes1 byte_7 = bytes1(randomSource << (8*8));
        
        // Version hex digit: M
        if (((byte_9 < 0x40) || (byte_9 > 0x4F))) {
            byte_9 = bytes1((uint8(byte_9) % 16) + 64);
            randomSource &= 0xFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFF;
            randomSource |= (bytes16(byte_9) >> (6*8));
        }
        
        // Variant hex digit: N
        if (((byte_7 < 0x80) || (byte_7 > 0xBF))) {
            byte_7 = bytes1((uint8(byte_7) % 64) + 128);
            randomSource &= 0xFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFF;
            randomSource |= (bytes16(byte_7) >> (8*8));
        }
        
        return randomSource;
    }
    
    function toUUIDLayout(bytes16 uuid) private pure returns (string memory) {
        string memory uuidLayout;
        string memory partialLayout;
        
        partialLayout = toHexString(uint256(uint32(bytes4(uuid << (0 *8)))), 4);
        uuidLayout = string.concat(uuidLayout, partialLayout, "-");
        
        partialLayout = toHexString(uint256(uint16(bytes2(uuid << (4 *8)))), 2);
        uuidLayout = string.concat(uuidLayout, partialLayout, "-");
        
        partialLayout = toHexString(uint256(uint16(bytes2(uuid << (6 *8)))), 2);
        uuidLayout = string.concat(uuidLayout, partialLayout, "-");
        
        partialLayout = toHexString(uint256(uint16(bytes2(uuid << (8 *8)))), 2);
        uuidLayout = string.concat(uuidLayout, partialLayout, "-");
        
        partialLayout = toHexString(uint256(uint48(bytes6(uuid << (10*8)))), 6);
        uuidLayout = string.concat(uuidLayout, partialLayout);
        
        return uuidLayout;
    }
    
    function toHexString(uint256 value, uint256 length) private pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        
        for (uint256 i = 2 * length - 1;;) {
            buffer[i] = symbols[value & 0xF];
            value >>= 4;
            
            if (i == 0) {
                break;
            }
            else {
                unchecked{i--;}
            }
        }
        
        return string(buffer);
    }
}