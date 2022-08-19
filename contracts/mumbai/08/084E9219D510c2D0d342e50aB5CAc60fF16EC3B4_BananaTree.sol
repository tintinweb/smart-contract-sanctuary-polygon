// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Tree.sol";

contract BananaTree is Tree {
    function name() external pure override returns (string memory) {
        return "BananaTree";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract Tree {
    string private _greeting;

    // ******************************************************************************** //

    function greet() external view returns (string memory) {
        return _greeting;
    }

    function setGreeting(string memory greeting) external {
        _greeting = greeting;
    }

    function name() external pure virtual returns (string memory);
}