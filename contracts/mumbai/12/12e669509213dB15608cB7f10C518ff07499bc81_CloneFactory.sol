// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract CloneFactory {
    address public instance;
    address public contractAddr;

    event Deployed(address addr, uint salt);

    function getAddress(
        bytes memory bytecode,
        uint _salt
    ) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint(hash)));
    }

    function deploy(
        bytes memory bytecode,
        uint _salt
    ) public returns (address) {
        address addr;
        assembly {
            addr := create2(
                0, 
                add(bytecode, 0x20),
                mload(bytecode), 
                _salt 
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
        return addr;
    }

    function getBytecode(
        address implementation,
        bytes memory context
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d61", // RETURNDATASIZE, PUSH2
                uint16(0x2d + context.length + 1), // size of minimal proxy (45 bytes) + size of context + stop byte
                hex"8060", // DUP1, PUSH1
                uint8(0x0a + 1), // default offset (0x0a) + 1 byte because we increased size from uint8 to uint16
                hex"3d3981f3363d3d373d3d3d363d73", // standard EIP1167 implementation
                implementation, // implementation address
                hex"5af43d82803e903d91602b57fd5bf3", // standard EIP1167 implementation
                hex"00", // stop byte (prevents context from executing as code)
                context // appended context data
            );
    }

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenCollection,
        uint256 tokenId,
        uint256 salt
    ) external returns (address) {
        bytes memory encodedTokenData = abi.encode(
            chainId,
            tokenCollection,
            tokenId
        );
        contractAddr = cloneContract(implementation,encodedTokenData,salt);
        
        return contractAddr;
    }

    function cloneContract(
        address implementation,
        bytes memory context,
        uint salt
    ) internal returns (address) {
        bytes memory code = getBytecode(implementation, context);
        instance = deploy(code, salt);
        return instance;
    }
}