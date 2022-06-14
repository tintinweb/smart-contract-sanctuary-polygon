//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Swap.
 * @dev Swap integration for DEX Aggregators.
 */

// import files
import { SwapHelpers } from "./helpers.sol";

abstract contract Swap is SwapHelpers {
	/**
	 * @dev Swap ETH/ERC20_Token using dex aggregators.
	 * @notice Swap tokens from exchanges like 1INCH, 0x etc, with calculation done off-chain.
	 * @param _connectors The name of the connectors like 1INCH-A, 0x etc, in order of their priority.
	 * @param _data Encoded function call data including function selector encoded with parameters.
	 */
	function swap(string[] memory _connectors, bytes[] memory _data)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(bool success, bytes memory returnData) = _swap(_connectors, _data);

		require(success, "swap-Aggregator-failed");
		(_eventName, _eventParam) = abi.decode(returnData, (string, bytes));
	}
}

contract ConnectV2SwapAggregatorPolygon is Swap {
	string public name = "Swap-Aggregator-v1";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import { InstaConnectors } from "../../common/interfaces.sol";

contract SwapHelpers {
	/**
	 * @dev Instadapp Connectors Registry
	 */
	InstaConnectors internal constant instaConnectors =
		InstaConnectors(0x2A00684bFAb9717C21271E0751BCcb7d2D763c88);

	/**
	 *@dev Swap using the dex aggregators.
	 *@param _connectors name of the connectors in preference order.
	 *@param _data data for the swap cast.
	 */
	function _swap(string[] memory _connectors, bytes[] memory _data)
		internal
		returns (bool success, bytes memory returnData)
	{
		uint256 _length = _connectors.length;
		require(_length > 0, "zero-length-not-allowed");
		require(_data.length == _length, "calldata-length-invalid");

		for (uint256 i = 0; i < _length; i++) {
			(success, returnData) = instaConnectors
				.connectors(_connectors[i])
				.delegatecall(_data[i]);
			if (success) break;
		}
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

interface InstaConnectors {
    function connectors(string memory) external returns (address);
}