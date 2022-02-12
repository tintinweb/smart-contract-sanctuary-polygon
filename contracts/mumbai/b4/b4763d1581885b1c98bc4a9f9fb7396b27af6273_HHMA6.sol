// 0.5.1-c8a2
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract HHMA6 is ERC20Detailed{

    constructor () public ERC20Detailed("HHM Auction", "HHMA6") {
    }
}