// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Proxy {
    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    fallback() external {
        address _implementation = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                _implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Proxy.sol';

contract ProxyFactory {
    address public immutable depositAddress;

    constructor(address addr) {
        require(addr != address(0), '0x0 is an invalid address');
        depositAddress = addr;
    }

    function deployNewInstance(bytes32 salt) external returns (address proxy) {
        address _depositAddress = depositAddress;
        proxy = address(new Proxy{ salt: salt }(_depositAddress));
    }

    function getInstanceAddress(bytes32 salt)
        public
        view
        returns (address instance)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(
                    abi.encodePacked(
                        type(Proxy).creationCode,
                        abi.encode(depositAddress)
                    )
                )
            )
        );
        instance = address(uint160(uint256(hash)));
    }
}