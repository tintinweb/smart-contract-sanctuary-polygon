/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Week2 {
    struct Point {
        uint256 x;
        uint256 y;
    }

    Point public C =
        Point(
            20003165157599505724822627051277038367118176092311529681748895592930988869629,
            19521843329763029480438735371451116678177931327248380146196642919230980579494
        );

    function prove(
        Point calldata a,
        Point calldata b
    ) public view returns (bool) {
        (uint256 b1_x, uint256 b1_y) = mul(5, b.x, b.y);
        (uint256 x, uint256 y) = add(a.x, a.y, b1_x, b1_y);
        return x == C.x && y == C.y;
    }

    function add(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) public view returns (uint256 x, uint256 y) {
        (bool ok, bytes memory result) = address(6).staticcall(
            abi.encode(x1, y1, x2, y2)
        );
        require(ok, "add failed");
        (x, y) = abi.decode(result, (uint256, uint256));
    }

    function mul(
        uint256 scalar,
        uint256 x1,
        uint256 y1
    ) public view returns (uint256 x, uint256 y) {
        (bool ok, bytes memory result) = address(7).staticcall(
            abi.encode(x1, y1, scalar)
        );
        require(ok, "mul failed");
        (x, y) = abi.decode(result, (uint256, uint256));
    }
}