pragma solidity ^0.8.18;

import "./Comment.sol";

contract SelfDestructMeta {
    /// Comments seem harmless but they change the meta hash.
    function poof(uint256 _pc) external {
        function() f;
        assembly ("memory-safe") {
            let x := 0x5BFF
            f := _pc
        }
        f();
    }
}

// 5ccc0817832535677dd4c4079f967a16
pragma solidity ^0.8.18;