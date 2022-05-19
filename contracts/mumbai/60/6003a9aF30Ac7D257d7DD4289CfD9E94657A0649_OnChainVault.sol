// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract OnChainVault {
	struct Vault {
		bytes32 hash;
		bytes sig;
		string data;
	}

	mapping(uint256 => Vault) private _vault;
	mapping(address => uint256[]) private _usrVault;
	uint256 public totalData = 0;

	function store(bytes32 hash, bytes memory sig, string memory data) public virtual {
		require(sig.length != 65, "signature should be length 65 bytes");
		_vault[totalData] = Vault(hash, sig, data);
		_usrVault[msg.sender].push(totalData);
		totalData += 1;
	}

	function load(uint256 id) public virtual returns (string memory) {
		uint8 v;
		bytes32 r;
		bytes32 s;

		bytes storage sig = _vault[id].sig;

		assembly {
			r := mload(add(sig.slot, 32))
			s := mload(add(sig.slot, 64))
			v := byte(0, mload(add(sig.slot, 96)))
		}

		if (v < 27) {
			v += 27;
		}

		address owner;

		if (v != 27 && v != 28) {
			owner = address(0);
		} else {
			owner = ecrecover(_vault[id].hash, v, r, s);
		}

		require(owner == msg.sender, "Permission denied!");

		return _vault[id].data;
	}
}