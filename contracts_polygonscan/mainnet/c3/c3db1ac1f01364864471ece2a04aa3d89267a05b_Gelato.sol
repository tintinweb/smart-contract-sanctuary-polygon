// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import {IHarvester} from "IHarvester.sol";
import {IVault} from "IVault.sol";
import "SafeMath.sol";
import "Ownable.sol";
import "EnumerableSet.sol";

contract Gelato is Ownable {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;

	EnumerableSet.AddressSet private vaults;

	IHarvester public harvester;

	function addVault(address _newVault) external onlyOwner {
		require(!vaults.contains(_newVault), "EXISTS");

		vaults.add(_newVault);
	}

	function removeVault(address _vault) external onlyOwner {
		require(vaults.contains(_vault), "!EXISTS");

		vaults.remove(_vault);
	}

	function setHarvester(IHarvester _harvester) external onlyOwner {
		harvester = _harvester;
	}

	function getVault(uint256 index) public view returns (address) {
		return vaults.at(index);
	}

	function checker()
		external
		view
		returns (bool canExec, bytes memory execPayload)
	{
		uint256 delay = harvester.delay();

		for (uint256 i = 0; i < vaults.length(); i++) {
			IVault vault = IVault(getVault(i));

			canExec = block.timestamp >= vault.lastDistribution().add(delay);

			execPayload = abi.encodeWithSelector(
				IHarvester.harvestVault.selector,
				address(vault)
			);

			if (canExec) break;
		}
	}
}