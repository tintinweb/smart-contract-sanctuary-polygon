// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Fallback {
    uint8 num = 0;

    function fixMe() public view returns (bool) {
        return num == 1;
    }

    fallback() external {
        num = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Fallback.sol";

contract GameFactory {
    Fallback[] public Fallbacks;
    uint256 public saltFallbackCounter;

    function createFallbackGame() public {
        bytes32 salt = bytes32(saltFallbackCounter);
        Fallback _fallback = (new Fallback){salt: salt}();
        Fallbacks.push(_fallback);
        saltFallbackCounter += 1;
    }

    function finder() public view returns (address) {
        return address(Fallbacks[saltFallbackCounter - 1]);
    }

    function checkFallbackGame(address _entity) public view returns (bool) {
        Fallback entity;
        entity = Fallback(_entity);
        return entity.fixMe();
    }
}