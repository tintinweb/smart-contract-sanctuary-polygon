// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

contract JwtTest {
    function emitJwt(string memory jwt) external {
        emit EmitJwt(msg.sender, jwt);
    }

    event EmitJwt(address sender, string jwt);
}