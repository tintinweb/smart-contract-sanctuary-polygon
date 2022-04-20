//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Demo.sol";

contract Demo_args {
    string private name;
    uint256 private number;
    Demo private demoAddress;

    constructor(
        string memory _name,
        uint256 _number,
        Demo _demoAddress
    ) {
        name = _name;
        number = _number;
        demoAddress = _demoAddress;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    function getDemoAddress() external view returns (Demo) {
        return demoAddress;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Demo {
    event Echo(string message);

    function echo(string calldata message) external {
        emit Echo(message);
    }
}