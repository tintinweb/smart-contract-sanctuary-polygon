// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Retriever } from "./Retriever.sol";

contract Doppleganger {
    bytes32 immutable runtime;

    constructor(Retriever retriever) {
        runtime = retriever.retrieve();
    }

    function readRuntime() public view returns (bytes32) {
        return runtime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Retriever {
    bytes32 retrieved;

    function setRetrieved(bytes32 _retrieved) public {
        retrieved = _retrieved;
    }

    function retrieve() public view returns (bytes32) {
        return retrieved;
    }
}