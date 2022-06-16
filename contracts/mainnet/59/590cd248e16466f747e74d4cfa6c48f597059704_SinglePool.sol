/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

interface ISinglePoolFactory {
    function singlePoolImpl() external view returns (address);
}

contract SinglePool {

    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event OwnerChanged(address previousOwner, address newOwner);
    event Upgraded(address implementation);

    modifier onlyOwner {
        require(msg.sender == _owner());
        _;
    }
    
    constructor(address _owner, bytes memory _data) public {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setOwner(_owner);
        
        address impl = ISinglePoolFactory(msg.sender).singlePoolImpl();
        if (_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = impl.delegatecall(_data);
            require(success);
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
        require(newOwner != address(0), "Proxy: new Owner is the zero address");
        emit OwnerChanged(_owner(), newOwner);
        _setOwner(newOwner);
    }

    function () payable external { 
        address impl = ISinglePoolFactory(_owner()).singlePoolImpl();
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