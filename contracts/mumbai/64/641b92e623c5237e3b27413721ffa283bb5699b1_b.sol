/**
 *Submitted for verification at polygonscan.com on 2023-01-01
*/

/** 
 *  SourceUnit: /Users/beamnawapat/Desktop/GithubRepo/Covest/core/contracts/test/b.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity 0.8.17;

library StroageLib {
    struct Layout {
        string message;
    }
    bytes32 internal constant STORAGE_SLOT =
        keccak256("covest.contracts.insurance.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_SLOT;
        assembly {
            l.slot := position
        }
    }
}


/** 
 *  SourceUnit: /Users/beamnawapat/Desktop/GithubRepo/Covest/core/contracts/test/b.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.17;

////import {StroageLib} from "./storage.sol";

contract b {
    using StroageLib for StroageLib.Layout;
    event Annoucement(string msg);

    function sayHello() public {
        StroageLib.layout().message = "Hello";
        emit Annoucement("Hello");
    }
}