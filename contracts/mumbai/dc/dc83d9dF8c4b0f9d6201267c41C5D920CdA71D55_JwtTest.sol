// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

struct State {
    address sender;
    string jwt;
    bool isVerified;
}

contract JwtTest {
    uint256 private _counter;
    mapping(uint256 => State) private _states;

    function register(string memory jwt) external {
        _counter += 1;
        _states[_counter] = State(msg.sender, jwt, false);
        emit Registered(_counter, msg.sender, jwt);
    }

    function verify(uint256 id) external {
        _states[id].isVerified = true;
        emit Verified(id, msg.sender);
    }

    event Registered(uint256 id, address sender, string jwt);
    event Verified(uint256 id, address verifiyer);
}