/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract Proxy {
	bytes32 private constant ADMIN_SLOT = 0xde50c0ef4724e938441b7d87888451dee5481c5f4cdb090e8051ee74ce71c31c;
	bytes32 private constant IMPLEMENTATION_SLOT = 0x454e447e72dbaa44ab6e98057df04d15461fc11a64ce58e5e1472346dea4223f;

	constructor (address _i) {
		_setImplementation(_i);
		_setAdmin(msg.sender);
	}

	event AdminChanged (address admin);
	event Upgraded (address implementation);

	modifier onlyAdmin () {
		require(msg.sender == _admin());
		_;
	}

	function proxyChangeAdmin(address _newAdmin) external onlyAdmin {
		require(_newAdmin != address(0));
		_setAdmin(_newAdmin);
		emit AdminChanged(_newAdmin);
	}

	function proxyUpgradeTo(address _newImplementation) public onlyAdmin {
		_setImplementation(_newImplementation);
		emit Upgraded(_newImplementation);
	}

	function proxyUpgradeToAndCall(
		address _newImplementation,
		bytes calldata _data
	) external payable onlyAdmin returns (bytes memory) {
		proxyUpgradeTo(_newImplementation);
		(bool success, bytes memory data) = address(this).call{value:msg.value}(_data);
		require(success);
		return data;
	}

	function _admin () internal view returns (address a) {
		bytes32 slot = ADMIN_SLOT;
		assembly {
			a := sload(slot)
		}
	}

	function _implementation () internal view returns (address i) {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			i := sload(slot)
		}
	}

	function admin() external view onlyAdmin returns (address) {
		return _admin();
	}

	function implementation() external view onlyAdmin returns (address) {
		return _implementation();
	}

	function _setAdmin (address newAdmin) internal {
		bytes32 slot = ADMIN_SLOT;
		assembly {
			sstore(slot, newAdmin)
		}
	}

	function _setImplementation (address newImplementation) internal {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			sstore(slot, newImplementation)
		}
	}

	fallback () external payable {
		address i = _implementation();
		assembly {
			calldatacopy(0, 0, calldatasize())

			let result := delegatecall(gas(), i, 0, calldatasize(), 0, 0)

			returndatacopy(0, 0, returndatasize())

			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}

	receive () external payable {}
}