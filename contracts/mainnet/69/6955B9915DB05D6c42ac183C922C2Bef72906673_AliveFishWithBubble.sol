// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library AliveFishWithBubble {
    function Fish2StringPart1() public pure returns (bytes memory) {
    return bytes(
            abi.encodePacked(
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="1380pt" height="1380pt" viewBox="0 0 1380 1380" preserveAspectRatio="xMidYMid meet">',
                '<style> .small { font:  50px Comic Sans MS ; } </style>',
                '<defs>',
                '<linearGradient cx="0.25" cy="0.25" r="0.75" id="gradBackground" gradientTransform="rotate(90)">',
                '<stop offset="0%" stop-color="hsl(204, 80%, 84%)"/>',
                '<stop offset="50%" stop-color="hsl(204, 80%, 75%)"/>',
                '<stop offset="100%" stop-color="hsl(204, 80%, 60%)"/>',
                '</linearGradient>',
                '</defs>'
            ) 
      );
    }

    function Fish2StringPart4() public pure returns (bytes memory) {
    return bytes(
            abi.encodePacked(
                '<defs>',
                '<radialGradient cx="0.15" cy="0.15" r="0.95" id="gradBubble">',
                '<stop offset="0%" stop-color="hsl(200, 77%, 100%)"/>',
                '<stop offset="50%" stop-color="hsl(200, 77%, 80%)"/>',
                '<stop offset="100%" stop-color="hsl(200, 77%, 60%)"/>',
                '</radialGradient>',
                '</defs>',
                '<rect width="1380" height="1380" fill="url(#gradBackground)"/>'
                '<circle cx="690" cy="690" r="570" stroke="black" stroke-width="7" fill="url(#gradBubble)"/>'
            )
        );
    }
}