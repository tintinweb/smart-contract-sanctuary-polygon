/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

contract A {
    uint256 public c=10;
}


contract Factory {
    function deploy(
        uint256 _salt
    ) public returns (address _x){
        _x = address(new A{salt: bytes32(_salt)}());
        //A(x_).transferOwnership(msg.sender);
    }

    function getBytecode()
        public
        pure
        returns (bytes memory)
    {
        bytes memory bytecode = type(A).creationCode;
        return abi.encodePacked(bytecode);
    }

    function getAddress(
        uint256 _salt)
        public
        view
        returns (address,bytes32)
    {
        bytes32 _code = keccak256(getBytecode());
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