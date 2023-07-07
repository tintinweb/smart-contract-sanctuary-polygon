//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
    function transferOwnership(address newOwner) external;
    function balanceOf(address _userAddress) external view returns (uint256);
    function transfer(address _to, uint256 _value) external;
    function renounceOwnership() external;
}

contract ERC20TokenDeployerWithCreate2 {
    event Deployed(address contractAddress, uint256 saltUsed);

    function getAddress(
        bytes memory bytecode,
        uint256 _salt
    ) external view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    
    function deploy(bytes memory bytecode, uint256 _salt, address _transferTokenTo, bool _ownershipRenounce) public payable {
        address contractAddressDeployed;

        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            contractAddressDeployed := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )
        }

        if(contractAddressDeployed == address(0)) {
            revert("Token address is zero");
        } else {
            if(!_ownershipRenounce) {
                IERC20(contractAddressDeployed).transferOwnership(msg.sender);
            } else {
                IERC20(contractAddressDeployed).renounceOwnership();
            }
            
            uint256 tokenBalanceThis = IERC20(contractAddressDeployed).balanceOf(address(this));
            IERC20(contractAddressDeployed).transfer(_transferTokenTo, tokenBalanceThis);
        }

        emit Deployed(contractAddressDeployed, _salt);
    }
}