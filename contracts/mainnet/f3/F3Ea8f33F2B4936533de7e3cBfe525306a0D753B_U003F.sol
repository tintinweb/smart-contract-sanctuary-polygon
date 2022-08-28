// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**                                                                              
       .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.        
       (###############################################(        
   *%%%(,,,#########################################,,,(%%%*    
   (###(   (#######################################(   (###(    
   (###############(                   (###################(    
   (###########%(((,   ,(((((((((((,   ,(((%###############(    
   (###########(       (###########(       (###############(    
   (###########(       (###########(       (###############(    
   (###########(       (###########(       (###############(    
   (###########(       (###########(       (###############(    
   (###########&%%%%%%%&########,,,.       (###############(    
   (###########################(           (###############(    
   (#######################(       (#######################(    
   (#######################(       (#######################(    
   (#######################(       (#######################(    
   (#######################################################(    
   (#######################&%%%%%%%&#######################(    
   (#######################(       (#######################(    
   (#######################(       (#######################(    
   (#######################(       (#######################(    
   (###(   (#######################################(   (###(    
   ,(((((((%#######################################%(((((((,    
       (###############################################(                                                                     
 */   

interface ISnowV1Program {
    function name() external view returns (string memory);
    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex) external returns (uint8 index, uint256 value);
}

contract U003F is ISnowV1Program {
    function name() external pure returns (string memory) {
        return "?";
    }

    function run(uint256[64] calldata canvas, uint8) external pure returns (uint8 index, uint256 value) {
        uint256[5] memory sprites = [
            0x000000000FFF0FFF33FF33FF3FC03FC03F0F3F0F3F0F3F0F3F0F3F0F3FFF3FFF, // top-left
            0x00000000FFF0FFF0FFCCFFCC0FFC0FFCC3FCC3FCC3FCC3FCC3FCC3FC03FC03FC, // top-right
            0x3FFC3FFC3FFC3FFC3FFF3FFF3FFC3FFC3FFC3FFC33FF33FF0FFF0FFF00000000, // bottom-left
            0x3FFC3FFC3FFC3FFCFFFCFFFC3FFC3FFC3FFC3FFCFFCCFFCCFFF0FFF000000000, // bottom-right
            0x00003ffc5ffa783e739e739e739e7f1e7e7e7e7e7ffe7e7e7e7e5ffa3ffc0000  // bully sprite
        ];

        // Draw in top-right corner
        if (canvas[6] != sprites[0]) return (6, sprites[0]);
        if (canvas[7] != sprites[1]) return (7, sprites[1]);
        if (canvas[14] != sprites[2]) return (14, sprites[2]);
        if (canvas[15] != sprites[3]) return (15, sprites[3]);

        // Drawing has already been painted
        // Draw 16x16 on QR to bully <3
        return (62, sprites[4]);
    }
}