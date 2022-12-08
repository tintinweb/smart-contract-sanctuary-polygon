pragma solidity ^0.8.4;

import "./MockTokenParent.sol";

contract VerifyThis is MockTokenParent {
    uint256 public test = 100;
}

pragma solidity ^0.8.0;

contract MockTokenParent {
    uint256 public testor = 10;
}