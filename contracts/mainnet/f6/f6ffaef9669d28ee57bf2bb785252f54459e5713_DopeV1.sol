/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

interface ERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function decimals() external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.7;


contract DopeV1 is Context {

	struct GameConfig {
		bool isActive;
		bool initiated;
		address tokenAddress;
		uint256 currentSession;
		uint256 feePercent;
		uint256 minimumParticipants;
		uint256 pickRewardPercent;
		uint256 bidAmount;
	}

	mapping(uint256 => GameConfig) private gameConfigs;

	uint256 public totalGames = 0;

	address private owner;

	// session holds the information about game's session participants(tickets count)
	// gameId => sessionId => participantsCount
	mapping(uint256 => mapping(uint256 => uint256)) private sessions;

	// participants mapping returns game's session index => participant key/value storage
	// gameId => sessionId => uniqueIdentifier => address
	mapping(uint256 => mapping(uint256 => mapping(uint256 => address))) private participants;

	// tickets returns information about adress' tickets count
	// gameId => sessionId => address => ticketsCount
	mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private tickets;

	// Address => ticketsCount total tickets bought
	mapping(address => uint256) private addressTotalTicketsCount;

	constructor(){
		owner = _msgSender();
	}

	modifier onlyOwner {
		require(msg.sender == owner, "Only owner");
		_;
	}

	// SET: OnlyOwner
	function addGame(address _tokenAddress, uint256 _feePercent, uint256 _minimumParticipants, uint256 _pickRewardPercent, uint256 _bidAmount) external onlyOwner {
		uint256 index = totalGames + 1;
		gameConfigs[index] = GameConfig({
		initiated : true,
		isActive : true,
		tokenAddress : _tokenAddress,
		currentSession : 1,
		feePercent : _feePercent,
		minimumParticipants : _minimumParticipants,
		pickRewardPercent : _pickRewardPercent,
		bidAmount : _bidAmount
		});
		totalGames += 1;
	}

	// GET: Everyone
	function getGame(uint256 gameId) public view returns (GameConfig memory){
		return gameConfigs[gameId];
	}

	// SET: OnlyOwner
	function editGame(uint256 gameId, bool _isActive, uint256 _feePercent, uint256 _minimumParticipants, uint256 _pickRewardPercent, uint256 _bidAmount) external onlyOwner {
		isGameInitiated(gameId);

		GameConfig storage game = gameConfigs[gameId];

		game.isActive = _isActive;
		game.feePercent = _feePercent;
		game.minimumParticipants = _minimumParticipants;
		game.pickRewardPercent = _pickRewardPercent;
		game.bidAmount = _bidAmount;
	}

	// SET: OnlyOwner
	function deleteGame(uint256 gameId) external onlyOwner {
		isGameInitiated(gameId);
		delete gameConfigs[gameId];
	}




	// SET
	function participate(uint256 gameId, uint256 ticketsCount) external {

		// Check for game configs
		isGameInitiated(gameId);
		isGameActive(gameId);

		require(ticketsCount > 0, "Invalid number of tickets");

		GameConfig memory game = gameConfigs[gameId];
		ERC20 token = ERC20(game.tokenAddress);

		uint256 balance = token.balanceOf(_msgSender());
		// Check if balance is high bid * count
		require(balance > (game.bidAmount * ticketsCount), "Not enough balance");

		bool transfer = token.transferFrom(_msgSender(), address(this), game.bidAmount * ticketsCount);
		if (transfer) {
			setAddressTotalTickets(_msgSender(), ticketsCount);
			uint currentPlayersCount = getTotalTicketsBySession(gameId, game.currentSession);

			for (uint256 i = 1; i <= ticketsCount; i++) {
				setParticipantForSession(gameId, game.currentSession, currentPlayersCount + i, _msgSender());
			}

			addToTicketsBySession(gameId, game.currentSession, ticketsCount);
			setTicketsForUser(gameId, game.currentSession, _msgSender(), ticketsCount);
		} else {
			revert("Transfer failed");
		}
	}
	
	// SET:
	function draw(uint256 gameId) external {
		GameConfig storage game = gameConfigs[gameId];
		uint256 currentParticipants = getTotalTicketsBySession(gameId, game.currentSession);

		require(currentParticipants > game.minimumParticipants, "Not enough participants");
		require(game.isActive == true, "Game is not active");

		ERC20 token = ERC20(game.tokenAddress);
		// Added +1 as random number will be generated from 0-49, if currentParticipants=50 => +1 => 1-50
		uint256 winnerIndex = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender()))) % currentParticipants) + 1;
		address winnerAddress = getParticipantInSessionByIndex(gameId, game.currentSession, winnerIndex);

		uint256 total = game.bidAmount * getTotalTicketsBySession(gameId, game.currentSession);
		uint256 pickerReward = (total * game.pickRewardPercent) / 100;
		uint256 winnerReward = total - pickerReward - ((total * game.feePercent) / 100);

		bool drawTransfer = token.transfer(_msgSender(), pickerReward);
		bool winnerTransfer = token.transfer(winnerAddress, winnerReward);

		if (drawTransfer && winnerTransfer) {
			game.currentSession += 1;}
	}



	// GET: OnlyOwner
	function withdraw(address tokenAddress, address toAddress, uint256 amount) external onlyOwner {
		ERC20(tokenAddress).transfer(toAddress, amount);
	}

	// GET: Everyone
	function getTicketsCount(uint256 gameId, uint256 session, address userAddress) external view returns (uint256){
		return tickets[gameId][session][userAddress];
	}

	// SET: private
	function setTicketsForUser(uint256 gameId, uint256 session, address userAddress, uint256 ticketsCount) private {
		tickets[gameId][session][userAddress] += ticketsCount;
	}


	// SET: Private
	function setParticipantForSession(uint256 gameId, uint256 session, uint256 index, address userAddress) private {
		participants[gameId][session][index] = userAddress;
	}

	// GET: Everyone
	function getParticipantInSessionByIndex(uint256 gameId, uint256 session, uint256 index) public view returns (address){
		return participants[gameId][session][index];
	}



	// GET: Everyone
	function addressTotalTickets(address userAddress) external view returns (uint256){
		return addressTotalTicketsCount[userAddress];
	}

	// SET: OnlyOwner
	function setAddressTotalTickets(address userAddress, uint256 ticketsCount) private {
		addressTotalTicketsCount[userAddress] += ticketsCount;
	}

	// GET: Everyone
	function getTotalTicketsBySession(uint256 gameId, uint256 session) public view returns (uint256){
		return sessions[gameId][session];
	}

	// SET: Owner only
	function addToTicketsBySession(uint256 gameId, uint256 session, uint256 ticketsCount) private {
		sessions[gameId][session] += ticketsCount;
	}

	// SET: OnlyOwner
	function useReserveFunds(address tokenAddress, address fundAddress, uint256 amount) external onlyOwner {
		ERC20(tokenAddress).transferFrom(fundAddress, address(this), amount);
	}


	// GET: Everyone
	function isGameInitiated(uint256 gameId) public view returns (bool) {
		require(gameConfigs[gameId].initiated == true, "Game is not initiated");
		return true;
	}

	// GET: Everyone
	function isGameActive(uint256 gameId) public view returns (bool) {
		require(gameConfigs[gameId].isActive == true, "Game is not active");
		return true;
	}
}