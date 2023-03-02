/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ContractDeployerFactory is Ownable {
    event ContractDeployed(uint256 salt, address addr);

    //根据Calldata和salt部署地址
    function deployContract(uint256 _salt, bytes memory _contractBytecode) public onlyOwner {
        address addr;
        assembly {
            addr := create2(0, add(_contractBytecode, 0x20), mload(_contractBytecode), _salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(_salt, addr);
    }
    
    //根据合约的Bytecode和部署参数,得到Calldata
    function getBytecode(bytes memory _creationCode,address _k)
        public
        pure
        returns (bytes memory _contractBytecode)
    {
        _contractBytecode = abi.encodePacked(_creationCode,abi.encode(_k));
    }

    //根据Calldata和salt预测合约地址
    function getAddress(uint256 _salt, bytes memory _contractBytecode) public view returns (address,bytes32) {
         bytes32 _code = keccak256(_contractBytecode);
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