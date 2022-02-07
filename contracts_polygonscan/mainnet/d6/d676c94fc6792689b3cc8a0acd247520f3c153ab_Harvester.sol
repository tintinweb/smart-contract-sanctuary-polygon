//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "IVault.sol";
import "IUniswapV2Router.sol";
import "Ownable.sol";
import "SafeMath.sol";

contract Harvester is Ownable {
	using SafeMath for uint256;

	event Harvested(address indexed vault, address indexed sender);

	// Quickswap Router
	IUniswapV2Router constant ROUTER =
		IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

	// Connectors
	address public WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
	address public WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

	uint256 public delay;

	constructor(uint256 _delay) {
		delay = _delay;
	}

	modifier onlyAfterDelay(IVault vault) {
		require(
			block.timestamp >= vault.lastDistribution().add(delay),
			"Not ready to harvest"
		);
		_;
	}

	function getBestConnector(
		address from,
		address to,
		uint256 amount
	) public view returns (address connector) {
		connector = address(0);

		// Check with no connector
		address[] memory path = new address[](2);
		path[0] = address(from);
		path[1] = address(to);
		uint256 noConnector = ROUTER.getAmountsOut(amount, path)[
			path.length - 1
		];

		// Check with WMATIC
		uint256 usingMatic = noConnector;
		// when volatile asset not the connector
		if (address(from) != WMATIC && address(to) != WMATIC) {
			path = new address[](3);
			path[0] = address(from);
			path[1] = WMATIC;
			path[2] = address(to);
			usingMatic = ROUTER.getAmountsOut(amount, path)[path.length - 1];
			connector = usingMatic > noConnector ? WMATIC : connector;
		}

		// Check with WETH
		// when volatile asset is not the connector
		if (address(from) != WETH && address(to) != WETH) {
			path = new address[](3);
			path[0] = address(from);
			path[1] = WETH;
			path[2] = address(to);
			uint256 usingETH = ROUTER.getAmountsOut(amount, path)[
				path.length - 1
			];
			connector = usingETH > usingMatic ? WETH : connector;
		}
	}

	/**
		@notice Harvest vault using quickswap router
		@dev any user can harvest after delay has passed
	*/
	function harvestVault(IVault vault) public onlyAfterDelay(vault) {
		// Amount to Harvest
		uint256 afterFee = vault.harvest();
		require(afterFee > 0, "!Yield");

		IERC20 from = vault.rewards();
		IERC20 to = vault.target();

		address connector = getBestConnector(
			address(from),
			address(to),
			afterFee
		);

		// Quickswap path
		address[] memory path;

		if (connector == address(0)) {
			path = new address[](2);
			path[0] = address(from);
			path[1] = address(to);
		} else {
			path = new address[](3);
			path[0] = address(from);
			path[1] = connector;
			path[2] = address(to);
		}

		// Swap underlying to target
		from.approve(address(ROUTER), afterFee);
		uint256 received = ROUTER.swapExactTokensForTokens(
			afterFee,
			1,
			path,
			address(this),
			block.timestamp + 1
		)[path.length - 1];

		// Send profits to vault
		to.approve(address(vault), received);
		vault.distribute(received);

		emit Harvested(address(vault), msg.sender);
	}

	/**
		@dev update delay required to harvest vault
	*/
	function setDelay(uint256 _delay) external onlyOwner {
		delay = _delay;
	}

	// no tokens should ever be stored on this contract. Any tokens that are sent here by mistake are recoverable by the owner
	function sweep(address _token) external onlyOwner {
		IERC20(_token).transfer(
			owner(),
			IERC20(_token).balanceOf(address(this))
		);
	}
}