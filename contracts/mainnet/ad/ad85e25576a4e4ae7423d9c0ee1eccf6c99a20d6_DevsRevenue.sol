/**
 *Submitted for verification at polygonscan.com on 2022-09-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC20{
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns(uint256);
}

contract DevsRevenue{

	// 1. Contracts
	IERC20 public immutable dai;

	// 2. Structs
	struct FixedRevenueDev{
		address walletAddress;
		uint daiPerMonth;
	}

	// 3. State variables
	address public ownershipRevenueDev;
	FixedRevenueDev[2] public fixedRevenueDevs;
	uint public lastWithdrawalTimestamp;

	// 4. Events
	event OwnershipRevenueDevSet(address dev);
	event FixedRevenueDevAdded(FixedRevenueDev dev);

	event RevenueWithdrawn(
		address ownershipRevenueDev,
		address fixedRevenueDev1,
		address fixedRevenueDev2,
		uint ownershipRevenueDevAmountDai,
		uint fixedRevenueDevAmountDai1,
		uint fixedRevenueDevAmountDai2
	);

	// Constructor (initialize devs)
	constructor(
		IERC20 _dai,
		address _ownershipRevenueDev,
		FixedRevenueDev[2] memory _fixedRevenueDevs
	){
		require(address(_dai) != address(0) && _ownershipRevenueDev != address(0), "ADDRESS_0");

		dai = _dai;

		ownershipRevenueDev = _ownershipRevenueDev;
		emit OwnershipRevenueDevSet(_ownershipRevenueDev);

		addFixedRevenueDev(0, _fixedRevenueDevs[0]);
		addFixedRevenueDev(1, _fixedRevenueDevs[1]);
	}

	// 1. Used in constructor
	function addFixedRevenueDev(uint _index, FixedRevenueDev memory _dev) private{
		require(_dev.walletAddress != address(0), "ADDRESS_0");
		require(_dev.daiPerMonth > 0, "VALUE_0");

		FixedRevenueDev storage dev = fixedRevenueDevs[_index];

		dev.walletAddress = _dev.walletAddress;
		dev.daiPerMonth = _dev.daiPerMonth;

		emit FixedRevenueDevAdded(dev);
	}

	// 2. Update settings
	function updateDaiPerMonth(uint amountDaiDev1, uint amountDaiDev2) external{
		require(msg.sender == ownershipRevenueDev, "ONLY_OWNER");

		fixedRevenueDevs[0].daiPerMonth = amountDaiDev1;
		fixedRevenueDevs[1].daiPerMonth = amountDaiDev2;
	}

	// 3. Withdraw
	function withdrawDai() external{
		require(msg.sender == ownershipRevenueDev
			|| msg.sender == fixedRevenueDevs[0].walletAddress
			|| msg.sender == fixedRevenueDevs[1].walletAddress, "NOT_DEV");

		require(block.timestamp - lastWithdrawalTimestamp >= 30 days, "TIME_TOO_EARLY");

		lastWithdrawalTimestamp = block.timestamp;

		FixedRevenueDev storage fixedRevenueDev1 = fixedRevenueDevs[0];
		FixedRevenueDev storage fixedRevenueDev2 = fixedRevenueDevs[1];

		uint ownershipRevenueDai = dai.balanceOf(address(this)) - fixedRevenueDev1.daiPerMonth - fixedRevenueDev2.daiPerMonth;

		dai.transfer(ownershipRevenueDev, ownershipRevenueDai);
		dai.transfer(fixedRevenueDev1.walletAddress, fixedRevenueDev1.daiPerMonth);
		dai.transfer(fixedRevenueDev2.walletAddress, fixedRevenueDev2.daiPerMonth);

		emit RevenueWithdrawn(
			ownershipRevenueDev,
			fixedRevenueDev1.walletAddress,
			fixedRevenueDev2.walletAddress,
			ownershipRevenueDai,
			fixedRevenueDev1.daiPerMonth,
			fixedRevenueDev2.daiPerMonth
		);
	}
}