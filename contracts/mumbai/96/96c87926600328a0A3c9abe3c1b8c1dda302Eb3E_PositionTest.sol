/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

// move up and down + side to side on the surface of a torus
contract PositionTest {
    uint256 public x;
    uint256 public y;

    constructor() {
        x = 0;
        y = 0;
    }

    function Up() public {
        unchecked {
            y += 1;
        }
    }

    function Down() public {
        unchecked {
            y -= 1;
        }
    }

    function Left() public {
        unchecked {
            x -= 1;
        }
    }

    function Right() public {
        unchecked {
            x += 1;
        }
    }

    function report () public view returns (uint256, uint256) {
        return (x, y);
    }
}