/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/IProxy.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IProxy {

	function ProxyType() external pure returns (uint256);

	function implementation() external view returns (address implementation_);

}


// File contracts/Proxy.sol

pragma solidity ^0.8.10;

abstract contract Proxy is IProxy {

		function delegatedCall(address _to, bytes memory _data) internal {
			assembly {
				let result := delegatecall(
					sub(gas(), 10000),
					_to,
					add(_data, 0x20),
					mload(_data),
					0,
					0
				)

				let size := returndatasize()

				let ptr := mload(0x40)

				returndatacopy(ptr, 0, size)

				switch result 
					case 0 {
						revert(ptr, size)
					}

					default {
						return(ptr, size)
					}
			}
		}

		function ProxyType() external virtual override pure returns (uint256 proxyType) {
			proxyType = 2;
		}

		function implementation() external virtual override view returns (address);

}


// File contracts/UpgradableProxy.sol

pragma solidity ^0.8.10;

contract UpgradableProxy is Proxy {
	event ProxyUpdated(address indexed _old, address indexed _new);

	event ProxyOwnerUpdated(address indexed _old, address indexed _new);

	bytes32 public constant IMPLEMENTATION_SLOT = keccak256("be.brave.proxy.implementation");

	bytes32 public constant OWNER_SLOT = keccak256("be.brave.proxy.owner");

	constructor(address implementation_) {
		setImplementation(implementation_);
		setProxyOwner(msg.sender);
	}

	function setProxyOwner(address _owner) private {
		bytes32 slot = OWNER_SLOT;
		assembly {
			sstore(slot, _owner)
		}
	}

	function proxyOwner() public view returns (address owner_) {
		bytes32 slot = OWNER_SLOT;
		assembly {
			owner_ := sload(slot)
		}
	}

	function setImplementation(address implementation_) private {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			sstore(slot, implementation_)
		}
	}

	function _implementation() internal view returns (address implementation_) {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			implementation_ := sload(slot)
		}
	}

	function implementation() external virtual override view returns( address) {
		return _implementation();
	}

	modifier onlyOwner {
		require(msg.sender == proxyOwner());
		_;
	}

	fallback() external payable {
		delegatedCall(_implementation(), msg.data);
	}

	receive() external payable {
		bytes memory data_;
		delegatedCall(_implementation(), data_);
	}

	function transferProxyOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0), "new owner cannot be the zero address");
		emit ProxyOwnerUpdated(proxyOwner(), _newOwner);
		setProxyOwner(_newOwner);
	}

	function isContract(address _target) internal view returns (bool) {
		if (_target == address(0)) {
			return false;
		}

		uint256 size;
		assembly {
			size := extcodesize(_target)
		}

		return size > 0;
	}

	function UpdateImplementation(address _newImplementation) public onlyOwner {
		require(_newImplementation != address(0) || _newImplementation != address(0x0), "Invalid proxy address");
		require(isContract(_newImplementation), "Proxy address is not a contract");
		emit ProxyUpdated(_implementation(), _newImplementation);

		setImplementation(_newImplementation);
	}

	function UpdateAndCallImplementation(address _newImplementation, bytes memory _data) public payable onlyOwner {
		UpdateImplementation(_newImplementation);
		(bool success, bytes memory returnData) = address(this).call{
			value: msg.value
		}(_data);
		require(success, string(returnData));
	}
}


// File contracts/Brave.sol

contract Brave is UpgradableProxy {
	constructor(address implementation_) UpgradableProxy(implementation_) {}
}