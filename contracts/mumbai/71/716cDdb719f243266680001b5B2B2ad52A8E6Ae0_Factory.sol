/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

pragma solidity ^0.8.7;

contract Factory {
    event Created(address indexed addr);

    function create(
        bytes memory code,
        uint256 salt,
        bytes calldata data
    ) external returns (address) {
        address addr;

        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        if (data.length > 0) {
            (bool success, ) = addr.call(data);
            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        emit Created(addr);

        return addr;
    }
}