/**
 *Submitted for verification at polygonscan.com on 2022-06-14
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

interface IConstructor {
    function version() external view returns (string memory);
}   

contract FactoryProxy {

    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event OwnerChanged(address previousOwner, address newOwner);
    event Upgraded(address implementation);

    modifier onlyOwner {
        require(msg.sender == _owner());
        _;
    }
    
    constructor(address payable _impl, address _owner, bytes memory _data) public {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        
        bytes32 slot = _IMPLEMENTATION_SLOT;
        _setOwner(_owner);
        
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _impl)
        }
        
        if(_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = _impl.delegatecall(_data);
            require(success);
        }
    }

    function implementation() external view onlyOwner returns (address) {
        return _implementation();
    }

    function _implementation() internal view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    function _setImplementation(address newImplementation, string memory version) private {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        require(keccak256(abi.encodePacked(IConstructor(newImplementation).version())) == keccak256(abi.encodePacked(version)));

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function Owner() external view onlyOwner returns (address) {
        return _owner();
    }

    function _owner() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    function _setOwner(address newOwner) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newOwner)
        }
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "TransparentUpgradeableProxy: new Owner is the zero address");
        emit OwnerChanged(_owner(), newOwner);
        _setOwner(newOwner);
    }

    function upgradeTo(address newImplementation, string calldata version) external onlyOwner {
        _upgradeTo(newImplementation, version);
    }

    function _upgradeTo(address newImplementation, string memory version) internal {
        _setImplementation(newImplementation, version);
        emit Upgraded(newImplementation);
    }

    function () payable external {
        address impl = _implementation();
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}