/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

pragma solidity 0.8.19;

// ----------------------------------------------------------------------------
// SD contract 
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

contract NEW {
    address public owner;
    uint256 public salt;
    
    constructor(address _owner, uint256 _salt) {
        owner = _owner;
        salt = _salt;
    }
    
    function destruct() external {
        require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }
}

contract Reinit  {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
    
    function create(uint256 _s) public returns (address) { 
        address _contract = deploy(getBytecode(_s), keccak256(abi.encodePacked(_s)));
        return (_contract);
    }

    function getAddress(uint256 _s) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), keccak256(abi.encodePacked(_s)), keccak256(getBytecode(_s)))
        );
        return address(uint160(uint(hash)));
    }

    function deploy(bytes memory code, bytes32 salt) internal returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function getBytecode(uint _s) internal view returns (bytes memory) {
        bytes memory bytecode = abi.encodePacked(type(NEW).creationCode, abi.encode(address(this), _s));
        return bytecode;
    }

    function destruct(uint _s) public returns (bool) {
        (bool success,) = getAddress(_s).call(abi.encodeWithSignature("destruct()"));
        return success;
    }

    function destruct() external {
        require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }

}