/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// SPDX-License-Identifier: MIT

// ╭╮╭━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╭╮╱╱╭╮
// ┃┃┃╭╯╱╱╱╱╱╱╱╱╱╱╱╱╱┃╰╮╭╯┃
// ┃╰╯╯╭━━┳╮╭┳━━┳━╮╭━┻╮┃┃╭┻━┳━┳━━┳━━╮
// ┃╭╮┃┃┃━┫╰╯┃╭╮┃╭╮┫╭╮┃╰╯┃┃━┫╭┫━━┫┃━┫
// ┃┃┃╰┫┃━┫┃┃┃╰╯┃┃┃┃╰╯┣╮╭┫┃━┫┃┣━━┃┃━┫
// ╰╯╰━┻━━┻┻┻┻━━┻╯╰┻━━╯╰╯╰━━┻╯╰━━┻━━╯
// https://kemonoverse.io/

pragma solidity ^0.8.4;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BatchTransfer {
    function transferERC20(
        IERC20 token,
        address[] memory to,
        uint256[] memory amount
    ) external {
        for (uint256 i = 0; i < to.length; i++) {
            require(token.transferFrom(msg.sender, to[i], amount[i]));
        }
    }

    function transferERC721(
        IERC721 token,
        address[] memory to,
        uint256[] memory tokenId
    ) external {
        for (uint256 i = 0; i < to.length; i++) {
            token.safeTransferFrom(msg.sender, to[i], tokenId[i]);
        }
    }
}