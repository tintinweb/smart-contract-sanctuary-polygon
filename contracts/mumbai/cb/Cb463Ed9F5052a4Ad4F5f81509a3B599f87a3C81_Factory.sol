// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract Factory {
    mapping(address => uint256) public counter;

    event Deployed(address indexed addr);

    function deploy(
        bytes memory bytecode, bytes32 salt
    ) external returns (address addr) {
        require(
            bytecode.length > 0,
            "Factory.deploy: empty bytecode"
        );

        assembly {
            addr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
        }

        require(
            addr != address(0),
            "Factory.deploy: failed deployment"
        );
            
        emit Deployed(addr);
    }

    function computeAddress(
        bytes memory bytecode, bytes32 salt
    ) external view returns (address) {
        bytes32 hashed = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        return address(uint160(uint256(hashed)));
    }
}