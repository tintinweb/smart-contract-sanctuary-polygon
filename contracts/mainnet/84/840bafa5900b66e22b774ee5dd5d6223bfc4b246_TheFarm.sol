// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC1155Holder.sol";
import "./Ownable.sol";

import "./ITheFarm.sol";
import "./IRegistryFarmer.sol";
import "./IHonestFarmerClubV2.sol";

import "./LibraryFarmer.sol";

contract TheFarm is ITheFarm, ERC1155Holder, Ownable {
	// Events
	event Stake(
		uint256 indexed farmerId,
		address indexed depositor,
		uint256 indexed lockingDurationDays
	);
	event Withdraw(
		uint256 indexed farmerId,
		address indexed depositor,
		uint256 blocksStaked
	);
	event Claim(
		uint256 indexed farmerId,
		address indexed depositor,
		uint256 numberOfClaimedBlocks
	);
	event AddDelegate(address delegate);
	event RemoveDelegate(address delegate);

	// Infrastructure
	IRegistryFarmer public registryFarmer;
	uint256 public BLOCK_TIME_SECONDS = 2;

	// Depositors
	mapping(uint256 => address) public depositorByFarmerId; // FarmerId => Address
	mapping(uint256 => uint256) public latestDepositBlockNumberByFarmerId; // FarmerId => BlockNumber
	mapping(uint256 => uint256) public unlockBlockByFarmerId; // FarmerId => BlockNumber

	// Claiming
	bool public isClaimable;
	mapping(uint256 => uint256) public potatoPerDayByLockingDuration; // LockingDurationInDays => uint256
	mapping(uint256 => uint256) public claimedBlocksByFarmerId; // FarmerId => Blocks

	// Emission Delegation
	mapping(address => bool) public isDelegateByAddress; // Address => bool

	constructor(address _registryFarmer) {
		registryFarmer = IRegistryFarmer(_registryFarmer);

		potatoPerDayByLockingDuration[0] = 10;
		potatoPerDayByLockingDuration[50] = 12;
		potatoPerDayByLockingDuration[100] = 15;
	}

	modifier isUnlockedFarmer(uint256 farmerId) {
		require(
			unlockBlockByFarmerId[farmerId] <= block.number,
			"Farmer is locked"
		);
		_;
	}

	modifier onlyDepositorOrDelegate(uint256 farmerId) {
		if (isDelegateByAddress[msg.sender]) {
			_;
		} else {
			require(
				depositorByFarmerId[farmerId] == msg.sender,
				"Only depositor is allowed to call this function"
			);
			_;
		}
	}

	modifier onlyDepositorOrDelegateBatch(uint256[] memory farmerIds) {
		if (isDelegateByAddress[msg.sender]) {
			_;
		} else {
			for (uint256 i = 0; i < farmerIds.length; i++) {
				uint256 farmerId = farmerIds[i];
				require(
					depositorByFarmerId[farmerId] == msg.sender,
					"Only depositor is allowed to call this function"
				);
			}
			_;
		}
	}

	// Stake
	function _stakeFarmer(uint256 farmerId, uint256 lockingDurationDays)
		private
	{
		latestDepositBlockNumberByFarmerId[farmerId] = block.number;
		depositorByFarmerId[farmerId] = msg.sender;
		unlockBlockByFarmerId[farmerId] =
			block.number +
			lockingDurationDays *
			(86400 / BLOCK_TIME_SECONDS); // 1 day in Polygon land

		emit Stake(farmerId, msg.sender, lockingDurationDays);
	}

	function stakeFarmer(uint256 farmerId, uint256 lockingDurationDays) public {
		_transferFarmer(farmerId, msg.sender, address(this));
		_stakeFarmer(farmerId, lockingDurationDays);
	}

	function _stakeFarmerBatch(
		uint256[] memory farmerIds,
		uint256 lockingDurationDays
	) private {
		for (uint256 i = 0; i < farmerIds.length; i++) {
			uint256 farmerId = farmerIds[i];
			_stakeFarmer(farmerId, lockingDurationDays);
		}
	}

	function stakeFarmerBatch(
		uint256[] memory farmerIds,
		uint256 lockingDurationDays
	) public {
		_transferFarmerBatch(farmerIds, msg.sender, address(this));
		_stakeFarmerBatch(farmerIds, lockingDurationDays);
	}

	// Claiming
	function _claimBlocks(uint256 farmerId) private {
		uint256 claimableBlocks = getClaimableBlocks(farmerId);
		if (claimableBlocks > 0) {
			claimedBlocksByFarmerId[farmerId] += claimableBlocks;
			latestDepositBlockNumberByFarmerId[farmerId] = block.number;

			emit Claim(farmerId, msg.sender, claimableBlocks);
		}
	}

	function claimBlocks(uint256 farmerId)
		public
		onlyDepositorOrDelegate(farmerId)
	{
		_claimBlocks(farmerId);
	}

	function claimBlocksBatch(uint256[] memory farmerIds)
		public
		onlyDepositorOrDelegateBatch(farmerIds)
	{
		for (uint256 i = 0; i < farmerIds.length; i++) {
			uint256 farmerId = farmerIds[i];
			_claimBlocks(farmerId);
		}
	}

	// Withdraw
	function _unstakeFarmer(uint256 farmerId)
		private
		isUnlockedFarmer(farmerId)
	{
		claimBlocks(farmerId);
		depositorByFarmerId[farmerId] = address(0);
		unlockBlockByFarmerId[farmerId] = 0;
		uint256 blockStaked = claimedBlocksByFarmerId[farmerId];

		emit Withdraw(farmerId, msg.sender, blockStaked);
	}

	function withdrawFarmer(uint256 farmerId)
		public
		onlyDepositorOrDelegate(farmerId)
	{
		_unstakeFarmer(farmerId);
		_transferFarmer(farmerId, address(this), msg.sender);
	}

	function _unstakeFarmerBatch(uint256[] memory farmerIds) private {
		for (uint256 i = 0; i < farmerIds.length; i++) {
			uint256 farmerId = farmerIds[i];
			_unstakeFarmer(farmerId);
		}
	}

	function withdrawFarmerBatch(uint256[] memory farmerIds)
		public
		onlyDepositorOrDelegateBatch(farmerIds)
	{
		_unstakeFarmerBatch(farmerIds);
		_transferFarmerBatch(farmerIds, address(this), msg.sender);
	}

	// Emission Delegation
	function addDelegate(address delegate) public onlyOwner {
		isDelegateByAddress[delegate] = true;

		emit AddDelegate(delegate);
	}

	function removeDelegate(address delegate) public onlyOwner {
		isDelegateByAddress[delegate] = false;

		emit RemoveDelegate(delegate);
	}

	// Admin
	function toggleIsClaimable() public onlyOwner {
		isClaimable = !isClaimable;
	}

	function setPotatoRewards(uint256 lockingDurationDays, uint256 potatoPerDay)
		public
		onlyOwner
	{
		potatoPerDayByLockingDuration[lockingDurationDays] = potatoPerDay;
	}

	function withdrawFunds() public onlyOwner {
		uint256 maticBalance = address(this).balance;
		payable(msg.sender).transfer(maticBalance);
	}

	function emergencyWithdrawFarmers(uint256[] memory farmerIds)
		public
		onlyOwner
	{
		_unstakeFarmerBatch(farmerIds);
		_transferFarmerBatch(farmerIds, address(this), msg.sender);
	}

	// Views
	function isUnlocked(uint256 farmerId)
		public
		view
		returns (bool _isUnlocked)
	{
		uint256 unlockBlock = unlockBlockByFarmerId[farmerId];

		return unlockBlock <= block.number;
	}

	function getLatestDepositBlock(uint256 farmerId)
		public
		view
		returns (uint256)
	{
		return latestDepositBlockNumberByFarmerId[farmerId];
	}

	function getClaimableBlocksByBlock(uint256 farmerId, uint256 blockNumber)
		public
		view
		returns (uint256)
	{
		return
			isStaked(farmerId)
				? (blockNumber - getLatestDepositBlock(farmerId))
				: 0;
	}

	function getClaimableBlocks(uint256 farmerId)
		public
		view
		returns (uint256 claimableBlocks)
	{
		return getClaimableBlocksByBlock(farmerId, block.number);
	}

	function getClaimableBlocksByBlockBatch(
		uint256[] memory farmerIds,
		uint256 blockNumber
	) public view returns (uint256[] memory _claimableBlocks) {
		uint256[] memory claimableBlocks = new uint256[](farmerIds.length);

		for (uint256 i = 0; i < farmerIds.length; i++) {
			uint256 farmerId = farmerIds[i];
			claimableBlocks[i] = getClaimableBlocksByBlock(
				farmerId,
				blockNumber
			);
		}

		return claimableBlocks;
	}

	function getClaimableBlocksBatch(uint256[] memory farmerIds)
		public
		view
		returns (uint256[] memory _claimableBlocks)
	{
		return getClaimableBlocksByBlockBatch(farmerIds, block.number);
	}

	function getDepositor(uint256 farmerId)
		public
		view
		returns (address _depositor)
	{
		address depositor = depositorByFarmerId[farmerId];
		return depositor;
	}

	function getDepositorBatch(uint256[] memory farmerIds)
		public
		view
		returns (address[] memory _depositors)
	{
		address[] memory depositors = new address[](farmerIds.length);

		for (uint256 i = 0; i < depositors.length; i++) {
			uint256 farmerId = farmerIds[i];
			depositors[i] = getDepositor(farmerId);
		}

		return depositors;
	}

	function isStaked(uint256 farmerId) public view returns (bool) {
		return getDepositor(farmerId) != address(0);
	}

	function isStakedBatch(uint256[] memory farmerIds)
		public
		view
		returns (bool[] memory)
	{
		bool[] memory _isStaked = new bool[](farmerIds.length);

		for (uint256 i = 0; i < farmerIds.length; i++) {
			uint256 farmerId = farmerIds[i];
			_isStaked[i] = isStaked(farmerId);
		}

		return _isStaked;
	}

	// Utils
	function _transferFarmer(
		uint256 farmerId,
		address from,
		address to
	) private {
		IHonestFarmerClubV2 honestFarmerClubV2 = IHonestFarmerClubV2(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.HonestFarmerClubV2
			)
		);
		honestFarmerClubV2.safeTransferFrom(from, to, farmerId, 1, "");
	}

	function _transferFarmerBatch(
		uint256[] memory farmerIds,
		address from,
		address to
	) private {
		IHonestFarmerClubV2 honestFarmerClubV2 = IHonestFarmerClubV2(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.HonestFarmerClubV2
			)
		);

		uint256[] memory amounts = new uint256[](farmerIds.length);
		for (uint256 i; i < farmerIds.length; i++) {
			amounts[i] = 1;
		}

		honestFarmerClubV2.safeBatchTransferFrom(
			from,
			to,
			farmerIds,
			amounts,
			""
		);
	}
}