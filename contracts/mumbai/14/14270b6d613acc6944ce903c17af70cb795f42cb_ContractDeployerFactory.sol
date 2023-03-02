/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

contract ContractDeployerFactory {
    event ContractDeployed(uint256 salt, address addr);

    function deployContract(uint256 _salt, bytes memory _contractBytecode) public {
        address addr;
        assembly {
            addr := create2(0, add(_contractBytecode, 0x20), mload(_contractBytecode), _salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(_salt, addr);
    }

        function getBytecode(bytes memory _contractBytecode)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_contractBytecode);
    }

    function getAddress(uint256 _salt,bytes memory _contractBytecode) public view returns (address,bytes32) {
         bytes32 _code = keccak256(getBytecode(_contractBytecode));
         bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this), 
                _salt,
                _code
            )
        );
        return (address(uint160(uint256(hash))),_code);
    }
}