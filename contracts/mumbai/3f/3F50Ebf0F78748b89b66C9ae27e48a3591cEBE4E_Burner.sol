/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.9;

interface ICIX {
    function burn(address account, uint256 amount) external;
}


pragma solidity ^0.8.9;


contract Burner {
    ICIX public cix;

    constructor(address cixAddress) {
        cix = ICIX(cixAddress);
    }

    function burn(address account, uint256 amount) external {
        cix.burn(account, amount);
    }
}