// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IAavegotchi.sol";

contract AavegotchiAutoPet {
    IAavegotchi public aavegotchi =
        IAavegotchi(0x86935F11C86623deC8a25696E1C19a8659CbF95d);

    constructor() {}

    function setPetOperatorForAll(address _operator, bool _approved) public {
        aavegotchi.setPetOperatorForAll(_operator, _approved);
    }

    function interact(uint256[] memory _tokenIds) public {
        aavegotchi.interact(_tokenIds);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAavegotchi {
    function interact(uint256[] calldata _tokenIds) external;

    function setPetOperatorForAll(address _operator, bool _approved) external;
}